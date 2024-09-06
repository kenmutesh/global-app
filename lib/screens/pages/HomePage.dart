import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:global_app/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:global_app/screens/pages/StocksTake.dart';

const String baseClockinUrl = clockin;
const String clockinPostUrl = saveClockin;
const String clockoutPostUrl = clockout;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  int? branchId;
  String _statusMessage = 'Loading...';
  bool _hasActiveClockIn = false;
  String? _imagePath;
  bool _isUploading = false;
  DateTime? _lastPressedTime;

  @override
  void initState() {
    super.initState();
    _fetchClockInData();
  }

  Future<void> _fetchClockInData() async {
    try {
      final authToken = await _storage.read(key: 'token');
      final branchJson = await _storage.read(key: 'branch');

      if (authToken != null && branchJson != null) {
        final branch = jsonDecode(branchJson);
        final branchId = branch['id'].toString();

        final response = await http.get(
          Uri.parse(
              '$baseClockinUrl?branch_id=${Uri.encodeComponent(branchId)}'),
          headers: {'Authorization': 'Bearer $authToken'},
        );

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
      // Compress the image
      final compressedImage = await _compressImage(File(pickedFile.path));
      setState(() {
        _imagePath = compressedImage.path;
      });
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final image = img.decodeImage(imageFile.readAsBytesSync());
    final compressedImage =
        img.encodeJpg(image!, quality: 85); // Adjust quality as needed
    final directory = await getTemporaryDirectory();
    final targetPath =
        '${directory.path}/compressed_${imageFile.path.split('/').last}';
    final compressedFile = File(targetPath)..writeAsBytesSync(compressedImage);
    return compressedFile;
  }

  Future<void> _uploadImage() async {
    if (_imagePath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final authToken = await _storage.read(key: 'token');
      final branchJson = await _storage.read(key: 'branch');

      if (branchJson != null) {
        final branch = jsonDecode(branchJson);
        setState(() {
          branchId = branch['id'];
        });
      } else {
        setState(() {
          branchId = null;
        });
      }

      if (authToken != null && branchId != null) {
        final uri = Uri.parse(clockinPostUrl);
        final request = http.MultipartRequest('POST', uri);

        request.headers['Authorization'] = 'Bearer $authToken';
        request.fields['branch_id'] = branchId!.toString();
        print('branch');
        print(branchId);
        final multipartFile =
            await http.MultipartFile.fromPath('image', _imagePath!);
        request.files.add(multipartFile);

        final response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final data = jsonDecode(responseBody);
          setState(() {
            _statusMessage = 'Clock-in successful: ${data['message']}';
            _hasActiveClockIn = true;
          });
          _showSnackBar('Clock-in successful', Colors.green);
        } else {
          setState(() {
            _statusMessage =
                'Failed to clock in. Status code: ${response.statusCode}';
          });
          _showSnackBar('Failed to clock in', Colors.red);
        }
      } else {
        setState(() {
          _statusMessage = 'No authentication token or branch ID found.';
        });
        _showSnackBar('No authentication token or branch ID found', Colors.red);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _clockOut() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final authToken = await _storage.read(key: 'token');
      final branchJson = await _storage.read(key: 'branch');

      if (authToken != null && branchJson != null) {
        final branch = jsonDecode(branchJson);
        final branchId = branch['id'].toString();

        final response = await http.post(
          Uri.parse(clockoutPostUrl),
          headers: {'Authorization': 'Bearer $authToken'},
          body: {'branch_id': branchId},
        );

        if (response.statusCode == 200) {
          setState(() {
            _hasActiveClockIn = false;
            _imagePath = null;
            _statusMessage = 'Clock-out successful. Capture image to clock in.';
          });
          _showSnackBar('Clock-out successful', Colors.green);
        } else {
          setState(() {
            _statusMessage =
                'Failed to clock out. Status code: ${response.statusCode}';
          });
          _showSnackBar('Failed to clock out', Colors.red);
        }
      } else {
        setState(() {
          _statusMessage = 'No authentication token or branch ID found.';
        });
        _showSnackBar('No authentication token or branch ID found', Colors.red);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
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
          title: const Text('Home Page'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
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
              const SizedBox(height: 20),
              _imagePath == null
                  ? const CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          AssetImage('assets/images/avatar_background.png'),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(File(_imagePath!)),
                    ),
              const SizedBox(height: 20),
              _isUploading
                  ? const CircularProgressIndicator()
                  : _imagePath == null
                      ? ElevatedButton(
                          onPressed: _captureImage,
                          child: const Text('Capture Image to Clock In'),
                        )
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed:
                                  _hasActiveClockIn ? _clockOut : _uploadImage,
                              child: Text(
                                  _hasActiveClockIn ? 'Clock Out' : 'Clock In'),
                            ),
                            const SizedBox(height: 10),
                            if (!_hasActiveClockIn)
                              ElevatedButton(
                                onPressed: _captureImage,
                                child: const Text('Retake Image'),
                              ),
                          ],
                        ),
              if (_hasActiveClockIn)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Stockstake(),
                      ),
                    );
                  },
                  child: const Text('Proceed to Stock-Take'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();

    if (_lastPressedTime == null ||
        now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }
}
