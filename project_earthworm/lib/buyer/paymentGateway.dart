import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatelessWidget {
  final double amount;
  final bool isSupport;
  final String cropName;
  final String farmerName;
  final String farmerPhone;

  PaymentPage({
    Key? key,
    required this.amount,
    required this.isSupport,
    required this.cropName,
    required this.farmerName,
    required this.farmerPhone,
  }) : super(key: key);

  final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Details
            const Text(
              'Contact Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Farmer Name: $farmerName'),
            Text('Phone: $farmerPhone'),
            const SizedBox(height: 20),

            // Order Summary
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: ListTile(
                title: Text(cropName),
                subtitle: Text(isSupport ? 'Support Payment' : 'Crop Payment'),
                trailing: Text('₹${_formatter.format(amount)}'),
              ),
            ),
            const SizedBox(height: 20),

            // QR Code from Google Drive
            const Text(
              'Scan to Pay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Center(
              child: Image.network(
                'https://drive.google.com/uc?id=1BD_m2y6x7tlkFv1r-g5oQ5GtzXQ5Kgt_', // Direct link to your QR code image
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Payment Details
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Card Number'),
                    const SizedBox(height: 5),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter card number',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Expiration Date'),
                              const SizedBox(height: 5),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'MM/YY',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CVV'),
                              const SizedBox(height: 5),
                              TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: '***',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pay Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Implement payment gateway integration here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment functionality not implemented.'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button color
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text('Pay ₹${_formatter.format(amount)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: PaymentPage(
        amount: 250.28,
        isSupport: true,
        cropName: 'Wheat',
        farmerName: 'John Doe',
        farmerPhone: '+1234567890',
      ),
    ),
  );
}