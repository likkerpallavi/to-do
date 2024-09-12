import 'package:flutter/material.dart';
import 'package:to_do/todoList.dart';


class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => TodoListScreen(),
              ),
            );
          },
          child: Text('Login'),
        ),
      ),
    );
  }
}
