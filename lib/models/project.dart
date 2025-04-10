import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart'; // Для форматирования даты дедлайна

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
class Project with _$Project {
  // Используем factory constructor для freezed
  const factory Project({
    required String id, // Supabase UUIDs приходят как строки
    @JsonKey(name: 'user_id') required String userId,
    // Добавляем статус проекта, по умолчанию 'active'
    @JsonKey(defaultValue: 'active') required String status, 
    // Добавляем дедлайн проекта (может быть null)
    DateTime? deadline,
    required String name,
    String? description, // Добавим описание, если его не было
    @JsonKey(name: 'color_hex') String? colorHex,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Project;

  // Factory constructor для создания из JSON
  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);

  // Добавляем приватный конструктор, необходимый для геттеров во freezed
  const Project._();

  // Вспомогательный геттер для форматированного дедлайна
  String? get formattedDeadline {
    if (deadline == null) return null;
    // Используем DateFormat для локализованного формата даты
    final formatter = DateFormat.yMMMd(); // Например, "Dec 10, 2023" 
    return formatter.format(deadline!); 
  }
} 