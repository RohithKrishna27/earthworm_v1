import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auction_detail_page.dart';

class WonAuctionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Won Auctions'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .where('status',
                isEqualTo: 'completed') // Only get completed auctions
            .where('winner', isEqualTo: userId) // Match with winner ID
            .orderBy('endTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading auctions. Please try again later.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final auctions = snapshot.data!.docs;

          if (auctions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No won auctions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: auctions.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final auction = auctions[index].data() as Map<String, dynamic>;
              final endTime = (auction['endTime'] as Timestamp).toDate();

              // Add null checks for nested fields
              final cropDetails =
                  auction['cropDetails'] as Map<String, dynamic>? ?? {};
              final farmerDetails =
                  auction['farmerDetails'] as Map<String, dynamic>? ?? {};
              final winningBid = auction['currentBid'] ?? 0.0;

              return Card(
                child: ListTile(
                  title: Text(
                    '${cropDetails['type'] ?? 'Unknown Crop'} - ${cropDetails['quantity'] ?? 0} quintals',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Won Amount: ₹${winningBid}'),
                      Text('End Date: ${endTime.toString().split('.')[0]}'),
                      if (farmerDetails['name'] != null)
                        Text('Farmer: ${farmerDetails['name']}'),
                      if (farmerDetails['phone'] != null)
                        Text('Contact: ${farmerDetails['phone']}'),
                    ],
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuctionDetailPage(
                          auctionId: auctions[index].id,
                          currentBid: (winningBid as num).toDouble(),
                          auctionData: auction,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
