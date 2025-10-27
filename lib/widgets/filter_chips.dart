import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final currentFilter = taskProvider.filter;
    
    return Padding(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: [
          _buildFilterChip(
            context: context,
            label: '全部',
            value: 'all',
            currentFilter: currentFilter,
          ),
          _buildFilterChip(
            context: context,
            label: '进行中',
            value: 'pending',
            currentFilter: currentFilter,
          ),
          _buildFilterChip(
            context: context,
            label: '已完成',
            value: 'completed',
            currentFilter: currentFilter,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String value,
    required String currentFilter,
  }) {
    return FilterChip(
      label: Text(label),
      selected: currentFilter == value,
      onSelected: (selected) {
        Provider.of<TaskProvider>(context, listen: false)
            .setFilter(value);
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }
}