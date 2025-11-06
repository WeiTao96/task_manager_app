import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  
  const TaskItem({Key? key, required this.task}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: task.isCompleted 
              ? [Color(0xFF1A1A2E).withOpacity(0.3), Color(0xFF048A81).withOpacity(0.3)]
              : [Colors.white, Color(0xFFF5F5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: task.difficulty.color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: task.difficulty.color.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: task.difficulty.color,
              width: 6,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // 像素风格复选框
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: task.isCompleted ? Color(0xFF048A81) : Color(0xFF2E4057),
                    width: 2,
                  ),
                  color: task.isCompleted ? Color(0xFF048A81) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Provider.of<TaskProvider>(context, listen: false)
                        .toggleTaskCompletion(task.id);
                  },
                  child: task.isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              
              SizedBox(width: 12),
              
              // 任务内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 任务标题
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: task.isCompleted ? Color(0xFF2E4057).withOpacity(0.6) : Color(0xFF1A1A2E),
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : TextDecoration.none,
                        shadows: task.isCompleted ? null : [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: Offset(1, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // 任务描述
                    if (task.description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFF2E4057).withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    SizedBox(height: 6),
                    
                    // 任务信息栏
                    Row(
                      children: [
                        // 日期
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF2E4057).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Color(0xFF2E4057).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 10,
                                color: Color(0xFF2E4057),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: Color(0xFF2E4057),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 6),
                        
                        // 类别
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(task.category),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Text(
                            task.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        SizedBox(width: 6),
                        
                        // 难度指示器
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: task.difficulty.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: task.difficulty.color, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getDifficultyIcon(task.difficulty),
                                size: 10,
                                color: task.difficulty.color,
                              ),
                              SizedBox(width: 2),
                              Text(
                                task.difficulty.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: task.difficulty.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Spacer(),
                        
                        // 经验和金币奖励
                        if (task.xp > 0 || task.gold > 0) ...[
                          Row(
                            children: [
                              if (task.xp > 0) ...[
                                Icon(Icons.star, size: 12, color: Color(0xFF048A81)),
                                Text(
                                  '${task.xp}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF048A81),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                              ],
                              if (task.gold > 0) ...[
                                Icon(Icons.monetization_on, size: 12, color: Color(0xFFFFD23F)),
                                Text(
                                  '${task.gold}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: Color(0xFFFFD23F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              Column(
                children: [
                  // 编辑按钮
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFF048A81),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _navigateToEditTask(context, task),
                      child: Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 6),
                  
                  // 删除按钮
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _showDeleteDialog(context, task.id),
                      child: Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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