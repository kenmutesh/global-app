import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:global_app/screens/pages/partials/PreviousStocksPage.dart';
import 'package:global_app/screens/pages/partials/ProductsPage.dart';

class Stockstake extends StatefulWidget {
  const Stockstake({super.key});

  @override
  State<Stockstake> createState() => _StockstakeState();
}

class _StockstakeState extends State<Stockstake> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? branchName;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBranch();
  }

  Future<void> _loadBranch() async {
    try {
      String? branchJson = await _storage.read(key: 'branch');
      if (branchJson != null) {
        final branch = jsonDecode(branchJson);
        setState(() {
          branchName = branch['name'];
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const ProductsPage(),
      const PreviousStocksPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(branchName ?? 'Loading...'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
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
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
