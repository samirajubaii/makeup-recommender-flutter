import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/recommendation_provider.dart';
import '../product/product_details_screen.dart';

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
  static const errorSoft   = Color(0xFFFDF0EE);
  static const errorBorder = Color(0xFFE8C4BE);
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

// ─── AiScreen ────────────────────────────────────────────────────────────────

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final picker = ImagePicker();
  File? imageFile;
  String skinType = "dry";

  Future<void> pickFromGallery() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => imageFile = File(x.path));
  }

  Future<void> pickFromCamera() async {
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return;
    setState(() => imageFile = File(x.path));
  }

  Future<void> analyze() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first")),
      );
      return;
    }
    await context.read<RecommendationProvider>().analyzeFace(
      image: imageFile!,
      skinTypeValue: skinType,
    );
  }

  void openRecommended(Map<String, dynamic> m) {
    final productId = m["productId"]?.toString();
    final shadeId   = m["shadeId"]?.toString();
    if (productId == null || productId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          productId: productId,
          preselectedShadeId: shadeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = context.watch<RecommendationProvider>();

    // No Scaffold — renders directly inside HomeScreen's Scaffold body
    return Stack(
      children: [
        // ── Scrollable content
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Hero text
            const Text(
              "Find your perfect\nfoundation shade",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1.15,
                color: _Palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upload a selfie in natural light for best accuracy.",
              style: TextStyle(
                fontSize: 13.5,
                color: _Palette.inkMid,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // ── Image picker card
            _HeroImageCard(
              imageFile: imageFile,
              onGallery: pickFromGallery,
              onCamera:  pickFromCamera,
            ),

            const SizedBox(height: 28),

             _AnalyzeLuxuryCard(
  isLoading: rec.isLoading,
  onTap: analyze,
),
const SizedBox(height: 32),

            // ── Skin type selector
            _SectionLabel(title: "Skin Type"),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SkinTypeChip(label: "Oily",        value: "oily",        selected: skinType, onTap: (v) => setState(() => skinType = v)),
                _SkinTypeChip(label: "Dry",         value: "dry",         selected: skinType, onTap: (v) => setState(() => skinType = v)),
                _SkinTypeChip(label: "Combination", value: "combination", selected: skinType, onTap: (v) => setState(() => skinType = v)),
                _SkinTypeChip(label: "Normal",      value: "normal",      selected: skinType, onTap: (v) => setState(() => skinType = v)),
              ],
              
            ),
           
const SizedBox(height: 32),

            

            // ── Error
            if (rec.error != null) ...[
              _ErrorCard(message: rec.error!),
              const SizedBox(height: 20),
            ],

            // ── Analysis results
            if (rec.tone != null || rec.undertone != null || rec.skinType != null) ...[
              _SectionLabel(title: "Your Results"),
              const SizedBox(height: 12),
              _ResultsCard(rec: rec),
              const SizedBox(height: 28),
            ],

            // ── Foundations
            _SectionLabel(title: "Recommended Foundations"),
            const SizedBox(height: 12),
            if (rec.foundations.isEmpty)
              _EmptyHint(text: "No foundation recommendations yet.")
            else
              ...rec.foundations.map((m) => _RecoCard(
                m: m,
                fullImageUrl: rec.toAbsoluteImageUrl(m["imageUrl"]?.toString()),
                onTap: () => openRecommended(m),
              )),

            const SizedBox(height: 28),

            // ── Concealers
            _SectionLabel(title: "Recommended Concealers"),
            const SizedBox(height: 12),
            if (rec.concealers.isEmpty)
              _EmptyHint(text: "No concealer recommendations yet.")
            else
              ...rec.concealers.map((m) => _RecoCard(
                m: m,
                fullImageUrl: rec.toAbsoluteImageUrl(m["imageUrl"]?.toString()),
                onTap: () => openRecommended(m),
              )),
          ],
        ),

        // ── Sticky analyze button — same pattern as original
        
      ],
    );
  }
}

// ─── Hero Image Card ──────────────────────────────────────────────────────────

class _HeroImageCard extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onGallery;
  final VoidCallback onCamera;

  const _HeroImageCard({
    required this.imageFile,
    required this.onGallery,
    required this.onCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.border),
        boxShadow: _Shadow.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: imageFile == null
                ? Container(
                    color: _Palette.surfaceWarm,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            color: _Palette.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: _Palette.border, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 34,
                            color: _Palette.inkMid,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Add a selfie to begin",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.3,
                            color: _Palette.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Front-facing · natural light",
                          style: TextStyle(fontSize: 13, color: _Palette.inkMid),
                        ),
                      ],
                    ),
                  )
                : Image.file(imageFile!, fit: BoxFit.cover, width: double.infinity),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_outlined,
                    label: "Gallery",
                    onTap: onGallery,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_outlined,
                    label: "Camera",
                    onTap: onCamera,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _Palette.surfaceWarm,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Palette.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: _Palette.inkMid),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _Palette.ink,
              ),
            ),
          ],
        ),
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
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: _Palette.inkMid,
      ),
    );
  }
}

// ─── Skin Type Chip ───────────────────────────────────────────────────────────

class _SkinTypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _SkinTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _Palette.ink : _Palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? _Palette.ink : _Palette.border),
          boxShadow: isSelected ? _Shadow.soft : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _Palette.inkMid,
          ),
        ),
      ),
    );
  }
}

// ─── Results Card ─────────────────────────────────────────────────────────────

class _ResultsCard extends StatelessWidget {
  final RecommendationProvider rec;
  const _ResultsCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.border),
        boxShadow: _Shadow.soft,
      ),
      child: Row(
        children: [
          if (rec.tone != null)
            Expanded(child: _ResultStat(label: "Tone", value: rec.tone!)),
          if (rec.undertone != null) ...[
            _VertDivider(),
            Expanded(child: _ResultStat(label: "Undertone", value: rec.undertone!)),
          ],
          if (rec.skinType != null) ...[
            _VertDivider(),
            Expanded(child: _ResultStat(label: "Skin", value: rec.skinType!)),
          ],
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  const _ResultStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _Palette.ink,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: _Palette.inkLight,
            letterSpacing: .2,
          ),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: _Palette.border,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

// ─── Error Card ───────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.errorSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Palette.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: _Palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Couldn't analyze",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _Palette.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: _Palette.inkMid, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Hint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Palette.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: _Palette.inkLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: _Palette.inkMid),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reco Card ────────────────────────────────────────────────────────────────

class _RecoCard extends StatelessWidget {
  final Map<String, dynamic> m;
  final String fullImageUrl;
  final VoidCallback onTap;

  const _RecoCard({
    required this.m,
    required this.fullImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name  = m["productName"]?.toString() ?? "Product";
    final shade = m["shade"]?.toString();
    final price = m["price"]?.toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.border),
          boxShadow: _Shadow.soft,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 72,
                height: 72,
                color: _Palette.surfaceWarm,
                child: fullImageUrl.isEmpty
                    ? const Icon(Icons.image_outlined, size: 28, color: _Palette.inkLight)
                    : Image.network(
                        fullImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_outlined, color: _Palette.inkLight),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                      height: 1.2,
                      color: _Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (shade != null)
                        _MiniTag(icon: Icons.palette_outlined, text: shade),
                      if (price != null)
                        _MiniTag(icon: Icons.attach_money_rounded, text: "\$$price"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _Palette.inkLight),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _Palette.surfaceWarm,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _Palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _Palette.inkMid),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _Palette.inkMid,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Analyze Button ───────────────────────────────────────────────────────────

class _AnalyzeLuxuryCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AnalyzeLuxuryCard({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? "Analyzing your skin..."
                      : "Analyze Face",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? "AI shade matching in progress"
                      : "Get personalized foundation matches",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: _Palette.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
