import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart'; // Используем cross_file
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p; // Для работы с путями
import 'dart:convert';

import '../database/database.dart'; // Локальная БД
import '../models/attachment.dart'; // Модель данных
import '../services/supabase_client_provider.dart'; // Клиент Supabase
import '../providers/auth_providers.dart'; // Добавляем правильный импорт

// Провайдер для AttachmentRepository
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider);
  final authChanges =
      ref.watch(authStateProvider); // <-- Используем правильное имя
  return AttachmentRepository(client, db, ref,
      userId: authChanges.value?.session?.user.id);
});

const String _bucketName = 'attachments'; // Название бакета в Supabase

class AttachmentRepository {
  final SupabaseClient _client;
  final AppDatabase _db;
  final Ref _ref;
  final String? _userId;

  AttachmentRepository(this._client, this._db, this._ref,
      {required String? userId})
      : _userId = userId;

  // Получение метаданных вложений для задачи
  Future<List<Attachment>> fetchAttachmentsForTask(String taskId) async {
    if (_userId == null) return [];

    // 1. Пробуем из локальной БД
    try {
      final localEntries = await (_db.select(_db.attachments)
            ..where((a) => a.userId.equals(_userId))
            ..where((a) => a.taskId.equals(taskId)))
          .get();
      if (localEntries.isNotEmpty) {
        print('Fetched attachments for task $taskId from local DB');
        final attachments = localEntries.map(_mapEntryToModel).toList();
        return await _fetchDownloadUrls(attachments);
      }
    } catch (e) {
      print('Error fetching attachments for task $taskId from local DB: $e');
    }

    // 2. Если нет локально, читаем метаданные из БД Supabase
    print(
        'Local attachments DB empty for task $taskId, fetching from Supabase...');
    try {
      final response = await _client
          .from('attachments')
          .select()
          .eq('user_id', _userId)
          .eq('task_id', taskId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final List<Attachment> attachments = data
          .map((json) => Attachment.fromJson(json as Map<String, dynamic>))
          .toList();

      // Кэшируем метаданные в локальной БД
      if (attachments.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.attachments,
            attachments.map(_mapModelToCompanion).toList(),
            mode: InsertMode.insertOrReplace,
          );
        });
        print(
            'Cached ${attachments.length} attachments metadata for task $taskId to local DB');
      }
      return await _fetchDownloadUrls(attachments);
    } on PostgrestException catch (error) {
      print(
          'Error fetching attachments metadata from Supabase: ${error.message}');
      throw Exception('Failed to fetch attachments: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching attachments: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Загрузка файла в Supabase Storage и сохранение метаданных
  Future<Attachment> uploadAttachment(String taskId, XFile file) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final fileName = p.basename(file.path);
      final storagePath = '$_userId/$taskId/$fileName';
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;
      final fileExt = p.extension(fileName).toLowerCase();
      final mimeType = file.mimeType ?? _lookupMimeType(fileExt);

      print('Uploading $fileName to $_bucketName/$storagePath...');

      // 1. Загружаем файл в Storage
      await _client.storage.from(_bucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );
      print('File uploaded successfully.');

      // 2. Создаем метаданные
      final attachment = Attachment(
        id: '',
        userId: _userId,
        taskId: taskId,
        fileName: fileName,
        storagePath: storagePath,
        mimeType: mimeType,
        size: fileSize,
        createdAt: null,
      );

      // 3. Сохраняем метаданные в БД Supabase
      final metaData = attachment.toJson();
      metaData.remove('id');
      metaData.remove('created_at');
      metaData.remove('downloadUrl');

      final response =
          await _client.from('attachments').insert(metaData).select().single();
      final newAttachment = Attachment.fromJson(response);

      // 4. Кэшируем метаданные локально
      await _db.into(_db.attachments).insert(
          _mapModelToCompanion(newAttachment),
          mode: InsertMode.replace);
      print('Added attachment metadata ${newAttachment.id} to local DB');

      // 5. Получаем URL и возвращаем модель с ним
      final url = await getDownloadUrl(newAttachment.storagePath);
      return newAttachment.copyWith(downloadUrl: url);
    } on StorageException catch (error) {
      print(
          'Supabase Storage Error: ${error.message} (statusCode: ${error.statusCode})');
      throw Exception('Storage Error (${error.statusCode}): ${error.message}');
    } on PostgrestException catch (error) {
      print('Supabase DB Error saving attachment metadata: ${error.message}');
      throw Exception('DB Error: ${error.message}');
    } catch (error) {
      print('Unexpected error uploading attachment: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Удаление файла из Storage и метаданных из БД
  Future<void> deleteAttachment(Attachment attachment) async {
    if (_userId == null || _userId != attachment.userId)
      throw Exception('Authorization error');

    try {
      print('Deleting file $_bucketName/${attachment.storagePath}...');
      await _client.storage.from(_bucketName).remove([attachment.storagePath]);
      print('File deleted from storage.');

      await _client.from('attachments').delete().eq('id', attachment.id);
      await (_db.delete(_db.attachments)
            ..where((a) => a.id.equals(attachment.id)))
          .go();
      print('Deleted attachment metadata ${attachment.id} from local DB');
    } on StorageException catch (error) {
      if (error.statusCode == '404') {
        print(
            'File already deleted from storage, proceeding to delete metadata...');
      } else {
        print('Supabase Storage Error deleting file: ${error.message}');
        throw Exception('Storage Error: ${error.message}');
      }
      try {
        await _client.from('attachments').delete().eq('id', attachment.id);
        await (_db.delete(_db.attachments)
              ..where((a) => a.id.equals(attachment.id)))
            .go();
      } catch (e) {/* Игнорируем */}
    } on PostgrestException catch (error) {
      print('Supabase DB Error deleting attachment metadata: ${error.message}');
      throw Exception('DB Error: ${error.message}');
    } catch (error) {
      print('Unexpected error deleting attachment: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Получение временной ссылки для скачивания файла
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final response = await _client.storage
          .from(_bucketName)
          .createSignedUrl(storagePath, 60 * 60);
      return response;
    } catch (e) {
      print('Error creating signed URL for $storagePath: $e');
      return null;
    }
  }

  Future<List<Attachment>> _fetchDownloadUrls(
      List<Attachment> attachments) async {
    final List<Attachment> attachmentsWithUrls = [];
    for (final attachment in attachments) {
      final url = await getDownloadUrl(attachment.storagePath);
      attachmentsWithUrls.add(attachment.copyWith(downloadUrl: url));
    }
    return attachmentsWithUrls;
  }

  String _lookupMimeType(String extension) {
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  // --- Конвертеры ---
  Attachment _mapEntryToModel(AttachmentEntry entry) {
    return Attachment(
      id: entry.id,
      userId: entry.userId,
      taskId: entry.taskId,
      projectId: entry.projectId,
      fileName: entry.fileName,
      storagePath: entry.storagePath,
      mimeType: entry.mimeType,
      size: entry.size,
      createdAt: entry.createdAt,
    );
  }

  AttachmentsCompanion _mapModelToCompanion(Attachment model) {
    return AttachmentsCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      taskId: Value(model.taskId),
      projectId: Value(model.projectId),
      fileName: Value(model.fileName),
      storagePath: Value(model.storagePath),
      mimeType: Value(model.mimeType),
      size: Value(model.size),
    );
  }
}

// --- Провайдер для списка вложений задачи ---
// Используем family, чтобы передать taskId
// Используем FutureProvider, так как список обычно загружается один раз при открытии
final attachmentsProvider =
    FutureProvider.family<List<Attachment>, String>((ref, taskId) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.fetchAttachmentsForTask(taskId);
});

// Переиспользуем провайдер из task_repository для отслеживания изменений аутентификации
// Если его там нет, нужно создать здесь или в общем месте
// final supabaseAuthChangesProvider = StreamProvider<AuthState>((ref) { ... });
