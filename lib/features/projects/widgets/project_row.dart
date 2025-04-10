import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Для форматирования дедлайна

import '../../../models/project.dart';
import '../../../features/projects/widgets/add_project_sheet.dart';
import '../../../services/project_repository.dart'; // Для удаления
import '../../../providers/project_providers.dart'; // Для invalidate
import '../../tasks/task_list_screen.dart'; // Для навигации

class ProjectRow extends ConsumerWidget {
  final Project project;

  const ProjectRow({super.key, required this.project});

  // Вспомогательная функция для получения цвета статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'on_hold':
        return Colors.orange;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Вспомогательная функция для получения отображаемого имени статуса
  String _getDisplayStatus(String status) {
     switch (status) {
      case 'active': return 'Активный';
      case 'on_hold': return 'Приостановлен';
      case 'archived': return 'В архиве';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.folder), // Или CircleAvatar с цветом проекта
      title: Text(project.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.description != null && project.description!.isNotEmpty)
            Text(
              project.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Отображение статуса в виде чипа
              Chip(
                label: Text(
                  _getDisplayStatus(project.status),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: _getStatusColor(project.status),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: EdgeInsets.zero,
                 visualDensity: VisualDensity.compact, // Делаем чип компактнее
              ),
              const SizedBox(width: 8),
              // Отображение дедлайна, если есть
              if (project.deadline != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      project.formattedDeadline ?? '' , // Используем геттер
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          )
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'edit') {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => AddProjectSheet(project: project),
            );
          } else if (value == 'delete') {
            // Логика удаления
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Удалить проект?'),
                content: Text('Вы уверены, что хотите удалить проект "${project.name}"? Задачи, связанные с ним, будут отвязаны.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              try {
                await ref.read(projectRepositoryProvider).deleteProject(project.id);
                ref.invalidate(allProjectsProvider); // Обновляем список
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Проект "${project.name}" удален')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка удаления проекта: $e')),
                );
              }
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(leading: Icon(Icons.edit), title: Text('Редактировать')),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Удалить', style: TextStyle(color: Colors.red))),
          ),
        ],
      ),
      onTap: () {
         // Переход к списку задач этого проекта
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TasksListScreen(projectId: project.id, projectName: project.name),
          ),
        );
      },
    );
  }
} 