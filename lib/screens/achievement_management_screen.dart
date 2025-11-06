import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/profession_provider.dart';
import '../providers/task_provider.dart';
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
  String? _selectedTaskId; // 新增：选中的任务ID
  String? _selectedTaskTitle; // 新增：选中的任务标题
  int _targetValue = 1;
  int _rewardXp = 50;
  int _rewardGold = 10;
  Color _color = Colors.amber;
  String? _selectedProfessionId;
  String? _selectedProfessionName;

  @override
  void initState() {
    super.initState();
    // 确保任务列表已加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.loadTasks();
    });
  }

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
                    onChanged: (value) => setState(() {
                      _conditionType = value!;
                      // 切换条件类型时清空相关选择
                      if (_conditionType != ConditionType.specificTask) {
                        _selectedTaskId = null;
                        _selectedTaskTitle = null;
                      }
                      if (_conditionType != ConditionType.difficultyTasks) {
                        _targetDifficulty = TaskDifficulty.medium;
                      }
                    }),
                  ),
                  SizedBox(height: 16),
                  
                  // 难度选择器
                  _buildDifficultySelector(),
                  
                  // 任务选择器  
                  _buildTaskSelector(),
                  
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: _getTargetValueLabel(),
                      helperText: _getTargetValueHelper(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _targetValue.toString(),
                    enabled: _conditionType != ConditionType.specificTask, // 特定任务时禁用编辑
                    validator: (value) {
                      if (_conditionType == ConditionType.specificTask) return null; // 特定任务不需要验证目标值
                      if (value?.isEmpty == true) return '请输入目标数值';
                      if (int.tryParse(value!) == null) return '请输入有效数字';
                      if (int.parse(value) <= 0) return '目标数值必须大于0';
                      return null;
                    },
                    onSaved: (value) => _targetValue = _conditionType == ConditionType.specificTask ? 1 : int.parse(value!),
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
  
  // 构建难度选择器
  Widget _buildDifficultySelector() {
    if (_conditionType != ConditionType.difficultyTasks) {
      return SizedBox.shrink(); // 不显示时返回空组件
    }
    
    return Column(
      children: [
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
    );
  }
  
  // 构建任务选择器
  Widget _buildTaskSelector() {
    if (_conditionType != ConditionType.specificTask) {
      return SizedBox.shrink(); // 不显示时返回空组件
    }
    
    return Column(
      children: [
        Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            final allTasks = taskProvider.tasks;
            // 过滤掉已完成的任务，只显示未完成的任务
            final availableTasks = allTasks.where((task) => !task.isCompleted).toList();
            
            // 如果任务列表为空，显示提示
            if (availableTasks.isEmpty) {
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
                      SizedBox(height: 8),
                      Text(
                        allTasks.isEmpty ? '暂无可用任务' : '暂无未完成的任务',
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        allTasks.isEmpty ? '请先创建一些任务' : '所有任务都已完成，请创建新任务或重置已完成的任务',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择目标任务',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedTaskId,
                      hint: Text('请选择任务', style: TextStyle(color: Colors.grey)),
                      isExpanded: true,
                      items: availableTasks.map((task) {
                        return DropdownMenuItem<String?>(
                          value: task.id,
                          child: Row(
                            children: [
                              Icon(
                                _getDifficultyIcon(task.difficulty),
                                color: task.difficulty.color,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTaskId = value;
                          if (value != null && availableTasks.isNotEmpty) {
                            try {
                              final selectedTask = availableTasks.firstWhere((t) => t.id == value);
                              _selectedTaskTitle = selectedTask.title;
                              _targetValue = 1; // 特定任务的目标值固定为1
                            } catch (e) {
                              print('找不到任务: $value');
                              _selectedTaskTitle = null;
                            }
                          } else {
                            _selectedTaskTitle = null;
                          }
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '选择需要完成的特定任务',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    );
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
      case ConditionType.specificTask:
        return '任务完成状态';
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
      case ConditionType.specificTask:
        return '完成指定的任务（自动设为1）';
      case ConditionType.professionLevel:
        return '职业需要达到的等级';
    }
  }

  void _saveAchievement() async {
    if (_formKey.currentState?.validate() != true) return;

    // 额外验证：特定任务条件必须选择任务
    if (_conditionType == ConditionType.specificTask && _selectedTaskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请选择目标任务'), backgroundColor: Colors.red),
      );
      return;
    }

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
      targetTaskId: _conditionType == ConditionType.specificTask ? _selectedTaskId : null,
      targetTaskTitle: _conditionType == ConditionType.specificTask ? _selectedTaskTitle : null,
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