import 'dart:async';
import 'dart:io'; // Для работы с File И ПРОВЕРКИ ПЛАТФОРМЫ

import 'package:dio/dio.dart' as dio; // Импортируем dio с префиксом
import 'package:flutter/foundation.dart' show kIsWeb; // Для проверки Web
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Для безопасного хранения токена
import 'package:path_provider/path_provider.dart'; // Для пути сохранения
import 'package:path/path.dart' as p; // Для работы с путями

// --- Константы (вынести в отдельный файл или конфигурацию) ---
const String YANDEX_CLIENT_ID = 'e09038f3161d4811a14177d4d5795edc'; // Твой Client ID
const String YANDEX_REDIRECT_URI = 'studorgyd://oauth-callback'; // Твой Redirect URI
const String YANDEX_AUTHORIZATION_ENDPOINT = 'https://oauth.yandex.ru/authorize';
const String YANDEX_TOKEN_ENDPOINT = 'https://oauth.yandex.ru/token';
const List<String> YANDEX_SCOPES = ['cloud_api:disk.read', 'cloud_api:disk.write']; // Запрашиваемые права

// --- ЗАГЛУШКИ ДЛЯ НЕПОДДЕРЖИВАЕМЫХ ПЛАТФОРМ ---

// Заглушка для SecureStorage
class _DummySecureStorage implements FlutterSecureStorage {
  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions}) async {}
  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions}) async => null;
  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions}) async => false;
  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions}) async {}
  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions}) async => {};
  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions}) async {}
  @override
  AndroidOptions get aOptions => const AndroidOptions();
  @override
  IOSOptions get iOptions => const IOSOptions();
  @override
  LinuxOptions get lOptions => const LinuxOptions();
  @override
  Stream<bool> get isAuthenticationAvailable => Stream.value(false);
}

// Заглушка для YandexDiskService
class DummyYandexDiskService implements YandexDiskService {
  @override
  FlutterSecureStorage get _secureStorage => _DummySecureStorage(); 
  @override
  FlutterAppAuth get _appAuth => const FlutterAppAuth();
  @override
  dio.Dio get _dio => dio.Dio();
  @override
  Future<void> signIn() async { throw UnimplementedError('Yandex Disk not supported on this platform'); }
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> getAccessToken() async => null;
  @override
  Future<Map<String, dynamic>> getDiskInfo() async => {};
  @override
  Future<Map<String, dynamic>> listFiles(String path, {int limit = 20, int offset = 0}) async => {'_embedded': {'items': []}};
  @override
  Future<String?> getUploadLink(String diskPath, {bool overwrite = false}) async => null;
  @override
  Future<void> uploadFile(String uploadUrl, File file) async { throw UnimplementedError('Yandex Disk not supported on this platform'); }
  @override
  Future<String?> getDownloadLink(String diskPath) async => null;
  @override
  Future<File?> downloadFile(String downloadUrl, String fileName) async => null;
  @override
  Future<void> createFolder(String diskPath) async { throw UnimplementedError('Yandex Disk not supported on this platform'); }
  @override
  Future<void> deleteResource(String diskPath, {bool permanently = false}) async { throw UnimplementedError('Yandex Disk not supported on this platform'); }
  @override
  Future<String?> _refreshAccessToken() async => null;
  @override
  Future<void> _saveTokens(String? accessToken, String? refreshToken, DateTime? expiry) async {}
  @override
  Future<DateTime?> _getExpiryDateTime() async => null;
}

// --- КОНЕЦ ЗАГЛУШЕК ---

// Провайдер для безопасного хранилища (с проверкой платформы)
final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  // Возвращаем заглушку для macOS и Web (где плагин не работает)
  if (!kIsWeb && Platform.isMacOS) {
    print('Using DummySecureStorage for macOS');
    return _DummySecureStorage();
  }
  // На других платформах (iOS, Android) используем реальный плагин
  return const FlutterSecureStorage();
});

// Провайдер для YandexDiskService (с проверкой платформы)
final yandexDiskServiceProvider = Provider<YandexDiskService>((ref) {
   // Возвращаем заглушку для macOS и Web
  if (!kIsWeb && Platform.isMacOS) {
    print('Using DummyYandexDiskService for macOS');
    return DummyYandexDiskService();
  }
  // На других платформах создаем РЕАЛЬНЫЙ сервис
  return YandexDiskServiceImpl(
    ref.watch(secureStorageProvider),
    const FlutterAppAuth(), 
    dio.Dio(),
  );
});

// Провайдер для состояния аутентификации Яндекс Диска (с проверкой платформы)
final yandexAuthStateProvider = StateNotifierProvider<YandexAuthStateNotifier, AsyncValue<String?>>((ref) {
  // Для macOS сразу возвращаем "не аутентифицирован"
   if (!kIsWeb && Platform.isMacOS) {
     // Создаем Notifier с заглушкой
    return YandexAuthStateNotifier._dummy(); 
  }
  // Для других платформ работаем как обычно, используем РЕАЛЬНЫЙ сервис
  return YandexAuthStateNotifier(ref.watch(yandexDiskServiceProvider));
});

class YandexAuthStateNotifier extends StateNotifier<AsyncValue<String?>> {
  final YandexDiskService _service;
  
  // Обычный конструктор
  YandexAuthStateNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadToken();
  }

  // Приватный конструктор для заглушки на macOS
  YandexAuthStateNotifier._dummy() : _service = DummyYandexDiskService(), super(const AsyncValue.data(null));

  // Флаг для определения, используется ли заглушка
  bool get isUnsupported => _service is DummyYandexDiskService;

  Future<void> _loadToken() async {
     // Если используется заглушка, не пытаемся загрузить токен
     if (isUnsupported) return;
    try {
      final token = await _service.getAccessToken();
      state = AsyncValue.data(token);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signIn() async {
    state = const AsyncValue.loading();
    try {
      await _service.signIn();
      final token = await _service.getAccessToken();
      state = AsyncValue.data(token);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _service.signOut();
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

// Определяем YandexDiskService как абстрактный класс (интерфейс)
abstract class YandexDiskService {
  FlutterSecureStorage get _secureStorage; 
  FlutterAppAuth get _appAuth;
  dio.Dio get _dio;
  
  Future<void> signIn();
  Future<void> signOut();
  Future<String?> getAccessToken();
  Future<String?> _refreshAccessToken(); 
  Future<void> _saveTokens(String? accessToken, String? refreshToken, DateTime? expiry);
  Future<DateTime?> _getExpiryDateTime();
  Future<Map<String, dynamic>> getDiskInfo();
  Future<Map<String, dynamic>> listFiles(String path, {int limit = 20, int offset = 0});
  Future<String?> getUploadLink(String diskPath, {bool overwrite = false});
  Future<void> uploadFile(String uploadUrl, File file);
  Future<String?> getDownloadLink(String diskPath);
  Future<File?> downloadFile(String downloadUrl, String fileName);
  Future<void> createFolder(String diskPath);
  Future<void> deleteResource(String diskPath, {bool permanently = false});
}

// Реализация YandexDiskService
class YandexDiskServiceImpl implements YandexDiskService {
  @override
  final FlutterSecureStorage _secureStorage;
  @override
  final FlutterAppAuth _appAuth;
  @override
  final dio.Dio _dio; 

  static const String _refreshTokenKey = 'yandex_refresh_token';
  static const String _accessTokenKey = 'yandex_access_token';
  static const String _accessTokenExpiryKey = 'yandex_access_token_expiry';

  String? _cachedAccessToken;

  YandexDiskServiceImpl(this._secureStorage, this._appAuth, this._dio) {
    // Настройка Dio (добавление интерцептора для автоматического добавления токена)
    _dio.interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getAccessToken(); // Получаем актуальный токен
        if (token != null) {
          options.headers['Authorization'] = 'OAuth $token';
        }
        return handler.next(options); // Продолжаем запрос
      },
      onError: (dio.DioException e, handler) async {
         // TODO: Обработка ошибок, например, 401 Unauthorized - попытка обновить токен
         if (e.response?.statusCode == 401) {
           print('Yandex API returned 401, attempting token refresh...');
           try {
             final newToken = await _refreshAccessToken();
             if (newToken != null) {
               // Повторяем изначальный запрос с новым токеном
               final options = e.requestOptions;
               options.headers['Authorization'] = 'OAuth $newToken';
               final response = await _dio.fetch(options);
               return handler.resolve(response);
             } else {
                print('Failed to refresh token after 401.');
                await signOut(); // Выходим, если не смогли обновить токен
             }
           } catch (refreshError) {
              print('Error during token refresh: $refreshError');
              await signOut();
           }
         }
        return handler.next(e); // Пробрасываем ошибку дальше, если это не 401 или обновление не удалось
      }
    ));
  }

  @override
  Future<void> signIn() async {
    try {
      final AuthorizationTokenResponse result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          YANDEX_CLIENT_ID,
          YANDEX_REDIRECT_URI,
          serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: YANDEX_AUTHORIZATION_ENDPOINT,
            tokenEndpoint: YANDEX_TOKEN_ENDPOINT,
          ),
          scopes: YANDEX_SCOPES,
          promptValues: ['login', 'consent'],
        ),
      );

      print('Yandex OAuth Success!');
      await _saveTokens(
        result.accessToken,
        result.refreshToken,
        result.accessTokenExpirationDateTime
      );
       _cachedAccessToken = result.accessToken;
        } catch (e) {
      print('Error during Yandex OAuth: $e');
      // Перевыбрасываем исключение для обработки в UI
      throw Exception('Ошибка авторизации Яндекс: $e');
    }
  }

  @override
  Future<void> signOut() async {
     _cachedAccessToken = null;
     await _secureStorage.delete(key: _refreshTokenKey);
     await _secureStorage.delete(key: _accessTokenKey);
     await _secureStorage.delete(key: _accessTokenExpiryKey);
     print('Yandex tokens cleared.');
  }

  @override
  Future<String?> getAccessToken() async {
    // 1. Проверяем кэш
    if (_cachedAccessToken != null) {
       final expiry = await _getExpiryDateTime();
       if (expiry != null && expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
         // Токен в кэше еще действителен (с запасом в 1 минуту)
         return _cachedAccessToken;
       }
    }

    // 2. Проверяем хранилище
    final storedToken = await _secureStorage.read(key: _accessTokenKey);
    final expiry = await _getExpiryDateTime();

    if (storedToken != null && expiry != null && expiry.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
       _cachedAccessToken = storedToken;
       return storedToken;
    }

    // 3. Если токена нет или он истек, пытаемся обновить
     print('Access token expired or missing, attempting refresh...');
    return await _refreshAccessToken();
  }

  @override
  Future<String?> _refreshAccessToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      print('No refresh token found for Yandex.');
      await signOut(); // Если нет refresh token, нужно снова войти
      return null;
    }

    try {
      final TokenResponse result = await _appAuth.token(
        TokenRequest(
          YANDEX_CLIENT_ID,
          YANDEX_REDIRECT_URI,
          refreshToken: refreshToken,
          issuer: 'https://oauth.yandex.ru', // Указываем issuer
          // clientSecret: null, // Secret не нужен для публичных клиентов
           serviceConfiguration: const AuthorizationServiceConfiguration(
             authorizationEndpoint: YANDEX_AUTHORIZATION_ENDPOINT,
             tokenEndpoint: YANDEX_TOKEN_ENDPOINT,
           ),
          scopes: YANDEX_SCOPES,
        ),
      );

      print('Yandex Token Refresh Success!');
      await _saveTokens(
        result.accessToken,
        result.refreshToken ?? refreshToken, // Яндекс может не вернуть refresh token при обновлении
        result.accessTokenExpirationDateTime
      );
      _cachedAccessToken = result.accessToken;
      return result.accessToken;
        } catch (e) {
      print('Error refreshing Yandex token: $e');
       await signOut(); // Выходим при ошибке обновления
      return null;
    }
  }

  @override
  Future<void> _saveTokens(String? accessToken, String? refreshToken, DateTime? expiry) async {
     if (accessToken != null) {
       await _secureStorage.write(key: _accessTokenKey, value: accessToken);
     }
     if (refreshToken != null) {
       await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
     }
      if (expiry != null) {
       await _secureStorage.write(key: _accessTokenExpiryKey, value: expiry.toIso8601String());
     }
  }

  @override
   Future<DateTime?> _getExpiryDateTime() async {
     final expiryString = await _secureStorage.read(key: _accessTokenExpiryKey);
     return expiryString != null ? DateTime.tryParse(expiryString) : null;
   }

  @override
  Future<Map<String, dynamic>> getDiskInfo() async {
     try {
       final response = await _dio.get('https://cloud-api.yandex.net/v1/disk/');
       return response.data as Map<String, dynamic>;
     } on dio.DioException catch (e) {
        print('Error fetching Yandex Disk info: ${e.response?.data ?? e.message}');
        rethrow; // Перевыбрасываем для обработки выше
     }
  }

  @override
  Future<Map<String, dynamic>> listFiles(String path, {int limit = 20, int offset = 0}) async {
     try {
       final response = await _dio.get(
         'https://cloud-api.yandex.net/v1/disk/resources',
         queryParameters: {
           'path': path, // Например, '/' для корня или '/папка'
           'limit': limit,
           'offset': offset,
           'sort': 'name', // Или 'created', 'modified'
         },
       );
       // Ответ содержит информацию о папке и вложенных элементах в _embedded
       return response.data as Map<String, dynamic>; 
     } on dio.DioException catch (e) {
        print('Error listing Yandex Disk files in path \'$path\': ${e.response?.data ?? e.message}');
        rethrow;
     }
  }

  @override
  Future<String?> getUploadLink(String diskPath, {bool overwrite = false}) async {
    try {
      final response = await _dio.get(
        'https://cloud-api.yandex.net/v1/disk/resources/upload',
        queryParameters: {
          'path': diskPath, 
          'overwrite': overwrite.toString(),
        },
      );
      // Ссылка находится в поле href
      return response.data['href'] as String?;
    } on dio.DioException catch (e) {
       print('Error getting upload link for path \'$diskPath\': ${e.response?.data ?? e.message}');
       // Обработка специфических ошибок (например, 409 Conflict)
       if (e.response?.statusCode == 409) {
         print('File already exists at $diskPath and overwrite is false.');
         // Можно вернуть null или выбросить кастомное исключение
       }
       rethrow;
    }
  }

  @override
  Future<void> uploadFile(String uploadUrl, File file) async {
    try {
      final fileSize = await file.length();
      // Создаем отдельный Dio instance для загрузки без интерцептора авторизации
      final uploadDio = dio.Dio(); 
      await uploadDio.put(
        uploadUrl,
        data: file.openRead(), // Отправляем поток байтов
        options: dio.Options( // Используем префикс
          headers: {
            dio.Headers.contentLengthHeader: fileSize, // Важно указать размер
            // Headers.contentTypeHeader: 'application/octet-stream', // Можно указать тип, если известен
          },
           // Убираем стандартный Authorization header, т.к. он не нужен для uploadUrl
           // Dio интерцептор добавит его, но Яндекс его тут не ожидает.
           // Нужно либо убрать интерцептор для этого запроса, либо создать отдельный Dio инстанс.
           // Проще всего - добавить пустой заголовок, чтобы интерцептор его не перезаписал
           // (если интерцептор проверяет на null перед добавлением)
           // Либо создать новый Dio instance для загрузки:
           // final uploadDio = dio.Dio();
           // await uploadDio.put(...)
        ), 
        // Можно добавить onSendProgress для отображения прогресса загрузки
        // onSendProgress: (int sent, int total) {
        //   print('Upload progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        // },
      );
      print('File ${file.path} uploaded successfully.');
    } on dio.DioException catch (e) {
       print('Error uploading file to \'$uploadUrl\': ${e.response?.data ?? e.message}');
       rethrow;
    }
  }

  @override
  Future<String?> getDownloadLink(String diskPath) async {
     try {
       final response = await _dio.get(
         'https://cloud-api.yandex.net/v1/disk/resources/download',
         queryParameters: {'path': diskPath},
       );
       return response.data['href'] as String?;
     } on dio.DioException catch (e) {
        print('Error getting download link for path \'$diskPath\': ${e.response?.data ?? e.message}');
        rethrow;
     }
  }

  @override
  Future<File?> downloadFile(String downloadUrl, String fileName) async {
    try {
      // Получаем директорию для сохранения (например, ApplicationDocumentsDirectory)
      final directory = await getApplicationDocumentsDirectory();
      final savePath = p.join(directory.path, fileName); // Используем path.join

      print('Downloading file to: $savePath');

      // Создаем отдельный Dio instance для скачивания без интерцептора авторизации
      final downloadDio = dio.Dio();
      await downloadDio.download(
        downloadUrl, 
        savePath,
        // Можно добавить onReceiveProgress для отображения прогресса
        // onReceiveProgress: (received, total) {
        //   if (total != -1) {
        //     print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
        //   }
        // },
      );
      print('File $fileName downloaded successfully.');
      return File(savePath);
    } on dio.DioException catch (e) {
       print('Error downloading file from \'$downloadUrl\': ${e.response?.data ?? e.message}');
       rethrow;
    } catch (e) {
       print('Error saving downloaded file: $e');
       rethrow;
    }
  }

  @override
  Future<void> createFolder(String diskPath) async {
     try {
       await _dio.put(
         'https://cloud-api.yandex.net/v1/disk/resources',
         queryParameters: {'path': diskPath},
       );
       print('Folder $diskPath created successfully.');
     } on dio.DioException catch (e) {
        // Обработка ошибки, если папка уже существует (409 Conflict)
        if (e.response?.statusCode == 409) {
           print('Folder $diskPath already exists.');
           // Можно не считать это ошибкой
           return; 
        }
        print('Error creating folder \'$diskPath\': ${e.response?.data ?? e.message}');
        rethrow;
     }
  }

  @override
  Future<void> deleteResource(String diskPath, {bool permanently = false}) async {
     try {
       await _dio.delete(
         'https://cloud-api.yandex.net/v1/disk/resources',
         queryParameters: {
           'path': diskPath,
           'permanently': permanently.toString(),
         },
       );
       print('Resource $diskPath deleted successfully (permanently: $permanently).');
     } on dio.DioException catch (e) {
        // Обработка ошибки, если ресурс не найден (404 Not Found)
        if (e.response?.statusCode == 404) {
           print('Resource $diskPath not found for deletion.');
           // Можно не считать это ошибкой
           return;
        }
        print('Error deleting resource \'$diskPath\': ${e.response?.data ?? e.message}');
        rethrow;
     }
  }
} 