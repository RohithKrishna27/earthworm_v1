import 'package:flutter/material.dart';
import 'package:project_earthworm/farmer/CropAnalysisScreen.dart';
import 'package:project_earthworm/npkanalyse.dart';

class Language {
  static const String english = 'en';
  static const String kannada = 'kn';
  static const String hindi = 'hi';
}

class KhrishiMitraHome extends StatefulWidget {
  @override
  _KhrishiMitraHomeState createState() => _KhrishiMitraHomeState();
}

class _KhrishiMitraHomeState extends State<KhrishiMitraHome> {
  String _currentLanguage = Language.english;

  // Multilingual text mappings
  Map<String, Map<String, String>> _languageTexts = {
    Language.english: {
      'title': 'Khrishi Mitra',
      'welcome': 'Welcome to Khrishi Mitra',
      'select': 'Select an option:',
      'microclimate': 'Microclimate Weather of Your Farm Land',
      'crop_suggestion': 'Crop Suggestion',
      'npk_values': 'NPK Values',
      'irrigation': 'Irrigation and Important Alerts',
    },
    Language.kannada: {
      'title': 'ಖೃಷಿ ಮಿತ್ರ',
      'welcome': 'ಖೃಷಿ ಮಿತ್ರಕ್ಕೆ ಸ್ವಾಗತ',
      'select': 'ಒಂದು ಆಯ್ಕೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ:',
      'microclimate': 'ನಿಮ್ಮ ಕೃಷಿ ಭೂಮಿಯ ಹವಾಮಾನ',
      'crop_suggestion': 'ಬೆಳೆ ಸಲಹೆ',
      'npk_values': 'NPK ಮೌಲ್ಯಗಳು',
      'irrigation': 'ನೀರಾವರಿ ಮತ್ತು ಮಹತ್ವಪೂರ್ಣ ಎಚ್ಚರಿಕೆಗಳು',
    },
    Language.hindi: {
      'title': 'कृषि मित्र',
      'welcome': 'कृषि मित्र में स्वागत है',
      'select': 'एक विकल्प चुनें:',
      'microclimate': 'अपने खेत की सूक्ष्म जलवायु',
      'crop_suggestion': 'फसल सुझाव',
      'npk_values': 'NPK मान',
      'irrigation': 'सिंचाई और महत्वपूर्ण चेतावनियां',
    },
  };

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_languageTexts[_currentLanguage]!['title']!),
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: Language.english,
                child: Text('English'),
              ),
              PopupMenuItem(
                value: Language.kannada,
                child: Text('ಕನ್ನಡ (Kannada)'),
              ),
              PopupMenuItem(
                value: Language.hindi,
                child: Text('हिन्दी (Hindi)'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _languageTexts[_currentLanguage]!['welcome']!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              _languageTexts[_currentLanguage]!['select']!,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            OptionButton(
              title: _languageTexts[_currentLanguage]!['microclimate']!,
              icon: Icons.cloud,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CropAnalysisScreen(),
                  ),
                );
              },
            ),
            OptionButton(
              title: _languageTexts[_currentLanguage]!['crop_suggestion']!,
              icon: Icons.grass,
              onTap: () {
Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CropAnalysisScreen(),
                  ),
                );              },
            ),
            OptionButton(
              title: _languageTexts[_currentLanguage]!['npk_values']!,
              icon: Icons.science,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NPKAnalysisScreen(),
                  ),
                ); 
                
              },
            ),
            OptionButton(
              title: _languageTexts[_currentLanguage]!['irrigation']!,
              icon: Icons.water_drop,
              onTap: () {
                // Navigate to Irrigation and Alerts screen
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OptionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const OptionButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.green),
        onTap: onTap,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: KhrishiMitraHome(),
    theme: ThemeData(primarySwatch: Colors.green),
  ));
}
