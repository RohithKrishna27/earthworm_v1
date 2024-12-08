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
  String _result = ''; // Result after submission

  bool _answered = false; // To track if the question is answered
  bool _isLoading = false; // To track the loading state

  @override
  void initState() {
    super.initState();
    _fetchQuizData();
  }

  // Fetch quiz data from Gemini API based on the selected topic
  Future<void> _fetchQuizData() async {
    setState(() {
      _isLoading = true; // Show loading screen when fetching data
      _answered = false; // Reset answered flag before fetching new data
    });

    try {
      final response = await http.post(
        Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyCAGtWDRBB3dQf9eqiJLqAsjrUHpQB3seI"), // Replace with your valid API key
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Generate a quiz based on the topic '${widget.topic}'. The response should contain:\n"
                          "- A question (first line),\n"
                          "- Four options (second line, separated by commas),\n"
                          "- The correct answer (third line, format exactly like in the option),\n"
                          "- An explanation (fourth line).\n"
                          "Please do not use ** for bold formatting."
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String fullResponse = responseData['candidates'][0]['content']['parts'][0]['text'];

        // Split and clean the response
        List<String> responseParts = fullResponse.split("\n").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        // Ensure the response has at least 4 parts: question, options, correct answer, explanation
        if (responseParts.length >= 4) {
          setState(() {
            _question = responseParts[0]; // Question comes first
            _options = responseParts[1].split(",").map((option) => option.trim()).toList(); // Options come second (split by commas)
            _correctAnswer = responseParts[2].replaceFirst("Correct answer: ", "").trim(); // Correct answer comes third
            _explanation = responseParts[3].trim(); // Explanation comes fourth
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
    } finally {
      setState(() {
        _isLoading = false; // Hide loading screen once data is fetched
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
      _answered = true;
      if (_selectedAnswer == _correctAnswer) {
        _result = 'Correct!';
      } else {
        _result = 'Incorrect. The correct answer is $_correctAnswer.';
      }
    });
  }

  // Handle the next question
  void _nextQuestion() {
    setState(() {
      _isLoading = true; // Show loading screen before fetching new data
      _question = ''; // Clear the question
      _options = []; // Clear the options
      _correctAnswer = ''; // Clear the correct answer
      _explanation = ''; // Clear the explanation
      _selectedAnswer = null; // Clear the selected answer
      _result = ''; // Clear the result
      _answered = false; // Reset answered flag
    });
    // Fetch new question data
    _fetchQuizData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.topic}'),
      ),
      body: SingleChildScrollView( // Wrap the body in a SingleChildScrollView
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display loading indicator if question is not yet loaded
            if (_isLoading) 
              Center(child: CircularProgressIndicator()),

            // Display question with icon before it
            if (_question.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.question_mark, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _question,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 20),
            
            // Display options as radio buttons
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
            
            // Submit button
            ElevatedButton(
              onPressed: _submitQuiz,
              child: Text('Submit'),
            ),
            
            SizedBox(height: 20),

            // Show the result (correct or incorrect)
            if (_answered)
              Text(
                _result,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: _result == 'Correct!' ? Colors.green : Colors.red, // Green for correct, red for incorrect
                ),
              ),
            
            SizedBox(height: 20),

            // Show the correct answer and explanation after submission
            if (_answered)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Correct Answer: $_correctAnswer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Explanation: $_explanation',
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            
            SizedBox(height: 20),

            // Show Next Question button only after answering
            if (_answered)
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text('Next Question'),
              ),
          ],
        ),
      ),
    );
  }
}
