import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../models/task.dart';
import '../../models/daily_note.dart';
import '../../services/daily_note_repository.dart';
import '../tasks/widgets/task_row.dart';
import '../../providers/daily_note_providers.dart'; // Для selectedDateProvider
import '../../providers/task_providers.dart'; // <-- Добавляем импорт для провайдеров дашборда
import '../tasks/widgets/add_task_sheet.dart'; // Для быстрого создания

// Провайдер для недавних заметок (остается здесь)
final recentNotesProvider = FutureProvider<List<DailyNote>>((ref) async {
  final notes = await ref.watch(dailyNoteRepositoryProvider).fetchAllNotes();
  // Оставляем только несколько последних (например, 5)
  return notes.take(5).toList();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksTodayAsync = ref.watch(tasksDueTodayProvider);
    final overdueTasksAsync = ref.watch(overdueTasksProvider);
    final upcomingTasksAsync = ref.watch(upcomingTasksProvider);
    final recentNotesAsync = ref.watch(recentNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          // Кнопка быстрого создания задачи
          IconButton(
            icon: const Icon(Icons.add_task), 
            tooltip: 'Создать задачу',
            onPressed: () {
               showModalBottomSheet(
                 context: context,
                 isScrollControlled: true, 
                 builder: (_) => Padding(
                   padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                   child: const AddTaskSheet(), // Без параметров
                 ),
               );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
           // Обновляем все провайдеры дашборда
          ref.invalidate(tasksDueTodayProvider);
          ref.invalidate(overdueTasksProvider);
          ref.invalidate(upcomingTasksProvider);
          ref.invalidate(recentNotesProvider);
          // Дожидаемся перезагрузки одного из них (например, задач на сегодня)
          await ref.read(tasksDueTodayProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Секция: Сегодня --- 
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildSectionHeader(context, 'Сегодня', tasksTodayAsync),
                     _buildTaskList(context, tasksTodayAsync, 'Нет задач на сегодня.'),
                  ],
                ),
              ),
            ),
            
            // --- Секция: Просрочено --- 
            Card(
               margin: const EdgeInsets.only(bottom: 16.0),
               // Можно добавить цвет фона или рамки для привлечения внимания
               color: overdueTasksAsync.valueOrNull?.isNotEmpty == true 
                  ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3) 
                  : null,
               child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Просрочено', overdueTasksAsync, isError: true),
                    _buildTaskList(context, overdueTasksAsync, 'Нет просроченных задач.'),
                  ],
                ),
              ),
            ),

            // --- Секция: Скоро (7 дней) --- 
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
               child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Скоро (7 дней)', upcomingTasksAsync),
                    _buildTaskList(context, upcomingTasksAsync, 'Нет предстоящих задач.'),
                  ],
                ),
              ),
            ),

            // --- Секция: Недавние заметки --- 
            Card(
               margin: const EdgeInsets.only(bottom: 16.0),
               child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      _buildSectionHeader(context, 'Недавние заметки', recentNotesAsync),
                      _buildNotesList(context, ref, recentNotesAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Хелпер для заголовка секции (теперь принимает AsyncValue для количества)
  Widget _buildSectionHeader(BuildContext context, String title, AsyncValue<List<dynamic>> asyncValue, {bool isError = false}) {
     // Получаем количество элементов, если данные загружены
    final count = asyncValue.maybeWhen(
       data: (items) => items.length,
       orElse: () => null, // Возвращаем null в других случаях
    );
    final titleText = count != null && count > 0 ? '$title ($count)' : title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        titleText,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: isError && count != null && count > 0 ? Theme.of(context).colorScheme.error : null,
        ),
      ),
    );
  }

  // Хелпер для отображения списка задач
  Widget _buildTaskList(BuildContext context, AsyncValue<List<Task>> asyncValue, String emptyMessage) {
    return asyncValue.when(
      data: (tasks) {
         if (tasks.isEmpty) {
           return Padding(
             padding: const EdgeInsets.symmetric(vertical: 16.0),
             child: Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey))),
           );
         }
         // Используем Column + TaskRow для компактности, без ListView
         return Column(
           children: tasks.map((task) => TaskRow(task: task, isCompact: true)).toList(),
         );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())), 
      error: (err, st) => Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('Ошибка: $err', style: const TextStyle(color: Colors.red)))),
    );
  }

  // Хелпер для отображения списка заметок
  Widget _buildNotesList(BuildContext context, WidgetRef ref, AsyncValue<List<DailyNote>> asyncValue) {
     return asyncValue.when(
      data: (notes) {
         if (notes.isEmpty) {
           return const Padding(
             padding: EdgeInsets.symmetric(vertical: 16.0),
             child: Center(child: Text('Нет недавних заметок.', style: TextStyle(color: Colors.grey))),
           );
         }
         return Column(
           children: notes.map((note) {
             final formattedDate = DateFormat.yMMMd('ru').format(note.date);
             // Просто ListTile, без превью
             return ListTile(
               leading: const Icon(Icons.note_alt_outlined, size: 20),
               title: Text(formattedDate),
               trailing: const Icon(Icons.chevron_right, size: 18),
               dense: true,
               visualDensity: VisualDensity.compact,
               onTap: () {
                  ref.read(selectedDateProvider.notifier).state = note.date;
                  context.go('/notes');
               },
             );
           }).toList(),
         );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())), 
      error: (err, st) => Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('Ошибка: $err', style: const TextStyle(color: Colors.red)))),
    );
  }
} 