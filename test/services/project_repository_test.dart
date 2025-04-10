import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_organizer/services/project_repository.dart';
import 'package:student_organizer/models/project.dart';
import 'package:student_organizer/services/supabase_client_provider.dart'; // Нужен для override

import '../mocks.dart';

typedef PostgrestList = List<Map<String, dynamic>>;
typedef PostgrestMap = Map<String, dynamic>;

void main() {
  // Объявляем моки
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockPostgrestFilterBuilder<PostgrestList> mockFilterBuilderList;
  late MockPostgrestTransformBuilder<PostgrestMap> mockTransformBuilderMap;

  // Тестовые данные
  const testUserId = 'test-user-id';
  final testProjectJson = {
    'id': 'project-1', 
    'name': 'Test Project 1', 
    'user_id': testUserId, 
    'color_hex': '#FF0000',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
  final testProject = Project.fromJson(testProjectJson);

  // Контейнер Riverpod для тестов
  late ProviderContainer container;
  late ProjectRepository projectRepository;

  setUp(() {
    // Инициализация моков
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilderList = MockPostgrestFilterBuilder<PostgrestList>();
    mockTransformBuilderMap = MockPostgrestTransformBuilder<PostgrestMap>();
    registerFallbackValues(); // Регистрируем fallback типы

    // Настройка базового поведения Auth
    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);

    // Настройка цепочек PostgREST
    when(() => mockSupabaseClient.from(any())).thenReturn(mockQueryBuilder);
    // fetch: from -> select -> then
    when(() => mockQueryBuilder.select(any())).thenReturn(mockFilterBuilderList);
    when(() => mockFilterBuilderList.then(any())).thenAnswer((_) async => [testProjectJson]);
    // add: from -> insert -> select -> single -> then
    when(() => mockQueryBuilder.insert(any<List<Map<String, dynamic>>>()))
        .thenReturn(mockTransformBuilderMap as PostgrestTransformBuilder<PostgrestList>); // Используем cast с осторожностью
    when(() => mockTransformBuilderMap.select(any()))
        .thenReturn(mockFilterBuilderList as PostgrestFilterBuilder<PostgrestList>); 
    when(() => mockFilterBuilderList.single())
        .thenReturn(mockTransformBuilderMap);
    when(() => mockTransformBuilderMap.then(any())).thenAnswer((_) async => testProjectJson);

    // Создаем контейнер с переопределенным supabaseClientProvider
    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabaseClient),
      ],
    );
    // Получаем репозиторий из контейнера
    projectRepository = container.read(projectRepositoryProvider);
  });

  tearDown(() {
    container.dispose(); // Очищаем контейнер после теста
  });

  group('ProjectRepository Tests (Riverpod Mocks)', () {
    group('fetchProjects', () {
      test('should return a list of projects on successful fetch', () async {
        // Act
        final result = await projectRepository.fetchProjects();
        // Assert
        expect(result, isA<List<Project>>());
        expect(result.length, 1);
        expect(result.first.id, testProject.id);
        verify(() => mockFilterBuilderList.then(any())).called(1);
      });

       test('should throw exception on PostgrestException during fetch', () async {
        // Arrange
        const exception = PostgrestException(message: 'Fetch error');
        when(() => mockFilterBuilderList.then(any())).thenThrow(exception);
        // Act & Assert
        expect(() => projectRepository.fetchProjects(), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Fetch error'))));
      });
    });

    group('addProject', () {
      test('should return the created project on successful add', () async {
        // Act
        final result = await projectRepository.addProject('New Project', '#00FF00');
        // Assert
        expect(result, isA<Project>());
        expect(result.id, testProject.id);
        verify(() => mockTransformBuilderMap.then(any())).called(1);
      });

       test('should throw exception on PostgrestException during add', () async {
        // Arrange
        const exception = PostgrestException(message: 'Insert error');
        when(() => mockTransformBuilderMap.then(any())).thenThrow(exception);
        // Act & Assert
        expect(() => projectRepository.addProject('New Project', null), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Insert error'))));
      });
      
      test('should throw exception if user is not authenticated', () async {
        // Arrange
        when(() => mockGoTrueClient.currentUser).thenReturn(null);
        // Act & Assert
        expect(() => projectRepository.addProject('New Project', null), throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not authenticated'))));
      });
    });
  });
} 