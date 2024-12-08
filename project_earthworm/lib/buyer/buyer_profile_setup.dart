import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerProfileSetup extends StatefulWidget {
  @override
  _BuyerProfileSetupState createState() => _BuyerProfileSetupState();
}

class _BuyerProfileSetupState extends State<BuyerProfileSetup> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Get user's phone and email from authentication
      final phone = user.phoneNumber ?? '';
      final email = user.email ?? '';

      await FirebaseFirestore.instance.collection('buyers').doc(user.uid).set({
        'company': _companyController.text,
        'address': _addressController.text,
        'state': _stateController.text,
        'district': _districtController.text,
        'pinCode': _pinCodeController.text,
        'gstNumber': _gstController.text,
        'phone': phone, // Add phone from auth
        'email': email, // Add email from auth
        'profileCompleted': true,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pushReplacementNamed(context, '/buyer/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display current user's phone/email
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                          'Phone: ${FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Not provided'}'),
                      Text(
                          'Email: ${FirebaseAuth.instance.currentUser?.email ?? 'Not provided'}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Business Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: 'District',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pinCodeController,
                decoration: InputDecoration(
                  labelText: 'PIN Code',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length != 6) return 'Invalid PIN code';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _gstController,
                decoration: InputDecoration(
                  labelText: 'GST Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    _gstController.dispose();
    super.dispose();
  }
}
