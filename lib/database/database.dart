import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Импортируем модели для конвертеров
import '../models/task.dart' show TaskPriority;
import '../models/link.dart' show LinkEntityType, LinkEntityTypeConverter;

part 'database.g.dart'; // Сгенерированный файл

// --- Конвертер Drift для TaskPriority <-> int ---
class TaskPriorityDriftConverter extends TypeConverter<TaskPriority, int> {
  const TaskPriorityDriftConverter();

  @override
  TaskPriority fromSql(int fromDb) {
    // 0 -> none, 1 -> low, 2 -> medium, 3 -> high 
    return TaskPriority.values[fromDb]; 
  }

  @override
  int toSql(TaskPriority value) {
    // none -> 0, low -> 1, medium -> 2, high -> 3
    return value.index;
  }
}

// --- Конвертер Drift для LinkEntityType <-> int ---
class LinkEntityTypeConverter extends TypeConverter<LinkEntityType, int> {
  const LinkEntityTypeConverter();

  @override
  LinkEntityType fromSql(int fromDb) {
    // 0->task, 1->project, 2->note (согласно enum LinkEntityType)
    return LinkEntityType.values[fromDb];
  }

  @override
  int toSql(LinkEntityType value) {
    return value.index;
  }
}

// --- Определения Таблиц --- 

@DataClassName('ProjectEntry') // Используем суффикс Entry, чтобы не конфликтовать с моделью Project
class Projects extends Table {
  TextColumn get id => text()(); // UUID как текст
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  TextColumn get colorHex => text().named('color_hex').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()(); // Nullable т.к. в БД default
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get deadline => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskEntry')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get projectId => text().named('project_id').nullable().references(Projects, #id, onDelete: KeyAction.setNull)();
  TextColumn get parentTaskId => text().named('parent_task_id').nullable().references(Tasks, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text()();
  // Храним JSON как текст, т.к. drift для SQLite не имеет прямого типа JSON
  // При чтении/записи будем делать jsonEncode/Decode
  TextColumn get description => text().nullable()(); 
  TextColumn get status => text().withDefault(const Constant('todo'))(); 
  BoolColumn get isCompleted => boolean().named('is_completed').withDefault(const Constant(false))();
  DateTimeColumn get dueDate => dateTime().named('due_date').nullable()();
  IntColumn get priority => integer().map(const TaskPriorityDriftConverter()).withDefault(const Constant(0))(); 
  TextColumn get tags => text().named('tags').nullable()();
  TextColumn get recurrenceRule => text().named('recurrence_rule').nullable()();
  DateTimeColumn get reminderTime => dateTime().named('reminder_time').nullable()(); // <-- Поле напоминания
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  // Новые столбцы для зависимостей (храним как JSON Text)
  TextColumn get dependsOn => text().named('depends_on').nullable()();
  TextColumn get blocking => text().named('blocking').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyNoteEntry')
class DailyNotes extends Table {
   TextColumn get id => text()();
   TextColumn get userId => text().named('user_id')();
   DateTimeColumn get date => dateTime()(); // Drift умеет работать с DateTime для date
   // Храним JSON как текст
   TextColumn get content => text().nullable()(); 
   DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
   DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

   @override
   Set<Column> get primaryKey => {id};
   // Уникальный индекс по user_id и date
   @override
   List<String> get customConstraints => ['UNIQUE(user_id, date)'];
}

// Восстанавливаем таблицу Links
@DataClassName('LinkEntry')
class Links extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  IntColumn get sourceType => integer().map(const LinkEntityTypeConverter()).named('source_type')();
  TextColumn get sourceId => text().named('source_id')();
  IntColumn get targetType => integer().map(const LinkEntityTypeConverter()).named('target_type')();
  TextColumn get targetId => text().named('target_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
  // Индекс для быстрого поиска по источнику
  @override
  List<Index> get indexes => [Index('idx_links_source', 'SELECT * FROM links WHERE source_type = ?1 AND source_id = ?2')];
}

// Таблица для хранения информации о прикрепленных файлах
@DataClassName('AttachmentEntry')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get taskId => text().named('task_id').nullable()();
  TextColumn get projectId => text().named('project_id').nullable()();
  TextColumn get fileName => text().named('file_name')();
  TextColumn get storagePath => text().named('storage_path')(); // <-- Изменено имя
  TextColumn get mimeType => text().named('mime_type').nullable()();
  IntColumn get size => integer()(); // <-- Сделано обязательным
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()(); // <-- Сделано nullable

  @override
  Set<Column> get primaryKey => {id};
}

// НОВАЯ ТАБЛИЦА: Шаблоны заметок
@DataClassName('NoteTemplateEntry')
class NoteTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get title => text()(); // Название шаблона
  TextColumn get content => text().nullable()(); // Содержимое шаблона (JSON text)
  DateTimeColumn get createdAt => dateTime().named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Класс Базы Данных --- 

@DriftDatabase(tables: [Tasks, Projects, DailyNotes, Links, Attachments, NoteTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Увеличиваем версию схемы до 4
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      print('Migrating database from $from to $to...');
      if (from < 2) {
        // Миграция с версии 1 на 2: добавляем таблицу DailyNotes и Links
        print('Applying migration for schema version 2...');
        await m.createTable(dailyNotes);
        await m.createTable(links);
      }
      if (from < 3) {
        // Миграция с версии 2 на 3: Добавляем поля depends_on, blocking, parent_task_id, tags, recurrence_rule, reminder_time в Tasks
        print('Applying migration for schema version 3...');
        await m.addColumn(tasks, tasks.dependsOn);
        await m.addColumn(tasks, tasks.blocking);
        await m.addColumn(tasks, tasks.parentTaskId);
        await m.addColumn(tasks, tasks.tags);
        await m.addColumn(tasks, tasks.recurrenceRule);
        await m.addColumn(tasks, tasks.reminderTime);
      }
      if (from < 4) {
        // Миграция с версии 3 на 4: Добавляем поля status и deadline в Projects
        print('Applying migration for schema version 4...');
        await m.addColumn(projects, projects.status);
        await m.addColumn(projects, projects.deadline);
      }
      print('Database migration finished.');
    },
  );

  // --- Доступ к DAO или таблицам --- 
  // Удаляем эти геттеры, так как они генерируются автоматически
  // и их явное определение здесь вызывает конфликты.
  /* 
  @override
  Projects get projects => projects;
  @override
  Tasks get tasks => tasks;
  @override
  DailyNotes get dailyNotes => dailyNotes;
  @override
  Links get links => links;
  @override
  Attachments get attachments => attachments;
  @override
  NoteTemplates get noteTemplates => noteTemplates;
  */
}

// --- Открытие соединения с БД --- 

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'student_organizer_db.sqlite'));

    // Настройка для нативных библиотек SQLite
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    // Важно для macOS и iOS, чтобы найти библиотеку
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}

// --- Провайдер для базы данных --- 

// Создаем синглтон базы данных через Riverpod
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Закрываем БД при диспозе провайдера (важно)
  ref.onDispose(() => db.close()); 
  return db;
}); 