import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
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
  
  DateTime _dueDate = DateTime.now().add(Duration(days: 1));
  String _selectedCategory = '工作';
  final List<String> _categories = ['工作', '个人', '学习', '其他'];
  
  Task? _editingTask;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Task) {
        setState(() {
          _editingTask = args;
          _titleController.text = args.title;
          _descriptionController.text = args.description;
          _dueDate = args.dueDate;
          _selectedCategory = args.category;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
      
      if (_editingTask == null) {
        // 添加新任务
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _dueDate,
          category: _selectedCategory,
        );
        taskProvider.addTask(newTask);
      } else {
        // 更新现有任务
        _editingTask!.title = _titleController.text;
        _editingTask!.description = _descriptionController.text;
        _editingTask!.dueDate = _dueDate;
        _editingTask!.category = _selectedCategory;
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