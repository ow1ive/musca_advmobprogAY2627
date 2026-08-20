import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  bool _showFullDescription = false;
  bool _isAddingToCart = false;

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      final userId = await _userService.getLoggedInUserId();

      // ENHANCEMENT 3: Add selected product to cart using DummyJSON POST endpoint.
      await _cartService.addToCart(
        userId: userId,
        productId: widget.product.id,
        quantity: 1,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.title} added to cart for user $userId',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add to cart: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(elevation: 0, title: const SizedBox.shrink()),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Hero(
                tag: 'product-thumb-${product.id}',
                child: Image.network(
                  product.thumbnail,
                  width: double.infinity,
                  height: 260.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 260.h,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: Icon(Icons.image_not_supported, size: 44.sp),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              // Enhancement 2: "Read All" control to reveal the full article/product description.
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _showFullDescription = !_showFullDescription;
                  });
                },
                child: Text(_showFullDescription ? 'Show Less' : 'Read All'),
              ),
            ),
            SizedBox(height: 18.h),
            // Enhancement 2: Dedicated details view shown after card tap.
            CustomText(
              text: product.title,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                CustomText(
                  text: '\$${product.price.toStringAsFixed(2)}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(width: 12.w),
                Icon(Icons.star, color: Colors.amber, size: 18.sp),
                SizedBox(width: 4.w),
                CustomText(
                  text: product.rating.toStringAsFixed(1),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                Chip(label: Text(product.category)),
                Chip(label: Text('Stock: ${product.stock}')),
                if (product.brand.isNotEmpty) Chip(label: Text(product.brand)),
              ],
            ),
            SizedBox(height: 14.h),
            // Enhancement 3: Add this product to the user cart by posting product values to `/carts/add`.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isAddingToCart ? null : _addToCart,
                icon: _isAddingToCart
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_shopping_cart),
                label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
              ),
            ),
            SizedBox(height: 14.h),
            CustomText(
              text: product.description,
              fontSize: 14.sp,
              maxLines: _showFullDescription ? null : 4,
              overflow: _showFullDescription ? null : TextOverflow.ellipsis,
            ),
            SizedBox(height: 18.h),
            if (product.tags.isNotEmpty) ...[
              CustomText(
                text: 'Tags',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: product.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
