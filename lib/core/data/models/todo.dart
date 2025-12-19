import 'package:isar/isar.dart';

part 'todo.g.dart';

@collection
class Todo {
  Id id = Isar.autoIncrement;

  late String userId; // 👈 КЛЮЧЕВО

  late String title;
  String? description;

  @Enumerated(EnumType.name)
  late TodoPriority priority;

  @Enumerated(EnumType.name)
  late TodoCategory category;

  bool isCompleted = false;
  DateTime? completedAt;

  DateTime createdAt = DateTime.now();
  DateTime? dueDate;

  DateTime? snoozedUntil;

  Todo copyWith({
    String? userId,
    String? title,
    String? description,
    TodoPriority? priority,
    TodoCategory? category,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? snoozedUntil,
  }) {
    return Todo()
      ..id = id
      ..userId = userId ?? this.userId
      ..title = title ?? this.title
      ..description = description ?? this.description
      ..priority = priority ?? this.priority
      ..category = category ?? this.category
      ..isCompleted = isCompleted ?? this.isCompleted
      ..completedAt = completedAt ?? this.completedAt
      ..createdAt = createdAt ?? this.createdAt
      ..dueDate = dueDate ?? this.dueDate
      ..snoozedUntil = snoozedUntil ?? this.snoozedUntil;
  }
}

enum TodoPriority { low, medium, high }

enum TodoCategory { work, personal, health, shopping, education, finance }
