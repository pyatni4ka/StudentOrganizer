// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'],
  status: json['status'] as String? ?? 'backlog',
  isCompleted: json['is_completed'] as bool,
  dueDate:
      json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
  projectId: json['project_id'] as String?,
  userId: json['user_id'] as String,
  priority: const TaskPriorityConverter().fromJson(
    (json['priority'] as num).toInt(),
  ),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  dependsOn:
      (json['depends_on'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  blocking:
      (json['blocking'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  parentTaskId: json['parent_task_id'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  recurrenceRule: json['recurrence_rule'] as String?,
  reminderTime:
      json['reminder_time'] == null
          ? null
          : DateTime.parse(json['reminder_time'] as String),
);

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'is_completed': instance.isCompleted,
      'due_date': instance.dueDate?.toIso8601String(),
      'project_id': instance.projectId,
      'user_id': instance.userId,
      'priority': const TaskPriorityConverter().toJson(instance.priority),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'depends_on': instance.dependsOn,
      'blocking': instance.blocking,
      'parent_task_id': instance.parentTaskId,
      'tags': instance.tags,
      'recurrence_rule': instance.recurrenceRule,
      'reminder_time': instance.reminderTime?.toIso8601String(),
    };
