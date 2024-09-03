import 'package:flutter/material.dart';
import 'package:global_app/constants/constants.dart';
import 'package:global_app/screens/pages/HomePage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List<Map<String, dynamic>> _branches = [];
  int? _selectedBranchId;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isFetchingBranches = false;

  final FlutterSecureStorage storage = FlutterSecureStorage(); // Define storage

  @override
  void initState() {
    super.initState();
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    setState(() {
      _isFetchingBranches = true;
    });

    try {
      final response = await http.get(Uri.parse(stores));
      
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
    final String? branchId = _selectedBranchId
        ?.toString(); // Assuming `_selectedBranchId` is an `int?`

    if (username.isEmpty || password.isEmpty || branchId == null) {
      // Show an error if any required fields are missing
      _showSnackBar('Please provide all required fields.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': username,
          'password': password,
          'store': branchId,
        }),
      );
print('test');
      print(loginUrl);
      if (response.statusCode == 200) {
        // Parse the response body
        final responseBody = jsonDecode(response.body);
        final token = responseBody['token'];
        final user = responseBody['user'];
        final branch = responseBody['branch'];

        // Store token and user details securely
        await storage.write(key: 'token', value: token);
        await storage.write(key: 'user', value: jsonEncode(user));
        await storage.write(key: 'branch', value: jsonEncode(branch));

        // Navigate to the HomePage on success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (response.statusCode == 401) {
        // Handle invalid credentials
        final responseBody = jsonDecode(response.body);
        final message =
            responseBody['message'] ?? 'Invalid username or password';
        _showSnackBar(message);
      } else {
        // Handle other types of errors
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
                        _isFetchingBranches
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : DropdownButtonFormField<int>(
                                value: _selectedBranchId,
                                hint: Text('Select Branch'),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedBranchId = newValue;
                                    print(
                                        'Selected Branch ID: $_selectedBranchId'); // Debugging
                                  });
                                },
                                items: _branches
                                    .map((Map<String, dynamic> branch) {
                                  print(
                                      'Branch ID: ${branch['id']} Name: ${branch['name']}'); // Debugging
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
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
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
