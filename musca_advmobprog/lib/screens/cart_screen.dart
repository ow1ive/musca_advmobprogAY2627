import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

const Color _cartAccent = Color(0xFFFDBE2D);

Color _cartPageBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF17151C)
        : const Color(0xFFF7F4FB);

Color _cartCardBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF241F2B)
        : Colors.white;

Color _cartThumbBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2E2937)
        : const Color(0xFFF8F6FB);

Color _cartSecondaryText(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

Color _cartMutedButtonBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF332E3B)
        : const Color(0xFFF1EEF6);

Color _cartMutedButtonForeground(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  late Future<Cart> _cartFuture;
  int _activeUserId = 1;
  bool _isUpdatingCart = false;

  @override
  void initState() {
    super.initState();
    // ENHANCEMENT 3: Resolve cart using the authenticated user's saved id.
    _cartFuture = _loadCartForLoggedInUser();
  }

  Future<Cart> _loadCartForLoggedInUser() async {
    final userId = await _userService.getLoggedInUserId();
    _activeUserId = userId;
    return _cartService.getCartByUserId(userId);
  }

  Future<void> _updateItemQuantity({
    required CartProduct item,
    required bool increase,
  }) async {
    setState(() {
      _isUpdatingCart = true;
    });

    try {
      final updatedCart = increase
          ? await _cartService.increaseCartItemQuantity(
              userId: _activeUserId,
              product: item,
            )
          : await _cartService.decreaseCartItemQuantity(
              userId: _activeUserId,
              product: item,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _cartFuture = Future.value(updatedCart);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update cart: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cart>(
      future: _cartFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 16.sp,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final cart = snapshot.data ?? Cart.empty(userId: _activeUserId);

        if (cart.products.isEmpty) {
          return Center(
            child: CustomText(
              text: 'No cart items found.',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        final allItems = cart.products;
        final subtotal = allItems.fold<double>(
          0,
          (sum, item) => sum + item.total,
        );
        final deliveryFee = allItems.isEmpty ? 0.0 : 0.0;

        return Container(
          color: _cartPageBackground(context),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 16.h),
                  itemCount: allItems.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = allItems[index];

                    // ENHANCEMENT 3: Render only the authenticated user's cart.
                    return _CartItemCard(
                      item: item,
                      isUpdating: _isUpdatingCart,
                      onIncrease: () =>
                          _updateItemQuantity(item: item, increase: true),
                      onDecrease: () =>
                          _updateItemQuantity(item: item, increase: false),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 18.h),
                decoration: BoxDecoration(
                  color: _cartPageBackground(context),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal:', value: subtotal),
                    SizedBox(height: 8.h),
                    _SummaryRow(label: 'Delivery Fee:', value: deliveryFee),
                    SizedBox(height: 8.h),
                    _SummaryRow(label: 'User ID:', valueText: '${cart.userId}'),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _cartAccent,
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          'Confirm Order',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.isUpdating,
  });

  final CartProduct item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cartCardBackground(context),
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        // Enhancement 1: Cart items remain clickable and route to the detail screen.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(cartProduct: item)),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: _cartThumbBackground(context),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.all(8.r),
                child: Image.network(
                  item.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_outlined,
                    color: _cartSecondaryText(context),
                    size: 24.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: _cartAccent,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${item.discountPercentage.toStringAsFixed(0)}% off • \$${(item.discountedTotal > 0 ? item.discountedTotal : item.total).toStringAsFixed(2)} total',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _cartSecondaryText(context),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                children: [
                  _QuantityButton(
                    icon: Icons.add,
                    backgroundColor: _cartAccent,
                    foregroundColor: Colors.black87,
                    onTap: isUpdating ? null : onIncrease,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${item.quantity}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _QuantityButton(
                    icon: Icons.remove,
                    backgroundColor: _cartMutedButtonBackground(context),
                    foregroundColor: _cartMutedButtonForeground(context),
                    onTap: isUpdating ? null : onDecrease,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: SizedBox(
          width: 32.w,
          height: 32.w,
          child: Icon(icon, color: foregroundColor, size: 18.sp),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, this.value, this.valueText});

  final String label;
  final double? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: _cartSecondaryText(context),
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          valueText ?? '\$${(value ?? 0).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: _cartAccent,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
