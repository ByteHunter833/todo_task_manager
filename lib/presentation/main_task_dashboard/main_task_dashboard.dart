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
import './widgets/quick_add_fab_widget.dart';
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

  void _onVoiceInput() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input feature coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todosStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: QuickAddFabWidget(
        onAddTask: _onAddTask,
        onVoiceInput: _onVoiceInput,
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

            // Statistics Calculation
            final totalTasksForToday =
                todayTodos.length +
                completedTodos
                    .where((t) => _isSameDay(t.dueDate, today))
                    .length;
            final completedTasksForToday = completedTodos
                .where((t) => _isSameDay(t.dueDate, today))
                .length;

            final double todayProgress = totalTasksForToday == 0
                ? 1.0
                : completedTasksForToday / totalTasksForToday;

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
                          completionStreak:
                              5, // Logic for streak needs specific history data
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
