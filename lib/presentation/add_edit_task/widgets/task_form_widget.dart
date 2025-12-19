import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:todo_task_manager/core/data/models/todo.dart'; // Import Todo model

import '../../../core/app_export.dart';

class TaskFormWidget extends StatefulWidget {
  final Todo? initialTodo;
  final DateTime? selectedDate;
  final Function(Todo) onSave;
  final Function(bool)? onChanged;

  const TaskFormWidget({
    super.key,
    this.initialTodo,
    this.selectedDate,
    required this.onSave,
    this.onChanged,
  });

  @override
  State<TaskFormWidget> createState() => _TaskFormWidgetState();
}

class _TaskFormWidgetState extends State<TaskFormWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();

  String _selectedPriority = TodoPriority.medium.name.capitalize();
  String _selectedCategory = TodoCategory.work.name.capitalize();
  late DateTime _selectedDate;

  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isFormValid = false;
  late Map<String, dynamic> _initialFormValues;

  final List<String> _priorities = ['High', 'Medium', 'Low'];
  final List<String> _categories = [
    'Work',
    'Personal',
    'Shopping',
    'Health',
    'Education',
    'Finance',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _titleController.addListener(_handleFormChange);
    _descriptionController.addListener(_handleFormChange);
  }

  void _initializeForm() {
    final task = widget.initialTodo;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _selectedPriority = task.priority.name.capitalize();
      _selectedCategory = task.category.name.capitalize();

      if (task.dueDate != null) {
        _selectedDate = task.dueDate!;
        _selectedTime = TimeOfDay.fromDateTime(task.dueDate!);
      } else {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      }
    } else {
      _selectedDate = widget.selectedDate ?? DateTime.now();
    }

    _initialFormValues = _getCurrentFormValues();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      _validateForm();
    });
  }

  Map<String, dynamic> _getCurrentFormValues() {
    return {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _selectedPriority,
      'category': _selectedCategory,
      'date': _selectedDate,
      'time': _selectedTime,
    };
  }

  void _validateForm() {
    final isValid = _titleController.text.trim().isNotEmpty;
    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  void _handleFormChange() {
    _validateForm();
    _checkUnsavedChanges();
  }

  void _checkUnsavedChanges() {
    final currentValues = _getCurrentFormValues();
    final hasChanges = !mapEquals(_initialFormValues, currentValues);
    widget.onChanged?.call(hasChanges);
  }

  bool mapEquals(Map map1, Map map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.lightTheme.colorScheme.error;
      case 'Medium':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'Low':
        return AppTheme.lightTheme.colorScheme.secondary;
      default:
        return AppTheme.lightTheme.colorScheme.secondary;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && !_isSameDate(picked, _selectedDate)) {
      setState(() {
        _selectedDate = picked;
      });
      _checkUnsavedChanges();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _checkUnsavedChanges();
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _saveTask() {
    if (!_isFormValid) return;

    final combinedDueDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Prepare enums
    final priorityEnum = TodoPriority.values.byName(
      _selectedPriority.toLowerCase(),
    );
    final categoryEnum = TodoCategory.values.byName(
      _selectedCategory.toLowerCase(),
    );

    late Todo todoToSave;

    if (widget.initialTodo != null) {
      // Update existing task using copyWith
      todoToSave = widget.initialTodo!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: priorityEnum,
        category: categoryEnum,
        dueDate: combinedDueDate,
      );
    } else {
      // Create new task
      todoToSave = Todo()
        ..title = _titleController.text.trim()
        ..description = _descriptionController.text.trim()
        ..priority = priorityEnum
        ..category = categoryEnum
        ..dueDate = combinedDueDate
        ..createdAt = DateTime.now();
    }

    widget.onSave(todoToSave);
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleFormChange);
    _descriptionController.removeListener(_handleFormChange);
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          _buildSectionTitle('Task Title'),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter task title...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: CustomIconWidget(
                        iconName: 'task_alt',
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice input feature coming soon!'),
                      ),
                    );
                  },
                  icon: CustomIconWidget(
                    iconName: 'mic',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Description Field
          _buildSectionTitle('Description'),
          SizedBox(height: 1.h),
          TextFormField(
            controller: _descriptionController,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add task description (optional)...',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'description',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            minLines: 1,
          ),

          SizedBox(height: 3.h),

          // Date and Time Section
          _buildSectionTitle('Due Date & Time'),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'calendar_today',
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'access_time',
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          size: 20,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          _selectedTime.format(context),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Priority Section
          _buildSectionTitle('Priority Level'),
          SizedBox(height: 1.h),
          Row(
            children: _priorities.map((priority) {
              final isSelected = _selectedPriority == priority;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: priority != _priorities.last ? 2.w : 0,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPriority = priority;
                      });
                      _checkUnsavedChanges();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getPriorityColor(priority).withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _getPriorityColor(priority)
                              : AppTheme.lightTheme.colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          priority,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: isSelected
                                    ? _getPriorityColor(priority)
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: 3.h),

          // Category Section
          _buildSectionTitle('Category'),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'category',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
              ),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
                _checkUnsavedChanges();
              }
            },
          ),

          SizedBox(height: 4.h),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFormValid ? _saveTask : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomIconWidget(
                    iconName: 'save',
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    widget.initialTodo != null ? 'Update Task' : 'Save Task',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
    );
  }
}

// Extension to help with capitalizing first letter of enum names
extension StringCasingExtension on String {
  String capitalize() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
