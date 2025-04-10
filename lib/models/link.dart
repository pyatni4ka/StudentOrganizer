import 'package:freezed_annotation/freezed_annotation.dart';

part 'link.freezed.dart';
part 'link.g.dart';

enum LinkEntityType { task, project, note }

// Конвертер для LinkEntityType <-> text (как в базе Supabase)
class LinkEntityTypeConverter implements JsonConverter<LinkEntityType, String> {
  const LinkEntityTypeConverter();

  @override
  LinkEntityType fromJson(String json) {
    return LinkEntityType.values.firstWhere((e) => e.name == json, 
        orElse: () => throw ArgumentError('Unknown LinkEntityType: $json'));
  }

  @override
  String toJson(LinkEntityType object) {
    return object.name;
  }
}

@freezed
class Link with _$Link {
  const factory Link({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @LinkEntityTypeConverter() @JsonKey(name: 'source_type') required LinkEntityType sourceType,
    @JsonKey(name: 'source_id') required String sourceId,
    @LinkEntityTypeConverter() @JsonKey(name: 'target_type') required LinkEntityType targetType,
    @JsonKey(name: 'target_id') required String targetId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    // Дополнительные поля, если нужны для отображения (например, название цели)
    // String? targetTitle, 
  }) = _Link;

  factory Link.fromJson(Map<String, dynamic> json) => _$LinkFromJson(json);
}

// Класс для хранения информации о бэклинке (для UI)
// Может содержать больше контекста, чем просто модель Link
@freezed
class BacklinkInfo with _$BacklinkInfo {
  const factory BacklinkInfo({
    required String linkId, // ID самой связи
    required LinkEntityType sourceType,
    required String sourceId,
    required String sourceTitleOrDate, // Заголовок задачи/проекта или дата заметки
    // Можно добавить иконку типа
  }) = _BacklinkInfo;

  // Не из JSON напрямую, собирается в репозитории
} 