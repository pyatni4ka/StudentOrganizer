import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Для форматирования размера файла
import 'package:file_picker/file_picker.dart'; // Для выбора файла для загрузки
import 'dart:io'; // Для работы с File

import '../../services/yandex_disk_service.dart'; // Импортируем сервис и провайдеры
import '../../providers/file_providers.dart'; // Импортируем провайдеры файлов

class FileManagerScreen extends ConsumerWidget {
  const FileManagerScreen({super.key});

  // Функция для форматирования размера файла
  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (bytes / 1024).floor();
    if (i >= suffixes.length) i = suffixes.length - 1;
    if (i < 0) i = 0; 
    return '${(bytes / (1024 * i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Следим за состоянием аутентификации Яндекс Диска
    final authState = ref.watch(yandexAuthStateProvider);
    final authNotifier = ref.watch(yandexAuthStateProvider.notifier);
    final isYandexDiskUnsupported = authNotifier.isUnsupported;
    
    // Пытаемся получить состояние списка файлов, но обрабатываем ошибку, если пользователь не вошел
    // Используем AsyncValue.guard для безопасного чтения провайдера, который может выбросить исключение
    final fileListStateAsync = ref.watch(fileListProvider.select((state) => state.items));
    // final fileListStateAsync = AsyncValue.guard(() => ref.watch(fileListProvider.select((state) => state.items)));
    final currentPath = ref.watch(fileListProvider.select((state) => state.currentPath));
    final canGoBack = ref.watch(fileListProvider.select((state) => state.pathHistory.length > 1));
    final fileNotifier = ref.read(fileListProvider.notifier);

    // Определяем, доступен ли fileListProvider (он зависит от authState)
    // final isFileListAvailable = authState.valueOrNull != null && !isYandexDiskUnsupported;

    return Scaffold(
      appBar: AppBar(
        // Добавляем кнопку Назад, если можно вернуться
        leading: canGoBack 
           ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => fileNotifier.goBack(), tooltip: 'Назад')
           : null,
        title: Text(currentPath == '/' ? 'Яндекс Диск' : currentPath.split('/').last), // Показываем имя текущей папки
        actions: [
           // Кнопка Обновить (только если доступно и вошли)
          if (!isYandexDiskUnsupported && authState.valueOrNull != null) 
             IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Обновить',
                onPressed: () => fileNotifier.refresh(),
             ),
           // Кнопка Выход/Вход (только если доступно)
           if (!isYandexDiskUnsupported) 
              authState.maybeWhen(
                data: (token) => token != null
                  ? IconButton(
                      icon: const Icon(Icons.logout),
                      tooltip: 'Выйти из Яндекс Диска',
                      onPressed: () => authNotifier.signOut(),
                    )
                  : IconButton(
                      icon: const Icon(Icons.login),
                      tooltip: 'Войти в Яндекс Диск',
                      onPressed: () => authNotifier.signIn(),
                    ),
                orElse: () => const SizedBox.shrink(), 
             )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0), // Убираем горизонтальный padding
          child: isYandexDiskUnsupported
             ? _buildUnsupportedWidget(context) // Показываем виджет "не поддерживается"
             : authState.when(
                 loading: () => const CircularProgressIndicator(),
                 error: (error, stackTrace) => _buildErrorWidget(context, ref, error), // Выносим виджет ошибки
                 data: (token) {
                   if (token == null) {
                      return _buildLoginWidget(context, ref); // Выносим виджет входа
                   } else {
                     // Пользователь вошел - отображаем список файлов
                     // Проверяем состояние fileListProvider здесь, т.к. он может быть в ошибке
                     return RefreshIndicator( // Добавляем RefreshIndicator
                       onRefresh: () async => fileNotifier.refresh(),
                       child: fileListStateAsync.when(
                         loading: () => const Center(child: CircularProgressIndicator()),
                         error: (error, stack) => _buildErrorWidget(context, ref, error, isFileListError: true), // Ошибка загрузки файлов
                         data: (items) {
                           if (items.isEmpty && currentPath == '/') { // Показываем сообщение только в корне
                             return const Center(child: Text('Ваш Яндекс Диск пуст.', style: TextStyle(color: Colors.grey)));
                           } else if (items.isEmpty) {
                              return const Center(child: Text('Папка пуста.', style: TextStyle(color: Colors.grey)));
                           }
                           return ListView.separated(
                             itemCount: items.length,
                             itemBuilder: (context, index) {
                               final item = items[index];
                               // Формируем подзаголовок отдельно
                               String subtitleText;
                               if (item.isDir) {
                                 subtitleText = 'Папка';
                               } else {
                                 final sizeFormatted = _formatBytes(item.size ?? 0, 1);
                                 final modifiedFormatted = item.modified != null 
                                     ? " - ${DateFormat.yMd('ru').add_Hm().format(item.modified!)}" 
                                     : "";
                                 subtitleText = '$sizeFormatted$modifiedFormatted';
                               }
                               
                               return ListTile(
                                 leading: Icon(item.isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined),
                                 title: Text(item.name),
                                 subtitle: Text(
                                    subtitleText, // Используем сформированную строку
                                    style: Theme.of(context).textTheme.bodySmall, 
                                  ),
                                 trailing: _buildItemActions(context, ref, item), // Добавляем меню действий
                                 onTap: () {
                                   if (item.isDir) {
                                     fileNotifier.openDirectory(item.path);
                                   } else {
                                     // TODO: Возможно, предпросмотр или открытие файла?
                                     _showDownloadConfirmation(context, ref, item);
                                   }
                                 },
                                 onLongPress: () { // Показываем меню по долгому нажатию
                                   _showItemMenu(context, ref, item);
                                 },
                               );
                             },
                             separatorBuilder: (context, index) => const Divider(height: 1), 
                           );
                         },
                       ),
                     );
                   }
                 },
               )
        ),
      ),
      // Добавляем FloatingActionButton
      floatingActionButton: !isYandexDiskUnsupported && authState.valueOrNull != null 
         ? FloatingActionButton(
             tooltip: 'Создать/Загрузить',
             onPressed: () => _showAddMenu(context, ref),
             child: const Icon(Icons.add),
           )
         : null, // Не показываем кнопку, если не вошли
    );
  }

  // Виджет для отображения ошибки
  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object error, {bool isFileListError = false}) {
     return Padding(
       padding: const EdgeInsets.all(16.0),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.error_outline, color: Colors.red, size: 40), 
           const SizedBox(height: 16),
           Text(
             isFileListError ? 'Ошибка загрузки файлов: $error' : 'Ошибка аутентификации: $error', 
             textAlign: TextAlign.center, 
             style: const TextStyle(color: Colors.red)
           ),
           const SizedBox(height: 16),
           if (!isFileListError) // Кнопка повторного входа только при ошибке аутентификации
             ElevatedButton(
               onPressed: () => ref.read(yandexAuthStateProvider.notifier).signIn(), 
               child: const Text('Попробовать войти снова')
             ),
           if (isFileListError) // Кнопка обновления при ошибке загрузки файлов
             ElevatedButton(
               onPressed: () => ref.read(fileListProvider.notifier).refresh(), 
               child: const Text('Попробовать снова')
             ),
         ]
       )
     );
  }

  // Виджет для отображения приглашения ко входу
  Widget _buildLoginWidget(BuildContext context, WidgetRef ref) {
    return Padding(
       padding: const EdgeInsets.all(16.0),
       child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
             const SizedBox(height: 16),
             const Text('Войдите в Яндекс Диск, чтобы просматривать файлы.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
             const SizedBox(height: 16),
             ElevatedButton(onPressed: () => ref.read(yandexAuthStateProvider.notifier).signIn(), child: const Text('Войти в Яндекс Диск')),
          ]
       ),
    );
  }

  // --- Меню действий для элемента списка ---
  Widget _buildItemActions(BuildContext context, WidgetRef ref, DiskItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Действия',
      onSelected: (String result) {
        switch (result) {
          case 'download':
            _showDownloadConfirmation(context, ref, item);
            break;
          case 'delete':
            _showDeleteConfirmation(context, ref, item);
            break;
          // Добавить 'rename', 'move' и т.д. в будущем
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        if (!item.isDir)
           const PopupMenuItem<String>(
              value: 'download',
              child: ListTile(leading: Icon(Icons.download), title: Text('Скачать')),
            ),
        const PopupMenuItem<String>(
           value: 'delete',
           child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Удалить')),
         ),
      ],
    );
  }

  // --- Меню по долгому нажатию (аналогично кнопке) ---
  void _showItemMenu(BuildContext context, WidgetRef ref, DiskItem item) {
     // Можно использовать showModalBottomSheet или другой вид меню
     showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: <Widget>[
              if (!item.isDir)
                ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Скачать'),
                    onTap: () { 
                      Navigator.pop(bc); 
                      _showDownloadConfirmation(context, ref, item);
                    }),
               ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Удалить'),
                  onTap: () { 
                     Navigator.pop(bc);
                     _showDeleteConfirmation(context, ref, item);
                   }),
            ],
          );
        });
  }

  // --- Диалоги подтверждения ---
  void _showDownloadConfirmation(BuildContext context, WidgetRef ref, DiskItem item) async {
    // Запрашиваем подтверждение
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Скачать файл?'),
          content: Text('Скачать файл "${item.name}"?'),
          actions: <Widget>[
            TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(child: const Text('Скачать'), onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );

    if (confirm == true) {
       _downloadFile(context, ref, item);
    }
  }
  
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, DiskItem item) async {
    // Запрашиваем подтверждение
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Удалить ${item.isDir ? 'папку' : 'файл'}?'),
          content: Text('Вы уверены, что хотите удалить "${item.name}"?\nЭто действие необратимо.'),
          actions: <Widget>[
            TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop(false)),
            TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('Удалить')),
          ],
        );
      },
    );

    if (confirm == true) {
       _deleteResource(context, ref, item);
    }
  }

  // --- Логика действий --- 
  Future<void> _downloadFile(BuildContext context, WidgetRef ref, DiskItem item) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Начинаю скачивание ${item.name}...')));
    try {
      final service = ref.read(yandexDiskServiceProvider);
      final downloadUrl = await service.getDownloadLink(item.path);
      if (downloadUrl != null) {
        final downloadedFile = await service.downloadFile(downloadUrl, item.name);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Файл ${item.name} скачан ${downloadedFile != null ? 'в ${downloadedFile.path}' : ''}'),
           action: downloadedFile != null 
              ? SnackBarAction(label: 'Открыть', onPressed: () { /* TODO: Открыть файл */ }) 
              : null,
        ));
      } else {
        throw Exception('Не удалось получить ссылку на скачивание.');
      }
    } catch (e) {
       ScaffoldMessenger.of(context).hideCurrentSnackBar();
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка скачивания: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteResource(BuildContext context, WidgetRef ref, DiskItem item) async {
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Удаление ${item.name}...')));
     try {
       await ref.read(yandexDiskServiceProvider).deleteResource(item.path, permanently: true);
       ref.read(fileListProvider.notifier).refresh(); // Обновляем список
       ScaffoldMessenger.of(context).hideCurrentSnackBar();
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.name}" удален(а).')));
     } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red));
     }
  }
  
  // --- Меню и логика добавления (FAB) ---
  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
             ListTile(
                 leading: const Icon(Icons.create_new_folder_outlined),
                 title: const Text('Создать папку'),
                 onTap: () {
                   Navigator.pop(bc);
                   _showCreateFolderDialog(context, ref);
                 }),
             ListTile(
                 leading: const Icon(Icons.upload_file_outlined),
                 title: const Text('Загрузить файл'),
                 onTap: () {
                   Navigator.pop(bc);
                   _pickAndUploadFile(context, ref);
                 }),
          ],
        );
      },
    );
  }
  
  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Создать новую папку'),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(hintText: "Название папки"),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(child: const Text('Отмена'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('Создать'), 
              onPressed: () {
                 final folderName = folderNameController.text.trim();
                 if (folderName.isNotEmpty) {
                    Navigator.of(context).pop();
                    _createFolder(context, ref, folderName);
                 }
              }),
          ],
        );
      },
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref, String folderName) async {
      final currentPath = ref.read(fileListProvider).currentPath;
      final newPath = currentPath == '/' ? '/$folderName' : '$currentPath/$folderName';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Создание папки $folderName...')));
      try {
        await ref.read(yandexDiskServiceProvider).createFolder(newPath);
        ref.read(fileListProvider.notifier).refresh();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Папка "$folderName" создана.')));
      } catch (e) {
         ScaffoldMessenger.of(context).hideCurrentSnackBar();
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка создания папки: $e'), backgroundColor: Colors.red));
      }
  }

  Future<void> _pickAndUploadFile(BuildContext context, WidgetRef ref) async {
    // Используем file_picker для выбора файла
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      final currentPath = ref.read(fileListProvider).currentPath;
      final diskPath = currentPath == '/' ? '/$fileName' : '$currentPath/$fileName';
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Загрузка файла $fileName...')));
      try {
         final service = ref.read(yandexDiskServiceProvider);
         final uploadUrl = await service.getUploadLink(diskPath, overwrite: false); // Пока не перезаписываем
         if (uploadUrl != null) {
           await service.uploadFile(uploadUrl, file);
           ref.read(fileListProvider.notifier).refresh();
           ScaffoldMessenger.of(context).hideCurrentSnackBar();
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Файл "$fileName" загружен.')));
         } else {
            throw Exception('Не удалось получить ссылку для загрузки (возможно, файл уже существует).');
         }
      } catch (e) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка загрузки файла: $e'), backgroundColor: Colors.red));
      }
    } else {
      // Пользователь отменил выбор файла
      print('File picking cancelled');
    }
  }

  // НОВЫЙ Виджет для отображения "не поддерживается"
  Widget _buildUnsupportedWidget(BuildContext context) {
    return Padding(
       padding: const EdgeInsets.all(16.0),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.desktop_access_disabled_outlined, size: 60, color: Colors.grey),
           const SizedBox(height: 16),
           Text(
             'Интеграция с Яндекс.Диском недоступна на данной платформе (macOS).', 
             textAlign: TextAlign.center, 
             style: TextStyle(fontSize: 16, color: Colors.grey[700]),
           ),
         ]
       ),
    );
  }
} 