import 'package:flutter/material.dart';
import 'package:global_app/constants/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PreviousStocksPage extends StatefulWidget {
  const PreviousStocksPage({super.key});

  @override
  _PreviousStocksPageState createState() => _PreviousStocksPageState();
}

class _PreviousStocksPageState extends State<PreviousStocksPage> {
  List<dynamic> clockIns = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClockIns();
  }

  // Function to fetch clock-ins from API
  Future<void> fetchClockIns() async {
    final response = await http.get(Uri.parse(userProductUrl));
    if (response.statusCode == 200) {
      setState(() {
        clockIns = json.decode(response.body)['data'];
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to handle delete
  Future<void> deleteClockIn(int id) async {
    final response = await http.post(
      Uri.parse('https://your-api-endpoint.com/delete-clockin/$id'),
    );
    if (response.statusCode == 200) {
      // Successfully deleted, remove the clock-in from the list
      setState(() {
        clockIns.removeWhere((clockIn) => clockIn['id'] == id);
      });
    } else {
      // Handle delete error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete clock-in')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Stocks'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: clockIns.length,
              itemBuilder: (context, index) {
                final clockIn = clockIns[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text(
                        'Stock Date: ${clockIn['date']}, ${clockIn['store']}'),
                    subtitle: Text('Products: ${clockIn['products'].length}'),
                    trailing: clockIn['can_delete']
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteClockIn(clockIn['id']);
                            },
                          )
                        : null,
                    children: (clockIn['products'] as List).map((product) {
                      return ListTile(
                        title: Text(product['name']),
                        subtitle: Text(
                            'Opening Stock: ${product['opening_stock']} | Sales: ${product['sales']}'),
                        trailing: product['is_checked']
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
