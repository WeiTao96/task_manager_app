import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  String _filter = 'all'; // all, completed, pending

  List<Task> get tasks {
    switch (_filter) {
      case 'completed':
        return _tasks.where((task) => task.isCompleted).toList();
      case 'pending':
        return _tasks.where((task) => !task.isCompleted).toList();
      default:
        return _tasks;
    }
  }

  String get filter => _filter;

  final TaskService _taskService = TaskService();

  Future<void> loadTasks() async {
    _tasks = await _taskService.getTasks();
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    await _taskService.addTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _taskService.updateTask(task);
    await loadTasks();
  }

   // 删除任务
  Future<void> deleteTask(String id) async {
    await _taskService.deleteTask(id);
    await loadTasks();
  }

  // 切换任务完成状态
  Future<void> toggleTaskCompletion(String id) async {
    final task = _tasks.firstWhere((task) => task.id == id);
    task.isCompleted = !task.isCompleted;
    await updateTask(task);
  }

  Future<void> setFilter(String filter) async {
    _filter = filter;
    notifyListeners();
  }
}
