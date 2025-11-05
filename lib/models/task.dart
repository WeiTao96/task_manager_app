import 'package:flutter/material.dart';

// 任务重复类型枚举
enum TaskRepeatType {
  special('特殊任务'),
  daily('每日任务'), 
  weekly('每周任务');

  const TaskRepeatType(this.displayName);
  final String displayName;
}

// 任务难度枚举
enum TaskDifficulty {
  low('低'),
  medium('中'),
  high('高');

  const TaskDifficulty(this.displayName);
  final String displayName;
  
  // 获取难度对应的颜色
  Color get color {
    switch (this) {
      case TaskDifficulty.low:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.high:
        return Colors.red;
    }
  }
}

class Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  DateTime dueDate;
  String category; // 现在直接使用职业名称作为分类
  int xp; // 经验值
  int gold; // 金币
  TaskRepeatType repeatType; // 任务重复类型
  TaskDifficulty difficulty; // 任务难度
  DateTime? lastCompletedDate; // 上次完成日期
  String? originalTaskId; // 原始任务ID（用于重复任务）

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.dueDate,
    required this.category,
    this.xp = 0,
    this.gold = 0,
    this.repeatType = TaskRepeatType.special,
    this.difficulty = TaskDifficulty.medium,
    this.lastCompletedDate,
    this.originalTaskId,
  });

  // 转换为Map，用于持久化存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'xp': xp,
      'gold': gold,
      'repeatType': repeatType.name,
      'difficulty': difficulty.name,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'originalTaskId': originalTaskId,
    };
  }

    // 从Map创建Task对象
  factory Task.fromMap(Map<String, dynamic> map) {
    // 解析重复类型
    TaskRepeatType repeatType = TaskRepeatType.special;
    if (map.containsKey('repeatType') && map['repeatType'] != null) {
      try {
        repeatType = TaskRepeatType.values.firstWhere(
          (type) => type.name == map['repeatType'],
          orElse: () => TaskRepeatType.special,
        );
      } catch (e) {
        repeatType = TaskRepeatType.special;
      }
    }

    // 解析难度
    TaskDifficulty difficulty = TaskDifficulty.medium;
    if (map.containsKey('difficulty') && map['difficulty'] != null) {
      try {
        difficulty = TaskDifficulty.values.firstWhere(
          (diff) => diff.name == map['difficulty'],
          orElse: () => TaskDifficulty.medium,
        );
      } catch (e) {
        difficulty = TaskDifficulty.medium;
      }
    }

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      dueDate: DateTime.parse(map['dueDate']),
      category: map['category'],
      xp: map.containsKey('xp') && map['xp'] != null ? (map['xp'] as int) : 0,
      gold: map.containsKey('gold') && map['gold'] != null ? (map['gold'] as int) : 0,
      repeatType: repeatType,
      difficulty: difficulty,
      lastCompletedDate: map['lastCompletedDate'] != null 
        ? DateTime.parse(map['lastCompletedDate']) 
        : null,
      originalTaskId: map['originalTaskId'],
    );
  }
}
