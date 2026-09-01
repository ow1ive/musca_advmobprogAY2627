import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, this.username = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _cartPrimary = Color(0xFF3346A4);
  final UserService _userService = UserService();
  int _selectedIndex = 0;
  String _profileHeaderName = 'Profile';
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadProfileHeaderName();
  }

  Future<void> _loadProfileHeaderName() async {
    final user = await _userService.getUser();

    if (!mounted) {
      return;
    }

    setState(() {
      _profileHeaderName = user.firstName.isNotEmpty
          ? user.firstName
          : (user.username.isNotEmpty ? user.username : 'Profile');
    });
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }

  @override
  Widget build(BuildContext context) {
    final isCartTab = _selectedIndex == 1;
    final isProfileTab = _selectedIndex == 2;
    final hasAccentHeader = isCartTab || isProfileTab;
    final cartPageBackground = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF17151C)
        : const Color(0xFFF7F4FB);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isCartTab ? cartPageBackground : null,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: hasAccentHeader ? 0 : 2,
          backgroundColor: hasAccentHeader ? _cartPrimary : null,
          foregroundColor: hasAccentHeader ? Colors.white : null,
          title: _selectedIndex == 0
              ? Image.asset(
                  'assets/images/nubdexchange_logo (1).png',
                  scale: 11.sp,
                )
              : CustomText(
                  text: _selectedIndex == 1
                      ? 'Cart'
                      : _selectedIndex == 2
                      ? _profileHeaderName
                      : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: const <Widget>[
            ProductScreen(),
            CartScreen(),
            ProfileScreen(),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        // ENHANCEMENT 2: Chat converted from bottom navigation to FloatingActionButton.
        floatingActionButton: isCartTab
            // ENHANCEMENT 2: Hide Chat FAB on cart_screen.
            ? null
            : FloatingActionButton(
                backgroundColor: isCartTab
                    ? _cartPrimary
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _ChatScreen()),
                  );
                },
                child: Icon(Icons.chat_bubble_rounded, size: 24.sp),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BottomAppBar(
          color: isCartTab ? cartPageBackground : Theme.of(context).cardColor,
          child: SizedBox(
            height: 64.h,
            child: Row(
              children: [
                Expanded(
                  child: _NavAction(
                    icon: Icons.work_outline,
                    isSelected: _selectedIndex == 0,
                    selectedColor: isCartTab ? _cartPrimary : null,
                    unselectedColor: isCartTab ? const Color(0xFF78707E) : null,
                    onTap: () => _onTappedBar(0),
                  ),
                ),
                Expanded(
                  child: _NavAction(
                    icon: Icons.shopping_cart_checkout,
                    isSelected: _selectedIndex == 1,
                    selectedColor: isCartTab ? _cartPrimary : null,
                    unselectedColor: isCartTab ? const Color(0xFF78707E) : null,
                    onTap: () => _onTappedBar(1),
                  ),
                ),
                Expanded(
                  child: _NavAction(
                    icon: Icons.person,
                    isSelected: _selectedIndex == 2,
                    selectedColor: isCartTab ? _cartPrimary : null,
                    unselectedColor: isCartTab ? const Color(0xFF78707E) : null,
                    onTap: () => _onTappedBar(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
    this.unselectedColor,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? (selectedColor ?? Theme.of(context).colorScheme.primary)
        : (unselectedColor ?? Theme.of(context).iconTheme.color);

    return InkWell(
      onTap: onTap,
      child: Center(
        child: Icon(icon, color: color, size: 24.sp),
      ),
    );
  }
}

class _ChatScreen extends StatelessWidget {
  const _ChatScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(
        child: CustomText(
          text: 'Chat screen placeholder',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
