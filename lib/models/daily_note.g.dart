// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DailyNoteImpl _$$DailyNoteImplFromJson(Map<String, dynamic> json) =>
    _$DailyNoteImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: const DateConverter().fromJson(json['date'] as String),
      content: json['content'] as Map<String, dynamic>?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$DailyNoteImplToJson(_$DailyNoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'date': const DateConverter().toJson(instance.date),
      'content': instance.content,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
