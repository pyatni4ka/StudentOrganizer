import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/yandex_disk_service.dart'; // Импортируем сервис и провайдеры
// Попробуем относительный импорт, если абсолютный не работает
import '../../services/secure_storage_service.dart';

// TextEditingController для поля ввода API ключа
// Лучше использовать StatefulWidget или StateProvider/Notifier для управления состоянием контроллера
// Пока сделаем просто глобальным для примера (не рекомендуется для больших приложений)
final _apiKeyControllerProvider = StateProvider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose()); // Очищаем контроллер при удалении провайдера
  return controller;
});

// StateProvider для отслеживания состояния загрузки/сохранения ключа
final _apiKeyLoadingProvider = StateProvider<bool>((ref) => false);
// StateProvider для отображения сохраненного ключа (или части)
final _savedApiKeyDisplayProvider = StateProvider<String?>((ref) => null);

class SettingsScreen extends ConsumerStatefulWidget { // Меняем на StatefulWidget
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> { // Создаем State

  @override
  void initState() {
    super.initState();
    // При инициализации пытаемся загрузить и отобразить ключ
    // Делаем это через Future.microtask, чтобы ref был доступен
    Future.microtask(() => _loadAndDisplayApiKey());
  }

  Future<void> _loadAndDisplayApiKey() async {
    // ИСПРАВЛЕНИЕ: Явно указываем тип SecureStorageService
    final SecureStorageService storageService = ref.read(secureStorageProvider);
    final apiKey = await storageService.readApiKey(); // Вызываем метод сервиса
    if (mounted) { // Проверяем, что виджет все еще в дереве
      ref.read(_savedApiKeyDisplayProvider.notifier).state = _maskApiKey(apiKey);
    }
  }

  // Маскирует API ключ, показывая только последние 4 символа
  String? _maskApiKey(String? apiKey) {
    if (apiKey == null || apiKey.length < 8) {
      return apiKey; // Возвращаем как есть, если ключ короткий или null
    }
    return '**** **** **** ${apiKey.substring(apiKey.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    // Получаем состояние аутентификации Яндекс Диска
    final yandexAuthState = ref.watch(yandexAuthStateProvider);
    final authNotifier = ref.watch(yandexAuthStateProvider.notifier);
    final isYandexDiskUnsupported = authNotifier.isUnsupported;

    // Получаем контроллер и состояния для Gemini API
    final apiKeyController = ref.watch(_apiKeyControllerProvider);
    final isApiKeyLoading = ref.watch(_apiKeyLoadingProvider);
    final savedApiKeyDisplay = ref.watch(_savedApiKeyDisplayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Секция Gemini API ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini AI', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  const Text(
                    'Введите ваш API ключ Google AI Studio для использования AI функций. Ключ хранится локально и безопасно.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  if (savedApiKeyDisplay != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text('Сохраненный ключ: $savedApiKeyDisplay', style: const TextStyle(color: Colors.green)),
                    ),
                  TextField(
                    controller: apiKeyController,
                    obscureText: true, // Скрываем ввод ключа
                    decoration: const InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'Введите ваш ключ...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isApiKeyLoading, // Блокируем поле при сохранении
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (savedApiKeyDisplay != null)
                        TextButton(
                          onPressed: isApiKeyLoading ? null : () async {
                              ref.read(_apiKeyLoadingProvider.notifier).state = true;
                              // ИСПРАВЛЕНИЕ: Явно указываем тип SecureStorageService
                              final SecureStorageService storageService = ref.read(secureStorageProvider);
                              await storageService.deleteApiKey(); // Вызываем метод сервиса
                              apiKeyController.clear(); // Очищаем поле ввода
                              if (mounted) {
                                ref.read(_savedApiKeyDisplayProvider.notifier).state = null;
                                ref.read(_apiKeyLoadingProvider.notifier).state = false;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('API ключ удален.'), backgroundColor: Colors.orange),
                                );
                              }
                          },
                          child: isApiKeyLoading ? const SizedBox.shrink() : const Text('Удалить ключ', style: TextStyle(color: Colors.red)),
                        ),
                       const Spacer(),
                      ElevatedButton.icon(
                        icon: isApiKeyLoading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: const Text('Сохранить ключ'),
                        onPressed: isApiKeyLoading || apiKeyController.text.isEmpty
                            ? null
                            : () async {
                                ref.read(_apiKeyLoadingProvider.notifier).state = true;
                                // ИСПРАВЛЕНИЕ: Явно указываем тип SecureStorageService
                                final SecureStorageService storageService = ref.read(secureStorageProvider);
                                final newApiKey = apiKeyController.text.trim();
                                if (newApiKey.isNotEmpty) {
                                   await storageService.writeApiKey(newApiKey); // Вызываем метод сервиса
                                   if (mounted) {
                                      ref.read(_savedApiKeyDisplayProvider.notifier).state = _maskApiKey(newApiKey);
                                      apiKeyController.clear(); // Очищаем поле после сохранения
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('API ключ сохранен!'), backgroundColor: Colors.green),
                                      );
                                   }
                                } else {
                                   if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Поле ключа не может быть пустым'), backgroundColor: Colors.red),
                                      );
                                   }
                                }
                                if (mounted) {
                                   ref.read(_apiKeyLoadingProvider.notifier).state = false;
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16), // Отступ между карточками

          // --- Секция Яндекс Диска ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Яндекс Диск', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  // Если не поддерживается, показываем сообщение
                  if (isYandexDiskUnsupported)
                     Padding(
                       padding: const EdgeInsets.symmetric(vertical: 8.0),
                       child: Text(
                         'Интеграция с Яндекс.Диском недоступна на данной платформе (macOS).',
                         style: TextStyle(color: Colors.grey[700]),
                       ),
                     )
                  // Иначе используем стандартную логику
                  else 
                    yandexAuthState.when(
                      data: (token) {
                        if (token != null) {
                          // Пользователь вошел
                          return Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                              const Text('Статус: Подключен', style: TextStyle(color: Colors.green)),
                               // TODO: Показать имя пользователя или другую информацию?
                               const SizedBox(height: 10),
                               ElevatedButton.icon(
                                 icon: const Icon(Icons.logout),
                                 label: const Text('Отключить Яндекс Диск'),
                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                 onPressed: () {
                                   authNotifier.signOut(); // Используем authNotifier
                                 },
                               ),
                             ],
                           );
                        } else {
                          // Пользователь не вошел
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Статус: Не подключен'),
                              const SizedBox(height: 5),
                              const Text('Подключите аккаунт Яндекс Диска для прикрепления файлов к задачам.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.login),
                                label: const Text('Подключить Яндекс Диск'),
                                onPressed: () {
                                  authNotifier.signIn(); // Используем authNotifier
                                },
                              ),
                            ],
                          );
                        }
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('Статус: Ошибка', style: TextStyle(color: Colors.red)),
                           const SizedBox(height: 5),
                           Text('$error', style: const TextStyle(color: Colors.redAccent)),
                           const SizedBox(height: 10),
                           // Кнопка для повторной попытки входа
                           ElevatedButton.icon(
                             icon: const Icon(Icons.refresh),
                             label: const Text('Попробовать снова'),
                             onPressed: () {
                               authNotifier.signIn(); // Используем authNotifier
                             },
                           ),
                         ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // TODO: Добавить другие секции настроек (Тема, Уведомления и т.д.)

        ],
      ),
    );
  }
} 