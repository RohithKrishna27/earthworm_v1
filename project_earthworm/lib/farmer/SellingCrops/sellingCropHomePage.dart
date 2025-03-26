import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'former_auction_status.dart';

class BiddingResultsPage extends StatelessWidget {
  Future<String> _getLocationText(Map<String, dynamic> auction) async {
    try {
      // Check if there's a current bid with buyer info
      if (auction['currentBid'] != null && auction['currentBidder'] != null) {
        // Get the buyer ID from the currentBidder map
        final currentBidder = auction['currentBidder'] as Map<String, dynamic>;
        final buyerId = currentBidder['id'];

        if (buyerId != null) {
          // Fetch buyer's data
          final buyerDoc = await FirebaseFirestore.instance
              .collection('buyers')
              .doc(buyerId)
              .get();

          if (buyerDoc.exists) {
            final buyerData = buyerDoc.data() as Map<String, dynamic>?;
            if (buyerData != null) {
              // Construct location string from buyer's address
              final List<String> locationParts = [];
              if (buyerData['district'] != null) {
                locationParts.add(buyerData['district']);
              }
              if (buyerData['state'] != null) {
                locationParts.add(buyerData['state']);
              }

              return locationParts.isNotEmpty
                  ? locationParts.join(', ')
                  : 'Location not specified';
            }
          }
        }
      }

      // Fallback to auction location if no buyer info
      if (auction['location'] != null) {
        if (auction['location'] is String) {
          return auction['location'];
        } else if (auction['location'] is Map) {
          final locationMap = auction['location'] as Map<String, dynamic>;
          return locationMap['address'] ?? 'Location not specified';
        }
      }

      return 'Location not specified';
    } catch (e) {
      print('Error fetching location: $e');
      return 'Location not specified';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('auctions')
            .where('farmerDetails.id',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('status', whereIn: ['active', 'completed'])
            .orderBy('startTime', descending: true)
            .orderBy(FieldPath.documentId, descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading auctions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.green.shade600,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading your auctions...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inbox_rounded,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Bidding Results',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have no completed or active auctions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final auction =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final endTime = (auction['endTime'] as Timestamp).toDate();
              final isTimeExpired = DateTime.now().isAfter(endTime);

              // Update auction status if time has expired
              if (isTimeExpired && auction['status'] == 'active') {
                FirebaseFirestore.instance
                    .collection('auctions')
                    .doc(snapshot.data!.docs[index].id)
                    .update({'status': 'completed'});
              }

              final isActive = !isTimeExpired && auction['status'] == 'active';

              return FutureBuilder<String>(
                future: _getLocationText(auction),
                builder: (context, locationSnapshot) {
                  final locationText =
                      locationSnapshot.data ?? 'Location not specified';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmerAuctionStatusPage(
                              auctionId: snapshot.data!.docs[index].id,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auction['cropDetails']['type']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${auction['cropDetails']['quantity']} quintals',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.timer
                                            : Icons.check_circle,
                                        size: 16,
                                        color: isActive
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isActive ? 'Active' : 'Completed',
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      size: 20,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${auction['currentBid'] ?? auction['cropDetails']['basePrice']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 20,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          locationText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Bidding Results',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: BiddingResultsPage(),
  ));
}