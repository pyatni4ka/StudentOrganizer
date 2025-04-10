import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:macos_ui/macos_ui.dart'; // <-- Возвращаем (оставит ошибку URI)
import 'package:intl/intl.dart'; // Импорт для форматирования дат
import 'package:intl/date_symbol_data_local.dart'; // <--- Добавляем для initializeDateFormatting
import 'package:flutter_localizations/flutter_localizations.dart'; // Для локализации
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <--- Добавляем импорт

import 'navigation/app_router.dart'; // Импортируем роутер
// import 'presentation/widgets/app_sidebar.dart'; // Закомментируем, пока файл не создан

// import 'app.dart'; // <-- Удаляем импорт, так как файл не найден
import 'database/database.dart'; // Для инициализации базы данных
// import 'providers/database_provider.dart'; // <-- Удаляем импорт, так как файл не найден

// Удаляем константу supabaseUrl отсюда, если она не нужна глобально вне инициализации
// const String supabaseUrl = 'https://dmnthylhsvbmxotwrvwf.supabase.co';
// Удаляем жестко прописанный ключ!
// const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

Future<void> main() async {
  // Обеспечиваем инициализацию Flutter перед асинхронными операциями
  WidgetsFlutterBinding.ensureInitialized();

  // Загружаем переменные окружения из .env файла
  await dotenv.load(fileName: ".env");

  // Получаем ключи из переменных окружения
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  // Проверяем, что ключи загрузились
  if (supabaseUrl == null || supabaseAnonKey == null) {
    // Здесь можно добавить более явную обработку ошибки, например, показать диалог
    print(
      'ОШИБКА: Переменные окружения SUPABASE_URL или SUPABASE_ANON_KEY не найдены в .env файле!',
    );
    // Можно либо завершить приложение, либо продолжить с заглушками, если это допустимо
    return;
  }

  // Возвращаем инициализацию macOS UI (оставит ошибку URI)
  await MacosUi.initialize();

  // Инициализация Supabase с использованием ключей из .env
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Инициализируем данные для форматирования дат
  await initializeDateFormatting('ru_RU', null);

  // Запускаем приложение, обернутое в ProviderScope
  runApp(const ProviderScope(child: StudentOrganizerApp()));
}

// Определяем корневой виджет приложения
class StudentOrganizerApp extends ConsumerWidget {
  const StudentOrganizerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider); // Получаем роутер из провайдера

    // Используем MacosApp для macOS стиля
    return MacosApp.router(
      title: 'Student Organizer',
      theme: MacosThemeData.light(), // TODO: Добавить поддержку темной темы
      darkTheme: MacosThemeData.dark(),
      themeMode: ThemeMode.system, // Или ThemeMode.light / ThemeMode.dark
      routerConfig: router, // Передаем конфигурацию роутера
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ru', ''), // Russian, no country code
      ],
      debugShowCheckedModeBanner: false,
    );

    /* // Старый MaterialApp
    return MaterialApp.router(
      title: 'Student Organizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: router, // Передаем конфигурацию роутера
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ru', ''), // Russian, no country code
      ],
      debugShowCheckedModeBanner: false,
    );
    */
  }
}

// Удаляем неиспользуемые MyApp и MyHomePage
/*
class MyApp extends StatelessWidget { ... }
class MyHomePage extends StatefulWidget { ... }
class _MyHomePageState extends State<MyHomePage> { ... }
*/
