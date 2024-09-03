import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:global_app/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

// Example constants
const String baseClockinUrl = clockin;
const String clockinPostUrl = saveClockin;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _statusMessage = 'Loading...';
  bool _hasActiveClockIn = false;
  DateTime? _lastPressedTime;

  @override
  void initState() {
    super.initState();
    _fetchClockInData();
  }

  Future<void> _fetchClockInData() async {
    try {
      final authToken = await _storage.read(key: 'token');
      final branch = await _storage.read(key: 'branch');

      if (authToken != null && branch != null) {
        final response = await http.get(
          Uri.parse('$baseClockinUrl?branch=${Uri.encodeComponent(branch)}'),
          headers: {'Authorization': 'Bearer $authToken'},
        );
        print('test');
        print(response)
        print(response.statusCode);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _hasActiveClockIn = data['active'] != null;
            _statusMessage = _hasActiveClockIn
                ? 'Active clock-in found. Proceed to stocks.'
                : 'No active clock-in found. Capture image to clock in.';
          });
        } else {
          setState(() {
            _statusMessage = 'Failed to fetch clock-in data.';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No authentication token or branch found.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _uploadImage(pickedFile.path);
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    try {
      final authToken = await _storage.read(key: 'token');
      if (authToken != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(clockinPostUrl),
        );
        request.headers['Authorization'] = 'Bearer $authToken';
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final data = jsonDecode(responseBody);
          setState(() {
            _statusMessage = 'Clock-in successful: ${data['message']}';
            _hasActiveClockIn = true; // Update to show proceed button
          });
        } else {
          setState(() {
            _statusMessage = 'Failed to clock in.';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No authentication token found.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  void _refreshData() {
    _fetchClockInData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home Page'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_statusMessage),
              SizedBox(height: 20),
              if (_hasActiveClockIn)
                ElevatedButton(
                  onPressed: () {
                    // Navigate to stocks page
                  },
                  child: Text('Proceed to Stocks'),
                )
              else
                ElevatedButton(
                  onPressed: _captureImage,
                  child: Text('Capture Image to Clock In'),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_statusMessage),
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
    Navigator.of(context).maybePop();
    SystemNavigator.pop(); // Exit the app
  }
}
