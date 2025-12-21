// lib/presentation/task_list_view/task_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';
import 'package:todo_task_manager/providers/todo_provider.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/sort_bottom_sheet_widget.dart';
import './widgets/task_card_widget.dart';

class TaskListView extends ConsumerStatefulWidget {
  const TaskListView({super.key});

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _dismissedTaskIds = {};

  Map<String, dynamic> _activeFilters = {};
  String _sortBy = 'dueDate';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Просто перестраиваем UI — фильтрация в build
    setState(() {});
  }

  String _priorityToString(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return 'High';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.low:
        return 'Low';
    }
  }

  String _categoryToString(TodoCategory category) {
    switch (category) {
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _activeFilters,
        onFiltersChanged: (filters) {
          setState(() {
            _activeFilters = filters;
          });
        },
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheetWidget(
        currentSortBy: _sortBy,
        currentSortAscending: _sortAscending,
        onSortChanged: (sortBy, ascending) {
          setState(() {
            _sortBy = sortBy;
            _sortAscending = ascending;
          });
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _activeFilters.clear();
      _searchController.clear();
    });
  }

  void _toggleTaskCompletion(Todo todo) {
    ref.read(todoRepositoryProvider).toggle(todo);
    HapticFeedback.lightImpact();
  }

  void _deleteTask(int taskId) {
    ref.read(todoRepositoryProvider).delete(taskId);
  }

  void _snoozeTask(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Task'),
        content: const Text('Choose how long to snooze this task:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (todo.dueDate != null) {
                final updatedTodo = todo.copyWith(
                  dueDate: todo.dueDate!.add(const Duration(hours: 1)),
                );
                ref.read(todoRepositoryProvider).add(updatedTodo);
              }
              Navigator.pop(context);
            },
            child: const Text('1 Hour'),
          ),
          TextButton(
            onPressed: () {
              if (todo.dueDate != null) {
                final updatedTodo = todo.copyWith(
                  dueDate: todo.dueDate!.add(const Duration(days: 1)),
                );
                ref.read(todoRepositoryProvider).add(updatedTodo);
              }
              Navigator.pop(context);
            },
            child: const Text('1 Day'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    ref.invalidate(todosStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosStreamProvider);
    final searchQuery = _searchController.text.toLowerCase();
    final hasActiveFilters =
        _activeFilters.isNotEmpty || searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showSortBottomSheet,
            icon: CustomIconWidget(
              iconName: 'sort',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/settings-and-preferences'),
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (allTodos) {
          // Фильтрация
          List<Todo> filtered = List.from(allTodos);

          // Remove dismissed tasks
          filtered.removeWhere((task) => _dismissedTaskIds.contains(task.id));

          if (searchQuery.isNotEmpty) {
            filtered = filtered.where((task) {
              final title = (task.title as String? ?? '').toLowerCase();
              final description = (task.description ?? '').toLowerCase();
              return title.contains(searchQuery) ||
                  description.contains(searchQuery);
            }).toList();
          }

          if (_activeFilters.containsKey('dateRange')) {
            final dateRange = _activeFilters['dateRange'] as DateTimeRange;
            filtered = filtered.where((task) {
              final dueDate = task.dueDate;
              if (dueDate == null) return false;
              return dueDate.isAfter(
                    dateRange.start.subtract(const Duration(days: 1)),
                  ) &&
                  dueDate.isBefore(dateRange.end.add(const Duration(days: 1)));
            }).toList();
          }

          if (_activeFilters.containsKey('priority')) {
            final priorities = _activeFilters['priority'] as List<String>;
            filtered = filtered.where((task) {
              return priorities.contains(_priorityToString(task.priority));
            }).toList();
          }

          if (_activeFilters.containsKey('category')) {
            final categories = _activeFilters['category'] as List<String>;
            filtered = filtered.where((task) {
              return categories.contains(_categoryToString(task.category));
            }).toList();
          }

          if (_activeFilters.containsKey('status')) {
            final statuses = _activeFilters['status'] as List<String>;
            filtered = filtered.where((task) {
              final isCompleted = task.isCompleted;
              final dueDate = task.dueDate;
              final isOverdue =
                  dueDate != null &&
                  dueDate.isBefore(DateTime.now()) &&
                  !isCompleted;

              for (String status in statuses) {
                if (status == 'Completed' && isCompleted) return true;
                if (status == 'Pending' && !isCompleted && !isOverdue) {
                  return true;
                }
                if (status == 'Overdue' && isOverdue) return true;
              }
              return false;
            }).toList();
          }

          // Сортировка
          filtered.sort((a, b) {
            int comparison = 0;

            switch (_sortBy) {
              case 'dueDate':
                final aDate = a.dueDate;
                final bDate = b.dueDate;
                if (aDate == null && bDate == null) {
                  comparison = 0;
                } else if (aDate == null) {
                  comparison = 1;
                } else if (bDate == null)
                  comparison = -1;
                else
                  comparison = aDate.compareTo(bDate);
                break;
              case 'priority':
                final priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};
                final aPriority =
                    priorityOrder[_priorityToString(a.priority)] ?? 0;
                final bPriority =
                    priorityOrder[_priorityToString(b.priority)] ?? 0;
                comparison = aPriority.compareTo(bPriority);
                break;
              case 'category':
                comparison = _categoryToString(
                  a.category,
                ).compareTo(_categoryToString(b.category));
                break;
              case 'createdAt':
                final aCreated = a.createdAt as DateTime?;
                final bCreated = b.createdAt as DateTime?;
                if (aCreated == null && bCreated == null) {
                  comparison = 0;
                } else if (aCreated == null)
                  comparison = 1;
                else if (bCreated == null)
                  comparison = -1;
                else
                  comparison = aCreated.compareTo(bCreated);
                break;
            }

            return _sortAscending ? comparison : -comparison;
          });

          return Column(
            children: [
              Container(
                color: AppTheme.lightTheme.colorScheme.surface,
                padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.lightTheme.scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.outline
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search tasks...',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(3.w),
                                  child: CustomIconWidget(
                                    iconName: 'search',
                                    color: AppTheme
                                        .lightTheme
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        onPressed: () =>
                                            _searchController.clear(),
                                        icon: CustomIconWidget(
                                          iconName: 'close',
                                          color: AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                          size: 20,
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 2.h,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Container(
                          decoration: BoxDecoration(
                            color: hasActiveFilters
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasActiveFilters
                                  ? AppTheme.lightTheme.colorScheme.primary
                                  : AppTheme.lightTheme.colorScheme.outline
                                        .withOpacity(0.2),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _showFilterBottomSheet,
                            icon: CustomIconWidget(
                              iconName: 'filter_list',
                              color: hasActiveFilters
                                  ? Colors.white
                                  : AppTheme.lightTheme.colorScheme.onSurface
                                        .withOpacity(0.6),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasActiveFilters) SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filtered.length} task${filtered.length != 1 ? 's' : ''} found',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.lightTheme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _clearAllFilters,
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.lightTheme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyStateWidget(
                        hasActiveFilters: hasActiveFilters,
                        onClearFilters: _clearAllFilters,
                        onCreateTask: () =>
                            Navigator.pushNamed(context, '/add-edit-task'),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshTasks,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final task = filtered[index];
                            return Dismissible(
                              key: ValueKey('dismissible_task_${task.id}'),
                              background: Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(left: 6.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CustomIconWidget(
                                      iconName: 'check_circle',
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Complete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.colorScheme.error
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 6.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CustomIconWidget(
                                      iconName: 'delete',
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // Complete task - allow immediate dismissal
                                  _toggleTaskCompletion(task);
                                  _dismissedTaskIds.add(task.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task completed'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return true;
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  // Delete task - show confirmation dialog
                                  final confirmed =
                                      await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Task'),
                                          content: const Text(
                                            'Are you sure you want to delete this task?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;

                                  if (confirmed) {
                                    _deleteTask(task.id);
                                    _dismissedTaskIds.add(task.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Task deleted'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                  return confirmed;
                                }
                                return false;
                              },
                              onDismissed: (direction) {
                                // Widget is removed from tree by Dismissible after animation
                              },
                              child: TaskCardWidget(
                                task: task,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/add-edit-task',
                                  arguments: task,
                                ),
                                onSnooze: () => _snoozeTask(task),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-edit-task'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
