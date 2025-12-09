import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../models/task.dart';

class UltraSimpleTaskFormScreen extends StatefulWidget {
  @override
  _UltraSimpleTaskFormScreenState createState() =>
      _UltraSimpleTaskFormScreenState();
}

class _UltraSimpleTaskFormScreenState extends State<UltraSimpleTaskFormScreen> {
  String _title = '';
  String _description = '';
  String _xp = '10';
  String _gold = '5';
  DateTime _dueDate = DateTime.now().add(Duration(days: 1));
  String _selectedCategory = '默认';
  TaskRepeatType _selectedRepeatType = TaskRepeatType.special;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.medium;
  bool _isLoading = false;
  List<String> _professionNames = ['默认'];

  @override
  void initState() {
    super.initState();
    _loadProfessions();
  }

  void _loadProfessions() async {
    try {
      final professionProvider = Provider.of<ProfessionProvider>(
        context,
        listen: false,
      );
      await professionProvider.loadProfessions();

      if (mounted) {
        setState(() {
          if (professionProvider.professions.isNotEmpty) {
            _professionNames = professionProvider.professions
                .map((p) => p.name)
                .toList();
            _selectedCategory = _professionNames.first;
          }
        });
      }
    } catch (e) {
      print('Error loading professions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('添加任务'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 任务标题
              _buildInputSection(
                title: '任务标题',
                value: _title,
                hint: '请输入任务标题',
                onChanged: (value) => setState(() => _title = value),
              ),

              // 任务描述
              _buildInputSection(
                title: '任务描述',
                value: _description,
                hint: '请输入任务描述（可选）',
                onChanged: (value) => setState(() => _description = value),
                maxLines: 3,
              ),

              // 职业选择
              _buildSection(
                title: '选择职业',
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    onTap: _showProfessionPicker,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),

              // 任务类型选择
              _buildSection(
                title: '任务类型',
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    onTap: _showRepeatTypeDialog,
                    child: Row(
                      children: [
                        Icon(
                          _getRepeatTypeIcon(_selectedRepeatType),
                          color: _getRepeatTypeColor(_selectedRepeatType),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedRepeatType.displayName,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),

              // 任务难度选择
              _buildSection(
                title: '任务难度',
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    onTap: _showDifficultyDialog,
                    child: Row(
                      children: [
                        Icon(
                          _getDifficultyIcon(_selectedDifficulty),
                          color: _selectedDifficulty.color,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDifficulty.displayName,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),

              // 截止日期
              _buildSection(
                title: '截止日期',
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatDate(_dueDate),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 奖励设置
              _buildSection(
                title: '任务奖励',
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInputSection(
                        title: '经验值',
                        value: _xp,
                        hint: '10',
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() => _xp = value),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildInputSection(
                        title: '金币',
                        value: _gold,
                        hint: '5',
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setState(() => _gold = value),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // 保存按钮
              GestureDetector(
                onTap: _isLoading ? null : _saveTask,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            '保存任务',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required String value,
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextFormField(
              initialValue: value,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
              maxLines: maxLines,
              keyboardType: keyboardType,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfessionPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择职业'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _professionNames.length,
              itemBuilder: (context, index) {
                final profession = _professionNames[index];
                return ListTile(
                  title: Text(profession),
                  trailing: _selectedCategory == profession
                      ? Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCategory = profession;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _dueDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (picked != null && mounted) {
        setState(() {
          _dueDate = picked;
        });
      }
    } catch (e) {
      print('Error selecting date: $e');
    }
  }

  Future<void> _saveTask() async {
    // 基本验证
    if (_title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请输入任务标题'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title.trim(),
        description: _description.trim(),
        dueDate: _dueDate,
        category: _selectedCategory,
        xp: int.tryParse(_xp) ?? 10,
        gold: int.tryParse(_gold) ?? 5,
        repeatType: _selectedRepeatType,
        difficulty: _selectedDifficulty,
      );

      await taskProvider.addTask(newTask);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('任务 "${newTask.title}" 添加成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 显示难度选择对话框
  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择任务难度'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TaskDifficulty.values.length,
              itemBuilder: (context, index) {
                final difficulty = TaskDifficulty.values[index];
                return ListTile(
                  leading: Icon(
                    _getDifficultyIcon(difficulty),
                    color: difficulty.color,
                  ),
                  title: Text(difficulty.displayName),
                  subtitle: Text(_getDifficultyDescription(difficulty)),
                  trailing: _selectedDifficulty == difficulty
                      ? Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
          ],
        );
      },
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

  // 获取难度的描述
  String _getDifficultyDescription(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.low:
        return '简单任务，轻松完成';
      case TaskDifficulty.medium:
        return '中等难度，需要一定努力';
      case TaskDifficulty.high:
        return '困难任务，需要全力以赴';
    }
  }

  // 显示重复类型选择对话框
  void _showRepeatTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择任务类型'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TaskRepeatType.values.length,
              itemBuilder: (context, index) {
                final type = TaskRepeatType.values[index];
                return ListTile(
                  leading: Icon(
                    _getRepeatTypeIcon(type),
                    color: _getRepeatTypeColor(type),
                  ),
                  title: Text(type.displayName),
                  subtitle: Text(_getRepeatTypeDescription(type)),
                  trailing: _selectedRepeatType == type
                      ? Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedRepeatType = type;
                      // 根据任务类型设置合适的截止日期
                      _updateDueDateForRepeatType(type);
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 获取重复类型对应的图标
  IconData _getRepeatTypeIcon(TaskRepeatType type) {
    switch (type) {
      case TaskRepeatType.daily:
        return Icons.today;
      case TaskRepeatType.weekly:
        return Icons.date_range;
      case TaskRepeatType.monthly:
        return Icons.calendar_month;
      case TaskRepeatType.special:
        return Icons.star;
    }
  }

  // 获取重复类型对应的颜色
  Color _getRepeatTypeColor(TaskRepeatType type) {
    switch (type) {
      case TaskRepeatType.daily:
        return Colors.orange;
      case TaskRepeatType.weekly:
        return Colors.blue;
      case TaskRepeatType.monthly:
        return Colors.indigo;
      case TaskRepeatType.special:
        return Colors.purple;
    }
  }

  // 获取重复类型的描述
  String _getRepeatTypeDescription(TaskRepeatType type) {
    switch (type) {
      case TaskRepeatType.daily:
        return '每天重复，需要当天完成';
      case TaskRepeatType.weekly:
        return '每周重复，需要本周内完成';
      case TaskRepeatType.monthly:
        return '每月重复，需要当月内完成';
      case TaskRepeatType.special:
        return '一次性任务，无重复要求';
    }
  }

  // 根据重复类型更新截止日期
  void _updateDueDateForRepeatType(TaskRepeatType type) {
    final now = DateTime.now();
    switch (type) {
      case TaskRepeatType.daily:
        // 每日任务设置为今天结束
        _dueDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case TaskRepeatType.weekly:
        // 每周任务设置为本周日结束
        final daysUntilSunday = 7 - now.weekday;
        final nextSunday = now.add(Duration(days: daysUntilSunday));
        _dueDate = DateTime(
          nextSunday.year,
          nextSunday.month,
          nextSunday.day,
          23,
          59,
          59,
        );
        break;
      case TaskRepeatType.monthly:
        // 每月任务设置为本月最后一天结束
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        _dueDate = DateTime(
          endOfMonth.year,
          endOfMonth.month,
          endOfMonth.day,
          23,
          59,
          59,
        );
        break;
      case TaskRepeatType.special:
        // 特殊任务保持用户选择的日期，或默认明天
        if (_dueDate.isBefore(now)) {
          _dueDate = now.add(Duration(days: 1));
        }
        break;
    }
  }
}
