import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  
  const TaskItem({Key? key, required this.task}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: task.difficulty.color,
          width: 3,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: task.difficulty.color,
              width: 6,
            ),
          ),
        ),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              Provider.of<TaskProvider>(context, listen: false)
                  .toggleTaskCompletion(task.id);
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: task.isCompleted 
                  ? TextDecoration.lineThrough 
                  : TextDecoration.none,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${task.dueDate.year}-${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(task.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // 难度指示器
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: task.difficulty.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: task.difficulty.color,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDifficultyIcon(task.difficulty),
                          size: 12,
                          color: task.difficulty.color,
                        ),
                        SizedBox(width: 2),
                        Text(
                          task.difficulty.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: task.difficulty.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              _showDeleteDialog(context, task.id);
            },
          ),
          onTap: () {
            _navigateToEditTask(context, task);
          },
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case '工作':
        return Colors.blue;
      case '个人':
        return Colors.green;
      case '学习':
        return Colors.orange;
      case '其他':
        return Colors.purple;
      default:
        return Colors.grey;
    }
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
  
  void _showDeleteDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('删除任务'),
          content: Text('确定要删除这个任务吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<TaskProvider>(context, listen: false)
                    .deleteTask(taskId);
                Navigator.of(context).pop();
              },
              child: Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _navigateToEditTask(BuildContext context, Task task) {
    Navigator.pushNamed(
      context,
      '/edit_task',
      arguments: task,
    );
  }
}