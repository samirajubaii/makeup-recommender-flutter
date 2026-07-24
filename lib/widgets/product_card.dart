import 'package:flutter/material.dart';
import '../core/api/constants.dart';
import '../models/product.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _P {
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkLight    = Color(0xFFB0AAA6);
  static const accent      = Color(0xFFB85C50);
  static const accentSoft  = Color(0xFFF2E8E6);
}

// ─── ProductCard ─────────────────────────────────────────────────────────────

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  String? _buildFullImageUrl(String? img) {
    if (img == null || img.trim().isEmpty) return null;
    if (img.startsWith("http")) return img;
    return "${ApiConstants.baseUrl}$img";
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = _buildFullImageUrl(product.imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _P.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1714).withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalH  = constraints.maxHeight;
              final imageH  = (totalH * 0.57).floorToDouble();
              final contentH = totalH - imageH;

              return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Image
                  SizedBox(
                    height: imageH,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        fullImageUrl == null
                            ? Container(
                                color: _P.surfaceWarm,
                                child: Center(
                                  child: Icon(Icons.image_outlined,
                                      size: 28, color: _P.inkLight),
                                ),
                              )
                            : Image.network(
                                fullImageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, prog) {
                                  if (prog == null) return child;
                                  return Container(
                                    color: _P.surfaceWarm,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _P.inkLight,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: _P.surfaceWarm,
                                  child: Center(
                                    child: Icon(Icons.broken_image_outlined,
                                        size: 28, color: _P.inkLight),
                                  ),
                                ),
                              ),

                        // Price chip
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _PriceChip(
                            priceText: "\$${product.price.toStringAsFixed(2)}",
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Content — ClipRect hard ceiling
                  ClipRect(
                    child: SizedBox(
                      height: contentH,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max, // fill contentH exactly
                          children: [

                            // Category tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _P.accentSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "BEAUTY",
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: _P.accent,
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // Product name — Expanded so it always fills remaining
                            // space, pushing CTA to a fixed bottom position
                            Expanded(
                              child: Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -.3,
                                  color: _P.ink,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // CTA row — always at the same vertical position
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _P.surfaceWarm,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: _P.border),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "View",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _P.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  height: 30,
                                  width: 30,
                                  decoration: BoxDecoration(
                                    color: _P.ink,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Price Chip ───────────────────────────────────────────────────────────────

class _PriceChip extends StatelessWidget {
  final String priceText;
  const _PriceChip({required this.priceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        priceText,
        style: const TextStyle(
          color: _P.ink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: -.1,
        ),
      ),
    );
  }
}