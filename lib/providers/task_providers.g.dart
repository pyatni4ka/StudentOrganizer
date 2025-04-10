// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskListHash() => r'5fb76beb0a1b9411a7d018f45b3a8a7371fd3186';

/// See also [TaskList].
@ProviderFor(TaskList)
final taskListProvider =
    AutoDisposeAsyncNotifierProvider<TaskList, List<Task>>.internal(
      TaskList.new,
      name: r'taskListProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product') ? null : _$taskListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TaskList = AutoDisposeAsyncNotifier<List<Task>>;
String _$tasksByStatusHash() => r'9c59bc607dfccd04b1cf7d8e52fd7c5ab64f3020';

/// See also [TasksByStatus].
@ProviderFor(TasksByStatus)
final tasksByStatusProvider = AutoDisposeAsyncNotifierProvider<
  TasksByStatus,
  Map<String, List<Task>>
>.internal(
  TasksByStatus.new,
  name: r'tasksByStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tasksByStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TasksByStatus = AutoDisposeAsyncNotifier<Map<String, List<Task>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
