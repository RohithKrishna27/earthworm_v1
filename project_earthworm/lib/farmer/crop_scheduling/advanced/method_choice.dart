import 'package:flutter/material.dart';

class FarmingMethodsScreen extends StatelessWidget {
  const FarmingMethodsScreen({Key? key}) : super(key: key);

  void _showMethodDetails(
      BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMethodBox(
    BuildContext context,
    String title,
    String description,
    String imagePath,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showMethodDetails(context, title, description),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.asset(
                imagePath,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Farming Methods'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Select an Advanced Farming Method',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildMethodBox(
              context,
              'Vertical Farming',
              'Indoor farming technique where crops are grown in vertically stacked layers with controlled environment and LED lighting.',
              'assets/images/vertical_farming.jpg',
              Colors.green,
            ),
            _buildMethodBox(
              context,
              'Aquaponics',
              'Sustainable system combining aquaculture (raising fish) with hydroponics (growing plants in water) in a symbiotic environment.',
              'assets/images/aquaponics.jpg',
              Colors.blue,
            ),
            _buildMethodBox(
              context,
              'Aeroponics',
              'High-tech method of growing plants in an air or mist environment without soil and with minimal water usage.',
              'assets/images/aeroponics.jpg',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
