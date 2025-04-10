import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../models/link.dart';
import 'supabase_client_provider.dart';
import 'task_repository.dart'; // Нужен для supabaseAuthChangesProvider

// Provider for the LinkRepository
final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authChanges = ref.watch(supabaseAuthChangesProvider);
  return LinkRepository(client, userId: authChanges.value?.session?.user.id);
});

class LinkRepository {
  final SupabaseClient _client;
  final String? _userId;

  LinkRepository(this._client, {required String? userId}) : _userId = userId;

  // --- Управление ссылками ---

  /// Добавляет одну ссылку.
  Future<Link> addLink({
    required LinkEntityType sourceType,
    required String sourceId,
    required LinkEntityType targetType,
    required String targetId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('links')
          .insert({
            'user_id': _userId,
            'source_type': sourceType.name,
            'source_id': sourceId,
            'target_type': targetType.name,
            'target_id': targetId,
          })
          .select()
          .single();
      return Link.fromJson(response);
    } on PostgrestException catch (e) {
      // Обработка ошибки уникальности (если ссылка уже существует)
      if (e.code == '23505') { // Код ошибки PostgreSQL для unique violation
        // Ссылка уже существует, можно ее найти и вернуть, или просто проигнорировать
        print('Link already exists: $sourceType/$sourceId -> $targetType/$targetId');
        // Попробуем найти существующую
        final existing = await findExistingLink(sourceType: sourceType, sourceId: sourceId, targetType: targetType, targetId: targetId);
        if (existing != null) return existing;
        // Если не нашли (что странно), перевыбрасываем ошибку
      }
      print('Error adding link: ${e.message}');
      throw Exception('Failed to add link: ${e.message}');
    } catch (e) {
      print('Unexpected error adding link: $e');
      throw Exception('Unexpected error adding link: $e');
    }
  }

  /// Удаляет одну ссылку по ее ID.
  Future<void> deleteLinkById(String linkId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('links')
          .delete()
          .eq('id', linkId)
          .eq('user_id', _userId); // Удаляем только свои ссылки
    } on PostgrestException catch (e) {
      print('Error deleting link by ID $linkId: ${e.message}');
      throw Exception('Failed to delete link: ${e.message}');
    } catch (e) {
      print('Unexpected error deleting link by ID $linkId: $e');
      throw Exception('Unexpected error deleting link: $e');
    }
  }

  /// Удаляет все ИСХОДЯЩИЕ ссылки для заданного источника.
  Future<void> deleteLinksFromSource(LinkEntityType sourceType, String sourceId) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('links')
          .delete()
          .eq('user_id', _userId)
          .eq('source_type', sourceType.name)
          .eq('source_id', sourceId);
    } on PostgrestException catch (e) {
      print('Error deleting links from $sourceType/$sourceId: ${e.message}');
      throw Exception('Failed to delete links: ${e.message}');
    } catch (e) {
      print('Unexpected error deleting links from $sourceType/$sourceId: $e');
      throw Exception('Unexpected error deleting links: $e');
    }
  }

  /// Находит существующую ссылку (для обработки конфликта при добавлении).
  Future<Link?> findExistingLink({
    required LinkEntityType sourceType,
    required String sourceId,
    required LinkEntityType targetType,
    required String targetId,
  }) async {
    if (_userId == null) return null;
    try {
      final response = await _client
          .from('links')
          .select()
          .eq('user_id', _userId)
          .eq('source_type', sourceType.name)
          .eq('source_id', sourceId)
          .eq('target_type', targetType.name)
          .eq('target_id', targetId)
          .maybeSingle();
      return response == null ? null : Link.fromJson(response);
    } catch (e) {
      print('Error finding existing link: $e');
      return null;
    }
  }

  // --- Получение ссылок --- 

  /// Получает все ИСХОДЯЩИЕ ссылки для заданного источника.
  Future<List<Link>> getLinksFromSource(LinkEntityType sourceType, String sourceId) async {
    if (_userId == null) return [];
    try {
      final response = await _client
          .from('links')
          .select()
          .eq('user_id', _userId)
          .eq('source_type', sourceType.name)
          .eq('source_id', sourceId)
          .order('created_at');
      return (response as List).map((e) => Link.fromJson(e)).toList();
    } catch (e) {
      print('Error getting links from $sourceType/$sourceId: $e');
      return [];
    }
  }

  /// Получает все ВХОДЯЩИЕ ссылки (бэклинки) для заданной цели.
  /// Возвращает список `Link`.
  Future<List<Link>> getBacklinksForTarget(LinkEntityType targetType, String targetId) async {
    if (_userId == null) return [];
    try {
      final response = await _client
          .from('links')
          .select()
          .eq('user_id', _userId)
          .eq('target_type', targetType.name)
          .eq('target_id', targetId)
          .order('created_at');
      return (response as List).map((e) => Link.fromJson(e)).toList();
    } catch (e) {
      print('Error getting backlinks for $targetType/$targetId: $e');
      return [];
    }
  }

  /// Получает информацию о бэклинках (для UI), включая заголовок/дату источника.
  /// Делает дополнительные запросы к соответствующим таблицам.
  Future<List<BacklinkInfo>> getBacklinkInfosForTarget(
      LinkEntityType targetType, String targetId) async {
    if (_userId == null) return [];

    final List<Link> backlinks = await getBacklinksForTarget(targetType, targetId);
    if (backlinks.isEmpty) return [];

    final List<BacklinkInfo> backlinkInfos = [];

    // Группируем ID источников по типам для пакетных запросов
    final Map<LinkEntityType, Set<String>> sourceIdsByType = {};
    for (final link in backlinks) {
      (sourceIdsByType[link.sourceType] ??= {}).add(link.sourceId);
    }

    // Делаем запросы для каждого типа источника
    final Map<String, String> sourceTitles = {}; // Map<sourceId, title/date>

    // Задачи
    if (sourceIdsByType.containsKey(LinkEntityType.task)) {
      final taskIds = sourceIdsByType[LinkEntityType.task]!.toList();
      try {
        final tasksResponse = await _client
            .from('tasks')
            .select('id, title')
            .inFilter('id', taskIds)
            .eq('user_id', _userId); 
        for (final taskData in tasksResponse as List) {
          sourceTitles[taskData['id']] = taskData['title'] ?? '?';
        }
      } catch (e) {
         print('Error fetching task titles for backlinks: $e');
      }
    }
    // Проекты
    if (sourceIdsByType.containsKey(LinkEntityType.project)) {
      final projectIds = sourceIdsByType[LinkEntityType.project]!.toList();
       try {
        final projectsResponse = await _client
            .from('projects')
            .select('id, name')
            .inFilter('id', projectIds)
            .eq('user_id', _userId); 
        for (final projectData in projectsResponse as List) {
          sourceTitles[projectData['id']] = projectData['name'] ?? '?';
        }
       } catch (e) {
         print('Error fetching project names for backlinks: $e');
       }
    }
    // Заметки
    if (sourceIdsByType.containsKey(LinkEntityType.note)) {
      final noteIds = sourceIdsByType[LinkEntityType.note]!.toList();
       try {
        final notesResponse = await _client
            .from('daily_notes')
            .select('id, date')
            .inFilter('id', noteIds)
            .eq('user_id', _userId); 
        for (final noteData in notesResponse as List) {
          final dateString = noteData['date'];
          sourceTitles[noteData['id']] = dateString != null 
              ? DateFormat.yMMMd('ru').format(DateTime.parse(dateString)) 
              : '?';
        }
       } catch (e) {
          print('Error fetching note dates for backlinks: $e');
       }
    }

    // Собираем BacklinkInfo
    for (final link in backlinks) {
      backlinkInfos.add(BacklinkInfo(
        linkId: link.id,
        sourceType: link.sourceType,
        sourceId: link.sourceId,
        sourceTitleOrDate: sourceTitles[link.sourceId] ?? 'Недоступно',
      ));
    }

    return backlinkInfos;
  }

} 