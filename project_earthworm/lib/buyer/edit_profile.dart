import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerEditProfilePage extends StatefulWidget {
  @override
  _BuyerEditProfilePageState createState() => _BuyerEditProfilePageState();
}

class _BuyerEditProfilePageState extends State<BuyerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _companyController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get the user data passed as arguments
    final userData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (userData != null) {
      _companyController.text = userData['company']?.toString() ?? '';
      _gstNumberController.text = userData['gstNumber']?.toString() ?? '';
      _phoneController.text = userData['phone']?.toString() ?? '';
      _emailController.text = userData['email']?.toString() ?? '';
      _addressController.text = userData['address']?.toString() ?? '';
      _districtController.text = userData['district']?.toString() ?? '';
      _stateController.text = userData['state']?.toString() ?? '';
      _pinCodeController.text = userData['pinCode']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _gstNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      
      await FirebaseFirestore.instance.collection('buyers').doc(userId).update({
        'company': _companyController.text,
        'gstNumber': _gstNumberController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'pinCode': _pinCodeController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Company Information', Icons.business),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _companyController,
                      labelText: 'Company Name',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _gstNumberController,
                      labelText: 'GST Number',
                      icon: Icons.confirmation_number,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32),
                    _buildSectionTitle('Address Details', Icons.location_on),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      icon: Icons.home,
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _districtController,
                      labelText: 'District',
                      icon: Icons.location_city,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _stateController,
                      labelText: 'State',
                      icon: Icons.map,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _pinCodeController,
                      labelText: 'PIN Code',
                      icon: Icons.pin_drop,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size(double.infinity, 54),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}