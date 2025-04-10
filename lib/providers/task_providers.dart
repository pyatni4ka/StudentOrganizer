import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart'; // Импорт для аннотаций

import '../models/task.dart';
import '../services/task_repository.dart';
import 'project_providers.dart'; // Нужен selectedProjectProvider

part 'task_providers.g.dart'; // Сгенерированный файл

// УДАЛЯЕМ старый tasksProvider, так как будем использовать taskListProvider напрямую
// final tasksProvider = FutureProvider<List<Task>>((ref) async {
//   return ref.watch(taskListProvider.future);
// });

// --- ПРОВАЙДЕРЫ ДАННЫХ ДЛЯ ДАШБОРДА --- 
final tasksDueTodayProvider = FutureProvider.autoDispose<List<Task>>((ref) => 
  ref.watch(taskRepositoryProvider).fetchTasksDueToday());

final overdueTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) => 
  ref.watch(taskRepositoryProvider).fetchOverdueTasks());

final upcomingTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) => 
  ref.watch(taskRepositoryProvider).fetchUpcomingTasks());

// --- НОВЫЙ ПРОВАЙДЕР: Все задачи с датой выполнения для календаря ---
// Не зависит от selectedProjectId, загружает ВСЕ задачи пользователя с dueDate
final tasksWithDueDateProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  // TODO: Оптимизировать? Возможно, репозиторию нужен метод fetchTasksWithDueDate?
  // Пока что получаем все задачи и фильтруем.
  final repository = ref.watch(taskRepositoryProvider);
  // Вызываем fetchTasks без projectId, чтобы получить все задачи пользователя
  final allTasks = await repository.fetchTasks(); 
  return allTasks.where((task) => task.dueDate != null).toList();
});
// ---------------------------------------------------------------------

// AsyncNotifierProvider для управления состоянием задач
@riverpod
class TaskList extends _$TaskList {
  
  // Получаем доступ к репозиторию
  TaskRepository _repository() => ref.watch(taskRepositoryProvider);

  // Метод build теперь зависит от выбранного проекта
  @override
  Future<List<Task>> build() async {
    final selectedProjectId = ref.watch(selectedProjectProvider);
    // Получаем параметры сортировки
    final sortColumn = ref.watch(taskSortColumnProvider);
    final isAscending = ref.watch(taskSortAscendingProvider);

    // --- ИЗМЕНЕНИЕ: Получаем ВСЕ задачи (включая подзадачи) --- 
    // Фильтрация по parentTaskId будет происходить в UI (TaskListScreen)
    final tasks = await _repository().fetchTasks(projectId: selectedProjectId);
    
    // --- УЛУЧШЕНИЕ: Более полная и корректная сортировка --- 
    tasks.sort((a, b) {
      int compareResult = 0;
      
      // 1. Сначала по статусу выполнения (невыполненные выше)
      if (a.isCompleted != b.isCompleted) {
         compareResult = a.isCompleted ? 1 : -1;
      } else {
         // 2. Затем по выбранной колонке
        switch (sortColumn) {
          case TaskSortColumn.createdAt:
             compareResult = (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)); // По убыванию по умолчанию
             break;
          case TaskSortColumn.dueDate:
             // Задачи без срока идут в конце при любом направлении
             if (a.dueDate == null && b.dueDate == null) {
               compareResult = 0;
             } else if (a.dueDate == null) compareResult = 1; // a (без даты) > b (с датой)
             else if (b.dueDate == null) compareResult = -1; // a (с датой) < b (без даты)
             else compareResult = a.dueDate!.compareTo(b.dueDate!); // По возрастанию по умолчанию
             break;
          case TaskSortColumn.priority:
             // Сортируем по индексу enum (high=3 > none=0)
             compareResult = b.priority.index.compareTo(a.priority.index); // По убыванию по умолчанию
             break;
           case TaskSortColumn.title:
             compareResult = a.title.toLowerCase().compareTo(b.title.toLowerCase()); // По возрастанию по умолчанию
             break;
        }
      }
      // Применяем направление сортировки, если compareResult не 0
      // ИЛИ если это основная сортировка по isCompleted
      if (compareResult != 0 || a.isCompleted != b.isCompleted) {
        return isAscending ? compareResult : -compareResult;
      } else {
        // Если по основной колонке равны, вторично сортируем по дате создания (новые выше)
         return (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
      }
    });

    return tasks;
  }

  // Метод для добавления задачи
  Future<Task> addTask(Task task) async {
    // Получаем текущий выбранный проект, чтобы присвоить его задаче
    // если проект не выбран явно при создании задачи.
    final selectedProjectId = ref.read(selectedProjectProvider);
    final taskToAdd = task.projectId == null 
        ? task.copyWith(projectId: selectedProjectId)
        : task;
        
    state = const AsyncValue.loading();
    try {
      // ИСПРАВЛЕНИЕ: Возвращаем результат из репозитория
      final newTask = await _repository().addTask(taskToAdd); 
      ref.invalidateSelf(); 
      await future;
      // После добавления нужно обновить и вид Kanban
      ref.invalidate(tasksByStatusProvider);
      return newTask; // <-- Возвращаем созданную задачу
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow; // Перевыбрасываем для обработки в UI
    }
  }

  // Метод для обновления задачи
  Future<Task> updateTask(Task task) async {
    // Не ставим глобальное состояние загрузки, 
    // чтобы UI мог показывать индикатор у конкретной задачи
    try {
      // ИСПРАВЛЕНИЕ: Возвращаем результат из репозитория
      final updatedTask = await _repository().updateTask(task);
      final previousState = await future;
      state = AsyncValue.data([
        for (final t in previousState)
          if (t.id == updatedTask.id) updatedTask else t,
      ]);
      // Перезагружаем в фоне и обновляем Kanban вид И ДАШБОРД
      ref.invalidateSelf(); 
      ref.invalidate(tasksByStatusProvider); 
      // Инвалидируем провайдеры дашборда
      ref.invalidate(tasksDueTodayProvider);
      ref.invalidate(overdueTasksProvider);
      ref.invalidate(upcomingTasksProvider);
      return updatedTask; // <-- Возвращаем обновленную задачу
    } catch (e) {
       print('Error updating task in provider: $e');
       rethrow; // Перевыбрасываем для обработки в UI
    }
  }

  // Метод для удаления задачи
  Future<void> deleteTask(String taskId, {bool deleteSubtasks = true}) async {
     // Можно показать индикатор в UI перед вызовом
    try {
      await _repository().deleteTask(taskId, deleteSubtasks: deleteSubtasks);
      // Перезагружаем список, чтобы он обновился
      ref.invalidateSelf();
      await future; // Дожидаемся завершения перезагрузки
      // Обновляем Kanban вид
      ref.invalidate(tasksByStatusProvider);
    } catch (e, s) {
       print('Error deleting task in provider: $e\n$s'); // Логируем со стеком
       // НЕ выбрасываем исключение дальше, чтобы не вызывать красный экран.
       // UI обработает ошибку через SnackBar в TaskRow.
       // throw Exception('Ошибка удаления задачи: $e');
    }
  }

  // TODO: Добавить методы updateTask, deleteTask

}

// --- Провайдер для задач, сгруппированных по статусу (для Kanban) ---
@riverpod
class TasksByStatus extends _$TasksByStatus {
  TaskRepository _repository() => ref.watch(taskRepositoryProvider);

  @override
  Future<Map<String, List<Task>>> build() {
    final selectedProjectId = ref.watch(selectedProjectProvider);
    return _repository().fetchTasksByStatus(projectId: selectedProjectId);
  }

  // Метод для изменения статуса задачи (перетаскивание в Kanban)
  Future<void> moveTask(String taskId, String newStatus) async {
    // Не устанавливаем глобальное состояние загрузки, чтобы доска не мерцала
    try {
      // 1. Получаем текущую задачу
      final currentState = state.valueOrNull; // Используем valueOrNull
      Task? taskToMove;
      if (currentState != null) {
        for (final list in currentState.values) {
          try {
             taskToMove = list.firstWhere((t) => t.id == taskId);
             break; // Нашли, выходим из цикла
          } catch (e) {
             // firstWhere выбросил StateError, если не нашел
             continue; // Продолжаем искать в следующем списке
          }
          // taskToMove = list.firstWhere((t) => t.id == taskId, orElse: () => throw StateError('Task not found')); // Старый вариант с orElse
          // if (taskToMove != null) break;
        }
      }

      if (taskToMove == null) {
        print('Task not found in current state for moving');
        ref.invalidateSelf(); // Перезагрузим на всякий случай
        return;
      }
      
      // 2. Оптимистично обновляем UI
      if (currentState != null) {
        final newState = Map<String, List<Task>>.from(currentState);
        // Удаляем из старого списка
        for (var list in newState.values) {
          list.removeWhere((t) => t.id == taskId);
        }
        // Добавляем в новый список
        (newState[newStatus] ??= []).add(taskToMove.copyWith(status: newStatus));
        state = AsyncValue.data(newState);
      }

      // 3. Обновляем задачу в репозитории
      final updatedTask = await _repository().updateTask(taskToMove.copyWith(status: newStatus));
      
      // 4. Обновляем оба провайдера (на случай, если что-то пошло не так или для консистентности)
      ref.invalidateSelf();
      ref.invalidate(taskListProvider);

    } catch (e) {
      print('Error moving task: $e');
      // Откатываем UI или просто перезагружаем
      ref.invalidateSelf(); 
      ref.invalidate(taskListProvider); 
      // TODO: Показать сообщение об ошибке пользователю
    }
  }

  // При добавлении, обновлении, удалении задачи через TaskList провайдер,
  // этот провайдер будет автоматически инвалидирован и перезагрузится.
}

// Провайдер для хранения текущего вида задач (list или kanban)
final taskViewModeProvider = StateProvider<TaskViewMode>((ref) => TaskViewMode.list);

enum TaskViewMode { list, kanban }

// --- Провайдеры для управления сортировкой --- 
enum TaskSortColumn { createdAt, dueDate, priority, title }

final taskSortColumnProvider = StateProvider<TaskSortColumn>((ref) => TaskSortColumn.createdAt);
final taskSortAscendingProvider = StateProvider<bool>((ref) => false); // По умолчанию сортируем по убыванию (новые сверху)

// TODO: Добавить StateNotifierProvider или AsyncNotifierProvider для управления состоянием задач 