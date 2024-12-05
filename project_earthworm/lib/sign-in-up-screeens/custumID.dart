import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUserIDPage extends StatefulWidget {
  final String uid;
  final String userType;

  const CustomUserIDPage({Key? key, required this.uid, required this.userType})
      : super(key: key);

  @override
  _CustomUserIDPageState createState() => _CustomUserIDPageState();
}

class _CustomUserIDPageState extends State<CustomUserIDPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  // Prevent going back
  Future<bool> _onWillPop() async {
    return false; // Disable back button
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[200]!,
                Colors.white,
                Colors.green[200]!,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Complete Your Registration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildCustomUserIDForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomUserIDForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            'Choose a Unique User ID',
            style: TextStyle(
              fontSize: 18,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _userIdController,
            decoration: InputDecoration(
              labelText: 'Unique User ID',
              hintText: 'Choose a memorable username',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'User ID is required';
              }
              if (value.length < 3) {
                return 'User ID must be at least 3 characters';
              }
              if (value.length > 20) {
                return 'User ID cannot exceed 20 characters';
              }
              if (value.contains(' ')) {
                return 'User ID cannot contain spaces';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Only letters, numbers, and underscores allowed';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ],
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleCustomUserID,
            child: _isLoading
                ? CircularProgressIndicator()
                : Text('Complete Registration'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCustomUserID() async {
    // Reset error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Lowercase the user ID for consistency
      final lowercaseUserID = _userIdController.text.toLowerCase().trim();

      // Check if user ID is already taken
      final userIdSnapshot =
          await _firestore.collection('usernames').doc(lowercaseUserID).get();

      if (userIdSnapshot.exists) {
        setState(() {
          _errorMessage = 'This User ID is already taken';
          _isLoading = false;
        });
        return;
      }

      // Update user document with custom user ID
      await _firestore.collection('users').doc(widget.uid).update({
        'customUserID': lowercaseUserID,
        'registrationStatus': 'complete',
      });

      // Reserve the username
      await _firestore.collection('usernames').doc(lowercaseUserID).set({
        'uid': widget.uid,
        'userType': widget.userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to appropriate home page
      if (widget.userType == 'farmer') {
        Navigator.pushReplacementNamed(context, '/farmer/home');
      } else if (widget.userType == 'buyer') {
        Navigator.pushReplacementNamed(context, '/buyer/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
