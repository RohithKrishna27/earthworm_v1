import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_earthworm/farmer/calculator/calculator_home.dart';
import 'package:project_earthworm/farmer/farmerdashboard.dart';
import 'package:project_earthworm/farmer/farmer_profile.dart';

class FarmerHome extends StatefulWidget {
  @override
  _FarmerHomeState createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    CalculatorHomeScreen(),
    OnboardingScreen(),
    FormerProfile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1B5E20), // Dark green
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // Define vibrant colors
  final Color primaryGreen = Color(0xFF66BB6A); // Vibrant green
  final Color secondaryGreen = Color(0xFF1B5E20); // Dark green
  final Color accentYellow = Color(0xFFFFEB3B); // Vibrant yellow
  final Color backgroundColor = Color(0xFFF1F8E9); // Light green background

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = screenWidth * 0.9; // 90% of screen width

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              // Welcome Header with enhanced styling
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: secondaryGreen,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your farming journey continues here!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Feature Boxes with enhanced styling
              _buildLargeFeatureBox(
                context,
                'Farmer Dashboard',
                'Track and manage your farm activities',
                Icons.dashboard,
                '/dashboard',
                Color(0xFF66BB6A), // Vibrant green
                boxWidth,
              ),

              _buildLargeFeatureBox(
                context,
                'Sell Your Crops',
                'List and manage your crop sales',
                Icons.store,
                '/sell-crops',
                Color(0xFF43A047), // Slightly darker green
                boxWidth,
              ),

              _buildLargeFeatureBox(
                context,
                'Crop Assistance',
                'Get expert advice and crop management tips',
                Icons.eco,
                '/crop-assistance',
                Color(0xFF2E7D32), // Darkest green
                boxWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeFeatureBox(BuildContext context, String title,
      String subtitle, IconData icon, String route, Color color, double width) {
    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Route generator and other screens remain the same as previous implementation
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => OnboardingScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => FarmerDashboardScreen());
      case '/sell-crops':
        return MaterialPageRoute(builder: (_) => SellCropsScreen());
      case '/crop-assistance':
        return MaterialPageRoute(builder: (_) => CropAssistanceScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

// Feature screens with matching theme
class FarmerDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmer Dashboard'),
        backgroundColor: Color(0xFF66BB6A),
      ),
      body: Center(child: Text('Farmer Dashboard Content')),
    );
  }
}

class SellCropsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sell Your Crops'),
        backgroundColor: Color(0xFF43A047),
      ),
      body: Center(child: Text('Sell Crops Content')),
    );
  }
}

class CropAssistanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Assistance'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: Center(child: Text('Crop Assistance Content')),
    );
  }
}
