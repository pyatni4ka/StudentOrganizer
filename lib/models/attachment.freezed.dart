// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Attachment _$AttachmentFromJson(Map<String, dynamic> json) {
  return _Attachment.fromJson(json);
}

/// @nodoc
mixin _$Attachment {
  String get id => throw _privateConstructorUsedError; // UUID
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'task_id')
  String? get taskId => throw _privateConstructorUsedError; // Связь с задачей
  @JsonKey(name: 'project_id')
  String? get projectId => throw _privateConstructorUsedError; // Или с проектом (в будущем?)
  @JsonKey(name: 'file_name')
  String get fileName => throw _privateConstructorUsedError; // Путь в Supabase Storage (bucket/user_id/task_id/file_name)
  @JsonKey(name: 'storage_path')
  String get storagePath => throw _privateConstructorUsedError;
  @JsonKey(name: 'mime_type')
  String? get mimeType => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError; // Размер в байтах
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError; // Поле для URL скачивания (не хранится в БД, получается динамически)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get downloadUrl => throw _privateConstructorUsedError;

  /// Serializes this Attachment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttachmentCopyWith<Attachment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttachmentCopyWith<$Res> {
  factory $AttachmentCopyWith(
    Attachment value,
    $Res Function(Attachment) then,
  ) = _$AttachmentCopyWithImpl<$Res, Attachment>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'task_id') String? taskId,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'file_name') String fileName,
    @JsonKey(name: 'storage_path') String storagePath,
    @JsonKey(name: 'mime_type') String? mimeType,
    int size,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false) String? downloadUrl,
  });
}

/// @nodoc
class _$AttachmentCopyWithImpl<$Res, $Val extends Attachment>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? taskId = freezed,
    Object? projectId = freezed,
    Object? fileName = null,
    Object? storagePath = null,
    Object? mimeType = freezed,
    Object? size = null,
    Object? createdAt = freezed,
    Object? downloadUrl = freezed,
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
            taskId:
                freezed == taskId
                    ? _value.taskId
                    : taskId // ignore: cast_nullable_to_non_nullable
                        as String?,
            projectId:
                freezed == projectId
                    ? _value.projectId
                    : projectId // ignore: cast_nullable_to_non_nullable
                        as String?,
            fileName:
                null == fileName
                    ? _value.fileName
                    : fileName // ignore: cast_nullable_to_non_nullable
                        as String,
            storagePath:
                null == storagePath
                    ? _value.storagePath
                    : storagePath // ignore: cast_nullable_to_non_nullable
                        as String,
            mimeType:
                freezed == mimeType
                    ? _value.mimeType
                    : mimeType // ignore: cast_nullable_to_non_nullable
                        as String?,
            size:
                null == size
                    ? _value.size
                    : size // ignore: cast_nullable_to_non_nullable
                        as int,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            downloadUrl:
                freezed == downloadUrl
                    ? _value.downloadUrl
                    : downloadUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AttachmentImplCopyWith<$Res>
    implements $AttachmentCopyWith<$Res> {
  factory _$$AttachmentImplCopyWith(
    _$AttachmentImpl value,
    $Res Function(_$AttachmentImpl) then,
  ) = __$$AttachmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'task_id') String? taskId,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'file_name') String fileName,
    @JsonKey(name: 'storage_path') String storagePath,
    @JsonKey(name: 'mime_type') String? mimeType,
    int size,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false) String? downloadUrl,
  });
}

/// @nodoc
class __$$AttachmentImplCopyWithImpl<$Res>
    extends _$AttachmentCopyWithImpl<$Res, _$AttachmentImpl>
    implements _$$AttachmentImplCopyWith<$Res> {
  __$$AttachmentImplCopyWithImpl(
    _$AttachmentImpl _value,
    $Res Function(_$AttachmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? taskId = freezed,
    Object? projectId = freezed,
    Object? fileName = null,
    Object? storagePath = null,
    Object? mimeType = freezed,
    Object? size = null,
    Object? createdAt = freezed,
    Object? downloadUrl = freezed,
  }) {
    return _then(
      _$AttachmentImpl(
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
        taskId:
            freezed == taskId
                ? _value.taskId
                : taskId // ignore: cast_nullable_to_non_nullable
                    as String?,
        projectId:
            freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                    as String?,
        fileName:
            null == fileName
                ? _value.fileName
                : fileName // ignore: cast_nullable_to_non_nullable
                    as String,
        storagePath:
            null == storagePath
                ? _value.storagePath
                : storagePath // ignore: cast_nullable_to_non_nullable
                    as String,
        mimeType:
            freezed == mimeType
                ? _value.mimeType
                : mimeType // ignore: cast_nullable_to_non_nullable
                    as String?,
        size:
            null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                    as int,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        downloadUrl:
            freezed == downloadUrl
                ? _value.downloadUrl
                : downloadUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AttachmentImpl implements _Attachment {
  const _$AttachmentImpl({
    required this.id,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'task_id') this.taskId,
    @JsonKey(name: 'project_id') this.projectId,
    @JsonKey(name: 'file_name') required this.fileName,
    @JsonKey(name: 'storage_path') required this.storagePath,
    @JsonKey(name: 'mime_type') this.mimeType,
    required this.size,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false) this.downloadUrl,
  });

  factory _$AttachmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttachmentImplFromJson(json);

  @override
  final String id;
  // UUID
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'task_id')
  final String? taskId;
  // Связь с задачей
  @override
  @JsonKey(name: 'project_id')
  final String? projectId;
  // Или с проектом (в будущем?)
  @override
  @JsonKey(name: 'file_name')
  final String fileName;
  // Путь в Supabase Storage (bucket/user_id/task_id/file_name)
  @override
  @JsonKey(name: 'storage_path')
  final String storagePath;
  @override
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  @override
  final int size;
  // Размер в байтах
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  // Поле для URL скачивания (не хранится в БД, получается динамически)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? downloadUrl;

  @override
  String toString() {
    return 'Attachment(id: $id, userId: $userId, taskId: $taskId, projectId: $projectId, fileName: $fileName, storagePath: $storagePath, mimeType: $mimeType, size: $size, createdAt: $createdAt, downloadUrl: $downloadUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    taskId,
    projectId,
    fileName,
    storagePath,
    mimeType,
    size,
    createdAt,
    downloadUrl,
  );

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentImplCopyWith<_$AttachmentImpl> get copyWith =>
      __$$AttachmentImplCopyWithImpl<_$AttachmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttachmentImplToJson(this);
  }
}

abstract class _Attachment implements Attachment {
  const factory _Attachment({
    required final String id,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'task_id') final String? taskId,
    @JsonKey(name: 'project_id') final String? projectId,
    @JsonKey(name: 'file_name') required final String fileName,
    @JsonKey(name: 'storage_path') required final String storagePath,
    @JsonKey(name: 'mime_type') final String? mimeType,
    required final int size,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final String? downloadUrl,
  }) = _$AttachmentImpl;

  factory _Attachment.fromJson(Map<String, dynamic> json) =
      _$AttachmentImpl.fromJson;

  @override
  String get id; // UUID
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'task_id')
  String? get taskId; // Связь с задачей
  @override
  @JsonKey(name: 'project_id')
  String? get projectId; // Или с проектом (в будущем?)
  @override
  @JsonKey(name: 'file_name')
  String get fileName; // Путь в Supabase Storage (bucket/user_id/task_id/file_name)
  @override
  @JsonKey(name: 'storage_path')
  String get storagePath;
  @override
  @JsonKey(name: 'mime_type')
  String? get mimeType;
  @override
  int get size; // Размер в байтах
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt; // Поле для URL скачивания (не хранится в БД, получается динамически)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get downloadUrl;

  /// Create a copy of Attachment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttachmentImplCopyWith<_$AttachmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
