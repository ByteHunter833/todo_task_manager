import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';
import 'package:todo_task_manager/providers/auth_provider.dart';
import 'package:todo_task_manager/providers/todo_provider.dart';

import '../../core/app_export.dart';
import './widgets/dashboard_header_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/statistics_bar_widget.dart';
import './widgets/task_section_widget.dart';

class MainTaskDashboard extends ConsumerStatefulWidget {
  const MainTaskDashboard({super.key});

  @override
  ConsumerState<MainTaskDashboard> createState() => _MainTaskDashboardState();
}

class _MainTaskDashboardState extends ConsumerState<MainTaskDashboard>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  String? fetchUserName() {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) => user?.displayName,
      loading: () => null,
      error: (_, _) => null,
    );
  }

  String? get _userName => fetchUserName();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    return Future.delayed(const Duration(milliseconds: 500));
  }

  void _onTaskTap(Todo todo) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/add-edit-task', arguments: todo);
  }

  void _onTaskComplete(Todo todo) {
    HapticFeedback.mediumImpact();
    ref.read(todoRepositoryProvider).toggle(todo);
  }

  void _onTaskDelete(Todo todo) {
    HapticFeedback.heavyImpact();
    final int id = todo.id;
    final String title = todo.title;
    ref.read(todoRepositoryProvider).delete(id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Task "$title" deleted')));
  }

  void _onTaskEdit(Todo todo) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/add-edit-task', arguments: todo);
  }

  void _onSearchTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/search-and-filter');
  }

  void _onProfileTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/settings-and-preferences');
  }

  void _onAddTask() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/add-edit-task');
  }

  bool _isSameDay(DateTime? date, DateTime today) {
    if (date == null) return false;
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  double _calculateTodayProgress(List<Todo> allTodos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Get tasks that are due today or have no due date (general tasks)
    final tasksForToday = allTodos.where((t) {
      if (t.dueDate == null) return true; // Include tasks without due dates
      return _isSameDay(t.dueDate, today);
    }).toList();
    if (tasksForToday.isEmpty) return 1.0;
    // Count completed tasks
    final completedCount = tasksForToday.where((t) => t.isCompleted).length;
    return completedCount / tasksForToday.length;
  }

  void _onVoiceInput() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input feature coming soon!')),
    );
  }

  int _calculateCompletionStreak(List<Todo> completedTodos) {
    if (completedTodos.isEmpty) return 0;
    // Get all unique dates when tasks were completed
    final completedDates = <DateTime>{};
    for (final todo in completedTodos) {
      if (todo.completedAt != null) {
        final completedDate = DateTime(
          todo.completedAt!.year,
          todo.completedAt!.month,
          todo.completedAt!.day,
        );
        completedDates.add(completedDate);
      }
    }
    if (completedDates.isEmpty) return 0;
    // Sort dates in descending order (most recent first)
    final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));
    // Calculate streak starting from the most recent date
    int streak = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // If the most recent completed date is not today or yesterday, streak is 0
    final lastCompletedDate = sortedDates.first;
    final daysDiff = today.difference(lastCompletedDate).inDays;
    if (daysDiff > 1) {
      return 0;
    }
    // Count consecutive days backwards from the most recent date
    for (int i = 1; i < sortedDates.length; i++) {
      final expectedDate = sortedDates[i - 1].subtract(const Duration(days: 1));
      if (sortedDates[i] == expectedDate) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosStreamProvider);
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'voice_fab',
        onPressed: () => _onAddTask(),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: const CustomIconWidget(
          iconName: 'add',
          color: Colors.white,
          size: 24,
        ),
      ),
      body: SafeArea(
        child: todosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (allTodos) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final nextWeek = today.add(const Duration(days: 7));
            // Filtering Lists
            final overdueTodos = allTodos.where((t) {
              if (t.dueDate == null || t.isCompleted) return false;
              final tDate = DateTime(
                t.dueDate!.year,
                t.dueDate!.month,
                t.dueDate!.day,
              );
              return tDate.isBefore(today);
            }).toList();
            final todayTodos = allTodos.where((t) {
              if (t.isCompleted) return false;
              return _isSameDay(t.dueDate, today);
            }).toList();
            final upcomingTodos = allTodos.where((t) {
              if (t.dueDate == null || t.isCompleted) return false;
              final tDate = DateTime(
                t.dueDate!.year,
                t.dueDate!.month,
                t.dueDate!.day,
              );
              return tDate.isAfter(today) && tDate.isBefore(nextWeek);
            }).toList();
            final completedTodos = allTodos
                .where((t) => t.isCompleted)
                .toList();
            // Preparing task lists
            final overduetodosList = overdueTodos;
            final todaytodosList = todayTodos;
            final upcomingtodosList = upcomingTodos;
            final completedtodosList = completedTodos.take(5).toList();
            // Statistics Calculation - Dynamic Progress
            final double todayProgress = _calculateTodayProgress(allTodos);
            final hasAnyTasks = allTodos.isNotEmpty;
            if (!hasAnyTasks) {
              return EmptyStateWidget(
                title: 'Welcome to TaskFlow Pro!',
                subtitle:
                    'Start organizing your life by adding your first task.',
                buttonText: 'Add Your First Task',
                onButtonTap: _onAddTask,
              );
            }
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.lightTheme.colorScheme.primary,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        DashboardHeaderWidget(
                          userName: _userName,
                          onSearchTap: _onSearchTap,
                          onProfileTap: _onProfileTap,
                        ),
                        StatisticsBarWidget(
                          completionStreak: _calculateCompletionStreak(
                            completedTodos,
                          ),
                          todayProgress: todayProgress,
                          completedTasks: completedTodos.length,
                          totalTasks: allTodos.length,
                        ),
                      ],
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      overduetodosList.isNotEmpty
                          ? TaskSectionWidget(
                              title: 'Overdue',
                              tasks: overduetodosList,
                              accentColor: const Color(0xFFDC2626),
                              onTaskTap: _onTaskTap,
                              onTaskComplete: _onTaskComplete,
                              onTaskDelete: _onTaskDelete,
                              onTaskEdit: _onTaskEdit,
                            )
                          : const SizedBox.shrink(),
                      todaytodosList.isNotEmpty
                          ? TaskSectionWidget(
                              title: 'Today',
                              tasks: todaytodosList,
                              accentColor:
                                  AppTheme.lightTheme.colorScheme.primary,
                              onTaskTap: _onTaskTap,
                              onTaskComplete: _onTaskComplete,
                              onTaskDelete: _onTaskDelete,
                              onTaskEdit: _onTaskEdit,
                            )
                          : const SizedBox.shrink(),
                      upcomingtodosList.isNotEmpty
                          ? TaskSectionWidget(
                              title: 'Upcoming',
                              tasks: upcomingtodosList,
                              accentColor: const Color(0xFFD97706),
                              onTaskTap: _onTaskTap,
                              onTaskComplete: _onTaskComplete,
                              onTaskDelete: _onTaskDelete,
                              onTaskEdit: _onTaskEdit,
                            )
                          : const SizedBox.shrink(),
                      completedtodosList.isNotEmpty
                          ? TaskSectionWidget(
                              title: 'Recently Completed',
                              tasks: completedtodosList,
                              accentColor: const Color(0xFF059669),
                              onTaskTap: _onTaskTap,
                              onTaskComplete: _onTaskComplete,
                              onTaskDelete: _onTaskDelete,
                              onTaskEdit: _onTaskEdit,
                            )
                          : const SizedBox.shrink(),
                      SizedBox(height: 10.h),
                    ]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        HapticFeedback.lightImpact();
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, '/task-list-view');
            break;
          case 2:
            Navigator.pushNamed(context, '/calendar-view');
            break;
          case 3:
            Navigator.pushNamed(context, '/analytics-dashboard');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'list',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'calendar_today',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'analytics',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Analytics',
        ),
      ],
    );
  }
}
