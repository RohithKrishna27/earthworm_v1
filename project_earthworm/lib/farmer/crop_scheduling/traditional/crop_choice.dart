// crop_selection_screen.dart
import 'package:flutter/material.dart';
import 'crop_questionnaire.dart';
import 'crop_schedule.dart';

class CropSelectionScreen extends StatelessWidget {
  const CropSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.green[700],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Select Your Crop',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.green[700]!,
                          Colors.green[500]!,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryCard('Cereals', Icons.grass),
                            _buildCategoryCard('Pulses', Icons.spa),
                            _buildCategoryCard(
                                'Vegetables', Icons.local_florist),
                            _buildCategoryCard('Oilseeds', Icons.water_drop),
                            _buildCategoryCard(
                                'Cash Crops', Icons.monetization_on),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Crops Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildCropCard(
                        context, 'Rice', 'images/rice.png', 'Cereals'),
                    _buildCropCard(
                        context, 'Maize', 'images/maize.png', 'Cereals'),
                    _buildCropCard(
                        context, 'Mustard', 'images/mustard.png', 'Oilseeds'),
                    _buildCropCard(
                        context, 'Tomatoes', 'images/tomato.png', 'Vegetables'),
                    _buildCropCard(context, 'Ground Nut',
                        'images/ground_nut.png', 'Oilseeds'),
                    _buildCropCard(
                        context, 'Ragi', 'images/ragi.png', 'Cereals'),
                    _buildCropCard(
                        context, 'Cotton', 'images/cotton.png', 'Cash Crops'),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: Colors.green[700]),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropCard(
    BuildContext context,
    String title,
    String imagePath,
    String category,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropQuestionnaireScreen(cropName: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                imagePath,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 110,
                    color: Colors.green[50],
                    child: Icon(Icons.image_not_supported,
                        color: Colors.green[700]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
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
}
