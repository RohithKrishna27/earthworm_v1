import 'package:cloud_firestore/cloud_firestore.dart';

class AuctionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Handle auction expiry check
  static Future<void> checkAndEndExpiredAuction(String auctionId) async {
    final auction =
        await _firestore.collection('auctions').doc(auctionId).get();
    if (!auction.exists) return;

    final auctionData = auction.data()!;
    if (auctionData['status'] == 'active') {
      final endTime = (auctionData['endTime'] as Timestamp).toDate();
      if (DateTime.now().isAfter(endTime)) {
        await endAuction(auctionId);
      }
    }
  }

  // Main auction end handler
  static Future<void> endAuction(String auctionId) async {
    final auctionRef = _firestore.collection('auctions').doc(auctionId);

    await _firestore.runTransaction((transaction) async {
      final auctionDoc = await transaction.get(auctionRef);
      if (!auctionDoc.exists) return;

      final auctionData = auctionDoc.data()!;
      if (auctionData['status'] != 'active' ||
          auctionData['currentBidder'] == null) return;

      // Decide which handler to use based on auction type
      final bool isGroupAuction = auctionData['isGroupFarming'] ?? false;

      if (isGroupAuction) {
        await _handleGroupAuctionEnd(transaction, auctionRef, auctionData);
      } else {
        await _handleSingleAuctionEnd(transaction, auctionRef, auctionData);
      }
    });
  }

  // Handle single farmer auction completion
  static Future<void> _handleSingleAuctionEnd(
    Transaction transaction,
    DocumentReference auctionRef,
    Map<String, dynamic> auctionData,
  ) async {
    // Create order for single farmer
    final orderRef = _firestore.collection('orders').doc();
    transaction.set(orderRef, {
      'buyerId': auctionData['currentBidder']['id'],
      'farmerId': auctionData['farmerDetails']['id'],
      'farmerName': auctionData['farmerDetails']['name'],
      'cropType': auctionData['cropDetails']['type'],
      'quantity': auctionData['cropDetails']['quantity'],
      'price': auctionData['currentBid'],
      'status': 'pending',
      'orderType': 'auction',
      'auctionId': auctionRef.id,
      'isGroupOrder': false,
      'location': auctionData['location'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create notification for farmer
    await _createNotification(
      userId: auctionData['farmerDetails']['id'],
      title: 'Auction Completed',
      message:
          'Your auction for ${auctionData['cropDetails']['type']} has been completed at ₹${auctionData['currentBid']}',
      auctionId: auctionRef.id,
      orderId: orderRef.id,
    );

    // Update auction status
    _updateAuctionStatus(transaction, auctionRef, auctionData);
  }

  // Handle group auction completion
  static Future<void> _handleGroupAuctionEnd(
    Transaction transaction,
    DocumentReference auctionRef,
    Map<String, dynamic> auctionData,
  ) async {
    final List<dynamic> groupMembers = auctionData['groupMembers'] ?? [];
    if (groupMembers.isEmpty) return;

    for (var member in groupMembers) {
      // Create order for each group member
      final orderRef = _firestore.collection('orders').doc();
      transaction.set(orderRef, {
        'buyerId': auctionData['currentBidder']['id'],
        'farmerId': member['farmerId'],
        'farmerName': member['name'],
        'cropType': auctionData['cropDetails']['type'],
        'quantity': auctionData['cropDetails']['quantity'],
        'price': auctionData['currentBid'],
        'status': 'pending',
        'orderType': 'auction',
        'auctionId': auctionRef.id,
        'isGroupOrder': true,
        'groupAuctionId': auctionRef.id,
        'location': auctionData['location'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for each group member
      await _createNotification(
        userId: member['farmerId'],
        title: 'Group Auction Completed',
        message:
            'Your group auction for ${auctionData['cropDetails']['type']} has been completed at ₹${auctionData['currentBid']}',
        auctionId: auctionRef.id,
        orderId: orderRef.id,
      );
    }

    // Update auction status
    _updateAuctionStatus(transaction, auctionRef, auctionData);
  }

  // Helper method to update auction status
  static void _updateAuctionStatus(
    Transaction transaction,
    DocumentReference auctionRef,
    Map<String, dynamic> auctionData,
  ) {
    transaction.update(auctionRef, {
      'status': 'completed',
      'winningBid': auctionData['currentBid'],
      'winner': auctionData['currentBidder']['id'],
      'winnerDetails': auctionData['currentBidder'],
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Helper method to create notifications
  static Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String auctionId,
    required String orderId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'auction_completed',
      'title': title,
      'message': message,
      'auctionId': auctionId,
      'orderId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
