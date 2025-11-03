class Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  DateTime dueDate;
  String category;
  int xp; // 经验值
  int gold; // 金币
  String? professionId; // 关联的职业ID

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.dueDate,
    required this.category,
    this.xp = 0,
    this.gold = 0,
    this.professionId,
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
      'professionId': professionId,
    };
  }

  // 从Map创建Task对象
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      dueDate: DateTime.parse(map['dueDate']),
      category: map['category'],
      xp: map.containsKey('xp') && map['xp'] != null ? (map['xp'] as int) : 0,
      gold: map.containsKey('gold') && map['gold'] != null ? (map['gold'] as int) : 0,
      professionId: map['professionId'],
    );
  }
}
