import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

import '../ai/face_scan_screen.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../product/product_details_screen.dart';
import 'shop_tab.dart';
import '../orders/orders_screen.dart';

import '../admin/admin_home_screen.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────

class _Palette {
  static const background  = Color(0xFFFAF9F7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkMid      = Color(0xFF6B6360);
  static const inkLight    = Color(0xFFB0AAA6);
  static const accent      = Color(0xFFB85C50); // terracotta / deep rose
  static const accentSoft  = Color(0xFFF2E8E6);
  static const accentMuted = Color(0xFFDEB8B2);
}

class _Radius {
  static const sm  = Radius.circular(12);
  static const md  = Radius.circular(18);
  static const lg  = Radius.circular(24);
  static const xl  = Radius.circular(32);
  static const pill = Radius.circular(999);
}

class _Shadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> medium = [
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.10),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}

// ─── HomeScreen ──────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // KEEP ORIGINAL LOGIC
    if (auth.isAuthed && auth.isAdmin) {
      return const AdminHomeScreen();
    }

    final pages = [
      ShopTab(
        onOpenProduct: (id) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: id),
          ),
        ),
      ),
      const AiScreen(),
      const CartScreen(),
      _ProfileTab(isAuthed: auth.isAuthed),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: _Palette.background,
      appBar: _LuxuryAppBar(isAuthed: auth.isAuthed),
      body: Container(
        color: _Palette.background,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(
            key: ValueKey(index),
            child: pages[index],
          ),
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: index,
        onTap: (v) => setState(() => index = v),
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _LuxuryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAuthed;

  const _LuxuryAppBar({required this.isAuthed});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _Palette.background,
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo mark
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: _Palette.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      "assets/images/blush_and_buy_logo.jpeg",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "BLUSH & BUY",
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.4,
                          color: _Palette.ink,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Luxury Beauty",
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: .4,
                          color: _Palette.inkLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isAuthed)
                  _AuthButton(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  )
                else
                  _IconChip(
                    icon: Icons.logout_rounded,
                    tooltip: "Logout",
                    onTap: () async {
                      await context.read<AuthProvider>().logout(context);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Logged out")),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AuthButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _Palette.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Sign in",
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconChip({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: _Palette.surfaceWarm,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Palette.border),
          ),
          child: Icon(icon, size: 18, color: _Palette.inkMid),
        ),
      ),
    );
  }
}

// ─── Floating Nav Bar ────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (icon: Icons.storefront_outlined,    active: Icons.storefront_rounded,     label: "Shop"),
    (icon: Icons.auto_awesome_outlined,  active: Icons.auto_awesome_rounded,   label: "AI"),
    (icon: Icons.shopping_bag_outlined,  active: Icons.shopping_bag_rounded,   label: "Cart"),
    (icon: Icons.person_outline_rounded, active: Icons.person_rounded,         label: "Profile"),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _Palette.border),
          boxShadow: _Shadow.medium,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _Palette.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.active : item.icon,
                      size: 22,
                      color: selected ? _Palette.accent : _Palette.inkLight,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 7),
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: _Palette.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Profile Tab ─────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final bool isAuthed;
  const _ProfileTab({required this.isAuthed});

  @override
  Widget build(BuildContext context) {
    if (!isAuthed) {
      return _UnauthenticatedProfile();
    }

    final user = context.read<AuthProvider>().user!;
    return _AuthenticatedProfile(user: user);
  }
}

class _UnauthenticatedProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: _Palette.surfaceWarm,
                shape: BoxShape.circle,
                border: Border.all(color: _Palette.border, width: 1.5),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 36,
                color: _Palette.inkMid,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "Welcome to\nBlush & Buy",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.15,
                color: _Palette.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Discover luxury beauty, AI-powered\nrecommendations, and seamless shopping.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.65,
                color: _Palette.inkMid,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Palette.ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  "Continue to Login",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: .1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedProfile extends StatelessWidget {
  final dynamic user;
  const _AuthenticatedProfile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // ── User card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _Palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _Palette.border),
            boxShadow: _Shadow.soft,
          ),
          child: Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: _Palette.surfaceWarm,
                  shape: BoxShape.circle,
                  border: Border.all(color: _Palette.border, width: 1.5),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: _Palette.inkMid,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                        color: _Palette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: _Palette.inkMid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Premium Member",
                        style: TextStyle(
                          color: _Palette.accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Menu items
        _MenuSection(
          items: [
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              title: "My Orders",
              subtitle: "Track and manage purchases",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              ),
            ),
            _MenuItem(
              icon: Icons.favorite_border_rounded,
              title: "Wishlist",
              subtitle: "Saved products",
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.tune_rounded,
              title: "Preferences",
              subtitle: "Customize your experience",
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 12),

        _MenuSection(
          items: [
            _MenuItem(
              icon: Icons.logout_rounded,
              title: "Sign Out",
              subtitle: "Securely sign out of your account",
              onTap: () async {
                await context.read<AuthProvider>().logout(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully")),
                  );
                }
              },
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Menu Components ─────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.border),
        boxShadow: _Shadow.soft,
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: _Palette.border,
                indent: 64,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFB04040) : _Palette.ink;
    final bgColor = isDestructive ? const Color(0xFFFFF0EE) : _Palette.surfaceWarm;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _Palette.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _Palette.inkLight,
            ),
          ],
        ),
      ),
    );
  }
}