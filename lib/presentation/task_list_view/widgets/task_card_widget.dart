import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';

import '../../../core/app_export.dart';

class TaskCardWidget extends StatelessWidget {
  final Todo task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.onSnooze,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TodoPriority.high:
        return AppTheme.lightTheme.colorScheme.error;
      case TodoPriority.low:
        return AppTheme.lightTheme.colorScheme.tertiary;
      case TodoPriority.medium:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  Color _getCategoryColor() {
    switch (task.category) {
      case TodoCategory.work:
        return AppTheme.lightTheme.primaryColor;
      case TodoCategory.shopping:
        return AppTheme.lightTheme.colorScheme.tertiary;
      case TodoCategory.health:
        return Colors.green;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  String _getPriorityName() {
    switch (task.priority) {
      case TodoPriority.high:
        return 'High';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.low:
        return 'Low';
    }
  }

  String _getCategoryName() {
    switch (task.category) {
      case TodoCategory.work:
        return 'Work';
      case TodoCategory.personal:
        return 'Personal';
      case TodoCategory.health:
        return 'Health';
      case TodoCategory.shopping:
        return 'Shopping';
      case TodoCategory.education:
        return 'Education';
      case TodoCategory.finance:
        return 'Finance';
    }
  }

  String _getCategoryIcon() {
    switch (task.category) {
      case TodoCategory.work:
        return 'work';
      case TodoCategory.shopping:
        return 'shopping_cart';
      case TodoCategory.health:
        return 'favorite';
      case TodoCategory.education:
        return 'school';
      case TodoCategory.finance:
        return 'account_balance_wallet';
      default:
        return 'person';
    }
  }

  String _formatDueDate() {
    final dueDate = task.dueDate;
    if (dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Today ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    } else if (taskDate.isBefore(today)) {
      return 'Overdue ${dueDate.month}/${dueDate.day}';
    } else {
      return '${dueDate.month}/${dueDate.day} ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}';
    }
  }

  bool _isOverdue() {
    final dueDate = task.dueDate;
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now()) &&
        !(task.isCompleted as bool? ?? false);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted as bool? ?? false;
    final title = task.title as String? ?? 'Untitled Task';
    final description = task.description ?? '';
    final isOverdue = _isOverdue();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.7)
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(
                color: AppTheme.lightTheme.colorScheme.error.withValues(
                  alpha: 0.3,
                ),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.6)
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPriorityName(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: _getPriorityColor(),
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      SizedBox(width: 2.w),
                      const CustomIconWidget(
                        iconName: 'check_circle',
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isCompleted
                          ? AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.5)
                          : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                      height: 1.3,
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
                        color: _getCategoryColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: _getCategoryIcon(),
                            color: _getCategoryColor(),
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _getCategoryName(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: _getCategoryColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_formatDueDate().isNotEmpty) ...[
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: isOverdue
                            ? AppTheme.lightTheme.colorScheme.error
                            : AppTheme.lightTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        _formatDueDate(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                          color: isOverdue
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: onSnooze,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: 'more_vert',
                          color: AppTheme.lightTheme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
