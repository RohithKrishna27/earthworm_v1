import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'buyer_home.dart';
import 'buyer_profile_setup.dart';

class BuyerMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buyers')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If buyer profile doesn't exist or isn't complete, show setup
        if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
          return BuyerProfileSetup();
        }

        return BuyerHome();
      },
    );
  }
}
