import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

const int cartUserId = 5;

class CartService {
  static final Map<int, Cart> _cachedUserCarts = {};

  Cart _mergeCartProducts(Cart existingCart, Cart incomingCart) {
    final mergedProducts = <int, CartProduct>{
      for (final product in existingCart.products) product.id: product,
    };

    for (final product in incomingCart.products) {
      final current = mergedProducts[product.id];

      if (current == null) {
        mergedProducts[product.id] = product;
        continue;
      }

      mergedProducts[product.id] = current.copyWith(
        quantity: current.quantity + product.quantity,
        total: current.total + product.total,
        discountedTotal: current.discountedTotal + product.discountedTotal,
      );
    }

    final products = mergedProducts.values.toList();
    final total = products.fold<double>(0, (sum, item) => sum + item.total);
    final discountedTotal = products.fold<double>(
      0,
      (sum, item) => sum + item.discountedTotal,
    );
    final totalQuantity = products.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return existingCart.copyWith(
      id: existingCart.id == 0 ? incomingCart.id : existingCart.id,
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      totalProducts: products.length,
      quantity: totalQuantity,
    );
  }

  Cart _recalculateCart(Cart cart, List<CartProduct> products) {
    final total = products.fold<double>(0, (sum, item) => sum + item.total);
    final discountedTotal = products.fold<double>(
      0,
      (sum, item) => sum + item.discountedTotal,
    );
    final totalQuantity = products.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return cart.copyWith(
      products: products,
      total: total,
      discountedTotal: discountedTotal,
      totalProducts: products.length,
      quantity: totalQuantity,
    );
  }

  CartProduct _copyWithQuantity(CartProduct product, int quantity) {
    final total = product.price * quantity;
    final discountedTotal =
        total - (total * (product.discountPercentage / 100));

    return product.copyWith(
      quantity: quantity,
      total: total,
      discountedTotal: discountedTotal,
    );
  }

  // ENHANCEMENT 3: Get cart by user ID using DummyJSON Cart API.
  Future<Cart> getCartByUserId(int userId) async {
    final cachedCart = _cachedUserCarts[userId];

    if (cachedCart != null) {
      return cachedCart;
    }

    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      if (cartsJson.isEmpty) {
        final emptyCart = Cart.empty(userId: userId);
        _cachedUserCarts[userId] = emptyCart;
        return emptyCart;
      }

      final cart = Cart.fromJson(cartsJson.first as Map<String, dynamic>);
      _cachedUserCarts[userId] = cart;
      return cart;
    } else {
      throw Exception('Failed to load cart for user $userId');
    }
  }

  // ENHANCEMENT 3: Add selected product to cart using DummyJSON POST endpoint.
  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final addedCart = Cart.fromJson(data);
      final existingCart =
          _cachedUserCarts[userId] ?? Cart.empty(userId: userId);
      final mergedCart = _mergeCartProducts(existingCart, addedCart);

      _cachedUserCarts[userId] = mergedCart;
      return mergedCart;
    } else {
      throw Exception('Failed to add product to cart');
    }
  }

  Future<Cart> increaseCartItemQuantity({
    required int userId,
    required CartProduct product,
  }) async {
    final updatedCart = await addToCart(
      userId: userId,
      productId: product.id,
      quantity: 1,
    );

    return updatedCart;
  }

  Future<Cart> decreaseCartItemQuantity({
    required int userId,
    required CartProduct product,
  }) async {
    final existingCart =
        _cachedUserCarts[userId] ?? await getCartByUserId(userId);
    final updatedProducts = <CartProduct>[];

    for (final item in existingCart.products) {
      if (item.id != product.id) {
        updatedProducts.add(item);
        continue;
      }

      final nextQuantity = item.quantity - 1;

      if (nextQuantity > 0) {
        updatedProducts.add(_copyWithQuantity(item, nextQuantity));
      }
    }

    final updatedCart = _recalculateCart(existingCart, updatedProducts);
    _cachedUserCarts[userId] = updatedCart;
    return updatedCart;
  }
}
