import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
class Attachment with _$Attachment {
  const factory Attachment({
    required String id, // UUID
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'task_id') String? taskId, // Связь с задачей
    @JsonKey(name: 'project_id') String? projectId, // Или с проектом (в будущем?)
    @JsonKey(name: 'file_name') required String fileName,
    // Путь в Supabase Storage (bucket/user_id/task_id/file_name)
    @JsonKey(name: 'storage_path') required String storagePath, 
    @JsonKey(name: 'mime_type') String? mimeType,
    required int size, // Размер в байтах
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // Поле для URL скачивания (не хранится в БД, получается динамически)
    @JsonKey(includeFromJson: false, includeToJson: false) String? downloadUrl,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) => _$AttachmentFromJson(json);
} 