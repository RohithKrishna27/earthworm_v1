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
  late String _question;
  late List<String> _options;
  late String _correctAnswer;
  String? _selectedAnswer; // Make this nullable to match the Radio widget
  String _result = '';

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  // Fetch question and options from Gemini API based on the selected topic
  Future<void> _fetchQuizData() async {
    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyCAGtWDRBB3dQf9eqiJLqAsjrUHpQB3seI"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": "Create a quiz question based on the topic '${widget.topic}', and include 4 options and the correct answer."}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Assuming the response contains a question and options
        final String question = responseData['candidates'][0]['content']['parts'][0]['text'];
        final List<String> options = ["Option 1", "Option 2", "Option 3", "Option 4"]; // Replace with actual response options
        final String correctAnswer = "Option 1"; // Replace with the actual correct answer from the API response

        setState(() {
          _question = question;
          _options = options;
          _correctAnswer = correctAnswer;
        });
      } else {
        setState(() {
          _question = "Failed to fetch quiz question.";
          _options = [];
          _correctAnswer = "";
        });
      }
    } catch (e) {
      setState(() {
        _question = "Error fetching quiz data: $e";
        _options = [];
        _correctAnswer = "";
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
            Text(
              _question.isNotEmpty ? _question : 'Loading question...',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            if (_options.isNotEmpty)
              ..._options.map((option) {
                return ListTile(
                  title: Text(option),
                  leading: Radio<String?>(
                    value: option,
                    groupValue: _selectedAnswer,
                    onChanged: _onAnswerSelected, // Now works with nullable String?
                  ),
                );
              }).toList(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitQuiz,
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
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
