import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart'; // Для стандартных ссылок
// import 'package:flutter_quill/src/models/documents/attribute.dart'; // Импорт для LinkAction/LinkMenuAction
// QuillEditor использует свой LinkMenuAction
import 'dart:convert'; // Импорт для jsonDecode

import '../../providers/daily_note_providers.dart';
import '../../services/task_repository.dart'; // Для поиска задач
import '../../services/project_repository.dart'; // Для поиска проектов
import '../../providers/project_providers.dart'; // Для selectedProjectProvider
import '../tasks/widgets/add_task_sheet.dart'; // Импорт для показа деталей задачи
// <-- Импорт репозитория шаблонов
import 'note_templates_screen.dart'; // <-- Импортируем экран, где определен провайдер
import '../../models/note_template.dart'; // <-- Импорт модели шаблона
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'; // <-- Импорт расширений

class DailyNoteScreen extends ConsumerStatefulWidget {
  const DailyNoteScreen({super.key});

  @override
  ConsumerState<DailyNoteScreen> createState() => _DailyNoteScreenState();
}

class _DailyNoteScreenState extends ConsumerState<DailyNoteScreen> {
  // Состояние для видимости тулбара
  bool _isToolbarVisible = false;

  // TODO: Реализовать сохранение по таймеру или при потере фокуса?
  // bool _isSaving = false;

  // Функция для сохранения заметки
  Future<void> _saveNote() async {
    // setState(() => _isSaving = true);
    final controller = ref.read(dailyNoteQuillControllerProvider);
    try {
      await ref.read(dailyNoteNotifierProvider.notifier).saveNote(controller);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заметка сохранена'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // if (mounted) setState(() => _isSaving = false);
    }
  }

  // Исправляем сигнатуру и возвращаемый тип
  Future<LinkMenuAction> _handleLinkTap(BuildContext context, String linkText, Node node) async {
    print('Tapped link: $linkText');
    final taskMatch = RegExp(r'^\[\[(.*)\]\]$').firstMatch(linkText);
    final projectMatch = RegExp(r'^@([\w\s-]+)$').firstMatch(linkText);
    final noteMatch = RegExp(r'^##(\d{4}-\d{2}-\d{2})$').firstMatch(linkText);

    try {
      if (taskMatch != null) {
        final taskName = taskMatch.group(1)?.trim();
        if (taskName != null) {
          final task = await ref.read(taskRepositoryProvider).findTaskByTitle(taskName);
          if (task != null && context.mounted) {
             print('Navigating to task: ${task.id}');
             showModalBottomSheet(
               context: context,
               isScrollControlled: true, 
               builder: (_) => Padding(
                 padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                 child: AddTaskSheet(taskToEdit: task), // Используем импортированный виджет
               ),
             );
            return LinkMenuAction.none; // Используем none для остановки обработки
          }
        }
      } else if (projectMatch != null) {
        final projectName = projectMatch.group(1)?.trim();
        if (projectName != null) {
          final project = await ref.read(projectRepositoryProvider).findProjectByName(projectName);
          if (project != null && context.mounted) {
             print('Navigating to project: ${project.id}');
             ref.read(selectedProjectProvider.notifier).state = project.id;
             context.go('/tasks'); 
             return LinkMenuAction.none;
          }
        }
      } else if (noteMatch != null) {
        final dateString = noteMatch.group(1);
        final targetDate = DateTime.tryParse(dateString ?? '');
        if (targetDate != null && context.mounted) {
           print('Navigating to note: $dateString');
           ref.read(selectedDateProvider.notifier).state = DateTime(targetDate.year, targetDate.month, targetDate.day);
           return LinkMenuAction.none;
        }
      }
    } catch (e) {
       print('Error handling link tap ($linkText): $e');
       if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Не удалось перейти по ссылке: $e'), backgroundColor: Colors.orange),
          );
       }
       return LinkMenuAction.none;
    }

    // Если не наш паттерн, пытаемся открыть как обычный URL
    final Uri? uri = Uri.tryParse(linkText);
    if (uri != null && await canLaunchUrl(uri)) {
       print('Launching URL: $linkText');
       await launchUrl(uri, mode: LaunchMode.externalApplication);
       return LinkMenuAction.none;
    }

    print('Could not handle link: $linkText');
    return LinkMenuAction.none;
  }

  // --- НОВЫЙ МЕТОД: Показать диалог выбора шаблона --- 
  Future<void> _showApplyTemplateDialog() async {
    final templatesAsync = ref.read(noteTemplatesProvider); // Получаем список шаблонов

    await showDialog(
      context: context,
      builder: (context) => templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const AlertDialog(
              title: Text('Применить шаблон'),
              content: Text('Нет доступных шаблонов. Создайте их в разделе управления шаблонами.'),
              actions: [ TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')) ],
            );
          }
          return SimpleDialog(
            title: const Text('Выберите шаблон'),
            children: templates.map((template) {
              return SimpleDialogOption(
                child: Text(template.title),
                onPressed: () {
                  Navigator.pop(context); // Закрываем диалог выбора
                  _applyTemplate(template); // Применяем шаблон
                },
              );
            }).toList(),
          );
        },
        loading: () => const AlertDialog(title: Text('Загрузка шаблонов...'), content: Center(child: CircularProgressIndicator())), 
        error: (error, stack) => AlertDialog(title: const Text('Ошибка'), content: Text('Не удалось загрузить шаблоны: $error')), 
      ),
    );
  }

  // --- НОВЫЙ МЕТОД: Применить выбранный шаблон --- 
  void _applyTemplate(NoteTemplate template) {
    if (template.content == null) return; 

    try {
      final contentData = template.content; // Уже Object?
      Document templateDocument = Document(); // Пустой по умолчанию
       if (contentData is String) {
          try {
             templateDocument = Document.fromJson(jsonDecode(contentData));
          } catch (e) { /* Ошибка декодирования строки */ print('Error decoding template string content: $e');}
       } else if (contentData is List) {
          try {
             templateDocument = Document.fromJson(contentData);
          } catch (e) { /* Ошибка создания документа из списка */ print('Error creating document from template list content: $e');}
       } else {
          print('Warning: Unknown template content format: ${contentData.runtimeType}');
          return; // Не применяем неизвестный формат
       }

      final controller = ref.read(dailyNoteQuillControllerProvider);

      // ИСПРАВЛЕНИЕ: Заменяем документ контроллера
      controller.document = templateDocument;
      // Опционально: перемещаем курсор в начало
      controller.moveCursorToStart();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Шаблон "${template.title}" применен')),
      );
    } catch (e) {
       print('Error applying template: $e');
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка применения шаблона: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final quillController = ref.watch(dailyNoteQuillControllerProvider);
    final noteState = ref.watch(dailyNoteNotifierProvider);
    final DateFormat headerFormatter = DateFormat.yMMMMd('ru'); // Формат для заголовка

    return Scaffold(
      appBar: AppBar(
        title: Text('Заметка на ${headerFormatter.format(selectedDate)}'),
        actions: [
          // Кнопка календаря для выбора даты
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Выбрать дату',
            onPressed: () => _showCalendarDialog(context, ref, selectedDate),
          ),
          // Кнопка для показа/скрытия тулбара
          IconButton(
            icon: Icon(_isToolbarVisible ? Icons.format_quote : Icons.format_quote_outlined),
            tooltip: _isToolbarVisible ? 'Скрыть панель' : 'Показать панель',
            onPressed: () {
              setState(() {
                _isToolbarVisible = !_isToolbarVisible;
              });
            },
          ),
          // --- НОВАЯ КНОПКА: Применить шаблон --- 
          IconButton(
            icon: const Icon(Icons.file_copy_outlined), // Иконка шаблона
            tooltip: 'Применить шаблон',
            onPressed: _showApplyTemplateDialog,
          ),
          // Кнопка сохранения (можно убрать, если будет автосохранение)
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Сохранить', 
            onPressed: _saveNote, 
          ),
          // TODO: Добавить другие действия (поиск, экспорт?)
        ],
      ),
      body: Column(
        children: [
          // Тулбар Quill (теперь скрываемый)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Visibility(
              visible: _isToolbarVisible,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Чтобы Column занимал только нужное место
                children: [
                   // --- ИЗМЕНЕНИЕ: Используем QuillToolbar --- 
                    QuillToolbar(
                      configurations: QuillToolbarConfigurations(
                        controller: quillController,
                        sharedConfigurations: const QuillSharedConfigurations(locale: Locale('ru')),
                        // Добавляем кнопки расширений
                        embedButtons: FlutterQuillEmbeds.toolbarButtons(
                           showImageButton: false, 
                           showVideoButton: false,
                        ),
                         // Добавляем кастомные кнопки
                        customButtons: [
                          QuillToolbarTableButton(controller: quillController),
                          QuillToolbarSelectHeaderStyleButtonsButton(controller: quillController),
                          QuillToolbarHistoryButton(controller: quillController, isUndo: true),
                          QuillToolbarHistoryButton(controller: quillController, isUndo: false),
                          QuillToolbarToggleStyleButton(
                              attribute: Attribute.codeBlock,
                              controller: quillController,
                              icon: Icons.code,
                              tooltip: 'Блок кода',
                           ),
                          QuillToolbarSearchButton(controller: quillController),
                        ],
                      ),
                    ),
                   const Divider(height: 1),
                ],
              ),
            ),
          ),
          // Редактор Quill
          Expanded(
            child: noteState.when(
              data: (_) => Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: QuillEditor.basic(
                    configurations: QuillEditorConfigurations(
                      controller: quillController,
                      padding: EdgeInsets.zero, 
                      // Добавляем обработчик ссылок
                      linkActionPickerDelegate: _handleLinkTap,
                       // Включаем обработчики для расширений
                      embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                      sharedConfigurations: const QuillSharedConfigurations(
                        locale: Locale('ru'),
                      ),
                    )
                  ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Text('Ошибка загрузки заметки: $error', style: const TextStyle(color: Colors.red)),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Диалог выбора даты
  void _showCalendarDialog(BuildContext context, WidgetRef ref, DateTime currentSelectedDate) {
    DateTime focusedDay = currentSelectedDate;
    DateTime? tempSelectedDay = currentSelectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Используем StatefulBuilder для обновления состояния календаря в диалоге
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Выберите дату заметки'),
              content: SizedBox(
                width: double.maxFinite,
                child: TableCalendar(
                  locale: 'ru_RU',
                  firstDay: DateTime.utc(2010, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(tempSelectedDay, day),
                  onDaySelected: (selectedDay, newFocusedDay) {
                    setDialogState(() { // Обновляем состояние внутри диалога
                      tempSelectedDay = selectedDay;
                      focusedDay = newFocusedDay; // Обновляем фокус для правильной навигации
                    });
                  },
                  onPageChanged: (newFocusedDay) {
                      setDialogState(() {
                           focusedDay = newFocusedDay; // Обновляем фокус при смене месяца/года
                      });
                  },
                  calendarStyle: const CalendarStyle(
                    // TODO: Можно настроить стиль
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    if (tempSelectedDay != null) {
                      // Обновляем выбранную дату в главном провайдере
                      ref.read(selectedDateProvider.notifier).state = tempSelectedDay!;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Выбрать'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 