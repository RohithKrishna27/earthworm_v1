import 'package:flutter/material.dart';

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
              // App Bar
              SliverAppBar(
                expandedHeight: 150,
                floating: false,
                pinned: true,
                backgroundColor: Colors.green[700],
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Select Your Crop',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                  padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryCard('Cereals', Icons.grass),
                            _buildCategoryCard('Pulses', Icons.spa),
                            _buildCategoryCard(
                                'Vegetables', Icons.local_florist),
                            _buildCategoryCard(
                                'Fruits', Icons.emoji_food_beverage),
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
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildCropCard(
                      context,
                      'Rice',
                      'assets/rice.jpg',
                      'Most widely consumed staple food',
                      'Cereals',
                    ),
                    _buildCropCard(
                      context,
                      'Wheat',
                      'assets/wheat.jpg',
                      'Essential grain for bread and pasta',
                      'Cereals',
                    ),
                    _buildCropCard(
                      context,
                      'Corn',
                      'assets/corn.jpg',
                      'Versatile crop with many uses',
                      'Cereals',
                    ),
                    _buildCropCard(
                      context,
                      'Soybeans',
                      'assets/soybeans.jpg',
                      'High-protein legume crop',
                      'Pulses',
                    ),
                    _buildCropCard(
                      context,
                      'Tomatoes',
                      'assets/tomatoes.jpg',
                      'Popular vegetable/fruit crop',
                      'Vegetables',
                    ),
                    _buildCropCard(
                      context,
                      'Cotton',
                      'assets/cotton.jpg',
                      'Important textile crop',
                      'Cash Crops',
                    ),
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
      elevation: 4,
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.green[700]),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
    String description,
    String category,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to crop details
          Navigator.pushNamed(context, '/crop-details', arguments: title);
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder (replace with actual images)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.green[200],
                child: Icon(
                  Icons.image,
                  size: 50,
                  color: Colors.green[700],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
