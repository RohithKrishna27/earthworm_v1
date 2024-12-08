import 'package:flutter/material.dart';
import 'options_page.dart';

class LearnHome extends StatelessWidget {
  final List<String> topics = [
    'Soil Preparation',
    'Irrigation Techniques',
    'Crop Rotation',
    'Pest Management',
    'Organic Farming'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farming Practices'),
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(topics[index]),
            onTap: () {
              // Pass the selected topic to the next screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OptionsPage(topic: topics[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
