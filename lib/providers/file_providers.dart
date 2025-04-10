import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/yandex_disk_service.dart';

// Модель для представления элемента в списке файлов (упрощенная)
// API Яндекса возвращает больше полей, берем основные
class DiskItem {
  final String name;
  final String path;
  final String type; // 'dir' или 'file'
  final String? mimeType;
  final int? size;
  final DateTime? modified;

  DiskItem({
    required this.name,
    required this.path,
    required this.type,
    this.mimeType,
    this.size,
    this.modified,
  });

  factory DiskItem.fromJson(Map<String, dynamic> json) {
    return DiskItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      type: json['type'] ?? 'file',
      mimeType: json['mime_type'],
      size: json['size'],
      modified: json['modified'] != null ? DateTime.tryParse(json['modified']) : null,
    );
  }

  bool get isDir => type == 'dir';
}

// Состояние для FileListNotifier
class FileListState {
  final AsyncValue<List<DiskItem>> items;
  final String currentPath;
  // Можно добавить историю путей для навигации назад
  final List<String> pathHistory;

  const FileListState({
    this.items = const AsyncValue.loading(),
    this.currentPath = '/', // Начинаем с корня
    this.pathHistory = const ['/'],
  });

  FileListState copyWith({
    AsyncValue<List<DiskItem>>? items,
    String? currentPath,
    List<String>? pathHistory,
  }) {
    return FileListState(
      items: items ?? this.items,
      currentPath: currentPath ?? this.currentPath,
      pathHistory: pathHistory ?? this.pathHistory,
    );
  }
}

// Notifier для управления списком файлов
class FileListNotifier extends StateNotifier<FileListState> {
  final YandexDiskService _yandexService;

  // Основной конструктор
  FileListNotifier(this._yandexService) : super(const FileListState()) {
    // Загружаем файлы для начального пути при инициализации
    _fetchFiles(state.currentPath);
  }
  
  // Конструктор для заглушки или начального состояния ошибки
  FileListNotifier._dummy(this._yandexService, FileListState initialState) : super(initialState);

  Future<void> _fetchFiles(String path) async {
    // Не загружаем, если сервис - заглушка или состояние уже ошибка
    if (_yandexService is DummyYandexDiskService || state.items is AsyncError) return;
    // Устанавливаем состояние загрузки для текущего пути
    state = state.copyWith(items: const AsyncValue.loading(), currentPath: path);
    try {
      final response = await _yandexService.listFiles(path);
      // API Яндекса возвращает вложенные элементы в _embedded.items
      final List<dynamic> itemsJson = response['_embedded']?['items'] ?? [];
      final List<DiskItem> items = itemsJson.map((json) => DiskItem.fromJson(json)).toList();

      // Обновляем состояние с полученными данными
      state = state.copyWith(items: AsyncValue.data(items));
    } catch (e, s) {
      // Обрабатываем ошибку
      print('Error fetching files for path \'$path\': $e');
      state = state.copyWith(items: AsyncValue.error(e, s));
    }
  }

  /// Переход в другую папку
  void openDirectory(String path) {
    if (!path.startsWith('/')) {
      path = state.currentPath == '/' ? '/$path' : '${state.currentPath}/$path';
    }
    print('Opening directory: $path');
    // Добавляем новый путь в историю
    final newHistory = List<String>.from(state.pathHistory)..add(path);
    state = state.copyWith(pathHistory: newHistory); // Обновляем историю ДО загрузки
    _fetchFiles(path);
  }

  /// Переход на уровень вверх
  bool goBack() {
    if (state.pathHistory.length <= 1) {
      return false; // Уже в корне, некуда назад
    }
    print('Going back...');
    final newHistory = List<String>.from(state.pathHistory)..removeLast();
    final previousPath = newHistory.last;
    state = state.copyWith(pathHistory: newHistory); // Обновляем историю
    _fetchFiles(previousPath);
    return true;
  }

  /// Обновить текущую директорию
  void refresh() {
    print('Refreshing path: ${state.currentPath}');
    _fetchFiles(state.currentPath);
  }
}

// Провайдер для FileListNotifier
final fileListProvider = StateNotifierProvider<FileListNotifier, FileListState>((ref) {
  // Зависим от состояния аутентификации
  final authState = ref.watch(yandexAuthStateProvider);
  final yandexService = ref.watch(yandexDiskServiceProvider); // Получаем сервис (может быть заглушкой)
  final authNotifier = ref.watch(yandexAuthStateProvider.notifier); // Получаем нотификатор для флага

  // Если сервис - заглушка (macOS), возвращаем Notifier в состоянии "недоступно"
  if (authNotifier.isUnsupported) {
    // Можно создать специальное состояние ошибки или использовать существующее
    final errorState = FileListState(
      items: AsyncError(
        'Яндекс.Диск недоступен на этой платформе', 
        StackTrace.current
      ),
      currentPath: '-', // Или другое значение, указывающее на недоступность
      pathHistory: const [],
    );
    // Возвращаем Notifier с этим состоянием. Он не будет пытаться загружать файлы.
    return FileListNotifier._dummy(yandexService, errorState);
  } 
  // Если пользователь не аутентифицирован (но сервис НЕ заглушка)
  else if (authState.valueOrNull == null) {
     // Возвращаем Notifier в состоянии "требуется вход"
     // Можно также использовать AsyncError или специальный флаг в состоянии.
     final loginNeededState = FileListState(
      items: AsyncError(
        'Требуется вход в Яндекс.Диск', 
        StackTrace.current
      ),
      currentPath: '-', 
      pathHistory: const [],
    );
     return FileListNotifier._dummy(yandexService, loginNeededState);
  } 
  // Если все ок (не заглушка и пользователь вошел), создаем обычный Notifier
  else {
     return FileListNotifier(yandexService);
  }
}); 