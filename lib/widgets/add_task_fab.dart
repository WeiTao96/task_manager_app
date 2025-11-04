import 'package:flutter/material.dart';
import '../screens/ultra_simple_task_form_screen.dart';

class AddTaskFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UltraSimpleTaskFormScreen()),
        );
      },
      child: Icon(Icons.add, color: Colors.white),
      backgroundColor: Colors.blue[700],
      elevation: 4,
    );
  }
}