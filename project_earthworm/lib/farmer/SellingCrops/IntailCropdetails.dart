import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Main form widget for collecting crop details
class CropDetailsForm extends StatefulWidget {
  final String currentUserId;
  
  const CropDetailsForm({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _CropDetailsFormState createState() => _CropDetailsFormState();
}

class _CropDetailsFormState extends State<CropDetailsForm> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers
  final TextEditingController _farmerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _expectedPriceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Group farming state
  bool isGroupFarming = false;
  int? numberOfMembers;
  List<TextEditingController> memberUidControllers = [];
  List<Map<String, dynamic>> memberDetails = [];

  // Selection state
  String? selectedState;
  String? selectedDistrict;
  String? selectedAPMC;
  String? selectedCrop;

  // Price related state
  double? minPrice;
  double? maxPrice;
  bool? isAboveMSP;
  bool isLoadingPrice = false;
  String? apiError;

  // MSP data
  final Map<String, double> mspPrices = {
    'Rice': 2183,
    'Maize': 2090,
    'Wheat': 2275,
    'Groundnut': 6783,
    'Mustard': 5650,
    'Ragi': 4846,
    'Jowar': 3180,
    'Cotton': 7121,
    'Sugarcane': 315,
    'Tomato': 2000,
    'Onion': 1500,
    'Potato': 1000,
  };

  // Location data
  final Map<String, List<String>> stateDistricts = {
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur'],
    'Punjab': ['Amritsar', 'Ludhiana', 'Jalandhar', 'Patiala'],
    'Other': ['District 1']
  };

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  // Load current user's data from Firebase
  Future<void> _loadInitialUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _farmerNameController.text = userData['name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
    }
  }

  // Fetch user details by UID
  Future<Map<String, dynamic>?> _fetchUserDetails(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists) {
        return userDoc.data();
      }
      _showErrorSnackBar('User not found');
      return null;
    } catch (e) {
      _showErrorSnackBar('Error fetching user details: $e');
      return null;
    }
  }
   final Map<String, Map<String, List<String>>> stateAPMCMarkets = {
    'Karnataka': {
      'Bangalore': ['KR Market', 'Yeshwanthpur APMC', 'Binny Mill'],
      'Mysore': ['Bandipalya APMC', 'Mysore Central Market'],
      'Hubli': ['Hubli APMC Market', 'Amargol Market'],
      'Mangalore': ['Mangalore APMC', 'Central Market']
    },
    'Maharashtra': {
      'Mumbai': ['Vashi APMC', 'Dadar Market'],
      'Pune': ['Market Yard APMC', 'Gultekdi Market'],
      'Nagpur': ['Nagpur APMC', 'Cotton Market'],
      'Nashik': ['Nashik APMC', 'Pimpalgaon Market']
    }
    // Add more states and markets as needed
  };

  // Fetch market prices from API
    Future<void> _fetchMarketPrice() async {
    if (selectedState == null || selectedCrop == null) return;

    setState(() {
      isLoadingPrice = true;
      apiError = null;
    });

    try {
      // First try the primary API
      final primaryBaseUrl = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070";
      final primaryApiKey = "579b464db66ec23bdd000001e3c6f8ed17cb4769425e0176dc5b7318";
      
      final primaryResponse = await http.get(
        Uri.parse(
          '$primaryBaseUrl?api-key=$primaryApiKey&format=json&filters[state]=${Uri.encodeComponent(selectedState!)}&filters[commodity]=${Uri.encodeComponent(selectedCrop!)}'
        )
      ).timeout(const Duration(seconds: 10));

      if (primaryResponse.statusCode == 200) {
        final data = json.decode(primaryResponse.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          setState(() {
            minPrice = double.tryParse(data['records'][0]['min_price'].toString());
            maxPrice = double.tryParse(data['records'][0]['max_price'].toString());
          });
          return;
        }
      }

      // If primary API fails, try backup API
      final backupResponse = await http.get(
        Uri.parse(
          "https://market-api-m222.onrender.com/api/commodities/state/$selectedState/commodity/$selectedCrop"
        )
      ).timeout(const Duration(seconds: 10));

      if (backupResponse.statusCode == 200) {
        final data = json.decode(backupResponse.body);
        setState(() {
          if (data != null && data['min_price'] != null && data['max_price'] != null) {
            minPrice = double.tryParse(data['min_price'].toString());
            maxPrice = double.tryParse(data['max_price'].toString());
          } else {
            apiError = 'Price data not available for selected crop';
          }
        });
      } else {
        setState(() {
          apiError = 'Unable to fetch market prices';
        });
      }
    } catch (e) {
      setState(() {
        apiError = 'Error fetching market prices: $e';
      });
    } finally {
      setState(() {
        isLoadingPrice = false;
      });
    }
  }
  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  } Widget _buildAPMCSelection() {
    if (selectedState == null || selectedDistrict == null) return const SizedBox.shrink();
    
    final markets = stateAPMCMarkets[selectedState]?[selectedDistrict] ?? [];
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedAPMC,
        decoration: const InputDecoration(
          labelText: 'APMC Market',
          border: OutlineInputBorder(),
          filled: true,
        ),
        items: markets.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedAPMC = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an APMC market';
          }
          return null;
        },
      ),
    );
  }

 Widget _buildGroupMemberFields() {
    return Column(
      children: List.generate(numberOfMembers ?? 0, (index) {
        if (memberUidControllers.length <= index) {
          memberUidControllers.add(TextEditingController());
        }
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Member ${index + 2}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: memberUidControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Member UID',
                    filled: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _fetchMemberDetails(index),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter member UID';
                    }
                    return null;
                  },
                ),
                if (index < memberDetails.length && memberDetails[index].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Member Verified',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Name: ${memberDetails[index]['name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Phone: ${memberDetails[index]['phone']}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  // Handle member detail fetching
  Future<void> _fetchMemberDetails(int index) async {
    try {
      final details = await _fetchUserDetails(memberUidControllers[index].text);
      if (details != null) {
        setState(() {
          while (memberDetails.length <= index) {
            memberDetails.add({});
          }
          memberDetails[index] = details;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching member details: $e');
    }
  }

  // Build state selection dropdown
  Widget _buildStateSelection() {
    return DropdownButtonFormField<String>(
      value: selectedState,
      decoration: const InputDecoration(
        labelText: 'State',
        border: OutlineInputBorder(),
        filled: true,
      ),
      items: [
        'Karnataka',
        'Maharashtra',
        'Andhra Pradesh',
        'Kerala',
        'Punjab',
        'Other'
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedState = value;
          selectedDistrict = null;
          selectedAPMC = null;
          if (selectedCrop != null) {
            _fetchMarketPrice();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a state';
        }
        return null;
      },
    );
  }

  // Build district selection dropdown
  Widget _buildDistrictSelection() {
    if (selectedState == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: DropdownButtonFormField<String>(
        value: selectedDistrict,
        decoration: const InputDecoration(
          labelText: 'District',
          border: OutlineInputBorder(),
          filled: true,
        ),
        items: stateDistricts[selectedState]?.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedDistrict = value;
            selectedAPMC = null;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a district';
          }
          return null;
        },
      ),
    );
  }
  

  // Build crop selection dropdown
  Widget _buildCropSelection() {
    return DropdownButtonFormField<String>(
      value: selectedCrop,
      decoration: const InputDecoration(
        labelText: 'Crop',
        border: OutlineInputBorder(),
        filled: true,
      ),
      items: [
        'Tomato',
        'Onion',
        'Potato',
        'Rice',
        'Maize',
        'Wheat',
        'Groundnut',
        'Mustard',
        'Ragi',
        'Jowar',
        'Cotton',
        'Sugarcane'
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCrop = value;
          if (selectedState != null) {
            _fetchMarketPrice();
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a crop';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Basic Details'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Farmer Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Farmer Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _farmerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Farmer Name',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Group Farming Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Group Farming',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Group Selling'),
                      value: isGroupFarming,
                      onChanged: (value) {
                        setState(() {
                          isGroupFarming = value;
                          if (!value) {
                            numberOfMembers = null;
                            memberUidControllers.clear();
                            memberDetails.clear();
                          }
                        });
                      },
                    ),
                    if (isGroupFarming) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: numberOfMembers,
                        decoration: const InputDecoration(
                          labelText: 'Number of Members',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        items: [2, 3, 4].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value members'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            numberOfMembers = value;
                            if (value != null && memberUidControllers.length > value - 1) {
                              memberUidControllers = memberUidControllers.sublist(0, value - 1);
                              memberDetails = memberDetails.sublist(0, value - 1);
                            }
                          });
                        },
validator: (value) {
                          if (isGroupFarming && value == null) {
                            return 'Please select number of members';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGroupMemberFields(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStateSelection(),
                    _buildDistrictSelection(),
                                _buildAPMCSelection(), // Add this line

                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Crop Details Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crop Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCropSelection(),
                    const SizedBox(height: 16),
                    
                    // Market Price Display
                    if (isLoadingPrice)
                      const Center(child: CircularProgressIndicator())
                    else if (apiError != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          apiError!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      )
                    else if (minPrice != null && maxPrice != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Market Price Range:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹$minPrice - ₹$maxPrice per quintal',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _expectedPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Expected Price (₹/quintal)',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expected price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty && selectedCrop != null) {
                          final expectedPrice = double.tryParse(value) ?? 0;
                          final mspPrice = mspPrices[selectedCrop!] ?? 0;
                          setState(() {
                            isAboveMSP = expectedPrice >= mspPrice;
                          });
                        }
                      },
                    ),

                    if (isAboveMSP != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAboveMSP! ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAboveMSP! ? Icons.check_circle : Icons.warning,
                              color: isAboveMSP! ? Colors.green[700] : Colors.orange[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAboveMSP! 
                                ? 'Price is above MSP'
                                : 'Price is below MSP',
                              style: TextStyle(
                                color: isAboveMSP! ? Colors.green[700] : Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Additional Details Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup Address',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pickup address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Crop Description',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter crop description';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // AI Analysis Button
            ElevatedButton.icon(
              onPressed: () {
                // Implement AI crop quality analysis
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('AI Analysis'),
                    content: Text('AI Crop Quality Analysis feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('AI Crop Quality Analysis'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
            ElevatedButton(
               onPressed: () async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Prepare form data
        final formData = {
          'submissionTimestamp': FieldValue.serverTimestamp(),
          'farmerDetails': {
            'farmerId': widget.currentUserId,
            'name': _farmerNameController.text,
            'phone': _phoneController.text,
          },
          'groupFarming': {
            'isGroupFarming': isGroupFarming,
            'numberOfMembers': numberOfMembers,
            'members': memberDetails.map((member) => {
              'uid': member['uid'],
              'name': member['name'],
              'phone': member['phone'],
            }).toList(),
          },
          'location': {
            'state': selectedState,
            'district': selectedDistrict,
            'apmcMarket': selectedAPMC,
          },
          'cropDetails': {
            'cropType': selectedCrop,
            'marketPrice': {
              'min': minPrice,
              'max': maxPrice,
            },
            'expectedPrice': double.parse(_expectedPriceController.text),
            'mspCompliance': {
              'mspPrice': mspPrices[selectedCrop!],
              'isAboveMSP': isAboveMSP,
            },
          },
          'address': _addressController.text,
          'description': _descriptionController.text,
        };

        // Remove loading indicator
        Navigator.pop(context);

        // Navigate to review page
       
      } catch (e) {
        // Remove loading indicator if shown
        Navigator.pop(context);
        _showErrorSnackBar('Error submitting form: $e');
      }
    }
  },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 0),
              ),
              child: const Text(
                'Review Details',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _farmerNameController.dispose();
    _phoneController.dispose();
    _expectedPriceController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    for (var controller in memberUidControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
}