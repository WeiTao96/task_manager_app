import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'profession_provider.dart';
import 'shop_provider.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  String _filter = 'all'; // all, completed, pending
  ProfessionProvider? _professionProvider; // 职业提供者引用
  ShopProvider? _shopProvider; // 商店提供者引用

  List<Task> get tasks {
    switch (_filter) {
      case 'completed':
        return _tasks.where((task) => task.isCompleted).toList();
      case 'pending':
        return _tasks.where((task) => !task.isCompleted).toList();
      default:
        if (_filter.startsWith('category:')) {
          final category = _filter.substring(9); // 移除 'category:' 前缀
          return _tasks.where((task) => task.category == category).toList();
        }
        return _tasks;
    }
  }

  String get filter => _filter;

  final TaskService _taskService = TaskService();

  // 设置职业提供者引用
  void setProfessionProvider(ProfessionProvider professionProvider) {
    _professionProvider = professionProvider;
  }

  // 设置商店提供者引用
  void setShopProvider(ShopProvider shopProvider) {
    _shopProvider = shopProvider;
  }

  Future<void> loadTasks() async {
    try {
      _tasks = await _taskService.getTasks();
      notifyListeners();
    } catch (e) {
      print('Error loading tasks: $e');
      _tasks = []; // 如果加载失败，设置为空列表
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _taskService.addTask(task);
      await loadTasks();
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _taskService.updateTask(task);
      await loadTasks();
    } catch (e) {
      print('Error updating task: $e');
    }
  }

   // 删除任务
  Future<void> deleteTask(String id) async {
    try {
      await _taskService.deleteTask(id);
      await loadTasks();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

    // 切换任务完成状态
  Future<void> toggleTaskCompletion(String id) async {
    final task = _tasks.firstWhere((task) => task.id == id);
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    
    // 如果任务刚完成且分类是职业名称，给职业添加经验
    if (!wasCompleted && task.isCompleted && _professionProvider != null) {
      // 应用商店增益效果
      double expMultiplier = 1.0;
      if (_shopProvider != null) {
        expMultiplier = _shopProvider!.getExpMultiplier();
      }
      
      final finalExp = (task.xp * expMultiplier).round();
      
      // 通过职业名称查找职业
      try {
        final profession = _professionProvider!.professions.firstWhere(
          (prof) => prof.name == task.category,
        );
        await _professionProvider!.addExperienceToProfession(profession.id, finalExp);
        
        // 如果应用了增益，显示额外获得的经验
        if (expMultiplier > 1.0) {
          final bonusExp = finalExp - task.xp;
          print('经验药水生效！额外获得 $bonusExp 经验！');
        }
      } catch (e) {
        // 如果没找到对应职业，说明是默认分类，不做任何操作
      }
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

  // 更新用户金币（用于商店消费）
  Future<void> updateGold(int newGoldAmount) async {
    // 这里可以添加一个记录来跟踪金币的使用
    // 暂时通过添加一个负值的"交易"记录来实现
    if (newGoldAmount < totalGold) {
      final spent = totalGold - newGoldAmount;
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = Task(
        id: id,
        title: '商店消费',
        description: '在商店购买物品',
        isCompleted: true,
        dueDate: DateTime.now(),
        category: '交易',
        xp: 0,
        gold: -spent, // 负值表示消费
      );
      await addTask(transaction);
    }
  }
}
