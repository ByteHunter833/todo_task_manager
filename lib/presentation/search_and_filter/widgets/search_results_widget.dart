import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchResultsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final String searchQuery;
  final String sortBy;
  final Function(String) onSortChanged;
  final Function(Map<String, dynamic>) onTaskTap;

  const SearchResultsWidget({
    super.key,
    required this.searchResults,
    required this.searchQuery,
    required this.sortBy,
    required this.onSortChanged,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    // Если пусто, возвращаем EmptyState (без Column/Expanded)
    if (searchResults.isEmpty) {
      return _buildEmptyState();
    }

    // Используем ListView для ВСЕГО контента, включая заголовок
    return ListView.separated(
      // Убираем горизонтальный padding у самого списка, чтобы скроллбар был с краю,
      // но добавляем padding снизу для клавиатуры
      padding: EdgeInsets.only(bottom: 2.h),
      // Добавляем +1 к количеству элементов для Заголовка
      itemCount: searchResults.length + 1,
      separatorBuilder: (context, index) {
        // Нет разделителя сразу после заголовка (индекс 0)
        if (index == 0) return SizedBox(height: 1.h);
        return SizedBox(height: 2.h);
      },
      itemBuilder: (context, index) {
        // Индекс 0 — это Заголовок
        if (index == 0) {
          return _buildSortHeader();
        }

        // Остальные индексы — задачи (смещаем индекс на -1)
        final task = searchResults[index - 1];

        // Оборачиваем карточку в Padding, так как у ListView мы его убрали
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: _buildTaskCard(task),
        );
      },
    );
  }

  Widget _buildSortHeader() {
    return Container(
      // Уменьшил вертикальный отступ, так как теперь есть separator в ListView
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
      padding: EdgeInsets.symmetric(vertical: 1.h), // Добавил внутренний отступ
      child: Row(
        children: [
          Text(
            '${searchResults.length} result${searchResults.length != 1 ? 's' : ''}',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'relevance', child: Text('Relevance')),
              const PopupMenuItem(value: 'dueDate', child: Text('Due Date')),
              const PopupMenuItem(value: 'priority', child: Text('Priority')),
              const PopupMenuItem(
                value: 'modified',
                child: Text('Recently Modified'),
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort: ${_getSortDisplayName(sortBy)}',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: 1.w),
                CustomIconWidget(
                  iconName: 'arrow_drop_down',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... Остальные методы (_buildResultsList больше не нужен)
  // ... _buildTaskCard, _buildEmptyState и т.д. оставляем без изменений

  // Просто скопируйте методы ниже из вашего старого кода:
  // _buildTaskCard
  // _buildEmptyState
  // _buildPriorityIndicator
  // _highlightSearchText
  // _getDueDateColor
  // _formatDueDate
  // _getSortDisplayName

  // ВНИМАНИЕ: Для полноты кода вставляю методы, которые нужно оставить:

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] as String;
    final description = task['description'] as String;
    final dueDate = task['dueDate'] as DateTime?;
    final priority = task['priority'] as String;
    final category = task['category'] as String;
    final isCompleted = task['isCompleted'] as bool;
    final relevanceScore = task['relevanceScore'] as double? ?? 0.0;

    return InkWell(
      onTap: () => onTaskTap(task),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(
              alpha: 0.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTheme.lightTheme.textTheme.titleMedium
                          ?.copyWith(
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant
                                : AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                      children: _highlightSearchText(title, searchQuery),
                    ),
                  ),
                ),
                _buildPriorityIndicator(priority),
              ],
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 1.h),
              RichText(
                text: TextSpan(
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  children: _highlightSearchText(
                    description.length > 100
                        ? '${description.substring(0, 100)}...'
                        : description,
                    searchQuery,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                if (dueDate != null) ...[
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: _getDueDateColor(dueDate),
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatDueDate(dueDate),
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: _getDueDateColor(dueDate),
                    ),
                  ),
                ],
                if (sortBy == 'relevance' && relevanceScore > 0) ...[
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(relevanceScore * 100).toInt()}%',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.tertiary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      // Добавляем скролл, чтобы при открытой клавиатуре контент не ломался
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 2.h,
        ), // Небольшой отступ сверху/снизу
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Важно: занимаем минимум места по высоте
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              searchQuery.isEmpty
                  ? 'Start typing to search tasks'
                  : 'No tasks found',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            if (searchQuery.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  'Try adjusting your search or filters',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add task with pre-filled search term
                },
                icon: const CustomIconWidget(
                  iconName: 'add',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text('Create "$searchQuery" task'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = AppTheme.lightTheme.colorScheme.error;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  List<TextSpan> _highlightSearchText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            color: AppTheme.lightTheme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate.isBefore(today)) {
      return AppTheme.lightTheme.colorScheme.error;
    } else if (taskDate.isAtSameMomentAs(today)) {
      return Colors.orange;
    } else {
      return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else if (taskDate.isBefore(today)) {
      final difference = today.difference(taskDate).inDays;
      return '$difference day${difference != 1 ? 's' : ''} overdue';
    } else {
      return '${dueDate.month}/${dueDate.day}/${dueDate.year}';
    }
  }

  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'relevance':
        return 'Relevance';
      case 'dueDate':
        return 'Due Date';
      case 'priority':
        return 'Priority';
      case 'modified':
        return 'Recently Modified';
      default:
        return 'Relevance';
    }
  }
}
