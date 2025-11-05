import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/profession_provider.dart';
import '../models/achievement.dart';
import '../models/task.dart';
import '../widgets/achievement_card.dart';

class AchievementManagementScreen extends StatefulWidget {
  static const routeName = '/achievement-management';

  @override
  _AchievementManagementScreenState createState() => _AchievementManagementScreenState();
}

class _AchievementManagementScreenState extends State<AchievementManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('成就管理'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddAchievementDialog,
            tooltip: '添加自定义成就',
          ),
        ],
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, achievementProvider, child) {
          final achievements = achievementProvider.achievements;
          
          if (achievements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    '暂无成就',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _showAddAchievementDialog,
                    child: Text('添加第一个成就'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return AchievementCard(
                achievement: achievement,
                onTap: () => _showAchievementDetails(achievement),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddAchievementDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddAchievementScreen(),
      ),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(achievement.icon),
            SizedBox(width: 8),
            Expanded(child: Text(achievement.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            SizedBox(height: 16),
            Text('类型: ${achievement.type.displayName}'),
            Text('条件: ${achievement.conditionType.displayName}'),
            Text('目标: ${achievement.targetValue}'),
            if (!achievement.isUnlocked)
              Text('当前进度: ${achievement.currentValue}'),
            if (achievement.professionName != null)
              Text('关联职业: ${achievement.professionName}'),
          ],
        ),
        actions: [
          if (achievement.isCustom)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAchievement(achievement);
              },
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _deleteAchievement(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除成就'),
        content: Text('确定要删除成就"${achievement.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<AchievementProvider>(context, listen: false)
                    .deleteAchievement(achievement.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('成就删除成功')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class AddAchievementScreen extends StatefulWidget {
  @override
  _AddAchievementScreenState createState() => _AddAchievementScreenState();
}

class _AddAchievementScreenState extends State<AddAchievementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _icon = '🏆';
  AchievementType _type = AchievementType.special;
  ConditionType _conditionType = ConditionType.taskCount;
  TaskDifficulty _targetDifficulty = TaskDifficulty.medium; // 新增难度选择
  int _targetValue = 1;
  int _rewardXp = 50;
  int _rewardGold = 10;
  Color _color = Colors.amber;
  String? _selectedProfessionId;
  String? _selectedProfessionName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('添加成就'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 基本信息
              _buildSection(
                title: '基本信息',
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: '成就标题'),
                    validator: (value) => value?.isEmpty == true ? '请输入成就标题' : null,
                    onSaved: (value) => _title = value ?? '',
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: '成就描述'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty == true ? '请输入成就描述' : null,
                    onSaved: (value) => _description = value ?? '',
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: '图标 (Emoji)'),
                    initialValue: _icon,
                    onSaved: (value) => _icon = value ?? '🏆',
                  ),
                ],
              ),

              // 成就类型
              _buildSection(
                title: '成就类型',
                children: [
                  DropdownButtonFormField<AchievementType>(
                    value: _type,
                    decoration: InputDecoration(labelText: '成就类型'),
                    items: AchievementType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                ],
              ),

              // 完成条件
              _buildSection(
                title: '完成条件',
                children: [
                  DropdownButtonFormField<ConditionType>(
                    value: _conditionType,
                    decoration: InputDecoration(labelText: '条件类型'),
                    items: ConditionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _conditionType = value!),
                  ),
                  SizedBox(height: 16),
                  
                  // 当条件类型是"完成指定难度任务"时，显示难度选择器
                  if (_conditionType == ConditionType.difficultyTasks) ...[
                    DropdownButtonFormField<TaskDifficulty>(
                      value: _targetDifficulty,
                      decoration: InputDecoration(
                        labelText: '目标任务难度',
                        helperText: '选择需要完成的任务难度',
                      ),
                      items: TaskDifficulty.values.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Row(
                            children: [
                              Icon(
                                _getDifficultyIcon(difficulty),
                                color: difficulty.color,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(difficulty.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _targetDifficulty = value!),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _getTargetValueLabel(),
                      helperText: _getTargetValueHelper(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _targetValue.toString(),
                    validator: (value) {
                      if (value?.isEmpty == true) return '请输入目标数值';
                      if (int.tryParse(value!) == null) return '请输入有效数字';
                      if (int.parse(value) <= 0) return '目标数值必须大于0';
                      return null;
                    },
                    onSaved: (value) => _targetValue = int.parse(value!),
                  ),
                ],
              ),

              // 职业关联
              Consumer<ProfessionProvider>(
                builder: (context, professionProvider, child) {
                  return _buildSection(
                    title: '职业关联',
                    children: [
                      DropdownButtonFormField<String?>(
                        value: _selectedProfessionId,
                        decoration: InputDecoration(labelText: '关联职业（可选）'),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('无关联（全局成就）'),
                          ),
                          ...professionProvider.professions.map((profession) {
                            return DropdownMenuItem<String?>(
                              value: profession.id,
                              child: Text('${profession.icon} ${profession.name}'),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProfessionId = value;
                            _selectedProfessionName = value != null
                                ? professionProvider.professions
                                    .firstWhere((p) => p.id == value)
                                    .name
                                : null;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),

              // 奖励设置
              _buildSection(
                title: '奖励设置',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '经验奖励'),
                          keyboardType: TextInputType.number,
                          initialValue: _rewardXp.toString(),
                          validator: (value) {
                            if (value?.isEmpty == true) return '请输入经验奖励';
                            if (int.tryParse(value!) == null) return '请输入有效数字';
                            return null;
                          },
                          onSaved: (value) => _rewardXp = int.parse(value!),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(labelText: '金币奖励'),
                          keyboardType: TextInputType.number,
                          initialValue: _rewardGold.toString(),
                          validator: (value) {
                            if (value?.isEmpty == true) return '请输入金币奖励';
                            if (int.tryParse(value!) == null) return '请输入有效数字';
                            return null;
                          },
                          onSaved: (value) => _rewardGold = int.parse(value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 颜色选择
              _buildSection(
                title: '成就颜色',
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Colors.amber,
                      Colors.blue,
                      Colors.green,
                      Colors.red,
                      Colors.purple,
                      Colors.orange,
                      Colors.pink,
                      Colors.teal,
                    ].map((color) {
                      return GestureDetector(
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: _color == color
                                ? Border.all(color: Colors.black, width: 3)
                                : Border.all(color: Colors.grey, width: 1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAchievement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '创建成就',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // 获取难度对应的图标
  IconData _getDifficultyIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.low:
        return Icons.keyboard_arrow_down;
      case TaskDifficulty.medium:
        return Icons.remove;
      case TaskDifficulty.high:
        return Icons.keyboard_arrow_up;
    }
  }

  // 根据条件类型获取目标数值标签
  String _getTargetValueLabel() {
    switch (_conditionType) {
      case ConditionType.taskCount:
        return '目标任务数量';
      case ConditionType.experienceGained:
        return '目标经验值';
      case ConditionType.goldEarned:
        return '目标金币数量';
      case ConditionType.streakDays:
        return '连续天数';
      case ConditionType.difficultyTasks:
        return '目标任务数量';
      case ConditionType.professionLevel:
        return '目标职业等级';
    }
  }

  // 根据条件类型获取目标数值帮助文本
  String _getTargetValueHelper() {
    switch (_conditionType) {
      case ConditionType.taskCount:
        return '需要完成的任务总数';
      case ConditionType.experienceGained:
        return '需要获得的经验值总数';
      case ConditionType.goldEarned:
        return '需要获得的金币总数';
      case ConditionType.streakDays:
        return '需要连续完成任务的天数';
      case ConditionType.difficultyTasks:
        return '需要完成的${_targetDifficulty.displayName}难度任务数量';
      case ConditionType.professionLevel:
        return '职业需要达到的等级';
    }
  }

  void _saveAchievement() async {
    if (_formKey.currentState?.validate() != true) return;

    _formKey.currentState?.save();

    final achievement = Achievement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title,
      description: _description,
      icon: _icon,
      type: _type,
      conditionType: _conditionType,
      targetValue: _targetValue,
      targetDifficulty: _conditionType == ConditionType.difficultyTasks ? _targetDifficulty : null,
      rewardXp: _rewardXp,
      rewardGold: _rewardGold,
      color: _color,
      isCustom: true,
      professionId: _selectedProfessionId,
      professionName: _selectedProfessionName,
    );

    try {
      await Provider.of<AchievementProvider>(context, listen: false)
          .addCustomAchievement(achievement);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成就"${achievement.title}"创建成功！')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e')),
      );
    }
  }
}