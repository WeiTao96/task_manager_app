import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../models/task.dart';

class SimpleTaskFormScreen extends StatefulWidget {
  static const routeName = '/simple_add_task';
  
  @override
  _SimpleTaskFormScreenState createState() => _SimpleTaskFormScreenState();
}

class _SimpleTaskFormScreenState extends State<SimpleTaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _xpController = TextEditingController(text: '10');
  final _goldController = TextEditingController(text: '5');
  
  DateTime _dueDate = DateTime.now().add(Duration(days: 1));
  String _selectedCategory = '';
  bool _hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
    // 简化初始化，立即设置一个默认值
    _selectedCategory = '默认';
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 只在第一次构建时初始化表单
    if (!_hasInitialized) {
      _hasInitialized = true;
      _loadProfessionsAsync();
    }
  }
  
  void _loadProfessionsAsync() {
    // 异步加载职业，不影响初始UI显示
    Future.microtask(() async {
      try {
        final professionProvider = Provider.of<ProfessionProvider>(context, listen: false);
        if (professionProvider.professions.isEmpty && !professionProvider.isLoading) {
          await professionProvider.loadProfessions();
          
          // 加载完成后更新默认选择
          if (mounted && professionProvider.professions.isNotEmpty) {
            setState(() {
              _selectedCategory = professionProvider.professions.first.name;
            });
          }
        }
      } catch (e) {
        print('Error loading professions: $e');
      }
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _xpController.dispose();
    _goldController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('添加任务'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 标题输入
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '任务标题',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入任务标题';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // 描述输入
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '任务描述（可选）',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              
              // 截止日期
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('截止日期'),
                subtitle: Text(
                  '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: _selectDate,
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 16),
              
              // 职业选择
              Consumer<ProfessionProvider>(
                builder: (context, professionProvider, child) {
                  // 如果正在加载，显示加载指示器
                  if (professionProvider.isLoading) {
                    return Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 16),
                            Text('正在加载职业列表...'),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final professions = professionProvider.professions;
                  
                  // 如果没有职业，显示创建职业提示
                  if (professions.isEmpty) {
                    return Card(
                      elevation: 2,
                      color: Colors.orange[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 40,
                              color: Colors.orange[700],
                            ),
                            SizedBox(height: 12),
                            Text(
                              '需要先创建职业',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '职业帮助您追踪成长进度',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/add_profession').then((_) {
                                  professionProvider.loadProfessions();
                                  _loadProfessionsAsync();
                                });
                              },
                              icon: Icon(Icons.add, size: 18),
                              label: Text('创建职业'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // 有职业时，显示职业选择器
                  // 确保选择的职业在列表中存在
                  String? currentValue = _selectedCategory;
                  if (currentValue.isEmpty || !professions.any((prof) => prof.name == currentValue)) {
                    currentValue = professions.first.name;
                    // 异步更新选择的分类
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedCategory = currentValue!;
                        });
                      }
                    });
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: currentValue,
                    decoration: InputDecoration(
                      labelText: '选择职业',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: professions.map((profession) {
                      return DropdownMenuItem<String>(
                        value: profession.name,
                        child: Row(
                          children: [
                            Text(profession.icon, style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Expanded(child: Text(profession.name)),
                            Text(
                              'Lv.${profession.level}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  );
                },
              ),
              SizedBox(height: 16),
              
              // XP 和 Gold 输入（水平布局）
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _xpController,
                      decoration: InputDecoration(
                        labelText: '经验值 (XP)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star, color: Colors.blue),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入经验值';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 0) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _goldController,
                      decoration: InputDecoration(
                        labelText: '金币 (Gold)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入金币数';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 0) {
                          return '请输入有效的数字';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  child: Text(
                    '添加任务',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }
  
  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 检查是否选择了职业
    final professionProvider = Provider.of<ProfessionProvider>(context, listen: false);
    if (professionProvider.professions.isEmpty || _selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先创建并选择一个职业'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }
    
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final xp = int.tryParse(_xpController.text) ?? 10;
      final gold = int.tryParse(_goldController.text) ?? 5;
      
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        category: _selectedCategory,
        xp: xp,
        gold: gold,
      );
      
      await taskProvider.addTask(newTask);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('任务添加成功！'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      print('Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存任务失败：${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}