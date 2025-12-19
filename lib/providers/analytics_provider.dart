import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';
import 'package:todo_task_manager/providers/todo_provider.dart';

/// Analytics metrics for tasks
class AnalyticsMetrics {
  final int tasksCompleted;
  final int tasksTotal;
  final double completionRate;
  final int currentStreak;
  final int longestStreak;
  final double dailyAverage;
  final Map<TodoCategory, int> categoryBreakdown;
  final Map<TodoPriority, int> priorityDistribution;
  final List<DailyStats> dailyStats;

  AnalyticsMetrics({
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.completionRate,
    required this.currentStreak,
    required this.longestStreak,
    required this.dailyAverage,
    required this.categoryBreakdown,
    required this.priorityDistribution,
    required this.dailyStats,
  });
}

/// Daily statistics for trend analysis
class DailyStats {
  final DateTime date;
  final int completed;
  final int total;
  final double completionRate;

  DailyStats({
    required this.date,
    required this.completed,
    required this.total,
    required this.completionRate,
  });
}

/// Analytics repository for computing metrics
class AnalyticsRepository {
  AnalyticsMetrics computeWeeklyMetrics(List<Todo> todos) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return _computeMetrics(todos, weekAgo, now);
  }

  AnalyticsMetrics computeMonthlyMetrics(List<Todo> todos) {
    final now = DateTime.now();
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    return _computeMetrics(todos, monthAgo, now);
  }

  AnalyticsMetrics computeYearlyMetrics(List<Todo> todos) {
    final now = DateTime.now();
    final yearAgo = DateTime(now.year - 1, now.month, now.day);

    return _computeMetrics(todos, yearAgo, now);
  }

  AnalyticsMetrics _computeMetrics(
    List<Todo> todos,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Filter todos within date range
    final filteredTodos = todos.where((todo) {
      final createdAt = todo.createdAt;
      return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
    }).toList();

    // Calculate completion metrics
    final completedTodos = filteredTodos
        .where((todo) => todo.isCompleted)
        .toList();
    final tasksCompleted = completedTodos.length;
    final tasksTotal = filteredTodos.length;
    final completionRate = tasksTotal > 0
        ? (tasksCompleted / tasksTotal) * 100
        : 0.0;

    // Calculate daily average
    final daysDifference = endDate.difference(startDate).inDays;
    final dailyAverage = daysDifference > 0
        ? tasksCompleted / daysDifference
        : 0.0;

    // Calculate streaks
    final streakData = _calculateStreaks(filteredTodos);
    final currentStreak = streakData['current'] ?? 0;
    final longestStreak = streakData['longest'] ?? 0;

    // Calculate category breakdown
    final categoryBreakdown = _calculateCategoryBreakdown(filteredTodos);

    // Calculate priority distribution
    final priorityDistribution = _calculatePriorityDistribution(filteredTodos);

    // Calculate daily stats
    final dailyStats = _calculateDailyStats(filteredTodos, startDate, endDate);

    return AnalyticsMetrics(
      tasksCompleted: tasksCompleted,
      tasksTotal: tasksTotal,
      completionRate: completionRate,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      dailyAverage: dailyAverage,
      categoryBreakdown: categoryBreakdown,
      priorityDistribution: priorityDistribution,
      dailyStats: dailyStats,
    );
  }

  /// Calculate current and longest streaks
  Map<String, int> _calculateStreaks(List<Todo> todos) {
    if (todos.isEmpty) return {'current': 0, 'longest': 0};

    // Sort todos by completion date (most recent first)
    final sortedTodos = todos.where((todo) => todo.isCompleted).toList()
      ..sort(
        (a, b) => (b.completedAt ?? DateTime.now()).compareTo(
          a.completedAt ?? DateTime.now(),
        ),
      );

    if (sortedTodos.isEmpty) return {'current': 0, 'longest': 0};

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final now = DateTime.now();
    DateTime? lastDate;

    for (final todo in sortedTodos) {
      final completedDate = todo.completedAt ?? DateTime.now();
      final daysDiff = now.difference(completedDate).inDays; // Count from today

      if (lastDate == null) {
        // First task
        if (daysDiff <= 1) {
          tempStreak = 1;
          currentStreak = 1;
        }
      } else {
        final daysBetween = lastDate.difference(completedDate).inDays;
        if (daysBetween == 1) {
          tempStreak++;
          if (daysDiff <= 1) {
            currentStreak = tempStreak;
          }
        } else {
          longestStreak = longestStreak > tempStreak
              ? longestStreak
              : tempStreak;
          tempStreak = 1;
        }
      }

      lastDate = completedDate;
    }

    longestStreak = longestStreak > tempStreak ? longestStreak : tempStreak;

    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Calculate tasks breakdown by category
  Map<TodoCategory, int> _calculateCategoryBreakdown(List<Todo> todos) {
    final breakdown = <TodoCategory, int>{};

    for (final category in TodoCategory.values) {
      breakdown[category] = todos
          .where((todo) => todo.category == category)
          .length;
    }

    return breakdown;
  }

  /// Calculate tasks breakdown by priority
  Map<TodoPriority, int> _calculatePriorityDistribution(List<Todo> todos) {
    final distribution = <TodoPriority, int>{};

    for (final priority in TodoPriority.values) {
      distribution[priority] = todos
          .where((todo) => todo.priority == priority)
          .length;
    }

    return distribution;
  }

  /// Calculate daily statistics
  List<DailyStats> _calculateDailyStats(
    List<Todo> todos,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dailyStatsMap = <DateTime, DailyStats>{};

    // Initialize all days with 0 values
    for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + i);
      dailyStatsMap[date] = DailyStats(
        date: date,
        completed: 0,
        total: 0,
        completionRate: 0.0,
      );
    }

    // Populate with actual data
    for (final todo in todos) {
      final createdDate = DateTime(
        todo.createdAt.year,
        todo.createdAt.month,
        todo.createdAt.day,
      );

      if (dailyStatsMap.containsKey(createdDate)) {
        final current = dailyStatsMap[createdDate]!;
        dailyStatsMap[createdDate] = DailyStats(
          date: createdDate,
          completed: current.completed + (todo.isCompleted ? 1 : 0),
          total: current.total + 1,
          completionRate: 0.0, // Will be calculated below
        );
      }
    }

    // Calculate completion rates
    dailyStatsMap.forEach((date, stats) {
      dailyStatsMap[date] = DailyStats(
        date: stats.date,
        completed: stats.completed,
        total: stats.total,
        completionRate: stats.total > 0
            ? (stats.completed / stats.total) * 100
            : 0.0,
      );
    });

    return dailyStatsMap.values.toList();
  }
}

// Providers

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

final weeklyAnalyticsProvider = StreamProvider<AnalyticsMetrics>((ref) {
  return ref
      .watch(todosStreamProvider)
      .when(
        data: (todos) async* {
          final repository = ref.watch(analyticsRepositoryProvider);
          yield repository.computeWeeklyMetrics(todos);
        },
        loading: () async* {},
        error: (error, stack) async* {},
      );
});

final monthlyAnalyticsProvider = StreamProvider<AnalyticsMetrics>((ref) {
  return ref
      .watch(todosStreamProvider)
      .when(
        data: (todos) async* {
          final repository = ref.watch(analyticsRepositoryProvider);
          yield repository.computeMonthlyMetrics(todos);
        },
        loading: () async* {},
        error: (error, stack) async* {},
      );
});

final yearlyAnalyticsProvider = StreamProvider<AnalyticsMetrics>((ref) {
  return ref
      .watch(todosStreamProvider)
      .when(
        data: (todos) async* {
          final repository = ref.watch(analyticsRepositoryProvider);
          yield repository.computeYearlyMetrics(todos);
        },
        loading: () async* {},
        error: (error, stack) async* {},
      );
});
