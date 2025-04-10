import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/project.dart';
import '../services/project_repository.dart';

part 'project_providers.g.dart';

// FutureProvider для асинхронной загрузки списка проектов
// final projectsProvider = FutureProvider<List<Project>>((ref) async {
//   final repository = ref.watch(projectRepositoryProvider);
//   return repository.fetchProjects();
// });

// AsyncNotifierProvider для управления состоянием проектов
@riverpod
class ProjectList extends _$ProjectList {
  
  // Получаем доступ к репозиторию
  ProjectRepository _repository() => ref.watch(projectRepositoryProvider);

  // Метод build загружает начальное состояние
  @override
  Future<List<Project>> build() async {
    return _repository().fetchProjects();
  }

  // Метод для добавления проекта
  Future<void> addProject(String name, String? colorHex) async {
    // Получаем текущее состояние перед началом операции
    final previousStateResult = state;
    
    // Устанавливаем состояние загрузки
    state = const AsyncValue.loading();
    try {
      // Вызываем метод репозитория
      final newProject = await _repository().addProject(name, colorHex);
      // Обновляем состояние: добавляем новый проект к существующему списку
      // Используем данные из предыдущего успешного состояния, если они были
      final currentProjects = previousStateResult.valueOrNull ?? [];
      state = AsyncValue.data([...currentProjects, newProject]);
      
    } catch (e, s) {
      // В случае ошибки устанавливаем состояние ошибки
      // Возвращаем предыдущее состояние (если оно было успешным) 
      // или оставляем ошибку, если и до этого была ошибка
      if (previousStateResult is AsyncData<List<Project>>) {
         state = AsyncValue<List<Project>>.error(e, s).copyWithPrevious(previousStateResult);
      } else {
         state = AsyncValue.error(e, s);
      }
       print('Error adding project in provider: $e');
      // Не перевыбрасываем ошибку здесь, UI должен обработать AsyncError
    }
  }

  // Метод для обновления проекта
  Future<void> updateProject(Project project) async {
    final previousStateResult = state;
    // Не ставим глобальное состояние загрузки, чтобы список не мерцал
    // state = const AsyncValue.loading(); 
    try {
      final updatedProject = await _repository().updateProject(project);
      // Обновляем состояние: заменяем старый проект новым
      final currentProjects = previousStateResult.valueOrNull ?? [];
      state = AsyncValue.data([
        for (final p in currentProjects)
          if (p.id == updatedProject.id) updatedProject else p,
      ]);
    } catch (e) {
      // В случае ошибки НЕ меняем основное состояние на Error, 
      // чтобы список не пропадал. Просто логируем или показываем SnackBar.
      print('Error updating project in provider: $e');
      // state = AsyncValue.error(e, s); // Не делаем так
      // Оставляем предыдущее состояние, но можно его пометить как "ошибка обновления"
      // или использовать copyWithPrevious, если нужно
    }
  }

  // Метод для удаления проекта
  Future<void> deleteProject(String projectId) async {
     final previousStateResult = state;
     // Не ставим глобальное состояние загрузки
     // state = const AsyncValue.loading();
     try {
       await _repository().deleteProject(projectId);
       // Обновляем состояние: удаляем проект из списка
       final currentProjects = previousStateResult.valueOrNull ?? [];
       state = AsyncValue.data([
         for (final p in currentProjects) 
           if (p.id != projectId) p,
       ]);
       
       // Если удаляемый проект был выбран, сбрасываем выбор
       if (ref.read(selectedProjectProvider) == projectId) {
         ref.read(selectedProjectProvider.notifier).state = null;
       }
     } catch (e) {
       print('Error deleting project in provider: $e');
       // Не меняем состояние на Error
       // state = AsyncValue.error(e, s);
     }
  }

  // TODO: Добавить методы updateProject, deleteProject

}

// Провайдер для хранения ID текущего выбранного проекта (null = "Все задачи")
final selectedProjectProvider = StateProvider<String?>((ref) => null);

// TODO: Удалить старый projectsProvider, если он больше не нужен
// или использовать projectListProvider.future для FutureProvider 