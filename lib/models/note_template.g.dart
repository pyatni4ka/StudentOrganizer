// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteTemplateImpl _$$NoteTemplateImplFromJson(Map<String, dynamic> json) =>
    _$NoteTemplateImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'],
      userId: json['user_id'] as String,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$NoteTemplateImplToJson(_$NoteTemplateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'user_id': instance.userId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
