import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';
import '../product/product_details_screen.dart';
import 'checkout_screen.dart';

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

// ─── CartScreen ───────────────────────────────────────────────────────────────

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final auth = context.read<AuthProvider>();
      final cart = context.read<CartProvider>();
      if (!auth.isAuthed) {
        cart.setGuestMode();
        return;
      }
      await cart.loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    // ── Not authenticated — no Scaffold, plain layout
    if (!auth.isAuthed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(title: "My Cart", subtitle: null, onRefresh: null),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: _StateCard(
                  icon: Icons.lock_outline_rounded,
                  iconColor: _P.accent,
                  iconBg: _P.accentSoft,
                  title: "Sign in to view your cart",
                  subtitle: "We'll keep your items safe once you sign in.",
                  action: _PrimaryButton(
                    label: "Login / Register",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Main cart UI — no Scaffold
    return Stack(
      children: [
        // ── Scrollable area
        Builder(builder: (context) {
          if (cart.loading) {
            return const Center(
              child: CircularProgressIndicator(color: _P.ink, strokeWidth: 2),
            );
          }

          if (cart.error != null) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    title: "My Cart",
                    subtitle: null,
                    onRefresh: () => cart.loadCart(),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: _StateCard(
                        icon: Icons.wifi_off_rounded,
                        iconColor: _P.inkMid,
                        iconBg: _P.surfaceWarm,
                        title: "Something went wrong",
                        subtitle: cart.error!,
                        action: _OutlineButton(
                          label: "Try again",
                          icon: Icons.refresh_rounded,
                          onTap: () => cart.loadCart(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (cart.items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(
                    title: "My Cart",
                    subtitle: null,
                    onRefresh: () => cart.loadCart(),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: _StateCard(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: _P.inkMid,
                        iconBg: _P.surfaceWarm,
                        title: "Your cart is empty",
                        subtitle: "Add something you love — we'll bring it here.",
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Items list
          return ListView.builder(
            // bottom padding: checkout bar (~90) + floating nav bar (~112)
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 222),
            itemCount: cart.items.length + 1, // +1 for header
            itemBuilder: (_, i) {
              if (i == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PageHeader(
                      title: "My Cart",
                      subtitle: "${cart.items.length} item${cart.items.length == 1 ? '' : 's'}",
                      onRefresh: cart.loading ? null : () => cart.loadCart(),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }

              final item = cart.items[i - 1];
              return _CartItemCard(
                name: item.product.name,
                shadeName: item.shadeName,
                qty: item.quantity,
                unitPrice: item.unitPrice,
                onDelete: () => cart.removeItem(item.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(
                      productId: item.product.id,
                      preselectedShadeId: item.shade?["id"]?.toString(),
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // ── Checkout bar — floats above the nav bar
        if (!cart.loading && cart.error == null && cart.items.isNotEmpty)
          Positioned(
            left: 20,
            right: 20,
            bottom: 112, // clears HomeScreen's floating nav bar
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              decoration: BoxDecoration(
                color: _P.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _P.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1714).withOpacity(0.10),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Total
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TOTAL",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: _P.inkLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "\$${cart.total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.6,
                            color: _P.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkout button
                  GestureDetector(
                    onTap: cart.items.isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: cart.items.isEmpty ? _P.inkLight : _P.ink,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: cart.items.isEmpty
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF1A1714).withOpacity(0.22),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Checkout",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRefresh;

  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1,
                  color: _P.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _P.inkMid,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onRefresh != null)
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: _P.surfaceWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _P.border),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: _P.inkMid,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Cart Item Card ───────────────────────────────────────────────────────────

class _CartItemCard extends StatelessWidget {
  final String name;
  final String? shadeName;
  final int qty;
  final double unitPrice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.name,
    required this.shadeName,
    required this.qty,
    required this.unitPrice,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _P.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1714).withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon tile
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: _P.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_mall_outlined,
                color: _P.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                      height: 1.2,
                      color: _P.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (shadeName != null)
                        _Pill(text: shadeName!, icon: Icons.palette_outlined),
                      _Pill(text: "×$qty", icon: Icons.confirmation_number_outlined),
                      _Pill(
                        text: "\$${unitPrice.toStringAsFixed(2)}",
                        icon: Icons.attach_money_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8C4BE)),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFB04040),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pill Tag ─────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _P.surfaceWarm,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _P.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _P.inkLight),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _P.inkMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── State Card ───────────────────────────────────────────────────────────────

class _StateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? action;

  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
              color: _P.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: _P.inkMid,
              height: 1.55,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _P.ink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1714).withOpacity(0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Login / Register",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .1,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _P.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _P.inkMid),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _P.ink,
                letterSpacing: .1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}