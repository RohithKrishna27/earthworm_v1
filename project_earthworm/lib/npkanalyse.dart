import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class NPKAnalysisScreen extends StatefulWidget {
  @override
  _NPKAnalysisScreenState createState() => _NPKAnalysisScreenState();
}

class _NPKAnalysisScreenState extends State<NPKAnalysisScreen> {
  Map<String, dynamic> _npkData = {};
  String _geminiInsights = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentNPKData();
  }

  Future<void> _fetchCurrentNPKData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DatabaseReference sensorRef = 
        FirebaseDatabase.instance.ref('sensorData');
      
      final snapshot = await sensorRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Focus only on NPK data
        setState(() {
          _npkData = {
            'nitrogen': data['N'] ?? 0,
            'phosphorus': data['P'] ?? 0,
            'potassium': data['K'] ?? 0,
          };
          _isLoading = false;
        });

        // Generate Gemini NPK insights
        await _generateNPKInsights();
      } else {
        setState(() {
          _isLoading = false;
          _geminiInsights = 'No NPK data available';
        });
      }
    } catch (e) {
      print('Error fetching NPK data: $e');
      setState(() {
        _isLoading = false;
        _npkData = {};
        _geminiInsights = 'Unable to fetch NPK data: $e';
      });
    }
  }

  Future<void> _generateNPKInsights() async {
    if (_npkData.isEmpty) return;

    // Prepare data for Gemini analysis
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
                Analyze the following NPK soil nutrient data:

                $dataDescription

                Provide comprehensive insights focusing exclusively on:
                1. Current NPK nutrient levels and their balance
                2. Interpretation of nitrogen, phosphorus, and potassium concentrations
                3. Recommended nutrient amendments
                4. Potential impact on crop growth based on NPK levels
                5. Specific fertilization strategies
                
                Respond in a concise, actionable agricultural format.
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
    return '''
    NPK Soil Nutrient Analysis:
    - Nitrogen (N): ${_npkData['nitrogen']}
    - Phosphorus (P): ${_npkData['phosphorus']}
    - Potassium (K): ${_npkData['potassium']}
    
    Timestamp: ${DateTime.now()}
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NPK Soil Nutrient Analysis'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchCurrentNPKData,
          )
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current NPK Levels',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                // Display NPK data
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _npkData.entries.map((entry) => 
                        Text('${entry.key}: ${entry.value}')
                      ).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'AI NPK Insights',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  _geminiInsights,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
    );
  }
}