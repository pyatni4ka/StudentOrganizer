// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LinkImpl _$$LinkImplFromJson(Map<String, dynamic> json) => _$LinkImpl(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  sourceType: const LinkEntityTypeConverter().fromJson(
    json['source_type'] as String,
  ),
  sourceId: json['source_id'] as String,
  targetType: const LinkEntityTypeConverter().fromJson(
    json['target_type'] as String,
  ),
  targetId: json['target_id'] as String,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$LinkImplToJson(
  _$LinkImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'source_type': const LinkEntityTypeConverter().toJson(instance.sourceType),
  'source_id': instance.sourceId,
  'target_type': const LinkEntityTypeConverter().toJson(instance.targetType),
  'target_id': instance.targetId,
  'created_at': instance.createdAt?.toIso8601String(),
};
