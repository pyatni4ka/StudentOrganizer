import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ai_providers.dart'; // Импортируем AI провайдеры

class AICenterScreen extends ConsumerWidget {
  const AICenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(nextTaskSuggestionProvider);
    final summaryAsync = ref.watch(weekNotesSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Помощник'),
         actions: [
           // Кнопка для обновления данных (перезапуска провайдеров)
           IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить рекомендации',
              onPressed: () {
                 ref.invalidate(nextTaskSuggestionProvider);
                 ref.invalidate(weekNotesSummaryProvider);
              },
            ),
         ]
      ),
      body: ListView( // Используем ListView для прокрутки, если контента много
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAISection(
            context,
            title: 'Предложение следующей задачи',
            icon: Icons.lightbulb_outline,
            asyncValue: suggestionAsync,
          ),
          const SizedBox(height: 24),
          _buildAISection(
            context,
            title: 'Саммари заметок за неделю',
            icon: Icons.summarize_outlined,
            asyncValue: summaryAsync,
          ),
           // TODO: Добавить другие секции для AI аналитики
        ],
      ),
    );
  }

  // Вспомогательный виджет для отображения секции с результатом от AI
  Widget _buildAISection(BuildContext context, {required String title, required IconData icon, required AsyncValue<String> asyncValue}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
             color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
             borderRadius: BorderRadius.circular(8),
          ),
          child: asyncValue.when(
             data: (text) => SelectableText(text), // SelectableText для копирования
             loading: () => const Center(child: CircularProgressIndicator()), 
             error: (err, stack) => Text('Ошибка: $err', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ),
      ],
    );
  }
} 