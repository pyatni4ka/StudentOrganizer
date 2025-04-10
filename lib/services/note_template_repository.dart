import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart';
import '../models/note_template.dart';
import '../services/supabase_client_provider.dart';
import 'task_repository.dart';

// Провайдер для NoteTemplateRepository
final noteTemplateRepositoryProvider = Provider<NoteTemplateRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider);
  final authChanges = ref.watch(supabaseAuthChangesProvider); // Используем общий провайдер аутентификации
  return NoteTemplateRepository(client, db, ref, userId: authChanges.value?.session?.user.id);
});

class NoteTemplateRepository {
  final SupabaseClient _client;
  final AppDatabase _db;
  final Ref _ref;
  final String? _userId;

  NoteTemplateRepository(this._client, this._db, this._ref, {required String? userId}) : _userId = userId;

  // Получение всех шаблонов для текущего пользователя
  Future<List<NoteTemplate>> fetchTemplates() async {
    if (_userId == null) return [];

    // 1. Пробуем из локальной БД
    try {
       final localEntries = await (_db.select(_db.noteTemplates)..where((t) => t.userId.equals(_userId))).get();
       if (localEntries.isNotEmpty) {
         print('Fetched note templates from local DB');
         return localEntries.map(_mapEntryToModel).toList();
       }
    } catch (e) {
       print('Error fetching note templates from local DB: $e');
    }

    // 2. Если локально пусто, получаем из Supabase
    print('Local note templates DB empty, fetching from Supabase...');
    try {
      final response = await _client
          .from('note_templates')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: true);
      final List<dynamic> data = response as List<dynamic>;
      final templates = data.map((json) => NoteTemplate.fromJson(json as Map<String, dynamic>)).toList();

      // 3. Кэшируем в локальной БД
      if (templates.isNotEmpty) {
         await _db.batch((batch) {
           batch.insertAll(
             _db.noteTemplates,
             templates.map(_mapModelToCompanion).toList(),
             mode: InsertMode.insertOrReplace,
           );
         });
         print('Cached ${templates.length} note templates to local DB');
      }
      return templates;

    } on PostgrestException catch (error) {
      print('Error fetching note templates from Supabase: ${error.message}');
      throw Exception('Failed to fetch templates: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching templates: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Добавление нового шаблона
  Future<NoteTemplate> addTemplate(NoteTemplate template) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final templateData = template.toJson()..['user_id'] = _userId;
      templateData.remove('id'); templateData.remove('created_at'); templateData.remove('updated_at');
      // content уже должен быть Object? (JSON List)

      final response = await _client.from('note_templates').insert(templateData).select().single();
      final newTemplate = NoteTemplate.fromJson(response);

      await _db.into(_db.noteTemplates).insert(_mapModelToCompanion(newTemplate), mode: InsertMode.replace);
      print('Added note template ${newTemplate.id} to local DB');
      return newTemplate;
    } on PostgrestException catch (error) {
      print('Error adding note template: ${error.message}');
      throw Exception('Failed to add template: ${error.message}');
    } catch (error) {
      print('Unexpected error adding template: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Обновление шаблона
  Future<NoteTemplate> updateTemplate(NoteTemplate template) async {
    if (_userId == null || _userId != template.userId) throw Exception('Authorization error');

    try {
      final templateData = template.toJson();
      templateData.remove('created_at'); templateData.remove('updated_at');
      templateData.remove('id'); templateData.remove('user_id');

      final response = await _client.from('note_templates').update(templateData)
          .eq('id', template.id).eq('user_id', _userId).select().single();
      final updatedTemplate = NoteTemplate.fromJson(response);

      await (_db.update(_db.noteTemplates)..where((t) => t.id.equals(template.id))).write(_mapModelToCompanion(updatedTemplate));
      print('Updated note template ${template.id} in local DB');
      return updatedTemplate;
    } on PostgrestException catch (error) {
      print('Error updating note template: ${error.message}');
      throw Exception('Failed to update template: ${error.message}');
    } catch (error) {
      print('Unexpected error updating template: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Удаление шаблона
  Future<void> deleteTemplate(String templateId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _client.from('note_templates').delete().eq('id', templateId).eq('user_id', _userId); 
      await (_db.delete(_db.noteTemplates)..where((t) => t.id.equals(templateId))).go();
      print('Deleted note template $templateId from local DB');
    } on PostgrestException catch (error) {
      print('Error deleting note template: ${error.message}');
      throw Exception('Failed to delete template: ${error.message}');
    } catch (error) {
      print('Unexpected error deleting template: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // --- Конвертеры --- 
  NoteTemplate _mapEntryToModel(NoteTemplateEntry entry) {
    Object? contentData;
    if (entry.content != null) {
      try {
        contentData = jsonDecode(entry.content!); 
      } catch (_) {
        contentData = entry.content; 
      }
    }
    return NoteTemplate(
      id: entry.id,
      userId: entry.userId,
      title: entry.title,
      content: contentData,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  NoteTemplatesCompanion _mapModelToCompanion(NoteTemplate model) {
     String? contentText;
     if (model.content != null) {
       try {
         contentText = jsonEncode(model.content); 
       } catch (_) {
         contentText = model.content.toString(); 
       }
     }
    return NoteTemplatesCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      title: Value(model.title),
      content: Value(contentText),
    );
  }
} 