import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:carousel_slider/carousel_controller.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmer Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OnboardingScreen(),
    );
  }
}

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if farmer profile exists
  Future<bool> checkFarmerProfileExists() async {
    if (currentUserId == null) return false;
    
    final docSnapshot = await _firestore
        .collection('farmers')
        .doc(currentUserId)
        .get();
    
    return docSnapshot.exists;
  }

  // Get farmer profile data
  Future<Map<String, dynamic>?> getFarmerProfile() async {
    if (currentUserId == null) return null;

    final docSnapshot = await _firestore
        .collection('farmers')
        .doc(currentUserId)
        .get();
    
    return docSnapshot.data();
  }

  // Store farmer profile data
  Future<void> storeFarmerProfile({
    required String name,
    required double landSize,
    required String farmingMethod,
    required GeoPoint location,
  }) async {
    if (currentUserId == null) throw Exception('No user logged in');

    await _firestore.collection('farmers').doc(currentUserId).set({
      'name': name,
      'landSize': landSize,
      'farmingMethod': farmingMethod,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get inventory stream for current user
  Stream<QuerySnapshot> getInventoryStream() {
    if (currentUserId == null) throw Exception('No user logged in');

    return _firestore
        .collection('farmers')
        .doc(currentUserId)
        .collection('inventory')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get transactions stream for current user
  Stream<QuerySnapshot> getTransactionsStream() {
    if (currentUserId == null) throw Exception('No user logged in');

    return _firestore
        .collection('farmers')
        .doc(currentUserId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _landSizeController = TextEditingController();
  String? _selectedFarmingMethod;
  Position? _currentPosition;
  bool _isLoading = false;
 final FirebaseService _firebaseService = FirebaseService();
  

  final List<String> _farmingMethods = [
    'Organic Farming',
    'Conventional Farming',
    'Hydroponics',
    'Permaculture',
    'Mixed Farming'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
        _checkExistingProfile();

  }
Future<void> _checkExistingProfile() async {
  setState(() => _isLoading = true);

  try {
    // Check if user is logged in
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // If no user, trigger authentication or registration
      await _registerOrSignInUser();
      return;
    }

    // Check Firestore for existing profile
    DocumentSnapshot profileDoc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(currentUser.uid)
        .get();

    if (profileDoc.exists) {
      // Profile exists, navigate to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FarmerDashboard(
              farmerId: currentUser.uid,
            ),
          ),
        );
      }
    } else {
      // No profile exists, stay on onboarding screen
      setState(() => _isLoading = false);
    }
  } catch (e) {
    // Handle any errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error checking profile: $e')),
    );
    setState(() => _isLoading = false);
  }
}

Future<void> _registerOrSignInUser() async {
  try {
    // Perform anonymous sign-in
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
    
    // Trigger profile check again
    await _checkExistingProfile();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Authentication error: $e')),
    );
  }
}
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      setState(() => _isLoading = true);
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate() || _currentPosition == null) return;

  try {
    setState(() => _isLoading = true);

    // Get current authenticated user
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Store profile in Firestore using user's UID
    await FirebaseFirestore.instance
        .collection('farmers')
        .doc(currentUser.uid)
        .set({
      'name': _nameController.text,
      'landSize': double.parse(_landSizeController.text),
      'farmingMethod': _selectedFarmingMethod,
      'location': GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      'createdAt': FieldValue.serverTimestamp(),
      'onboardingComplete': true,  // Add this flag
    });

    // Navigate to dashboard
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FarmerDashboard(
            farmerId: currentUser.uid,
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving data: $e')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farmer Registration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Farmer Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _landSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Land Size (acres)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter land size';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFarmingMethod,
                      decoration: const InputDecoration(
                        labelText: 'Farming Method',
                        border: OutlineInputBorder(),
                      ),
                      items: _farmingMethods
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedFarmingMethod = value),
                      validator: (value) =>
                          value == null ? 'Please select a farming method' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _currentPosition == null ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Continue to Dashboard'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _landSizeController.dispose();
    super.dispose();
  }
}

class FarmerDashboard extends StatefulWidget {
  final String farmerId;

  const FarmerDashboard({
    Key? key, 
    required this.farmerId,
  }) : super(key: key);

  @override
  _FarmerDashboardState createState() => _FarmerDashboardState();
}
class _FarmerDashboardState extends State<FarmerDashboard> {
  Position? _currentPosition;
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _marketData = [];
  bool _isLoading = true;
  GoogleMapController? _mapController;
  int _currentMarketIndex = 0;
    final FirebaseService _firebaseService = FirebaseService();
  Timer? _marketScrollTimer;
  final CarouselController _carouselController = CarouselController();
  
  // Add this line to define the _farmingZones Set
  Set<Circle> _farmingZones = {};

  // Financial tracking controllers
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  final TextEditingController _incomeSourceController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();

  // Inventory tracking controllers
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startMarketScroll();
  }

  void _startMarketScroll() {
    _marketScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_marketData.isNotEmpty) {
        setState(() {
          _currentMarketIndex = (_currentMarketIndex + 1) % _marketData.length;
        });
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      await _getCurrentLocation();
      await Future.wait([
        _fetchWeatherData(),
        _fetchMarketData(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

 // Add these functions to the _FarmerDashboardState class

Future<void> _getCurrentLocation() async {
  try {
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
      }
      return;
    }

    // Then check & request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions permanently denied. Please enable in settings.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Get current position with high accuracy
    setState(() => _isLoading = true);
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    );

    setState(() {
      _currentPosition = position;
      _isLoading = false;
    });

    // Update map camera position
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
    setState(() => _isLoading = false);
  }
}

void _updateFarmingZones() {
  if (_weatherData == null || _currentPosition == null) return;

  final current = _weatherData!['current'];
  final forecast = _weatherData!['forecast']['forecastday'];

  // Convert values to double safely
  double temp = toDouble(current['temp_c']);
  double humidity = toDouble(current['humidity']);
  double windSpeed = toDouble(current['wind_kph']);
  double rainfall = 0.0;
  
  // Calculate average rainfall from forecast
  for (var day in forecast) {
    rainfall += toDouble(day['day']['totalprecip_mm']);
  }
  rainfall /= forecast.length;

  // Create zones based on conditions
  Set<Circle> newZones = {
    // Main farming zone
    Circle(
      circleId: const CircleId('optimal_zone'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: 1000, // 1km radius
      fillColor: _getZoneColor(temp, humidity, rainfall),
      strokeWidth: 2,
      strokeColor: Colors.green,
    ),
    // Buffer zone
    Circle(
      circleId: const CircleId('buffer_zone'),
      center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      radius: 1500, // 1.5km radius
      fillColor: Colors.yellow.withOpacity(0.1),
      strokeWidth: 1,
      strokeColor: Colors.yellow,
    ),
    // Risk zone - if conditions are unfavorable
    if (temp > 35 || humidity > 85 || windSpeed > 25)
      Circle(
        circleId: const CircleId('risk_zone'),
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        radius: 2000, // 2km radius
        fillColor: Colors.red.withOpacity(0.1),
        strokeWidth: 1,
        strokeColor: Colors.red,
      ),
  };

  setState(() {
    _farmingZones = newZones;
  });
}

Color _getZoneColor(double temp, double humidity, double rainfall) {
  // Optimal conditions
  if (temp >= 20 && temp <= 30 && humidity >= 60 && humidity <= 80 && rainfall >= 2) {
    return Colors.green.withOpacity(0.3);
  }
  // Moderate conditions
  else if (temp >= 15 && temp <= 35 && humidity >= 40 && humidity <= 90) {
    return Colors.yellow.withOpacity(0.3);
  }
  // Poor conditions
  else {
    return Colors.red.withOpacity(0.3);
  }
}

Widget _buildMapSection() {
  if (_currentPosition == null) {
    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Accessing location...'),
            ],
          ),
        ),
      ),
    );
  }

  return SizedBox(
    height: 300,
    child: Card(
      elevation: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
  'Farm Location & Weather Zones\nತೋಟ ಸ್ಥಳ ಮತ್ತು ಹವಾಮಾನ ವಲಯಗಳು',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: () {
                    _getCurrentLocation();
                    _updateFarmingZones();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('farm_location'),
                  position: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: 'Your Farm',
                    snippet: 'Temp: ${_weatherData?['current']['temp_c'].toStringAsFixed(1)}°C',
                  ),
                ),
              },
              circles: _farmingZones,
              onMapCreated: (controller) {
                _mapController = controller;
                _updateFarmingZones();
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.hybrid,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildZoneLegend('Optimal', Colors.green),
                _buildZoneLegend('Moderate', Colors.yellow),
                _buildZoneLegend('Risk', Colors.red),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


Future<void> _fetchWeatherData() async {
  if (_currentPosition == null) return;

  try {
    final String apiKey = '5f2a93688542443d98d140812242411';
    final url = Uri.parse(
      'http://api.weatherapi.com/v1/forecast.json'
      '?key=$apiKey'
      '&q=${_currentPosition!.latitude},${_currentPosition!.longitude}'
      '&days=7'
      '&aqi=yes'
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final decodedData = json.decode(response.body);
      
      // Ensure numeric values are properly converted to double
      if (decodedData['current'] != null) {
        decodedData['current']['temp_c'] = (decodedData['current']['temp_c'] ?? 0).toDouble();
        decodedData['current']['humidity'] = (decodedData['current']['humidity'] ?? 0).toDouble();
        decodedData['current']['wind_kph'] = (decodedData['current']['wind_kph'] ?? 0).toDouble();
      }

      setState(() => _weatherData = decodedData);
      _updateFarmingZones();
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching weather: $e')),
    );
  }
}

Widget _buildWeatherParameter(
  String label, 
  String value, 
  IconData icon,
  String tooltip,
) {
  return Tooltip(
    message: tooltip,
    child: Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 8),
        Text(
          label, 
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Helper function to safely convert dynamic values to double
double toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}


Widget _buildWeatherSection() {
  if (_weatherData == null) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Weather data unavailable'),
      ),
    );
  }

  final current = _weatherData!['current'];
  final forecast = _weatherData!['forecast']['forecastday'][0]['day'];

  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farming Weather Conditions/ಕೃಷಿ ಹವಾಮಾನ ಪರಿಸ್ಥಿತಿಗಳು',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherParameter(
                'Temperature',
                '${current['temp_c'].toStringAsFixed(1)}°C',
                Icons.thermostat,
                'Optimal: 20-30°C',
              ),
              _buildWeatherParameter(
                'Soil Moisture',
                '${current['humidity']}%',
                Icons.water_drop,
                'Ideal: 60-80%',
              ),
              _buildWeatherParameter(
                'Wind Speed',
                '${current['wind_kph'].toStringAsFixed(1)} km/h',
                Icons.air,
                'Safe: <20 km/h',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherParameter(
                'Rainfall',
                '${forecast['totalprecip_mm']} mm',
                Icons.umbrella,
                'Expected today',
              ),
              _buildWeatherParameter(
                'UV Index',
                current['uv'].toString(),
                Icons.wb_sunny,
                'Protection needed: >3',
              ),
              _buildWeatherParameter(
                'Pest Risk',
                _calculatePestRisk(current['temp_c'], current['humidity']),
                Icons.bug_report,
                'Based on conditions',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _calculatePestRisk(double temp, double humidity) {
  if (temp > 25 && humidity > 70) {
    return 'High';
  } else if (temp > 20 && humidity > 60) {
    return 'Medium';
  } else {
    return 'Low';
  }
}




Widget _buildZoneLegend(String label, Color color) {
  return Row(
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 4),
      Text(label),
    ],
  );
}
Future<void> _fetchMarketData() async {
  try {
    final String baseUrl = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070";
    final String apiKey = "579b464db66ec23bdd000001e3c6f8ed17cb4769425e0176dc5b7318";
    
    // Add Maharashtra filter
    final String defaultState = "Maharashtra";
    final url = Uri.parse('$baseUrl?api-key=$apiKey&format=json&filters[state]=${Uri.encodeComponent(defaultState)}');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final records = data['records'] as List<dynamic>;
      
      setState(() {
        _marketData = records.map((record) => {
          'commodity': record['commodity'] ?? '',
          'price': record['modal_price'] ?? '0.0',
          'trend': _calculateTrend(record['modal_price']),
          'market': record['market'] ?? '',
          'state': record['state'] ?? '',
        }).toList();
      });
    } else {
      throw Exception('Failed to load market data');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching market data: $e')),
    );
  }
}

String _calculateTrend(String currentPrice) {
  // You can implement more sophisticated trend calculation here
  // For now, we'll use a random trend as placeholder
  return Random().nextBool() ? 'up' : 'down';
}
  

 
 Widget _buildMarketTrends() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market Trends/ಮಾರುಕಟ್ಟೆ ಪ್ರವೃತ್ತಿಗಳು',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: CarouselSlider.builder(
                itemCount: _marketData.length,
                options: CarouselOptions(
                  autoPlay: true,
                  aspectRatio: 2.0,
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) {
                    setState(() => _currentMarketIndex = index);
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final item = _marketData[index];
                  return _buildMarketCard(item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildMarketCard(Map<String, dynamic> item) {
  return Card(
    color: Colors.white,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['commodity'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Market: ${item['market']}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'State: ${item['state']}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${item['price']}',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                item['trend'] == 'up' 
                    ? Icons.trending_up 
                    : Icons.trending_down,
                color: item['trend'] == 'up' 
                    ? Colors.green 
                    : Colors.red,
                size: 24,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Widget _buildInventorySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Management/ಸ್ಟಾಕ್ ನಿರ್ವಹಣೆ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Form(
              child: Column(
                children: [
                  TextFormField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name/ಐಟಂ ಹೆಸರು',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity/ಪ್ರಮಾಣ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Price/ಯುನಿಟ್ ಬೆಲೆ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addInventoryItem,
                    child: const Text('Add Item'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('farmers')
                  .doc(widget.farmerId)
                  .collection('inventory')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(item['itemName'] ?? ''),
                      subtitle: Text('Quantity: ${item['quantity']}'),
                      trailing: Text('₹${item['unitPrice']}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addInventoryItem() async {
    try {
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.farmerId)
          .collection('inventory')
          .add({
        'itemName': _itemNameController.text,
        'quantity': double.parse(_quantityController.text),
        'unitPrice': double.parse(_unitPriceController.text),
        'timestamp': FieldValue.serverTimestamp(),
      });

      _itemNameController.clear();
      _quantityController.clear();
      _unitPriceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    }
  }

  Widget _buildFinancialSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Managementಹಣಕಾಸು ನಿರ್ವಹಣೆ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildFinancialForm(),
            const SizedBox(height: 16),
            _buildFinancialSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialForm() {
    return Column(
      children: [
        ExpansionTile(
          title: const Text('Add Expense/ಖರ್ಚು ಸೇರಿಸು'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _expenseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _expenseAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addExpense,
                    child: const Text('Add Expense'),
                  ),
                ],
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('Add Income/ಆದಾಯ ಸೇರಿಸು'),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _incomeSourceController,
                    decoration: const InputDecoration(
                      labelText: 'Income Source',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _incomeAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addIncome,
                    child: const Text('Add Income'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialSummary() {
    return StreamBuilder<QuerySnapshot>(
      
      stream: FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.farmerId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!.docs;
        double totalIncome = 0;
        double totalExpenses = 0;

        for (var doc in transactions) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['type'] == 'income') {
            totalIncome += data['amount'] ?? 0;
          } else {
            totalExpenses += data['amount'] ?? 0;
          }
        }

        return Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Net Balance/ನಿವ್ವಳ ಮೊತ್ತ'),
                trailing: Text(
                  '₹${(totalIncome - totalExpenses).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: totalIncome >= totalExpenses
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction =
                    transactions[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: Icon(
                    transaction['type'] == 'income'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: transaction['type'] == 'income'
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(transaction['description']),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(
                    (transaction['timestamp'] as Timestamp).toDate(),
                  )),
                  trailing: Text(
                    '₹${transaction['amount'].toStringAsFixed(2)}',
                    style: TextStyle(
                      color: transaction['type'] == 'income'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addExpense() async {
    await _addTransaction('expense');
  }

  Future<void> _addIncome() async {
    await _addTransaction('income');
  }

  Future<void> _addTransaction(String type) async {
    try {
      final description = type == 'income'
          ? _incomeSourceController.text
          : _expenseNameController.text;
      final amount = double.parse(
        type == 'income'
            ? _incomeAmountController.text
            : _expenseAmountController.text,
      );

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(widget.farmerId)
          .collection('transactions')
          .add({
        'type': type,
        'description': description,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (type == 'income') {
        _incomeSourceController.clear();
        _incomeAmountController.clear();
      } else {
        _expenseNameController.clear();
        _expenseAmountController.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${type.capitalize()} added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding $type: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherSection(),
                    const SizedBox(height: 16),
                    _buildMapSection(),
                    const SizedBox(height: 16),
                    _buildMarketTrends(),
                    const SizedBox(height: 16),
                    _buildInventorySection(),
                    const SizedBox(height: 16),
                    _buildFinancialSection(),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _marketScrollTimer?.cancel();
    _mapController?.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    _incomeSourceController.dispose();
    _incomeAmountController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}