import 'package:cloud_firestore/cloud_firestore.dart';

class AuctionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check and end expired auctions
  static Future<void> checkAndEndExpiredAuction(String auctionId) async {
    final auction =
        await _firestore.collection('auctions').doc(auctionId).get();
    final auctionData = auction.data()!;

    // Check if auction is still active and has expired
    if (auctionData['status'] == 'active') {
      final endTime = (auctionData['endTime'] as Timestamp).toDate();
      if (DateTime.now().isAfter(endTime)) {
        await endAuction(auctionId);
      }
    }
  }

  // End auction and create order for winner
  static Future<void> endAuction(String auctionId) async {
    final auctionRef = _firestore.collection('auctions').doc(auctionId);

    // Use transaction to ensure data consistency
    await _firestore.runTransaction((transaction) async {
      final auctionDoc = await transaction.get(auctionRef);
      final auctionData = auctionDoc.data()!;

      // Only proceed if auction is still active
      if (auctionData['status'] == 'active' &&
          auctionData['currentBidder'] != null) {
        // Create order for the winning buyer
        final orderRef = _firestore.collection('orders').doc();
        transaction.set(orderRef, {
          'buyerId': auctionData['currentBidder']['id'],
          'farmerId': auctionData['farmerDetails']['id'],
          'cropType': auctionData['cropDetails']['type'],
          'quantity': auctionData['cropDetails']['quantity'],
          'price': auctionData['currentBid'],
          'status': 'pending',
          'orderType': 'auction',
          'auctionId': auctionId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update auction status and winner
        transaction.update(auctionRef, {
          'status': 'completed',
          'winningBid': auctionData['currentBid'],
          'winner': auctionData['currentBidder']['id'], // Store just the ID
          'winnerDetails': auctionData['currentBidder'], // Store full details
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    final updatedAuction = await auctionRef.get();
    if (updatedAuction.exists) {
      await _sendAuctionCompletionNotifications(updatedAuction.data()!);
    }
  }

  static Future<void> _sendAuctionCompletionNotifications(
      Map<String, dynamic> auctionData) async {
    // Implement your notification logic here
    // You might want to send notifications to both the farmer and the winning buyer
  }
}
