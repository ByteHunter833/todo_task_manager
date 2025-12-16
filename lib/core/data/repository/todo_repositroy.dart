import 'package:isar/isar.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';

class TodoRepository {
  final Isar isar;
  TodoRepository(this.isar);

  Stream<List<Todo>> watchAll() {
    return isar.todos.where().watch(fireImmediately: true);
  }

  Future<void> add(Todo todo) async {
    await isar.writeTxn(() => isar.todos.put(todo));
  }

  Future<void> toggle(Todo todo) async {
    await isar.writeTxn(() {
      todo.isCompleted = !todo.isCompleted;
      todo.completedAt = todo.isCompleted ? DateTime.now() : null;
      return isar.todos.put(todo);
    });
  }

  Future<void> delete(Id id) async {
    await isar.writeTxn(() => isar.todos.delete(id));
  }
}
