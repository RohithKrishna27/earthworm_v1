import 'package:flutter/material.dart';

class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Center(
        child: Text('This is the Todo List page'),
      ),
    );
  }
}
