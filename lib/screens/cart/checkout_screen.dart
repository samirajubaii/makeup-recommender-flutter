import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';
import '../auth/login_screen.dart';
import '../orders/orders_screen.dart';

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

// ─── CheckoutScreen ───────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool placing = false;

  final phoneController    = TextEditingController();
  final cityController     = TextEditingController();
  final address1Controller = TextEditingController();
  final address2Controller = TextEditingController();
  final notesController    = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    cityController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    notesController.dispose();
    super.dispose();
  }

  bool _isValid() {
    return phoneController.text.trim().isNotEmpty &&
        cityController.text.trim().isNotEmpty &&
        address1Controller.text.trim().isNotEmpty;
  }

  Future<void> _placeOrder() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    if (!auth.isAuthed) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty.")),
      );
      return;
    }

    if (!_isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill phone, city, and address line 1.")),
      );
      return;
    }

    setState(() => placing = true);

    try {
      final orderItems = cart.items.map((it) {
        return {
          "productId": it.product.id,
          "shadeId": it.shade?["id"]?.toString(),
          "quantity": it.quantity,
        };
      }).toList();

      final body = {
        "userId": auth.user!.id,
        "items": orderItems,
        "paymentMethod": "COD",
        "phone": phoneController.text.trim(),
        "city": cityController.text.trim(),
        "addressLine1": address1Controller.text.trim(),
        "addressLine2": address2Controller.text.trim().isEmpty
            ? null
            : address2Controller.text.trim(),
        "notes": notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      };

      await ApiClient.instance.dio.post(ApiConstants.orders, data: body);

      await cart.loadCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Order placed! Payment: Cash on Delivery.")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
        (route) => route.isFirst,
      );
    } on DioException catch (e) {
      final d = e.response?.data;
      final msg =
          (d is Map) ? (d["error"] ?? d["message"])?.toString() : null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? "Failed to place order")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: _P.background,
      body: Column(
        children: [
          // ── Custom App Bar
          _CheckoutAppBar(),

          // ── Scrollable body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                // ── Order summary
                _SummaryCard(cart: cart),

                const SizedBox(height: 12),

                // ── Payment method
                _InfoCard(
                  icon: Icons.payments_outlined,
                  iconBg: _P.accentSoft,
                  iconColor: _P.accent,
                  title: "Cash on Delivery",
                  subtitle: "You will pay when the order arrives.",
                ),

                const SizedBox(height: 24),

                // ── Section label
                const _SectionLabel(title: "Delivery Information"),
                const SizedBox(height: 14),

                // ── Fields
                _StyledField(
                  controller: phoneController,
                  label: "Phone Number",
                  hint: "+1 555 000 0000",
                  icon: Icons.phone_outlined,
                  required: true,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: cityController,
                  label: "City",
                  hint: "e.g. New York",
                  icon: Icons.location_city_outlined,
                  required: true,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: address1Controller,
                  label: "Address Line 1",
                  hint: "Street & building number",
                  icon: Icons.home_outlined,
                  required: true,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: address2Controller,
                  label: "Address Line 2",
                  hint: "Apartment, floor… (optional)",
                  icon: Icons.apartment_outlined,
                ),
                const SizedBox(height: 12),
                _StyledField(
                  controller: notesController,
                  label: "Order Notes",
                  hint: "Any special instructions… (optional)",
                  icon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Sticky place order bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(12),
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
          child: GestureDetector(
            onTap: placing ? null : _placeOrder,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: placing ? const Color(0xFF3D3430) : _P.ink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: placing
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A1714).withOpacity(0.20),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Center(
                child: placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Place Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _CheckoutAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _P.background,
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: _P.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _P.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: _P.inkMid,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Logo + title
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: _P.ink,
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
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Checkout",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                        color: _P.ink,
                      ),
                    ),
                    Text(
                      "Review & place your order",
                      style: TextStyle(
                        fontSize: 11,
                        color: _P.inkLight,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final CartProvider cart;
  const _SummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _P.ink,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${cart.items.length} item${cart.items.length == 1 ? '' : 's'} in order",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.65),
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "\$${cart.total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _P.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "COD",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: .4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                    color: _P.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _P.inkMid,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -.4,
        color: _P.ink,
      ),
    );
  }
}

// ─── Styled Field ─────────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;
  final int maxLines;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .4,
                color: _P.inkMid,
              ),
            ),
            if (required)
              const Text(
                " *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _P.accent,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _P.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1714).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 14.5,
              color: _P.ink,
              letterSpacing: -.1,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _P.inkLight, fontSize: 14),
              prefixIcon: Icon(icon, size: 18, color: _P.inkMid),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
