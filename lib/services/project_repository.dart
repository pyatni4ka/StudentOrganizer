import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database.dart'; // Импорт AppDatabase и Provider
import '../models/project.dart';
import '../services/supabase_client_provider.dart';
import '../services/link_repository.dart'; // Для удаления ссылок
import '../models/link.dart'; // Для LinkEntityType
import '../providers/auth_providers.dart'; // <-- Добавляем импорт

// Provider for the ProjectRepository
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider);
  final authChanges =
      ref.watch(authStateProvider); // <-- Используем правильное имя
  return ProjectRepository(client, db, ref,
      userId: authChanges.value?.session?.user.id);
});

class ProjectRepository {
  final SupabaseClient _client;
  final AppDatabase _db;
  final Ref
      _ref; // Для доступа к другим репозиториям (например, LinkRepository)
  final String? _userId;

  ProjectRepository(this._client, this._db, this._ref,
      {required String? userId})
      : _userId = userId;

  // Получение всех проектов для текущего пользователя
  Future<List<Project>> fetchProjects() async {
    if (_userId == null) return [];

    // 1. Пробуем из локальной БД
    try {
      final query = _db.select(_db.projects)
        ..where((p) => p.userId.equals(_userId))
        ..orderBy([
          (p) => OrderingTerm(expression: p.createdAt, mode: OrderingMode.desc)
        ]);
      final localEntries = await query.get();

      if (localEntries.isNotEmpty) {
        print('Fetched projects from local DB');
        return localEntries.map<Project>(_mapEntryToModel).toList();
      }
    } catch (e) {
      print('Error fetching projects from local DB: $e');
      // Продолжаем, чтобы попробовать из Supabase
    }

    // 2. Если локально пусто или ошибка, получаем из Supabase
    print('Local projects DB empty or error, fetching from Supabase...');
    try {
      final response = await _client
          .from('projects')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      final List<Project> projects = data
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();

      // 3. Кэшируем в локальной БД
      if (projects.isNotEmpty) {
        try {
          await _db.batch((batch) {
            batch.insertAll<Projects, ProjectEntry>(
                _db.projects, projects.map(_mapModelToCompanion).toList(),
                mode: InsertMode.insertOrReplace);
          });
          print('Cached ${projects.length} projects to local DB');
        } catch (dbError) {
          print('Error caching projects to local DB: $dbError');
        }
      }
      return projects;
    } on PostgrestException catch (error) {
      print('Error fetching projects from Supabase: ${error.message}');
      throw Exception('Failed to fetch projects: ${error.message}');
    } catch (error) {
      print('Unexpected error fetching projects: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Добавление нового проекта
  Future<Project> addProject(Project project) async {
    if (_userId == null) throw Exception('User not authenticated');

    try {
      // 1. Добавляем в Supabase
      final projectData = project.toJson()..['user_id'] = _userId;
      projectData.remove('id');
      projectData.remove('created_at');
      projectData.remove('updated_at');
      // Убедимся, что status и deadline передаются (если они есть в модели)
      projectData['status'] = project.status;
      projectData['deadline'] = project.deadline?.toIso8601String();

      final response =
          await _client.from('projects').insert(projectData).select().single();
      final newProject = Project.fromJson(response);

      // 2. Добавляем в локальную БД
      await _db
          .into(_db.projects)
          .insert(_mapModelToCompanion(newProject), mode: InsertMode.replace);
      print('Added project ${newProject.id} to local DB');

      return newProject;
    } on PostgrestException catch (error) {
      print('Error adding project: ${error.message}');
      throw Exception('Failed to add project: ${error.message}');
    } catch (error) {
      print('Unexpected error adding project: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Обновление проекта
  Future<Project> updateProject(Project project) async {
    if (_userId == null || _userId != project.userId)
      throw Exception('Authorization error');

    try {
      // 1. Обновляем в Supabase
      final projectData = project.toJson();
      projectData.remove('id');
      projectData.remove('user_id');
      projectData.remove('created_at');
      projectData.remove('updated_at');
      // Убедимся, что status и deadline передаются для обновления
      projectData['status'] = project.status;
      projectData['deadline'] = project.deadline?.toIso8601String();

      final response = await _client
          .from('projects')
          .update(projectData)
          .eq('id', project.id)
          .eq('user_id', _userId)
          .select()
          .single();
      final updatedProject = Project.fromJson(response);

      // 2. Обновляем в локальной БД
      await (_db.update(_db.projects)
            ..where((p) => p.id.equals(updatedProject.id)))
          .write(_mapModelToCompanion(updatedProject));
      print('Updated project ${updatedProject.id} in local DB');

      return updatedProject;
    } on PostgrestException catch (error) {
      print('Error updating project: ${error.message}');
      throw Exception('Failed to update project: ${error.message}');
    } catch (error) {
      print('Unexpected error updating project: $error');
      throw Exception('Unexpected error: $error');
    }
  }

  // Удаление проекта и связанных данных
  Future<void> deleteProject(String projectId) async {
    if (_userId == null) throw Exception('User not authenticated');

    await _db.transaction(() async {
      // 1. Удаляем ссылки, связанные с проектом (из Supabase)
      try {
        await _ref
            .read(linkRepositoryProvider)
            .deleteLinksRelatedToEntity(LinkEntityType.project, projectId);
        print('Deleted links related to project $projectId');
      } catch (e) {
        print(
            'Error deleting links for project $projectId, continuing... Error: $e');
        // Не прерываем удаление проекта из-за ошибки удаления ссылок
      }

      // --- Обработка задач, связанных с проектом (внутри транзакции БД) ---
      print('Unlinking tasks associated with project $projectId...');
      // Обновляем локальные задачи
      await (_db.update(_db.tasks)..where((t) => t.projectId.equals(projectId)))
          .write(const TasksCompanion(projectId: Value(null)));
      print('Unlinked tasks locally for project $projectId');

      // Обновляем задачи в Supabase (вне транзакции локальной БД)
      try {
        await _client
            .from('tasks')
            .update({'project_id': null})
            .eq('project_id', projectId)
            .eq('user_id', _userId);
        print('Unlinked tasks in Supabase for project $projectId');
      } catch (e) {
        print(
            'Error unlinking tasks in Supabase for project $projectId, continuing... Error: $e');
        // Можно добавить логику компенсации, если критично
      }

      // 3. Удаляем проект из локальной БД (в транзакции)
      await (_db.delete(_db.projects)..where((p) => p.id.equals(projectId)))
          .go();
      print('Deleted project $projectId from local DB');

      // 2. Удаляем проект из Supabase (вне транзакции)
      try {
        await _client
            .from('projects')
            .delete()
            .eq('id', projectId)
            .eq('user_id', _userId);
        print('Deleted project $projectId from Supabase');
      } catch (e) {
        print(
            'Error deleting project $projectId from Supabase, local changes might persist! Error: $e');
        // Выбрасываем исключение, чтобы откатить локальную транзакцию
        throw Exception('Failed to delete project from Supabase: $e');
      }
    });
    print('Project deletion process completed for $projectId');
  }

  // Поиск проекта по точному названию
  Future<Project?> findProjectByName(String name) async {
    if (_userId == null) return null;

    try {
      // 1. Ищем в локальной БД
      final query = _db.select(_db.projects)
        ..where((p) => p.userId.equals(_userId) & p.name.equals(name));
      final localEntry = await query.getSingleOrNull();

      if (localEntry != null) {
        print('Found project "$name" in local DB');
        return _mapEntryToModel(localEntry);
      }

      // 2. Ищем в Supabase, если нет локально
      print('Searching project "$name" in Supabase...');
      final response = await _client
          .from('projects')
          .select()
          .eq('user_id', _userId)
          .eq('name', name)
          .limit(1)
          .maybeSingle();
      if (response == null) {
        print('Project "$name" not found in Supabase');
        return null;
      }
      final project = Project.fromJson(response);

      // Кэшируем найденный проект
      try {
        await _db.into(_db.projects).insert(_mapModelToCompanion(project),
            mode: InsertMode.insertOrReplace);
        print('Cached project "$name" to local DB');
      } catch (dbError) {
        print('Error caching project "$name" to local DB: $dbError');
      }

      return project;
    } on PostgrestException catch (error) {
      print('Error finding project by name "$name": ${error.message}');
      return null;
    } catch (error) {
      print('Unexpected error finding project by name "$name": $error');
      return null;
    }
  }

  // --- Конвертеры ---
  Project _mapEntryToModel(ProjectEntry entry) {
    return Project(
      id: entry.id,
      userId: entry.userId,
      name: entry.name,
      description: entry.description,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      // Добавляем маппинг для новых полей
      status: entry.status, // Статус берем напрямую
      deadline: entry.deadline, // Дедлайн берем напрямую
    );
  }

  ProjectsCompanion _mapModelToCompanion(Project model) {
    return ProjectsCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      name: Value(model.name),
      description: Value(model.description),
      // createdAt и updatedAt обычно управляются БД, но можно передать при необходимости
      // createdAt: Value(model.createdAt),
      // updatedAt: Value(model.updatedAt),
      // Добавляем маппинг для новых полей
      status: Value(model.status), // Передаем статус
      deadline: Value(model.deadline), // Передаем дедлайн
    );
  }
}
