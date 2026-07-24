import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';

/// ───────────────── DESIGN TOKENS ─────────────────

class _P {
  static const background = Color(0xFFFAF9F7);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);

  static const border = Color(0xFFEDEAE5);

  static const ink = Color(0xFF1A1714);
  static const inkMid = Color(0xFF6B6360);
  static const inkLight = Color(0xFFB0AAA6);

  static const accent = Color(0xFFB85C50);
  static const accentSoft = Color(0xFFF2E8E6);

  static const errorSoft = Color(0xFFFDF0EE);
  static const errorBorder = Color(0xFFE8C4BE);
}

class _Shadow {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF1A1714).withOpacity(0.05),
      blurRadius: 18,
      offset: const Offset(0, 5),
    ),
  ];
}

/// ───────────────── SCREEN ─────────────────

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  bool loading = false;
  String? error;

  List<Map<String, dynamic>> brands = [];

  final nameCtrl = TextEditingController();
  final logoCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    logoCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res =
          await ApiClient.instance.dio.get(ApiConstants.brands);

      final list = (res.data as List).cast<dynamic>();

      brands = list
          .map(
            (e) => Map<String, dynamic>.from(e as Map),
          )
          .toList();
    } on DioException catch (e) {
      error = e.response?.data?["error"]?.toString() ??
          "Failed to load brands";
    } catch (_) {
      error = "Failed to load brands";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> addBrand() async {
    final name = nameCtrl.text.trim();
    final logo = logoCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brand name is required"),
        ),
      );
      return;
    }

    try {
      await ApiClient.instance.dio.post(
        ApiConstants.adminBrands,
        data: {
          "name": name,
          "logoUrl": logo.isEmpty ? null : logo,
        },
      );

      nameCtrl.clear();
      logoCtrl.clear();

      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brand added successfully ✅"),
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ??
          "Failed to add brand";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> deleteBrand(String id) async {
    try {
      await ApiClient.instance.dio.delete(
        "${ApiConstants.adminBrands}/$id",
      );

      await load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brand deleted"),
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ??
          "Failed to delete brand";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _P.inkMid,
        fontSize: 13,
      ),
      filled: true,
      fillColor: _P.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _P.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _P.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _P.ink,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading && brands.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: _P.ink,
          strokeWidth: 2,
        ),
      );
    }

    if (error != null && brands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _P.errorSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _P.errorBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _P.accent,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _P.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _SolidBtn(
                  label: "Retry",
                  icon: Icons.refresh_rounded,
                  onTap: load,
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        40,
      ),
      children: [
        /// ───── HEADER ─────

        Row(
          children: [
            const Expanded(
              child: Text(
                "Brands",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: _P.ink,
                ),
              ),
            ),

            /// Refresh button
            GestureDetector(
              onTap: loading ? null : load,
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _P.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _P.border,
                  ),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _P.inkMid,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        /// ───── ADD BRAND CARD ─────

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _P.border,
            ),
            boxShadow: _Shadow.soft,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const _SectionLabel(
                title: "Create Brand",
              ),

              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: _deco("Brand Name"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: logoCtrl,
                decoration: _deco(
                  "Logo URL (optional)",
                ),
              ),

              const SizedBox(height: 18),

              _SolidBtn(
                label: "Add Brand",
                icon: Icons.add_rounded,
                onTap: addBrand,
                fullWidth: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        /// ───── LIST HEADER ─────

        const _SectionLabel(
          title: "All Brands",
        ),

        const SizedBox(height: 14),

        /// Empty state
        if (!loading && brands.isEmpty)
          const _EmptyState(
            icon: Icons.business_outlined,
            title: "No brands yet",
            subtitle:
                "Create your first beauty brand above.",
          ),

        /// ───── BRANDS LIST ─────

        ...brands.map((b) {
          final id =
              b["id"]?.toString() ?? "";

          final name =
              b["name"]?.toString() ??
                  "Brand";

          final logoUrl =
              b["logoUrl"]?.toString();

          return Container(
            margin: const EdgeInsets.only(
              bottom: 14,
            ),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: _P.border,
              ),
              boxShadow: _Shadow.soft,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                14,
                14,
                10,
                14,
              ),
              child: Row(
                children: [
                  _BrandLogo(
                    url: logoUrl,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                FontWeight.w800,
                            color: _P.ink,
                            letterSpacing: -.2,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                _P.surfaceWarm,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              999,
                            ),
                            border: Border.all(
                              color: _P.border,
                            ),
                          ),
                          child: Text(
                            (logoUrl == null ||
                                    logoUrl
                                        .isEmpty)
                                ? "No logo URL"
                                : "Logo Connected",
                            style:
                                const TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color:
                                  _P.inkMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: () =>
                        deleteBrand(id),
                    child: Container(
                      height: 38,
                      width: 38,
                      decoration:
                          BoxDecoration(
                        color:
                            _P.errorSoft,
                        borderRadius:
                            BorderRadius
                                .circular(12),
                        border: Border.all(
                          color:
                              _P.errorBorder,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .delete_outline_rounded,
                        size: 18,
                        color: _P.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// ───────────────── BRAND LOGO ─────────────────

class _BrandLogo extends StatelessWidget {
  final String? url;

  const _BrandLogo({
    this.url,
  });

  @override
  Widget build(BuildContext context) {
    final u = (url ?? "").trim();
    final hasImage = u.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 58,
        height: 58,
        color: _P.surfaceWarm,
        child: hasImage
            ? Image.network(
                u,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return const Icon(
                    Icons
                        .broken_image_outlined,
                    color: _P.inkLight,
                  );
                },
              )
            : const Icon(
                Icons.business_outlined,
                color: _P.inkLight,
                size: 24,
              ),
      ),
    );
  }
}

/// ───────────────── LABEL ─────────────────

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: _P.inkMid,
      ),
    );
  }
}

/// ───────────────── EMPTY STATE ─────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _P.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: _P.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _P.border,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _P.inkMid,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 14,
                    color: _P.ink,
                  ),
                ),

                const SizedBox(height: 3),

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
        ],
      ),
    );
  }
}

/// ───────────────── SOLID BUTTON ─────────────────

class _SolidBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _SolidBtn({
    required this.label,
    this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width:
            fullWidth ? double.infinity : null,
        padding: fullWidth
            ? null
            : const EdgeInsets.symmetric(
                horizontal: 20,
              ),
        decoration: BoxDecoration(
          color:
              enabled ? _P.ink : _P.inkLight,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}