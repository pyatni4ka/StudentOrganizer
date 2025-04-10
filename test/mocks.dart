import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Моки клиентов
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

// Моки для PostgREST (без implements)
class MockSupabaseQueryBuilder extends Mock {}
class MockPostgrestFilterBuilder<T> extends Mock {}
class MockPostgrestTransformBuilder<T> extends Mock {}
class MockPostgrestResponse extends Mock implements PostgrestResponse {}

// Мок для LocalStorage
class MockLocalStorage extends Mock implements LocalStorage {
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() async => null;
  @override
  Future<bool> hasAccessToken() async => false;
  @override
  Future<void> persistSession(String persistSessionString) async {}
  @override
  Future<void> removePersistedSession() async {}
}

// Helper
void registerFallbackValues() {
  registerFallbackValue(<String, dynamic>{}); 
} 