import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../models/task.dart';

class TaskFormScreen extends StatefulWidget {
  static const routeName = '/add_task';
  static const editRouteName = '/edit_task';
  
  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _xpController = TextEditingController(text: '10');
  final _goldController = TextEditingController(text: '5');
  
  DateTime _dueDate = DateTime.now().add(Duration(days: 1));
  String _selectedCategory = ''; // 将用作职业名称
  
  Task? _editingTask;
  bool _isLoading = true;
  bool _hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _isLoading = false; // 默认不显示加载指示器
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 只在第一次构建时初始化表单
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeForm();
    }
  }
  
  void _initializeForm() {
    try {
      // 检查是否是编辑模式
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Task) {
        _editingTask = args;
        _titleController.text = args.title;
        _descriptionController.text = args.description;
        _dueDate = args.dueDate;
        _selectedCategory = args.category;
        _xpController.text = args.xp.toString();
        _goldController.text = args.gold.toString();
      }
      
      // 异步加载职业列表（非阻塞）
      _loadProfessionsIfNeeded();
    } catch (e) {
      print('Error initializing form: $e');
    }
  }
  
  void _loadProfessionsIfNeeded() {
    try {
      final professionProvider = Provider.of<ProfessionProvider>(context, listen: false);
      if (professionProvider.professions.isEmpty) {
        // 异步加载，不阻塞UI
        Future.microtask(() => professionProvider.loadProfessions());
      }
    } catch (e) {
      print('Error loading professions: $e');
    }
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
        title: Text(_editingTask == null ? '添加任务' : '编辑任务'),
        actions: [
          if (_editingTask != null) ...[
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteTask,
            ),
          ],
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
              ),
              SizedBox(height: 16),
              
              // 职业选择（职业优先）
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
                            CircularProgressIndicator(strokeWidth: 2),
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
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              '还没有职业',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '职业帮助您更好地组织任务和追踪成长进度',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/add_profession').then((_) {
                                  professionProvider.loadProfessions();
                                });
                              },
                              icon: Icon(Icons.add),
                              label: Text('创建第一个职业'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  // 有职业时，显示职业选择器
                  // 如果当前选中的不在职业列表中，默认选择第一个职业
                  if (_selectedCategory.isEmpty || !professions.any((prof) => prof.name == _selectedCategory)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedCategory = professions.first.name;
                      });
                    });
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategory.isEmpty ? null : _selectedCategory,
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
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/add_profession').then((_) {
                                professionProvider.loadProfessions();
                              });
                            },
                            icon: Icon(Icons.add, size: 16),
                            label: Text('创建职业'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/professions');
                            },
                            icon: Icon(Icons.manage_accounts, size: 16),
                            label: Text('管理职业'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              textStyle: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    _editingTask == null ? '添加任务' : '更新任务',
                    style: TextStyle(fontSize: 16),
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
        SnackBar(content: Text('请先创建并选择一个职业')),
      );
      return;
    }
    
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final xp = int.tryParse(_xpController.text) ?? 0;
      final gold = int.tryParse(_goldController.text) ?? 0;
      
      if (_editingTask == null) {
        // 添加新任务
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
      } else {
        // 更新现有任务
        _editingTask!.title = _titleController.text.trim();
        _editingTask!.description = _descriptionController.text.trim();
        _editingTask!.dueDate = _dueDate;
        _editingTask!.category = _selectedCategory;
        _editingTask!.xp = xp;
        _editingTask!.gold = gold;
        await taskProvider.updateTask(_editingTask!);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存任务失败：${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _deleteTask() async {
    if (_editingTask == null) return;
    
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.deleteTask(_editingTask!.id);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error deleting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除任务失败：${e.toString()}')),
        );
      }
    }
  }
}