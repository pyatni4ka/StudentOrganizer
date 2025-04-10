// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  String get id =>
      throw _privateConstructorUsedError; // Supabase UUIDs приходят как строки
  String get title => throw _privateConstructorUsedError;
  Object? get description =>
      throw _privateConstructorUsedError; // Используем Object? для поддержки JSON из Quill
  String get status =>
      throw _privateConstructorUsedError; // Поле для статуса Kanban
  @JsonKey(name: 'is_completed')
  bool get isCompleted => throw _privateConstructorUsedError;
  @JsonKey(name: 'due_date')
  DateTime? get dueDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_id')
  String? get projectId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @TaskPriorityConverter()
  TaskPriority get priority => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'depends_on')
  List<String> get dependsOn => throw _privateConstructorUsedError;
  @JsonKey(name: 'blocking')
  List<String> get blocking => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_task_id')
  String? get parentTaskId => throw _privateConstructorUsedError;
  @JsonKey(name: 'tags')
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule => throw _privateConstructorUsedError;
  @JsonKey(name: 'reminder_time')
  DateTime? get reminderTime => throw _privateConstructorUsedError;

  /// Serializes this Task to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call({
    String id,
    String title,
    Object? description,
    String status,
    @JsonKey(name: 'is_completed') bool isCompleted,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'user_id') String userId,
    @TaskPriorityConverter() TaskPriority priority,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'depends_on') List<String> dependsOn,
    @JsonKey(name: 'blocking') List<String> blocking,
    @JsonKey(name: 'parent_task_id') String? parentTaskId,
    @JsonKey(name: 'tags') List<String> tags,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'reminder_time') DateTime? reminderTime,
  });
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? isCompleted = null,
    Object? dueDate = freezed,
    Object? projectId = freezed,
    Object? userId = null,
    Object? priority = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? dependsOn = null,
    Object? blocking = null,
    Object? parentTaskId = freezed,
    Object? tags = null,
    Object? recurrenceRule = freezed,
    Object? reminderTime = freezed,
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
            description:
                freezed == description ? _value.description : description,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            isCompleted:
                null == isCompleted
                    ? _value.isCompleted
                    : isCompleted // ignore: cast_nullable_to_non_nullable
                        as bool,
            dueDate:
                freezed == dueDate
                    ? _value.dueDate
                    : dueDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            projectId:
                freezed == projectId
                    ? _value.projectId
                    : projectId // ignore: cast_nullable_to_non_nullable
                        as String?,
            userId:
                null == userId
                    ? _value.userId
                    : userId // ignore: cast_nullable_to_non_nullable
                        as String,
            priority:
                null == priority
                    ? _value.priority
                    : priority // ignore: cast_nullable_to_non_nullable
                        as TaskPriority,
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
            dependsOn:
                null == dependsOn
                    ? _value.dependsOn
                    : dependsOn // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            blocking:
                null == blocking
                    ? _value.blocking
                    : blocking // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            parentTaskId:
                freezed == parentTaskId
                    ? _value.parentTaskId
                    : parentTaskId // ignore: cast_nullable_to_non_nullable
                        as String?,
            tags:
                null == tags
                    ? _value.tags
                    : tags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            recurrenceRule:
                freezed == recurrenceRule
                    ? _value.recurrenceRule
                    : recurrenceRule // ignore: cast_nullable_to_non_nullable
                        as String?,
            reminderTime:
                freezed == reminderTime
                    ? _value.reminderTime
                    : reminderTime // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
    _$TaskImpl value,
    $Res Function(_$TaskImpl) then,
  ) = __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    Object? description,
    String status,
    @JsonKey(name: 'is_completed') bool isCompleted,
    @JsonKey(name: 'due_date') DateTime? dueDate,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'user_id') String userId,
    @TaskPriorityConverter() TaskPriority priority,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'depends_on') List<String> dependsOn,
    @JsonKey(name: 'blocking') List<String> blocking,
    @JsonKey(name: 'parent_task_id') String? parentTaskId,
    @JsonKey(name: 'tags') List<String> tags,
    @JsonKey(name: 'recurrence_rule') String? recurrenceRule,
    @JsonKey(name: 'reminder_time') DateTime? reminderTime,
  });
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
    : super(_value, _then);

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? isCompleted = null,
    Object? dueDate = freezed,
    Object? projectId = freezed,
    Object? userId = null,
    Object? priority = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? dependsOn = null,
    Object? blocking = null,
    Object? parentTaskId = freezed,
    Object? tags = null,
    Object? recurrenceRule = freezed,
    Object? reminderTime = freezed,
  }) {
    return _then(
      _$TaskImpl(
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
        description: freezed == description ? _value.description : description,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        isCompleted:
            null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                    as bool,
        dueDate:
            freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        projectId:
            freezed == projectId
                ? _value.projectId
                : projectId // ignore: cast_nullable_to_non_nullable
                    as String?,
        userId:
            null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                    as String,
        priority:
            null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                    as TaskPriority,
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
        dependsOn:
            null == dependsOn
                ? _value._dependsOn
                : dependsOn // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        blocking:
            null == blocking
                ? _value._blocking
                : blocking // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        parentTaskId:
            freezed == parentTaskId
                ? _value.parentTaskId
                : parentTaskId // ignore: cast_nullable_to_non_nullable
                    as String?,
        tags:
            null == tags
                ? _value._tags
                : tags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        recurrenceRule:
            freezed == recurrenceRule
                ? _value.recurrenceRule
                : recurrenceRule // ignore: cast_nullable_to_non_nullable
                    as String?,
        reminderTime:
            freezed == reminderTime
                ? _value.reminderTime
                : reminderTime // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskImpl implements _Task {
  const _$TaskImpl({
    required this.id,
    required this.title,
    this.description,
    this.status = 'backlog',
    @JsonKey(name: 'is_completed') required this.isCompleted,
    @JsonKey(name: 'due_date') this.dueDate,
    @JsonKey(name: 'project_id') this.projectId,
    @JsonKey(name: 'user_id') required this.userId,
    @TaskPriorityConverter() required this.priority,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'depends_on') final List<String> dependsOn = const [],
    @JsonKey(name: 'blocking') final List<String> blocking = const [],
    @JsonKey(name: 'parent_task_id') this.parentTaskId,
    @JsonKey(name: 'tags') final List<String> tags = const [],
    @JsonKey(name: 'recurrence_rule') this.recurrenceRule,
    @JsonKey(name: 'reminder_time') this.reminderTime,
  }) : _dependsOn = dependsOn,
       _blocking = blocking,
       _tags = tags;

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final String id;
  // Supabase UUIDs приходят как строки
  @override
  final String title;
  @override
  final Object? description;
  // Используем Object? для поддержки JSON из Quill
  @override
  @JsonKey()
  final String status;
  // Поле для статуса Kanban
  @override
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @override
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  @override
  @JsonKey(name: 'project_id')
  final String? projectId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @TaskPriorityConverter()
  final TaskPriority priority;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<String> _dependsOn;
  @override
  @JsonKey(name: 'depends_on')
  List<String> get dependsOn {
    if (_dependsOn is EqualUnmodifiableListView) return _dependsOn;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependsOn);
  }

  final List<String> _blocking;
  @override
  @JsonKey(name: 'blocking')
  List<String> get blocking {
    if (_blocking is EqualUnmodifiableListView) return _blocking;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blocking);
  }

  @override
  @JsonKey(name: 'parent_task_id')
  final String? parentTaskId;
  final List<String> _tags;
  @override
  @JsonKey(name: 'tags')
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: 'recurrence_rule')
  final String? recurrenceRule;
  @override
  @JsonKey(name: 'reminder_time')
  final DateTime? reminderTime;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, description: $description, status: $status, isCompleted: $isCompleted, dueDate: $dueDate, projectId: $projectId, userId: $userId, priority: $priority, createdAt: $createdAt, updatedAt: $updatedAt, dependsOn: $dependsOn, blocking: $blocking, parentTaskId: $parentTaskId, tags: $tags, recurrenceRule: $recurrenceRule, reminderTime: $reminderTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(
              other.description,
              description,
            ) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._dependsOn,
              _dependsOn,
            ) &&
            const DeepCollectionEquality().equals(other._blocking, _blocking) &&
            (identical(other.parentTaskId, parentTaskId) ||
                other.parentTaskId == parentTaskId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            (identical(other.reminderTime, reminderTime) ||
                other.reminderTime == reminderTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    const DeepCollectionEquality().hash(description),
    status,
    isCompleted,
    dueDate,
    projectId,
    userId,
    priority,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_dependsOn),
    const DeepCollectionEquality().hash(_blocking),
    parentTaskId,
    const DeepCollectionEquality().hash(_tags),
    recurrenceRule,
    reminderTime,
  );

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(this);
  }
}

abstract class _Task implements Task {
  const factory _Task({
    required final String id,
    required final String title,
    final Object? description,
    final String status,
    @JsonKey(name: 'is_completed') required final bool isCompleted,
    @JsonKey(name: 'due_date') final DateTime? dueDate,
    @JsonKey(name: 'project_id') final String? projectId,
    @JsonKey(name: 'user_id') required final String userId,
    @TaskPriorityConverter() required final TaskPriority priority,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'depends_on') final List<String> dependsOn,
    @JsonKey(name: 'blocking') final List<String> blocking,
    @JsonKey(name: 'parent_task_id') final String? parentTaskId,
    @JsonKey(name: 'tags') final List<String> tags,
    @JsonKey(name: 'recurrence_rule') final String? recurrenceRule,
    @JsonKey(name: 'reminder_time') final DateTime? reminderTime,
  }) = _$TaskImpl;

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  String get id; // Supabase UUIDs приходят как строки
  @override
  String get title;
  @override
  Object? get description; // Используем Object? для поддержки JSON из Quill
  @override
  String get status; // Поле для статуса Kanban
  @override
  @JsonKey(name: 'is_completed')
  bool get isCompleted;
  @override
  @JsonKey(name: 'due_date')
  DateTime? get dueDate;
  @override
  @JsonKey(name: 'project_id')
  String? get projectId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @TaskPriorityConverter()
  TaskPriority get priority;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'depends_on')
  List<String> get dependsOn;
  @override
  @JsonKey(name: 'blocking')
  List<String> get blocking;
  @override
  @JsonKey(name: 'parent_task_id')
  String? get parentTaskId;
  @override
  @JsonKey(name: 'tags')
  List<String> get tags;
  @override
  @JsonKey(name: 'recurrence_rule')
  String? get recurrenceRule;
  @override
  @JsonKey(name: 'reminder_time')
  DateTime? get reminderTime;

  /// Create a copy of Task
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
