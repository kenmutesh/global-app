import 'package:flutter/material.dart';
import 'package:global_app/constants/constants.dart';
import 'package:global_app/screens/pages/HomePage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _branches = [];
  int? _selectedStoreId;
  int? _selectedBranchId;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isFetchingStores = false;
  bool _isFetchingBranches = false;

  final FlutterSecureStorage storage =
      const FlutterSecureStorage(); // Define storage

  @override
  void initState() {
    super.initState();
    _fetchStores(); // Fetch stores on page load
  }

  Future<void> _fetchStores() async {
    setState(() {
      _isFetchingStores = true;
    });

    try {
      final response =
          await http.get(Uri.parse(storesUrl)); // Fetch stores from API

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _stores = data
              .map((item) => {'id': item['id'], 'name': item['name']})
              .toList();
        });
      } else {
        throw Exception(
            'Failed to load stores. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stores: $e');
      _showSnackBar('Error fetching stores. Please try again.');
    } finally {
      setState(() {
        _isFetchingStores = false;
      });
    }
  }

  Future<void> _fetchBranches(int storeId) async {
    setState(() {
      _isFetchingBranches = true;
      _branches = [];
      _selectedBranchId = null;
    });

    try {
      final response =
          await http.get(Uri.parse('$branchesUrl?store_id=$storeId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _branches = data
              .map((item) => {'id': item['id'], 'name': item['name']})
              .toList();
        });
      } else {
        throw Exception(
            'Failed to load branches. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching branches: $e');
      _showSnackBar('Error fetching branches. Please try again.');
    } finally {
      setState(() {
        _isFetchingBranches = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final String? branchId = _selectedBranchId?.toString();
    final String? storeId = _selectedStoreId?.toString();

    if (username.isEmpty ||
        password.isEmpty ||
        branchId == null ||
        storeId == null) {
      _showSnackBar('Please provide all required fields.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Get the current location
      Position position = await _determinePosition();

      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': username,
          'password': password,
          'branch_id': branchId,
          'store_id': storeId,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final token = responseBody['token'];
        final user = responseBody['user'];
        final branch = responseBody['branch'];

        await storage.write(key: 'token', value: token);
        await storage.write(key: 'user', value: jsonEncode(user));
        await storage.write(key: 'branch', value: jsonEncode(branch));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (response.statusCode == 401) {
        final responseBody = jsonDecode(response.body);
        final message =
            responseBody['message'] ?? 'Invalid username or password';
        _showSnackBar(message);
      } else {
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ??
            'Unexpected error occurred. Please try again.';
        _showSnackBar(message);
      }
    } catch (e) {
      print('Login Error: $e');
      _showSnackBar('Login failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Please enable location services to proceed.');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
          'Location permissions are permanently denied, we cannot request permissions.');
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                ),
                child: Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isFetchingStores
                            ? Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                value: _selectedStoreId,
                                hint: Text('Select Store'),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedStoreId = newValue;
                                    _selectedBranchId = null;
                                    if (_selectedStoreId != null) {
                                      _fetchBranches(_selectedStoreId!);
                                    }
                                  });
                                },
                                items:
                                    _stores.map((Map<String, dynamic> store) {
                                  return DropdownMenuItem<int>(
                                    value: store['id'],
                                    child: Text(store['name']),
                                  );
                                }).toList(),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                        SizedBox(height: 16),
                        _isFetchingBranches
                            ? Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                value: _selectedBranchId,
                                hint: Text('Select Branch'),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedBranchId = newValue;
                                  });
                                },
                                items: _branches
                                    .map((Map<String, dynamic> branch) {
                                  return DropdownMenuItem<int>(
                                    value: branch['id'],
                                    child: Text(branch['name']),
                                  );
                                }).toList(),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username or Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
