import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_earthworm/farmer/SellingCrops/orderSummay.dart';

class AICropAnalysisPage extends StatefulWidget {
  final Map<String, dynamic> formData;

  const AICropAnalysisPage({Key? key, required this.formData}) : super(key: key);

  @override
  _AICropAnalysisPageState createState() => _AICropAnalysisPageState();
}

class _AICropAnalysisPageState extends State<AICropAnalysisPage> {
  int currentImageIndex = 0;
  List<String> cloudinaryUrls = [];
  List<Map<String, dynamic>> analysisResults = [];
  bool isLoading = false;
  String selectedLanguage = 'English';
  
  // Your Gemini API key - store this securely
  final String geminiApiKey = 'AIzaSyBHZH-qGsEjnyoKDcpCM-BzfLIr9YdUJkU';
  
  final Map<String, Map<String, String>> translations = {
    'English': {
      'title': 'AI Quality Analysis',
      'instruction': 'Please take 3 clear photos of your crop from different angles',
      'photo': 'Take Photo',
      'gallery': 'Choose from Gallery',
      'progress': 'Photo of 3',
      'analyzing': 'Analyzing image...',
      'upload': 'Uploading image...',
      'next': 'Next Photo',
      'complete': 'Complete Analysis',
    },
    'हिंदी': {
      'title': 'एआई गुणवत्ता विश्लेषण',
      'instruction': 'कृपया अपनी फसल की 3 स्पष्ट तस्वीरें अलग-अलग कोणों से लें',
      'photo': 'फोटो लें',
      'gallery': 'गैलरी से चुनें',
      'progress': 'फोटो  में से 3',
      'analyzing': 'छवि का विश्लेषण किया जा रहा है...',
      'upload': 'छवि अपलोड की जा रही है...',
      'next': 'अगली फोटो',
      'complete': 'विश्लेषण पूरा करें',
    },
    'ಕನ್ನಡ': {
      'title': 'AI ಗುಣಮಟ್ಟ ವಿಶ್ಲೇಷಣೆ',
      'instruction': 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಬೆಳೆಯ 3 ಸ್ಪಷ್ಟ ಫೋಟೋಗಳನ್ನು ವಿಭಿನ್ನ ಕೋನಗಳಿಂದ ತೆಗೆದುಕೊಳ್ಳಿ',
      'photo': 'ಫೋಟೋ ತೆಗೆಯಿರಿ',
      'gallery': 'ಗ್ಯಾಲರಿಯಿಂದ ಆಯ್ಕೆಮಾಡಿ',
      'progress': 'ಫೋಟೋ / 3',
      'analyzing': 'ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...',
      'upload': 'ಚಿತ್ರವನ್ನು ಅಪ್‌ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'next': 'ಮುಂದಿನ ಫೋಟೋ',
      'complete': 'ವಿಶ್ಲೇಷಣೆ ಪೂರ್ಣಗೊಳಿಸಿ',
    },
  };

  Future<String> uploadToCloudinary(File imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/des6gx3es/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'xy1q3pre'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final jsonData = jsonDecode(response.body);
    return jsonData['secure_url'];
  }

  Future<Map<String, dynamic>> analyzeImageWithGemini(String imageUrl) async {
  final String cropType = widget.formData['cropDetails']['cropType'];
  
  // First get the image data from the URL
  final http.Response imageResponse = await http.get(Uri.parse(imageUrl));
  if (imageResponse.statusCode != 200) {
    throw Exception('Failed to download image from Cloudinary');
  }
  
  // Convert image data to base64
  final String base64Image = base64Encode(imageResponse.bodyBytes);
  
  // Create prompt for Gemini API that specifies what we need
  final prompt = '''
  Analyze this $cropType crop image and provide detailed assessment on the following quality parameters. 
  Rate each parameter on a scale of 0.0 to 0.9 (where 0.9 is excellent quality):
  
  1. Batch_Consistency: How uniform the crop samples are
  2. Color: How appropriate and vibrant the color is for this crop type
  3. Firmness: How firm and not overripe the crop appears
  4. Shape_and_Size: How ideal the shape and size are for this crop type
  5. Texture: How appropriate the surface texture appears
  6. Damaged: Amount of visible damage, blemishes or disease (0.0 means no damage, 0.9 means extensive damage)
  
  Provide results in JSON format with only these keys and numerical values.
  ''';

  // Define the request body
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': prompt},
          {
            'inline_data': {
              'mime_type': 'image/jpeg',
              'data': base64Image
            }
          }
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.1,
      'topK': 32,
      'topP': 1,
      'maxOutputTokens': 4096,
    }
  };

  // Make the API request
  final response = await http.post(
  Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$geminiApiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(requestBody),
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    
    try {
      // Extract the text content from the response
      final textContent = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      print('API Response: $textContent'); // Add this for debugging
      
      // Try to find JSON in the response
      // First, try to parse the entire text as JSON
      try {
        final parsedJson = jsonDecode(textContent);
        return _normalizeAnalysisResult(parsedJson);
      } catch (e) {
        // If that fails, try to extract JSON from markdown code blocks
        final jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
        final match = jsonRegex.firstMatch(textContent);
        
        if (match != null && match.group(1) != null) {
          final jsonText = match.group(1)!.trim();
          try {
            final parsedJson = jsonDecode(jsonText);
            return _normalizeAnalysisResult(parsedJson);
          } catch (e) {
            print('Error parsing extracted JSON: $e');
          }
        }
        
        // If that fails, try to find any JSON-like structure
        final braceRegex = RegExp(r'{[\s\S]*?}');
        final braceMatch = braceRegex.firstMatch(textContent);
        
        if (braceMatch != null) {
          try {
            final parsedJson = jsonDecode(braceMatch.group(0)!);
            return _normalizeAnalysisResult(parsedJson);
          } catch (e) {
            print('Error parsing JSON from braces: $e');
          }
        }
      }
    } catch (e) {
      print('Error processing API response: $e');
    }
  } else {
    print('API Error: ${response.statusCode}, ${response.body}');
  }
  
    // Return default values if anything fails
    return {
      'Batch_Consistency': 0.5,
      'Color': 0.5,
      'Firmness': 0.5,
      'Shape_and_Size': 0.5,
      'Texture': 0.5,
      'Damaged': 0.3,
    };
  }

  Map<String, double> calculateAverageResults() {
    Map<String, double> averages = {};
    // Parameters to consider for average (excluding Damaged)
    final parameters = [
      'Batch_Consistency', 'Color', 'Firmness',
      'Shape_and_Size', 'Texture'
    ];

    // Calculate individual parameter averages
    for (var param in parameters) {
      double sum = 0;
      for (var result in analysisResults) {
        sum += (result[param] ?? 0) * 10 + 1;
      }
      averages[param] = sum / analysisResults.length;
    }

    // Add damaged score separately (not included in overall average)
    double damagedSum = 0;
    for (var result in analysisResults) {
      damagedSum += (result['Damaged'] ?? 0) * 10 + 1;
    }
    averages['Damaged'] = damagedSum / analysisResults.length;

    // Calculate overall quality as average of parameters (excluding Damaged)
    double totalSum = parameters.fold(0.0, (sum, param) => sum + averages[param]!);
    averages['Overall_Quality'] = totalSum / parameters.length;

    return averages;
  }

  // Helper method to normalize the analysis result
Map<String, dynamic> _normalizeAnalysisResult(Map<String, dynamic> raw) {
  return {
    'Batch_Consistency': _parseDouble(raw['Batch_Consistency']) ?? 0.6,
    'Color': _parseDouble(raw['Color']) ?? 0.6,
    'Firmness': _parseDouble(raw['Firmness']) ?? 0.6,
    'Shape_and_Size': _parseDouble(raw['Shape_and_Size']) ?? 0.6,
    'Texture': _parseDouble(raw['Texture']) ?? 0.6,
    'Damaged': _parseDouble(raw['Damaged']) ?? 0.3,
  };
}


  Future<void> processImage(ImageSource source) async {
    try {
      setState(() => isLoading = true);
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
      );
      
      if (image == null) {
        setState(() => isLoading = false);
        return;
      }

      // Show uploading status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations[selectedLanguage]!['upload']!)),
      );

      // Upload to Cloudinary
      final cloudinaryUrl = await uploadToCloudinary(File(image.path));
      cloudinaryUrls.add(cloudinaryUrl);

      // Show analyzing status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations[selectedLanguage]!['analyzing']!)),
      );

      // Analyze image with Gemini
      final analysis = await analyzeImageWithGemini(cloudinaryUrl);
      analysisResults.add(analysis);

      // Update progress
      setState(() {
        currentImageIndex++;
        isLoading = false;
      });

      // If all images are processed, save to Firebase and show results
      if (currentImageIndex == 3) {
        await saveToFirebase();
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}
  Future<void> saveToFirebase() async {
    try {
      final averageResults = calculateAverageResults();
      final mspDetails = widget.formData['cropDetails']['mspCompliance'];
      final expectedPrice = widget.formData['cropDetails']['expectedPrice'] as double;

      final cropSaleRef = await FirebaseFirestore.instance
          .collection('crop_analysis')
          .add({
            'userId': widget.formData['farmerDetails']['farmerId'],
            'farmerName': widget.formData['farmerDetails']['name'],
            'farmerPhone': widget.formData['farmerDetails']['phone'],
            'cropType': widget.formData['cropDetails']['cropType'],
            'quantity': widget.formData['cropDetails']['weight'],
            'expectedPrice': expectedPrice,
            'location': {
              'state': widget.formData['location']['state'],
              'district': widget.formData['location']['district'],
              'apmcMarket': widget.formData['location']['apmcMarket'],
            },
            // Add MSP details
            'mspDetails': {
              'mspPrice': mspDetails['mspPrice'],
              'isAboveMSP': mspDetails['isAboveMSP'],
              'mspDifference': expectedPrice - (mspDetails['mspPrice'] as num),
              'percentageAboveMSP': ((expectedPrice - (mspDetails['mspPrice'] as num)) / (mspDetails['mspPrice'] as num) * 100).toStringAsFixed(2) + '%'
            },
            'imageUrls': cloudinaryUrls,
            'analysisResults': analysisResults,
            'averageResults': averageResults,
            'isGroupFarming': widget.formData['groupFarming']['isGroupFarming'],
            'groupMembers': widget.formData['groupFarming']['members'],
            'address': widget.formData['address'],
            'description': widget.formData['description'],
            'status': 'pending',
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Create a new Map to avoid modifying widget.formData directly
      final updatedFormData = Map<String, dynamic>.from(widget.formData);
      updatedFormData['analysisResults'] = {
        'imageUrls': cloudinaryUrls,
        'results': averageResults,
        'analysisId': cropSaleRef.id
      };

      // Navigate to results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsPage(
            averages: averageResults,
            cropType: widget.formData['cropDetails']['cropType'],
            imageUrls: cloudinaryUrls,
            formData: updatedFormData,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translations[selectedLanguage]!['title']!),
        backgroundColor: Colors.green,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: selectedLanguage,
              dropdownColor: Colors.green,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              icon: const Icon(Icons.language, color: Colors.white),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => selectedLanguage = newValue);
                }
              },
              items: ['English', 'हिंदी', 'ಕನ್ನಡ'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              translations[selectedLanguage]!['instruction']!,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Progress indicator
            LinearProgressIndicator(
              value: currentImageIndex / 3,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 12),
            Text(
              "${currentImageIndex + 1} ${translations[selectedLanguage]!['progress']!.replaceAll("of", "")}",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // Image selection buttons
            if (!isLoading) ...[
              ElevatedButton.icon(
                onPressed: () => processImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: Text(
                  translations[selectedLanguage]!['photo']!,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  minimumSize: const Size(240, 48),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => processImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: Text(
                  translations[selectedLanguage]!['gallery']!,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  minimumSize: const Size(240, 48),
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                isLoading ? translations[selectedLanguage]!['analyzing']! : "",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ],
            
            const Spacer(),
            
            // Show thumbnails of uploaded images
            if (cloudinaryUrls.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Uploaded Images:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cloudinaryUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          cloudinaryUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ResultsPage extends StatelessWidget {
  final Map<String, double> averages;
  final String cropType;
  final List<String> imageUrls;
  final Map<String, dynamic> formData;

  const ResultsPage({
    Key? key,
    required this.averages,
    required this.cropType,
    required this.imageUrls,
    required this.formData,
  }) : super(key: key);

  String getQualityText(double score) {
    if (score >= 9.0) return 'Excellent';
    if (score >= 7.5) return 'Very Good';
    if (score >= 6.0) return 'Good';
    if (score >= 5.0) return 'Average';
    if (score >= 3.5) return 'Below Average';
    return 'Poor';
  }

  Color getQualityColor(double score) {
    if (score >= 9.0) return Colors.green;
    if (score >= 7.5) return Colors.green[700]!;
    if (score >= 6.0) return Colors.lime;
    if (score >= 5.0) return Colors.amber;
    if (score >= 3.5) return Colors.orange;
    return Colors.red;
  }

  // Calculates adjusted price based on quality
  double calculateAdjustedPrice() {
    final basePrice = formData['cropDetails']['expectedPrice'] as double;
    final qualityFactor = (averages['Overall_Quality']! - 5) / 5;  // -1 to 1 range
    final adjustment = basePrice * qualityFactor * 0.15;  // Max 15% adjustment
    return basePrice + adjustment;
  }

  @override
  Widget build(BuildContext context) {
    final adjustedPrice = calculateAdjustedPrice();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Analysis Results'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall quality card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Overall Quality',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: getQualityColor(averages['Overall_Quality']!),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            averages['Overall_Quality']!.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '/10',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      getQualityText(averages['Overall_Quality']!),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: getQualityColor(averages['Overall_Quality']!),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quality parameters
            Text(
              'Quality Parameters',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Parameter cards
            for (String param in ['Batch_Consistency', 'Color', 'Firmness', 'Shape_and_Size', 'Texture'])
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      param.replaceAll('_', ' '),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          averages[param]!.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: getQualityColor(averages[param]!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: getQualityColor(averages[param]!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Damage parameter card with inverted colors
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                elevation: 2,
                child: ListTile(
                  title: Text(
                    'Damage Level',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        averages['Damaged']!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          // Color is inverted for damage - higher is worse
                          color: getQualityColor(11 - averages['Damaged']!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 12,
                        // Color is inverted for damage - higher is worse
                        backgroundColor: getQualityColor(11 - averages['Damaged']!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Price adjustment section
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Adjustment',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Base Price:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
<<<<<<< Updated upstream
                          '₹${formData['cropDetails']['expectedPrice']} per quintal',
=======
                          '₹${formData['cropDetails']['expectedPrice']} per Quintal',
>>>>>>> Stashed changes
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quality Adjusted:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          '₹${adjustedPrice.toStringAsFixed(2)} per Quintal',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: adjustedPrice >= formData['cropDetails']['expectedPrice'] 
                                ? Colors.green 
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adjustment:',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        Text(
                          '${((adjustedPrice / formData['cropDetails']['expectedPrice'] - 1) * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: adjustedPrice >= formData['cropDetails']['expectedPrice'] 
                                ? Colors.green 
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Image gallery
            Text(
              'Analyzed Images',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Image.network(imageUrls[index]),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Continue button
          // Continue button
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: () {
      // Update form data with adjusted price
      final updatedFormData = Map<String, dynamic>.from(formData);
      updatedFormData['cropDetails']['adjustedPrice'] = adjustedPrice;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderSummaryPage(
            formData: updatedFormData,
            qualityScores: averages,
            imageUrls: imageUrls,
            isDirectSale: true, // You may need to determine this value from your app logic
          ),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    child: Text(
      'Continue to Order Summary',
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}