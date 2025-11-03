class Profession {
  final String id;
  String name;
  String description;
  String icon; // 图标名称或emoji
  String color; // 颜色代码
  int level;
  int experience;

  Profession({
    required this.id,
    required this.name,
    required this.description,
    this.icon = '💼',
    this.color = 'blue',
    this.level = 1,
    this.experience = 0,
  });

  // 计算当前等级所需的总经验
  int get requiredExpForCurrentLevel {
    return (level * 100 * 1.2).round();
  }

  // 计算下一等级所需的经验
  int get expToNextLevel {
    final nextLevelExp = ((level + 1) * 100 * 1.2).round();
    return nextLevelExp - experience;
  }

  // 计算当前等级的进度百分比
  double get levelProgress {
    if (level == 1) return experience / requiredExpForCurrentLevel;
    
    final currentLevelStart = ((level - 1) * 100 * 1.2).round();
    final currentLevelEnd = requiredExpForCurrentLevel;
    final progressInLevel = experience - currentLevelStart;
    final levelRange = currentLevelEnd - currentLevelStart;
    
    return levelRange > 0 ? (progressInLevel / levelRange).clamp(0.0, 1.0) : 0.0;
  }

  // 根据经验值更新等级
  void updateLevel() {
    try {
      int newLevel = 1;
      int totalExp = 0;
      
      while (totalExp <= experience) {
        int levelExp = (newLevel * 100 * 1.2).round();
        if (totalExp + levelExp > experience) break;
        totalExp += levelExp;
        newLevel++;
      }
      
      level = newLevel;
    } catch (e) {
      print('Error updating level: $e');
      level = 1; // 如果出错，设置为1级
    }
  }

  // 添加经验值
  void addExperience(int exp) {
    try {
      if (exp < 0) return; // 防止添加负经验值
      experience += exp;
      updateLevel();
    } catch (e) {
      print('Error adding experience: $e');
    }
  }

  // 转换为Map，用于持久化存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'level': level,
      'experience': experience,
    };
  }

  // 从Map创建Profession对象
  factory Profession.fromMap(Map<String, dynamic> map) {
    try {
      return Profession(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        icon: map['icon']?.toString() ?? '💼',
        color: map['color']?.toString() ?? 'blue',
        level: map['level'] != null ? (map['level'] as int) : 1,
        experience: map['experience'] != null ? (map['experience'] as int) : 0,
      );
    } catch (e) {
      print('Error creating Profession from map: $e');
      print('Map data: $map');
      // 返回一个默认的Profession对象，避免崩溃
      return Profession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '错误职业',
        description: '数据解析错误',
        icon: '💼',
        color: 'blue',
      );
    }
  }

  // 预定义职业模板
  static List<Map<String, String>> get templates => [
    {
      'name': '程序员',
      'description': '编程技能与技术成长',
      'icon': '💻',
      'color': 'blue',
    },
    {
      'name': '设计师',
      'description': '设计能力与创意思维',
      'icon': '🎨',
      'color': 'purple',
    },
    {
      'name': '健身达人',
      'description': '体能训练与健康管理',
      'icon': '💪',
      'color': 'red',
    },
    {
      'name': '学者',
      'description': '知识学习与研究能力',
      'icon': '📚',
      'color': 'green',
    },
    {
      'name': '企业家',
      'description': '商业思维与管理能力',
      'icon': '💼',
      'color': 'orange',
    },
    {
      'name': '艺术家',
      'description': '艺术创作与表达能力',
      'icon': '🎭',
      'color': 'pink',
    },
  ];
}