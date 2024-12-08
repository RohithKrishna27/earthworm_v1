import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_earthworm/buyer/buyer_profile_page.dart';
import 'package:project_earthworm/buyer/won_auction_page.dart';
import 'auction_card.dart';
import 'buyer_auction_page.dart';

class BuyerHome extends StatefulWidget {
  @override
  _BuyerHomeState createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  int _selectedIndex = 0;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  final List<Widget> _pages = [
    BuyerDashboard(),
    BuyerAuctionsPage(),
    WonAuctionsPage(),
    BuyerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Auctions'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Won'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// buyer_dashboard.dart
class BuyerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Implement notifications
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Buyer Info
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('buyers')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox();

                final buyerData = snapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${buyerData['company']}!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Find and bid on high-quality produce',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),

            // Stats Section
            Text(
              'Your Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Active Bids',
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('auctions')
                        .where('status', isEqualTo: 'active')
                        .where('bids',
                            arrayContains: {'bidderId': userId}).snapshots(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data?.docs.length ?? 0}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'Won Auctions',
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('auctions')
                        .where('winner', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data?.docs.length ?? 0}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Recent Auctions Section
            Text(
              'Recent Active Auctions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('auctions')
                  .where('status', isEqualTo: 'active')
                  .where('endTime', isGreaterThan: Timestamp.now())
                  .orderBy('endTime')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No active auctions available'),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return AuctionCard(
                      auctionId: doc.id,
                      data: data,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, Widget value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              value,
            ],
          ),
        ),
      ),
    );
  }
}
