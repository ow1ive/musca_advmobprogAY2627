import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import 'product_details_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, this.product, this.cartProduct})
    : assert(product != null || cartProduct != null);

  final Product? product;
  final CartProduct? cartProduct;

  Product get _resolvedProduct {
    if (product != null) {
      return product!;
    }

    final item = cartProduct!;
    return Product(
      id: item.id,
      title: item.title,
      description: 'Cart item details for ${item.title}',
      category: 'Cart Item',
      price: item.price,
      discountPercentage: item.discountPercentage,
      rating: 0.0,
      stock: item.quantity,
      tags: const ['cart'],
      brand: '',
      sku: '',
      weight: 0.0,
      dimensions: const ProductDimensions(width: 0, height: 0, depth: 0),
      warrantyInformation: '',
      shippingInformation: '',
      availabilityStatus: 'In Cart',
      reviews: const [],
      returnPolicy: '',
      minimumOrderQuantity: 1,
      meta: const ProductMeta(
        createdAt: '',
        updatedAt: '',
        barcode: '',
        qrCode: '',
      ),
      images: [item.thumbnail],
      thumbnail: item.thumbnail,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProductDetailsScreen(product: _resolvedProduct);
  }
}
