import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/link.dart';
import '../services/link_repository.dart';

part 'link_providers.g.dart';

// Определяем тип аргумента для family
class BacklinkTarget {
  final LinkEntityType type;
  final String id;

  BacklinkTarget(this.type, this.id);

  // Переопределяем == и hashCode для корректной работы family
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BacklinkTarget &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}

// Provider family для получения информации о бэклинках для конкретной цели
@riverpod
Future<List<BacklinkInfo>> backlinks(BacklinksRef ref, BacklinkTarget target) async {
  final linkRepository = ref.watch(linkRepositoryProvider);
  return linkRepository.getBacklinkInfosForTarget(target.type, target.id);
}

// TODO: Добавить провайдеры для исходящих ссылок, если нужно будет их отображать 