import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../providers/profession_provider.dart';

class AchievementProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  List<Achievement> _achievements = [];
  ProfessionProvider? _professionProvider;

  List<Achievement> get achievements => _achievements;

  // 已解锁的成就
  List<Achievement> get unlockedAchievements => 
    _achievements.where((a) => a.isUnlocked).toList();

  // 未解锁的成就
  List<Achievement> get lockedAchievements => 
    _achievements.where((a) => !a.isUnlocked).toList();

  // 自定义成就
  List<Achievement> get customAchievements => 
    _achievements.where((a) => a.isCustom).toList();

  // 系统成就
  List<Achievement> get systemAchievements => 
    _achievements.where((a) => !a.isCustom).toList();

  // 设置职业提供者
  void setProfessionProvider(ProfessionProvider professionProvider) {
    _professionProvider = professionProvider;
  }

  // 加载成就
  Future<void> loadAchievements() async {
    try {
      _achievements = await _taskService.getAchievements();
      
      // 如果没有成就，创建一些默认成就
      if (_achievements.isEmpty) {
        await _createDefaultAchievements();
        _achievements = await _taskService.getAchievements();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  // 创建默认成就
  Future<void> _createDefaultAchievements() async {
    final defaultAchievements = [
      Achievement(
        id: 'first_task',
        title: '初出茅庐',
        description: '完成你的第一个任务',
        icon: '🌱',
        type: AchievementType.taskCompletion,
        conditionType: ConditionType.taskCount,
        targetValue: 1,
        rewardXp: 50,
        rewardGold: 10,
        color: Colors.green,
      ),
      Achievement(
        id: 'task_master_10',
        title: '任务新手',
        description: '累计完成10个任务',
        icon: '💪',
        type: AchievementType.taskCompletion,
        conditionType: ConditionType.taskCount,
        targetValue: 10,
        rewardXp: 100,
        rewardGold: 25,
        color: Colors.blue,
      ),
      Achievement(
        id: 'task_master_50',
        title: '任务能手',
        description: '累计完成50个任务',
        icon: '🏅',
        type: AchievementType.taskCompletion,
        conditionType: ConditionType.taskCount,
        targetValue: 50,
        rewardXp: 250,
        rewardGold: 50,
        color: Colors.orange,
      ),
      Achievement(
        id: 'task_master_100',
        title: '任务大师',
        description: '累计完成100个任务',
        icon: '👑',
        type: AchievementType.taskCompletion,
        conditionType: ConditionType.taskCount,
        targetValue: 100,
        rewardXp: 500,
        rewardGold: 100,
        color: Colors.purple,
      ),
      Achievement(
        id: 'exp_collector_1000',
        title: '经验收集者',
        description: '累计获得1000经验值',
        icon: '⭐',
        type: AchievementType.experience,
        conditionType: ConditionType.experienceGained,
        targetValue: 1000,
        rewardXp: 200,
        rewardGold: 50,
        color: Colors.amber,
      ),
      Achievement(
        id: 'gold_collector_500',
        title: '财富积累者',
        description: '累计获得500金币',
        icon: '💰',
        type: AchievementType.special,
        conditionType: ConditionType.goldEarned,
        targetValue: 500,
        rewardXp: 150,
        rewardGold: 75,
        color: Colors.yellow,
      ),
      Achievement(
        id: 'streak_3',
        title: '坚持不懈',
        description: '连续3天完成任务',
        icon: '🔥',
        type: AchievementType.streak,
        conditionType: ConditionType.streakDays,
        targetValue: 3,
        rewardXp: 100,
        rewardGold: 30,
        color: Colors.red,
      ),
      Achievement(
        id: 'streak_7',
        title: '一周挑战',
        description: '连续7天完成任务',
        icon: '🚀',
        type: AchievementType.streak,
        conditionType: ConditionType.streakDays,
        targetValue: 7,
        rewardXp: 300,
        rewardGold: 75,
        color: Colors.deepOrange,
      ),
      Achievement(
        id: 'hard_tasks_10',
        title: '挑战者',
        description: '完成10个高难度任务',
        icon: '⚡',
        type: AchievementType.difficulty,
        conditionType: ConditionType.difficultyTasks,
        targetValue: 10,
        rewardXp: 200,
        rewardGold: 40,
        color: Colors.red,
      ),
    ];

    for (final achievement in defaultAchievements) {
      await _taskService.addAchievement(achievement);
    }
  }

  // 添加自定义成就
  Future<void> addCustomAchievement(Achievement achievement) async {
    try {
      await _taskService.addAchievement(achievement);
      _achievements.add(achievement);
      notifyListeners();
    } catch (e) {
      print('Error adding custom achievement: $e');
      throw e;
    }
  }

  // 更新成就
  Future<void> updateAchievement(Achievement achievement) async {
    try {
      await _taskService.updateAchievement(achievement);
      final index = _achievements.indexWhere((a) => a.id == achievement.id);
      if (index != -1) {
        _achievements[index] = achievement;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating achievement: $e');
      throw e;
    }
  }

  // 删除成就
  Future<void> deleteAchievement(String id) async {
    try {
      await _taskService.deleteAchievement(id);
      _achievements.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting achievement: $e');
      throw e;
    }
  }

  // 检查并更新成就进度
  Future<void> checkAchievements({
    List<Task>? completedTasks,
    int? totalExperience,
    int? totalGold,
    int? currentStreak,
    Map<TaskDifficulty, int>? difficultyTaskCounts,
  }) async {
    bool hasUpdates = false;
    List<Achievement> newlyUnlocked = [];

    for (final achievement in _achievements) {
      if (achievement.isUnlocked) continue;

      int newValue = achievement.currentValue;

      switch (achievement.conditionType) {
        case ConditionType.taskCount:
          newValue = completedTasks?.length ?? 0;
          break;
        case ConditionType.experienceGained:
          newValue = totalExperience ?? 0;
          break;
        case ConditionType.goldEarned:
          newValue = totalGold ?? 0;
          break;
        case ConditionType.streakDays:
          newValue = currentStreak ?? 0;
          break;
        case ConditionType.difficultyTasks:
          if (difficultyTaskCounts != null && achievement.targetDifficulty != null) {
            newValue = difficultyTaskCounts[achievement.targetDifficulty!] ?? 0;
          }
          break;
        case ConditionType.professionLevel:
          // TODO: 实现职业等级检查
          break;
      }

      if (newValue != achievement.currentValue) {
        achievement.currentValue = newValue;
        hasUpdates = true;

        if (achievement.canUnlock) {
          achievement.isUnlocked = true;
          achievement.unlockedDate = DateTime.now();
          newlyUnlocked.add(achievement);
        }

        await _taskService.updateAchievement(achievement);
      }
    }

    if (hasUpdates) {
      notifyListeners();
    }

    // 显示新解锁的成就
    for (final achievement in newlyUnlocked) {
      await _showAchievementUnlockedDialog(achievement);
    }
  }

  // 显示成就解锁对话框
  Future<void> _showAchievementUnlockedDialog(Achievement achievement) async {
    // 这个方法需要在UI层实现，这里只是占位
    print('🎉 成就解锁: ${achievement.title}');
  }

  // 根据职业筛选成就
  List<Achievement> getAchievementsByProfession(String? professionId) {
    return _achievements.where((a) => a.professionId == professionId).toList();
  }

  // 获取成就统计
  Map<String, int> getAchievementStats() {
    final total = _achievements.length;
    final unlocked = unlockedAchievements.length;
    final custom = customAchievements.length;
    
    return {
      'total': total,
      'unlocked': unlocked,
      'locked': total - unlocked,
      'custom': custom,
      'completion_rate': total > 0 ? ((unlocked / total) * 100).round() : 0,
    };
  }

  // 获取最近解锁的成就
  List<Achievement> getRecentlyUnlocked({int limit = 5}) {
    final unlocked = unlockedAchievements
        .where((a) => a.unlockedDate != null)
        .toList();
    
    unlocked.sort((a, b) => b.unlockedDate!.compareTo(a.unlockedDate!));
    
    return unlocked.take(limit).toList();
  }
}