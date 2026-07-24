import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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
  static const successSoft = Color(0xFFEAF5EE);
  static const success     = Color(0xFF1E7A3D);
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

// ─── AdminProductsScreen ─────────────────────────────────────────────────────

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool loading = false;
  String? error;

  List<Map<String, dynamic>> products   = [];
  List<Map<String, dynamic>> brands     = [];
  List<Map<String, dynamic>> categories = [];

  final nameCtrl  = TextEditingController();
  final descCtrl  = TextEditingController();
  final priceCtrl = TextEditingController();
  final stockCtrl = TextEditingController();

  String? brandId;
  String? categoryId;
  String? finish;
  bool allSkin = false;

  String? uploadedImageUrl;
  File? pickedFile;

  final picker = ImagePicker();

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    super.dispose();
  }

  String fullImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    if (url.startsWith("http")) return url;
    return "${ApiConstants.baseUrl}$url";
  }

  Future<void> loadAll() async {
    setState(() { loading = true; error = null; });
    try {
      final pRes = await ApiClient.instance.dio.get(ApiConstants.products);
      products = (pRes.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final bRes = await ApiClient.instance.dio.get(ApiConstants.brands);
      brands = (bRes.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final cRes = await ApiClient.instance.dio.get(ApiConstants.categories);
      categories = (cRes.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      brandId    ??= brands.isNotEmpty     ? brands.first["id"].toString()      : null;
      categoryId ??= categories.isNotEmpty ? categories.first["id"].toString()  : null;
    } on DioException catch (e) {
      error = e.response?.data?["error"]?.toString() ?? "Failed to load products";
    } catch (_) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> pickImage() async {
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() { pickedFile = File(x.path); uploadedImageUrl = null; });
  }

  Future<void> uploadImage() async {
    if (pickedFile == null) return;
    try {
      final form = FormData.fromMap({
        "photo": await MultipartFile.fromFile(
          pickedFile!.path,
          filename: pickedFile!.path.split("/").last,
        ),
      });
      final res = await ApiClient.instance.dio.post(
        ApiConstants.adminUpload,
        data: form,
        options: Options(contentType: "multipart/form-data"),
      );
      final img = res.data["imageUrl"]?.toString();
      if (img == null || img.isEmpty) throw Exception("Upload returned empty url");
      setState(() => uploadedImageUrl = img);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded ✅")),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ?? "Upload failed";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> createProduct() async {
    final name      = nameCtrl.text.trim();
    final priceText = priceCtrl.text.trim();
    if (name.isEmpty || priceText.isEmpty || brandId == null || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("name, price, brand, category are required")),
      );
      return;
    }
    try {
      await ApiClient.instance.dio.post(
        ApiConstants.adminProducts,
        data: {
          "name":                   name,
          "description":            descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          "imageUrl":               uploadedImageUrl,
          "price":                  double.parse(priceText),
          "stock":                  int.tryParse(stockCtrl.text.trim()) ?? 0,
          "brandId":                brandId,
          "categoryId":             categoryId,
          "finish":                 finish,
          "suitableForAllSkinTypes": allSkin,
        },
      );
      nameCtrl.clear(); descCtrl.clear(); priceCtrl.clear(); stockCtrl.clear();
      pickedFile = null; uploadedImageUrl = null; finish = null; allSkin = false;
      await loadAll();
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ?? "Failed to create product";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await ApiClient.instance.dio.delete("${ApiConstants.adminProducts}/$id");
      await loadAll();
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ?? "Failed to delete product";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> openEditProduct(Map<String, dynamic> p) async {
    final id    = p["id"].toString();
    final name  = TextEditingController(text: p["name"]?.toString() ?? "");
    final desc  = TextEditingController(text: p["description"]?.toString() ?? "");
    final price = TextEditingController(text: (p["price"] ?? "").toString());
    final stock = TextEditingController(text: (p["stock"] ?? "").toString());
 
    String? eFinish     = p["finish"]?.toString();
    bool    eAllSkin    = (p["suitableForAllSkinTypes"] == true);
    String? eBrandId    = (p["brandId"] ?? p["brand"]?["id"])?.toString();
    String? eCategoryId = (p["categoryId"] ?? p["category"]?["id"])?.toString();
    String? eImageUrl   = p["imageUrl"]?.toString();
 
    await showDialog(
      context: context,
      barrierColor: const Color(0xFF1A1714).withOpacity(0.45),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          InputDecoration deco(String label, {String? hint}) => InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(
              color: _P.inkMid,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
            hintStyle: const TextStyle(color: _P.inkLight, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _P.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _P.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _P.ink, width: 1.5),
            ),
            filled: true,
            fillColor: _P.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          );
 
          Widget fieldGroup(String groupLabel, Widget child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: _P.inkLight,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          );
 
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 780),
              decoration: BoxDecoration(
                color: _P.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _P.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1714).withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
 
                  // ── Header bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
                    decoration: const BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: _P.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: _P.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_outlined, size: 17, color: _P.accent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Edit Product",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.3,
                                  color: _P.ink,
                                ),
                              ),
                              Text(
                                "ID: $id",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _P.inkLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: _P.surfaceWarm,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _P.border),
                            ),
                            child: const Icon(Icons.close_rounded, size: 17, color: _P.inkMid),
                          ),
                        ),
                      ],
                    ),
                  ),
 
                  // ── Scrollable body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
 
                          // Group: Identity
                          fieldGroup("Product Identity",
                            Column(
                              children: [
                                TextField(
                                  controller: name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink),
                                  decoration: deco("Name"),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: desc,
                                  maxLines: 3,
                                  style: const TextStyle(fontSize: 13.5, color: _P.ink, height: 1.5),
                                  decoration: deco("Description", hint: "Optional product description…"),
                                ),
                              ],
                            ),
                          ),
 
                          const SizedBox(height: 22),
                          const Divider(height: 1, color: _P.border),
                          const SizedBox(height: 22),
 
                          // Group: Pricing & Stock
                          fieldGroup("Pricing & Inventory",
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: price,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _P.ink),
                                    decoration: deco("Price").copyWith(prefixIcon: const Icon(Icons.attach_money_rounded, size: 17, color: _P.inkLight)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: stock,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _P.ink),
                                    decoration: deco("Stock").copyWith(prefixIcon: const Icon(Icons.inventory_2_outlined, size: 17, color: _P.inkLight)),
                                  ),
                                ),
                              ],
                            ),
                          ),
 
                          const SizedBox(height: 22),
                          const Divider(height: 1, color: _P.border),
                          const SizedBox(height: 22),
 
                          // Group: Classification
                          fieldGroup("Classification",
                            Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: eBrandId,
                                  decoration: deco("Brand").copyWith(prefixIcon: const Icon(Icons.storefront_outlined, size: 17, color: _P.inkLight)),
                                  style: const TextStyle(fontSize: 13.5, color: _P.ink, fontWeight: FontWeight.w600),
                                  dropdownColor: _P.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  items: brands.map((b) => DropdownMenuItem(
                                    value: b["id"].toString(),
                                    child: Text(b["name"].toString()),
                                  )).toList(),
                                  onChanged: (v) => setLocal(() => eBrandId = v),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: eCategoryId,
                                  decoration: deco("Category").copyWith(prefixIcon: const Icon(Icons.category_outlined, size: 17, color: _P.inkLight)),
                                  style: const TextStyle(fontSize: 13.5, color: _P.ink, fontWeight: FontWeight.w600),
                                  dropdownColor: _P.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  items: categories.map((c) => DropdownMenuItem(
                                    value: c["id"].toString(),
                                    child: Text(c["name"].toString()),
                                  )).toList(),
                                  onChanged: (v) => setLocal(() => eCategoryId = v),
                                ),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  value: eFinish,
                                  decoration: deco("Finish").copyWith(prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 17, color: _P.inkLight)),
                                  style: const TextStyle(fontSize: 13.5, color: _P.ink, fontWeight: FontWeight.w600),
                                  dropdownColor: _P.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  items: const [
                                    DropdownMenuItem(value: "MATTE",   child: Text("Matte")),
                                    DropdownMenuItem(value: "NATURAL", child: Text("Natural")),
                                    DropdownMenuItem(value: "DEWY",    child: Text("Dewy")),
                                  ],
                                  onChanged: (v) => setLocal(() => eFinish = v),
                                ),
                              ],
                            ),
                          ),
 
                          const SizedBox(height: 22),
                          const Divider(height: 1, color: _P.border),
                          const SizedBox(height: 22),
 
                          // Group: Attributes
                          fieldGroup("Attributes",
                            _LuxSwitch(
                              value: eAllSkin,
                              label: "Suitable for all skin types",
                              onChanged: (v) => setLocal(() => eAllSkin = v),
                            ),
                          ),
 
                          // Image preview
                          if ((eImageUrl ?? "").isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Divider(height: 1, color: _P.border),
                            const SizedBox(height: 22),
                            fieldGroup("Current Image",
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  fullImageUrl(eImageUrl),
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(),
                                ),
                              ),
                            ),
                          ],
 
                          const SizedBox(height: 20),
 
                          // Image note
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: _P.surfaceWarm,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _P.border),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: _P.inkLight),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "To update the image, delete and recreate the product.",
                                    style: TextStyle(fontSize: 12, color: _P.inkMid, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
 
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
 
                  // ── Footer actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: const BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      border: Border(top: BorderSide(color: _P.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _OutlineBtn(
                            label: "Cancel",
                            onTap: () => Navigator.pop(context),
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _SolidBtn(
                            label: "Save Changes",
                            icon: Icons.check_rounded,
                            fullWidth: true,
                            onTap: () async {
                              try {
                                await ApiClient.instance.dio.put(
                                  "${ApiConstants.adminProducts}/$id",
                                  data: {
                                    "name":                   name.text.trim(),
                                    "description":            desc.text.trim().isEmpty ? null : desc.text.trim(),
                                    "price":                  double.tryParse(price.text.trim()),
                                    "stock":                  int.tryParse(stock.text.trim()),
                                    "brandId":                eBrandId,
                                    "categoryId":             eCategoryId,
                                    "finish":                 eFinish,
                                    "suitableForAllSkinTypes": eAllSkin,
                                  },
                                );
                                if (!mounted) return;
                                Navigator.pop(context);
                                await loadAll();
                              } on DioException catch (e) {
                                final msg = e.response?.data?["error"]?.toString() ?? "Update failed";
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

   Future<void> addShades(String productId) async {
    final shadeNameCtrl  = TextEditingController();
    final toneCtrl       = TextEditingController();
    final undertoneCtrl  = TextEditingController();
    final List<Map<String, String>> localShades = [];
 
    await showDialog(
      context: context,
      barrierColor: const Color(0xFF1A1714).withOpacity(0.45),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          void addOne() {
            final name      = shadeNameCtrl.text.trim();
            final tone      = toneCtrl.text.trim();
            final undertone = undertoneCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Shade name is required")),
              );
              return;
            }
            localShades.add({"name": name, "tone": tone, "undertone": undertone});
            shadeNameCtrl.clear(); toneCtrl.clear(); undertoneCtrl.clear();
            setLocal(() {});
          }
 
          InputDecoration deco(String label, {String? hint}) => InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(
              color: _P.inkMid,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
            hintStyle: const TextStyle(color: _P.inkLight, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _P.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _P.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _P.ink, width: 1.5),
            ),
            filled: true,
            fillColor: _P.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          );
 
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
              decoration: BoxDecoration(
                color: _P.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _P.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1714).withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
 
                  // ── Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
                    decoration: const BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: _P.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: _P.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.palette_outlined, size: 17, color: _P.accent),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Add Shades",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.3,
                                  color: _P.ink,
                                ),
                              ),
                              Text(
                                "Build your shade range below",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _P.inkLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 34,
                            width: 34,
                            decoration: BoxDecoration(
                              color: _P.surfaceWarm,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _P.border),
                            ),
                            child: const Icon(Icons.close_rounded, size: 17, color: _P.inkMid),
                          ),
                        ),
                      ],
                    ),
                  ),
 
                  // ── Scrollable body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
 
                          // Input group
                          const Text(
                            "NEW SHADE",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: _P.inkLight,
                            ),
                          ),
                          const SizedBox(height: 10),
 
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _P.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _P.border),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: shadeNameCtrl,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _P.ink),
                                  decoration: deco("Shade name", hint: "e.g. 245 Classic Beige"),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: toneCtrl,
                                        style: const TextStyle(fontSize: 13.5, color: _P.ink),
                                        decoration: deco("Tone", hint: "e.g. Medium"),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: undertoneCtrl,
                                        style: const TextStyle(fontSize: 13.5, color: _P.ink),
                                        decoration: deco("Undertone", hint: "e.g. Neutral"),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                GestureDetector(
                                  onTap: addOne,
                                  child: Container(
                                    height: 44,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: _P.surfaceWarm,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _P.border, width: 1.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_circle_outline_rounded, size: 16, color: _P.ink),
                                        SizedBox(width: 8),
                                        Text(
                                          "Add to list",
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: _P.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
 
                          // Shade list
                          if (localShades.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text(
                                  "STAGED SHADES",
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    color: _P.inkLight,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _P.accentSoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${localShades.length}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _P.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...localShades.asMap().entries.map((entry) {
                              final i = entry.key;
                              final s = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                decoration: BoxDecoration(
                                  color: _P.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _P.border),
                                ),
                                child: Row(
                                  children: [
                                    // Index bubble
                                    Container(
                                      height: 28,
                                      width: 28,
                                      decoration: BoxDecoration(
                                        color: _P.accentSoft,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${i + 1}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: _P.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s["name"] ?? "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13.5,
                                              color: _P.ink,
                                            ),
                                          ),
                                          if ((s["tone"] ?? "").isNotEmpty || (s["undertone"] ?? "").isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                if ((s["tone"] ?? "").isNotEmpty)
                                                  _ShadeChip(label: s["tone"]!),
                                                if ((s["tone"] ?? "").isNotEmpty && (s["undertone"] ?? "").isNotEmpty)
                                                  const SizedBox(width: 5),
                                                if ((s["undertone"] ?? "").isNotEmpty)
                                                  _ShadeChip(label: s["undertone"]!),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () { localShades.remove(s); setLocal(() {}); },
                                      child: Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: _P.errorSoft,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _P.errorBorder),
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: _P.accent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
 
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
 
                  // ── Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: const BoxDecoration(
                      color: _P.surface,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      border: Border(top: BorderSide(color: _P.border)),
                    ),
                    child: Row(
                      children: [
                        if (localShades.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              "${localShades.length} shade${localShades.length == 1 ? '' : 's'} ready",
                              style: const TextStyle(
                                fontSize: 12,
                                color: _P.inkMid,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        _OutlineBtn(label: "Cancel", onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 10),
                        _SolidBtn(
                          label: "Save Shades",
                          icon: Icons.check_rounded,
                          onTap: localShades.isEmpty
                              ? null
                              : () async {
                                  try {
                                    await ApiClient.instance.dio.post(
                                      "${ApiConstants.adminProducts}/$productId/shades",
                                      data: {"shades": localShades},
                                    );
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    await loadAll();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Shades saved ✅")),
                                    );
                                  } on DioException catch (e) {
                                    final msg = e.response?.data?["error"]?.toString() ?? "Failed to add shades";
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
 
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> deleteShade(String productId, String shadeId) async {
    try {
      await ApiClient.instance.dio.delete("${ApiConstants.adminProducts}/$productId/shades/$shadeId");
      await loadAll();
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ?? "Failed to delete shade";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(loadAll);
  }

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: _P.ink, strokeWidth: 2),
      );
    }

    if (error != null) {
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
                const Icon(Icons.error_outline_rounded, color: _P.accent, size: 32),
                const SizedBox(height: 12),
                Text(error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: _P.ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _SolidBtn(label: "Retry", onTap: loadAll, fullWidth: true),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [

        // ── Page header
        Row(
          children: [
            const Expanded(
              child: Text(
                "Products",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: _P.ink,
                ),
              ),
            ),
            GestureDetector(
              onTap: loadAll,
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _P.surfaceWarm,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _P.border),
                ),
                child: const Icon(Icons.refresh_rounded, size: 18, color: _P.inkMid),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Create Product card
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
              const _SectionLabel(title: "Create Product"),
              const SizedBox(height: 16),

              TextField(controller: nameCtrl,  decoration: _deco("Name")),
              const SizedBox(height: 12),
              TextField(controller: descCtrl,  decoration: _deco("Description"), maxLines: 3),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _deco("Price"))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: _deco("Stock"))),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: brandId,
                decoration: _deco("Brand"),
                items: brands.map((b) => DropdownMenuItem(value: b["id"].toString(), child: Text(b["name"].toString()))).toList(),
                onChanged: (v) => setState(() => brandId = v),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: categoryId,
                decoration: _deco("Category"),
                items: categories.map((c) => DropdownMenuItem(value: c["id"].toString(), child: Text(c["name"].toString()))).toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: finish,
                decoration: _deco("Finish (optional)"),
                items: const [
                  DropdownMenuItem(value: "MATTE",   child: Text("MATTE")),
                  DropdownMenuItem(value: "NATURAL", child: Text("NATURAL")),
                  DropdownMenuItem(value: "DEWY",    child: Text("DEWY")),
                ],
                onChanged: (v) => setState(() => finish = v),
              ),
              const SizedBox(height: 8),

              _LuxSwitch(
                value: allSkin,
                label: "Suitable for all skin types",
                onChanged: (v) => setState(() => allSkin = v),
              ),

              const SizedBox(height: 14),

              // Image pick + upload
              Row(
                children: [
                  Expanded(
                    child: _OutlineBtn(
                      label: "Pick Image",
                      icon: Icons.photo_library_outlined,
                      onTap: pickImage,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SolidBtn(
                      label: "Upload",
                      icon: Icons.cloud_upload_rounded,
                      onTap: pickedFile == null ? null : uploadImage,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),

              if (pickedFile != null || (uploadedImageUrl ?? "").isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _P.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _P.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (uploadedImageUrl ?? "").isNotEmpty
                                ? Icons.check_circle_rounded
                                : Icons.image_outlined,
                            size: 16,
                            color: (uploadedImageUrl ?? "").isNotEmpty ? _P.success : _P.inkMid,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickedFile != null && (uploadedImageUrl ?? "").isEmpty
                                  ? pickedFile!.path.split("/").last
                                  : "Image uploaded successfully",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _P.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((uploadedImageUrl ?? "").isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fullImageUrl(uploadedImageUrl),
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              _SolidBtn(
                label: "Create Product",
                icon: Icons.add_rounded,
                onTap: createProduct,
                fullWidth: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── All Products header
        const _SectionLabel(title: "All Products"),
        const SizedBox(height: 14),

        if (products.isEmpty)
          _EmptyState(
            icon: Icons.inventory_2_outlined,
            title: "No products yet",
            subtitle: "Create your first product from the form above.",
          ),

        ...products.map((p) {
          final id     = p["id"].toString();
          final img    = p["imageUrl"]?.toString();
          final shades = (p["shades"] as List?) ?? [];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.border),
              boxShadow: _Shadow.soft,
            ),
            child: Column(
              children: [
                // Product row
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: _P.surfaceWarm,
                          child: (img ?? "").isEmpty
                              ? const Icon(Icons.image_outlined, color: _P.inkLight, size: 22)
                              : Image.network(
                                  fullImageUrl(img),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image_outlined, color: _P.inkLight),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p["name"]?.toString() ?? "Product",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                letterSpacing: -.2,
                                color: _P.ink,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _Tag(icon: Icons.attach_money_rounded, label: "${p["price"]}"),
                                _Tag(icon: Icons.inventory_2_outlined, label: "Stock: ${p["stock"]}"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Menu
                      PopupMenuButton<String>(
  color: _P.surface,
  surfaceTintColor: _P.surface,
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: const BorderSide(color: _P.border),
  ),
  icon: Container(
    height: 34,
    width: 34,
    decoration: BoxDecoration(
      color: _P.surfaceWarm,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _P.border),
    ),
    child: const Icon(
      Icons.more_vert_rounded,
      size: 18,
      color: _P.inkMid,
    ),
  ),
  onSelected: (v) {
    if (v == "edit") openEditProduct(p);
    if (v == "delete") deleteProduct(id);
    if (v == "add_shades") addShades(id);
  },
  itemBuilder: (_) => [
    PopupMenuItem(
      value: "edit",
      child: Row(
        children: const [
          Icon(Icons.edit_outlined, size: 18, color: _P.ink),
          SizedBox(width: 10),
          Text(
            "Edit",
            style: TextStyle(
              color: _P.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),

    PopupMenuItem(
      value: "add_shades",
      child: Row(
        children: const [
          Icon(Icons.palette_outlined, size: 18, color: _P.ink),
          SizedBox(width: 10),
          Text(
            "Add Shades",
            style: TextStyle(
              color: _P.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),

    PopupMenuDivider(height: 10),

    PopupMenuItem(
      value: "delete",
      child: Row(
        children: const [
          Icon(Icons.delete_outline_rounded,
              size: 18,
              color: Color(0xFF8A5A52)),
          SizedBox(width: 10),
          Text(
            "Delete",
            style: TextStyle(
              color: Color(0xFF8A5A52),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  ],
)
                    ],
                  ),
                ),

                // Shades section
                if (shades.isNotEmpty) ...[
                  Divider(height: 1, thickness: 1, color: _P.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SHADES",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: _P.inkLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...shades.map((s) {
                          final m       = Map<String, dynamic>.from(s as Map);
                          final shadeId = m["id"].toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _P.surfaceWarm,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _P.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 14,
                                  width: 14,
                                  decoration: BoxDecoration(
                                    color: _P.accentSoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _P.accent.withOpacity(0.4)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${m["name"]} · ${m["tone"]}/${m["undertone"]}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _P.ink,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => deleteShade(id, shadeId),
                                  child: Container(
                                    height: 28,
                                    width: 28,
                                    decoration: BoxDecoration(
                                      color: _P.errorSoft,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _P.errorBorder),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 14,
                                      color: _P.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Shared UI Components ─────────────────────────────────────────────────────

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
        color: _P.inkMid,
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
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _P.ink),
            ),
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
class _ShadeChip extends StatelessWidget {
  final String label;
  const _ShadeChip({required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _P.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _P.inkMid),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _P.inkMid)),
        ],
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
            child: Icon(icon, size: 20, color: _P.inkMid),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _P.ink)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: _P.inkMid)),
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

  const _SolidBtn({required this.label, this.icon, required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: enabled ? _P.ink : _P.inkLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _OutlineBtn({required this.label, this.icon, required this.onTap, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: fullWidth ? double.infinity : null,
        padding: fullWidth ? null : const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _P.border, width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: _P.inkMid),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(color: _P.ink, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}