import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';

class CategoryBreakdownChartWidget extends StatefulWidget {
  final Map<TodoCategory, int>? categoryBreakdown;

  const CategoryBreakdownChartWidget({super.key, this.categoryBreakdown});

  @override
  State<CategoryBreakdownChartWidget> createState() =>
      _CategoryBreakdownChartWidgetState();
}

class _CategoryBreakdownChartWidgetState
    extends State<CategoryBreakdownChartWidget> {
  int touchedIndex = -1;

  static const Map<TodoCategory, Color> _categoryColors = {
    TodoCategory.work: Color(0xFF2563EB),
    TodoCategory.personal: Color(0xFF059669),
    TodoCategory.shopping: Color(0xFFD97706),
    TodoCategory.health: Color(0xFF8B5CF6),
    TodoCategory.education: Color(0xFFF59E0B),
    TodoCategory.finance: Color(0xFFDC2626),
  };

  static const Map<TodoCategory, String> _categoryNames = {
    TodoCategory.work: 'Work',
    TodoCategory.personal: 'Personal',
    TodoCategory.shopping: 'Shopping',
    TodoCategory.health: 'Health',
    TodoCategory.education: 'Education',
    TodoCategory.finance: 'Finance',
  };

  List<Map<String, dynamic>> _buildCategoryData() {
    if (widget.categoryBreakdown == null || widget.categoryBreakdown!.isEmpty) {
      return [
        {
          'name': 'Work',
          'value': 45,
          'color': _categoryColors[TodoCategory.work],
        },
        {
          'name': 'Personal',
          'value': 25,
          'color': _categoryColors[TodoCategory.personal],
        },
        {
          'name': 'Shopping',
          'value': 15,
          'color': _categoryColors[TodoCategory.shopping],
        },
        {
          'name': 'Health',
          'value': 10,
          'color': _categoryColors[TodoCategory.health],
        },
        {
          'name': 'Education',
          'value': 3,
          'color': _categoryColors[TodoCategory.education],
        },
        {
          'name': 'Finance',
          'value': 2,
          'color': _categoryColors[TodoCategory.finance],
        },
      ];
    }

    return widget.categoryBreakdown!.entries
        .map(
          (entry) => {
            'name': _categoryNames[entry.key] ?? 'Unknown',
            'value': entry.value,
            'color': _categoryColors[entry.key] ?? Colors.grey,
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryData = _buildCategoryData();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 25.h,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 8.w,
                      sections: categoryData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final isTouched = index == touchedIndex;
                        final fontSize = isTouched ? 14.sp : 12.sp;
                        final radius = isTouched ? 12.w : 10.w;

                        return PieChartSectionData(
                          color: data['color'] as Color,
                          value: (data['value'] as int).toDouble(),
                          title: '${data["value"]}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: isTouched
                              ? Container(
                                  padding: EdgeInsets.all(1.w),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.shadowColor,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    data['name'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                )
                              : null,
                          badgePositionPercentageOffset: 1.3,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryData.map((data) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        children: [
                          Container(
                            width: 3.w,
                            height: 3.w,
                            decoration: BoxDecoration(
                              color: data['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${data["value"]}%',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
