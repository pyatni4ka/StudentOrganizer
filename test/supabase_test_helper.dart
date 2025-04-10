import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mocks.dart'; // Используем правильный путь

class SupabaseTestHelper {
  // static Process? _process; // Больше не управляем процессом
  // static final _completer = Completer<void>(); // Больше не нужно

  static const String supabaseUrl = 'http://localhost:54321';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQw5GdRqyQDsynpguti1Q';
  static const String supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

  /// Инициализирует Supabase для тестов с фейковым хранилищем.
  static Future<void> initializeSupabase() async {
    print('Initializing Supabase client for tests with MockLocalStorage...');
    try {
       // Используем Supabase.initialize с MockLocalStorage
       await Supabase.initialize(
         url: supabaseUrl,
         anonKey: supabaseAnonKey,
         authOptions: FlutterAuthClientOptions(
            localStorage: MockLocalStorage(), 
         ),
         debug: false,
       );
       print('Supabase client initialized with MockLocalStorage.');
    } catch (e) {
       print('Error initializing Supabase client: $e');
       rethrow;
    }
  }

  /// Запускает локальный Supabase (закомментировано, т.к. запускаем вручную).
  // static Future<void> startSupabase() async { ... }

  /// Останавливает локальный Supabase (закомментировано).
  // static Future<void> stopSupabase() async { ... }

  /// Получает инициализированный SupabaseClient.
  static SupabaseClient get client {
    return Supabase.instance.client;
  }

  /// Очищает данные в указанных таблицах.
  static Future<void> clearTables(List<String> tableNames) async {
    final adminClient = SupabaseClient(supabaseUrl, supabaseServiceRoleKey);
    try {
      // Увеличиваем задержку
      print('Waiting 10 seconds for migrations...');
      await Future.delayed(const Duration(seconds: 10)); 
      
      for (final tableName in tableNames) {
         print('Clearing table: $tableName');
        await adminClient.from(tableName).delete().neq('id', '00000000-0000-0000-0000-000000000000'); 
      }
    } catch (e) {
       print('Error clearing tables: $e');
    } finally {
       await adminClient.dispose(); 
    }
  }
}

/// Глобальная настройка для тестов, использующих ЗАПУЩЕННЫЙ Supabase.
void setupSupabaseTests() {
  setUpAll(() async {
    await SupabaseTestHelper.initializeSupabase();
  });

  setUp(() async {
    await SupabaseTestHelper.clearTables(['projects', 'tasks', 'auth.users']); 
  });

  // tearDownAll не нужен, если Supabase запущен вручную
} 