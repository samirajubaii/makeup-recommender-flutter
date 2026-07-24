import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _Palette {
  static const background  = Color(0xFFFAF9F7);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);
  static const border      = Color(0xFFEDEAE5);
  static const ink         = Color(0xFF1A1714);
  static const inkMid      = Color(0xFF6B6360);
  static const inkLight    = Color(0xFFB0AAA6);
  static const accent      = Color(0xFFB85C50);
  static const accentSoft  = Color(0xFFF2E8E6);
  static const accentMuted = Color(0xFFDEB8B2);
}

class _Shadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

// ─── ShopTab ─────────────────────────────────────────────────────────────────

class ShopTab extends StatefulWidget {
  final void Function(String productId) onOpenProduct;
  const ShopTab({super.key, required this.onOpenProduct});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CatalogProvider>().init());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return RefreshIndicator(
      color: _Palette.accent,
      backgroundColor: _Palette.surface,
      onRefresh: () async => context.read<CatalogProvider>().fetchProducts(),
      child: CustomScrollView(
        slivers: [
          // ── Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Discover",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      color: _Palette.ink,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Luxury picks tailored for your look",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _Palette.inkMid,
                      letterSpacing: .1,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Search bar
                  _SearchBar(
                    controller: _search,
                    onSubmit: (v) => catalog.setSearch(v),
                  ),

                  const SizedBox(height: 24),

                  // ── Brands
                  _SectionLabel(
                    title: "Brands",
                    activeLabel: catalog.selectedBrandName,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          text: "All",
                          selected: catalog.selectedBrandName == null,
                          onTap: () => catalog.setBrandName(null),
                        ),
                        ...catalog.brands.map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              text: b.name,
                              selected: catalog.selectedBrandName == b.name,
                              onTap: () => catalog.setBrandName(b.name),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Categories
                  _SectionLabel(
                    title: "Categories",
                    activeLabel: catalog.selectedCategoryName,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          text: "All",
                          selected: catalog.selectedCategoryName == null,
                          onTap: () => catalog.setCategoryName(null),
                        ),
                        ...catalog.categories.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _FilterChip(
                              text: c.name,
                              selected: catalog.selectedCategoryName == c.name,
                              onTap: () => catalog.setCategoryName(c.name),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Loading bar
                  if (catalog.isLoading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        color: _Palette.accent,
                        backgroundColor: _Palette.accentSoft,
                      ),
                    )
                  else
                    const SizedBox(height: 2),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Products
          if (catalog.products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
                child: _EmptyState(
                  onClear: () {
                    _search.clear();
                    catalog.setSearch("");
                    catalog.setBrandName(null);
                    catalog.setCategoryName(null);
                  },
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p = catalog.products[i];
                    return ProductCard(
                      product: p,
                      onTap: () => widget.onOpenProduct(p.id),
                    );
                  },
                  childCount: catalog.products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65, // ← only change: was 0.72, taller cells = no overflow
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  const _SearchBar({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.border),
        boxShadow: _Shadow.soft,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, size: 20, color: _Palette.inkLight),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmit,
              style: const TextStyle(
                fontSize: 14,
                color: _Palette.ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: "Search foundation, concealer, lips…",
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: _Palette.inkLight,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onSubmit(controller.text),
            child: Container(
              height: 36,
              width: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _Palette.ink,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: Colors.white,
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
  final String? activeLabel;

  const _SectionLabel({required this.title, this.activeLabel});

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
            color: _Palette.inkMid,
          ),
        ),
        const Spacer(),
        if (activeLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _Palette.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              activeLabel!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _Palette.accent,
                letterSpacing: .1,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _Palette.ink : _Palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _Palette.ink : _Palette.border,
          ),
          boxShadow: selected ? _Shadow.soft : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: .1,
            color: selected ? Colors.white : _Palette.inkMid,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.border),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: _Palette.surfaceWarm,
              shape: BoxShape.circle,
              border: Border.all(color: _Palette.border),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 28,
              color: _Palette.inkMid,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No matches found",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
              color: _Palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try a different keyword or reset\nfilters to see more products.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: _Palette.inkMid,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _Palette.ink,
                side: const BorderSide(color: _Palette.border, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text(
                "Clear filters",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}