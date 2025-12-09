import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'profession_provider.dart';
import 'shop_provider.dart';
import 'achievement_provider.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  String _filter = 'all'; // all, completed, pending
  ProfessionProvider? _professionProvider; // 职业提供者引用
  ShopProvider? _shopProvider; // 商店提供者引用
  AchievementProvider? _achievementProvider; // 成就提供者引用
  bool _isLoading = false; // 防止重复加载
  int _spentGold = 0; // 非持久化：记录已消费的金币，用于在商店购买时减少显示的金币

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
  bool get isLoading => _isLoading;

  final TaskService _taskService = TaskService();

  Task? _findLocalTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Task?> _getTemplateTask(String templateId) async {
    final local = _findLocalTaskById(templateId);
    if (local != null) {
      return local;
    }
    return await _taskService.getTaskById(templateId);
  }

  Future<void> _updateTemplateGenerationInfo(
    String templateId,
    DateTime generatedDate,
  ) async {
    try {
      final template = await _getTemplateTask(templateId);
      if (template == null) {
        return;
      }

      template.lastCompletedDate = generatedDate;
      await _taskService.updateTask(template);

      final index = _tasks.indexWhere((task) => task.id == templateId);
      if (index != -1) {
        _tasks[index] = template;
      }
    } catch (e) {
      print('Error updating template generation info: $e');
    }
  }

  // 设置职业提供者引用
  void setProfessionProvider(ProfessionProvider professionProvider) {
    _professionProvider = professionProvider;
  }

  // 设置商店提供者引用
  void setShopProvider(ShopProvider shopProvider) {
    _shopProvider = shopProvider;
  }

  // 设置成就提供者引用
  void setAchievementProvider(AchievementProvider achievementProvider) {
    _achievementProvider = achievementProvider;
  }

  Future<void> loadTasks() async {
    // 防止重复加载
    if (_isLoading) {
      print('Already loading tasks, skipping...');
      return;
    }

    _isLoading = true;
    try {
      _tasks = await _taskService.getTasks();

      // 清理不需要的系统任务（如商店消费任务）
      await _cleanupSystemTasks();

      // 生成重复任务
      await _generateRepeatTasks();

      // 从 purchase_records 聚合已消费的金币并更新（持久化恢复）
      await _loadSpentFromPurchaseRecords();

      notifyListeners();
    } catch (e) {
      print('Error loading tasks: $e');
      _tasks = []; // 如果加载失败，设置为空列表
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // 清理不需要的系统任务
  Future<void> _cleanupSystemTasks() async {
    try {
      // 清理商店消费任务
      await removeTasksByTitle('商店消费');
    } catch (e) {
      print('Error cleaning up system tasks: $e');
    }
  }

  // 生成重复任务
  Future<void> _generateRepeatTasks() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 处理每日任务
      await _generateDailyTasks(today);

      // 处理每周任务
      await _generateWeeklyTasks(today);

      // 清理过期的重复任务
      await _cleanupExpiredRepeatTasks(today);
    } catch (e) {
      print('Error generating repeat tasks: $e');
    }
  }

  // 生成每日任务
  Future<void> _generateDailyTasks(DateTime today) async {
    try {
      // 找到所有每日任务模板（原始任务）
      final dailyTemplates = _tasks
          .where(
            (task) =>
                task.repeatType == TaskRepeatType.daily &&
                task.originalTaskId == null,
          )
          .toList();

      for (final template in dailyTemplates) {
        // 检查今天是否已经有这个任务的实例
        final hasToday = _tasks.any(
          (task) =>
              task.originalTaskId == template.id &&
              _isSameDay(task.dueDate, today),
        );

        final generatedToday =
            template.lastCompletedDate != null &&
            _isSameDay(template.lastCompletedDate!, today);

        if (!hasToday && !generatedToday) {
          // 创建今天的任务实例
          final todayTask = Task(
            id: '${template.id}_${today.millisecondsSinceEpoch}',
            title: template.title,
            description: template.description,
            dueDate: DateTime(today.year, today.month, today.day, 23, 59, 59),
            category: template.category,
            xp: template.xp,
            gold: template.gold,
            repeatType: TaskRepeatType.daily,
            difficulty: template.difficulty,
            originalTaskId: template.id,
          );

          await _taskService.addTask(todayTask);
          _tasks.add(todayTask);

          await _updateTemplateGenerationInfo(template.id, todayTask.dueDate);
        }
      }
    } catch (e) {
      print('Error generating daily tasks: $e');
    }
  }

  // 生成每周任务
  Future<void> _generateWeeklyTasks(DateTime today) async {
    try {
      // 获取本周的开始日期（周一）
      final weekStart = today.subtract(Duration(days: today.weekday - 1));

      // 找到所有每周任务模板
      final weeklyTemplates = _tasks
          .where(
            (task) =>
                task.repeatType == TaskRepeatType.weekly &&
                task.originalTaskId == null,
          )
          .toList();

      for (final template in weeklyTemplates) {
        // 检查本周是否已经有这个任务的实例
        final hasThisWeek = _tasks.any(
          (task) =>
              task.originalTaskId == template.id &&
              _isInSameWeek(task.dueDate, today),
        );

        final generatedThisWeek =
            template.lastCompletedDate != null &&
            _isInSameWeek(template.lastCompletedDate!, today);

        if (!hasThisWeek && !generatedThisWeek) {
          // 创建本周的任务实例（截止日期为周日）
          final weekEnd = weekStart.add(Duration(days: 6));
          final thisWeekTask = Task(
            id: '${template.id}_week_${weekStart.millisecondsSinceEpoch}',
            title: template.title,
            description: template.description,
            dueDate: DateTime(
              weekEnd.year,
              weekEnd.month,
              weekEnd.day,
              23,
              59,
              59,
            ),
            category: template.category,
            xp: template.xp,
            gold: template.gold,
            repeatType: TaskRepeatType.weekly,
            difficulty: template.difficulty,
            originalTaskId: template.id,
          );

          await _taskService.addTask(thisWeekTask);
          _tasks.add(thisWeekTask);

          await _updateTemplateGenerationInfo(
            template.id,
            thisWeekTask.dueDate,
          );
        }
      }
    } catch (e) {
      print('Error generating weekly tasks: $e');
    }
  }

  // 清理过期的重复任务
  Future<void> _cleanupExpiredRepeatTasks(DateTime today) async {
    try {
      final expiredTasks = <Task>[];

      for (final task in _tasks) {
        if (task.originalTaskId != null) {
          // 这是一个重复任务实例
          bool shouldRemove = false;

          if (task.repeatType == TaskRepeatType.daily) {
            // 清理昨天及之前的未完成每日任务
            if (task.dueDate.isBefore(today) && !task.isCompleted) {
              shouldRemove = true;
            }
          } else if (task.repeatType == TaskRepeatType.weekly) {
            // 清理上周及之前的未完成每周任务
            if (!_isInSameWeek(task.dueDate, today) &&
                task.dueDate.isBefore(today) &&
                !task.isCompleted) {
              shouldRemove = true;
            }
          }

          if (shouldRemove) {
            expiredTasks.add(task);
          }
        }
      }

      // 删除过期任务
      for (final task in expiredTasks) {
        await _taskService.deleteTask(task.id);
        _tasks.remove(task);
      }

      if (expiredTasks.isNotEmpty) {
        print('Cleaned up ${expiredTasks.length} expired repeat tasks');
      }
    } catch (e) {
      print('Error cleaning up expired repeat tasks: $e');
    }
  }

  // 检查两个日期是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 检查两个日期是否在同一周
  bool _isInSameWeek(DateTime date1, DateTime date2) {
    final startOfWeek1 = date1.subtract(Duration(days: date1.weekday - 1));
    final startOfWeek2 = date2.subtract(Duration(days: date2.weekday - 1));
    return _isSameDay(startOfWeek1, startOfWeek2);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  Future<void> _handleRepeatTaskCompletion(Task task) async {
    if (task.repeatType == TaskRepeatType.special) {
      return;
    }

    final baseId = task.originalTaskId ?? task.id;

    if (task.repeatType == TaskRepeatType.daily) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      final nextDate = taskDate.add(Duration(days: 1));
      final nextDueDate = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        23,
        59,
        59,
      );

      final alreadyExists = _tasks.any(
        (t) => t.originalTaskId == baseId && _isSameDay(t.dueDate, nextDueDate),
      );
      if (!alreadyExists) {
        final nextTask = Task(
          id: '${baseId}_${nextDueDate.millisecondsSinceEpoch}',
          title: task.title,
          description: task.description,
          dueDate: nextDueDate,
          category: task.category,
          xp: task.xp,
          gold: task.gold,
          repeatType: TaskRepeatType.daily,
          difficulty: task.difficulty,
          originalTaskId: baseId,
        );
        await _taskService.addTask(nextTask);
      }

      await _updateTemplateGenerationInfo(baseId, nextDueDate);
    } else if (task.repeatType == TaskRepeatType.weekly) {
      final currentWeekStart = _startOfWeek(task.dueDate);
      final nextWeekStart = currentWeekStart.add(Duration(days: 7));
      final nextWeekEnd = nextWeekStart.add(Duration(days: 6));
      final nextDueDate = DateTime(
        nextWeekEnd.year,
        nextWeekEnd.month,
        nextWeekEnd.day,
        23,
        59,
        59,
      );

      final alreadyExists = _tasks.any(
        (t) =>
            t.originalTaskId == baseId && _isInSameWeek(t.dueDate, nextDueDate),
      );
      if (!alreadyExists) {
        final nextTask = Task(
          id: '${baseId}_week_${nextWeekStart.millisecondsSinceEpoch}',
          title: task.title,
          description: task.description,
          dueDate: nextDueDate,
          category: task.category,
          xp: task.xp,
          gold: task.gold,
          repeatType: TaskRepeatType.weekly,
          difficulty: task.difficulty,
          originalTaskId: baseId,
        );
        await _taskService.addTask(nextTask);
      }

      await _updateTemplateGenerationInfo(baseId, nextDueDate);
    }
  }

  Future<void> _handleRepeatTaskRevert(Task task) async {
    if (task.repeatType == TaskRepeatType.special) {
      return;
    }

    final baseId = task.originalTaskId ?? task.id;
    final now = DateTime.now();

    final futureTasks = _tasks
        .where((t) => t.originalTaskId == baseId && t.dueDate.isAfter(now))
        .toList();

    for (final futureTask in futureTasks) {
      await _taskService.deleteTask(futureTask.id);
      _tasks.removeWhere((t) => t.id == futureTask.id);
    }

    await _updateTemplateGenerationInfo(baseId, task.dueDate);
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
      final task = _findLocalTaskById(id);
      if (task != null && task.originalTaskId != null) {
        await _updateTemplateGenerationInfo(task.originalTaskId!, task.dueDate);
      }
      _tasks.removeWhere((task) => task.id == id);
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

    // 如果任务刚完成，记录完成时间
    if (!wasCompleted && task.isCompleted) {
      task.lastCompletedDate = DateTime.now();

      // 如果分类是职业名称，给职业添加经验
      if (_professionProvider != null) {
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
          await _professionProvider!.addExperienceToProfession(
            profession.id,
            finalExp,
          );

          // 如果应用了增益，显示额外获得的经验
          if (expMultiplier > 1.0) {
            final bonusExp = finalExp - task.xp;
            print('经验药水生效！额外获得 $bonusExp 经验！');
          }
        } catch (e) {
          // 如果没找到对应职业，说明是默认分类，不做任何操作
        }
      }

      // 检查成就进度
      if (_achievementProvider != null) {
        await _checkAchievements(task);
      }

      await _handleRepeatTaskCompletion(task);
    } else if (wasCompleted && !task.isCompleted) {
      task.lastCompletedDate = null;
      await _handleRepeatTaskRevert(task);
    }

    await updateTask(task);
  }

  // 检查成就进度
  Future<void> _checkAchievements(Task recentlyCompletedTask) async {
    if (_achievementProvider == null) return;

    final completedTasks = _tasks.where((t) => t.isCompleted).toList();

    // 计算每个难度的任务完成数量
    final difficultyTaskCounts = <TaskDifficulty, int>{};
    for (final difficulty in TaskDifficulty.values) {
      difficultyTaskCounts[difficulty] = completedTasks
          .where((t) => t.difficulty == difficulty)
          .length;
    }

    await _achievementProvider!.checkAchievements(
      completedTasks: completedTasks,
      totalExperience: totalExp,
      totalGold: totalGold,
      currentStreak: 0, // TODO: 实现连续天数计算
      difficultyTaskCounts: difficultyTaskCounts,
      recentlyCompletedTask: recentlyCompletedTask,
    );
  }

  // total experience from completed tasks
  int get totalExp {
    return _tasks.where((t) => t.isCompleted).fold(0, (sum, t) => sum + (t.xp));
  }

  // total gold from completed tasks
  int get totalGold {
    final earned = _tasks
        .where((t) => t.isCompleted)
        .fold(0, (sum, t) => sum + (t.gold));
    final current = earned - _spentGold;
    return current < 0 ? 0 : current;
  }

  // 从数据库中的 purchase_records 表聚合已消费金币
  Future<void> _loadSpentFromPurchaseRecords() async {
    try {
      final records = await _taskService.getPurchaseHistory();
      // getPurchaseHistory 已经按 userId = 'current_user' 过滤
      final spent = records.fold<int>(
        0,
        (sum, r) => sum + ((r['pricePaid'] as int?) ?? 0),
      );
      _spentGold = spent;
      notifyListeners();
    } catch (e) {
      print('Error loading spent gold from purchase_records: $e');
    }
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
  Future<void> addReward({
    required int xp,
    required int gold,
    String? note,
  }) async {
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
    // 购买操作已经在 ShopProvider 中写入 purchase_records 表，
    // 这里重新从数据库聚合已消费金额以保证数据一致性
    await _loadSpentFromPurchaseRecords();
  }

  // 删除特定标题的任务（用于清理不需要的系统任务）
  Future<void> removeTasksByTitle(String title) async {
    try {
      // 找出所有匹配标题的任务
      final tasksToRemove = _tasks
          .where((task) => task.title == title)
          .toList();

      // 从数据库中删除
      for (final task in tasksToRemove) {
        await _taskService.deleteTask(task.id);
      }

      // 从本地列表中移除
      _tasks.removeWhere((task) => task.title == title);

      notifyListeners();
      print('Removed ${tasksToRemove.length} tasks with title: $title');
    } catch (e) {
      print('Error removing tasks by title: $e');
    }
  }
}
