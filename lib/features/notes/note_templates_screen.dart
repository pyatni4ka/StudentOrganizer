import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'dart:convert';

import '../../models/note_template.dart';
import '../../services/note_template_repository.dart';

// Провайдер для списка шаблонов
final noteTemplatesProvider = FutureProvider.autoDispose<List<NoteTemplate>>((ref) async {
  final repository = ref.watch(noteTemplateRepositoryProvider);
  return repository.fetchTemplates();
});

class NoteTemplatesScreen extends ConsumerWidget {
  const NoteTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(noteTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны заметок'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(child: Text('Нет созданных шаблонов.'));
          }
          return ListView.separated(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template.title),
                subtitle: const Text('Нажмите для редактирования, удерживайте для удаления'), // Упрощенно
                trailing: const Icon(Icons.edit_note),
                onTap: () {
                  // Открываем диалог/экран редактирования
                  _showTemplateEditDialog(context, ref, templateToEdit: template);
                },
                onLongPress: () async {
                  // Подтверждение и удаление
                  final confirmed = await showDialog<bool>(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: const Text('Удалить шаблон?'),
                       content: Text('Вы уверены, что хотите удалить шаблон "${template.title}"?'),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                         TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Удалить')),
                       ],
                     ),
                  ) ?? false;
                  
                  if (confirmed) {
                    try {
                      await ref.read(noteTemplateRepositoryProvider).deleteTemplate(template.id);
                      ref.invalidate(noteTemplatesProvider); // Обновляем список
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Шаблон удален')));
                      }
                    } catch (e) {
                       if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red));
                      }
                    }
                  }
                },
              );
            },
             separatorBuilder: (context, index) => const Divider(height: 1),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка загрузки шаблонов: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Создать шаблон',
        onPressed: () {
          _showTemplateEditDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Диалог для создания/редактирования шаблона
  void _showTemplateEditDialog(BuildContext context, WidgetRef ref, {NoteTemplate? templateToEdit}) {
    final isEditing = templateToEdit != null;
    final titleController = TextEditingController(text: isEditing ? templateToEdit.title : '');
    QuillController descriptionController;
    
    Document initialDocument = Document();
    if (isEditing && templateToEdit.content != null) {
       try {
         initialDocument = Document.fromJson(jsonDecode(templateToEdit.content as String));
       } catch(e) { print("Error decoding template content: $e"); }
    }
    descriptionController = QuillController(document: initialDocument, selection: const TextSelection.collapsed(offset: 0));

    showDialog(
      context: context,
      // Используем AlertDialog для простоты
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Редактировать шаблон' : 'Новый шаблон'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Название шаблона *'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text('Содержимое шаблона', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Container(
                 decoration: BoxDecoration(
                   border: Border.all(color: Theme.of(context).dividerColor),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Column(
                   children: [
                      QuillToolbar.simple(
                          configurations: QuillSimpleToolbarConfigurations(
                              controller: descriptionController,
                              sharedConfigurations: const QuillSharedConfigurations(locale: Locale('ru'))
                          ),
                      ),
                      const Divider(height: 1),
                      ConstrainedBox(
                         constraints: const BoxConstraints(maxHeight: 300), 
                         child: QuillEditor.basic(
                           configurations: QuillEditorConfigurations(
                             controller: descriptionController,
                             padding: const EdgeInsets.all(12),
                             sharedConfigurations: const QuillSharedConfigurations(locale: Locale('ru')),
                           )
                         ),
                       ),
                   ],
                 ),
              )
            ],
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите название'), backgroundColor: Colors.orange));
                 return;
              }
              final contentJson = descriptionController.document.toDelta().toJson();
              final repo = ref.read(noteTemplateRepositoryProvider);
              try {
                if (isEditing) {
                  final updatedTemplate = templateToEdit.copyWith(title: title, content: contentJson);
                  await repo.updateTemplate(updatedTemplate);
                } else {
                  final newTemplate = NoteTemplate(id: '', userId: '', title: title, content: contentJson); // userId будет взят в репо
                  await repo.addTemplate(newTemplate);
                }
                ref.invalidate(noteTemplatesProvider); // Обновляем список
                if (context.mounted) Navigator.pop(context); // Закрываем диалог
              } catch (e) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.red));
                 }
              }
            },
             child: const Text('Сохранить'),
          ),
        ],
      ),
    ).whenComplete(() {
        // Dispose контроллеров после закрытия диалога
        titleController.dispose();
        descriptionController.dispose();
    });
  }
} 