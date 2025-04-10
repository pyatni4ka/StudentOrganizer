import 'package:flutter/material.dart' hide TextButton; // Прячем TextButton из material
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:macos_ui/macos_ui.dart'; // Импорт macos_ui

import '../../models/project.dart';
import '../../providers/project_providers.dart';
import 'widgets/add_edit_project_dialog.dart'; // TODO: Переделать диалог на macos_ui

class ProjectManagementScreen extends ConsumerWidget {
  const ProjectManagementScreen({super.key});

  // Вспомогательная функция парсинга цвета (дублируется, вынести в утилиты?)
  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      if (buffer.length == 8) {
        return Color(int.parse(buffer.toString(), radix: 16));
      } else {
        return Colors.grey; // Цвет по умолчанию, если формат неверный
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final selectedProjectId = ref.watch(selectedProjectProvider);

    // Используем MacosScaffold, предполагая, что это часть основного окна
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Управление проектами'),
        actions: [
          // Кнопка добавления в тулбар
          ToolBarIconButton(
            label: 'Новый проект',
            icon: const MacosIcon(CupertinoIcons.add),
            onPressed: () {
               // TODO: Использовать showMacosSheet или кастомный диалог macos_ui
               showDialog(
                 context: context,
                 builder: (_) => const AddEditProjectDialog(), 
               );
            },
            showLabel: false, // Показываем только иконку
            tooltipMessage: 'Создать новый проект',
          ),
        ],
      ),
      children: [
        ContentArea( // Основная область
          builder: (context, scrollController) {
            return projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(child: Text('У вас еще нет проектов.'));
                }
                // Используем MacosList для нативного вида
                return MacosList(
                   // controller: scrollController, // Передаем контроллер
                   children: [
                      // TODO: Добавить заголовок секции?
                      ...projects.map((project) {
                         final projectColor = _parseColor(project.colorHex);
                         final bool isSelected = project.id == selectedProjectId;
                          return MacosListTile(
                            leading: MacosIcon(CupertinoIcons.circle_fill, color: projectColor, size: 14),
                            title: Text(project.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            // Используем macos_ui кнопки в трейлинге
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 PushButton(
                                    buttonSize: ButtonSize.small,
                                    child: const Icon(CupertinoIcons.pencil, size: 14),
                                    onPressed: () {
                                       // TODO: Использовать showMacosSheet
                                       showDialog(
                                          context: context,
                                          builder: (_) => AddEditProjectDialog(projectToEdit: project),
                                       );
                                    },
                                 ),
                                 const SizedBox(width: 4),
                                  PushButton(
                                    buttonSize: ButtonSize.small,
                                    secondary: true, // Стиль для удаления
                                    child: const Icon(CupertinoIcons.delete, size: 14, color: Colors.redAccent),
                                    onPressed: () async {
                                       // TODO: Использовать showMacosAlertDialog
                                      final confirm = await showDialog<bool>(
                                         context: context,
                                         builder: (context) => const AlertDialog(/* ... Material Alert ... */),
                                      ) ?? false;
                                      
                                      if (confirm && context.mounted) {
                                         try {
                                           await ref.read(projectListProvider.notifier).deleteProject(project.id);
                                           // Сообщение можно показать через macos_ui notification
                                         } catch (e) { /*...*/ }
                                      }
                                    },
                                 ),
                              ],
                            ),
                            onClick: () {
                              ref.read(selectedProjectProvider.notifier).state = project.id;
                              context.go('/tasks');
                            },
                         );
                      }),
                   ],
                 );
              },
              loading: () => const Center(child: ProgressCircle()), // Используем ProgressCircle
              error: (error, stack) => Center(child: Text('Ошибка загрузки проектов: $error')),
            );
          },
        ),
      ],
    );
  }
} 