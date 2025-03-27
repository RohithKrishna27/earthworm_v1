import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';

class NPKAnalysisScreen extends StatefulWidget {
  @override
  _NPKAnalysisScreenState createState() => _NPKAnalysisScreenState();
}

class _NPKAnalysisScreenState extends State<NPKAnalysisScreen> {
  List<NPKData> _npkDataList = [];
  String _geminiInsights = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNPKDataFromPastTwoWeeks();
  }

  Future<void> _fetchNPKDataFromPastTwoWeeks() async {
    setState(() {
      _isLoading = true;
      _npkDataList.clear();
    });

    try {
      DateTime twoWeeksAgo = DateTime.now().subtract(Duration(days: 14));

      final QuerySnapshot sensorSnapshot = await FirebaseFirestore.instance
          .collection('Sensor')
          .where('time', isGreaterThan: twoWeeksAgo)
          .orderBy('time', descending: true)
          .get();

      List<NPKData> npkData = sensorSnapshot.docs
          .map((doc) => NPKData(
                nitrogen: _convertToDouble(doc['n']),
                phosphorus: _convertToDouble(doc['p']),
                potassium: _convertToDouble(doc['k']),
                rainfall: _convertToDouble(doc['Rainfall'] ?? 0),
                timestamp: doc['time'] as Timestamp,
              ))
          .toList();

      setState(() {
        _npkDataList = npkData;
        _isLoading = false; 
      });

      await _generateNPKInsights();

    } catch (e) {
      print('Error fetching NPK data: $e');
      setState(() {
        _isLoading = false;
        _npkDataList = [];
        _geminiInsights = 'Unable to fetch NPK data: $e';
      });
    }
  }

  // Helper method to convert various types to double
  double _convertToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Method to calculate averages
  Map<String, double> _calculateNPKAverages() {
    if (_npkDataList.isEmpty) {
      return {
        'nitrogenAvg': 0.0,
        'phosphorusAvg': 0.0,
        'potassiumAvg': 0.0,
        'rainfallAvg': 0.0
      };
    }

    double nitrogenSum = _npkDataList.map((data) => data.nitrogen).reduce((a, b) => a + b);
    double phosphorusSum = _npkDataList.map((data) => data.phosphorus).reduce((a, b) => a + b);
    double potassiumSum = _npkDataList.map((data) => data.potassium).reduce((a, b) => a + b);
    double rainfallSum = _npkDataList.map((data) => data.rainfall).reduce((a, b) => a + b);

    return {
      'nitrogenAvg': nitrogenSum / _npkDataList.length,
      'phosphorusAvg': phosphorusSum / _npkDataList.length,
      'potassiumAvg': potassiumSum / _npkDataList.length,
      'rainfallAvg': rainfallSum / _npkDataList.length
    };
  }

  Future<void> _generateNPKInsights() async {
    if (_npkDataList.isEmpty) return;

    String dataDescription = _prepareNPKDataDescription();

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyBHZH-qGsEjnyoKDcpCM-BzfLIr9YdUJkU"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": """
                Analyze the following NPK and rainfall soil nutrient data from the past two weeks:

                $dataDescription

                Provide comprehensive insights focusing on:
                1. NPK nutrient level trends
                2. Rainfall impact on nutrient concentrations
                3. Recommended nutrient and irrigation strategies
                4. Potential crop growth implications
                5. Actionable agricultural recommendations
                """}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          _geminiInsights = responseData['candidates']?[0]['content']?['parts']?[0]['text'] 
            ?? "No NPK insights available from Gemini.";
        });
      } else {
        setState(() {
          _geminiInsights = "Failed to fetch NPK insights. Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _geminiInsights = "Error generating NPK insights: $e";
      });
    }
  }

  String _prepareNPKDataDescription() {
    return _npkDataList.map((data) => '''
    Soil Nutrient Reading:
    - Timestamp: ${data.timestamp.toDate()}
    - Nitrogen (N): ${data.nitrogen}
    - Phosphorus (P): ${data.phosphorus}
    - Potassium (K): ${data.potassium}
    - Rainfall: ${data.rainfall}
    ''').join('\n\n');
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soil Nutrient Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNPKDataFromPastTwoWeeks,
          )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.green))
        : RefreshIndicator(
            onRefresh: _fetchNPKDataFromPastTwoWeeks,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNutrientGraphs(),
                          SizedBox(height: 20),
                          _buildInsightsCard(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildNutrientGraphs() {
    // Calculate averages
    Map<String, double> averages = _calculateNPKAverages();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrient & Rainfall Analysis',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Colors.green[800]
              ),
            ),
            SizedBox(height: 10),
            // Wrap average information in a Wrap widget for better responsiveness
            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                Text('Avg Nitrogen: ${averages['nitrogenAvg']?.toStringAsFixed(2) ?? '0.00'}', 
                  style: TextStyle(color: Colors.blue)),
                Text('Avg Phosphorus: ${averages['phosphorusAvg']?.toStringAsFixed(2) ?? '0.00'}', 
                  style: TextStyle(color: Colors.red)),
                Text('Avg Potassium: ${averages['potassiumAvg']?.toStringAsFixed(2) ?? '0.00'}', 
                  style: TextStyle(color: Colors.green)),
                Text('Avg Rainfall: ${averages['rainfallAvg']?.toStringAsFixed(2) ?? '0.00'}', 
                  style: TextStyle(color: Colors.blue)),
              ],
            ),
            SizedBox(height: 20),
            // Make charts larger and more prominent
            SizedBox(
              height: 300, // Increased height
              child: SfCartesianChart(
                title: ChartTitle(text: 'NPK Levels'),
                primaryXAxis: DateTimeAxis(title: AxisTitle(text: 'Date')),
                primaryYAxis: NumericAxis(title: AxisTitle(text: 'Concentration')),
                series: <LineSeries<NPKData, DateTime>>[
                  LineSeries<NPKData, DateTime>(
                    name: 'Nitrogen',
                    color: Colors.blue,
                    dataSource: _npkDataList,
                    xValueMapper: (NPKData data, _) => data.timestamp.toDate(),
                    yValueMapper: (NPKData data, _) => data.nitrogen,
                  ),
                  LineSeries<NPKData, DateTime>(
                    name: 'Phosphorus',
                    color: Colors.red,
                    dataSource: _npkDataList,
                    xValueMapper: (NPKData data, _) => data.timestamp.toDate(),
                    yValueMapper: (NPKData data, _) => data.phosphorus,
                  ),
                  LineSeries<NPKData, DateTime>(
                    name: 'Potassium',
                    color: Colors.green,
                    dataSource: _npkDataList,
                    xValueMapper: (NPKData data, _) => data.timestamp.toDate(),
                    yValueMapper: (NPKData data, _) => data.potassium,
                  ),
                ],
                legend: Legend(
                  isVisible: true, 
                  position: LegendPosition.bottom
                ),
              ),
            ),
            SizedBox(height: 20),
            // Larger rainfall chart
            SizedBox(
              height: 250, // Increased height
              child: SfCartesianChart(
                title: ChartTitle(text: 'Rainfall'),
                primaryXAxis: DateTimeAxis(title: AxisTitle(text: 'Date')),
                primaryYAxis: NumericAxis(title: AxisTitle(text: 'Rainfall')),
                series: <AreaSeries<NPKData, DateTime>>[
                  AreaSeries<NPKData, DateTime>(
                    name: 'Rainfall',
                    color: Colors.blue.withOpacity(0.3),
                    dataSource: _npkDataList,
                    xValueMapper: (NPKData data, _) => data.timestamp.toDate(),
                    yValueMapper: (NPKData data, _) => data.rainfall,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInsightsCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Agricultural Insights',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Colors.green[800]
              ),
            ),
            SizedBox(height: 10),
            Text(
              _geminiInsights,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NPKData {
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double rainfall;
  final Timestamp timestamp;

  NPKData({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.rainfall,
    required this.timestamp,
  });
}