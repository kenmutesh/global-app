import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:global_app/constants/constants.dart';
import 'package:http/http.dart' as http;

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _products = [];
  Map<String, Map<String, dynamic>> _productData = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(productsUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> products = data['products'];
        setState(() {
          _products = products;
          _productData = {
            for (var product in products)
              product['slug']: {
                'id': product['id'],
                'opening_stock': TextEditingController(),
                'sales': TextEditingController(),
                'is_checked': false,
                'quantity': TextEditingController(),
              },
          };
        });
      } else {
        setState(() {
          _products = [];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveAllStocks() async {
    final String? token = await _storage.read(key: 'token');
    final List<Map<String, dynamic>> requestData = [];

    for (var slug in _productData.keys) {
      final data = _productData[slug]!;
      requestData.add({
        'product_id': data['id'],
        'opening_stock': data['opening_stock'].text,
        'sales': data['sales'].text,
        'is_checked': data['is_checked'],
        'quantity': data['quantity'].text,
      });
    }

    final response = await http.post(
      Uri.parse(saveProductUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'stocks': requestData}),
    );

    if (response.statusCode != 200) {
      // Handle error
    }
  }

  @override
  void dispose() {
    for (var data in _productData.values) {
      data['opening_stock'].dispose();
      data['sales'].dispose();
      data['quantity'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: _products.map<Widget>((product) {
            final slug = product['slug'];
            final data = _productData[slug]!;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(product['name'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: data['opening_stock'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Opening Stock',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: data['sales'],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sales',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: data['is_checked'],
                        onChanged: (bool? value) {
                          setState(() {
                            data['is_checked'] = value ?? false;
                          });
                        },
                      ),
                      const Text('Create order'),
                    ],
                  ),
                  if (data['is_checked']) ...[
                    TextField(
                      controller: data['quantity'],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          }).toList() +
          [
            ElevatedButton(
              onPressed: _saveAllStocks,
              child: const Text('Save products'),
            ),
          ],
    );
  }
}
