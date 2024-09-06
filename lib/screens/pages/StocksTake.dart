import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:global_app/screens/pages/partials/PreviousStocksPage.dart';
import 'package:global_app/screens/pages/partials/ProductsPage.dart';
import 'package:global_app/main.dart'; // Import main.dart for access to routes
import 'package:http/http.dart' as http; // HTTP for making the POST request
import 'package:global_app/constants/constants.dart'; // Import constants for API URLs

class Stockstake extends StatefulWidget {
  const Stockstake({super.key});

  @override
  State<Stockstake> createState() => _StockstakeState();
}

class _StockstakeState extends State<Stockstake> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? branchName;
  String? branchId; // To store branch ID for POST request
  String? authToken; // To store the auth token for the POST request
  int _selectedIndex = 0; // Current page index

  @override
  void initState() {
    super.initState();
    _loadBranch();
    _loadAuthToken();
  }

  Future<void> _loadBranch() async {
    try {
      String? branchJson = await _storage.read(key: 'branch');
      if (branchJson != null) {
        final branch = jsonDecode(branchJson);
        setState(() {
          branchName = branch['name'];
          branchId = branch['id'].toString(); // Get branch ID as a string
        });
      } else {
        setState(() {
          branchName = 'Unknown Branch';
        });
      }
    } catch (e) {
      setState(() {
        branchName = 'Error loading branch';
      });
    }
  }

  Future<void> _loadAuthToken() async {
    authToken = await _storage.read(key: 'token'); // Load stored auth token
  }

  // Method to send POST request on Clock Out
  Future<void> _clockOut() async {
    if (authToken == null || branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Missing auth token or branch ID')),
      );
      return;
    }

    try {
     final response = await http.post(
        Uri.parse(clockout),
        headers: {'Authorization': 'Bearer $authToken'},
        body: {'branch_id': branchId},
      );

      if (response.statusCode == 200) {
        await _storage.deleteAll();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LandingPage()),
        );
      } else {
        // Handle server error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during clock-out: ${response.body}')),
        );
      }
    } catch (e) {
      // Handle HTTP request error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to update the selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      ProductsPage(
        onPageChanged: _onItemTapped, // Pass the function to ProductsPage
      ),
      const PreviousStocksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(branchName ?? 'Loading...'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.camera),
            label: const Text('Clock Out'),
            onPressed: _clockOut, // Clock-out button in the AppBar
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: _clockOut, // Another clock-out button in the AppBar
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                branchName ?? 'Branch Name',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('Products'),
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context); // Close drawer after selection
              },
            ),
            ListTile(
              title: const Text('Previous Stocks'),
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context); // Close drawer after selection
              },
            ),
            ListTile(
              title: const Text('Clock Out'),
              onTap: () {
                _clockOut(); // Clock-out button in the drawer
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the current selected page
    );
  }
}
