import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../providers/task_providers.dart'; // Нужен для получения задач
import '../../models/task.dart';
import '../../providers/daily_note_providers.dart'; // Нужен для перехода к заметке
import 'package:go_router/go_router.dart'; // Для навигации
// <-- Добавляем импорт
import '../tasks/widgets/task_row.dart'; // Исправляем путь
import '../../models/daily_note.dart'; // Добавляем импорт модели заметки
import '../../services/daily_note_repository.dart'; // Добавляем импорт репозитория заметок

// Провайдер для загрузки ВСЕХ задач пользователя (для маркеров календаря)
// Используем FutureProvider, так как нам не нужно здесь управлять состоянием задач,
// только получить их один раз для отображения маркеров.
// final allTasksProvider = FutureProvider<List<Task>>((ref) async {
//   final taskRepository = ref.watch(taskRepositoryProvider);
//   return taskRepository.fetchTasks(); 
// });

// НОВЫЙ Провайдер для загрузки ВСЕХ заметок пользователя
final allCalendarNotesProvider = FutureProvider<List<DailyNote>>((ref) async {
  final repository = ref.watch(dailyNoteRepositoryProvider);
  // Используем существующий метод, если он загружает все
  // TODO: Убедиться, что fetchAllNotes действительно есть и работает
  return repository.fetchAllNotes(); 
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // Устанавливаем формат по умолчанию twoWeeks
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Функция для получения списка событий (задач) для конкретного дня
  List<Task> _getTasksForDay(DateTime day, List<Task> allTasks) {
    return allTasks.where((task) {
      // Проверка dueDate уже сделана в провайдере tasksWithDueDateProvider,
      // но на всякий случай оставим здесь isSameDay
      return task.dueDate != null && isSameDay(task.dueDate, day);
    }).toList();
  }

  // НОВАЯ Функция для получения заметок дня
  List<DailyNote> _getNotesForDay(DateTime day, List<DailyNote> allNotes) {
     return allNotes.where((note) => isSameDay(note.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ИСПОЛЬЗУЕМ tasksWithDueDateProvider
    final tasksAsync = ref.watch(tasksWithDueDateProvider);
    final allNotesAsync = ref.watch(allCalendarNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        // Добавляем кнопку "Сегодня"
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Сегодня',
            onPressed: () {
              final now = DateTime.now();
              // Проверяем, находимся ли мы уже на текущем месяце/неделе
              if (!isSameDay(_focusedDay, now)) {
                 setState(() {
                   _focusedDay = now;
                   _selectedDay = now; // Также выбираем сегодняшний день
                 });
              }
            },
          ),
        ],
      ),
      body: tasksAsync.when(
         data: (tasksWithDueDate) => allNotesAsync.when(
            data: (allNotes) {
              // Используем tasksWithDueDate для получения задач дня
              final selectedDayTasks = _getTasksForDay(_selectedDay ?? _focusedDay, tasksWithDueDate);

              return Column(
                children: [
                  TableCalendar<Task>(
                    locale: 'ru_RU', // Локализация
                    firstDay: DateTime.utc(2010, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    // Загрузчик событий теперь использует tasksWithDueDate
                    eventLoader: (day) => _getTasksForDay(day, tasksWithDueDate),
                    
                    // Одинарное нажатие - выбор дня для показа задач
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          // Не переходим к заметке при одинарном нажатии
                        });
                      }
                    },
                    
                    // "Двойное" нажатие (долгое) - переход к заметке
                     onDayLongPressed: (selectedDay, focusedDay) {
                       print('Long pressed on $selectedDay'); 
                       // Обновляем выбранную дату в провайдере заметок
                       ref.read(selectedDateProvider.notifier).state = selectedDay;
                       // Переходим к экрану заметки
                       context.go('/notes'); 
                     },

                    onFormatChanged: (format) {
                      // Разрешаем менять формат вручную, если нужно
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: const CalendarStyle(
                      // Стиль маркеров событий
                      markersAlignment: Alignment.bottomCenter, 
                      // todayDecoration: BoxDecoration(
                      //   color: Theme.of(context).colorScheme.primaryContainer,
                      //   shape: BoxShape.circle,
                      // ),
                      // selectedDecoration: BoxDecoration(
                      //   color: Theme.of(context).colorScheme.primary,
                      //   shape: BoxShape.circle,
                      // ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                    ),
                     calendarBuilders: CalendarBuilders(
                       // Кастомный билдер для маркеров
                        markerBuilder: (context, day, tasksFromEventLoader) { // tasksFromEventLoader содержит задачи дня
                           final notes = _getNotesForDay(day, allNotes);
                           bool hasTasks = tasksFromEventLoader.isNotEmpty;
                           bool hasNotes = notes.isNotEmpty;

                           if (hasTasks || hasNotes) {
                             // Рисуем один или два маркера внизу
                             return Positioned(
                               bottom: 5, // Немного поднимем
                               right: 0, 
                               left: 0, 
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   if (hasTasks)
                                      Container(
                                         margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                         width: 5, height: 5,
                                         decoration: BoxDecoration(
                                           shape: BoxShape.circle,
                                           color: Theme.of(context).colorScheme.primary, // Маркер задачи
                                         ),
                                       ),
                                    if (hasNotes)
                                      Container(
                                         margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                         width: 5, height: 5,
                                         decoration: const BoxDecoration(
                                           shape: BoxShape.circle,
                                           color: Colors.amber, // Маркер заметки (другой цвет)
                                         ),
                                       ),
                                 ],
                               ),
                             );
                           }
                           return null;
                         },
                     ),
                  ),
                  const SizedBox(height: 8.0),
                  // --- Список задач для выбранного дня --- 
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                     child: Text(
                       'Задачи на ${DateFormat.yMMMd('ru').format(_selectedDay ?? _focusedDay)}:',
                       style: Theme.of(context).textTheme.titleMedium,
                     ),
                   ),
                   const Divider(),
                  Expanded(
                    child: selectedDayTasks.isEmpty
                       ? const Center(child: Text('На этот день задач нет.', style: TextStyle(color: Colors.grey)))
                       : ListView.separated(
                          itemCount: selectedDayTasks.length,
                          itemBuilder: (context, index) {
                             final task = selectedDayTasks[index];
                             // Используем TaskRow для отображения
                             return TaskRow(task: task);
                           },
                           separatorBuilder: (context, index) => const Divider(height: 1),
                         ),
                  ),
                ],
              );
            },
            // Обработка загрузки/ошибки для заметок
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Ошибка загрузки заметок: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
         // Обработка загрузки/ошибки для tasksAsync
         loading: () => const Center(child: CircularProgressIndicator()),
         error: (error, stack) => Center(
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Text('Ошибка загрузки задач: $error', style: const TextStyle(color: Colors.red)),
            ),
        ),
      ),
    );
  }
} 