import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_organizer/services/project_repository.dart';
import 'package:student_organizer/models/project.dart';

import '../supabase_test_helper.dart'; // Импортируем хелпер

void main() {
  // Используем хелпер для настройки Supabase
  setupSupabaseTests(); 

  late SupabaseClient client;
  late ProjectRepository projectRepository;
  late String testUserId; // Будем получать ID тестового пользователя

  setUp(() async {
    // Получаем реальный клиент из хелпера
    client = SupabaseTestHelper.client;
    projectRepository = ProjectRepository(client);
    
    // Очищаем таблицы перед каждым тестом для изоляции
    await SupabaseTestHelper.clearTables(['projects']);

    // Создаем тестового пользователя для тестов, требующих аутентификации
    // (используем случайный email/пароль, т.к. база чистая)
    final email = 'test-${DateTime.now().millisecondsSinceEpoch}@test.com';
    const password = 'password123';
    final response = await client.auth.signUp(email: email, password: password);
    expect(response.user, isNotNull);
    testUserId = response.user!.id;
    // Обновляем репозиторий, т.к. клиент мог переинициализироваться
    projectRepository = ProjectRepository(client); 
  });

  group('ProjectRepository Tests (Integration)', () {
    group('fetchProjects', () {
      test('should return an empty list if no projects exist', () async {
        // Act
        final result = await projectRepository.fetchProjects();
        // Assert
        expect(result, isEmpty);
      });

      test('should return projects created by the user', () async {
        // Arrange: Создаем проект напрямую в БД
        final newProjectData = {
           'name': 'Fetched Project', 
           'user_id': testUserId,
           'color_hex': '#123456'
        };
        final insertResponse = await client.from('projects').insert(newProjectData).select().single();
        expect(insertResponse['id'], isNotNull); 
        final insertedId = insertResponse['id'];

        // Act
        final result = await projectRepository.fetchProjects();

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, 1);
        expect(result.first.id, insertedId);
        expect(result.first.name, 'Fetched Project');
        expect(result.first.userId, testUserId);
        expect(result.first.colorHex, '#123456');
      });
      
      // Тесты на ошибки сложнее воспроизвести без моков, 
      // но можно проверить базовую работоспособность
    });

    group('addProject', () {
      test('should add a project to the database and return it', () async {
        // Arrange
        const projectName = 'Added Project';
        const projectColor = '#ABCDEF';

        // Act
        final result = await projectRepository.addProject(projectName, projectColor);

        // Assert
        expect(result, isA<Project>());
        expect(result.name, projectName);
        expect(result.colorHex, projectColor);
        expect(result.userId, testUserId);
        expect(result.id, isNotNull);
        expect(result.createdAt, isNotNull);

        // Проверяем, что проект реально появился в БД
        final dbCheck = await client.from('projects').select().eq('id', result.id).single();
        expect(dbCheck['name'], projectName);
      });

       test('should throw exception if user is signed out during add', () async {
        // Arrange
        await client.auth.signOut(); // Выходим из системы
        // Обновляем репозиторий после signOut
        projectRepository = ProjectRepository(client);

        // Act & Assert
        expect(
          () => projectRepository.addProject('Should Fail', null),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not authenticated')))
        );
      });
      
      // Тест на PostgrestException при добавлении сложен без моков
      // (например, дубликат ID или нарушение ограничений)
    });

    // TODO: Добавить тесты для updateProject и deleteProject
  });
} 