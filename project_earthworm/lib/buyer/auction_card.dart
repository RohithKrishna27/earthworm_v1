// auction_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auction_detail_page.dart';
import 'buyer_bidding_page.dart';

class AuctionCard extends StatelessWidget {
  final String auctionId;
  final Map<String, dynamic> data;

  const AuctionCard({
    Key? key,
    required this.auctionId,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final endTime = (data['endTime'] as Timestamp).toDate();
    final remainingTime = endTime.difference(DateTime.now());

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${data['cropDetails']['type']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('Quantity: ${data['cropDetails']['quantity']} quintals'),
            Text('Base Price: ₹${data['cropDetails']['basePrice']}'),
            Text('Current Bid: ₹${data['currentBid']}'),
            if (data['qualityScore'] != null)
              Text('Quality Score: ${data['qualityScore'].toStringAsFixed(1)}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionDetailPage(
                auctionId: auctionId,
                currentBid: (data['currentBid'] as num).toDouble(),
                auctionData: data,
              ),
            ),
          );
        },
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuyerBiddingPage(
                  auctionId: auctionId,
                  currentBid: (data['currentBid'] as num).toDouble(),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text('Bid Now'),
        ),
      ),
    );
  }
}

// auction_detail_page.dart - Modified winner section
// Farmer Details (only shown after winning)
