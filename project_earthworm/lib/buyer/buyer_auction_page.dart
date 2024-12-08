import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_bidding_page.dart';

class BuyerAuctionsPage extends StatelessWidget {
  const BuyerAuctionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Auctions'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .where('status', isEqualTo: 'active')
            .where('endTime', isGreaterThan: Timestamp.now())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final auctions = snapshot.data!.docs;

          if (auctions.isEmpty) {
            return const Center(
              child: Text('No active auctions available'),
            );
          }

          return ListView.builder(
            itemCount: auctions.length,
            itemBuilder: (context, index) {
              final auction = auctions[index].data() as Map<String, dynamic>;
              final endTime = (auction['endTime'] as Timestamp).toDate();
              final remainingTime = endTime.difference(DateTime.now());

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    '${auction['cropDetails']['type']} - ${auction['cropDetails']['quantity']} quintals',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Base Price: ₹${auction['cropDetails']['basePrice']}'),
                      Text('Current Bid: ₹${auction['currentBid']}'),
                      Text('Time Left: ${remainingTime.inMinutes} minutes'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BuyerBiddingPage(
                            auctionId: auctions[index].id,
                            currentBid: auction['currentBid'],
                          ),
                        ),
                      );
                    },
                    child: const Text('Bid Now'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
