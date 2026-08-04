import '../models/product.dart';

class ProductService {
  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return const [
      Product(
        id: '1',
        name: 'Sample Product A',
        price: 19.99,
        description: 'A sample product for the project structure.',
      ),
      Product(
        id: '2',
        name: 'Sample Product B',
        price: 29.99,
        description: 'Another sample product for the design pattern.',
      ),
    ];
  }
}
