import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../core/api/api_client.dart';
import '../../core/api/constants.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// ─────────────────────────────────────────────────────────
/// Sephora Inspired Luxury UI
/// ─────────────────────────────────────────────────────────

class _P {
  static const background = Color(0xFFFAF9F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFF5F2EF);

  static const border = Color(0xFFEDEAE5);

  static const ink = Color(0xFF151311);
  static const inkMid = Color(0xFF6E6662);
  static const inkLight = Color(0xFFB0AAA6);

  static const accent = Color(0xFFB85C50);
  static const accentSoft = Color(0xFFF2E8E6);

  static const green = Color(0xFF3E7B58);
  static const blue = Color(0xFF3E68B8);
  static const red = Color(0xFFB84E4E);
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool loading = false;
  String? error;
  List<dynamic> orders = [];

  Future<void> load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthed) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiClient.instance.dio.get(
        ApiConstants.orders,
        queryParameters: {
          "userId": auth.user!.id,
        },
      );

      setState(() {
        orders = (res.data as List);
      });
    } on DioException catch (e) {
      final d = e.response?.data;

      final msg = (d is Map)
          ? (d["error"] ?? d["message"])?.toString()
          : null;

      setState(() {
        error = msg ?? "Failed to load orders";
      });
    } catch (_) {
      setState(() {
        error = "Failed to load orders";
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (context.read<AuthProvider>().isAuthed) {
        load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthed) {
      return Scaffold(
        backgroundColor: _P.background,
        body: Column(
          children: [
            _LuxuryHeader(
              title: "My Orders",
              subtitle: "Track your beauty purchases",
              count: null,
              onRefresh: null,
            ),

            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _StateCard(
                    icon: Icons.lock_outline_rounded,
                    title: "Sign in to view orders",
                    subtitle:
                        "Your order history and tracking updates will appear here.",
                    action: _PrimaryButton(
                      label: "Login / Register",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _P.background,
      body: Column(
        children: [
          _LuxuryHeader(
            title: "My Orders",
            subtitle: "Luxury beauty delivered",
            count: orders.length,
            onRefresh: loading ? null : load,
          ),

          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _P.ink,
                      strokeWidth: 2,
                    ),
                  )
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _StateCard(
                            icon: Icons.error_outline_rounded,
                            title: "Couldn’t load orders",
                            subtitle: error!,
                            action: _OutlineButton(
                              label: "Try Again",
                              icon: Icons.refresh_rounded,
                              onTap: load,
                            ),
                          ),
                        ),
                      )
                    : orders.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _StateCard(
                                icon: Icons.shopping_bag_outlined,
                                title: "No orders yet",
                                subtitle:
                                    "Your future beauty hauls will appear here.",
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              8,
                              20,
                              120,
                            ),
                            itemCount: orders.length,
                            itemBuilder: (_, i) {
                              final o = orders[i]
                                  as Map<String, dynamic>;

                              final items =
                                  (o["items"] as List?) ?? [];

                              final total =
                                  (o["total"] as num?)
                                          ?.toDouble() ??
                                      0.0;

                              final status =
                                  (o["status"] ?? "PENDING")
                                      .toString();

                              final paymentMethod =
                                  (o["paymentMethod"] ?? "COD")
                                      .toString();

                              final paymentStatus =
                                  (o["paymentStatus"] ?? "UNPAID")
                                      .toString();

                              final createdAtRaw =
                                  o["createdAt"]?.toString();

                              final createdAtLabel =
                                  createdAtRaw == null
                                      ? null
                                      : createdAtRaw
                                          .replaceFirst("T", " ")
                                          .split(".")
                                          .first;

                              return _OrderCard(
                                status: status,
                                total: total,
                                paymentMethod:
                                    paymentMethod,
                                paymentStatus:
                                    paymentStatus,
                                createdAtLabel:
                                    createdAtLabel,
                                items: items,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── HEADER ─────────────────

class _LuxuryHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? count;
  final VoidCallback? onRefresh;

  const _LuxuryHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _P.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: _P.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/images/blush_and_buy_logo.jpeg",
                    fit: BoxFit.cover,
                  ),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                        color: _P.ink,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      count != null
                          ? "$count orders • $subtitle"
                          : subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _P.inkMid,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: onRefresh,
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: _P.surface,
                    borderRadius:
                        BorderRadius.circular(14),
                    border:
                        Border.all(color: _P.border),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: onRefresh == null
                        ? _P.inkLight
                        : _P.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ───────────────── ORDER CARD ─────────────────

class _OrderCard extends StatelessWidget {
  final String status;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? createdAtLabel;
  final List items;

  const _OrderCard({
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAtLabel,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714)
                .withOpacity(.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(status: status),

              const Spacer(),

              Text(
                "\$${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                  color: _P.ink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.payments_outlined,
                text: paymentMethod,
              ),

              _MiniPill(
                icon: Icons.verified_outlined,
                text: paymentStatus,
              ),

              if (createdAtLabel != null)
                _MiniPill(
                  icon: Icons.schedule_outlined,
                  text: createdAtLabel!,
                ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: _P.border,
          ),

          const SizedBox(height: 18),

          const Text(
            "Items",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: _P.inkMid,
            ),
          ),

          const SizedBox(height: 14),

          ...items.map((it) {
            final m = it as Map<String, dynamic>;

            final product =
                m["product"] as Map<String, dynamic>?;

            final shade =
                m["shade"] as Map<String, dynamic>?;

            final name =
                product?["name"]?.toString() ??
                    "Product";

            final qty =
                (m["quantity"] ?? 1).toString();

            final shadeName =
                shade?["name"]?.toString();

            return Container(
              margin: const EdgeInsets.only(
                bottom: 10,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _P.surfaceWarm,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: _P.accentSoft,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: _P.accent,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                            color: _P.ink,
                            height: 1.2,
                          ),
                        ),

                        if (shadeName != null) ...[
                          const SizedBox(height: 4),

                          Text(
                            shadeName,
                            style:
                                const TextStyle(
                              fontSize: 12.5,
                              color: _P.inkMid,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _P.surface,
                      borderRadius:
                          BorderRadius.circular(
                        999,
                      ),
                      border: Border.all(
                        color: _P.border,
                      ),
                    ),
                    child: Text(
                      "x$qty",
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w800,
                        color: _P.ink,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// ───────────────── STATUS PILL ─────────────────

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();

    Color bg;
    Color text;

    switch (s) {
      case "DELIVERED":
        bg = _P.green.withOpacity(.12);
        text = _P.green;
        break;

      case "SHIPPED":
        bg = _P.blue.withOpacity(.12);
        text = _P.blue;
        break;

      case "CANCELLED":
        bg = _P.red.withOpacity(.12);
        text = _P.red;
        break;

      default:
        bg = _P.accentSoft;
        text = _P.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        s,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
          color: text,
        ),
      ),
    );
  }
}

/// ───────────────── MINI PILL ─────────────────

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: _P.surfaceWarm,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _P.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: _P.inkMid,
          ),

          const SizedBox(width: 6),

          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _P.inkMid,
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────────────── STATE CARD ─────────────────

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _P.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _P.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1714)
                .withOpacity(.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: _P.surfaceWarm,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: _P.accent,
            ),
          ),

          const SizedBox(height: 22),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _P.ink,
              letterSpacing: -.4,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: _P.inkMid,
              height: 1.5,
            ),
          ),

          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}

/// ───────────────── BUTTONS ─────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _P.ink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _P.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _P.border),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: _P.inkMid,
            ),

            const SizedBox(width: 8),

            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _P.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
