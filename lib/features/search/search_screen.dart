import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart';

// Импортируем модели
import '../../models/task.dart';
import '../../models/project.dart';
import '../../models/daily_note.dart';

// Импортируем репозитории
import '../../services/task_repository.dart';
import '../../services/project_repository.dart';
import '../../services/daily_note_repository.dart';

// Импортируем нужные провайдеры для навигации
import '../../providers/project_providers.dart';
import '../../providers/daily_note_providers.dart';

// Импортируем виджеты для отображения результатов
import '../tasks/widgets/task_row.dart';
import '../tasks/widgets/add_task_sheet.dart';
// TODO: Создать ProjectRow и NoteRow или использовать ListTile

part 'search_screen.g.dart'; // Для Riverpod Generator

// Провайдер для строки поиска
final searchQueryProvider = StateProvider<String>((ref) => '');

// Определяем класс для результатов поиска
class SearchResult {
  final List<Task> tasks;
  final List<Project> projects;
  final List<DailyNote> notes;

  SearchResult({required this.tasks, required this.projects, required this.notes});

  bool get isEmpty => tasks.isEmpty && projects.isEmpty && notes.isEmpty;
}

// Провайдер для результатов поиска
@riverpod
class SearchResults extends _$SearchResults {
  @override
  Future<SearchResult> build(String query) async {
    // Отмена, если запрос слишком короткий
    if (query.length < 2) { 
      return SearchResult(tasks: [], projects: [], notes: []);
    }

    // Используем debounce
    final link = ref.keepAlive(); // Используем поле ref
    final timer = Timer(const Duration(milliseconds: 500), () {
       link.close();
    });
    ref.onDispose(() => timer.cancel()); // Используем поле ref
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Проверяем, не изменился ли запрос и активен ли провайдер
    // Используем имя сгенерированного провайдера
    if (!ref.container.exists(searchResultsProvider(query)) || query != ref.read(searchQueryProvider)) { // Используем поле ref
       timer.cancel(); 
       link.close();
       throw StateError('Search query changed or provider disposed during debounce');
    }

    print('Performing search for: $query');

    // Получаем репозитории через ref.read
    final taskRepo = ref.read(taskRepositoryProvider); // Используем поле ref
    final projectRepo = ref.read(projectRepositoryProvider); // Используем поле ref
    final noteRepo = ref.read(dailyNoteRepositoryProvider); // Используем поле ref

    // Выполняем поиск параллельно
    final results = await Future.wait([
      taskRepo.searchTasks(query),
      projectRepo.searchProjects(query),
      noteRepo.searchNotes(query), 
    ]);

    return SearchResult(
      tasks: results[0] as List<Task>,
      projects: results[1] as List<Project>,
      notes: results[2] as List<DailyNote>,
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Синхронизируем контроллер с провайдером при инициализации
    _searchController.text = ref.read(searchQueryProvider);
    // Обновляем провайдер при изменении текста в контроллере
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    // Получаем результаты поиска, передавая текущий запрос
    final searchResultsAsync = ref.watch(searchResultsProvider(searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Поиск задач, проектов, заметок...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
          ),
          style: TextStyle(color: Theme.of(context).appBarTheme.titleTextStyle?.color),
          onSubmitted: (value) {
             // Можно инициировать поиск здесь, если не используется поиск "на лету"
             print('Search submitted: $value');
          },
        ),
        actions: [
          // Кнопка очистки поля поиска
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Очистить',
              onPressed: () {
                _searchController.clear();
                // ref.read(searchQueryProvider.notifier).state = ''; // Обновится через listener
              },
            ),
        ],
      ),
      body: searchQuery.isEmpty
            ? const Center(child: Text('Введите запрос для поиска.'))
            // Используем when для отображения состояний загрузки/ошибки/данных
            : searchResultsAsync.when(
                data: (results) => _buildResultsList(context, results, searchQuery),
                // Показываем индикатор, только если поиск действительно идет (query не пустой)
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) {
                  // Игнорируем ошибку 'Search query changed during debounce'
                  if (err is StateError && err.message == 'Search query changed during debounce') {
                    return const Center(child: CircularProgressIndicator()); // Показываем загрузку, пока ждем новый результат
                  } 
                  print('Search error: $err\n$st');
                  return Center(
                     child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Ошибка поиска: $err', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                },
             ),
    );
  }

  // Метод для построения списка результатов
  Widget _buildResultsList(BuildContext context, SearchResult results, String query) {
    if (results.isEmpty) {
      return Center(child: Text('По запросу "$query" ничего не найдено.'));
    }

    // Используем ListView.builder для эффективности
    // Объединяем все результаты в один список с разделителями
    List<Widget> listItems = [];

    // Задачи
    if (results.tasks.isNotEmpty) {
      listItems.add(_buildSectionHeader(context, 'Задачи (${results.tasks.length})'));
      listItems.addAll(results.tasks.map((task) => TaskRow(
          task: task,
          onTap: () {
            // Закрываем поиск и открываем задачу в AddTaskSheet
            context.pop();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true, 
              builder: (_) => Padding(
                 padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: AddTaskSheet(taskToEdit: task),
              ),
            );
          },
        )));
    }

    // Проекты
    if (results.projects.isNotEmpty) {
      listItems.add(_buildSectionHeader(context, 'Проекты (${results.projects.length})'));
      listItems.addAll(results.projects.map((project) => ListTile(
            leading: Icon(Icons.topic_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(project.name),
            onTap: () {
              // Устанавливаем выбранный проект
              ref.read(selectedProjectProvider.notifier).state = project.id;
              // Закрываем поиск и переходим к списку задач
              context.pop();
              context.go('/tasks');
            },
          )));
    }

    // Заметки
    if (results.notes.isNotEmpty) {
      listItems.add(_buildSectionHeader(context, 'Заметки (${results.notes.length})'));
      listItems.addAll(results.notes.map((note) => ListTile(
            leading: Icon(Icons.note_alt_outlined, color: Theme.of(context).colorScheme.secondary),
            title: Text('Заметка на ${DateFormat.yMMMd('ru').format(note.date)}'),
            subtitle: Text(
              _extractPlainText(note.content).substring(0, 100),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              // Устанавливаем выбранную дату
              ref.read(selectedDateProvider.notifier).state = note.date;
              // Закрываем поиск и переходим к заметке
              context.pop();
              context.go('/notes');
            },
          )));
    }

    return ListView.separated(
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
      separatorBuilder: (context, index) {
        // Добавляем разделитель после TaskRow или заголовка секции (если это не последний элемент)
        final item = listItems[index];
        if (item is TaskRow && index < listItems.length - 1 && listItems[index+1] is TaskRow) {
           return const Divider(height: 1, indent: 56); // Отступ для задач
        } else if (item is ListTile && index < listItems.length - 1 && listItems[index+1] is ListTile) {
           return const Divider(height: 1, indent: 56); // Отступ для проектов/заметок
        }
         return const SizedBox.shrink(); // Не показываем разделитель после заголовков
      },
      padding: const EdgeInsets.only(bottom: 20), // Отступ снизу
    );
  }

  // Вспомогательный виджет для заголовка секции
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  // Вспомогательная функция для извлечения текста из JSON Quill
  String _extractPlainText(dynamic content) {
     if (content == null) return '[пусто]';
     try {
       if (content is List) {
         final doc = Document.fromJson(content);
         String plainText = doc.toPlainText().trim().replaceAll('\n', ' ');
         return plainText.isEmpty ? '[пусто]' : plainText;
       } else if (content is Map) {
         // Используем jsonEncode/Decode из dart:convert
         final doc = Document.fromJson(jsonDecode(jsonEncode(content)) as List<dynamic>); 
         String plainText = doc.toPlainText().trim().replaceAll('\n', ' ');
         return plainText.isEmpty ? '[пусто]' : plainText;
       } else if (content is String) {
          return content.isEmpty ? '[пусто]' : content.replaceAll('\n', ' ');
       }
     } catch (e) {
       print('Error extracting plain text from search result: $e');
       return '[ошибка отображения]';
     }
     return '[неизвестный формат]';
   }

} 