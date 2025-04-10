import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart'; // Импортируем модель Task
import '../../providers/task_providers.dart'; // Импортируем провайдер задач
import '../../providers/project_providers.dart'; // Нужен для заголовка и передачи в AddTaskSheet
import '../../models/project.dart'; // Нужен для поиска имени проекта
import 'widgets/task_row.dart'; // Импортируем TaskRow
import 'widgets/add_task_sheet.dart'; // Импортируем виджет для добавления задачи
import 'widgets/task_kanban_board.dart'; // Импортируем Kanban доску
import 'widgets/loading_skeletons.dart'; // <-- Добавляем импорт скелетов

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем текущий режим отображения
    final viewMode = ref.watch(taskViewModeProvider);
    // Смотрим на оба провайдера данных, чтобы UI обновлялся
    final topLevelTasksAsyncValue = ref.watch(taskListProvider);
    final tasksByStatusAsyncValue = ref.watch(tasksByStatusProvider);
    
    final selectedProjectId = ref.watch(selectedProjectProvider);
    // Получаем список проектов для выпадающего меню
    final projectsAsyncValue = ref.watch(projectListProvider);

    // Определяем заголовок AppBar на основе выбранного проекта
    String appBarTitle = 'Все задачи';
    if (selectedProjectId != null) {
       appBarTitle = projectsAsyncValue.maybeWhen(
        data: (projects) {
          final project = projects.firstWhere((p) => p.id == selectedProjectId, 
             orElse: () => const Project(id: '', name: '...', userId: '', status: 'active')
          );
          return project.name;
        },
        orElse: () => 'Загрузка...', // Показываем загрузку, пока проекты не загружены
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Используем Row для заголовка и выпадающего меню
        title: Row(
          mainAxisSize: MainAxisSize.min, // Чтобы Row не занимал всю ширину
          children: [
            Text(appBarTitle),
            // Выпадающее меню для выбора проекта
            projectsAsyncValue.when(
              data: (projects) => PopupMenuButton<String?>(
                icon: const Icon(Icons.arrow_drop_down),
                tooltip: 'Выбрать проект',
                // Текущее значение для начальной подсветки (необязательно)
                // initialValue: selectedProjectId,
                onSelected: (String? projectId) {
                  // Обновляем выбранный проект
                  ref.read(selectedProjectProvider.notifier).state = projectId;
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String?>>[
                    // Пункт "Все задачи"
                    const PopupMenuItem<String?>(
                      value: null, // null соответствует "Всем задачам"
                      child: Text('Все задачи'),
                    ),
                    const PopupMenuDivider(),
                    // Пункты для каждого проекта
                    ...projects.map((Project project) {
                      return PopupMenuItem<String?>(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }),
                  ];
                },
              ),
              // Пока проекты грузятся, показываем заглушку или ничего
              loading: () => const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))), 
              error: (e, s) => IconButton(icon: const Icon(Icons.error_outline, color: Colors.red), onPressed: () {}, tooltip: 'Ошибка загрузки проектов'),
            ),
          ],
        ),
        actions: [
          // --- Кнопка Сортировки --- 
          PopupMenuButton<TaskSortColumn>(
             icon: const Icon(Icons.sort),
             tooltip: 'Сортировка',
             itemBuilder: (BuildContext context) => <PopupMenuEntry<TaskSortColumn>>[
                _buildSortMenuItem(context, ref, TaskSortColumn.createdAt, 'По дате создания'),
                _buildSortMenuItem(context, ref, TaskSortColumn.dueDate, 'По сроку выполнения'),
                _buildSortMenuItem(context, ref, TaskSortColumn.priority, 'По приоритету'),
                _buildSortMenuItem(context, ref, TaskSortColumn.title, 'По названию'),
             ],
             onSelected: (TaskSortColumn result) {
                final currentSortColumn = ref.read(taskSortColumnProvider);
                // Если выбрали ту же колонку, меняем направление сортировки
                if (result == currentSortColumn) {
                  ref.read(taskSortAscendingProvider.notifier).update((state) => !state);
                } else {
                  // Иначе, устанавливаем новую колонку и сбрасываем направление на убывание (по умолчанию)
                  ref.read(taskSortColumnProvider.notifier).state = result;
                  ref.read(taskSortAscendingProvider.notifier).state = false; 
                }
             },
           ),
          // Кнопка переключения вида
          IconButton(
            icon: Icon(viewMode == TaskViewMode.list ? Icons.view_kanban : Icons.view_list),
            tooltip: viewMode == TaskViewMode.list ? 'Вид: Канбан' : 'Вид: Список',
            onPressed: () {
              ref.read(taskViewModeProvider.notifier).state = 
                  viewMode == TaskViewMode.list ? TaskViewMode.kanban : TaskViewMode.list;
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Добавить задачу', 
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, 
                builder: (context) => Padding(
                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: AddTaskSheet(initialProjectId: selectedProjectId, parentTask: null), 
                ),
              );
            },
          ),
        ],
      ),
      body: viewMode == TaskViewMode.list
          ? _buildTaskList(context, ref, topLevelTasksAsyncValue, appBarTitle, selectedProjectId)
          : _buildKanbanBoard(context, ref, tasksByStatusAsyncValue, appBarTitle, selectedProjectId),
    );
  }

  // --- Вспомогательный метод для создания пункта меню сортировки ---
  PopupMenuItem<TaskSortColumn> _buildSortMenuItem(BuildContext context, WidgetRef ref, TaskSortColumn column, String title) {
    final currentSortColumn = ref.watch(taskSortColumnProvider);
    final isAscending = ref.watch(taskSortAscendingProvider);
    final bool isSelected = currentSortColumn == column;

    return PopupMenuItem<TaskSortColumn>(
      value: column,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          if (isSelected)
            Icon(isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
        ],
      ),
    );
  }

  // Вспомогательный метод для отображения списка
  Widget _buildTaskList(BuildContext context, WidgetRef ref, AsyncValue<List<Task>> tasksAsyncValue, String appBarTitle, String? selectedProjectId) {
    return tasksAsyncValue.when(
         data: (tasks) {
           // --- ИЗМЕНЕНИЕ: Фильтруем задачи, оставляя только те, у которых нет родителя --- 
           final topLevelTasks = tasks.where((task) => task.parentTaskId == null).toList();

           if (topLevelTasks.isEmpty) { // Проверяем отфильтрованный список
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Нет задач${selectedProjectId == null ? '' : ' в проекте "$appBarTitle"'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Создать первую задачу'),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, 
                          builder: (context) => Padding(
                             padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                            child: AddTaskSheet(initialProjectId: selectedProjectId, parentTask: null), 
                          ),
                        );
                      },
                    )
                  ],
                ),
              )
            );
          }
          return ListView.builder( // Используем Builder для разделения виджетов
            itemCount: topLevelTasks.length,
            itemBuilder: (context, index) {
              final task = topLevelTasks[index];
              // Передаем level = 0 для задач верхнего уровня
              return TaskRow(task: task, level: 0);
            },
            // separatorBuilder больше не нужен, так как TaskRow теперь Column
            // separatorBuilder: (context, index) => const Divider(height: 1, indent: 56, endIndent: 16),
          );
        },
        loading: () => const TaskListSkeleton(), // <-- Используем скелет списка
        error: (error, stackTrace) => Center(
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column( // Используем Column для текста и кнопки
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ошибка загрузки списка задач: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Обновляем провайдер списка задач
                      ref.invalidate(taskListProvider);
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
        ),
      );
  }

  // Вспомогательный метод для отображения Kanban доски
  Widget _buildKanbanBoard(BuildContext context, WidgetRef ref, AsyncValue<Map<String, List<Task>>> tasksByStatusAsyncValue, String appBarTitle, String? selectedProjectId) {
    return tasksByStatusAsyncValue.when(
      data: (tasksByStatus) {
        // Проверяем, есть ли вообще задачи во всех статусах
        final bool isEmpty = tasksByStatus.values.every((list) => list.isEmpty);
        if (isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Нет задач для Kanban доски${selectedProjectId == null ? '' : ' в проекте "$appBarTitle"'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Создать первую задачу'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, 
                        builder: (context) => Padding(
                           padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                          child: AddTaskSheet(initialProjectId: selectedProjectId, parentTask: null), 
                        ),
                      );
                    },
                  )
                ],
              ),
            )
          );
        }
        // Передаем данные в новый виджет Kanban
        return TaskKanbanBoard(tasksByStatus: tasksByStatus); 
      },
      loading: () => const KanbanBoardSkeleton(), // <-- Используем скелет Kanban
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Используем Column для текста и кнопки
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ошибка загрузки Kanban доски: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Обновляем провайдер задач по статусу
                  ref.invalidate(tasksByStatusProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 