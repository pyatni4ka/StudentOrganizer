// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$backlinksHash() => r'6e6177410057921fd7dff31081ef4f50f271d8ae';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [backlinks].
@ProviderFor(backlinks)
const backlinksProvider = BacklinksFamily();

/// See also [backlinks].
class BacklinksFamily extends Family<AsyncValue<List<BacklinkInfo>>> {
  /// See also [backlinks].
  const BacklinksFamily();

  /// See also [backlinks].
  BacklinksProvider call(BacklinkTarget target) {
    return BacklinksProvider(target);
  }

  @override
  BacklinksProvider getProviderOverride(covariant BacklinksProvider provider) {
    return call(provider.target);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'backlinksProvider';
}

/// See also [backlinks].
class BacklinksProvider extends AutoDisposeFutureProvider<List<BacklinkInfo>> {
  /// See also [backlinks].
  BacklinksProvider(BacklinkTarget target)
    : this._internal(
        (ref) => backlinks(ref as BacklinksRef, target),
        from: backlinksProvider,
        name: r'backlinksProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$backlinksHash,
        dependencies: BacklinksFamily._dependencies,
        allTransitiveDependencies: BacklinksFamily._allTransitiveDependencies,
        target: target,
      );

  BacklinksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.target,
  }) : super.internal();

  final BacklinkTarget target;

  @override
  Override overrideWith(
    FutureOr<List<BacklinkInfo>> Function(BacklinksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BacklinksProvider._internal(
        (ref) => create(ref as BacklinksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        target: target,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BacklinkInfo>> createElement() {
    return _BacklinksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BacklinksProvider && other.target == target;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, target.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BacklinksRef on AutoDisposeFutureProviderRef<List<BacklinkInfo>> {
  /// The parameter `target` of this provider.
  BacklinkTarget get target;
}

class _BacklinksProviderElement
    extends AutoDisposeFutureProviderElement<List<BacklinkInfo>>
    with BacklinksRef {
  _BacklinksProviderElement(super.provider);

  @override
  BacklinkTarget get target => (origin as BacklinksProvider).target;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
