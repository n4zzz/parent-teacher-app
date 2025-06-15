// lib/main_menu_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:educonnect/login_page.dart'; // Assuming login_page.dart is in lib

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to LoginPage and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (Route<dynamic> route) => false, // This predicate removes all routes
      );
    } catch (e) {
      // Handle potential errors during sign out, though it's rare
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user (optional, but good for display or other features)
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (user != null) // Display user email if available
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Welcome, ${user.email ?? 'User'}!', // Display email or 'User' if email is null
                    style: TextStyle(
                      fontSize: 18 * (MediaQuery.of(context).size.width / 393.0), // Responsive font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              // Announcement Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📢 Announcements',
                      style: TextStyle(
                        fontSize: 20 * (MediaQuery.of(context).size.width / 393.0), // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor, // Use theme color
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      'No announcement',
                      style: TextStyle(
                        fontSize: 16 * (MediaQuery.of(context).size.width / 393.0), // Responsive font size
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center, // Center the "No announcement" text
                    ),
                  ],
                ),
              ),
              // Add other menu items or features here later
            ],
          ),
        ),
      ),
    );
  }
}