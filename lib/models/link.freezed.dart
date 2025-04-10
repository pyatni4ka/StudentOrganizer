// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Link _$LinkFromJson(Map<String, dynamic> json) {
  return _Link.fromJson(json);
}

/// @nodoc
mixin _$Link {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @LinkEntityTypeConverter()
  @JsonKey(name: 'source_type')
  LinkEntityType get sourceType => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_id')
  String get sourceId => throw _privateConstructorUsedError;
  @LinkEntityTypeConverter()
  @JsonKey(name: 'target_type')
  LinkEntityType get targetType => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_id')
  String get targetId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Link to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Link
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LinkCopyWith<Link> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LinkCopyWith<$Res> {
  factory $LinkCopyWith(Link value, $Res Function(Link) then) =
      _$LinkCopyWithImpl<$Res, Link>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'source_type')
    LinkEntityType sourceType,
    @JsonKey(name: 'source_id') String sourceId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'target_type')
    LinkEntityType targetType,
    @JsonKey(name: 'target_id') String targetId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$LinkCopyWithImpl<$Res, $Val extends Link>
    implements $LinkCopyWith<$Res> {
  _$LinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Link
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? sourceType = null,
    Object? sourceId = null,
    Object? targetType = null,
    Object? targetId = null,
    Object? createdAt = freezed,
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
            sourceType:
                null == sourceType
                    ? _value.sourceType
                    : sourceType // ignore: cast_nullable_to_non_nullable
                        as LinkEntityType,
            sourceId:
                null == sourceId
                    ? _value.sourceId
                    : sourceId // ignore: cast_nullable_to_non_nullable
                        as String,
            targetType:
                null == targetType
                    ? _value.targetType
                    : targetType // ignore: cast_nullable_to_non_nullable
                        as LinkEntityType,
            targetId:
                null == targetId
                    ? _value.targetId
                    : targetId // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LinkImplCopyWith<$Res> implements $LinkCopyWith<$Res> {
  factory _$$LinkImplCopyWith(
    _$LinkImpl value,
    $Res Function(_$LinkImpl) then,
  ) = __$$LinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'source_type')
    LinkEntityType sourceType,
    @JsonKey(name: 'source_id') String sourceId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'target_type')
    LinkEntityType targetType,
    @JsonKey(name: 'target_id') String targetId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$LinkImplCopyWithImpl<$Res>
    extends _$LinkCopyWithImpl<$Res, _$LinkImpl>
    implements _$$LinkImplCopyWith<$Res> {
  __$$LinkImplCopyWithImpl(_$LinkImpl _value, $Res Function(_$LinkImpl) _then)
    : super(_value, _then);

  /// Create a copy of Link
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? sourceType = null,
    Object? sourceId = null,
    Object? targetType = null,
    Object? targetId = null,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$LinkImpl(
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
        sourceType:
            null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                    as LinkEntityType,
        sourceId:
            null == sourceId
                ? _value.sourceId
                : sourceId // ignore: cast_nullable_to_non_nullable
                    as String,
        targetType:
            null == targetType
                ? _value.targetType
                : targetType // ignore: cast_nullable_to_non_nullable
                    as LinkEntityType,
        targetId:
            null == targetId
                ? _value.targetId
                : targetId // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LinkImpl implements _Link {
  const _$LinkImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'source_type')
    required this.sourceType,
    @JsonKey(name: 'source_id') required this.sourceId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'target_type')
    required this.targetType,
    @JsonKey(name: 'target_id') required this.targetId,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$LinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$LinkImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @LinkEntityTypeConverter()
  @JsonKey(name: 'source_type')
  final LinkEntityType sourceType;
  @override
  @JsonKey(name: 'source_id')
  final String sourceId;
  @override
  @LinkEntityTypeConverter()
  @JsonKey(name: 'target_type')
  final LinkEntityType targetType;
  @override
  @JsonKey(name: 'target_id')
  final String targetId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Link(id: $id, userId: $userId, sourceType: $sourceType, sourceId: $sourceId, targetType: $targetType, targetId: $targetId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LinkImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.targetType, targetType) ||
                other.targetType == targetType) &&
            (identical(other.targetId, targetId) ||
                other.targetId == targetId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    sourceType,
    sourceId,
    targetType,
    targetId,
    createdAt,
  );

  /// Create a copy of Link
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LinkImplCopyWith<_$LinkImpl> get copyWith =>
      __$$LinkImplCopyWithImpl<_$LinkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LinkImplToJson(this);
  }
}

abstract class _Link implements Link {
  const factory _Link({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'source_type')
    required final LinkEntityType sourceType,
    @JsonKey(name: 'source_id') required final String sourceId,
    @LinkEntityTypeConverter()
    @JsonKey(name: 'target_type')
    required final LinkEntityType targetType,
    @JsonKey(name: 'target_id') required final String targetId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$LinkImpl;

  factory _Link.fromJson(Map<String, dynamic> json) = _$LinkImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @LinkEntityTypeConverter()
  @JsonKey(name: 'source_type')
  LinkEntityType get sourceType;
  @override
  @JsonKey(name: 'source_id')
  String get sourceId;
  @override
  @LinkEntityTypeConverter()
  @JsonKey(name: 'target_type')
  LinkEntityType get targetType;
  @override
  @JsonKey(name: 'target_id')
  String get targetId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Link
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LinkImplCopyWith<_$LinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BacklinkInfo {
  String get linkId => throw _privateConstructorUsedError; // ID самой связи
  LinkEntityType get sourceType => throw _privateConstructorUsedError;
  String get sourceId => throw _privateConstructorUsedError;
  String get sourceTitleOrDate => throw _privateConstructorUsedError;

  /// Create a copy of BacklinkInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BacklinkInfoCopyWith<BacklinkInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BacklinkInfoCopyWith<$Res> {
  factory $BacklinkInfoCopyWith(
    BacklinkInfo value,
    $Res Function(BacklinkInfo) then,
  ) = _$BacklinkInfoCopyWithImpl<$Res, BacklinkInfo>;
  @useResult
  $Res call({
    String linkId,
    LinkEntityType sourceType,
    String sourceId,
    String sourceTitleOrDate,
  });
}

/// @nodoc
class _$BacklinkInfoCopyWithImpl<$Res, $Val extends BacklinkInfo>
    implements $BacklinkInfoCopyWith<$Res> {
  _$BacklinkInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BacklinkInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? linkId = null,
    Object? sourceType = null,
    Object? sourceId = null,
    Object? sourceTitleOrDate = null,
  }) {
    return _then(
      _value.copyWith(
            linkId:
                null == linkId
                    ? _value.linkId
                    : linkId // ignore: cast_nullable_to_non_nullable
                        as String,
            sourceType:
                null == sourceType
                    ? _value.sourceType
                    : sourceType // ignore: cast_nullable_to_non_nullable
                        as LinkEntityType,
            sourceId:
                null == sourceId
                    ? _value.sourceId
                    : sourceId // ignore: cast_nullable_to_non_nullable
                        as String,
            sourceTitleOrDate:
                null == sourceTitleOrDate
                    ? _value.sourceTitleOrDate
                    : sourceTitleOrDate // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BacklinkInfoImplCopyWith<$Res>
    implements $BacklinkInfoCopyWith<$Res> {
  factory _$$BacklinkInfoImplCopyWith(
    _$BacklinkInfoImpl value,
    $Res Function(_$BacklinkInfoImpl) then,
  ) = __$$BacklinkInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String linkId,
    LinkEntityType sourceType,
    String sourceId,
    String sourceTitleOrDate,
  });
}

/// @nodoc
class __$$BacklinkInfoImplCopyWithImpl<$Res>
    extends _$BacklinkInfoCopyWithImpl<$Res, _$BacklinkInfoImpl>
    implements _$$BacklinkInfoImplCopyWith<$Res> {
  __$$BacklinkInfoImplCopyWithImpl(
    _$BacklinkInfoImpl _value,
    $Res Function(_$BacklinkInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BacklinkInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? linkId = null,
    Object? sourceType = null,
    Object? sourceId = null,
    Object? sourceTitleOrDate = null,
  }) {
    return _then(
      _$BacklinkInfoImpl(
        linkId:
            null == linkId
                ? _value.linkId
                : linkId // ignore: cast_nullable_to_non_nullable
                    as String,
        sourceType:
            null == sourceType
                ? _value.sourceType
                : sourceType // ignore: cast_nullable_to_non_nullable
                    as LinkEntityType,
        sourceId:
            null == sourceId
                ? _value.sourceId
                : sourceId // ignore: cast_nullable_to_non_nullable
                    as String,
        sourceTitleOrDate:
            null == sourceTitleOrDate
                ? _value.sourceTitleOrDate
                : sourceTitleOrDate // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc

class _$BacklinkInfoImpl implements _BacklinkInfo {
  const _$BacklinkInfoImpl({
    required this.linkId,
    required this.sourceType,
    required this.sourceId,
    required this.sourceTitleOrDate,
  });

  @override
  final String linkId;
  // ID самой связи
  @override
  final LinkEntityType sourceType;
  @override
  final String sourceId;
  @override
  final String sourceTitleOrDate;

  @override
  String toString() {
    return 'BacklinkInfo(linkId: $linkId, sourceType: $sourceType, sourceId: $sourceId, sourceTitleOrDate: $sourceTitleOrDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BacklinkInfoImpl &&
            (identical(other.linkId, linkId) || other.linkId == linkId) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            (identical(other.sourceId, sourceId) ||
                other.sourceId == sourceId) &&
            (identical(other.sourceTitleOrDate, sourceTitleOrDate) ||
                other.sourceTitleOrDate == sourceTitleOrDate));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, linkId, sourceType, sourceId, sourceTitleOrDate);

  /// Create a copy of BacklinkInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BacklinkInfoImplCopyWith<_$BacklinkInfoImpl> get copyWith =>
      __$$BacklinkInfoImplCopyWithImpl<_$BacklinkInfoImpl>(this, _$identity);
}

abstract class _BacklinkInfo implements BacklinkInfo {
  const factory _BacklinkInfo({
    required final String linkId,
    required final LinkEntityType sourceType,
    required final String sourceId,
    required final String sourceTitleOrDate,
  }) = _$BacklinkInfoImpl;

  @override
  String get linkId; // ID самой связи
  @override
  LinkEntityType get sourceType;
  @override
  String get sourceId;
  @override
  String get sourceTitleOrDate;

  /// Create a copy of BacklinkInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BacklinkInfoImplCopyWith<_$BacklinkInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
