import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormerProfile extends StatelessWidget {
  const FormerProfile({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen or any other screen after logout
      Navigator.of(context).pushReplacementNamed('/signin');
    } catch (e) {
      // Show error message if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: ${e.toString()}")),
      );
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users') // Replace 'users' with your collection name
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No user data found.'));
          }

          final userData = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150'), // Replace with profile image URL if available
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Name: ${userData['name'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Email: ${userData['email'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Phone: ${userData['phone'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                // Add additional fields here as needed
              ],
            ),
          );
        },
      ),
    );
  }
}
