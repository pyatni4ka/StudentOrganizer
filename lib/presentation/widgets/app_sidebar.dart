import 'package:flutter/cupertino.dart'; // Используем Cupertino Icons
import 'package:macos_ui/macos_ui.dart';
import 'package:go_router/go_router.dart';

// Провайдер для отслеживания текущего индекса (лучше через GoRouter)
// final sidebarIndexProvider = StateProvider<int>((ref) => 0);

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  // Индекс будет управляться через GoRouter
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tasks')) {
      return 0;
    }
    if (location.startsWith('/projects')) {
      return 1;
    }
    if (location.startsWith('/calendar')) {
      return 2;
    }
    if (location.startsWith('/notes')) {
      return 3;
    }
    if (location.startsWith('/files')) {
      return 4;
    }
     if (location.startsWith('/ai')) {
      return 5;
    }
    if (location.startsWith('/settings')) {
      return 6;
    }
    // TODO: Добавить /dashboard?
    return 0; // По умолчанию - Задачи
  }

  @override
  Widget build(BuildContext context) {
    // Используем Sidebar из macos_ui
    return Sidebar(
      minWidth: 220,
      builder: (context, scrollController) {
        return SidebarItems(
          currentIndex: _calculateSelectedIndex(context),
          onChanged: (index) {
            // Переход по индексу
            switch (index) {
              case 0:
                context.go('/tasks');
                break;
              case 1:
                context.go('/projects');
                break;
              case 2:
                context.go('/calendar');
                break;
              case 3:
                context.go('/notes');
                break;
              case 4:
                context.go('/files');
                break;
              case 5:
                context.go('/ai');
                break;
               case 6:
                 context.go('/settings');
                 break;
            }
          },
          items: const [
            SidebarItem(
              leading: MacosIcon(CupertinoIcons.list_bullet),
              label: Text('Задачи'),
            ),
            SidebarItem(
              leading: MacosIcon(CupertinoIcons.briefcase),
              label: Text('Проекты'),
            ),
            SidebarItem(
              leading: MacosIcon(CupertinoIcons.calendar),
              label: Text('Календарь'),
            ),
             SidebarItem(
              leading: MacosIcon(CupertinoIcons.news),
              label: Text('Заметки'),
            ),
            SidebarItem(
              leading: MacosIcon(CupertinoIcons.folder_open),
              label: Text('Файлы'),
            ),
             SidebarItem(
              leading: MacosIcon(CupertinoIcons.rocket_fill), // Пример иконки AI
              label: Text('AI Помощник'),
            ),
          ],
          // Добавляем разделитель и Настройки в конец
          footer: const SidebarItem(
             leading: MacosIcon(CupertinoIcons.settings),
             label: Text('Настройки'),
           ),
        );
      },
    );
  }
} 