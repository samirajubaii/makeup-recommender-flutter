import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';

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

// ─── Shared input decoration ─────────────────────────────────────────────────

InputDecoration _deco(String label) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(color: _P.inkMid, fontSize: 13),
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
    borderSide: const BorderSide(color: _P.ink, width: 1.5),
  ),
  filled: true,
  fillColor: _P.surface,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

// ─── AdminDashboardScreen ────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminProvider>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _P.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Container(
            color: _P.background,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Dashboard",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: _P.ink,
                            ),
                          ),
                        ),
                        _IconBtn(
                          icon: Icons.refresh_rounded,
                          enabled: !admin.loading,
                          onTap: admin.loading ? null : () => admin.loadAll(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Tab bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _P.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _P.border),
                    ),
                    child: TabBar(
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      labelColor: _P.ink,
                      unselectedLabelColor: _P.inkLight,
                      indicator: BoxDecoration(
                        color: _P.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _P.border),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A1714).withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: "Brands"),
                        Tab(text: "Categories"),
                        Tab(text: "Products"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Error banner
            if (admin.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _P.errorSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _P.errorBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: _P.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        admin.error!,
                        style: const TextStyle(fontSize: 13, color: _P.ink),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _BrandsTab(),
                  _CategoriesTab(),
                  _ProductsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Brands Tab ───────────────────────────────────────────────────────────────

class _BrandsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Brands",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                    color: _P.ink,
                  ),
                ),
              ),
              _AddButton(
                label: "Add Brand",
                onTap: admin.loading ? null : () => _showAddBrand(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: admin.loading && admin.brands.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _P.ink, strokeWidth: 2))
              : admin.brands.isEmpty
                  ? _EmptyState(icon: Icons.business_outlined, title: "No brands yet", subtitle: "Add your first brand above.")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: admin.brands.length,
                      itemBuilder: (_, i) {
                        final b    = admin.brands[i];
                        final id   = b["id"]?.toString() ?? "";
                        final name = b["name"]?.toString() ?? "Brand";
                        return _ListCard(
                          title: name,
                          icon: Icons.business_rounded,
                          onDelete: admin.loading ? null : () => admin.deleteBrand(id),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddBrand(BuildContext context) {
    final name = TextEditingController();
    final logo = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _LuxDialog(
        title: "Create Brand",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: _deco("Name")),
            const SizedBox(height: 12),
            TextField(controller: logo, decoration: _deco("Logo URL (optional)")),
          ],
        ),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          await context.read<AdminProvider>().createBrand(
            name: name.text.trim(),
            logoUrl: logo.text.trim().isEmpty ? null : logo.text.trim(),
          );
          if (context.mounted) Navigator.pop(context);
        },
        confirmLabel: "Create",
      ),
    );
  }
}

// ─── Categories Tab ───────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                    color: _P.ink,
                  ),
                ),
              ),
              _AddButton(
                label: "Add Category",
                onTap: admin.loading ? null : () => _showAddCategory(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: admin.loading && admin.categories.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _P.ink, strokeWidth: 2))
              : admin.categories.isEmpty
                  ? _EmptyState(icon: Icons.category_outlined, title: "No categories yet", subtitle: "Add your first category above.")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: admin.categories.length,
                      itemBuilder: (_, i) {
                        final c    = admin.categories[i];
                        final id   = c["id"]?.toString() ?? "";
                        final name = c["name"]?.toString() ?? "Category";
                        return _ListCard(
                          title: name,
                          icon: Icons.category_rounded,
                          onDelete: admin.loading ? null : () => admin.deleteCategory(id),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddCategory(BuildContext context) {
    final name = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _LuxDialog(
        title: "Create Category",
        content: TextField(controller: name, decoration: _deco("Name")),
        onCancel: () => Navigator.pop(context),
        onConfirm: () async {
          await context.read<AdminProvider>().createCategory(name: name.text.trim());
          if (context.mounted) Navigator.pop(context);
        },
        confirmLabel: "Create",
      ),
    );
  }
}

// ─── Products Tab ─────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Products",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.4,
                    color: _P.ink,
                  ),
                ),
              ),
              _AddButton(
                label: "Add Product",
                onTap: admin.loading ? null : () => _showAddProduct(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: admin.loading && admin.products.isEmpty
              ? const Center(child: CircularProgressIndicator(color: _P.ink, strokeWidth: 2))
              : admin.products.isEmpty
                  ? _EmptyState(icon: Icons.inventory_2_outlined, title: "No products yet", subtitle: "Add your first product above.")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: admin.products.length,
                      itemBuilder: (_, i) {
                        final p     = admin.products[i];
                        final id    = p["id"]?.toString() ?? "";
                        final name  = p["name"]?.toString() ?? "Product";
                        final price = p["price"]?.toString() ?? "-";
                        return _ListCard(
                          title: name,
                          subtitle: "\$$price",
                          icon: Icons.inventory_2_rounded,
                          onDelete: admin.loading ? null : () => admin.deleteProduct(id),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showAddProduct(BuildContext context) {
    final admin = context.read<AdminProvider>();

    if (admin.brands.isEmpty || admin.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Create at least 1 brand and 1 category first.")),
      );
      return;
    }

    final name      = TextEditingController();
    final price     = TextEditingController(text: "0");
    final stock     = TextEditingController(text: "0");
    final imageUrl  = TextEditingController();
    final desc      = TextEditingController();

    String  brandId    = admin.brands.first["id"].toString();
    String  categoryId = admin.categories.first["id"].toString();
    String? finish;
    bool    allSkin    = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => _LuxDialog(
          title: "Create Product",
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name,     decoration: _deco("Name")),
              const SizedBox(height: 12),
              TextField(controller: price,    decoration: _deco("Price"),    keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: stock,    decoration: _deco("Stock"),    keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: imageUrl, decoration: _deco("Image URL (optional)")),
              const SizedBox(height: 12),
              TextField(controller: desc,     decoration: _deco("Description (optional)")),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: brandId,
                decoration: _deco("Brand"),
                items: admin.brands.map((b) => DropdownMenuItem(value: b["id"].toString(), child: Text(b["name"]?.toString() ?? "Brand"))).toList(),
                onChanged: (v) => setLocal(() => brandId = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoryId,
                decoration: _deco("Category"),
                items: admin.categories.map((c) => DropdownMenuItem(value: c["id"].toString(), child: Text(c["name"]?.toString() ?? "Category"))).toList(),
                onChanged: (v) => setLocal(() => categoryId = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: finish,
                decoration: _deco("Finish (optional)"),
                items: const [
                  DropdownMenuItem(value: null,       child: Text("None")),
                  DropdownMenuItem(value: "MATTE",    child: Text("MATTE")),
                  DropdownMenuItem(value: "NATURAL",  child: Text("NATURAL")),
                  DropdownMenuItem(value: "DEWY",     child: Text("DEWY")),
                ],
                onChanged: (v) => setLocal(() => finish = v),
              ),
              const SizedBox(height: 8),
              _LuxSwitch(
                value: allSkin,
                label: "Suitable for all skin types",
                onChanged: (v) => setLocal(() => allSkin = v),
              ),
            ],
          ),
          onCancel: () => Navigator.pop(ctx),
          onConfirm: () async {
            await context.read<AdminProvider>().createProduct(
              name:                   name.text.trim(),
              price:                  double.tryParse(price.text.trim()) ?? 0,
              stock:                  int.tryParse(stock.text.trim()) ?? 0,
              brandId:                brandId,
              categoryId:             categoryId,
              imageUrl:               imageUrl.text.trim().isEmpty ? null : imageUrl.text.trim(),
              description:            desc.text.trim().isEmpty ? null : desc.text.trim(),
              finish:                 finish,
              suitableForAllSkinTypes: allSkin,
            );
            if (context.mounted) Navigator.pop(ctx);
          },
          confirmLabel: "Create",
        ),
      ),
    );
  }
}

// ─── Shared UI Components ─────────────────────────────────────────────────────

class _LuxDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;

  const _LuxDialog({
    required this.title,
    required this.content,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _P.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _P.ink),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: content,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // Cancel
        GestureDetector(
          onTap: onCancel,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.border, width: 1.5),
            ),
            child: const Center(
              child: Text("Cancel",
                  style: TextStyle(color: _P.ink, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Confirm
        GestureDetector(
          onTap: onConfirm,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: _P.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                confirmLabel,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onDelete;

  const _ListCard({
    required this.title,
    required this.icon,
    this.subtitle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _P.surfaceWarm,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _P.border),
            ),
            child: Icon(icon, size: 18, color: _P.inkMid),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: _P.ink)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 12.5, color: _P.inkMid)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: _P.errorSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _P.errorBorder),
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 16, color: _P.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: onTap != null ? _P.ink : _P.inkLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _IconBtn({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: _P.surfaceWarm,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.border),
        ),
        child: Icon(icon, size: 18, color: enabled ? _P.inkMid : _P.inkLight),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
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
              child: Icon(icon, size: 20, color: _P.inkMid),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14, color: _P.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12.5, color: _P.inkMid)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxSwitch extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _LuxSwitch({required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _P.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: _P.ink)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _P.ink,
            activeTrackColor: _P.accentSoft,
          ),
        ],
      ),
    );
  }
}