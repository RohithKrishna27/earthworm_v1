import 'package:flutter/material.dart';

class Farmingmap  extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Page'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Welcome to the Page!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
     ),
);
}
}