import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do/saveImageToPrefs.dart';
import 'package:to_do/todoitem.dart';
import 'databaseHelper.dart';
import 'task.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todoItems = [];
  File? _backgroundImage;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    // _loadBackgroundImage();
    _loadTasks();
  }

  void _loadBackgroundImage() async {
    File? imageFile = await _databaseHelper.getImageAsFile();  // Retrieve the image as File
    if (imageFile != null) {
      setState(() {
        _backgroundImage = imageFile;
      });
    }
  }


  void _loadTasks() async {
    final tasks = await _databaseHelper.getTasks();
    setState(() {
      _todoItems.clear();
      _todoItems.addAll(tasks.map((task) => TodoItem(
        taskName: task.taskName,
        taskDescription: task.taskDescription,
        taskDate: tz.TZDateTime.parse(tz.local, task.taskDate.toString()),
        taskTime: tz.TZDateTime.parse(tz.local, task.taskTime.toString()),
        color: task.color,
        isCompleted: task.isCompleted,
      )));
    });
  }

  void _addTodoItem(TodoItem item) async {
    final task = Task(
      taskName: item.taskName,
      taskDescription: item.taskDescription,
      taskDate: tz.TZDateTime.parse(tz.local, item.taskDate.toUtc().toIso8601String()),
      taskTime: tz.TZDateTime.parse(tz.local,item.taskTime.toUtc().toIso8601String()),
      color: item.color,
      isCompleted: item.isCompleted,
    );
    await _databaseHelper.insertTask(task);
    _loadTasks();
    _scheduleNotification(item);
  }

  void _scheduleNotification(TodoItem item) async {
    final tz.TZDateTime notificationTime = tz.TZDateTime(
      tz.local,
      item.taskDate.year,
      item.taskDate.month,
      item.taskDate.day,
      item.taskTime.hour,
      item.taskTime.minute,
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,

    );

    final iOSPlatformChannelSpecifics = DarwinNotificationDetails();

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Task Reminder',
      'Reminder for ${item.taskName}',

      notificationTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.add),
        //     onPressed: _openAddTaskDialog,
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          if (_backgroundImage != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(_backgroundImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Container(
            color: Colors.black.withOpacity(0.1), // Slight overlay to enhance text visibility
            child: _todoItems.isEmpty
                ? Center(
              child: Text('No tasks added yet!'),
            )
                : ListView.builder(
              itemCount: _todoItems.length,
              itemBuilder: (context, index) {
                final item = _todoItems[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 10,top: index==0?10:0),
                  color: item.color.withOpacity(0.3),
                  child: ListTile(
                    title: Text(
                      item.taskName,
                      style: TextStyle(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      '${item.taskDescription}\n${DateFormat.yMMMd().format(item.taskDate)} ${DateFormat.jm().format(item.taskTime)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeTodoItem(index),
                    ),
                    onTap: () => _toggleTodoItem(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
  }

  void _toggleTodoItem(int index) {
    setState(() {
      _todoItems[index].isCompleted = !_todoItems[index].isCompleted;
    });
  }

  void _openAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(
          onAdd: _addTodoItem,
        );
      },
    );
  }

// Save the image when picked
  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageBytes = await File(pickedFile.path).readAsBytes();
      await _databaseHelper.insertImage(imageBytes);  // Save image to SQLite

      setState(() {
        _backgroundImage = File(pickedFile.path);  // Show the image immediately
      });
    }
  }


// Load the image on app startup
//   void _loadBackgroundImage() async {
//     Image? image = await getImageWidgetFromPrefs();
//     setState(() {
//       _backgroundImage = image as File?;
//     });
//   }

}

class AddTaskDialog extends StatefulWidget {
  final Function(TodoItem) onAdd;

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _taskNameController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Color _selectedColor = Colors.blue;

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitTask() {
    if (_taskNameController.text.isNotEmpty &&
        _taskDescriptionController.text.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null) {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final newTask = TodoItem(
        taskName: _taskNameController.text,
        taskDescription: _taskDescriptionController.text,
        taskDate: tz.TZDateTime.from(dateTime, tz.local),
        taskTime: tz.TZDateTime.from(dateTime, tz.local),
        color: _selectedColor,
      );
      widget.onAdd(newTask);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            TextField(
              controller: _taskDescriptionController,
              decoration: InputDecoration(labelText: 'Task Description'),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat.yMMMd().format(_selectedDate!)
                        : 'No date chosen',
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: Text('Pick Date'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'No time chosen',
                  ),
                ),
                TextButton(
                  onPressed: _pickTime,
                  child: Text('Pick Time'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    color: _selectedColor,
                    height: 50,
                    child: Center(
                      child: Text(
                        'Selected Color',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickColor,
                  child: Text('Pick Color'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _submitTask,
          child: Text('Add Task'),
        ),
      ],
    );
  }
}
