import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class Task {
  final int? id;
  final String taskName;
  final String taskDescription;
  final tz.TZDateTime taskDate;
  final tz.TZDateTime taskTime;
  final Color color;
  final bool isCompleted;

  Task({
    this.id,
    required this.taskName,
    required this.taskDescription,
    required this.taskDate,
    required this.taskTime,
    required this.color,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskName': taskName,
      'taskDescription': taskDescription,
      'taskDate': taskDate.toUtc().toIso8601String(),
      'taskTime': taskTime.toUtc().toIso8601String(),
      'color': color.value,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      taskName: map['taskName'],
      taskDescription: map['taskDescription'],
      taskDate: tz.TZDateTime.from(DateTime.parse(map['taskDate']), tz.local),
      taskTime: tz.TZDateTime.from(DateTime.parse(map['taskTime']), tz.local),
      color: Color(map['color']),
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
