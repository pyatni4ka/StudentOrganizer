import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_client_provider.dart'; // Исправленный путь

// Провайдер, который следит за состоянием аутентификации пользователя
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return supabaseClient.auth.onAuthStateChange;
});

// Провайдер, который возвращает текущего пользователя (User?)
// Удобно использовать, чтобы быстро проверить, вошел ли пользователь
final currentUserProvider = Provider<User?>((ref) {
  // Следим за состоянием AuthState
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
}); 