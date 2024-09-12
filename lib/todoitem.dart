import 'package:flutter/material.dart';

class TodoItem {
  final String taskName;
  final String taskDescription;
  final DateTime taskDate;
  final DateTime taskTime;
  final Color color;
  bool isCompleted;

  TodoItem({
    required this.taskName,
    required this.taskDescription,
    required this.taskDate,
    required this.taskTime,
    required this.color,
    this.isCompleted = false,
  });
}
