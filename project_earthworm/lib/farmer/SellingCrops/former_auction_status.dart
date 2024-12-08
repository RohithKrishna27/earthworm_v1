import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_earthworm/services/auction_service.dart';

class FarmerAuctionStatusPage extends StatelessWidget {
  final String auctionId;

  const FarmerAuctionStatusPage({
    Key? key,
    required this.auctionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Status'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .doc(auctionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final auction = snapshot.data!.data() as Map<String, dynamic>;
          final endTime = (auction['endTime'] as Timestamp).toDate();
          final remainingTime = endTime.difference(DateTime.now());
          final currentBidder =
              auction['currentBidder'] as Map<String, dynamic>?;

          final bids = auction['bids'] as List?;
          if (auction['status'] == 'active' &&
              DateTime.now().isAfter(endTime)) {
            // Call the service to end the auction
            AuctionService.checkAndEndExpiredAuction(auctionId);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          remainingTime.isNegative
                              ? 'Auction Ended'
                              : 'Time Remaining: ${remainingTime.inMinutes}:${remainingTime.inSeconds % 60}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: remainingTime.isNegative
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Current Highest Bid: ₹${auction['currentBid'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentBidder != null &&
                            currentBidder['name'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Highest Bidder: ${currentBidder['name']}',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bid History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (bids == null || bids.isEmpty)
                          const Text('No bids yet')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bids.length,
                            itemBuilder: (context, index) {
                              final bid = bids[index] as Map<String, dynamic>;
                              return ListTile(
                                title: Text('₹${bid['amount'] ?? 0}'),
                                subtitle:
                                    Text(bid['bidderName'] ?? 'Unknown Bidder'),
                                trailing: Text(
                                  _formatTime(bid['timestamp']),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (remainingTime.isNegative && currentBidder != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Auction Complete',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Winning Bid: ₹${auction['currentBid'] ?? 0}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Winner: ${currentBidder['name'] ?? 'Unknown Bidder'}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          if (currentBidder['phone'] != null)
                            Text(
                              'Contact: ${currentBidder['phone']}',
                              style: const TextStyle(fontSize: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Time not available';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return 'Invalid time format';
    } catch (e) {
      return 'Time not available';
    }
  }
}
