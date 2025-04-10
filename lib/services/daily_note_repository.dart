import 'dart:convert';
import 'package:drift/drift.dart'; // Импорт drift
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Для форматирования даты в строку YYYY-MM-DD

import '../database/database.dart'; // Импорт AppDatabase
import '../models/daily_note.dart';
import '../models/link.dart';
import '../providers/auth_providers.dart'; // <-- Уточняем импорт для supabaseAuthChangesProvider
import 'supabase_client_provider.dart';
import 'link_repository.dart';
import 'project_repository.dart';
import 'task_repository.dart';

// Provider для DailyNoteRepository
final dailyNoteRepositoryProvider = Provider<DailyNoteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider); // Получаем БД
  final authChanges =
      ref.watch(authStateProvider); // <-- Используем правильное имя
  return DailyNoteRepository(client, db, ref,
      userId: authChanges.value?.session?.user.id);
});

class DailyNoteRepository {
  final SupabaseClient _client;
  final AppDatabase _db; // Локальная БД
  final Ref _ref; // Добавляем Ref
  final String? _userId; // Добавляем userId
  final _dateFormat = DateFormat('yyyy-MM-dd'); // Форматер для даты

  // Обновляем конструктор
  DailyNoteRepository(this._client, this._db, this._ref,
      {required String? userId})
      : _userId = userId;

  // --- Конвертеры ---
  DailyNote _mapEntryToModel(DailyNoteEntry entry) {
    Map<String, dynamic>? contentData;
    if (entry.content != null) {
      try {
        // Декодируем JSON-строку из БД в Map
        contentData = jsonDecode(entry.content!) as Map<String, dynamic>;
      } catch (_) {
        print('Error decoding content for note ${entry.id}');
        // Оставляем null или можно попробовать сохранить как строку?
        // contentData = {'error': 'Invalid format', 'raw': entry.content};
      }
    }
    return DailyNote(
      id: entry.id,
      userId: entry.userId,
      // Конвертируем из DateTime (Drift) в DateTime (Модель)
      date: entry.date,
      content: contentData,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  DailyNotesCompanion _mapModelToCompanion(DailyNote model) {
    String? contentText;
    if (model.content != null) {
      try {
        // Сохраняем как JSON-строку
        contentText = jsonEncode(model.content);
      } catch (_) {
        contentText = model.content.toString(); // Запасной вариант
      }
    }
    return DailyNotesCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      // Конвертируем DateTime в строку YYYY-MM-DD для Drift (если тип в Drift TEXT)
      // Или оставляем DateTime, если тип в Drift INTEGER (timestamp) или DATETIME
      // В нашем случае модель использует @DateConverter, который конвертирует в строку,
      // но Drift может ожидать DateTime. Проверим таблицу DailyNotes в database.dart
      // --> Таблица использует date(), значит ожидает DateTime.
      date: Value(model.date),
      content: Value(contentText),
      // createdAt и updatedAt управляются Supabase
    );
  }

  // Получение заметки по дате для текущего пользователя
  Future<DailyNote?> fetchNoteByDate(DateTime date) async {
    if (_userId == null) throw Exception('User not authenticated');
    final dateOnly =
        DateTime(date.year, date.month, date.day); // Используем только дату

    // 1. Пробуем из локальной БД
    final localEntry = await (_db.select(_db.dailyNotes)
          ..where((n) => n.userId.equals(_userId))
          ..where((n) => n.date.equals(dateOnly)) // Сравниваем DateTime
        )
        .getSingleOrNull();

    if (localEntry != null) {
      print('Fetched note for ${dateOnly.toIso8601String()} from local DB');
      return _mapEntryToModel(localEntry);
    }

    // 2. Если нет локально, идем в Supabase
    print(
        'Local note not found, fetching from Supabase for ${dateOnly.toIso8601String()}...');
    final dateString = _dateFormat.format(dateOnly);
    try {
      final response = await _client
          .from('daily_notes')
          .select()
          .eq('user_id', _userId)
          .eq('date', dateString)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final note = DailyNote.fromJson(response);

      // 3. Кэшируем в локальной БД
      await _db
          .into(_db.dailyNotes)
          .insert(_mapModelToCompanion(note), mode: InsertMode.insertOrReplace);
      print('Cached note for ${dateOnly.toIso8601String()} to local DB');

      return note;
    } on PostgrestException catch (error) {
      print('Error fetching daily note for $dateString: ${error.message}');
      throw Exception('Failed to fetch note: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching daily note: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Поиск заметки по строке даты YYYY-MM-DD для текущего пользователя
  // (Аналогично fetchNoteByDate, но принимает строку)
  Future<DailyNote?> findDailyNoteByDateString(String dateString) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Проверка формата даты (опционально, но полезно)
    try {
      _dateFormat.parseStrict(dateString);
    } catch (_) {
      print('Invalid date string format for search: $dateString');
      return null;
    }

    try {
      final response = await _client
          .from('daily_notes')
          .select()
          .eq('user_id', _userId)
          .eq('date', dateString)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return DailyNote.fromJson(response);
    } on PostgrestException catch (error) {
      print('Error finding daily note for $dateString: ${error.message}');
      // Возвращаем null при ошибке поиска
      return null;
    } catch (error) {
      print('Unexpected error finding daily note: $error');
      return null;
    }
  }

  // Создание или обновление заметки (Upsert) с парсингом ссылок
  Future<DailyNote> upsertNote(
      DateTime date, Map<String, dynamic>? content) async {
    if (_userId == null) throw Exception('User not authenticated');
    final dateString = _dateFormat.format(date);
    final dateOnly =
        DateTime(date.year, date.month, date.day); // Для локальной БД

    try {
      // 1. Сохраняем в Supabase
      final response = await _client
          .from('daily_notes')
          .upsert({'user_id': _userId, 'date': dateString, 'content': content})
          .select()
          .single();
      final savedNote = DailyNote.fromJson(response);

      // 2. Сохраняем (Upsert) в локальной БД
      // Drift upsert делается через insert с InsertMode.insertOrReplace
      await _db
          .into(_db.dailyNotes)
          .insert(_mapModelToCompanion(savedNote), mode: InsertMode.replace);
      print(
          'Upserted note for ${savedNote.date.toIso8601String()} in local DB');

      // 3. Парсим контент и обновляем ссылки
      try {
        await _updateLinksFromContent(savedNote.id, savedNote.content);
      } catch (linkError) {
        print(
            'Error updating links after upserting note ${savedNote.id}: $linkError');
      }
      return savedNote;
    } on PostgrestException catch (error) {
      // TODO: Rollback local upsert?
      print('Error upserting daily note for $dateString: ${error.message}');
      throw Exception('Failed to save note: ${error.message}');
    } catch (error) {
      print('Unexpected error upserting daily note: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Поиск заметок по дате или содержимому (упрощенный)
  Future<List<DailyNote>> searchNotes(String query) async {
    if (_userId == null || query.isEmpty) return [];

    // 1. Поиск по дате
    final dateRegex = RegExp(r'^(\d{4}-\d{2}-\d{2})$');
    final dateMatch = dateRegex.firstMatch(query);
    if (dateMatch != null) {
      final date = DateTime.tryParse(dateMatch.group(1)!);
      if (date != null) {
        final note = await fetchNoteByDate(date);
        return note != null ? [note] : [];
      }
    }

    // 2. Поиск по содержимому (ПОКА НЕ РЕАЛИЗОВАН В SUPABASE)
    print(
        'Searching notes by content in Supabase for \'$query\' is not implemented yet.');
    // ---------------------------------------------------------------------------
    // TODO: Реализовать поиск по ПОЛЮ СОДЕРЖИМОГО (content jsonb) в Supabase.
    // Аналогично поиску по описанию задач, это потребует:
    // 1. Использования `->>` / `@@ to_tsquery(...)`.
    // 2. Создания генерируемой колонки tsvector.
    // 3. Создания функции PostgreSQL для извлечения текста из Delta.
    // Пример с полнотекстовым поиском (если колонка content_tsv существует):
    // final response = await _client
    //     .from('daily_notes')
    //     .select()
    //     .eq('user_id', _userId!)
    //     .textSearch('content_tsv', query, config: 'russian')
    //     .order('date', ascending: false);
    // final List<dynamic> data = response as List<dynamic>;
    // return data.map((json) => DailyNote.fromJson(json as Map<String, dynamic>)).toList();
    // ---------------------------------------------------------------------------

    return []; // Возвращаем пустой список для поиска по содержимому

    /* 
    // Предыдущий закомментированный блок с textSearch('content::text', query) 
    // был не совсем корректен и удален для ясности.
    */
  }

  // --- Парсинг и обновление ссылок для заметок ---
  Future<void> _updateLinksFromContent(
      String noteId, Map<String, dynamic>? contentJson) async {
    if (_userId == null) return;

    String plainTextContent = '';
    if (contentJson != null) {
      try {
        if (contentJson is List) {
          Document doc = Document.fromJson(contentJson as List<dynamic>);
          plainTextContent = doc.toPlainText();
        } else {
          print(
              'Warning: DailyNote content is not a List, trying toString(). Content: $contentJson');
          plainTextContent = contentJson.toString();
        }
      } catch (e) {
        print(
            'Error decoding or getting plain text from note content $noteId: $e');
        await _ref
            .read(linkRepositoryProvider)
            .deleteLinksFromSource(LinkEntityType.note, noteId);
        return;
      }
    }

    if (plainTextContent.isEmpty) {
      await _ref
          .read(linkRepositoryProvider)
          .deleteLinksFromSource(LinkEntityType.note, noteId);
      return;
    }

    final linkRepo = _ref.read(linkRepositoryProvider);
    final projectRepo = _ref.read(projectRepositoryProvider);
    final taskRepo = _ref.read(taskRepositoryProvider);
    // DailyNoteRepository сам (this)

    final taskLinkRegex = RegExp(r'\[\[([^\]]+)\]\]');
    final projectLinkRegex = RegExp(r'@([\w\s-]+)\b');
    final noteLinkRegex = RegExp(r'##(\d{4}-\d{2}-\d{2})\b');

    final Set<Link> currentLinks = {};

    // Ищем ссылки на задачи
    for (final match in taskLinkRegex.allMatches(plainTextContent)) {
      final taskName = match.group(1)?.trim();
      if (taskName != null) {
        final targetTask = await taskRepo.findTaskByTitle(taskName);
        if (targetTask != null) {
          currentLinks.add(Link(
            id: '',
            userId: _userId,
            sourceType: LinkEntityType.note,
            sourceId: noteId,
            targetType: LinkEntityType.task,
            targetId: targetTask.id,
          ));
        }
      }
    }
    // Ищем ссылки на проекты
    for (final match in projectLinkRegex.allMatches(plainTextContent)) {
      final projectName = match.group(1)?.trim();
      if (projectName != null) {
        final targetProject = await projectRepo.findProjectByName(projectName);
        if (targetProject != null) {
          currentLinks.add(Link(
            id: '',
            userId: _userId,
            sourceType: LinkEntityType.note,
            sourceId: noteId,
            targetType: LinkEntityType.project,
            targetId: targetProject.id,
          ));
        }
      }
    }
    // Ищем ссылки на заметки
    for (final match in noteLinkRegex.allMatches(plainTextContent)) {
      final dateString = match.group(1);
      if (dateString != null) {
        final targetNote =
            await findDailyNoteByDateString(dateString); // Используем this
        if (targetNote != null && targetNote.id != noteId) {
          // Не ссылаемся на себя
          currentLinks.add(Link(
            id: '',
            userId: _userId,
            sourceType: LinkEntityType.note,
            sourceId: noteId,
            targetType: LinkEntityType.note,
            targetId: targetNote.id,
          ));
        }
      }
    }

    // --- Синхронизация ссылок --- (Аналогично TaskRepository)
    final oldLinks =
        await linkRepo.getLinksFromSource(LinkEntityType.note, noteId);
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
    }
    for (final link in linksToAdd) {
      futures.add(linkRepo.addLink(
          sourceType: link.sourceType,
          sourceId: link.sourceId,
          targetType: link.targetType,
          targetId: link.targetId));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      print('Links updated for note $noteId');
    }
  }

  // Удаление заметки по ID
  Future<void> deleteNoteById(String noteId) async {
    if (_userId == null) throw Exception('User not authenticated');

    // TODO: Удалить связанные ссылки?
    // Зависит от логики: должны ли ссылки на удаленную заметку пропадать.
    // try {
    //   await _ref.read(linkRepositoryProvider).deleteLinksFromSource(LinkEntityType.note, noteId);
    //   await _ref.read(linkRepositoryProvider).deleteLinksToTarget(LinkEntityType.note, noteId);
    // } catch(e) {
    //   print('Error deleting links for note $noteId: $e');
    // }

    try {
      // 1. Удаляем из Supabase
      await _client
          .from('daily_notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', _userId);

      // 2. Удаляем из локальной БД
      await (_db.delete(_db.dailyNotes)..where((n) => n.id.equals(noteId)))
          .go();
      print('Deleted note $noteId from local DB');
    } on PostgrestException catch (error) {
      print('Error deleting note: ${error.message}');
      throw Exception('Failed to delete note: ${error.message}');
    } catch (error) {
      print('Unexpected error deleting note: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Получение ВСЕХ заметок пользователя
  Future<List<DailyNote>> fetchAllNotes() async {
    if (_userId == null) return [];

    // 1. Пробуем из локальной БД
    try {
      final localEntries = await (_db.select(_db.dailyNotes)
            ..where((n) => n.userId.equals(_userId)))
          .get();
      if (localEntries.isNotEmpty) {
        print('Fetched all notes from local DB');
        // Сортируем по дате (новые сначала)
        final notes = localEntries.map(_mapEntryToModel).toList();
        notes.sort((a, b) => b.date.compareTo(a.date));
        return notes;
      }
    } catch (e) {
      print('Error fetching all notes from local DB: $e');
      // Продолжаем, чтобы попробовать из Supabase
    }

    // 2. Если локально пусто, получаем из Supabase
    print('Local notes DB empty or error, fetching all notes from Supabase...');
    try {
      final response = await _client
          .from('daily_notes')
          .select()
          .eq('user_id', _userId)
          .order('date', ascending: false); // Сортируем по дате

      final List<dynamic> data = response as List<dynamic>;
      final List<DailyNote> notes = data
          .map((json) => DailyNote.fromJson(json as Map<String, dynamic>))
          .toList();

      // 3. Кэшируем в локальной БД
      if (notes.isNotEmpty) {
        try {
          await _db.batch((batch) {
            batch.insertAll(
              _db.dailyNotes,
              notes.map(_mapModelToCompanion).toList(),
              mode: InsertMode.insertOrReplace,
            );
          });
          print('Cached ${notes.length} notes to local DB');
        } catch (dbError) {
          print('Error caching all notes to local DB: $dbError');
        }
      }

      return notes;
    } on PostgrestException catch (error) {
      print('Error fetching all notes from Supabase: ${error.message}');
      throw Exception('Failed to fetch all notes: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching all notes: $error');
      throw Exception('Unexpected error: $error');
    }
  }
}
