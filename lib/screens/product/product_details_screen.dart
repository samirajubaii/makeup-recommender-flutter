import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/constants.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

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
  static const success     = Color(0xFF1E7A3D);
  static const successSoft = Color(0xFFEAF5EE);
  static const info        = Color(0xFF225DB3);
  static const infoSoft    = Color(0xFFEAF0FB);
}

class _Shadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 6),
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

// ─── ProductDetailsScreen ────────────────────────────────────────────────────

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String? preselectedShadeId;
  final String? preselectedShadeName;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.preselectedShadeId,
    this.preselectedShadeName,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? selectedShadeId;
  int qty = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ProductProvider>().fetchProductDetails(widget.productId);
      if (widget.preselectedShadeId != null) {
        setState(() => selectedShadeId = widget.preselectedShadeId);
      }
    });
  }

  String _fullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return "";
    if (imageUrl.startsWith("http")) return imageUrl;
    return "${ApiConstants.baseUrl}$imageUrl";
  }

  @override
  Widget build(BuildContext context) {
    final pprov = context.watch<ProductProvider>();
    final cart  = context.read<CartProvider>();
    final auth  = context.read<AuthProvider>();
    final Product? p = pprov.selected;

    return Scaffold(
      backgroundColor: _P.background,
      appBar: _DetailsAppBar(),
      body: pprov.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _P.ink, strokeWidth: 2),
            )
          : p == null
              ? Center(
                  child: Text(
                    "Product not found",
                    style: TextStyle(color: _P.inkMid, fontSize: 15),
                  ),
                )
              : Stack(
                  children: [
                    // ── Scrollable content
                    ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
                      children: [
                        // ── Hero image
                        _HeroImage(
                          imageUrl: _fullImageUrl(p.imageUrl),
                          priceText: "\$${p.price.toStringAsFixed(2)}",
                        ),

                        const SizedBox(height: 20),

                        // ── Product name
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                            height: 1.1,
                            color: _P.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Curated for your look · Tap shades to preview",
                          style: TextStyle(
                            fontSize: 13,
                            color: _P.inkMid,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Badge(
                              icon: Icons.inventory_2_outlined,
                              text: "In stock (${p.stock})",
                              tone: _Tone.success,
                            ),
                            if (p.finish != null)
                              _Badge(
                                icon: Icons.blur_on_rounded,
                                text: "Finish: ${p.finish.toString().split(".").last}",
                                tone: _Tone.rose,
                              ),
                            if (p.suitableForAllSkinTypes == true)
                              _Badge(
                                icon: Icons.verified_outlined,
                                text: "All skin types",
                                tone: _Tone.info,
                              ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ── Shades
                        if (p.shades.isNotEmpty) ...[
                          _SectionLabel(
                            title: "Choose Shade",
                            trailing: selectedShadeId == null ? "Required" : "Selected ✓",
                            trailingAccent: selectedShadeId != null,
                          ),
                          const SizedBox(height: 12),

                          if (widget.preselectedShadeName != null) ...[
                            _AiPickCard(shadeName: widget.preselectedShadeName!),
                            const SizedBox(height: 10),
                          ],

                          ...p.shades.map((s) {
                            final isSelected = selectedShadeId == s.id;
                            return _ShadeRow(
                              selected: isSelected,
                              title: s.name,
                              subtitle: "${s.tone} · ${s.undertone}",
                              onTap: () => setState(() => selectedShadeId = s.id),
                            );
                          }),
                        ],

                        const SizedBox(height: 26),

                        // ── Quantity
                        _SectionLabel(title: "Quantity"),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _QtyStepper(
                            qty: qty,
                            onMinus: qty <= 1 ? null : () => setState(() => qty--),
                            onPlus: () => setState(() => qty++),
                          ),
                        ),
                      ],
                    ),

                    // ── Sticky bottom CTA bar
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: _BottomBar(
                        qty: qty,
                        total: p.price * qty,
                        onAddToCart: () async {
                          if (!auth.isAuthed) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                            return;
                          }
                          if (p.shades.isNotEmpty && selectedShadeId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please choose a shade first.")),
                            );
                            return;
                          }
                          try {
                            await cart.addToCart(
                              productId: p.id,
                              quantity: qty,
                              shadeId: selectedShadeId,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Added to cart")),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Exception: ${e.toString()}")),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _DetailsAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _P.background,
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: _P.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _P.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: _P.inkMid,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Product Details",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.3,
                      color: _P.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Image ───────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final String priceText;

  const _HeroImage({required this.imageUrl, required this.priceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.border),
        boxShadow: _Shadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (imageUrl.isEmpty)
            Center(
              child: Icon(Icons.image_not_supported_outlined,
                  size: 52, color: _P.inkLight),
            )
          else
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 52, color: _P.inkLight),
              ),
            ),

          // Subtle bottom scrim for price chip readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.18),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),

          // Price badge
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: _P.ink.withOpacity(0.82),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
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
  final String? trailing;
  final bool trailingAccent;

  const _SectionLabel({
    required this.title,
    this.trailing,
    this.trailingAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: _P.inkMid,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: trailingAccent ? _P.accentSoft : _P.surfaceWarm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: trailingAccent ? _P.accent : _P.inkMid,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── AI Pick Card ─────────────────────────────────────────────────────────────

class _AiPickCard extends StatelessWidget {
  final String shadeName;
  const _AiPickCard({required this.shadeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _P.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.accentSoft),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 18, color: _P.accent),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13.5, color: _P.inkMid),
                children: [
                  TextSpan(
                    text: "AI Pick: ",
                    style: TextStyle(fontWeight: FontWeight.w700, color: _P.ink),
                  ),
                ],
              )..children?.add(TextSpan(text: shadeName)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

enum _Tone { success, rose, info }

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final _Tone tone;

  const _Badge({required this.icon, required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    late Color fg, bg, bd;
    switch (tone) {
      case _Tone.success:
        fg = _P.success; bg = _P.successSoft; bd = _P.success.withOpacity(0.2);
        break;
      case _Tone.info:
        fg = _P.info; bg = _P.infoSoft; bd = _P.info.withOpacity(0.2);
        break;
      case _Tone.rose:
        fg = _P.accent; bg = _P.accentSoft; bd = _P.accent.withOpacity(0.2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: .1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shade Row ────────────────────────────────────────────────────────────────

class _ShadeRow extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShadeRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _P.accentSoft : _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _P.accent.withOpacity(0.5) : _P.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? _Shadow.soft : [],
        ),
        child: Row(
          children: [
            // Shade dot
            Container(
              height: 20,
              width: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _P.accentSoft : _P.surfaceWarm,
                border: Border.all(
                  color: selected ? _P.accent : _P.border,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                      color: selected ? _P.accent : _P.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _P.inkMid,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: selected
                  ? const Icon(Icons.check_circle_rounded,
                      key: ValueKey("on"), color: _P.accent, size: 20)
                  : const Icon(Icons.circle_outlined,
                      key: ValueKey("off"), color: _P.inkLight, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Qty Stepper ──────────────────────────────────────────────────────────────

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _P.border),
        boxShadow: _Shadow.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: Icons.remove_rounded,
            enabled: onMinus != null,
            onTap: onMinus,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "$qty",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _P.ink,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            enabled: true,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: enabled ? _P.surfaceWarm : _P.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? _P.ink : _P.inkLight,
        ),
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int qty;
  final double total;
  final VoidCallback onAddToCart;

  const _BottomBar({
    required this.qty,
    required this.total,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _P.border),
        boxShadow: _Shadow.medium,
      ),
      child: Row(
        children: [
          // Qty + total summary
          Column(
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
                "\$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                  color: _P.ink,
                ),
              ),
              Text(
                "Qty: $qty",
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _P.inkLight,
                  letterSpacing: .1,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Add to cart button
          Expanded(
            child: GestureDetector(
              onTap: onAddToCart,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: _P.ink,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _P.ink.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      "Add to Cart",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}