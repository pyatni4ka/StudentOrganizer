import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/task.dart';
import '../../../providers/task_providers.dart'; // Импортируем провайдер для действий
import '../../../services/task_repository.dart'; // <-- Добавляем импорт
import 'package:intl/intl.dart'; // Для форматирования даты
import 'add_task_sheet.dart'; // Импортируем AddTaskSheet
import '../../../providers/project_providers.dart'; // Импортируем провайдер проектов
import '../../../models/project.dart'; // Импортируем модель Project

// Провайдер состояния для отслеживания раскрытых задач
final _expandedTaskProvider = StateProvider.family<bool, String>((ref, taskId) => false);
// Провайдер для загрузки подзадач
final subtasksProvider = FutureProvider.family<List<Task>, String>((ref, parentId) async {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return taskRepository.fetchSubtasks(parentId);
});

class TaskRow extends ConsumerWidget {
  final Task task;
  final bool isCompact; // Новый параметр для компактного вида
  final VoidCallback? onTap; // Добавляем параметр onTap
  final int level; // Уровень вложенности (0 для корневых)

  const TaskRow({required this.task, this.isCompact = false, this.onTap, this.level = 0, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsyncValue = ref.watch(projectListProvider);
    final isExpanded = ref.watch(_expandedTaskProvider(task.id));
    final subtasksAsyncValue = ref.watch(subtasksProvider(task.id)); // Следим за подзадачами

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isOverdue = task.dueDate != null &&
                           !task.isCompleted &&
                           task.dueDate!.isBefore(DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0));
    final bool isRecurring = task.recurrenceRule != null;
    final bool hasReminder = task.reminderTime != null; // <-- Проверяем напоминание

    // Уменьшаем отступы и размеры для компактного вида
    final double verticalPadding = isCompact ? 8.0 : 12.0;
    final double horizontalPadding = isCompact ? 12.0 : 16.0;
    final double checkboxPaddingTop = isCompact ? 0 : 1.0;
    final double iconSize = isCompact ? 20 : 22;
    final double priorityIconSize = isCompact ? 16 : 18;
    final double metadataIconSize = isCompact ? 12 : 14;
    final TextStyle? titleStyle = isCompact
        ? textTheme.bodyMedium?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? colorScheme.outline : null,
          )
        : textTheme.bodyLarge?.copyWith(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? colorScheme.outline : null,
          );
    final TextStyle? metadataStyle = (isCompact
        ? textTheme.bodySmall
        : textTheme.bodySmall)
            ?.copyWith(color: colorScheme.outline);

    String? projectName;
    if (task.projectId != null && projectsAsyncValue is AsyncData<List<Project>>) {
      final projects = projectsAsyncValue.value;
      try {
        final project = projects.firstWhere((p) => p.id == task.projectId);
        projectName = project.name;
      } catch (e) {
        projectName = '???';
      }
    }

    final dismissBackground = Container(
      color: Colors.red.withOpacity(0.8),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
    );

    // Отступ слева в зависимости от уровня вложенности
    final double leftPadding = level * 24.0; // 24 пикселя на уровень

    return Column(
      children: [
        Dismissible(
          key: ValueKey(task.id),
          background: dismissBackground,
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            // Показываем диалог подтверждения, особенно если есть подзадачи
            bool deleteConfirmed = true;
             final subtasks = subtasksAsyncValue.asData?.value ?? [];
             if (subtasks.isNotEmpty && context.mounted) {
               deleteConfirmed = await showDialog<bool>(
                 context: context,
                 builder: (BuildContext context) {
                   return AlertDialog(
                     title: const Text('Удалить задачу?'),
                     content: Text('Задача "${task.title}" содержит ${subtasks.length} подзадач. Удалить их тоже?'),
                     actions: <Widget>[
                       TextButton(
                         child: const Text('Отмена'),
                         onPressed: () => Navigator.of(context).pop(false),
                       ),
                       TextButton(
                         child: const Text('Удалить'),
                         onPressed: () => Navigator.of(context).pop(true),
                       ),
                     ],
                   );
                 },
               ) ?? false;
             }
             return deleteConfirmed;
          },
          onDismissed: (direction) async {
            try {
              // Передаем флаг deleteSubtasks (по умолчанию true)
              await ref.read(taskRepositoryProvider).deleteTask(task.id, deleteSubtasks: true); // Используем taskRepositoryProvider
              // Обновляем списки
              ref.invalidate(taskListProvider); 
              ref.invalidate(tasksByStatusProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Задача "${task.title}" и подзадачи удалены')),
                );
              }
            } on TaskDeleteException catch (e) { // Ловим конкретное исключение
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка удаления: ${e.message}'), backgroundColor: Colors.red),
                );
              }
            } catch (e) { // Ловим другие ошибки
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Произошла ошибка при удалении: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
          child: Card(
            elevation: isCompact ? 0 : 1,
            margin: isCompact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: isCompact ? const RoundedRectangleBorder() : null,
            child: InkWell(
              onTap: onTap ?? () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: AddTaskSheet(taskToEdit: task), // TODO: Передать parentTaskId?
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(left: leftPadding + horizontalPadding, right: horizontalPadding, top: verticalPadding, bottom: verticalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox
                    Padding(
                      padding: EdgeInsets.only(top: checkboxPaddingTop),
                      child: IconButton(
                        icon: Icon(
                          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: task.isCompleted ? colorScheme.primary : colorScheme.outline,
                        ),
                        iconSize: iconSize,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: task.isCompleted ? 'Отметить как невыполненную' : 'Отметить как выполненную',
                        onPressed: () async { // <-- Делаем async
                          final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
                          // Добавляем try-catch
                          try {
                            await ref.read(taskRepositoryProvider).updateTask(updatedTask); // Используем taskRepositoryProvider напрямую
                            // Обновляем список через invalidate, чтобы перечитать из БД
                            ref.invalidate(taskListProvider); 
                            ref.invalidate(tasksByStatusProvider);
                            // Показываем SnackBar об успехе (опционально, может быть излишне)
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(content: Text(updatedTask.isCompleted ? 'Задача завершена' : 'Задача возобновлена')),
                            // );
                          } on TaskUpdateException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка обновления: ${e.message}'), backgroundColor: Colors.red),
                                );
                              }
                          } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Произошла ошибка: $e'), backgroundColor: Colors.red),
                                );
                              }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Основной контент
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Приоритет, Заголовок, Кнопка раскрытия
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildPriorityIcon(task.priority, colorScheme, priorityIconSize),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: titleStyle,
                                  maxLines: isCompact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Кнопка раскрытия подзадач
                              subtasksAsyncValue.maybeWhen(
                                data: (subtasks) => subtasks.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                      iconSize: 20,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: isExpanded ? 'Свернуть подзадачи' : 'Развернуть подзадачи',
                                      onPressed: () {
                                        ref.read(_expandedTaskProvider(task.id).notifier).state = !isExpanded;
                                      },
                                    )
                                  : const SizedBox.shrink(), // Нет подзадач - нет кнопки
                                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1)),
                                orElse: () => const SizedBox.shrink(), // Ошибка или нет данных
                              ),
                            ],
                          ),
                          // --- Отображение метаданных, ТЕГОВ и ПОВТОРЕНИЯ --- 
                          if (!isCompact) ...[
                            const SizedBox(height: 4),
                            DefaultTextStyle(
                              style: metadataStyle!, 
                              child: Wrap( 
                                spacing: 8.0, 
                                runSpacing: 4.0, 
                                children: [
                                  // Дата выполнения
                                  if (task.dueDate != null)
                                    _buildMetadataChip(
                                      icon: Icons.calendar_today,
                                      text: DateFormat.MMMd('ru').format(task.dueDate!),
                                      color: isOverdue ? colorScheme.error : colorScheme.outline,
                                      iconSize: metadataIconSize
                                    ),
                                  // Проект
                                  if (projectName != null)
                                    _buildMetadataChip(
                                      icon: Icons.folder_outlined,
                                      text: projectName,
                                      color: colorScheme.outline,
                                      iconSize: metadataIconSize
                                    ),
                                  // Иконка повторения
                                  if (isRecurring) 
                                     _buildMetadataChip(
                                      icon: Icons.repeat,
                                      text: recurrenceOptions[task.recurrenceRule] ?? 'Повтор', // Показываем текст правила
                                      color: colorScheme.outline,
                                      iconSize: metadataIconSize
                                    ),
                                  // Иконка напоминания в полном виде
                                  if (hasReminder)
                                     _buildMetadataChip(
                                       icon: Icons.notifications_active_outlined, 
                                       text: DateFormat.Md('ru').add_Hm().format(task.reminderTime!), 
                                       color: colorScheme.secondary, // Другой цвет для напоминания?
                                       iconSize: metadataIconSize,
                                     ),
                                  // Теги
                                  ...task.tags.map((tag) => 
                                    _buildTagChip(tag, colorScheme)
                                  ),
                                ],
                              ),
                            ),
                          ] else if (task.dueDate != null || projectName != null || task.tags.isNotEmpty || isRecurring || hasReminder) ...[
                             // Компактные иконки метаданных
                            const SizedBox(height: 2),
                             Row(
                               children: [
                                 if (task.dueDate != null) 
                                   Padding(
                                     padding: const EdgeInsets.only(right: 4.0),
                                     child: Icon(Icons.calendar_today, size: metadataIconSize, color: isOverdue ? colorScheme.error : colorScheme.outline),
                                   ),
                                  if (projectName != null)
                                     Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: Icon(Icons.folder_outlined, size: metadataIconSize, color: colorScheme.outline),
                                    ),
                                  if (task.tags.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: Icon(Icons.sell_outlined, size: metadataIconSize, color: colorScheme.outline),
                                    ),
                                  // Иконка повторения в компактном виде
                                  if (isRecurring)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: Icon(Icons.repeat, size: metadataIconSize, color: colorScheme.outline),
                                    ),
                                  // Иконка напоминания в компактном виде
                                  if (hasReminder)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: Icon(Icons.notifications_active_outlined, size: metadataIconSize, color: colorScheme.secondary),
                                    ),
                               ],
                             )
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Отображение подзадач, если раскрыто
        if (isExpanded)
          subtasksAsyncValue.when(
            data: (subtasks) => subtasks.isEmpty
                ? const SizedBox.shrink() // Нет подзадач - ничего не показываем
                : Padding(
                    padding: const EdgeInsets.only(left: 0), // Отступ для подзадач управляется в TaskRow
                    child: ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(), // Отключаем скролл для вложенного списка
                       itemCount: subtasks.length,
                       itemBuilder: (context, index) {
                         final subtask = subtasks[index];
                         // Рекурсивно отображаем TaskRow для подзадачи
                         return TaskRow(
                            task: subtask,
                            isCompact: isCompact,
                            onTap: () { // Передаем onTap для редактирования
                               showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (context) => Padding(
                                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                   child: AddTaskSheet(taskToEdit: subtask, parentTask: task), // Передаем родителя
                                ),
                              );
                            },
                            level: level + 1, // Увеличиваем уровень вложенности
                         );
                       },
                    ),
                  ),
            loading: () => const Padding(
               padding: EdgeInsets.all(16.0),
               child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
               padding: const EdgeInsets.all(16.0),
               child: Center(child: Text('Ошибка загрузки подзадач: $error')),
            ),
          ),
      ],
    );
  }

  // Вспомогательный виджет для иконки приоритета
  Widget _buildPriorityIcon(TaskPriority priority, ColorScheme colorScheme, double size) {
    IconData iconData;
    Color iconColor;
    switch (priority) {
      case TaskPriority.high:
        iconData = Icons.keyboard_arrow_up;
        iconColor = Colors.red;
        break;
      case TaskPriority.medium:
        iconData = Icons.drag_handle; // Или Icons.remove
        iconColor = Colors.orange;
        break;
      case TaskPriority.low:
        iconData = Icons.keyboard_arrow_down;
        iconColor = Colors.blue;
        break;
      case TaskPriority.none:
      default:
        return SizedBox(width: size);
    }
    return Icon(iconData, color: iconColor, size: size);
  }

  // --- НОВЫЕ Виджеты для метаданных и тегов ---
  Widget _buildMetadataChip({required IconData icon, required String text, required Color color, required double iconSize}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color)),
        ],
      );
  }

  Widget _buildTagChip(String tag, ColorScheme colorScheme) {
     // TODO: Добавить кастомный цвет/иконку для тегов (@контекст, #категория)?
     bool isContextTag = tag.startsWith('@');
     IconData tagIcon = isContextTag ? Icons.alternate_email : Icons.sell_outlined; 
     Color chipColor = isContextTag ? colorScheme.secondaryContainer : colorScheme.tertiaryContainer;
     Color textColor = isContextTag ? colorScheme.onSecondaryContainer : colorScheme.onTertiaryContainer;

      return Chip(
        avatar: Icon(tagIcon, size: 12, color: textColor), 
        label: Text(tag),
        labelStyle: TextStyle(fontSize: 11, color: textColor),
        backgroundColor: chipColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
      );
  }
}

// Импортируем опции повторения из AddTaskSheet (или выносим в отдельный файл)
const Map<String?, String> recurrenceOptions = {
  null: 'Нет',
  'daily': 'Ежедневно',
  'weekly': 'Еженедельно',
  'monthly': 'Ежемесячно',
  'yearly': 'Ежегодно',
}; 