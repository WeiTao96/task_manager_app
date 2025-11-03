import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';
import '../models/task.dart';
import '../models/profession.dart';

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
  String _selectedCategory = '工作';
  String? _selectedProfessionId; // 选中的职业ID
  final List<String> _categories = ['工作', '个人', '学习', '其他'];
  
  Task? _editingTask;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 加载职业列表
      Provider.of<ProfessionProvider>(context, listen: false).loadProfessions();
      
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Task) {
        setState(() {
          _editingTask = args;
          _titleController.text = args.title;
          _descriptionController.text = args.description;
          _dueDate = args.dueDate;
          _selectedCategory = args.category;
          _xpController.text = args.xp.toString();
          _goldController.text = args.gold.toString();
          _selectedProfessionId = args.professionId;
        });
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
      body: Padding(
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
              
              // 分类选择
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: '分类',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
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
              SizedBox(height: 16),
              
              // 职业选择
              Consumer<ProfessionProvider>(
                builder: (context, professionProvider, child) {
                  final professions = professionProvider.professions;
                  
                  return DropdownButtonFormField<String?>(
                    value: _selectedProfessionId,
                    decoration: InputDecoration(
                      labelText: '关联职业（可选）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('无关联职业'),
                      ),
                      ...professions.map((profession) {
                        return DropdownMenuItem<String?>(
                          value: profession.id,
                          child: Row(
                            children: [
                              Text(profession.icon, style: TextStyle(fontSize: 18)),
                              SizedBox(width: 8),
                              Expanded(child: Text(profession.name)),
                              Text('Lv.${profession.level}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProfessionId = newValue;
                      });
                    },
                  );
                },
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
  
  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final xp = int.parse(_xpController.text);
      final gold = int.parse(_goldController.text);
      
      if (_editingTask == null) {
        // 添加新任务
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _dueDate,
          category: _selectedCategory,
          xp: xp,
          gold: gold,
          professionId: _selectedProfessionId,
        );
        taskProvider.addTask(newTask);
      } else {
        // 更新现有任务
        _editingTask!.title = _titleController.text;
        _editingTask!.description = _descriptionController.text;
        _editingTask!.dueDate = _dueDate;
        _editingTask!.category = _selectedCategory;
        _editingTask!.xp = xp;
        _editingTask!.gold = gold;
        _editingTask!.professionId = _selectedProfessionId;
        taskProvider.updateTask(_editingTask!);
      }
      
      Navigator.pop(context);
    }
  }
  
  void _deleteTask() {
    if (_editingTask != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.deleteTask(_editingTask!.id);
      Navigator.pop(context);
    }
  }
}