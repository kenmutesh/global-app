import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Stockstake extends StatefulWidget {
  const Stockstake({super.key});

  @override
  State<Stockstake> createState() => _StockstakeState();
}

class _StockstakeState extends State<Stockstake> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? branchName;

  @override
  void initState() {
    super.initState();
    _loadBranch();
  }

  Future<void> _loadBranch() async {
    try {
      String? branchJson = await _storage.read(key: 'branch');
      if (branchJson != null) {
        // Assuming branchJson is a JSON string and needs to be parsed
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(branchName ?? 'Loading...'),
      ),
      body: Center(
        child: Text('Stocktaking Page'),
      ),
    );
  }
}
