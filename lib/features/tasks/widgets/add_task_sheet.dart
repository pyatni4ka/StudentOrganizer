import 'dart:convert'; // Для jsonEncode/Decode
// import 'dart:io'; // <<< Комментируем

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text; // Импорт Quill
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:file_picker/file_picker.dart'; // <-- Импорт file_picker
import 'package:cross_file/cross_file.dart'; // <-- Импорт XFile
import 'package:url_launcher/url_launcher.dart'; // Для стандартных ссылок
import 'package:add_2_calendar/add_2_calendar.dart'; // <-- Раскомментируем импорт
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'; // <-- Раскомментируем импорт
import 'package:path/path.dart' as p; // <-- Импорт path
import 'package:go_router/go_router.dart'; // <-- Импорт go_router

import 'package:student_organizer/models/project.dart'; // Импортируем модель Project
import 'package:student_organizer/models/task.dart'; // Импортируем модель Task
import 'package:student_organizer/providers/project_providers.dart'; // Импортируем провайдер проектов
import 'package:student_organizer/providers/task_providers.dart'; // Импортируем провайдер задач
import 'package:student_organizer/models/link.dart'; // Для BacklinkTarget
import 'package:student_organizer/providers/link_providers.dart'; // Для backlinksProvider
import 'package:student_organizer/services/gemini_service.dart'; // Импортируем Gemini Service
// Импортируем AI Service
import 'package:student_organizer/services/task_repository.dart'; // Для поиска задач по ссылкам
import 'package:student_organizer/services/project_repository.dart'; // Для поиска проектов по ссылкам
// Для поиска заметок по ссылкам
import 'package:student_organizer/providers/daily_note_providers.dart'; // Для selectedDateProvider
import 'package:student_organizer/services/attachment_repository.dart'; // <-- Импорт репо вложений
import 'package:student_organizer/models/attachment.dart'; // <-- Импорт модели вложений
import 'package:student_organizer/services/notification_service.dart'; // <-- Импорт сервиса уведомлений
import 'package:student_organizer/providers/project_provider.dart';

// Определяем опции для выбора времени напоминания
enum ReminderOffset { none, atTime, minutes5, hour1, day1 }

const Map<ReminderOffset, String> reminderOptions = {
  ReminderOffset.none: 'Нет',
  ReminderOffset.atTime: 'В срок',
  ReminderOffset.minutes5: 'За 5 минут',
  ReminderOffset.hour1: 'За 1 час',
  ReminderOffset.day1: 'За 1 день',
};

// Определяем возможные правила повторения для UI
const Map<String?, String> recurrenceOptions = {
  null: 'Нет',
  'daily': 'Ежедневно',
  'weekly': 'Еженедельно',
  'monthly': 'Ежемесячно',
  'yearly': 'Ежегодно',
};

// Провайдер для списка вложений текущей задачи
final taskAttachmentsProvider = FutureProvider.autoDispose
    .family<List<Attachment>, String>((ref, taskId) {
      // Если taskId пустой (новая задача), возвращаем пустой список
      if (taskId.isEmpty) {
        return Future.value([]);
      }
      final repository = ref.watch(attachmentRepositoryProvider);
      return repository.fetchAttachmentsForTask(taskId);
    });

class AddTaskSheet extends ConsumerStatefulWidget {
  final String? initialProjectId;
  final Task? taskToEdit; // Добавляем параметр для редактируемой задачи
  final Task? parentTask; // <-- Добавляем родительскую задачу

  const AddTaskSheet({
    this.initialProjectId,
    this.taskToEdit,
    this.parentTask,
    super.key,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  late QuillController _descriptionController; // Контроллер для Quill
  final _tagsController = TextEditingController(); // <-- Контроллер для тегов
  String? _selectedProjectId; // Выбранный ID проекта
  TaskPriority _selectedPriority = TaskPriority.none;
  DateTime? _selectedDueDate;
  String? _selectedRecurrenceRule;
  bool _addToCalendar = false;
  ReminderOffset? _selectedReminderOffset; // Выбранное смещение для напоминания

  // Состояние для видимости тулбара описания
  bool _isDescriptionToolbarVisible = false;

  // Состояние для AI операций
  bool _isAiSummarizing = false;
  bool _isAiGeneratingSubtasks = false;

  bool _isUploadingFile = false; // <-- Состояние загрузки файла

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    // _isEditing = widget.taskToEdit != null; // Ошибка 'setter not defined'

    if (widget.taskToEdit != null) { // Используем widget.taskToEdit != null напрямую
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _selectedProjectId = task.projectId;
      _selectedPriority = task.priority;
      _selectedDueDate = task.dueDate;
      _tagsController.text = task.tags.join(', '); // Отображаем теги через запятую
      _selectedRecurrenceRule = task.recurrenceRule;
      _selectedReminderOffset = _getReminderOffsetFromTime(task.reminderTime, task.dueDate);
      
      // Инициализация QuillController из description (Object?)
      Object? descriptionData = task.description;
      Document initialDocument = Document(); // Пустой документ по умолчанию
      try {
        if (descriptionData != null) {
          if (descriptionData is String) {
            // Если это строка, пытаемся декодировать как JSON
            try {
              final decoded = jsonDecode(descriptionData);
              initialDocument = Document.fromJson(decoded as List<dynamic>);
            } catch (e) {
              print('Error decoding description string as JSON: $e. Treating as plain text.');
              initialDocument.insert(0, descriptionData);
            }
          } else if (descriptionData is List) {
            // Если это уже List, предполагаем, что это Delta
             initialDocument = Document.fromJson(descriptionData);
          } else {
             print('Warning: Unknown description format in initState: ${descriptionData.runtimeType}. Creating empty document.');
          }
        } 
      } catch (e) {
         print('Error creating document from task description: $e');
         // Оставляем initialDocument пустым
      }
      _descriptionController = QuillController(document: initialDocument, selection: const TextSelection.collapsed(offset: 0));
      // _descriptionController.readOnly = false; // Управляется readOnly в QuillEditor

      // TODO: Загрузить существующие вложения для задачи
      // _attachments = await _fetchAttachments(task.id);
    } else {
      // Создание новой задачи
      _selectedProjectId = widget.initialProjectId;
      _descriptionController = QuillController.basic();
      // _descriptionController.readOnly = false;
      // Теги по умолчанию пустые
    }
    // Эти строки могли быть лишними, т.к. они устанавливаются выше в if (_isEditing)
    // _selectedDueDate = widget.taskToEdit?.dueDate; 
    // _selectedPriority = widget.taskToEdit?.priority ?? TaskPriority.none;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose(); // Не забываем диспозить QuillController
    _tagsController.dispose(); // <-- Не забываем dispose
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    // Делаем метод async
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название задачи'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime? reminderTime = _calculateReminderTime(
      _selectedReminderOffset,
      _selectedDueDate,
    );
    final descriptionJson = _descriptionController.document.toDelta().toJson();
    final tags =
        _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    if (_addToCalendar && _selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите срок выполнения для добавления в календарь.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Показываем индикатор загрузки
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final taskProviderNotifier = ref.read(taskListProvider.notifier);
      Task? savedTask;

      if (_isEditing) {
        final updatedTask = widget.taskToEdit!.copyWith(
          title: title,
          description: descriptionJson,
          dueDate: _selectedDueDate,
          projectId: _selectedProjectId,
          priority: _selectedPriority,
          tags: tags,
          recurrenceRule: _selectedRecurrenceRule,
          reminderTime: reminderTime,
        );
        // Вызываем метод репозитория напрямую (или через провайдер, если он есть)
        savedTask = await ref
            .read(taskRepositoryProvider)
            .updateTask(updatedTask);
      } else {
        final newTask = Task(
          id: '', // ID будет присвоен Supabase
          title: title,
          description: descriptionJson,
          isCompleted: false,
          status: 'backlog',
          dueDate: _selectedDueDate,
          projectId: _selectedProjectId,
          userId: '', // Будет присвоен в репозитории
          priority: _selectedPriority,
          parentTaskId: widget.parentTask?.id,
          tags: tags,
          recurrenceRule: _selectedRecurrenceRule,
          reminderTime: reminderTime,
          createdAt: null,
          updatedAt: null,
        );
        // Вызываем метод репозитория напрямую
        savedTask = await ref.read(taskRepositoryProvider).addTask(newTask);
      }

      // Скрываем индикатор загрузки
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      // --- Планирование/Отмена уведомления (с try-catch) ---
      try {
        _scheduleOrCancelNotification(savedTask);
      } catch (notificationError) {
        print("Error scheduling/canceling notification: $notificationError");
        // Не прерываем основной поток, но можем показать доп. сообщение
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка при настройке уведомления: $notificationError',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      // --------------------------------------

      // Показываем сообщение об успехе и закрываем sheet
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Задача обновлена!' : 'Задача добавлена!',
            ),
          ),
        );

        // Добавление в календарь, если нужно
        if (_addToCalendar && savedTask.dueDate != null) {
          _addEventToCalendar(savedTask);
        }
      }
    } on TaskAddException catch (e) {
      if (context.mounted)
        Navigator.of(context, rootNavigator: true).pop(); // Скрываем индикатор
      print("Error adding task from sheet: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления задачи: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TaskUpdateException catch (e) {
      if (context.mounted)
        Navigator.of(context, rootNavigator: true).pop(); // Скрываем индикатор
      print("Error updating task from sheet: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления задачи: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error, stackTrace) {
      // Ловим любые другие ошибки
      if (context.mounted)
        Navigator.of(context, rootNavigator: true).pop(); // Скрываем индикатор
      print(
        "Unexpected error ${_isEditing ? 'updating' : 'adding'} task from sheet: $error\n$stackTrace",
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Непредвиденная ошибка: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Расчет времени напоминания ---
  DateTime? _calculateReminderTime(ReminderOffset? offset, DateTime? dueDate) {
    if (offset == null || dueDate == null) {
      return null;
    }
    switch (offset) {
      case ReminderOffset.atTime:
        return dueDate;
      case ReminderOffset.minutes5:
        return dueDate.subtract(const Duration(minutes: 5));
      case ReminderOffset.hour1:
        return dueDate.subtract(const Duration(hours: 1));
      case ReminderOffset.day1:
        return dueDate.subtract(const Duration(days: 1));
      case ReminderOffset.none:
        return null; // Никогда не достигнем, но для полноты
    }
  }

  // --- Определение смещения по времени ---
  ReminderOffset _getReminderOffsetFromTime(
    DateTime? reminderTime,
    DateTime? dueDate,
  ) {
    if (reminderTime == null || dueDate == null) return ReminderOffset.none;
    final difference = dueDate.difference(reminderTime);
    if (difference.inMinutes == 0) return ReminderOffset.atTime;
    if (difference.inMinutes == 5) return ReminderOffset.minutes5;
    if (difference.inHours == 1) return ReminderOffset.hour1;
    if (difference.inDays == 1) return ReminderOffset.day1;
    return ReminderOffset.none; // Если не стандартное смещение
  }

  // --- Планирование или отмена уведомления ---
  void _scheduleOrCancelNotification(Task task) {
    final notificationService = ref.read(notificationServiceProvider);
    // Отменяем предыдущее уведомление на всякий случай
    notificationService.cancelNotification(task);
    // Планируем новое, если время задано
    if (task.reminderTime != null) {
      notificationService.scheduleNotification(
        task,
        task.reminderTime!,
        'Напоминание: ${task.title}', // Заголовок
        task.dueDate != null
            ? 'Срок: ${DateFormat.yMd('ru').add_Hm().format(task.dueDate!)}'
            : 'Не забудьте выполнить задачу!', // Тело
      );
    }
  }

  // --- НОВЫЙ МЕТОД: Добавление события в календарь ---
  void _addEventToCalendar(Task task) {
    // Раскомментируем и используем API add_2_calendar ^3.0.1
    final Event event = Event(
      title: task.title,
      description: 'Срок выполнения задачи из Student Organizer',
      location: '',
      startDate: task.dueDate!,
      endDate: task.dueDate!.add(const Duration(hours: 1)),
      iosParams: IOSParams(
        // Используем без const
        reminder: const Duration(minutes: 30),
      ),
      androidParams: AndroidParams(
        // Используем без const
        emailInvites: [],
      ),
    );

    Add2Calendar.addEvent2Cal(event)
        .then((success) {
          if (success && mounted) {
            print('Event added to calendar successfully.');
          }
        })
        .catchError((error) {
          print('Error adding event to calendar: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Не удалось добавить событие в календарь'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
  }

  // TODO: Вспомогательная функция для конвертации recurrenceRule в Recurrence
  // Recurrence? _getRecurrence(Task task) { ... }

  // Метод обработки нажатия на ссылку (адаптирован из DailyNoteScreen)
  Future<LinkMenuAction> _handleLinkTap(
    BuildContext context,
    String linkText,
    Node node,
  ) async {
    print('Tapped link in task description: $linkText');
    final taskMatch = RegExp(r'^\[\[(.*)\]\]$').firstMatch(linkText);
    final projectMatch = RegExp(r'^@([\w\s-]+)$').firstMatch(linkText);
    final noteMatch = RegExp(r'^##(\d{4}-\d{2}-\d{2})$').firstMatch(linkText);

    // Получаем ID текущей редактируемой задачи (если есть), чтобы не ссылаться на себя
    final currentTaskId = widget.taskToEdit?.id;

    try {
      if (taskMatch != null) {
        final taskName = taskMatch.group(1)?.trim();
        if (taskName != null) {
          final task = await ref
              .read(taskRepositoryProvider)
              .findTaskByTitle(taskName);
          // Переходим, только если задача найдена и это НЕ текущая задача
          if (task != null && task.id != currentTaskId && context.mounted) {
            print('Navigating to task: ${task.id}');
            Navigator.pop(context); // Закрываем текущий sheet
            // Показываем новый sheet с деталями найденной задачи
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (_) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: AddTaskSheet(taskToEdit: task),
                  ),
            );
            return LinkMenuAction.none;
          }
        }
      } else if (projectMatch != null) {
        final projectName = projectMatch.group(1)?.trim();
        if (projectName != null) {
          final project = await ref
              .read(projectRepositoryProvider)
              .findProjectByName(projectName);
          if (project != null && context.mounted) {
            print('Navigating to project: ${project.id}');
            Navigator.pop(context); // Закрываем текущий sheet
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
          Navigator.pop(context); // Закрываем текущий sheet
          ref.read(selectedDateProvider.notifier).state = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          );
          context.go('/notes'); // Переходим к экрану заметки
          return LinkMenuAction.none;
        }
      }
    } catch (e) {
      print('Error handling link tap ($linkText): $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось перейти по ссылке: $e'),
            backgroundColor: Colors.orange,
          ),
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

  // --- НОВЫЙ МЕТОД: Выбор и загрузка файла ---
  Future<void> _pickAndUploadFile() async {
    if (!_isEditing) return; // Нельзя прикрепить к несохраненной задаче
    final taskId = widget.taskToEdit!.id;

    setState(() => _isUploadingFile = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        // Используем XFile для совместимости
        final file = XFile(result.files.single.path!);
        print('Picked file: ${file.name}');
        final repo = ref.read(attachmentRepositoryProvider);
        await repo.uploadAttachment(taskId, file);
        // Обновляем список вложений
        ref.invalidate(taskAttachmentsProvider(taskId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Файл успешно загружен')),
          );
        }
      } else {
        // Пользователь отменил выбор
        print('File picking cancelled.');
      }
    } catch (e) {
      print('Error picking/uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки файла: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  // --- НОВЫЙ МЕТОД: Скачивание файла ---
  Future<void> _downloadFile(Attachment attachment) async {
    if (attachment.downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось получить ссылку для скачивания'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final uri = Uri.parse(attachment.downloadUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ); // Открываем в браузере/системе
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть ссылку для скачивания'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- НОВЫЙ МЕТОД: Удаление файла ---
  Future<void> _deleteFile(Attachment attachment) async {
    final taskId = widget.taskToEdit!.id;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Удалить файл?'),
                content: Text(
                  'Вы уверены, что хотите удалить файл "${attachment.fileName}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      try {
        await ref
            .read(attachmentRepositoryProvider)
            .deleteAttachment(attachment);
        ref.invalidate(taskAttachmentsProvider(taskId));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Файл удален')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления файла: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsyncValue = ref.watch(projectListProvider);
    final taskIdForAttachments =
        widget.taskToEdit?.id ?? ''; // Получаем ID для провайдера
    final attachmentsAsync = ref.watch(
      taskAttachmentsProvider(taskIdForAttachments),
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Редактировать задачу' : 'Новая задача',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название задачи *',
                border: OutlineInputBorder(),
              ),
              autofocus: !_isEditing, // Автофокус только при создании
            ),
            const SizedBox(height: 16),

            // Поле описания (Quill)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Описание',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Кнопка для показа/скрытия тулбара
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isDescriptionToolbarVisible
                            ? Icons.format_quote
                            : Icons.format_quote_outlined,
                        size: 20,
                      ),
                      tooltip:
                          _isDescriptionToolbarVisible
                              ? 'Скрыть панель'
                              : 'Показать панель',
                      onPressed: () {
                        setState(() {
                          _isDescriptionToolbarVisible =
                              !_isDescriptionToolbarVisible;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    // Кнопки AI (показываем, если ключ есть и режим редактирования)
                    if (ref.watch(geminiServiceProvider).isAvailable &&
                        _isEditing)
                      Row(
                        mainAxisSize:
                            MainAxisSize.min, // Чтобы не занимали много места
                        children: [
                          // Кнопка Суммаризации
                          IconButton(
                            icon: Icon(
                              Icons.summarize_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            tooltip: 'Суммаризировать описание (AI)',
                            onPressed:
                                _isAiSummarizing
                                    ? null
                                    : _summarizeDescription, // Блокируем при выполнении
                          ),
                          // Кнопка Генерации подзадач
                          IconButton(
                            icon: Icon(
                              Icons.checklist_rtl_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            tooltip: 'Сгенерировать подзадачи (AI)',
                            onPressed:
                                _isAiGeneratingSubtasks
                                    ? null
                                    : _generateSubtasks, // Блокируем при выполнении
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Тулбар Quill (скрываемый)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Visibility(
                      visible: _isDescriptionToolbarVisible,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Комментируем QuillToolbar и Editor из-за проблем с API/URI
                          /* 
                          Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                            QuillToolbar(
                              configurations: const QuillToolbarConfigurations( 
                                sharedConfigurations: QuillSharedConfigurations(locale: Locale('ru')),
                                // ... (закомментированные флаги) ...
                              ),
                            ),
                           const Divider(height: 1),
                         ],
                       ),
                       */
                       const SizedBox(height: 8), // Добавляем отступ вместо редактора
                      // Комментируем QuillEditor
                      /*
                       Expanded(
                         child: Container(
                           decoration: BoxDecoration(
                             border: Border.all(color: Theme.of(context).dividerColor),
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: ConstrainedBox(
                             constraints: const BoxConstraints(maxHeight: 200), 
                             child: QuillEditor.basic(
                               controller: _descriptionController, 
                               readOnly: false, 
                               configurations: const QuillEditorConfigurations( 
                                 embedBuilders: FlutterQuillEmbeds.editorBuilders(), // Закомментировано из-за URI
                                 sharedConfigurations: QuillSharedConfigurations(
                                   locale: Locale('ru'),
                                 ),
                                 padding: const EdgeInsets.all(12), 
                                 linkActionPickerDelegate: _handleLinkTap, 
                               )
                             ),
                           ),
                         ),
                       ),
                      */
                      // Возвращаем временное поле TextFormField
                       TextFormField( 
                         decoration: const InputDecoration(
                           labelText: 'Описание (временно текстом)',
                           hintText: 'Введите описание задачи...',
                           border: OutlineInputBorder(),
                         ),
                         maxLines: 3,
                         initialValue: _descriptionController.document.toPlainText(), // Пытаемся взять текст из Quill
                         onChanged: (text) {
                           // TODO: Обновлять _descriptionController?
                           // Может потребоваться пересоздать Document или использовать
                           // controller.replaceText, но это может быть сложно без Quill UI.
                         },
                       ),
                      const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // <-- Добавляем поле для Тегов -->
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                hintText: 'учеба, важно, @контекст',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Выбор проекта
            projectsAsyncValue.when(
              data:
                  (projects) => DropdownButtonFormField<String?>(
                    value: _selectedProjectId,
                    hint: const Text('Проект (необязательно)'),
                    isExpanded: true, // Растягиваем dropdown
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      // Добавляем опцию "Без проекта"
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Без проекта'),
                      ),
                      // Генерируем пункты для каждого проекта
                      ...projects.map((Project project) {
                        return DropdownMenuItem<String?>(
                          value: project.id,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color:
                                    _parseColor(project.colorHex) ??
                                    Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  project.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProjectId = newValue;
                      });
                    },
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Ошибка загрузки проектов: $err'),
            ),
            const SizedBox(height: 16),

            // Выбор Приоритета и Даты в одной строке
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Выравниваем по верху
              children: [
                // Приоритет (занимает меньше места)
                SizedBox(
                  width: 130, // Фиксированная ширина для приоритета
                  child: DropdownButtonFormField<TaskPriority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Приоритет',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        TaskPriority.values.map((TaskPriority priority) {
                          return DropdownMenuItem<TaskPriority>(
                            value: priority,
                            // TODO: Можно добавить иконки к приоритетам
                            child: Text(priority.name),
                          );
                        }).toList(),
                    onChanged: (TaskPriority? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPriority = newValue;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Дата и Чекбокс календаря (занимают остальное место)
                Expanded(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Чтобы занимало минимум высоты
                    children: [
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Срок выполнения',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDueDate == null
                                    ? 'Не задан'
                                    : DateFormat.yMd('ru').format(
                                      _selectedDueDate!,
                                    ), // Используем локализованный формат
                              ),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // --- Напоминание ---
                      DropdownButtonFormField<ReminderOffset>(
                        value: _selectedReminderOffset,
                        hint: const Text('Напомнить'),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ), // Подгоняем под остальные поля
                        ),
                        isDense: true, // Уменьшаем высоту
                        items:
                            ReminderOffset.values.map((offset) {
                              return DropdownMenuItem<ReminderOffset>(
                                value: offset,
                                child: Text(reminderOptions[offset] ?? ''),
                              );
                            }).toList(),
                        onChanged:
                            _selectedDueDate == null
                                ? null
                                : (ReminderOffset? newValue) {
                                  // Блокируем, если нет даты
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedReminderOffset = newValue;
                                    });
                                  }
                                },
                        disabledHint: const Text(
                          'Сначала укажите срок',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // --- Чекбокс "Добавить в календарь" ---
                      CheckboxListTile(
                        value: _addToCalendar,
                        onChanged:
                            _selectedDueDate == null
                                ? null
                                : (bool? value) {
                                  // Блокируем, если дата не выбрана
                                  setState(() {
                                    _addToCalendar = value ?? false;
                                  });
                                },
                        title: const Text(
                          'Добавить в календарь',
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity:
                            ListTileControlAffinity.leading, // Чекбокс слева
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        enabled:
                            _selectedDueDate !=
                            null, // Активен только если выбрана дата
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- НОВАЯ СЕКЦИЯ: Вложения (только при редактировании) ---
            if (_isEditing)
              _buildAttachmentsSection(context, ref, attachmentsAsync),

            // --- Секция Backlinks (только в режиме редактирования) ---
            if (_isEditing)
              _buildBacklinksSection(
                context,
                ref,
                widget.taskToEdit!,
              ), // Выносим в отдельный метод
            // --- Кнопка Сохранить/Добавить ---
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isEditing ? 'Сохранить изменения' : 'Добавить задачу',
              ),
            ),
            const SizedBox(height: 10), // Отступ снизу для прокрутки
          ],
        ),
      ),
    );
  }

  // --- Метод для построения секции Backlinks ---
  Widget _buildBacklinksSection(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    // Получаем бэклинки для текущей задачи
    final target = BacklinkTarget(LinkEntityType.task, task.id);
    final backlinksAsync = ref.watch(backlinksProvider(target));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        Text(
          'Ссылки на эту задачу:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        backlinksAsync.when(
          data: (links) {
            if (links.isEmpty) {
              return const Text(
                'Нет входящих ссылок.',
                style: TextStyle(color: Colors.grey),
              );
            }
            return ListView.builder(
              shrinkWrap: true, // Важно для ListView внутри Column
              physics:
                  const NeverScrollableScrollPhysics(), // Отключаем прокрутку внутреннего ListView
              itemCount: links.length,
              itemBuilder: (context, index) {
                final linkInfo = links[index];
                // Определяем иконку в зависимости от типа источника
                IconData iconData;
                switch (linkInfo.sourceType) {
                  case LinkEntityType.task:
                    iconData = Icons.task_alt;
                  case LinkEntityType.project:
                    iconData = Icons.topic_outlined;
                  case LinkEntityType.note:
                    iconData = Icons.note_alt_outlined;
                }
                return ListTile(
                  leading: Icon(iconData, size: 20),
                  title: Text(
                    linkInfo.sourceTitleOrDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  dense: true,
                  onTap: () {
                    // TODO: Реализовать навигацию к источнику ссылки
                    print(
                      'Navigate to ${linkInfo.sourceType.name} ${linkInfo.sourceId}',
                    );
                    Navigator.pop(context); // Закрываем текущий sheet
                    // Здесь нужна логика навигации к задаче/проекту/заметке
                  },
                );
              },
            );
          },
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (err, st) => Text(
                'Ошибка загрузки ссылок: $err',
                style: const TextStyle(color: Colors.red),
              ),
        ),
        const SizedBox(height: 20), // Отступ перед кнопкой
      ],
    );
  }

  // --- Методы для вызова AI ---

  // Суммаризация описания
  Future<void> _summarizeDescription() async {
    final descriptionText =
        _descriptionController.document.toPlainText().trim();
    if (descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Описание пустое.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAiSummarizing = true);
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final summary = await geminiService.summarizeText(descriptionText);

      // Показываем результат в диалоге
      if (mounted) {
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Краткое изложение (AI)'),
                content: Text(summary),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка суммаризации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiSummarizing = false);
    }
  }

  // Генерация подзадач
  Future<void> _generateSubtasks() async {
    final descriptionText =
        _descriptionController.document.toPlainText().trim();
    if (descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Описание пустое.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAiGeneratingSubtasks = true);
    try {
      final geminiService = ref.read(geminiServiceProvider);
      final subtasks = await geminiService.generateSubtasks(descriptionText);

      if (subtasks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось сгенерировать подзадачи.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Вставляем подзадачи в конец описания как список
      final currentLength = _descriptionController.document.length;
      _descriptionController.document.insert(
        currentLength - 1,
        '\n\n**Сгенерированные подзадачи:**\n',
      );
      for (final subtask in subtasks) {
        // Вставляем каждый пункт как элемент списка (Quill формат)
        _descriptionController.document.format(
          _descriptionController.document.length - 1,
          0,
          Attribute.clone(Attribute.ul, null),
        ); // Применяем формат списка
        _descriptionController.document.insert(
          _descriptionController.document.length - 1,
          '$subtask\n',
        );
      }
      // Перемещаем курсор в конец
      _descriptionController.moveCursorToEnd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка генерации подзадач: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAiGeneratingSubtasks = false);
    }
  }

  // --- НОВЫЙ МЕТОД: Построение секции вложений ---
  Widget _buildAttachmentsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Attachment>> attachmentsAsync,
  ) {
    // TODO: Добавить поддержку macOS UI для списка и кнопок
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Вложения', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon:
                  _isUploadingFile
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.attach_file),
              tooltip: 'Прикрепить файл',
              onPressed: _isUploadingFile ? null : _pickAndUploadFile,
            ),
          ],
        ),
        const SizedBox(height: 8),
        attachmentsAsync.when(
          data: (attachments) {
            if (attachments.isEmpty) {
              return const Text(
                'Нет прикрепленных файлов.',
                style: TextStyle(color: Colors.grey),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                final icon = _getFileIcon(attachment.fileName);
                // Форматируем размер файла
                final fileSizeFormatted = NumberFormat.compact(
                  locale: 'ru_RU',
                ).format(attachment.size);

                return ListTile(
                  leading: Icon(icon, size: 24),
                  title: Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$fileSizeFormatted - ${DateFormat.yMd('ru').format(attachment.createdAt!)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_outlined, size: 20),
                        tooltip: 'Скачать',
                        onPressed:
                            attachment.downloadUrl == null
                                ? null
                                : () => _downloadFile(attachment),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Удалить',
                        onPressed: () => _deleteFile(attachment),
                      ),
                    ],
                  ),
                  dense: true,
                  // onTap: () => _downloadFile(attachment), // Можно скачивать по тапу
                );
              },
            );
          },
          loading:
              () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          error:
              (err, st) => Text(
                'Ошибка загрузки вложений: $err',
                style: const TextStyle(color: Colors.red),
              ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Вспомогательная функция для иконки файла
  IconData _getFileIcon(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ].contains(extension)) {
      return Icons.image_outlined;
    } else if (extension == '.pdf') {
      return Icons.picture_as_pdf_outlined;
    } else if (['.doc', '.docx'].contains(extension)) {
      return Icons.description_outlined; // Или Icons.article_outlined
    } else if (['.xls', '.xlsx'].contains(extension)) {
      return Icons.table_chart_outlined;
    } else if (['.ppt', '.pptx'].contains(extension)) {
      return Icons.slideshow_outlined;
    } else if (['.zip', '.rar', '.7z'].contains(extension)) {
      return Icons.archive_outlined;
    } else if (['.mp3', '.wav', '.ogg'].contains(extension)) {
      return Icons.audiotrack_outlined;
    } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
      return Icons.video_library_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  // Вспомогательная функция для парсинга цвета (уже есть в AppShell, можно вынести в утилиты)
  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      if (buffer.length == 8) {
        return Color(int.parse(buffer.toString(), radix: 16));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
