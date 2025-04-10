
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/widgets.dart';

import '../models/daily_note.dart';
import '../services/daily_note_repository.dart';
import '../services/project_repository.dart';
import '../services/task_repository.dart';

part 'daily_note_providers.g.dart';

// Провайдер для хранения выбранной даты для ежедневной заметки
final selectedDateProvider = StateProvider<DateTime>((ref) {
  // Инициализируем текущей датой (без времени)
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Провайдер для контроллера Quill, связанного с выбранной датой
// Используем NotifierProvider для управления состоянием контроллера и его зависимостью от DailyNoteNotifier
final dailyNoteQuillControllerProvider = NotifierProvider.autoDispose<QuillControllerNotifier, QuillController>(QuillControllerNotifier.new);

class QuillControllerNotifier extends AutoDisposeNotifier<QuillController> {
  @override
  QuillController build() {
    // Следим за состоянием DailyNoteNotifier
    final noteAsync = ref.watch(dailyNoteNotifierProvider);
    QuillController controller;

    if (noteAsync is AsyncData<DailyNote?> && noteAsync.value?.content != null) {
      try {
        // Ожидаем Map<String, dynamic> с ключом 'ops'
        final Map<String, dynamic> contentMap = noteAsync.value!.content!;
        final List<dynamic>? opsList = contentMap['ops'] as List<dynamic>?; 
        
        if (opsList != null) {
           controller = QuillController(
            document: Document.fromJson(opsList), 
            selection: TextSelection.fromPosition(const TextPosition(offset: 0)),
           );
        } else {
           print('Warning: Could not find or decode \'ops\' list in daily note content map.');
           controller = QuillController.basic();
        }
      } catch (e) {
        print('Error creating QuillController from DB data (expected Map with \'ops\'): $e');
        controller = QuillController.basic();
      }
    } else {
      controller = QuillController.basic();
    }
    
    controller.readOnly = false; 
    
    ref.onDispose(() => controller.dispose()); 
    
    return controller;
  }
  
  // Можно добавить методы для обновления контроллера, если нужно
}

// Возвращаем DailyNoteNotifier
@riverpod
class DailyNoteNotifier extends _$DailyNoteNotifier {

  DailyNoteRepository _repository() => ref.watch(dailyNoteRepositoryProvider);
  ProjectRepository _projectRepo() => ref.watch(projectRepositoryProvider);
  TaskRepository _taskRepo() => ref.watch(taskRepositoryProvider);

  @override
  Future<DailyNote?> build() async {
    final selectedDate = ref.watch(selectedDateProvider);
    return _repository().fetchNoteByDate(selectedDate);
  }

  Future<void> saveNote(QuillController controller) async {
    final selectedDate = ref.read(selectedDateProvider);
    // ... (парсинг ссылок)
    final plainText = controller.document.toPlainText().trim();
    final List<String> taskTitles = _extractLinks(plainText, r'\[(.*?)\]');
    final List<String> projectNames = _extractLinks(plainText, r'@([\w\s-]+)');
    final List<String> dateStrings = _extractLinks(plainText, r'##(\d{4}-\d{2}-\d{2})');
    final Map<String, String?> resolvedTaskIds = {};
    final Map<String, String?> resolvedProjectIds = {};
    await Future.wait(taskTitles.map((title) async {
      final task = await _taskRepo().findTaskByTitle(title);
      resolvedTaskIds[title] = task?.id;
    }));
    await Future.wait(projectNames.map((name) async {
      final project = await _projectRepo().findProjectByName(name);
      resolvedProjectIds[name] = project?.id;
    }));
    // ... (печать результатов)

    final isDocumentEmpty = controller.document.length <= 1 && controller.document.root.children.first.isLast; 
    final deltaOps = controller.document.toDelta().toJson();
    final Map<String, dynamic>? contentToSave = isDocumentEmpty ? null : {'ops': deltaOps};

    try {
      final savedNote = await _repository().upsertNote(selectedDate, contentToSave);
      state = AsyncValue.data(savedNote);
      print('Note for $selectedDate saved successfully.');
      // Инвалидируем FutureProvider списка (allNotesProvider определен в другом файле)
      // ref.invalidate(allNotesProvider);
    } catch (e, s) {
      print('Error saving note for $selectedDate: $e');
      state = AsyncValue.error(e, s);
      throw Exception('Ошибка сохранения заметки: $e');
    }
  }

  // Метод удаления заметки
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository().deleteNoteById(noteId);
      print('Note $noteId deleted via notifier.');
      // Инвалидируем FutureProvider списка (allNotesProvider определен в другом файле)
      // ref.invalidate(allNotesProvider);
    } catch (e) {
      print('Error deleting note $noteId via notifier: $e');
      throw Exception('Ошибка удаления заметки: $e');
    }
  }

  List<String> _extractLinks(String text, String pattern) {
    final regex = RegExp(pattern);
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)?.trim() ?? '').where((link) => link.isNotEmpty).toList();
  }
}

// FutureProvider для списка всех заметок (определен в notes_list_screen.dart)
// final allNotesProvider = ... 