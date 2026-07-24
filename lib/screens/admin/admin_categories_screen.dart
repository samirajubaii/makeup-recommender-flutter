import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';

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

  static const errorSoft   = Color(0xFFFDF0EE);
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState
    extends State<AdminCategoriesScreen> {

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> categories = [];

  final nameCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res =
          await ApiClient.instance.dio.get(ApiConstants.categories);

      final list = (res.data as List).cast<dynamic>();

      categories = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

    } on DioException catch (e) {

      error = e.response?.data?["error"]?.toString()
          ?? "Failed to load categories";

    } catch (_) {

      error = "Failed to load categories";

    } finally {

      setState(() => loading = false);

    }
  }

  Future<void> addCategory() async {
    final name = nameCtrl.text.trim();

    if (name.isEmpty) return;

    try {
      await ApiClient.instance.dio.post(
        ApiConstants.adminCategories,
        data: {
          "name": name,
        },
      );

      nameCtrl.clear();

      await load();

    } on DioException catch (e) {

      final msg = e.response?.data?["error"]?.toString()
          ?? "Failed to add category";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    try {

      await ApiClient.instance.dio.delete(
        "${ApiConstants.adminCategories}/$id",
      );

      await load();

    } on DioException catch (e) {

      final msg = e.response?.data?["error"]?.toString()
          ?? "Failed to delete category";

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

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: _P.inkMid,
      fontSize: 13,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _P.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _P.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: _P.ink,
        width: 1.5,
      ),
    ),
    filled: true,
    fillColor: _P.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
  );

  @override
  Widget build(BuildContext context) {

    if (loading && categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: _P.ink,
          strokeWidth: 2,
        ),
      );
    }

    if (error != null && categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _P.errorSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _P.errorBorder),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [

        // ── Header

        Row(
          children: [

            const Expanded(
              child: Text(
                "Categories",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: _P.ink,
                ),
              ),
            ),

            GestureDetector(
              onTap: loading ? null : load,
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
        ),

        const SizedBox(height: 24),

        // ── Add Category Card

        Container(
          decoration: BoxDecoration(
            color: _P.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _P.border),
            boxShadow: _Shadow.soft,
          ),
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const _SectionLabel(
                title: "Create Category",
              ),

              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: _deco("Category name"),
              ),

              const SizedBox(height: 16),

              _SolidBtn(
                label: "Add Category",
                icon: Icons.add_rounded,
                onTap: addCategory,
                fullWidth: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── List Header

        const _SectionLabel(
          title: "All Categories",
        ),

        const SizedBox(height: 14),

        // ── Empty State

        if (!loading &&
            error == null &&
            categories.isEmpty)

          const _EmptyState(
            icon: Icons.category_outlined,
            title: "No categories yet",
            subtitle:
                "Create your first category from the form above.",
          ),

        // ── Categories List

        ...categories.map((c) {

          final id = c["id"].toString();

          final name =
              c["name"]?.toString() ?? "Category";

          return Container(
            margin: const EdgeInsets.only(bottom: 14),

            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.border),
              boxShadow: _Shadow.soft,
            ),

            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                8,
                14,
              ),

              child: Row(
                children: [

                  // icon

                  Container(
                    width: 56,
                    height: 56,

                    decoration: BoxDecoration(
                      color: _P.surfaceWarm,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _P.border),
                    ),

                    child: const Icon(
                      Icons.category_outlined,
                      color: _P.inkMid,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // text

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _P.ink,
                          ),
                        ),

                        const SizedBox(height: 7),

                        const _Tag(
                          icon: Icons.inventory_2_outlined,
                          label: "Category",
                        ),
                      ],
                    ),
                  ),

                  // delete

                  GestureDetector(
                    onTap: () => deleteCategory(id),

                    child: Container(
                      height: 36,
                      width: 36,

                      decoration: BoxDecoration(
                        color: _P.errorSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _P.errorBorder,
                        ),
                      ),

                      child: const Icon(
                        Icons.delete_outline_rounded,
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

// ─── Shared Widgets ──────────────────────────────────────────────────────────

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

class _Tag extends StatelessWidget {

  final IconData icon;
  final String label;

  const _Tag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _P.border),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [

          Icon(
            icon,
            size: 13,
            color: _P.inkLight,
          ),

          const SizedBox(width: 5),

          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _P.inkMid,
            ),
          ),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: _P.border),
      ),

      child: Row(
        children: [

          Container(
            height: 44,
            width: 44,

            decoration: BoxDecoration(
              color: _P.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _P.border),
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
                    fontWeight: FontWeight.w800,
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
        width: fullWidth ? double.infinity : null,
        padding: fullWidth
            ? null
            : const EdgeInsets.symmetric(horizontal: 20),

        decoration: BoxDecoration(
          color: enabled
              ? _P.ink
              : _P.inkLight,
          borderRadius: BorderRadius.circular(12),
        ),

        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                fullWidth ? MainAxisSize.max : MainAxisSize.min,

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