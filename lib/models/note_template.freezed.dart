// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NoteTemplate _$NoteTemplateFromJson(Map<String, dynamic> json) {
  return _NoteTemplate.fromJson(json);
}

/// @nodoc
mixin _$NoteTemplate {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  Object? get content =>
      throw _privateConstructorUsedError; // JSON (List<Map<String, dynamic>>) из Quill
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this NoteTemplate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NoteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteTemplateCopyWith<NoteTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteTemplateCopyWith<$Res> {
  factory $NoteTemplateCopyWith(
    NoteTemplate value,
    $Res Function(NoteTemplate) then,
  ) = _$NoteTemplateCopyWithImpl<$Res, NoteTemplate>;
  @useResult
  $Res call({
    String id,
    String title,
    Object? content,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$NoteTemplateCopyWithImpl<$Res, $Val extends NoteTemplate>
    implements $NoteTemplateCopyWith<$Res> {
  _$NoteTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = freezed,
    Object? userId = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            content: freezed == content ? _value.content : content,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteTemplateImplCopyWith<$Res>
    implements $NoteTemplateCopyWith<$Res> {
  factory _$$NoteTemplateImplCopyWith(
    _$NoteTemplateImpl value,
    $Res Function(_$NoteTemplateImpl) then,
  ) = __$$NoteTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    Object? content,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$NoteTemplateImplCopyWithImpl<$Res>
    extends _$NoteTemplateCopyWithImpl<$Res, _$NoteTemplateImpl>
    implements _$$NoteTemplateImplCopyWith<$Res> {
  __$$NoteTemplateImplCopyWithImpl(
    _$NoteTemplateImpl _value,
    $Res Function(_$NoteTemplateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? content = freezed,
    Object? userId = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$NoteTemplateImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        content: freezed == content ? _value.content : content,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteTemplateImpl implements _NoteTemplate {
  const _$NoteTemplateImpl({
    required this.id,
    required this.title,
    this.content,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$NoteTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final Object? content;
  // JSON (List<Map<String, dynamic>>) из Quill
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'NoteTemplate(id: $id, title: $title, content: $content, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other.content, content) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    const DeepCollectionEquality().hash(content),
    userId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of NoteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteTemplateImplCopyWith<_$NoteTemplateImpl> get copyWith =>
      __$$NoteTemplateImplCopyWithImpl<_$NoteTemplateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteTemplateImplToJson(this);
  }
}

abstract class _NoteTemplate implements NoteTemplate {
  const factory _NoteTemplate({
    required final String id,
    required final String title,
    final Object? content,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$NoteTemplateImpl;

  factory _NoteTemplate.fromJson(Map<String, dynamic> json) =
      _$NoteTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  Object? get content; // JSON (List<Map<String, dynamic>>) из Quill
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of NoteTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteTemplateImplCopyWith<_$NoteTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
