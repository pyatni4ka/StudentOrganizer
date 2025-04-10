import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Удаляем импорт secure_storage_service
// import '../services/secure_storage_service.dart';

// Провайдер для GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  // Сервис должен быть инициализирован асинхронно
  // Лучше использовать FutureProvider или StateNotifierProvider
  // Пока сделаем простую синхронную заглушку
  final service = GeminiService(ref);
  // Попытка инициализации при первом доступе (не лучший подход)
  service.initialize();
  return service;
});

class GeminiService {
  final Ref _ref;
  GenerativeModel? _model;
  bool _isInitialized = false;
  bool _isAvailable = false;

  GeminiService(this._ref);

  bool get isAvailable => _isInitialized && _isAvailable;

  // Асинхронная инициализация
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('Initializing Gemini Service...');
    // Читаем ключ из переменных окружения
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print('Gemini API Key not found in .env file.');
      _isAvailable = false;
      _isInitialized = true;
      return;
    }

    try {
      // Используем gemini-1.5-flash (более новая и эффективная модель)
      // TODO: Рассмотреть gemini-pro или другие модели по мере необходимости
      _model =
          GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      // Попробуем сделать простой запрос для проверки ключа (опционально)
      // await _model?.generateContent([Content.text('test')]);
      _isAvailable = true;
      print('Gemini Service Initialized Successfully.');
    } catch (e) {
      print('Error initializing Gemini Service: $e');
      _isAvailable = false;
      // Оставляем _isInitialized = false, чтобы попробовать снова?
      // Или _isInitialized = true, чтобы не пытаться повторно?
      // Пока оставим false
    }
    _isInitialized = true; // Отмечаем, что попытка инициализации была
  }

  // Метод для суммаризации текста
  Future<String> summarizeText(String text) async {
    if (!isAvailable || _model == null) {
      throw Exception('Gemini Service not available or not initialized.');
    }
    if (text.trim().isEmpty) {
      return 'Нет текста для суммаризации.';
    }
    print('Summarizing text with Gemini...');
    try {
      // ИСПРАВЛЕНИЕ: Корректный промпт
      final prompt =
          'Сделай краткое изложение следующего текста:\n------\n$text\n------\nКраткое изложение:';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? 'Не удалось получить краткое изложение.';
    } catch (e) {
      print('Error summarizing text: $e');
      throw Exception('Ошибка AI: $e');
    }
  }

  // Метод для генерации подзадач
  Future<List<String>> generateSubtasks(String description) async {
    if (!isAvailable || _model == null) {
      throw Exception('Gemini Service not available or not initialized.');
    }
    if (description.trim().isEmpty) {
      return [];
    }
    print('Generating subtasks with Gemini...');
    try {
      // ИСПРАВЛЕНИЕ: Корректный промпт
      final prompt =
          'Проанализируй описание задачи и разбей его на конкретные выполнимые подзадачи. Выведи только список подзадач, каждая на новой строке, без нумерации или маркеров.\n------\nОписание задачи: $description\n------\nПодзадачи:';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final generatedText = response.text;
      if (generatedText == null || generatedText.trim().isEmpty) {
        return [];
      }
      return generatedText
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error generating subtasks: $e');
      throw Exception('Ошибка AI: $e');
    }
  }

  // TODO: Добавить другие AI методы (предложение тегов, дат, анализ текста и т.д.)
}
