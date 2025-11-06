import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import 'task_item.dart';

class TaskList extends StatefulWidget {
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  bool _showCompletedTasks = false;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final allTasks = taskProvider.tasks;
    
    if (allTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '暂无任务',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    // 分离未完成和已完成的任务
    final incompleteTasks = allTasks.where((task) => !task.isCompleted).toList();
    final completedTasks = allTasks.where((task) => task.isCompleted).toList();
    
    return ListView(
      children: [
        // 未完成的任务
        ...incompleteTasks.map((task) => TaskItem(task: task)).toList(),
        
        // 已完成任务的收纳区域
        if (completedTasks.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 可点击的标题栏
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showCompletedTasks = !_showCompletedTasks;
                      });
                    },
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                      bottom: _showCompletedTasks ? Radius.zero : Radius.circular(12),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                          bottom: _showCompletedTasks ? Radius.zero : Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '已完成任务 (${completedTasks.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          Spacer(),
                          AnimatedRotation(
                            turns: _showCompletedTasks ? 0.5 : 0,
                            duration: Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 可展开的已完成任务列表
                  AnimatedCrossFade(
                    firstChild: SizedBox.shrink(),
                    secondChild: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        children: completedTasks.map((task) => 
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: _buildCompactTaskItem(task),
                            ),
                          )
                        ).toList(),
                      ),
                    ),
                    crossFadeState: _showCompletedTasks 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                    duration: Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // 底部留白
        SizedBox(height: 80),
      ],
    );
  }

  // 为收纳区域构建紧凑的任务项
  Widget _buildCompactTaskItem(task) {
    return Row(
      children: [
        // 复选框
        Checkbox(
          value: task.isCompleted,
          onChanged: (value) {
            Provider.of<TaskProvider>(context, listen: false)
                .toggleTaskCompletion(task.id);
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        
        // 任务内容
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 任务标题
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: task.isCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 2),
              
              // 任务信息行
              Row(
                children: [
                  // 难度指示器
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: task.difficulty.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.difficulty.color,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      task.difficulty.displayName,
                      style: TextStyle(
                        fontSize: 9,
                        color: task.difficulty.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 6),
                  
                  // 类别
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(task.category),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.category,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  Spacer(),
                  
                  // 日期
                  Text(
                    '${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 删除按钮
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 18),
          onPressed: () {
            _showDeleteDialog(context, task.id);
          },
          padding: EdgeInsets.all(4),
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  // 获取类别颜色
  Color _getCategoryColor(String category) {
    switch (category) {
      case '工作':
        return Colors.blue;
      case '个人':
        return Colors.green;
      case '学习':
        return Colors.orange;
      case '健康':
        return Colors.red;
      case '社交':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 显示删除确认对话框
  void _showDeleteDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除这个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Provider.of<TaskProvider>(context, listen: false)
                  .deleteTask(taskId);
            },
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}