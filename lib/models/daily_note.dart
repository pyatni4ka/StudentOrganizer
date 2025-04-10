import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_note.freezed.dart';
part 'daily_note.g.dart';

// Конвертер для Даты (только YYYY-MM-DD) <-> DateTime
// Supabase хранит date как строку в этом формате
class DateConverter implements JsonConverter<DateTime, String> {
  const DateConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json); // Просто парсим строку
  }

  @override
  String toJson(DateTime object) {
    // Форматируем как YYYY-MM-DD
    return '${object.year.toString().padLeft(4, '0')}-${object.month.toString().padLeft(2, '0')}-${object.day.toString().padLeft(2, '0')}';
  }
}

@freezed
class DailyNote with _$DailyNote {
  const factory DailyNote({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @DateConverter() required DateTime date, // Используем конвертер для даты
    // Предполагаем, что Quill Delta хранится как JSON
    // Используем dynamic, так как структура Delta может быть сложной
    Map<String, dynamic>? content, 
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DailyNote;

  factory DailyNote.fromJson(Map<String, dynamic> json) => _$DailyNoteFromJson(json);
} 