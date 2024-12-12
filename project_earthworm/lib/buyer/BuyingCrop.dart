import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_earthworm/buyer/paymentGateway.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class BuyerFeedPage extends StatelessWidget {
  const BuyerFeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer\'s Marketplace'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('crop_sales')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/empty_state.png', height: 200),
                  const Text('No crops available at the moment'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return CropCard(
                data: doc.data() as Map<String, dynamic>,
                docId: doc.id,
              );
            },
          );
        },
      ),
    );
  }
}

class CropCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const CropCard({
    Key? key,
    required this.data,
    required this.docId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##,###");
    final isBelowMSP = data['mspDetails'] != null &&
        data['mspDetails']['mspDifference'] != null &&
        data['mspDetails']['mspDifference'] < 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailedView(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    data['imageUrls'][0],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'AI Score: ${data['qualityScore']?.toStringAsFixed(1) ?? 'N/A'}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['cropType'] ?? 'Unknown Crop',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${formatter.format(data['expectedPrice'] ?? 0)}/quintal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        data['farmerName'] ?? 'Unknown Farmer',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${data['location']?['district'] ?? 'Unknown District'}, ${data['location']?['state'] ?? 'Unknown State'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.scale, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${formatter.format(data['quantity'] ?? 0)} quintals available',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  // Display crop rating if available
                  if (data['rating'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${data['rating'].toStringAsFixed(1)} / 5',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                  if (isBelowMSP)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite,
                              color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Support this farmer by purchasing at MSP rate',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: Icons.phone,
                          label: 'Call',
                          color: Colors.green,
                          onTap: () => _launchCall(data['farmerPhone'] ?? ''),
                        ),
                        _ActionButton(
                          icon: Icons.message,
                          label: 'Message',
                          color: Colors.blue,
                          onTap: () =>
                              _launchMessage(data['farmerPhone'] ?? ''),
                        ),
                        _ActionButton(
                          icon: Icons.info_outline,
                          label: 'Details',
                          color: Colors.grey,
                          onTap: () => _showDetailedView(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedView(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetailedCropView(
        data: data,
        docId: docId,
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    if (phone.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _launchMessage(String phone) async {
    if (phone.isNotEmpty) {
      final uri = Uri(scheme: 'sms', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class DetailedCropView extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const DetailedCropView({
    Key? key,
    required this.data,
    required this.docId,
  }) : super(key: key);

  @override
  _DetailedCropViewState createState() => _DetailedCropViewState();
}

class _DetailedCropViewState extends State<DetailedCropView> {
  int _currentImageIndex = 0;
  final _formatter = NumberFormat("#,##,###");
  String? farmerId;
  double cropRating = 0; // Store crop rating

  @override
  void initState() {
    super.initState();
    _fetchFarmerIdAndRating();
  }

  Future<void> _fetchFarmerIdAndRating() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('crop_sales')
          .doc(widget.docId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          farmerId = docSnapshot.data()?['userId'];
          cropRating = docSnapshot.data()?['qualityScore']?.toDouble() ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching farmer ID and rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBelowMSP = widget.data['mspDetails'] != null &&
        widget.data['mspDetails']['mspDifference'] != null &&
        widget.data['mspDetails']['mspDifference'] < 0;
    final mspPrice = widget.data['mspDetails'] != null &&
            widget.data['mspDetails']['mspPrice'] != null
        ? widget.data['mspDetails']['mspPrice']
        : null;
    final listedPrice = widget.data['expectedPrice'] ?? 0;
    final quantity = widget.data['quantity'] ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 300,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() => _currentImageIndex = index);
                },
              ),
              items:
                  List<String>.from(widget.data['imageUrls'] ?? []).map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, fit: BoxFit.cover),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.data['imageUrls']
                      ?.asMap()
                      .entries
                      .map<Widget>((entry) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    );
                  }).toList() ??
                  [],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.data['cropType'] ?? 'Unknown Crop',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold),
                ),
                if (cropRating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(
                        '${cropRating.toStringAsFixed(1)}/5',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'by ${widget.data['farmerName'] ?? 'Unknown Farmer'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildQualitySection(),
            const SizedBox(height: 24),
            _buildInfoCard(
              title: 'Pick-up Location',
              content: '${widget.data['address'] ?? 'Unknown Location'}',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Available Quantity',
              content: '${_formatter.format(quantity)} quintals',
              icon: Icons.scale,
            ),
            const SizedBox(height: 24),
            if (widget.data['description'] != null) ...[
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(widget.data['description'] ?? 'No description available'),
              const SizedBox(height: 24),
            ],
            if (isBelowMSP) ...[
              _buildPurchaseButton(
                label:
                    'Support Farmer - Buy at MSP (₹${_formatter.format(mspPrice ?? 0)})',
                totalAmount: (mspPrice ?? 0) * quantity,
                color: const Color.fromARGB(255, 157, 247, 175),
                isSupport: true,
              ),
              const SizedBox(height: 12),
              _buildPurchaseButton(
                label:
                    'Buy at Listed Price (₹${_formatter.format(listedPrice)})',
                totalAmount: listedPrice * quantity,
                color: const Color.fromARGB(255, 190, 187, 85),
                isSupport: false,
              ),
            ] else
              _buildPurchaseButton(
                label: 'Proceed to Buy',
                totalAmount: listedPrice * quantity,
                color: Colors.green,
                isSupport: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySection() {
    final qualityScore = widget.data['qualityScore'] ?? 0;
    final analysisResults = widget.data['analysisDetails'] != null
        ? widget.data['analysisDetails']['results'] as Map<String, dynamic>?
        : null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quality Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${qualityScore.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _getQualityDescription(qualityScore),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (cropRating > 0) ...[
              const SizedBox(height: 16),
              const Text(
                'User Ratings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    return Icon(
                      index < cropRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '(${cropRating.toStringAsFixed(1)})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (analysisResults != null)
              ...analysisResults.entries
                  .where((e) => e.key != 'Overall_Quality')
                  .map((e) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                e.key.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${e.value.toStringAsFixed(1)}/10',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: e.value / 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getQualityColor(e.value),
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 7) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  String _getQualityDescription(double score) {
    if (score >= 8)
      return 'Excellent quality crop with superior characteristics';
    if (score >= 7) return 'Very good quality crop meeting high standards';
    if (score >= 6)
      return 'Good quality crop with satisfactory characteristics';
    if (score >= 5) return 'Average quality crop with some variations';
    return 'Below average quality with room for improvement';
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton({
    required String label,
    required double totalAmount,
    required Color color,
    required bool isSupport,
  }) {
    return ElevatedButton(
      onPressed: () => _showPurchaseConfirmation(
        totalAmount: totalAmount,
        isSupport: isSupport,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ₹${_formatter.format(totalAmount)}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showPurchaseConfirmation({
    required double totalAmount,
    required bool isSupport,
  }) {
    double userRating =
        double.parse(_getQualityDescription(widget.data['qualityScore'] ?? 0)); // Store user's rating

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSupport ? 'Support Purchase' : 'Purchase Confirmation'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSupport)
                  const Text(
                    'Thank you for choosing to support the farmer by purchasing at MSP rate.',
                    style: TextStyle(color: Colors.green),
                  ),
                const SizedBox(height: 16),
                Text('Total Amount: ₹${_formatter.format(totalAmount)}'),
                const SizedBox(height: 16),
                const Text('Rate this product:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < userRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          userRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Text('Would you like to proceed with the purchase?'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _proceedToPayment(totalAmount, isSupport);

              // Update crop_sales rating
              await _updateCropRating(userRating);

              // Add to order_history with rating
              FirebaseFirestore.instance.collection('order_history').add({
                'totalAmount': totalAmount,
                'buyerId':
                    FirebaseAuth.instance.currentUser?.uid ?? 'unknown_buyer',
                'sellerId': farmerId ?? 'unknown_seller',
                'cropId': widget.docId,
                'rating': cropRating,
                'timestamp': FieldValue.serverTimestamp(),
                'cropType': widget.data['cropType'],
                'quantity': widget.data['quantity'],
                'status': 'pending',
                'supportPrice': isSupport,
                'ratingDetails': {
                  'ratedAt': FieldValue.serverTimestamp(),
                  'stars': userRating,
                  'buyerName': FirebaseAuth.instance.currentUser?.displayName ??
                      'Anonymous',
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCropRating(double newRating) async {
    try {
      // Get the current crop document
      final cropDoc = await FirebaseFirestore.instance
          .collection('crop_sales')
          .doc(widget.docId)
          .get();

      if (cropDoc.exists) {
        // Get current rating and rating count
        final currentRating = cropDoc.data()?['rating'] ?? 0.0;
        final ratingCount = cropDoc.data()?['ratingCount'] ?? 0;

        // Calculate new average rating
        final double updatedRating =
            (currentRating * ratingCount + newRating) / (ratingCount + 1);

        // Update the crop_sales document
        await FirebaseFirestore.instance
            .collection('crop_sales')
            .doc(widget.docId)
            .update({
          'rating': updatedRating,
          'ratingCount': ratingCount + 1,
        });
      }
    } catch (e) {
      print('Error updating crop rating: $e');
    }
  }

  void _proceedToPayment(double amount, bool isSupport) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          amount: amount,
          isSupport: isSupport,
          cropName: widget.data['cropType'] ?? 'Unknown Crop', // Crop name
          farmerName:
              widget.data['farmerName'] ?? 'Unknown Farmer', // Farmer name
          farmerPhone: widget.data['farmerPhone'] ?? '', // Farmer phone number
        ),
      ),
    );
  }
}
