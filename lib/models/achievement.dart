import 'package:flutter/material.dart';
import 'task.dart';

// 成就类型枚举
enum AchievementType {
  taskCompletion('任务完成类'),
  experience('经验类'),
  streak('连续完成类'),
  profession('职业类'),
  difficulty('难度挑战类'),
  special('特殊成就');

  const AchievementType(this.displayName);
  final String displayName;
}

// 成就条件类型枚举
enum ConditionType {
  taskCount('完成任务数量'),
  experienceGained('获得经验'),
  streakDays('连续天数'),
  professionLevel('职业等级'),
  difficultyTasks('完成指定难度任务'),
  specificTask('完成特定任务'),
  goldEarned('获得金币');

  const ConditionType(this.displayName);
  final String displayName;
}

class Achievement {
  final String id;
  String title;
  String description;
  String icon;
  AchievementType type;
  String? professionId; // 关联的职业ID，为null表示全局成就
  String? professionName; // 职业名称，用于显示
  ConditionType conditionType;
  int targetValue; // 目标值
  TaskDifficulty? targetDifficulty; // 目标难度（仅对difficultyTasks条件有效）
  String? targetTaskId; // 目标任务ID（仅对specificTask条件有效）
  String? targetTaskTitle; // 目标任务标题（用于显示）
  int currentValue; // 当前进度
  bool isUnlocked; // 是否已解锁
  DateTime? unlockedDate; // 解锁时间
  int rewardXp; // 奖励经验
  int rewardGold; // 奖励金币
  Color color; // 成就颜色
  bool isCustom; // 是否为自定义成就

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.icon = '🏆',
    required this.type,
    this.professionId,
    this.professionName,
    required this.conditionType,
    required this.targetValue,
    this.targetDifficulty,
    this.targetTaskId,
    this.targetTaskTitle,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedDate,
    this.rewardXp = 0,
    this.rewardGold = 0,
    this.color = Colors.amber,
    this.isCustom = false,
  });

  // 计算完成进度百分比
  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  // 是否可以解锁
  bool get canUnlock => !isUnlocked && currentValue >= targetValue;

  // 转换为Map，用于持久化存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.name,
      'professionId': professionId,
      'professionName': professionName,
      'conditionType': conditionType.name,
      'targetValue': targetValue,
      'targetDifficulty': targetDifficulty?.name,
      'targetTaskId': targetTaskId,
      'targetTaskTitle': targetTaskTitle,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockedDate': unlockedDate?.toIso8601String(),
      'rewardXp': rewardXp,
      'rewardGold': rewardGold,
      'color': color.value.toRadixString(16).substring(2),
      'isCustom': isCustom ? 1 : 0,
    };
  }

  // 从Map创建Achievement对象
  factory Achievement.fromMap(Map<String, dynamic> map) {
    // 解析成就类型
    AchievementType type = AchievementType.special;
    try {
      type = AchievementType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => AchievementType.special,
      );
    } catch (e) {
      type = AchievementType.special;
    }

    // 解析条件类型
    ConditionType conditionType = ConditionType.taskCount;
    try {
      conditionType = ConditionType.values.firstWhere(
        (t) => t.name == map['conditionType'],
        orElse: () => ConditionType.taskCount,
      );
    } catch (e) {
      conditionType = ConditionType.taskCount;
    }

    // 解析目标难度
    TaskDifficulty? targetDifficulty;
    if (map.containsKey('targetDifficulty') && map['targetDifficulty'] != null) {
      try {
        targetDifficulty = TaskDifficulty.values.firstWhere(
          (d) => d.name == map['targetDifficulty'],
        );
      } catch (e) {
        targetDifficulty = null;
      }
    }

    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'] ?? '🏆',
      type: type,
      professionId: map['professionId'],
      professionName: map['professionName'],
      conditionType: conditionType,
      targetValue: map['targetValue'],
      targetDifficulty: targetDifficulty,
      targetTaskId: map['targetTaskId'],
      targetTaskTitle: map['targetTaskTitle'],
      currentValue: map['currentValue'] ?? 0,
      isUnlocked: map['isUnlocked'] == 1,
      unlockedDate: map['unlockedDate'] != null 
        ? DateTime.parse(map['unlockedDate']) 
        : null,
      rewardXp: map['rewardXp'] ?? 0,
      rewardGold: map['rewardGold'] ?? 0,
      color: Color(int.parse('ff${map['color'] ?? 'FFC107'}', radix: 16)),
      isCustom: map['isCustom'] == 1,
    );
  }

    // 创建副本
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    String? professionId,
    String? professionName,
    ConditionType? conditionType,
    int? targetValue,
    TaskDifficulty? targetDifficulty,
    String? targetTaskId,
    String? targetTaskTitle,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedDate,
    int? rewardXp,
    int? rewardGold,
    Color? color,
    bool? isCustom,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      professionId: professionId ?? this.professionId,
      professionName: professionName ?? this.professionName,
      conditionType: conditionType ?? this.conditionType,
      targetValue: targetValue ?? this.targetValue,
      targetDifficulty: targetDifficulty ?? this.targetDifficulty,
      targetTaskId: targetTaskId ?? this.targetTaskId,
      targetTaskTitle: targetTaskTitle ?? this.targetTaskTitle,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      rewardXp: rewardXp ?? this.rewardXp,
      rewardGold: rewardGold ?? this.rewardGold,
      color: color ?? this.color,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}