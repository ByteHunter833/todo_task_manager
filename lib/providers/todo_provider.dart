// todo_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:todo_task_manager/core/data/models/todo.dart';
import 'package:todo_task_manager/core/data/repository/todo_repositroy.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
    'Isar Provider was not properly overridden in main.dart',
  );
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepository(ref.watch(isarProvider));
});

final todosStreamProvider = StreamProvider<List<Todo>>((ref) {
  return ref.watch(todoRepositoryProvider).watchAll();
});
