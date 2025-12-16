import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart'; // For Id
import 'package:sizer/sizer.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';
import 'package:todo_task_manager/core/data/repository/todo_repositroy.dart';
import 'package:todo_task_manager/providers/todo_provider.dart';

import '../../core/app_export.dart';
import './widgets/task_form_widget.dart';

Todo? _mapToTodo(Map<String, dynamic> map) {
  if (map.isEmpty) return null;

  try {
    final priorityName = (map['priority'] as String? ?? TodoPriority.low.name)
        .toLowerCase();
    final categoryName =
        (map['category'] as String? ?? TodoCategory.personal.name)
            .toLowerCase();

    final todo = Todo()
      ..id = map['id'] as int
      ..title = map['title'] as String
      ..description = map['description'] as String?
      ..priority = TodoPriority.values.byName(priorityName)
      ..category = TodoCategory.values.byName(categoryName)
      ..isCompleted = map['isCompleted'] as bool? ?? false
      ..dueDate = map['dueDate'] as DateTime?
      ..createdAt = map['createdAt'] as DateTime? ?? DateTime.now()
      ..completedAt = map['completedAt'] as DateTime?;

    return todo;
  } catch (e) {
    debugPrint('Error converting Map to Todo: $e');
    return null;
  }
}

class AddEditTask extends ConsumerStatefulWidget {
  final Map<String, dynamic>? task;

  const AddEditTask({super.key, this.task});

  @override
  ConsumerState<AddEditTask> createState() => _AddEditTaskState();
}

class _AddEditTaskState extends ConsumerState<AddEditTask> {
  bool _hasUnsavedChanges = false;
  Todo? _initialTodo;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _initialTodo = _mapToTodo(widget.task!);
    }
  }

  void _onFormChanged(bool hasChanges) {
    if (_hasUnsavedChanges != hasChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _initialTodo != null;
    final isarRepository = ref.read(todoRepositoryProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_hasUnsavedChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          leading: IconButton(
            onPressed: () async {
              if (_hasUnsavedChanges) {
                final shouldPop = await _showUnsavedChangesDialog();
                if (shouldPop == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          title: Text(
            isEditing ? 'Edit Task' : 'Add New Task',
            style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
          ),
          centerTitle: true,
          actions: [
            if (isEditing && _initialTodo!.id != Isar.autoIncrement)
              IconButton(
                onPressed: () => _showDeleteConfirmationDialog(
                  _initialTodo!.id,
                  isarRepository,
                ),
                icon: CustomIconWidget(
                  iconName: 'delete',
                  color: AppTheme.lightTheme.colorScheme.error,
                  size: 24,
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: TaskFormWidget(
            initialTodo: _initialTodo,
            onSave: (todoToSave) => _handleSaveTask(todoToSave, isarRepository),
            onChanged: _onFormChanged,
          ),
        ),
      ),
    );
  }

  void _handleSaveTask(Todo taskData, TodoRepository repository) async {
    try {
      await repository.add(taskData);

      _showSuccessMessage(
        _initialTodo != null
            ? 'Task updated successfully!'
            : 'Task created successfully!',
      );

      _triggerHapticFeedback();

      if (context.mounted) {
        Navigator.of(context).pop({'saved': true, 'id': taskData.id});
      }
    } catch (e) {
      _showSuccessMessage('Error saving task: ${e.toString()}', isError: true);
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    int id,
    TodoRepository repository,
  ) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'delete_forever',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Delete Task',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this task? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTask(id, repository);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(int id, TodoRepository repository) async {
    try {
      await repository.delete(id);
      _showSuccessMessage('Task deleted successfully!');

      if (context.mounted) {
        Navigator.of(context).pop({'deleted': true});
      }
    } catch (e) {
      _showSuccessMessage(
        'Error deleting task: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _showSuccessMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: isError ? 'error' : 'check_circle',
              color: isError ? Colors.white : AppTheme.getSuccessColor(true),
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.getSuccessColor(true),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _triggerHapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: AppTheme.getWarningColor(true),
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Unsaved Changes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes. Are you sure you want to leave without saving?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Leave',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
