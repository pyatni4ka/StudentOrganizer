// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DailyNote _$DailyNoteFromJson(Map<String, dynamic> json) {
  return _DailyNote.fromJson(json);
}

/// @nodoc
mixin _$DailyNote {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @DateConverter()
  DateTime get date => throw _privateConstructorUsedError; // Используем конвертер для даты
  // Предполагаем, что Quill Delta хранится как JSON
  // Используем dynamic, так как структура Delta может быть сложной
  Map<String, dynamic>? get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this DailyNote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyNoteCopyWith<DailyNote> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyNoteCopyWith<$Res> {
  factory $DailyNoteCopyWith(DailyNote value, $Res Function(DailyNote) then) =
      _$DailyNoteCopyWithImpl<$Res, DailyNote>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @DateConverter() DateTime date,
    Map<String, dynamic>? content,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$DailyNoteCopyWithImpl<$Res, $Val extends DailyNote>
    implements $DailyNoteCopyWith<$Res> {
  _$DailyNoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? content = freezed,
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
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            content:
                freezed == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
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
abstract class _$$DailyNoteImplCopyWith<$Res>
    implements $DailyNoteCopyWith<$Res> {
  factory _$$DailyNoteImplCopyWith(
    _$DailyNoteImpl value,
    $Res Function(_$DailyNoteImpl) then,
  ) = __$$DailyNoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @DateConverter() DateTime date,
    Map<String, dynamic>? content,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$DailyNoteImplCopyWithImpl<$Res>
    extends _$DailyNoteCopyWithImpl<$Res, _$DailyNoteImpl>
    implements _$$DailyNoteImplCopyWith<$Res> {
  __$$DailyNoteImplCopyWithImpl(
    _$DailyNoteImpl _value,
    $Res Function(_$DailyNoteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DailyNote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? date = null,
    Object? content = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$DailyNoteImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        content:
            freezed == content
                ? _value._content
                : content // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
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
class _$DailyNoteImpl implements _DailyNote {
  const _$DailyNoteImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @DateConverter() required this.date,
    final Map<String, dynamic>? content,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _content = content;

  factory _$DailyNoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyNoteImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @DateConverter()
  final DateTime date;
  // Используем конвертер для даты
  // Предполагаем, что Quill Delta хранится как JSON
  // Используем dynamic, так как структура Delta может быть сложной
  final Map<String, dynamic>? _content;
  // Используем конвертер для даты
  // Предполагаем, что Quill Delta хранится как JSON
  // Используем dynamic, так как структура Delta может быть сложной
  @override
  Map<String, dynamic>? get content {
    final value = _content;
    if (value == null) return null;
    if (_content is EqualUnmodifiableMapView) return _content;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'DailyNote(id: $id, userId: $userId, date: $date, content: $content, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyNoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality().equals(other._content, _content) &&
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
    userId,
    date,
    const DeepCollectionEquality().hash(_content),
    createdAt,
    updatedAt,
  );

  /// Create a copy of DailyNote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyNoteImplCopyWith<_$DailyNoteImpl> get copyWith =>
      __$$DailyNoteImplCopyWithImpl<_$DailyNoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyNoteImplToJson(this);
  }
}

abstract class _DailyNote implements DailyNote {
  const factory _DailyNote({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @DateConverter() required final DateTime date,
    final Map<String, dynamic>? content,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$DailyNoteImpl;

  factory _DailyNote.fromJson(Map<String, dynamic> json) =
      _$DailyNoteImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @DateConverter()
  DateTime get date; // Используем конвертер для даты
  // Предполагаем, что Quill Delta хранится как JSON
  // Используем dynamic, так как структура Delta может быть сложной
  @override
  Map<String, dynamic>? get content;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of DailyNote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyNoteImplCopyWith<_$DailyNoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
