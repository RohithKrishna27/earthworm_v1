import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum Language { English, Kannada, Hindi }

class CropAnalysisScreen extends StatefulWidget {
  @override
  _CropAnalysisScreenState createState() => _CropAnalysisScreenState();
}

class _CropAnalysisScreenState extends State<CropAnalysisScreen> {
  Language _selectedLanguage = Language.English;
  String _aiCropSuggestion = '';
  String _seedVarietyDetails = '';
  String _geminiResponseForCrop = '';
  String _geminiResponseForVariety = '';

  // Define translations for the texts
  final Map<Language, Map<String, String>> _localizedStrings = {
    Language.English: {
      'ai_crop_suggestion': 'AI Crop Suggestion',
      'n_label': 'Nitrogen (N)',
      'p_label': 'Phosphorus (P)',
      'k_label': 'Potassium (K)',
      'temperature_label': 'Temperature (°C)',
      'humidity_label': 'Humidity (%)',
      'ph_label': 'pH',
      'rainfall_label': 'Rainfall (mm)',
      'get_suggestion': 'Get Suggestion',
      'seed_variety_analyzer': 'Seed Variety Analyzer',
      'crop_name': 'Crop Name',
      'state': 'State',
      'search': 'Search',
      'description': 'Description',
      'features': 'Features',
      'states': 'States',
      'translator': 'Select Language',
      'gemini_explanation': 'Gemini API Explanation',
    },
    Language.Kannada: {
      'ai_crop_suggestion': 'ಎಐ ಬೆಳೆ ಸಲಹೆ',
      'n_label': 'ನೈಟ್ರೋಜನ್ (N)',
      'p_label': 'ಫಾಸ್ಪರಸ್ (P)',
      'k_label': 'ಪೊಟ್ಯಾಸಿಯಮ್ (K)',
      'temperature_label': 'ತಾಪಮಾನ (°C)',
      'humidity_label': 'ಆರ್ದ್ರತೆ (%)',
      'ph_label': 'pH',
      'rainfall_label': 'ಮಳೆ (mm)',
      'get_suggestion': 'ಸಲಹೆ ಪಡೆಯಿರಿ',
      'seed_variety_analyzer': 'ಬೀಜ ವೈವಿಧ್ಯತೆಗಳು ವಿಶ್ಲೇಷಣೆ',
      'crop_name': 'ಬೆಳೆ ಹೆಸರು',
      'state': 'ರಾಜ್ಯ',
      'search': 'ಹುಡುಕು',
      'description': 'ವಿವರಣೆ',
      'features': 'ಲಕ್ಷಣಗಳು',
      'states': 'ರಾಜ್ಯಗಳು',
      'translator': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
      'gemini_explanation': 'ಜೆಮಿನಿ ಎಪಿಐ ವಿವರಣೆ',
    },
    Language.Hindi: {
      'ai_crop_suggestion': 'एआई फसल सुझाव',
      'n_label': 'नाइट्रोजन (N)',
      'p_label': 'फॉस्फोरस (P)',
      'k_label': 'पोटाशियम (K)',
      'temperature_label': 'तापमान (°C)',
      'humidity_label': 'नमी (%)',
      'ph_label': 'pH',
      'rainfall_label': 'वर्षा (mm)',
      'get_suggestion': 'सुझाव प्राप्त करें',
      'seed_variety_analyzer': 'बीज वैराइटी विश्लेषिका',
      'crop_name': 'फसल का नाम',
      'state': 'राज्य',
      'search': 'खोज',
      'description': 'विवरण',
      'features': 'विशेषताएँ',
      'states': 'राज्य',
      'translator': 'भाषा चुनें',
      'gemini_explanation': 'जेमिनी एपीआई विवरण',
    },
  };

  final TextEditingController _nController = TextEditingController();
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _kController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();

  String _selectedCrop = 'Rice';
  String _selectedState = 'Punjab';

  Future<void> _fetchAICropSuggestion() async {
    try {
      final response = await http.post(
        Uri.parse("https://crop-prediction-apij.onrender.com/predict"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "N": int.tryParse(_nController.text) ?? 0,
          "P": int.tryParse(_pController.text) ?? 0,
          "K": int.tryParse(_kController.text) ?? 0,
          "temperature": double.tryParse(_temperatureController.text) ?? 0,
          "humidity": double.tryParse(_humidityController.text) ?? 0,
          "ph": double.tryParse(_phController.text) ?? 0,
          "rainfall": double.tryParse(_rainfallController.text) ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          // Access the prediction and confidence directly from the response
          final prediction = responseData['prediction'];
          final confidence = responseData['confidence'];

          _aiCropSuggestion = "Suggested Crop: $prediction with confidence: $confidence.";
          // Call Gemini API here for the crop prediction
          _fetchGeminiResponseForCrop(prediction);
        });
      } else {
        setState(() {
          _aiCropSuggestion = "Failed to fetch suggestion. Status code: ${response.statusCode}, Body: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _aiCropSuggestion = "Error fetching suggestion: $e";
      });
    }
  }

  Future<void> _fetchGeminiResponseForCrop(String cropPrediction) async {
    // Customize your prompt based on the cropPrediction
    String prompt = "Give me detailed information about $cropPrediction as a crop including its benefits, growing conditions, and best practices.";
    
    await _fetchGeminiResponse(prompt, true);
  }

  Future<void> _fetchSeedVarietyDetails() async {
    try {
      final response = await http.get(
        Uri.parse("https://seed-varities.onrender.com/advanced-search?crop_type=$_selectedCrop&state=$_selectedState"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          if (data.isNotEmpty) {
            // Access the first item in the response array
            final variety = data[0];
            _seedVarietyDetails = "Name: ${variety['Name of Variety']}, "
                "Features: ${variety['Salient Features']}, "
                "States: ${variety['States']}";
            // Call Gemini API for seed variety
            _fetchGeminiResponseForVariety(variety['Name of Variety']);
          } else {
            _seedVarietyDetails = "No varieties found.";
          }
        });
      } else {
        setState(() {
          _seedVarietyDetails = "Failed to fetch seed variety details. Status code: ${response.statusCode}, Body: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _seedVarietyDetails = "Error fetching seed varieties: $e";
      });
    }
  }

  Future<void> _fetchGeminiResponseForVariety(String varietyName) async {
    // Customize your prompt based on the varietyName
    String prompt = "Provide detailed information about the seed variety: $varietyName including its benefits and cultivation practices.";
    
    await _fetchGeminiResponse(prompt, false);
  }

  Future<void> _fetchGeminiResponse(String prompt, bool isForCrop) async {
    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyCAGtWDRBB3dQf9eqiJLqAsjrUHpQB3seI"), // Replace with your actual Gemini API endpoint
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          String geminiResponse = responseData['candidates']?[0]['content']?['parts']?[0]['text'] ?? "No additional information found.";
          if (isForCrop) {
            _geminiResponseForCrop = geminiResponse;
          } else {
            _geminiResponseForVariety = geminiResponse;
          }
        });
      } else {
        setState(() {
          if (isForCrop) {
            _geminiResponseForCrop = "Failed to fetch Gemini response. Status code: ${response.statusCode}, Body: ${response.body}";
          } else {
            _geminiResponseForVariety = "Failed to fetch Gemini response. Status code: ${response.statusCode}, Body: ${response.body}";
          }
        });
      }
    } catch (e) {
      setState(() {
        if (isForCrop) {
          _geminiResponseForCrop = "Error fetching Gemini response: $e";
        } else {
          _geminiResponseForVariety = "Error fetching Gemini response: $e";
        }
      });
    }
  }

  void _switchLanguage(Language? newLanguage) {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = Color(0xFF66BB6A); // Vibrant green
    final Color secondaryGreen = Color(0xFF1B5E20); // Dark green
    final Color backgroundColor = Color(0xFFF1F8E9); // Light green background
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Crop Analysis'),
        actions: [
          DropdownButton<Language>(
            value: _selectedLanguage,
            items: Language.values.map((Language language) {
              return DropdownMenuItem<Language>(
                value: language,
                child: Text(language.toString().split('.').last), // Displaying language name
              );
            }).toList(),
            onChanged: _switchLanguage,
            dropdownColor: Colors.white,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),
              // AI Crop Suggestion Section
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
                      _localizedStrings[_selectedLanguage]!['ai_crop_suggestion']!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: secondaryGreen,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['n_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _pController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['p_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _kController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['k_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _temperatureController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['temperature_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _humidityController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['humidity_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _phController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['ph_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _rainfallController,
                      decoration: InputDecoration(
                        labelText: _localizedStrings[_selectedLanguage]!['rainfall_label'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchAICropSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                      ),
                      child: Text(
                        _localizedStrings[_selectedLanguage]!['get_suggestion']!,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _aiCropSuggestion.isEmpty ? "No suggestions available." : _aiCropSuggestion,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _geminiResponseForCrop.isEmpty ? "No details from Gemini." : _geminiResponseForCrop,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              // Seed Variety Analyzer Section
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
                      _localizedStrings[_selectedLanguage]!['seed_variety_analyzer']!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: secondaryGreen,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButton<String>(
                      value: _selectedCrop,
                      items: ['Rice', 'Maize', 'Wheat', 'Groundnut', 'Cotton', 'Sugar-Cane']
                          .map((String crop) {
                        return DropdownMenuItem<String>(
                          value: crop,
                          child: Text(crop),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCrop = newValue!;
                        });
                      },
                      hint: Text(_localizedStrings[_selectedLanguage]!['crop_name']!),
                    ),
                    DropdownButton<String>(
                      value: _selectedState,
                      items: ['Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal']
                          .map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedState = newValue!;
                        });
                      },
                      hint: Text(_localizedStrings[_selectedLanguage]!['state']!),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSeedVarietyDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                      ),
                      child: Text(
                        _localizedStrings[_selectedLanguage]!['search']!,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _seedVarietyDetails.isEmpty ? "No details available." : _seedVarietyDetails,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _geminiResponseForVariety.isEmpty ? "No details from Gemini." : _geminiResponseForVariety,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}