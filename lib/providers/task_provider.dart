import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'profession_provider.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  String _filter = 'all'; // all, completed, pending
  ProfessionProvider? _professionProvider; // 职业提供者引用

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

  // 设置职业提供者引用
  void setProfessionProvider(ProfessionProvider professionProvider) {
    _professionProvider = professionProvider;
  }

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
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    
    // 如果任务刚完成且关联了职业，给职业添加经验
    if (!wasCompleted && task.isCompleted && task.professionId != null && _professionProvider != null) {
      await _professionProvider!.addExperienceToProfession(task.professionId!, task.xp);
    }
    
    await updateTask(task);
  }

  // total experience from completed tasks
  int get totalExp {
    return _tasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + (t.xp));
  }

  // total gold from completed tasks
  int get totalGold {
    return _tasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + (t.gold));
  }

  // 获取今日完成的任务数量（不包括奖励任务）
  int get todayCompletedTasks {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));
    
    return _tasks.where((task) {
      return task.isCompleted && 
             task.category != '奖励' && // 排除宝箱奖励任务
             task.dueDate.isAfter(todayStart) && 
             task.dueDate.isBefore(todayEnd);
    }).length;
  }

  // 检查今日是否已领取宝箱奖励
  bool get hasTodayTreasure {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));
    
    return _tasks.any((task) {
      return task.category == '奖励' && 
             task.title.contains('宝箱奖励') &&
             task.dueDate.isAfter(todayStart) && 
             task.dueDate.isBefore(todayEnd);
    });
  }

  // 检查是否可以开启宝箱（完成3个任务且今日未领取）
  bool get canOpenTreasure {
    return todayCompletedTasks >= 3 && !hasTodayTreasure;
  }

  Future<void> setFilter(String filter) async {
    _filter = filter;
    notifyListeners();
  }

  // 添加一次性奖励（宝箱或活动奖励）并标记为已完成以便计入总经验/金币
  Future<void> addReward({required int xp, required int gold, String? note}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final task = Task(
      id: id,
      title: note ?? '宝箱奖励',
      description: '来自宝箱的奖励',
      isCompleted: true,
      dueDate: DateTime.now(),
      category: '奖励',
      xp: xp,
      gold: gold,
    );
    await addTask(task);
  }
}
