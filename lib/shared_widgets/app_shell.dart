// import 'package:flutter/material.dart'; // Заменяем на macos_ui
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macos_ui/macos_ui.dart';

// Удаляем импорты, связанные с проектами, так как они будут в TaskListScreen или ProjectScreen
// import '../models/project.dart'; 
// import '../providers/project_providers.dart'; 

import '../presentation/widgets/app_sidebar.dart'; // Импортируем наш AppSidebar

class AppShell extends ConsumerWidget { // Больше не нужен StatefulWidget
  final Widget child; // Контент текущего экрана
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Используем MacosScaffold для интеграции с MacosWindow и Sidebar
    // MacosWindow управляется MacosApp.router, поэтому используем MacosScaffold
    return MacosScaffold(
      toolBar: const ToolBar( // Добавляем пустой тулбар для заголовка окна
         title: Text('Student Organizer'), // TODO: Сделать заголовок динамическим?
       ),
       children: [
         ContentArea( // Основная область
           builder: (context, scrollController) {
             return child; // Показываем дочерний виджет из ShellRoute
           },
         ),
          // Sidebar будет отображаться слева автоматически
          Sidebar( // Используем наш AppSidebar
            minWidth: 220,
            builder: (context, scrollController) {
              return const AppSidebar(); // Вставляем наш виджет сайдбара
            },
            // Можно добавить кастомный футер/хедер, если нужно
            // footer: Text('Footer'),
            // header: Text('Header'),
          ), 
       ],
    );
  }
} 