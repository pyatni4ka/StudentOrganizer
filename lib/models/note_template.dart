import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_template.freezed.dart';
part 'note_template.g.dart';

@freezed
class NoteTemplate with _$NoteTemplate {
  const factory NoteTemplate({
    required String id,
    required String title,
    Object? content, // JSON (List<Map<String, dynamic>>) из Quill
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _NoteTemplate;

  factory NoteTemplate.fromJson(Map<String, dynamic> json) => _$NoteTemplateFromJson(json);
} 