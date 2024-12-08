import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class BuyerBiddingPage extends StatefulWidget {
  final String auctionId;
  final double currentBid;

  const BuyerBiddingPage({
    Key? key,
    required this.auctionId,
    required this.currentBid,
  }) : super(key: key);

  @override
  _BuyerBiddingPageState createState() => _BuyerBiddingPageState();
}

class _BuyerBiddingPageState extends State<BuyerBiddingPage> {
  final _bidController = TextEditingController();
  late Stream<DocumentSnapshot> auctionStream;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    auctionStream = FirebaseFirestore.instance
        .collection('auctions')
        .doc(widget.auctionId)
        .snapshots();

    // Set up timer to check auction end
    _setupAuctionEndCheck();
  }

  void _setupAuctionEndCheck() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) async {
      final auctionDoc = await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .get();

      if (!auctionDoc.exists) return;

      final auctionData = auctionDoc.data() as Map<String, dynamic>;
      final endTime = (auctionData['endTime'] as Timestamp).toDate();

      if (DateTime.now().isAfter(endTime) && auctionData['winner'] == null) {
        // Auction has ended and winner hasn't been set
        final currentBidder = auctionData['currentBidder'];
        if (currentBidder != null) {
          await FirebaseFirestore.instance
              .collection('auctions')
              .doc(widget.auctionId)
              .update({
            'winner': currentBidder['id'],
            'winningBid': auctionData['currentBid'],
            'winningBidder': currentBidder,
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> _placeBid() async {
    try {
      if (_bidController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a bid amount')),
        );
        return;
      }

      final newBid = double.parse(_bidController.text);
      if (newBid <= widget.currentBid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid must be higher than current bid')),
        );
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to place a bid')),
        );
        return;
      }

      // Get buyer data
      final buyerDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(currentUser.uid)
          .get();

      if (!buyerDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buyer profile not found')),
        );
        return;
      }

      final buyerData = buyerDoc.data()!;

      // Get auction data to check if it's still active
      final auctionDoc = await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .get();

      final auctionData = auctionDoc.data() as Map<String, dynamic>;
      final endTime = (auctionData['endTime'] as Timestamp).toDate();

      if (DateTime.now().isAfter(endTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auction has ended')),
        );
        return;
      }

      // Update auction with new bid
      await FirebaseFirestore.instance
          .collection('auctions')
          .doc(widget.auctionId)
          .update({
        'currentBid': newBid,
        'currentBidder': {
          'id': currentUser.uid,
          'name': buyerData['company'] ?? 'Unknown Company',
          'phone': buyerData['phone'] ?? '',
        },
        'bids': FieldValue.arrayUnion([
          {
            'amount': newBid,
            'bidderId': currentUser.uid,
            'bidderName': buyerData['company'] ?? 'Unknown Company',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
      });

      _bidController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid placed successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rest of the build method remains the same
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Bid'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: auctionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final auction = snapshot.data!.data() as Map<String, dynamic>;
          final endTime = (auction['endTime'] as Timestamp).toDate();
          final remainingTime = endTime.difference(DateTime.now());

          if (remainingTime.isNegative) {
            return const Center(
              child: Text('Auction has ended'),
            );
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
                          'Time Remaining: ${remainingTime.inMinutes}:${remainingTime.inSeconds % 60}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Current Bid: ₹${auction['currentBid']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Your Bid Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _placeBid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Place Bid',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bidController.dispose();
    super.dispose();
  }
}
