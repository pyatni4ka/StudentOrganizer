import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../shared_widgets/app_shell.dart'; // Импортируем AppShell
import '../features/tasks/task_list_screen.dart'; // Импортируем TaskListScreen
import '../features/auth/auth_screen.dart'; // Импортируем AuthScreen
import '../providers/auth_providers.dart'; // Импортируем провайдер аутентификации
// Добавляем импорт для SettingsScreen
import '../features/projects/project_management_screen.dart'; // <-- Импортируем новый экран
import '../features/notes/daily_note_screen.dart'; // <-- Импортируем экран заметок
import '../features/calendar/calendar_screen.dart'; // <-- Импортируем экран календаря
import '../features/files/file_manager_screen.dart'; // <-- Импортируем экран файлов
import '../features/ai_center/ai_center_screen.dart'; // <-- Импортируем экран AI
import '../features/settings/settings_screen.dart' as features_settings; // Используем префикс
import '../features/notes/notes_list_screen.dart'; // Импортируем новый экран
import '../features/dashboard/dashboard_screen.dart'; // Импортируем Dashboard

// TODO: Импортировать реальные экраны, когда они будут созданы
// import '../features/dashboard/dashboard_screen.dart'; 
// import '../features/tasks/tasks_screen.dart';
// import '../features/calendar/calendar_screen.dart';
// import '../features/notes/notes_screen.dart';
// import '../features/files/files_screen.dart';
// import '../features/ai_center/ai_center_screen.dart';
// import '../features/settings/settings_screen.dart';
// import '../features/auth/auth_screen.dart';

// Провайдер для GoRouter
final goRouterProvider = Provider<GoRouter>((ref) {
  // Получаем текущего пользователя для логики редиректа
  final currentUser = ref.watch(currentUserProvider);
  final initialLocation = currentUser == null ? '/login' : '/'; // Стартуем с логина, если не вошли

  return GoRouter(
    initialLocation: initialLocation,
    // Слушаем изменения состояния аутентификации для автоматической переадресации
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
    redirect: (BuildContext context, GoRouterState state) {
      final loggedIn = currentUser != null;
      final loggingIn = state.matchedLocation == '/login';

      // Если пользователь не вошел и пытается получить доступ не к /login, перенаправляем на /login
      if (!loggedIn && !loggingIn) {
        return '/login';
      }
      // Если пользователь вошел и находится на /login, перенаправляем на главную
      if (loggedIn && loggingIn) {
        return '/';
      }
      // В остальных случаях остаемся на текущем маршруте
      return null;
    },
    routes: [
      // Маршрут для экрана аутентификации (вне оболочки)
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthScreen(),
      ),
      // Маршруты внутри основной оболочки приложения
      ShellRoute(
        builder: (context, state, child) {
          // Защищаем ShellRoute - если пользователя нет, редирект уже должен был сработать,
          // но на всякий случай можно добавить проверку или заглушку
          return AppShell(child: child); 
        },
        routes: [
          // Вложенные маршруты для каждого раздела
          GoRoute(
            path: '/', // Dashboard
            builder: (context, state) => const DashboardScreen(), // Ставим реальный экран
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TaskListScreen(),
          ),
          // Добавляем маршрут для экрана проектов
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectManagementScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const DailyNoteScreen(), // Экран редактирования/просмотра ОДНОЙ заметки
          ),
          // Новый маршрут для списка заметок
          GoRoute(
            path: '/notes_list',
            builder: (context, state) => const NotesListScreen(), 
          ),
          GoRoute(
            path: '/files',
            builder: (context, state) => const FileManagerScreen(),
          ),
          GoRoute(
            path: '/ai',
            builder: (context, state) => const AICenterScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const features_settings.SettingsScreen(), 
          ),
          // TODO: Добавить маршруты для деталей проекта, задач и т.д.
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error), // Добавляем обработчик ошибок
  );
});

// Вспомогательный класс для обновления GoRouter при изменении Stream
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Временный виджет-заглушка для экранов
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Экран "$title" в разработке')),
    );
  }
}

// Экран для отображения ошибок навигации
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(error?.toString() ?? 'Произошла ошибка навигации.'),
        ),
      ),
    );
  }
} 