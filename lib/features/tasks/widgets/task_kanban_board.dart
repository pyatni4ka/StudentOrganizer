import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

import '../../../models/task.dart';
import '../../../providers/task_providers.dart';
import '../../../services/task_repository.dart'; // <-- Импортируем для исключений и провайдера
import 'task_row.dart'; // Используем TaskRow для отображения карточки задачи

class TaskKanbanBoard extends ConsumerStatefulWidget {
  final Map<String, List<Task>> tasksByStatus;

  const TaskKanbanBoard({required this.tasksByStatus, super.key});

  @override
  ConsumerState<TaskKanbanBoard> createState() => _TaskKanbanBoardState();
}

class _TaskKanbanBoardState extends ConsumerState<TaskKanbanBoard> {
  final List<String> _statusOrder = ['backlog', 'todo', 'in_progress', 'done']; 
  
  @override
  void initState() {
    super.initState();
  }

  // Функция для получения читаемого названия статуса
  String _getReadableStatusName(String status) {
    switch (status) {
      case 'backlog': return 'Бэклог';
      case 'todo': return 'К выполнению';
      case 'in_progress': return 'В процессе';
      case 'done': return 'Готово';
      default: return status;
    }
  }

  // Обработчик перетаскивания элемента внутри колонки И МЕЖДУ КОЛОНКАМИ
  _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) async {
    // Получаем текущие списки (которые будут переданы в DragAndDropLists в методе build)
    final lists = _buildDragAndDropLists(context); 

    if (oldListIndex != newListIndex) {
      // Перемещение между колонками
      // Получаем задачу ДО ее удаления из списка (важно для optimistic update, если нужно)
      final taskToMove = (lists[oldListIndex].children[oldItemIndex].child as TaskRow).task;
      final newStatus = _statusOrder[newListIndex];
      print('Task ${taskToMove.id} moving from list $oldListIndex to list $newListIndex (status: $newStatus)');

      // --- Добавляем try-catch для обновления --- 
      try {
          // Создаем обновленную задачу
          final updatedTask = taskToMove.copyWith(status: newStatus);
          // Вызываем репозиторий напрямую
          await ref.read(taskRepositoryProvider).updateTask(updatedTask);
          // Обновляем оба провайдера, так как изменение статуса влияет на оба представления
          ref.invalidate(taskListProvider);
          ref.invalidate(tasksByStatusProvider);
          // Можно показать SnackBar об успехе, но это может быть излишне при drag-n-drop
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Статус задачи "${updatedTask.title}" обновлен')),
          // );
      } on TaskUpdateException catch (e) {
           print('Error moving task ${taskToMove.id}: ${e.message}');
           // Показываем SnackBar об ошибке
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка перемещения: ${e.message}'), backgroundColor: Colors.red),
             );
           }
           // Важно: нужно ли откатить UI? Пакет drag_and_drop_lists не предоставляет
           // легкого способа отменить перемещение после onReorder. 
           // Без optimistic UI update, invalidate должен вернуть все как было до ошибки.
      } catch (e) {
           print('Unexpected error moving task ${taskToMove.id}: $e');
            if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Непредвиденная ошибка: $e'), backgroundColor: Colors.red),
             );
           }
      }
      // -----------------------------------------------

      // Логику ниже убираем, так как обновление происходит через invalidate
      // // Перемещение между колонками
      // final movedItem = lists[oldListIndex].children.removeAt(oldItemIndex);
      // final task = (movedItem.child as TaskRow).task;
      // final newStatus = _statusOrder[newListIndex];
      // print('Task ${task.id} moved from list $oldListIndex to list $newListIndex (status: $newStatus)');
      // ref.read(tasksByStatusProvider.notifier).moveTask(task.id, newStatus);
      // // Не нужно оптимистичное обновление UI здесь, Riverpod обновит виджет
    } else {
      print('Item reordered: $oldItemIndex -> $newItemIndex in list $newListIndex (same list)');
      // TODO: Реализовать изменение порядка внутри колонки (если нужно сохранять порядок)
      // Это потребует добавления поля order/position в Task и логики обновления
    }
    // Не нужен setState(), так как Riverpod управляет состоянием
  }

  // --- НОВЫЙ МЕТОД для построения списков --- 
  List<DragAndDropList> _buildDragAndDropLists(BuildContext context) {
     // Доступ к Theme получаем здесь, в методе, который будет вызван из build
     final theme = Theme.of(context);
     final textTheme = theme.textTheme;
     final colorScheme = theme.colorScheme;

     return _statusOrder.map((status) {
      final tasks = widget.tasksByStatus[status] ?? [];
      return DragAndDropList(
        header: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            _getReadableStatusName(status), 
            style: textTheme.titleMedium,
          ),
        ),
        contentsWhenEmpty: Container(height: 50, alignment: Alignment.center, child: const Text('Нет задач', style: TextStyle(color: Colors.grey))), 
        canDrag: false,
        children: tasks.map((task) => DragAndDropItem(
          child: TaskRow(task: task, isCompact: true),
          canDrag: task.status != 'done',
        )).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<DragAndDropList> lists = _buildDragAndDropLists(context);

    return DragAndDropLists(
      children: lists,
      onItemReorder: _onItemReorder,
      onListReorder: (int oldListIndex, int newListIndex) {
         print('Attempted to reorder lists: $oldListIndex -> $newListIndex (Not allowed)');
      },
      onItemDraggingChanged: (DragAndDropItem? item, bool isDragging) {
        // ...
      },
      itemGhost: Builder(
         builder: (context) {
           return const Material(
              elevation: 4.0,
              child: Card(
                 child: Padding(padding: EdgeInsets.all(8.0), child: Text("Задача..."))
               ), 
            );
         }
      ),
       itemGhostOpacity: 1.0,
      itemDraggingWidth: 250,
      listPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      itemDivider: const SizedBox(height: 4),
      listInnerDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      lastListTargetSize: 40,
      listDragHandle: null,
      listTarget: null,
    );
  }
} 