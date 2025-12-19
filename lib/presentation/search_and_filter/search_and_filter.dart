import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/data/models/todo.dart';
import '../../providers/todo_provider.dart';
import './widgets/advanced_filter_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/recent_searches_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/search_results_widget.dart';

class SearchAndFilter extends ConsumerStatefulWidget {
  const SearchAndFilter({super.key});

  @override
  ConsumerState<SearchAndFilter> createState() => _SearchAndFilterState();
}

class _SearchAndFilterState extends ConsumerState<SearchAndFilter> {
  final TextEditingController _searchController = TextEditingController();

  // Search and filter state
  String _searchQuery = '';
  bool _isVoiceSearching = false;
  bool _isAdvancedFilterExpanded = false;
  String _sortBy = 'relevance';

  // Filter state
  Map<String, dynamic> _activeFilters = {};

  // Recent searches
  final List<String> _recentSearches = [
    'Meeting preparation',
    'Shopping list',
    'Project deadline',
    'Doctor appointment',
    'Workout routine',
  ];

  // Search results
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });

      // Add to recent searches if not empty and not already present
      if (query.isNotEmpty && !_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 10) {
            _recentSearches.removeLast();
          }
        });
      }
    }
  }

  void _performSearchOnTodos(List<Map<String, dynamic>> allTasks) {
    List<Map<String, dynamic>> results = List.from(allTasks);

    // Apply text search
    if (_searchQuery.isNotEmpty) {
      results = results.where((task) {
        final title = (task['title'] as String).toLowerCase();
        final description = (task['description'] as String).toLowerCase();
        final category = (task['category'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();

        final titleMatch = title.contains(query);
        final descriptionMatch = description.contains(query);
        final categoryMatch = category.contains(query);

        // Calculate relevance score
        double relevanceScore = 0.0;
        if (titleMatch) relevanceScore += 0.6;
        if (descriptionMatch) relevanceScore += 0.3;
        if (categoryMatch) relevanceScore += 0.1;

        task['relevanceScore'] = relevanceScore;

        return titleMatch || descriptionMatch || categoryMatch;
      }).toList();
    } else {
      // Set default relevance score for all tasks
      for (var task in results) {
        task['relevanceScore'] = 1.0;
      }
    }

    // Apply filters
    results = _applyFilters(results);

    // Apply sorting
    results = _applySorting(results);

    setState(() {
      _searchResults = results;
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> tasks) {
    List<Map<String, dynamic>> filtered = List.from(tasks);

    // Date range filter
    if (_activeFilters['dateRange'] != null) {
      final dateRange = _activeFilters['dateRange'] as Map<String, DateTime>;
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      filtered = filtered.where((task) {
        final dueDate = task['dueDate'] as DateTime?;
        if (dueDate == null) return false;

        final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);

        return (taskDate.isAtSameMomentAs(start) || taskDate.isAfter(start)) &&
            (taskDate.isAtSameMomentAs(end) || taskDate.isBefore(end));
      }).toList();
    }

    // Priority filter
    if (_activeFilters['priorities'] != null &&
        (_activeFilters['priorities'] as List).isNotEmpty) {
      final priorities = _activeFilters['priorities'] as List<String>;
      filtered = filtered.where((task) {
        return priorities.contains(task['priority']);
      }).toList();
    }

    // Category filter
    if (_activeFilters['categories'] != null &&
        (_activeFilters['categories'] as List).isNotEmpty) {
      final categories = _activeFilters['categories'] as List<String>;
      filtered = filtered.where((task) {
        return categories.contains(task['category']);
      }).toList();
    }

    // Status filter
    if (_activeFilters['status'] != null && _activeFilters['status'] != 'All') {
      final status = _activeFilters['status'] as String;
      filtered = filtered.where((task) {
        switch (status) {
          case 'Completed':
            return task['isCompleted'] == true;
          case 'Pending':
            return task['isCompleted'] == false &&
                (task['dueDate'] as DateTime?)?.isAfter(DateTime.now()) == true;
          case 'Overdue':
            return task['isCompleted'] == false &&
                (task['dueDate'] as DateTime?)?.isBefore(DateTime.now()) ==
                    true;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> tasks) {
    List<Map<String, dynamic>> sorted = List.from(tasks);

    switch (_sortBy) {
      case 'relevance':
        sorted.sort((a, b) {
          final scoreA = a['relevanceScore'] as double? ?? 0.0;
          final scoreB = b['relevanceScore'] as double? ?? 0.0;
          return scoreB.compareTo(scoreA);
        });
        break;
      case 'dueDate':
        sorted.sort((a, b) {
          final dateA = a['dueDate'] as DateTime?;
          final dateB = b['dueDate'] as DateTime?;
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;
      case 'priority':
        final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        sorted.sort((a, b) {
          final priorityA = priorityOrder[a['priority']] ?? 3;
          final priorityB = priorityOrder[b['priority']] ?? 3;
          return priorityA.compareTo(priorityB);
        });
        break;
      case 'modified':
        sorted.sort((a, b) {
          final dateA = a['modifiedAt'] as DateTime;
          final dateB = b['modifiedAt'] as DateTime;
          return dateB.compareTo(dateA);
        });
        break;
    }

    return sorted;
  }

  void _onVoiceSearch() {
    setState(() {
      _isVoiceSearching = true;
    });

    // Simulate voice search processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVoiceSearching = false;
          _searchController.text = 'meeting preparation';
          _searchQuery = 'meeting preparation';
        });
      }
    });
  }

  void _onFiltersChanged(Map<String, dynamic> filters) {
    setState(() {
      _activeFilters = Map.from(filters);
    });
  }

  void _onRemoveFilter(String filterKey) {
    setState(() {
      _activeFilters.remove(filterKey);
    });
  }

  void _onClearAllFilters() {
    setState(() {
      _activeFilters.clear();
    });
  }

  void _onRecentSearchTap(String search) {
    _searchController.text = search;
    setState(() {
      _searchQuery = search;
    });
  }

  void _onRemoveRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
    });
  }

  void _onTaskTap(Todo todo) {
    Navigator.pushNamed(context, '/add-edit-task', arguments: todo);
  }

  void _onToggleAdvancedFilter() {
    setState(() {
      _isAdvancedFilterExpanded = !_isAdvancedFilterExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final todosAsyncValue = ref.watch(todosStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Search & Filter'),
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
            onPressed: () =>
                Navigator.pushNamed(context, '/main-task-dashboard'),
            icon: CustomIconWidget(
              iconName: 'home',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: todosAsyncValue.when(
        data: (todos) {
          // Convert Todo objects to search-compatible format
          final allTasks = todos.map((todo) {
            return {
              'id': todo.id,
              'title': todo.title,
              'description': todo.description ?? '',
              'dueDate': todo.dueDate,
              'priority': _priorityToString(todo.priority),
              'category': _categoryToString(todo.category),
              'isCompleted': todo.isCompleted,
              'createdAt': todo.createdAt,
              'modifiedAt': todo.createdAt,
              'todo': todo, // Store original Todo object
            };
          }).toList();

          // Perform search on all tasks
          _performSearchOnTodos(allTasks);

          return CustomScrollView(
            slivers: [
              // 1. Search and Filter section
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 1.h),
                    SearchBarWidget(
                      searchController: _searchController,
                      onSearchChanged: (query) {},
                      onVoiceSearch: _onVoiceSearch,
                      isVoiceSearching: _isVoiceSearching,
                    ),
                    FilterChipsWidget(
                      activeFilters: _activeFilters,
                      onRemoveFilter: _onRemoveFilter,
                      onClearAll: _onClearAllFilters,
                    ),
                    AdvancedFilterWidget(
                      currentFilters: _activeFilters,
                      onFiltersChanged: _onFiltersChanged,
                      isExpanded: _isAdvancedFilterExpanded,
                      onToggleExpanded: _onToggleAdvancedFilter,
                    ),
                    SizedBox(height: 1.h),
                  ],
                ),
              ),

              // 2. Content section
              SliverFillRemaining(
                hasScrollBody: true,
                child: _searchQuery.isEmpty && _activeFilters.isEmpty
                    ? RecentSearchesWidget(
                        recentSearches: _recentSearches,
                        onSearchTap: _onRecentSearchTap,
                        onRemoveSearch: _onRemoveRecentSearch,
                      )
                    : SearchResultsWidget(
                        searchResults: _searchResults,
                        searchQuery: _searchQuery,
                        sortBy: _sortBy,
                        onSortChanged: _onSortChanged,
                        onTaskTap: (task) {
                          if (task['todo'] != null) {
                            _onTaskTap(task['todo'] as Todo);
                          }
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading tasks: $error')),
      ),
    );
  }
}
