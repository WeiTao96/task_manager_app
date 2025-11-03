import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/profession_provider.dart';

class FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final professionProvider = Provider.of<ProfessionProvider>(context);
    final currentFilter = taskProvider.filter;
    final tasks = taskProvider.tasks;
    
    // 获取所有任务的分类（包括默认分类和职业名称）
    final Set<String> categories = tasks.map((task) => task.category).toSet();
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildFilterChip(
            context: context,
            label: '全部',
            value: 'all',
            currentFilter: currentFilter,
            icon: '📋',
          ),
          _buildFilterChip(
            context: context,
            label: '进行中',
            value: 'pending',
            currentFilter: currentFilter,
            icon: '⏳',
          ),
          _buildFilterChip(
            context: context,
            label: '已完成',
            value: 'completed',
            currentFilter: currentFilter,
            icon: '✅',
          ),
          // 添加分类过滤器
          ...categories.map((category) {
            final profession = professionProvider.professions.cast<dynamic>().firstWhere(
              (prof) => prof.name == category,
              orElse: () => null,
            );
            
            return _buildFilterChip(
              context: context,
              label: category,
              value: 'category:$category',
              currentFilter: currentFilter,
              icon: profession?.icon ?? _getCategoryIcon(category),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String value,
    required String currentFilter,
    String? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: TextStyle(fontSize: 14)),
            SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: currentFilter == value,
      onSelected: (selected) {
        Provider.of<TaskProvider>(context, listen: false)
            .setFilter(value);
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }
  
  String _getCategoryIcon(String category) {
    switch (category) {
      case '工作': return '💼';
      case '个人': return '👤';
      case '学习': return '📚';
      case '其他': return '📋';
      default: return '📝';
    }
  }
}