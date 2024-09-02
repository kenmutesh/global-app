// lib/home_page.dart

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> _items = List.generate(20, (index) => 'Item $index');
  DateTime? _lastPressedTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home Page'),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: GestureDetector(
          onTap: () {
            final now = DateTime.now();
            if (_lastPressedTime == null ||
                now.difference(_lastPressedTime!) > Duration(seconds: 1)) {
              // Update last pressed time
              _lastPressedTime = now;

              // Show a snackbar with a message to inform the user
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tap again to exit'),
                  duration: Duration(seconds: 1),
                ),
              );
            } else {
              // Exit the app
              _exitApp();
            }
          },
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_items[index]),
                onTap: () {
                  // Optional: Handle item tap
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 1)) {
      _lastPressedTime = now;

      // Show a snackbar with a message to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap again to exit'),
          duration: Duration(seconds: 1),
        ),
      );
      return Future.value(false);
    } else {
      _exitApp();
      return Future.value(true);
    }
  }

  void _exitApp() {
    // Exit the app
    Navigator.of(context).maybePop();
    // Uncomment the following line to exit on Android:
    SystemNavigator.pop(); // This will exit the app
  }
}
