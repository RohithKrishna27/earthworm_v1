import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'former_auction_status.dart';
import 'dart:async';

class AuctionValidationPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Map<String, double> qualityScores;
  final List<String> imageUrls;
  final bool isDirectSale;

  const AuctionValidationPage({
    Key? key,
    required this.formData,
    required this.qualityScores,
    required this.imageUrls,
    required this.isDirectSale,
  }) : super(key: key);

  @override
  _AuctionValidationPageState createState() => _AuctionValidationPageState();
}

class _AuctionValidationPageState extends State<AuctionValidationPage> {
  final _durationController = TextEditingController();
  bool isEligible = false;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  void _checkEligibility() {
    final quantity = widget.formData['cropDetails']['weight'] as double;
    setState(() {
      isEligible = quantity >= 50;
    });
  }

  Future<void> _createAuction() async {
    if (!isEligible) return;

    try {
      final duration = int.parse(_durationController.text);
      if (duration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid duration')),
        );
        return;
      }

      final endTime = DateTime.now().add(Duration(minutes: duration));

      final docRef =
          await FirebaseFirestore.instance.collection('auctions').add({
        'cropDetails': {
          'type': widget.formData['cropDetails']['cropType'],
          'quantity': widget.formData['cropDetails']['weight'],
          'basePrice': widget.formData['cropDetails']['expectedPrice'],
        },
        'farmerDetails': {
          'id': widget.formData['farmerDetails']['farmerId'],
          'name': widget.formData['farmerDetails']['name'],
          'phone': widget.formData['farmerDetails']['phone'],
        },
        'location': widget.formData['location'],
        'qualityScore': widget.qualityScores['Overall_Quality'],
        'imageUrls': widget.imageUrls,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'active',
        'currentBid': widget.formData['cropDetails']['expectedPrice'],
        'currentBidder': null,
        'bids': [],
        'isGroupFarming': widget.formData['groupFarming']['isGroupFarming'],
        'groupMembers': widget.formData['groupFarming']['members'],
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FarmerAuctionStatusPage(auctionId: docRef.id),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Setup'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      isEligible ? Icons.check_circle : Icons.error,
                      color: isEligible ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEligible
                          ? 'Your crop is eligible for auction!'
                          : 'Minimum 50 quintals required for auction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEligible ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!isEligible) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isEligible) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set Auction Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (in minutes)',
                          border: OutlineInputBorder(),
                          helperText: 'Enter how long the auction should last',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _createAuction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Start Auction',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
