import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';

// ─── Design Tokens (mirrors AdminProductsScreen) ──────────────────────────────

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

// ─── Status helpers ───────────────────────────────────────────────────────────

Color _statusBg(String status) {
  switch (status) {
    case "PAID":      return const Color(0xFFECF0FB);
    case "SHIPPED":   return const Color(0xFFF0EBFB);
    case "DELIVERED": return _P.successSoft;
    case "PENDING":
    default:          return const Color(0xFFFFF8EC);
  }
}

Color _statusFg(String status) {
  switch (status) {
    case "PAID":      return const Color(0xFF3D5CB8);
    case "SHIPPED":   return const Color(0xFF6B3DB8);
    case "DELIVERED": return _P.success;
    case "PENDING":
    default:          return const Color(0xFFB87C20);
  }
}

Color _statusBorder(String status) {
  switch (status) {
    case "PAID":      return const Color(0xFFBFCBF0);
    case "SHIPPED":   return const Color(0xFFCFBBF0);
    case "DELIVERED": return const Color(0xFFA8DFB8);
    case "PENDING":
    default:          return const Color(0xFFF0D8A0);
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case "PAID":      return Icons.credit_card_rounded;
    case "SHIPPED":   return Icons.local_shipping_outlined;
    case "DELIVERED": return Icons.check_circle_outline_rounded;
    case "PENDING":
    default:          return Icons.hourglass_top_rounded;
  }
}

// ─── AdminOrdersScreen ────────────────────────────────────────────────────────

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> orders = [];

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiClient.instance.dio.get(ApiConstants.adminOrders);
      orders = (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      error = e.response?.data?["error"]?.toString() ?? "Failed to load orders";
    } catch (_) {
      error = "Failed to load orders";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      await ApiClient.instance.dio.put(
        "${ApiConstants.adminOrders}/$orderId/status",
        data: {"status": status},
      );
      await load();
    } on DioException catch (e) {
      final msg = e.response?.data?["error"]?.toString() ?? "Failed to update status";
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  String shortId(String id) {
    if (id.length <= 10) return id;
    return "${id.substring(0, 10)}…";
  }

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
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _P.ink, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                _SolidBtn(label: "Retry", onTap: load, fullWidth: true),
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
                "Orders",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: _P.ink,
                ),
              ),
            ),
            GestureDetector(
              onTap: load,
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

        const SizedBox(height: 8),

        // ── Order count label
        Text(
          "${orders.length} order${orders.length == 1 ? '' : 's'}",
          style: const TextStyle(fontSize: 13, color: _P.inkMid, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 22),

        // ── Empty state
        if (orders.isEmpty)
          Container(
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
                  child: const Icon(Icons.receipt_long_outlined, size: 20, color: _P.inkMid),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("No orders yet", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _P.ink)),
                      SizedBox(height: 3),
                      Text("Orders will appear here once placed.", style: TextStyle(fontSize: 12.5, color: _P.inkMid)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ── Order cards
        ...orders.map((o) {
          final id     = o["id"].toString();
          final status = (o["status"] ?? "PENDING").toString();
          final total  = (o["total"] ?? 0).toString();

          final user  = o["user"];
          final email = (user?["email"] ?? "").toString();

          final city  = o["city"]?.toString() ?? "-";
          final a1    = o["addressLine1"]?.toString() ?? "-";
          final phone = o["phone"]?.toString() ?? "-";

          final items = (o["items"] as List? ?? [])
              .map((it) => Map<String, dynamic>.from(it as Map))
              .toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: _P.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _P.border),
              boxShadow: _Shadow.soft,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  childrenPadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,

                  // ── Collapsed header
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _statusBorder(status)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(status), size: 12, color: _statusFg(status)),
                                const SizedBox(width: 5),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _statusFg(status),
                                    letterSpacing: .4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Total chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _P.surfaceWarm,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _P.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.attach_money_rounded, size: 13, color: _P.inkLight),
                                Text(
                                  total,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _P.inkMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "#${shortId(id)}",
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.2,
                          color: _P.ink,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: _P.inkLight),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _P.inkMid,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // ── Expanded body
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _P.border)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Status update
                          const Text(
                            "UPDATE STATUS",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: _P.inkLight,
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                              prefixIcon: Icon(_statusIcon(status), size: 17, color: _statusFg(status)),
                            ),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _P.ink),
                            dropdownColor: _P.surface,
                            borderRadius: BorderRadius.circular(14),
                            items: const [
                              DropdownMenuItem(value: "PENDING",   child: Text("Pending")),
                              DropdownMenuItem(value: "PAID",      child: Text("Paid")),
                              DropdownMenuItem(value: "SHIPPED",   child: Text("Shipped")),
                              DropdownMenuItem(value: "DELIVERED", child: Text("Delivered")),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              updateStatus(id, v);
                            },
                          ),

                          const SizedBox(height: 22),
                          const Divider(height: 1, color: _P.border),
                          const SizedBox(height: 20),

                          // Delivery block
                          const Text(
                            "DELIVERY",
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: _P.inkLight,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _P.surfaceWarm,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _P.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DeliveryRow(icon: Icons.location_city_outlined,    label: "City",    value: city),
                                const SizedBox(height: 8),
                                _DeliveryRow(icon: Icons.phone_outlined,            label: "Phone",   value: phone),
                                const SizedBox(height: 8),
                                _DeliveryRow(icon: Icons.home_outlined,             label: "Address", value: a1),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),
                          const Divider(height: 1, color: _P.border),
                          const SizedBox(height: 20),

                          // Items
                          Row(
                            children: [
                              const Text(
                                "ITEMS",
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: _P.inkLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _P.accentSoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${items.length}",
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

                          if (items.isEmpty)
                            const Text(
                              "No items.",
                              style: TextStyle(fontSize: 13, color: _P.inkMid),
                            ),

                          ...items.map((m) {
                            final p         = m["product"];
                            final shade     = m["shade"];
                            final pName     = p?["name"]?.toString() ?? "Product";
                            final qty       = m["quantity"]?.toString() ?? "0";
                            final shadeName = shade?["name"]?.toString() ?? "-";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                color: _P.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _P.border),
                              ),
                              child: Row(
                                children: [
                                  // Product icon
                                  Container(
                                    height: 36,
                                    width: 36,
                                    decoration: BoxDecoration(
                                      color: _P.surfaceWarm,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _P.border),
                                    ),
                                    child: const Icon(Icons.spa_outlined, size: 16, color: _P.inkLight),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: _P.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _OrderTag(icon: Icons.format_list_numbered_rounded, label: "Qty: $qty"),
                                            _OrderTag(icon: Icons.palette_outlined, label: shadeName),
                                          ],
                                        ),
                                      ],
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
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Shared UI Components ─────────────────────────────────────────────────────

class _DeliveryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DeliveryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _P.inkLight),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _P.inkMid),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, color: _P.ink, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _OrderTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OrderTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _P.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _P.inkLight),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _P.inkMid),
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
        child: Center(
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}