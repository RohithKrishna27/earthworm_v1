import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizPage extends StatefulWidget {
  final String topic;

  QuizPage({required this.topic});

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  String _question = ''; // Initialize with an empty string
  List<String> _options = []; // Initialize with an empty list
  String _correctAnswer = ''; // Initialize with an empty string
  String _explanation = ''; // Initialize with an empty string
  String? _selectedAnswer; // Nullable to match the Radio widget
  String _result = '';
  
  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  // Fetch quiz data from Gemini API based on the selected topic
  Future<void> _fetchQuizData() async {
    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyCAGtWDRBB3dQf9eqiJLqAsjrUHpQB3seI"), // Use your valid API key here
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Generate a quiz based on the topic '${widget.topic}'. Include: "
                          "- The correct answer (first line), "
                          "- The question (second line), "
                          "- An explanation (third line), "
                          "- Four options (fourth line, separated by commas)."
                }
              ]
            }
          ]
        }),
      );

      // Log the status code and response body for debugging
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String fullResponse = responseData['candidates'][0]['content']['parts'][0]['text'];

        // Split the response based on line breaks (or another separator)
        List<String> responseParts = fullResponse.split("\n");

        // Ensure the response has at least 4 parts: answer, question, explanation, options
        if (responseParts.length >= 4) {
          setState(() {
            _correctAnswer = responseParts[0].replaceFirst("Correct answer: ", "");
            _question = responseParts[1];
            _explanation = responseParts[2];
            _options = responseParts[3].split(","); // Split options by commas
          });
        } else {
          setState(() {
            _question = "Error: Quiz data is incomplete.";
            _options = [];
            _correctAnswer = "";
            _explanation = "";
          });
        }
      } else {
        setState(() {
          _question = "Failed to fetch quiz question. Status code: ${response.statusCode}";
          _options = [];
          _correctAnswer = "";
          _explanation = "";
        });
      }
    } catch (e) {
      setState(() {
        _question = "Error fetching quiz data: $e";
        _options = [];
        _correctAnswer = "";
        _explanation = "";
      });
    }
  }

  // Handle answer selection
  void _onAnswerSelected(String? answer) {
    setState(() {
      _selectedAnswer = answer; // Nullable answer
    });
  }

  // Handle quiz submission and check if the answer is correct
  void _submitQuiz() {
    setState(() {
      if (_selectedAnswer == _correctAnswer) {
        _result = 'Correct!';
      } else {
        _result = 'Incorrect. The correct answer is $_correctAnswer.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.topic}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display loading text if question is not yet loaded
            if (_question.isEmpty) 
              Center(child: CircularProgressIndicator()),
            
            // Display question if it's available
            if (_question.isNotEmpty) 
              Text(
                _question,
                style: TextStyle(fontSize: 18),
              ),
            
            SizedBox(height: 20),
            
            // Display explanation if available
            if (_explanation.isNotEmpty)
              Text(
                "Explanation: $_explanation",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            
            SizedBox(height: 20),
            
            // Display options if available
            if (_options.isNotEmpty)
              ..._options.map((option) {
                return ListTile(
                  title: Text(option),
                  leading: Radio<String?>(
                    value: option,
                    groupValue: _selectedAnswer,
                    onChanged: _onAnswerSelected,
                  ),
                );
              }).toList(),
            
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _submitQuiz,
              child: Text('Submit'),
            ),
            
            SizedBox(height: 20),
            
            // Display result if available
            if (_result.isNotEmpty)
              Text(
                _result,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
