import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

// Перечисление для приоритета
enum TaskPriority {
  none,
  low,
  medium,
  high
}

// Конвертер для TaskPriority <-> int (как в базе Supabase)
class TaskPriorityConverter implements JsonConverter<TaskPriority, int> {
  const TaskPriorityConverter();

  @override
  TaskPriority fromJson(int json) {
    // 0 -> none, 1 -> low, 2 -> medium, 3 -> high (согласно схеме БД)
    return TaskPriority.values[json]; 
  }

  @override
  int toJson(TaskPriority object) {
    // none -> 0, low -> 1, medium -> 2, high -> 3
    return object.index;
  }
}

@freezed
class Task with _$Task {
  const factory Task({
    required String id, // Supabase UUIDs приходят как строки
    required String title,
    Object? description, // Используем Object? для поддержки JSON из Quill
    @Default('backlog') String status, // Поле для статуса Kanban
    @JsonKey(name: 'is_completed') required bool isCompleted,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'user_id') required String userId,
    @TaskPriorityConverter() required TaskPriority priority,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'depends_on') @Default([]) List<String> dependsOn,
    @JsonKey(name: 'blocking') @Default([]) List<String> blocking,
    @JsonKey(name: 'parent_task_id') String? parentTaskId,
    @JsonKey(name: 'tags') @Default([]) List<String> tags,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'reminder_time') DateTime? reminderTime,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
} 