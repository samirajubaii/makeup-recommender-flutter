import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'admin_products_screen.dart';
import 'admin_brands_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_orders_screen.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _P {
  static const background  = Color(0xFFFAF9F7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkMid      = Color(0xFF6B6360);
  static const inkLight    = Color(0xFFB0AAA6);
  static const accent      = Color(0xFFB85C50);
  static const accentSoft  = Color(0xFFF2E8E6);
}

// ─── AdminHomeScreen ──────────────────────────────────────────────────────────

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _P.background,

      // ── App bar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: _P.background,
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
                        color: _P.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ADMIN",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                              color: _P.inkLight,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Dashboard",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.3,
                              color: _P.ink,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Logout
                    GestureDetector(
                      onTap: () async {
                        await context.read<AuthProvider>().logout(context);
                        if (!mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
                      },
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: _P.surfaceWarm,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _P.border),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 17,
                          color: _P.inkMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // ── Body
      body: Container(
        color: _P.background,
        child: IndexedStack(
          index: index,
          children: const [
            AdminProductsScreen(),
            AdminBrandsScreen(),
            AdminCategoriesScreen(),
            AdminOrdersScreen(),
          ],
        ),
      ),

      // ── Floating bottom nav
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _P.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1714).withOpacity(0.10),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.inventory_2_outlined,    activeIcon: Icons.inventory_2_rounded,      label: "Products",   index: 0, current: index, onTap: (v) => setState(() => index = v)),
              _NavItem(icon: Icons.business_outlined,       activeIcon: Icons.business_rounded,         label: "Brands",     index: 1, current: index, onTap: (v) => setState(() => index = v)),
              _NavItem(icon: Icons.category_outlined,       activeIcon: Icons.category_rounded,         label: "Categories", index: 2, current: index, onTap: (v) => setState(() => index = v)),
              _NavItem(icon: Icons.receipt_long_outlined,   activeIcon: Icons.receipt_long_rounded,     label: "Orders",     index: 3, current: index, onTap: (v) => setState(() => index = v)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _P.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 20,
              color: selected ? _P.accent : _P.inkLight,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: _P.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .1,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}