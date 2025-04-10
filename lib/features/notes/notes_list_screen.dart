import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Для Document
// Для jsonDecode
import 'package:grouped_list/grouped_list.dart'; // Импортируем пакет

import '../../models/daily_note.dart';
import '../../services/daily_note_repository.dart';
import '../../providers/daily_note_providers.dart'; // Для selectedDateProvider

// Модель для результата превью
class NotePreviewResult {
  final String previewText;
  final bool hasTaskLinks;
  final bool hasProjectLinks;
  final bool hasNoteLinks;

  NotePreviewResult({
    required this.previewText,
    this.hasTaskLinks = false,
    this.hasProjectLinks = false,
    this.hasNoteLinks = false,
  });
}

// FutureProvider для загрузки всех заметок (ВОЗВРАЩАЕМ)
final allNotesProvider = FutureProvider<List<DailyNote>>((ref) async {
  final repository = ref.watch(dailyNoteRepositoryProvider);
  return repository.fetchAllNotes();
});

// Провайдер для строки поиска
final noteSearchQueryProvider = StateProvider<String>((ref) => '');

// Возвращаем ConsumerWidget
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  // Функция для генерации превью и проверки ссылок
  NotePreviewResult _generatePreview(Map<String, dynamic>? content) {
    String previewText = '[Пустая заметка]';
    bool hasTaskLinks = false;
    bool hasProjectLinks = false;
    bool hasNoteLinks = false;

    if (content == null || !content.containsKey('ops')) {
      return NotePreviewResult(previewText: previewText);
    }
    try {
      final List<dynamic> opsList = content['ops'] as List<dynamic>;
      if (opsList.isEmpty) return NotePreviewResult(previewText: previewText);

      final document = Document.fromJson(opsList);
      String plainText = document.toPlainText().trim(); 

      if (plainText.isEmpty) return NotePreviewResult(previewText: previewText);

      // Проверяем наличие ссылок
      hasTaskLinks = plainText.contains(RegExp(r'\[\[.*\]\]'));
      hasProjectLinks = plainText.contains(RegExp(r'@([\w\s-]+)\b'));
      hasNoteLinks = plainText.contains(RegExp(r'##\d{4}-\d{2}-\d{2}\b'));

      // Генерируем текстовое превью
      plainText = plainText.replaceAll('\n', ' ');
      const maxLength = 80;
      previewText = plainText.length <= maxLength
          ? plainText
          : '${plainText.substring(0, maxLength)}...';

      return NotePreviewResult(
         previewText: previewText,
         hasTaskLinks: hasTaskLinks,
         hasProjectLinks: hasProjectLinks,
         hasNoteLinks: hasNoteLinks,
      );
    } catch (e) {
      print('Error generating note preview: $e');
      return NotePreviewResult(previewText: '[Ошибка отображения]');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allNotesAsync = ref.watch(allNotesProvider);
    final searchQuery = ref.watch(noteSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Поиск по дате или тексту...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
          ),
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
          onChanged: (query) {
            ref.read(noteSearchQueryProvider.notifier).state = query;
          },
        ),
        actions: [
          // Кнопка очистки поиска
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Очистить поиск',
              onPressed: () => ref.read(noteSearchQueryProvider.notifier).state = '',
            ),
          IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Новая заметка на сегодня',
              onPressed: () {
                 final today = DateTime.now();
                 final todayWithoutTime = DateTime(today.year, today.month, today.day);
                 ref.read(selectedDateProvider.notifier).state = todayWithoutTime;
                 context.go('/notes'); 
              },
            ),
        ],
      ),
      body: allNotesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('У вас пока нет заметок.'));
          }
          // Сортируем заметки по дате (сначала новые)
          final sortedNotes = List<DailyNote>.from(notes)
            ..sort((a, b) => b.date.compareTo(a.date));
            
          // Фильтруем список по поисковому запросу
          final filteredNotes = sortedNotes.where((note) {
             if (searchQuery.isEmpty) return true;
             final formattedDate = DateFormat.yMMMMd('ru').format(note.date);
             final previewResult = _generatePreview(note.content);
             final queryLower = searchQuery.toLowerCase();
             // Ищем по дате (включая разные форматы) или по превью
             return formattedDate.toLowerCase().contains(queryLower) || 
                    DateFormat('yyyy-MM-dd').format(note.date).contains(queryLower) || // Ищем по YYYY-MM-DD
                    previewResult.previewText.toLowerCase().contains(queryLower);
          }).toList();

          if (filteredNotes.isEmpty && searchQuery.isNotEmpty) {
            return const Center(child: Text('Ничего не найдено.'));
          } else if (filteredNotes.isEmpty && searchQuery.isEmpty) {
            return const Center(child: Text('У вас пока нет заметок.'));
          }

          // Используем GroupedListView
          return GroupedListView<DailyNote, DateTime>(
            elements: filteredNotes,
            groupBy: (note) => DateTime(note.date.year, note.date.month),
            groupSeparatorBuilder: (DateTime groupByValue) {
              final String monthYear = DateFormat.yMMMM('ru').format(groupByValue);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(
                  monthYear,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                       color: Theme.of(context).colorScheme.primary, 
                       fontWeight: FontWeight.bold
                  ),
                ),
              );
            },
            itemBuilder: (context, note) {
              final previewResult = _generatePreview(note.content);
              final formattedDate = DateFormat.yMMMMd('ru').format(note.date);
              
              return Dismissible(
                key: ValueKey(note.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withOpacity(0.8),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                   return await showDialog<bool>(
                     context: context,
                     builder: (BuildContext context) {
                       return AlertDialog(
                         title: const Text('Удалить заметку?'),
                         content: Text('Вы уверены, что хотите удалить заметку за $formattedDate?'),
                         actions: <Widget>[
                           TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop(false)),
                           TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('Удалить')),
                         ],
                       );
                     },
                   ) ?? false;
                },
                onDismissed: (direction) async {
                   try {
                     await ref.read(dailyNoteNotifierProvider.notifier).deleteNote(note.id);
                     // Добавляем небольшую задержку перед инвалидацией
                     await Future.delayed(const Duration(milliseconds: 300)); // Задержка для анимации Dismissible
                     if (!context.mounted) return; // Проверяем после задержки
                     ref.invalidate(allNotesProvider);
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Заметка за $formattedDate удалена')),
                     );
                   } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red),
                        );
                         // При ошибке тоже инвалидируем (можно и без задержки)
                         ref.invalidate(allNotesProvider);
                      }
                   }
                },
                child: ListTile(
                  title: Text(formattedDate),
                  subtitle: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          previewResult.previewText, 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8)),
                         ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            if (previewResult.hasTaskLinks) 
                              Icon(Icons.task_alt, size: 14, color: Colors.grey[600]),
                            if (previewResult.hasProjectLinks) 
                               Padding(
                                 padding: const EdgeInsets.only(left: 2.0),
                                 child: Icon(Icons.topic_outlined, size: 14, color: Colors.grey[600]),
                               ),
                            if (previewResult.hasNoteLinks) 
                               Padding(
                                  padding: const EdgeInsets.only(left: 2.0),
                                  child: Icon(Icons.note_alt_outlined, size: 14, color: Colors.grey[600]),
                                ),
                         ],
                      )
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = note.date;
                    context.go('/notes');
                  },
                  onLongPress: () {
                    _showNoteActionsMenu(context, ref, note, formattedDate);
                  },
                ),
              );
            },
            order: GroupedListOrder.DESC,
            useStickyGroupSeparators: true,
            floatingHeader: false,
            separator: const Divider(height: 1),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Ошибка загрузки заметок: $error', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  // Метод для показа контекстного меню
  void _showNoteActionsMenu(BuildContext context, WidgetRef ref, DailyNote note, String formattedDate) {
     showModalBottomSheet(
       context: context,
       builder: (BuildContext bc) {
         return Wrap(
           children: <Widget>[
             ListTile(
                 leading: const Icon(Icons.open_in_new),
                 title: const Text('Открыть'),
                 onTap: () { 
                   Navigator.pop(bc); 
                   ref.read(selectedDateProvider.notifier).state = note.date;
                   context.go('/notes');
                 }),
             ListTile(
                 leading: const Icon(Icons.delete_outline, color: Colors.red),
                 title: const Text('Удалить'),
                 onTap: () async { 
                   Navigator.pop(bc);
                   final confirm = await showDialog<bool>(
                     context: context,
                     builder: (BuildContext context) {
                       return AlertDialog(
                         title: const Text('Удалить заметку?'),
                         content: Text('Вы уверены, что хотите удалить заметку за $formattedDate?'),
                         actions: <Widget>[
                           TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop(false)),
                           TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('Удалить')),
                         ],
                       );
                     },
                   ) ?? false;

                   if (confirm) {
                      try {
                        await ref.read(dailyNoteNotifierProvider.notifier).deleteNote(note.id);
                        // Добавляем небольшую задержку перед инвалидацией
                        await Future.delayed(const Duration(milliseconds: 100)); // Меньшая задержка для меню
                        if (!context.mounted) return; // Проверяем после задержки
                        ref.invalidate(allNotesProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Заметка за $formattedDate удалена')),
                        );
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red),
                           );
                            ref.invalidate(allNotesProvider);
                         }
                      }
                   }
                 }),
           ],
         );
       });
  }
} 