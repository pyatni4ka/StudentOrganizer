import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert'; // Для jsonDecode
import 'package:flutter_quill/flutter_quill.dart'; // Для Document
// import 'package:quill_delta/quill_delta.dart'; // Удаляем этот импорт

// Понадобятся модели данных
// import '../models/project.dart'; // Если будем анализировать проекты
import 'task_repository.dart'; // Для получения задач
import 'daily_note_repository.dart'; // Для получения заметок

// Провайдер для AI Service
final aiServiceProvider = Provider<AIService>((ref) {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY is not set. Pass it using --dart-define.');
  }
  // Пробуем gemini-1.5-flash-latest снова
  final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
  return AIService(model, ref);
});

class AIService {
  final GenerativeModel _model;
  final Ref _ref; // Для доступа к другим репозиториям/провайдерам

  AIService(this._model, this._ref);

  /// Пример: Анализ задач и предложение следующей задачи
  Future<String> suggestNextTask() async {
    try {
      // Получаем недавние невыполненные задачи
      final taskRepo = _ref.read(taskRepositoryProvider);
      final tasks = await taskRepo.fetchTasks(); // Получаем все задачи
      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

      if (incompleteTasks.isEmpty) {
        return "У вас нет активных задач!";
      }

      // Формируем промпт для Gemini
      // Ограничиваем количество задач, чтобы не превысить лимиты токенов
      final tasksForPrompt = incompleteTasks.take(15).map((task) {
        final dueDate = task.dueDate != null ? 'Срок: ${task.dueDate!.toIso8601String().split('T')[0]}' : '';
        final priority = 'Приоритет: ${task.priority.name}';
        // Используем _extractPlainText для описания
        final descriptionText = _extractPlainText(task.description);
        // Добавляем описание в промпт, если оно есть
        final descriptionPart = descriptionText.isNotEmpty ? '\n  Описание: ${descriptionText.substring(0, descriptionText.length > 100 ? 100 : descriptionText.length)}...' : ''; 
        return '- ${task.title} ($priority, $dueDate)$descriptionPart'; 
      }).join('\n');
      
      final prompt = 'Проанализируй мой список невыполненных задач и предложи, какую задачу мне стоит сделать следующей, учитывая приоритет, срок выполнения и описание. Кратко объясни свой выбор.\n\nМои задачи:\n$tasksForPrompt';

      print("--- Sending prompt to Gemini ---\n$prompt\n------------------------------");

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      print("--- Received response from Gemini ---\n${response.text}\n------------------------------");

      return response.text ?? "Не удалось получить предложение.";
      
    } catch (e) {
      print('Error suggesting next task: $e');
      return "Ошибка при получении рекомендации: $e";
    }
  }

  /// Пример: Генерация краткого саммари по заметкам за неделю
  Future<String> summarizeWeekNotes() async {
    try {
       final noteRepo = _ref.read(dailyNoteRepositoryProvider);
       final today = DateTime.now();
       List<String> notesContent = [];

       for (int i = 0; i < 7; i++) {
          final date = today.subtract(Duration(days: i));
          final note = await noteRepo.fetchNoteByDate(date);
          if (note != null && note.content != null) {
             // TODO: Извлечь plain text из note.content (jsonb)
             notesContent.add('Дата: ${date.toIso8601String().split('T')[0]}\n${note.content.toString()}\n---\n'); 
          }
       }

       if (notesContent.isEmpty) {
         return "Нет заметок за последнюю неделю для анализа.";
       }

       final prompt = 'Сделай краткое саммари моих записей за последнюю неделю. Выдели основные темы или события.\n\nМои заметки:\n${notesContent.join('\n')}';

       print("--- Sending prompt to Gemini ---\n$prompt\n------------------------------");

       final content = [Content.text(prompt)];
       final response = await _model.generateContent(content);

        print("--- Received response from Gemini ---\n${response.text}\n------------------------------");

       return response.text ?? "Не удалось получить саммари.";

    } catch (e) {
       print('Error summarizing week notes: $e');
       return "Ошибка при генерации саммари: $e";
    }
  }

   /// Извлекает чистый текст из данных, которые могут быть JSON-строкой формата Delta.
   String _extractPlainText(Object? data) {
    if (data == null || data is! String || data.isEmpty) {
      return "";
    }
    try {
      // Пытаемся декодировать JSON. Delta хранится как список Map.
      final List<dynamic> jsonData = jsonDecode(data);
      // final delta = Delta.fromJson(jsonData); // Удаляем создание Delta
      final document = Document.fromJson(jsonData); // Используем Document.fromJson напрямую
      return document.toPlainText().trim(); // Убираем лишние пробелы
    } catch (e) {
      // Если это не валидный JSON или не Delta, возвращаем пустую строку
      // Можно добавить логирование ошибки при необходимости
      print('Error extracting plain text from data: $e. Data: $data');
      // Если data - это уже простой текст, а не JSON, вернем его как есть
       return data;
          return "";
    }
  }

} 