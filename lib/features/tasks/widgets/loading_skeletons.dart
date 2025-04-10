import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Базовый контейнер-скелет
Widget _buildSkeletonContainer({double? width, double height = 16.0, double borderRadius = 4.0, EdgeInsets margin = EdgeInsets.zero}) {
  return Container(
    width: width,
    height: height,
    margin: margin,
    decoration: BoxDecoration(
      color: Colors.black, // Цвет должен быть непрозрачным для shimmer
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );
}

/// Скелет для одной строки задачи в списке
class TaskRowSkeleton extends StatelessWidget {
  const TaskRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withOpacity(0.08),
      highlightColor: colorScheme.onSurface.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildSkeletonContainer(width: 24, height: 24, borderRadius: 12), // Checkbox
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSkeletonContainer(height: 14, width: double.infinity), // Title line 1
                  const SizedBox(height: 6),
                  _buildSkeletonContainer(height: 12, width: 100), // Subtitle line
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Скелет для всего списка задач
class TaskListSkeleton extends StatelessWidget {
  final int itemCount;
  const TaskListSkeleton({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(), // Отключаем скролл
      itemCount: itemCount,
      itemBuilder: (context, index) => const TaskRowSkeleton(),
    );
  }
}


/// Скелет для одной колонки Kanban
class KanbanColumnSkeleton extends StatelessWidget {
  const KanbanColumnSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8.0),
        color: colorScheme.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок колонки
              _buildSkeletonContainer(height: 18, width: 100, margin: const EdgeInsets.only(bottom: 12)),
              // Несколько карточек-скелетов
              _buildSkeletonContainer(height: 60, width: double.infinity, margin: const EdgeInsets.only(bottom: 8)),
              _buildSkeletonContainer(height: 40, width: double.infinity, margin: const EdgeInsets.only(bottom: 8)),
              _buildSkeletonContainer(height: 50, width: double.infinity),
            ],
          ),
        ),
      ),
    );
  }
}

/// Скелет для всей Kanban доски
class KanbanBoardSkeleton extends StatelessWidget {
  final int columnCount;
  const KanbanBoardSkeleton({super.key, this.columnCount = 4});

  @override
  Widget build(BuildContext context) {
     final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.onSurface.withOpacity(0.08),
      highlightColor: colorScheme.onSurface.withOpacity(0.15),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(), // Отключаем скролл
        children: List.generate(columnCount, (_) => const KanbanColumnSkeleton()),
      ),
    );
  }
} 