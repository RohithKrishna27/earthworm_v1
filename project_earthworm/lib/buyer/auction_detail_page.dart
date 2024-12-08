import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_bidding_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuctionDetailPage extends StatelessWidget {
  final String auctionId;
  final double currentBid;
  final Map<String, dynamic> auctionData;

  const AuctionDetailPage({
    Key? key,
    required this.auctionId,
    required this.currentBid,
    required this.auctionData,
  }) : super(key: key);

  Widget _buildImageWidget() {
    final imageUrls = auctionData['imageUrls'];

    if (imageUrls == null) {
      return Container(
        height: 200,
        child: Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 200,
      child: imageUrls is String
          ? Image.network(
              imageUrls,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(Icons.error_outline, size: 64, color: Colors.red),
                );
              },
            )
          : imageUrls is List
              ? PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final url = imageUrls[index];
                    return Image.network(
                      url.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                        );
                      },
                    );
                  },
                )
              : Center(
                  child: Icon(Icons.image_not_supported,
                      size: 64, color: Colors.grey),
                ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, Map<String, dynamic> auctionData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final status = auctionData['status'] ?? 'active';
    final winnerId = auctionData['winner'] is Map
        ? auctionData['winner']['id']
        : auctionData['winner'];

    if (status == 'completed' && winnerId == currentUserId) {
      if (auctionData['paymentStatus'] == 'completed') {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Payment Completed',
            style: TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      return ElevatedButton(
        onPressed: () async {
          try {
            bool confirm = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Payment'),
                    content:
                        Text('Proceed to pay ₹$currentBid for this auction?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Proceed'),
                      ),
                    ],
                  ),
                ) ??
                false;

            if (confirm) {
              await FirebaseFirestore.instance
                  .collection('auctions')
                  .doc(auctionId)
                  .update({
                'paymentStatus': 'completed',
                'paymentTimestamp': FieldValue.serverTimestamp(),
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment successful!')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed. Please try again.')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: Size(double.infinity, 50),
        ),
        child: Text(
          'Make Payment',
          style: TextStyle(fontSize: 18),
        ),
      );
    } else if (status == 'active') {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuyerBiddingPage(
                auctionId: auctionId,
                currentBid: currentBid,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 50),
        ),
        child: Text(
          'Place Bid',
          style: TextStyle(fontSize: 18),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Auction Ended',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auction Details'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .doc(auctionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final latestAuctionData =
              snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageWidget(),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${auctionData['cropDetails']?['type'] ?? 'Unknown Crop'} - ${auctionData['cropDetails']?['quantity'] ?? 0} quintals',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Base Price: ₹${auctionData['cropDetails']?['basePrice'] ?? 0}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Current Bid: ₹$currentBid',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(height: 32),
                      Text(
                        'Quality Score: ${(auctionData['qualityScore'] ?? 0.0).toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Location: ${auctionData['location']?['district'] ?? 'Unknown'}, ${auctionData['location']?['state'] ?? ''}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('auctions')
                            .doc(auctionId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return SizedBox();

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          final winnerId = data['winner'] is Map
                              ? data['winner']['id']
                              : data['winner'];

                          if (winnerId == currentUserId &&
                              data['farmerDetails'] != null) {
                            final farmerDetails =
                                data['farmerDetails'] as Map<String, dynamic>;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Farmer Contact Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (farmerDetails['name'] != null)
                                  Text('Name: ${farmerDetails['name']}'),
                                if (farmerDetails['phone'] != null)
                                  Text('Phone: ${farmerDetails['phone']}'),
                              ],
                            );
                          }
                          return SizedBox();
                        },
                      ),
                      SizedBox(height: 24),
                      _buildActionButton(context, latestAuctionData),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
