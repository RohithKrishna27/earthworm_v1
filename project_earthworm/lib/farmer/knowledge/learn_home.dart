import 'package:flutter/material.dart';
import 'options_page.dart';

class LearnHome extends StatelessWidget {
  final List<String> topics = [
    'Soil Preparation',
    'Irrigation Techniques',
    'Crop Rotation',
    'Pest Management',
    'Organic Farming',
    'Sustainable Agriculture',
    'Greenhouse Techniques',
  ];

  final List<IconData> topicIcons = [
    Icons.grain, // Soil Preparation
    Icons.water, // Irrigation Techniques
    Icons.rotate_left, // Crop Rotation
    Icons.pest_control, // Pest Management
    Icons.eco, // Organic Farming
    Icons.nature_people, // Sustainable Agriculture
    Icons.local_florist, // Greenhouse Techniques
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farming Practices'),
        backgroundColor: Colors.green, // Green theme for app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: GridView.builder(
            shrinkWrap: true, // Prevent the grid from taking up more space than necessary
            physics: NeverScrollableScrollPhysics(), // Disable the internal scrolling of GridView
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two cards per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1, // Increased aspect ratio to make the cards longer (12px added)
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // Navigate to the next page with the selected topic
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OptionsPage(topic: topics[index]),
                    ),
                  );
                },
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.green[50], // Light green background for cards
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          topicIcons[index],
                          size: 40,
                          color: Colors.green, // Green icon color
                        ),
                        SizedBox(height: 10),
                        Text(
                          topics[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800], // Darker green text color
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
