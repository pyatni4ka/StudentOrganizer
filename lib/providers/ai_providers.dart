import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/ai_service.dart';

part 'ai_providers.g.dart';

// Provider для получения предложения следующей задачи
@riverpod
Future<String> nextTaskSuggestion(NextTaskSuggestionRef ref) {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.suggestNextTask();
}

// Provider для получения саммари заметок за неделю
@riverpod
Future<String> weekNotesSummary(WeekNotesSummaryRef ref) {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.summarizeWeekNotes();
}

// Можно добавить другие провайдеры для разных AI фич 