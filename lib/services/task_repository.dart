import 'dart:async';
import 'dart:convert'; // Для jsonDecode

import 'package:drift/drift.dart' hide Column; // Прячем Column из drift
import 'package:flutter_quill/flutter_quill.dart'
    hide Text; // Прячем Text из quill
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import for listEquals

import '../database/database.dart'; // Импорт AppDatabase и Provider
import '../models/link.dart';
import '../models/task.dart';
import '../services/daily_note_repository.dart';
import '../services/link_repository.dart';
import '../services/project_repository.dart';
import '../services/supabase_client_provider.dart';
import '../providers/auth_providers.dart'; // <-- Добавляем импорт

// --- Custom Exceptions ---

class TaskAddException implements Exception {
  final String message;
  final dynamic originalError;
  TaskAddException(this.message, [this.originalError]);
  @override
  String toString() =>
      'TaskAddException: $message ${originalError != null ? "(Original: $originalError)" : ""}';
}

class TaskUpdateException implements Exception {
  final String message;
  final dynamic originalError;
  TaskUpdateException(this.message, [this.originalError]);
  @override
  String toString() =>
      'TaskUpdateException: $message ${originalError != null ? "(Original: $originalError)" : ""}';
}

class TaskDeleteException implements Exception {
  final String message;
  final dynamic originalError;
  TaskDeleteException(this.message, [this.originalError]);
  @override
  String toString() =>
      'TaskDeleteException: $message ${originalError != null ? "(Original: $originalError)" : ""}';
}

// Provider for the TaskRepository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider); // Получаем доступ к локальной БД
  // Слушаем изменения аутентификации
  final authChanges = ref.watch(authStateProvider);
  // Используем ключ, чтобы пересоздать репозиторий при смене пользователя
  return TaskRepository(client, db, ref,
      userId: authChanges.value?.session?.user.id);
});

class TaskRepository {
  final SupabaseClient _client;
  final AppDatabase _db; // Локальная БД
  final Ref _ref; // Сохраняем Ref
  final String? _userId; // Кэшируем ID пользователя

  // Добавляем Ref в конструктор
  TaskRepository(this._client, this._db, this._ref, {required String? userId})
      : _userId = userId;

  // Получение всех задач для текущего пользователя (для списка)
  Future<List<Task>> fetchTasks({String? projectId}) async {
    if (_userId == null) return [];

    // 1. Пробуем получить из локальной БД
    final query = _db.select(_db.tasks)
      ..where((t) => t.userId.equals(_userId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.isCompleted)
      ]) // Сначала невыполненные
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
      ]); // Потом по дате

    if (projectId != null) {
      query.where((t) => t.projectId.equals(projectId));
    } else {
      // Показываем задачи без проекта, если projectId == null
      query.where((t) => t.projectId.isNull());
    }

    final List<TaskEntry> localEntries = await query.get();

    if (localEntries.isNotEmpty) {
      print('Fetched tasks from local DB (projectId: $projectId)');
      return localEntries.map(_mapEntryToModel).toList();
    }

    // 2. Если локально пусто, получаем из Supabase
    print(
        'Local tasks DB empty, fetching from Supabase (projectId: $projectId)...');
    try {
      var supabaseQuery = _client.from('tasks').select().eq('user_id', _userId);

      if (projectId != null) {
        supabaseQuery = supabaseQuery.eq('project_id', projectId);
      } else {
        supabaseQuery = supabaseQuery.isFilter('project_id', null);
      }

      final response =
          await supabaseQuery.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      final List<Task> tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      // 3. Кэшируем в локальной БД
      if (tasks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.tasks,
            tasks.map(_mapModelToCompanion).toList(),
            mode: InsertMode.insertOrReplace,
          );
        });
        print(
            'Cached ${tasks.length} tasks to local DB (projectId: $projectId)');
      }

      // Сортируем результат для UI
      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0));
      });
      return tasks;
    } on PostgrestException catch (error) {
      print('Error fetching tasks from Supabase: ${error.message}');
      throw Exception('Failed to fetch tasks: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching tasks: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Получение задач, сгруппированных по статусу (для Kanban)
  Future<Map<String, List<Task>>> fetchTasksByStatus(
      {String? projectId}) async {
    if (_userId == null) return {}; // Нет пользователя - нет задач

    try {
      var query = _client.from('tasks').select().eq('user_id', _userId);

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      final response = await query.order('created_at',
          ascending:
              true); // Сортируем по дате создания для порядка внутри колонки

      final List<dynamic> data = response as List<dynamic>;
      final tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      // Группируем по статусу
      final Map<String, List<Task>> groupedTasks = {};
      for (final task in tasks) {
        (groupedTasks[task.status] ??= []).add(task);
      }

      // Добавляем пустые списки для стандартных статусов, если их нет
      for (final status in ['backlog', 'todo', 'in_progress', 'done']) {
        groupedTasks.putIfAbsent(status, () => []);
      }

      return groupedTasks;
    } on PostgrestException catch (error) {
      print('Error fetching tasks by status: ${error.message}');
      throw Exception('Failed to fetch tasks by status: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching tasks by status: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Добавление новой задачи с парсингом ссылок
  Future<Task> addTask(Task task) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // 1. Добавляем в Supabase
      final taskData = task.toJson()..['user_id'] = _userId;
      taskData.remove('id');
      taskData.remove('created_at');
      taskData.remove('updated_at');
      taskData['depends_on'] = task.dependsOn;
      taskData['blocking'] = task.blocking;
      if (task.parentTaskId != null) {
        taskData['parent_task_id'] = task.parentTaskId;
      }
      taskData['tags'] = task.tags;
      taskData['recurrence_rule'] = task.recurrenceRule;
      taskData['reminder_time'] = task.reminderTime?.toIso8601String();

      final response =
          await _client.from('tasks').insert(taskData).select().single();
      final newTask = Task.fromJson(response);

      // 2. Добавляем в локальную БД
      await _db
          .into(_db.tasks)
          .insert(_mapModelToCompanion(newTask), mode: InsertMode.replace);
      print('Added task ${newTask.id} to local DB');

      // 3. Обновляем ссылки (после добавления в обе БД)
      try {
        await _updateLinksFromDescription(newTask.id, newTask.description);
      } catch (linkError) {
        print(
            'Error updating links after adding task ${newTask.id}: $linkError');
      }
      return newTask;
    } on PostgrestException catch (error) {
      // TODO: Rollback local insert?
      print('Error adding task: ${error.message}');
      // Throw specific exception
      throw TaskAddException('Failed to add task to database.', error);
    } catch (error) {
      print('Unexpected error adding task: $error');
      // Throw specific exception
      throw TaskAddException('An unexpected error occurred.', error);
    }
  }

  // Обновление задачи с парсингом ссылок
  Future<Task> updateTask(Task task) async {
    if (_userId == null || _userId != task.userId)
      throw TaskUpdateException(
          'Authorization error'); // Use specific exception

    // --- Логика обработки повторения ПЕРЕД обновлением ---
    Task taskToUpdate = task;
    bool shouldResetCompletion = false;
    DateTime? nextDueDate;

    // Проверяем, была ли задача только что завершена и имеет ли правило повторения
    // Для этого нам нужна предыдущая версия задачи, которой у нас здесь нет.
    // Упрощенный подход: если задача ЗАВЕРШЕНА СЕЙЧАС и имеет правило повторения и ДАТУ,
    // то считаем, что ее нужно перенести.
    if (task.isCompleted &&
        task.recurrenceRule != null &&
        task.dueDate != null) {
      nextDueDate = _calculateNextDueDate(task.dueDate!, task.recurrenceRule!);
      if (nextDueDate != null) {
        print(
            'Rescheduling recurring task ${task.id} to $nextDueDate based on rule ${task.recurrenceRule}');
        taskToUpdate = task.copyWith(
            dueDate: nextDueDate,
            isCompleted: false // Сбрасываем статус выполнения
            );
        shouldResetCompletion = true; // Флаг, что нужно сбросить статус
      }
    }
    // --- Конец логики повторения ---

    try {
      // 1. Обновляем в Supabase (используем taskToUpdate)
      final taskData = taskToUpdate.toJson();
      taskData.remove('created_at');
      taskData.remove('updated_at');
      taskData.remove('id');
      taskData.remove('user_id');
      taskData['depends_on'] = taskToUpdate.dependsOn;
      taskData['blocking'] = taskToUpdate.blocking;
      taskData['parent_task_id'] = taskToUpdate.parentTaskId;
      taskData['tags'] = taskToUpdate.tags;
      taskData['recurrence_rule'] =
          taskToUpdate.recurrenceRule; // Обновляем правило
      // Важно: Передаем обновленный isCompleted и dueDate
      taskData['is_completed'] = taskToUpdate.isCompleted;
      taskData['due_date'] = taskToUpdate.dueDate?.toIso8601String();
      taskData['reminder_time'] = taskToUpdate.reminderTime?.toIso8601String();

      final response = await _client
          .from('tasks')
          .update(taskData)
          .eq('id', taskToUpdate.id)
          .eq('user_id', _userId)
          .select()
          .single();
      final updatedTaskFromDb = Task.fromJson(response);

      // 2. Обновляем в локальной БД (используем updatedTaskFromDb)
      await (_db.update(_db.tasks)
            ..where((t) => t.id.equals(updatedTaskFromDb.id)))
          .write(_mapModelToCompanion(updatedTaskFromDb));
      print(
          'Updated task ${updatedTaskFromDb.id} in local DB (Recurring: $shouldResetCompletion)');

      // 3. Обновляем ссылки (используем updatedTaskFromDb)
      try {
        await _updateLinksFromDescription(
            updatedTaskFromDb.id, updatedTaskFromDb.description);
      } catch (linkError) {
        print(
            'Error updating links after updating task ${updatedTaskFromDb.id}: $linkError');
      }
      return updatedTaskFromDb; // Возвращаем обновленную задачу из БД
    } on PostgrestException catch (error) {
      // TODO: Rollback local update?
      print('Error updating task: ${error.message}');
      // Throw specific exception
      throw TaskUpdateException('Failed to update task in database.', error);
    } catch (error) {
      print('Unexpected error updating task: $error');
      // Throw specific exception
      throw TaskUpdateException('An unexpected error occurred.', error);
    }
  }

  // --- Вспомогательная функция для расчета следующей даты ---
  DateTime? _calculateNextDueDate(DateTime currentDueDate, String rule) {
    // Убираем время, чтобы избежать проблем с часовыми поясами при добавлении дней/месяцев
    final currentDateOnly =
        DateTime(currentDueDate.year, currentDueDate.month, currentDueDate.day);

    try {
      switch (rule) {
        case 'daily':
          return currentDateOnly.add(const Duration(days: 1));
        case 'weekly':
          return currentDateOnly.add(const Duration(days: 7));
        case 'monthly':
          // Осторожно с концом месяца
          final nextMonth = currentDateOnly.month + 1;
          final nextYear =
              nextMonth > 12 ? currentDateOnly.year + 1 : currentDateOnly.year;
          final finalNextMonth = nextMonth > 12 ? 1 : nextMonth;
          // Проверяем, существует ли такое же число в следующем месяце
          int day = currentDateOnly.day;
          int daysInNextMonth = DateTime(nextYear, finalNextMonth + 1, 0).day;
          if (day > daysInNextMonth) {
            day = daysInNextMonth; // Переходим на последний день месяца
          }
          return DateTime(nextYear, finalNextMonth, day);
        case 'yearly':
          // Проверка на високосный год (29 февраля)
          if (currentDateOnly.month == 2 && currentDateOnly.day == 29) {
            // Переносим на 1 марта в невисокосные годы
            int nextYear = currentDateOnly.year + 1;
            while (nextYear % 4 != 0 ||
                (nextYear % 100 == 0 && nextYear % 400 != 0)) {
              nextYear++;
            }
            return DateTime(nextYear, 2, 29);
          } else {
            return DateTime(currentDateOnly.year + 1, currentDateOnly.month,
                currentDateOnly.day);
          }
        default:
          print('Unknown recurrence rule: $rule');
          return null;
      }
    } catch (e) {
      print('Error calculating next due date for rule $rule: $e');
      return null;
    }
  }

  // Удаление задачи (добавим удаление ссылок И ПОДЗАДАЧ)
  Future<void> deleteTask(String taskId, {bool deleteSubtasks = true}) async {
    // Добавляем флаг
    if (_userId == null) throw Exception('User not authenticated');

    // --- Рекурсивное удаление подзадач (если флаг установлен) ---
    if (deleteSubtasks) {
      print('Deleting subtasks for task $taskId...');
      final subtasks = await fetchSubtasks(taskId);
      for (final subtask in subtasks) {
        // Рекурсивно вызываем удаление для подзадачи
        // Передаем deleteSubtasks = true, чтобы удалить и их подзадачи
        await deleteTask(subtask.id, deleteSubtasks: true);
      }
      print('Finished deleting subtasks for task $taskId.');
    }
    // --- Конец рекурсивного удаления ---

    // 1. Удаляем ссылки (из Supabase)
    try {
      await _ref
          .read(linkRepositoryProvider)
          .deleteLinksFromSource(LinkEntityType.task, taskId);
    } catch (e) {
      print('Error deleting links for task $taskId: $e');
      // Продолжаем
    }

    try {
      // 2. Удаляем из Supabase
      await _client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', _userId);

      // 3. Удаляем из локальной БД
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
      print('Deleted task $taskId from local DB');
    } on PostgrestException catch (error) {
      // TODO: Rollback link deletion?
      print('Error deleting task: ${error.message}');
      // Throw specific exception
      throw TaskDeleteException('Failed to delete task from database.', error);
    } catch (error) {
      print('Unexpected error deleting task: $error');
      // Throw specific exception
      throw TaskDeleteException('An unexpected error occurred.', error);
    }
  }

  // Поиск задачи по точному названию для текущего пользователя
  Future<Task?> findTaskByTitle(String title) async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', _userId)
          .eq('title', title)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return Task.fromJson(response);
    } on PostgrestException catch (error) {
      print('Error finding task by title \'$title\': ${error.message}');
      return null;
    } catch (error) {
      print('Unexpected error finding task by title \'$title\': $error');
      return null;
    }
  }

  // Поиск задач (улучшенный, с FTS по названию через RPC)
  Future<List<Task>> searchTasks(String query) async {
    if (_userId == null || query.isEmpty) return [];

    final searchQuery = query.trim();
    if (searchQuery.isEmpty) return [];

    try {
      // --- Локальный поиск (остается по contains) ---
      final localQuery = _db.select(_db.tasks)
        ..where((t) => t.userId.equals(_userId))
        ..where((t) => t.title.contains(query));
      final List<TaskEntry> localEntries = await localQuery.get();

      if (localEntries.isNotEmpty) {
        print(
            'Found ${localEntries.length} tasks locally matching \'$query\' (title contains)');
        return localEntries.map(_mapEntryToModel).toList();
      }

      // --- Поиск в Supabase (ИСПОЛЬЗУЕМ FTS через RPC) ---
      print(
          'Searching tasks in Supabase for \'$searchQuery\' (FTS RPC title)...');
      final response =
          await _client.rpc('search_tasks_fts', // Название созданной функции
              params: {
            // Параметры функции
            'search_query': searchQuery,
            'user_uuid': _userId
          });

      // Обработка ответа RPC
      if (response == null) {
        print('RPC search_tasks_fts returned null');
        return [];
      }

      // response должен быть списком JSON объектов (задач)
      final List<dynamic> data = response as List<dynamic>;
      final List<Task> tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
      print(
          'Found ${tasks.length} tasks in Supabase matching \'$searchQuery\' (FTS RPC title)');

      return tasks;
    } on PostgrestException catch (error) {
      // Ошибка может прийти и от RPC
      print(
          'Error searching tasks (FTS RPC) for \'$searchQuery\': ${error.message}');
      return [];
    } catch (error) {
      print(
          'Unexpected error searching tasks (FTS RPC) for \'$searchQuery\': $error');
      return [];
    }
  }

  // Получение одной задачи по ID
  Future<Task?> getTaskById(String taskId) async {
    if (_userId == null) return null;

    // 1. Проверяем локальную БД
    TaskEntry? localEntry; // Объявляем заранее
    try {
      // getSingleOrNull вернет TaskEntry?
      localEntry = await (_db.select(_db.tasks)
            ..where((t) => t.id.equals(taskId)))
          .getSingleOrNull();
      if (localEntry != null) {
        print('Fetched task $taskId from local DB');
        return _mapEntryToModel(
            localEntry); // localEntry теперь точно TaskEntry
      }
    } catch (e) {
      print('Error fetching task $taskId from local DB: $e');
      // Продолжаем, чтобы попробовать из Supabase
    }

    // 2. Если нет локально, получаем из Supabase
    try {
      print('Fetching task $taskId from Supabase...');
      final response = await _client
          .from('tasks')
          .select()
          .eq('id', taskId)
          .eq('user_id',
              _userId) // Убедимся, что задача принадлежит пользователю
          .maybeSingle(); // Используем maybeSingle, так как задачи может не быть

      if (response == null) {
        print('Task $taskId not found in Supabase');
        return null;
      }

      final task = Task.fromJson(response);

      // Кэшируем в локальной БД
      try {
        await _db.into(_db.tasks).insert(_mapModelToCompanion(task),
            mode: InsertMode.insertOrReplace);
        print('Cached task $taskId to local DB');
      } catch (dbError) {
        print('Error caching task $taskId to local DB: $dbError');
      }

      return task;
    } on PostgrestException catch (error) {
      print('Error fetching task $taskId from Supabase: ${error.message}');
      return null;
    } catch (error) {
      print('Unexpected error fetching task $taskId: $error');
      return null;
    }
  }

  // Получение задач на СЕГОДНЯ
  Future<List<Task>> fetchTasksDueToday() async {
    if (_userId == null) return [];
    final todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Пытаемся из локальной БД
    try {
      final query = _db.select(_db.tasks)
        ..where((t) => t.userId.equals(_userId))
        ..where((t) => t.dueDate.isNotNull())
        ..where((t) =>
            t.dueDate.isBiggerOrEqualValue(todayStart) &
            t.dueDate.isSmallerThanValue(todayEnd))
        ..orderBy([(t) => OrderingTerm(expression: t.isCompleted)])
        ..orderBy([
          (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc)
        ]);
      final List<TaskEntry> localEntries = await query.get();
      if (localEntries.isNotEmpty) {
        print('Fetched tasks due today from local DB');
        return localEntries.map(_mapEntryToModel).toList();
      }
    } catch (e) {
      print('Error fetching tasks due today from local DB: $e');
    }

    // Из Supabase
    print('Fetching tasks due today from Supabase...');
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', _userId)
          .gte('due_date', todayStart.toIso8601String())
          .lt('due_date', todayEnd.toIso8601String())
          .order('is_completed', ascending: true) // Сначала невыполненные
          .order('priority', ascending: false); // Потом по приоритету

      final List<dynamic> data = response as List<dynamic>;
      final List<Task> tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
      // Кэшируем?
      // await _cacheTasks(tasks, 'due today');
      return tasks;
    } catch (e) {
      print('Error fetching tasks due today from Supabase: $e');
      return [];
    }
  }

  // Получение ПРОСРОЧЕННЫХ задач
  Future<List<Task>> fetchOverdueTasks() async {
    if (_userId == null) return [];
    final todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Пытаемся из локальной БД
    try {
      final query = _db.select(_db.tasks)
        ..where((t) => t.userId.equals(_userId))
        ..where((t) => t.isCompleted.equals(false))
        ..where((t) => t.dueDate.isNotNull())
        ..where((t) => t.dueDate.isSmallerThanValue(todayStart))
        ..orderBy([
          (t) => OrderingTerm(expression: t.dueDate)
        ]); // Сначала самые старые
      final List<TaskEntry> localEntries = await query.get();
      if (localEntries.isNotEmpty) {
        print('Fetched overdue tasks from local DB');
        return localEntries.map(_mapEntryToModel).toList();
      }
    } catch (e) {
      print('Error fetching overdue tasks from local DB: $e');
    }

    // Из Supabase
    print('Fetching overdue tasks from Supabase...');
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', _userId)
          .eq('is_completed', false)
          .lt('due_date', todayStart.toIso8601String())
          .order('due_date', ascending: true); // Сначала самые старые

      final List<dynamic> data = response as List<dynamic>;
      final List<Task> tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
      // await _cacheTasks(tasks, 'overdue');
      return tasks;
    } catch (e) {
      print('Error fetching overdue tasks from Supabase: $e');
      return [];
    }
  }

  // Получение ПРЕДСТОЯЩИХ задач (на N дней вперед, исключая сегодня)
  Future<List<Task>> fetchUpcomingTasks({int days = 7}) async {
    if (_userId == null) return [];
    final tomorrowStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            .add(const Duration(days: 1));
    final endDate =
        tomorrowStart.add(Duration(days: days)); // Не включая endDate

    // Пытаемся из локальной БД
    try {
      final query = _db.select(_db.tasks)
        ..where((t) => t.userId.equals(_userId))
        // ..where((t) => t.isCompleted.equals(false)) // Можно показывать и выполненные предстоящие?
        ..where((t) => t.dueDate.isNotNull())
        ..where((t) =>
            t.dueDate.isBiggerOrEqualValue(tomorrowStart) &
            t.dueDate.isSmallerThanValue(endDate))
        ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]) // По дате
        ..orderBy([
          (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc)
        ]); // По приоритету
      final List<TaskEntry> localEntries = await query.get();
      if (localEntries.isNotEmpty) {
        print('Fetched upcoming tasks from local DB');
        return localEntries.map(_mapEntryToModel).toList();
      }
    } catch (e) {
      print('Error fetching upcoming tasks from local DB: $e');
    }

    // Из Supabase
    print('Fetching upcoming tasks from Supabase...');
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', _userId)
          // .eq('is_completed', false) // Показывать и выполненные?
          .gte('due_date', tomorrowStart.toIso8601String())
          .lt('due_date', endDate.toIso8601String())
          .order('due_date', ascending: true)
          .order('priority', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final List<Task> tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();
      // await _cacheTasks(tasks, 'upcoming');
      return tasks;
    } catch (e) {
      print('Error fetching upcoming tasks from Supabase: $e');
      return [];
    }
  }

  // --- Парсинг и обновление ссылок ---
  Future<void> _updateLinksFromDescription(
      String taskId, Object? descriptionJson) async {
    if (_userId == null) return;

    String plainTextDescription = '';
    Document? doc; // Сделаем nullable и уберем late

    if (descriptionJson != null) {
      try {
        if (descriptionJson is String) {
          try {
            final decoded = jsonDecode(descriptionJson);
            if (decoded is List) {
              // Успешно декодировали строку в List, пробуем создать Document
              try {
                doc = Document.fromJson(decoded);
              } catch (docError) {
                print(
                    'Warning: Failed to create Document from decoded List for task $taskId: $docError. Using original string.');
                plainTextDescription =
                    descriptionJson; // Используем исходную строку
              }
            } else {
              // Декодировали, но результат не List. Считаем исходную строку текстом.
              print(
                  'Warning: Decoded JSON is not a List, using original string for task $taskId.');
              plainTextDescription = descriptionJson;
            }
          } catch (jsonError) {
            // Не удалось декодировать JSON, считаем исходную строку текстом.
            print(
                'Warning: Failed to decode JSON string, using original string for task $taskId: $jsonError');
            plainTextDescription = descriptionJson;
          }
        } else if (descriptionJson is List) {
          // descriptionJson уже является списком, пробуем создать Document
          try {
            doc = Document.fromJson(descriptionJson);
          } catch (docError) {
            print(
                'Warning: Failed to create Document from List for task $taskId, attempting toString(): $docError');
            // Пробуем получить текст, соединив элементы списка
            plainTextDescription =
                descriptionJson.map((e) => e.toString()).join('\\n');
          }
        } else {
          // Обрабатываем Map или другие типы - считаем текстом через toString()
          print(
              'Warning: Unsupported descriptionJson type (${descriptionJson.runtimeType}) for task $taskId, using toString().');
          plainTextDescription = descriptionJson.toString();
        }

        // Получаем текст, только если Document был успешно создан
        if (doc != null && plainTextDescription.isEmpty) {
          // Проверяем plainTextDescription, т.к. он мог быть установлен в catch блоках
          plainTextDescription = doc.toPlainText();
        }
      } catch (e) {
        // Ловим другие возможные ошибки (например, от doc.toPlainText())
        print('Error processing description for task $taskId: $e');
        // При ошибке обработки описания, удаляем все старые ссылки
        await _ref
            .read(linkRepositoryProvider)
            .deleteLinksFromSource(LinkEntityType.task, taskId);
        return; // Выходим из метода
      }
    }

    // --- Дальнейшая логика обработки ссылок с использованием plainTextDescription ---
    if (plainTextDescription.isEmpty) {
      // Если описания нет или оно пустое после извлечения текста, удаляем все старые ссылки
      await _ref
          .read(linkRepositoryProvider)
          .deleteLinksFromSource(LinkEntityType.task, taskId);
      return;
    }

    final linkRepo = _ref.read(linkRepositoryProvider);
    final projectRepo = _ref.read(projectRepositoryProvider);
    final noteRepo = _ref.read(dailyNoteRepositoryProvider);

    final taskLinkRegex = RegExp(r'\[\[([^\]]+)\]\]');
    final projectLinkRegex = RegExp(r'@([\w\s-]+)\b');
    final noteLinkRegex = RegExp(r'##(\d{4}-\d{2}-\d{2})\b');

    final Set<Link> currentLinks = {};

    // Ищем ссылки на задачи
    for (final match in taskLinkRegex.allMatches(plainTextDescription)) {
      // Используем plainTextDescription
      final taskName = match.group(1)?.trim();
      if (taskName != null) {
        final targetTask = await findTaskByTitle(taskName);
        if (targetTask != null && targetTask.id != taskId) {
          currentLinks.add(Link(
            id: '',
            userId: _userId,
            sourceType: LinkEntityType.task,
            sourceId: taskId,
            targetType: LinkEntityType.task,
            targetId: targetTask.id,
          ));
        }
      }
    }
    // Ищем ссылки на проекты
    for (final match in projectLinkRegex.allMatches(plainTextDescription)) {
      // Используем plainTextDescription
      final projectName = match.group(1)?.trim();
      if (projectName != null) {
        final targetProject = await projectRepo.findProjectByName(projectName);
        if (targetProject != null) {
          currentLinks.add(Link(
            id: '',
            userId: _userId,
            sourceType: LinkEntityType.task,
            sourceId: taskId,
            targetType: LinkEntityType.project,
            targetId: targetProject.id,
          ));
        }
      }
    }
    // Ищем ссылки на заметки
    for (final match in noteLinkRegex.allMatches(plainTextDescription)) {
      // Используем plainTextDescription
      final dateString = match.group(1);
      if (dateString != null) {
        final targetNote = await noteRepo.findDailyNoteByDateString(dateString);
        if (targetNote != null) {
          currentLinks.add(Link(
            id: '',
            userId: _userId,
            sourceType: LinkEntityType.task,
            sourceId: taskId,
            targetType: LinkEntityType.note,
            targetId: targetNote.id,
          ));
        }
      }
    }

    // --- Синхронизация ссылок ---
    final oldLinks =
        await linkRepo.getLinksFromSource(LinkEntityType.task, taskId);
    final Set<String> oldTargetIds =
        oldLinks.map((l) => '${l.targetType.name}-${l.targetId}').toSet();
    final Set<String> currentTargetIds =
        currentLinks.map((l) => '${l.targetType.name}-${l.targetId}').toSet();

    final linksToAdd = currentLinks
        .where(
            (l) => !oldTargetIds.contains('${l.targetType.name}-${l.targetId}'))
        .toList();
    final linksToDelete = oldLinks
        .where((l) =>
            !currentTargetIds.contains('${l.targetType.name}-${l.targetId}'))
        .toList();

    List<Future> futures = [];
    for (final link in linksToDelete) {
      futures.add(linkRepo.deleteLinkById(link.id));
      print('Deleting link: ${link.id}');
    }
    for (final link in linksToAdd) {
      futures.add(linkRepo.addLink(
          sourceType: link.sourceType,
          sourceId: link.sourceId,
          targetType: link.targetType,
          targetId: link.targetId));
      print(
          'Adding link: ${link.sourceType.name}/${link.sourceId} -> ${link.targetType.name}/${link.targetId}');
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      print('Links updated for task $taskId');
    }
  }

  // --- Конвертеры ---
  Task _mapEntryToModel(TaskEntry entry) {
    Object? descriptionData;
    if (entry.description != null) {
      try {
        descriptionData = jsonDecode(entry.description!);
      } catch (_) {
        descriptionData = entry.description;
      }
    }

    List<String> dependsOn = [];
    if (entry.dependsOn != null) {
      try {
        dependsOn = List<String>.from(jsonDecode(entry.dependsOn!));
      } catch (_) {
        print("Error decoding dependsOn for task ${entry.id}");
      }
    }
    List<String> blocking = [];
    if (entry.blocking != null) {
      try {
        blocking = List<String>.from(jsonDecode(entry.blocking!));
      } catch (_) {
        print("Error decoding blocking for task ${entry.id}");
      }
    }
    // Декодируем теги из JSON строки
    List<String> tags = [];
    if (entry.tags != null) {
      try {
        tags = List<String>.from(jsonDecode(entry.tags!));
      } catch (_) {
        print("Error decoding tags for task ${entry.id}");
      }
    }

    return Task(
      id: entry.id,
      userId: entry.userId,
      projectId: entry.projectId,
      title: entry.title,
      description: descriptionData,
      status: entry.status,
      isCompleted: entry.isCompleted,
      dueDate: entry.dueDate,
      priority: entry.priority,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      dependsOn: dependsOn,
      blocking: blocking,
      parentTaskId: entry.parentTaskId,
      tags: tags,
      recurrenceRule: entry.recurrenceRule,
      reminderTime: entry.reminderTime,
    );
  }

  TasksCompanion _mapModelToCompanion(Task model) {
    String? descriptionText;
    if (model.description != null) {
      try {
        descriptionText = jsonEncode(model.description);
      } catch (_) {
        descriptionText = model.description.toString();
      }
    }

    String? dependsOnJson =
        model.dependsOn.isNotEmpty ? jsonEncode(model.dependsOn) : null;
    String? blockingJson =
        model.blocking.isNotEmpty ? jsonEncode(model.blocking) : null;
    // Кодируем теги в JSON строку
    String? tagsJson = model.tags.isNotEmpty ? jsonEncode(model.tags) : null;

    return TasksCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      projectId: Value(model.projectId),
      title: Value(model.title),
      description: Value(descriptionText),
      status: Value(model.status),
      isCompleted: Value(model.isCompleted),
      dueDate: Value(model.dueDate),
      priority: Value(model.priority),
      dependsOn: Value(dependsOnJson),
      blocking: Value(blockingJson),
      parentTaskId: Value(model.parentTaskId),
      tags: Value(tagsJson),
      recurrenceRule: Value(model.recurrenceRule),
      reminderTime: Value(model.reminderTime),
    );
  }

  // НОВЫЙ МЕТОД: Получение подзадач для задачи
  Future<List<Task>> fetchSubtasks(String parentTaskId) async {
    if (_userId == null) return [];

    // 1. Пробуем получить из локальной БД
    try {
      final query = _db.select(_db.tasks)
        ..where((t) => t.userId.equals(_userId))
        ..where((t) =>
            t.parentTaskId.equals(parentTaskId)) // Фильтр по parentTaskId
        ..orderBy([(t) => OrderingTerm(expression: t.isCompleted)])
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
        ]);
      final List<TaskEntry> localEntries = await query.get();
      if (localEntries.isNotEmpty) {
        print('Fetched subtasks for $parentTaskId from local DB');
        return localEntries.map(_mapEntryToModel).toList();
      }
    } catch (e) {
      print('Error fetching subtasks for $parentTaskId from local DB: $e');
    }

    // 2. Если локально пусто, получаем из Supabase
    print(
        'Local subtasks DB empty, fetching from Supabase for $parentTaskId...');
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', _userId)
          .eq('parent_task_id', parentTaskId) // Фильтр по parent_task_id
          .order('is_completed', ascending: true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final List<Task> tasks = data
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      // Кэшируем в локальной БД
      if (tasks.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.tasks,
            tasks.map(_mapModelToCompanion).toList(),
            mode: InsertMode.insertOrReplace,
          );
        });
        print('Cached ${tasks.length} subtasks for $parentTaskId to local DB');
      }

      return tasks;
    } on PostgrestException catch (error) {
      print(
          'Error fetching subtasks from Supabase for $parentTaskId: ${error.message}');
      throw Exception('Failed to fetch subtasks: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching subtasks for $parentTaskId: $error');
      throw Exception('Unexpected error: $error');
    }
  }
}
