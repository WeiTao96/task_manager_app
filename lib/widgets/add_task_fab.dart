import 'package:flutter/material.dart';

class AddTaskFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/add_task');
      },
      child: Icon(Icons.add, color: Colors.white),
      backgroundColor: Colors.blue[700],
      elevation: 4,
    );
  }
}