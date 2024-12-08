import 'package:flutter/material.dart';
import 'videos_page.dart';
import 'quiz_page.dart';

class OptionsPage extends StatelessWidget {
  final String topic;

  OptionsPage({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose an Option'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What would you like to learn about $topic?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ListTile(
            title: Text('Watch Videos'),
            onTap: () {
              // Navigate to the video screen for the selected topic
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideosPage(topic: topic),
                ),
              );
            },
          ),
          ListTile(
            title: Text('Read Articles'),
            onTap: () {
              // Navigate to a placeholder screen for reading articles
              // You can implement this screen as needed
            },
          ),
          ListTile(
            title: Text('Play Quiz'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPage(topic: topic),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
