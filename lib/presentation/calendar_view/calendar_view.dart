import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/calendar_header_widget.dart';
import './widgets/calendar_month_widget.dart';
import './widgets/calendar_week_widget.dart';
import './widgets/daily_tasks_bottom_sheet.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView>
    with TickerProviderStateMixin {
  late PageController _monthPageController;
  late PageController _weekPageController;
  late AnimationController _refreshController;

  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isWeekView = false;
  bool _isRefreshing = false;

  // Mock task data
  final Map<DateTime, List<Map<String, dynamic>>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _monthPageController = PageController(initialPage: 1000);
    _weekPageController = PageController(initialPage: 1000);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _generateMockTasks();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _generateMockTasks() {
    final now = DateTime.now();
    final tasks = [
      {
        'id': 1,
        'title': 'Team Meeting',
        'description': 'Weekly team sync and project updates',
        'time': '09:00',
        'priority': 'High',
        'category': 'Work',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day),
      },
      {
        'id': 2,
        'title': 'Grocery Shopping',
        'description': 'Buy vegetables, fruits, and household items',
        'time': '14:30',
        'priority': 'Medium',
        'category': 'Shopping',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day),
      },
      {
        'id': 3,
        'title': 'Doctor Appointment',
        'description': 'Annual health checkup',
        'time': '11:00',
        'priority': 'High',
        'category': 'Health',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day + 1),
      },
      {
        'id': 4,
        'title': 'Project Deadline',
        'description': 'Submit final project deliverables',
        'time': '17:00',
        'priority': 'High',
        'category': 'Work',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day + 2),
      },
      {
        'id': 5,
        'title': 'Gym Workout',
        'description': 'Cardio and strength training session',
        'time': '07:00',
        'priority': 'Medium',
        'category': 'Health',
        'isCompleted': true,
        'date': DateTime(now.year, now.month, now.day - 1),
      },
      {
        'id': 6,
        'title': 'Family Dinner',
        'description': 'Dinner with parents and siblings',
        'time': '19:00',
        'priority': 'Low',
        'category': 'Personal',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day + 3),
      },
      {
        'id': 7,
        'title': 'Code Review',
        'description': 'Review pull requests and provide feedback',
        'time': '15:30',
        'priority': 'Medium',
        'category': 'Work',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day + 1),
      },
      {
        'id': 8,
        'title': 'Book Reading',
        'description': 'Read chapter 5-7 of productivity book',
        'time': '21:00',
        'priority': 'Low',
        'category': 'Personal',
        'isCompleted': false,
        'date': DateTime(now.year, now.month, now.day),
      },
    ];

    for (final task in tasks) {
      final date = task['date'] as DateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (_tasksByDate[dateKey] == null) {
        _tasksByDate[dateKey] = [];
      }
      _tasksByDate[dateKey]!.add(task);
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    final tasks = _tasksByDate[DateTime(date.year, date.month, date.day)] ?? [];
    _showDailyTasksBottomSheet(date, tasks);

    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  void _onDateLongPressed(DateTime date) {
    HapticFeedback.mediumImpact();
    _navigateToAddTask(date);
  }

  void _onPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });

    if (_isWeekView) {
      _weekPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _monthPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    HapticFeedback.lightImpact();
  }

  void _onNextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });

    if (_isWeekView) {
      _weekPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _monthPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    HapticFeedback.lightImpact();
  }

  void _onTodayPressed() {
    final today = DateTime.now();
    setState(() {
      _currentMonth = DateTime(today.year, today.month);
      _selectedDate = today;
    });

    HapticFeedback.mediumImpact();
  }

  void _onViewToggle() {
    setState(() {
      _isWeekView = !_isWeekView;
    });

    HapticFeedback.selectionClick();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();

    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isRefreshing = false;
    });

    _refreshController.reset();
  }

  void _showDailyTasksBottomSheet(
    DateTime date,
    List<Map<String, dynamic>> tasks,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyTasksBottomSheet(
        selectedDate: date,
        tasks: tasks,
        onTaskTap: _onTaskTap,
        onAddTask: () => _navigateToAddTask(date),
      ),
    );
  }

  void _onTaskTap(Map<String, dynamic> task) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/add-edit-task', arguments: task);
  }

  void _navigateToAddTask(DateTime? date) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/add-edit-task',
      arguments: {'selectedDate': date ?? _selectedDate},
    );
  }

  void _navigateToTimeline() {
    Navigator.pushNamed(context, '/task-list-view');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CalendarHeaderWidget(
              currentMonth: _currentMonth,
              isWeekView: _isWeekView,
              onPreviousMonth: _onPreviousMonth,
              onNextMonth: _onNextMonth,
              onTodayPressed: _onTodayPressed,
              onViewToggle: _onViewToggle,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.lightTheme.primaryColor,
                child: _isWeekView ? _buildWeekView() : _buildMonthView(),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthView() {
    return PageView.builder(
      controller: _monthPageController,
      onPageChanged: (index) {
        final monthOffset = index - 1000;
        final now = DateTime.now();
        setState(() {
          _currentMonth = DateTime(now.year, now.month + monthOffset);
        });
      },
      itemBuilder: (context, index) {
        final monthOffset = index - 1000;
        final now = DateTime.now();
        final month = DateTime(now.year, now.month + monthOffset);

        return CalendarMonthWidget(
          currentMonth: month,
          selectedDate: _selectedDate,
          tasksByDate: _tasksByDate,
          onDateSelected: _onDateSelected,
          onDateLongPressed: _onDateLongPressed,
        );
      },
    );
  }

  Widget _buildWeekView() {
    return PageView.builder(
      controller: _weekPageController,
      onPageChanged: (index) {
        final weekOffset = index - 1000;
        final now = DateTime.now();
        final startOfWeek = _getStartOfWeek(now);
        final selectedWeek = startOfWeek.add(Duration(days: weekOffset * 7));

        setState(() {
          _currentMonth = DateTime(selectedWeek.year, selectedWeek.month);
        });
      },
      itemBuilder: (context, index) {
        final weekOffset = index - 1000;
        final now = DateTime.now();
        final startOfWeek = _getStartOfWeek(now);
        final selectedWeek = startOfWeek.add(Duration(days: weekOffset * 7));

        return CalendarWeekWidget(
          selectedWeek: selectedWeek,
          selectedDate: _selectedDate,
          tasksByDate: _tasksByDate,
          onDateSelected: _onDateSelected,
          onDateLongPressed: _onDateLongPressed,
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _navigateToTimeline,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.primaryColor.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'timeline',
                      size: 20,
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Timeline View',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: () => _navigateToAddTask(null),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.primaryColor.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CustomIconWidget(
                iconName: 'add',
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday % 7;
    return date.subtract(Duration(days: weekday));
  }
}
