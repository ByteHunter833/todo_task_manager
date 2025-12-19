import 'package:isar/isar.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';

class TodoRepository {
  final Isar isar;
  final String userId;

  TodoRepository(this.isar, this.userId);

  Stream<List<Todo>> watchAll() {
    return isar.todos
        .filter()
        .userIdEqualTo(userId)
        .watch(fireImmediately: true);
  }

  Future<void> add(Todo todo) async {
    todo.userId = userId; // 👈 гарантируем владельца
    await isar.writeTxn(() => isar.todos.put(todo));
  }

  Future<void> toggle(Todo todo) async {
    if (todo.userId != userId) return; // защита от сюрпризов

    await isar.writeTxn(() {
      todo.isCompleted = !todo.isCompleted;
      todo.completedAt = todo.isCompleted ? DateTime.now() : null;
      return isar.todos.put(todo);
    });
  }

  Future<void> delete(Id id) async {
    final todo = await isar.todos.get(id);
    if (todo == null || todo.userId != userId) return;

    await isar.writeTxn(() => isar.todos.delete(id));
  }
}
