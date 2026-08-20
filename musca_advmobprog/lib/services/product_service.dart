import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  String get _baseUrl =>
      host.endsWith('/') ? host.substring(0, host.length - 1) : host;

  List<Product> _parseProducts(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List productsJson = data['products'] ?? [];
    return productsJson.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$_baseUrl/products'));

    if (response.statusCode == 200) {
      return _parseProducts(response);
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query.trim());
    final response = await http.get(
      Uri.parse('$_baseUrl/products/search?q=$encodedQuery'),
    );

    if (response.statusCode == 200) {
      return _parseProducts(response);
    } else {
      throw Exception('Failed to search products');
    }
  }

  Future<List<Product>> fetchProducts() {
    return getAllProducts();
  }
}
