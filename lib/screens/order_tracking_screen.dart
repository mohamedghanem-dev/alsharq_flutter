import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  static const _steps = [
    {'key': 'pending',   'label': 'قيد المراجعة',  'icon': Icons.search_rounded,      'color': Color(0xFFE8680A)},
    {'key': 'preparing', 'label': 'جاري التحضير',  'icon': Icons.restaurant_rounded,  'color': Color(0xFFF5C518)},
    {'key': 'ready',     'label': 'جاري التوصيل', 'icon': Icons.delivery_dining_rounded,'color': Color(0xFF3B82F6)},
    {'key': 'delivered', 'label': 'تم التوصيل',   'icon': Icons.check_circle_rounded, 'color': Color(0xFF22C55E)},
  ];

  int _stepIndex(String status) {
    final idx = _steps.indexWhere((s) => s['key'] == status);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textColor, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('تتبع الطلب',
              style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 16)),
            Text('#${orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId.toUpperCase()}',
              style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderGold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(
              child: Text('الطلب غير موجود', style: TextStyle(color: AppTheme.muted, fontSize: 16)));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final isCancelled = status == 'cancelled';
          final curIdx = _stepIndex(status);

          // Order info
          final total = (data['total'] as num?)?.toDouble() ?? 0;
          final address = data['address'] ?? '';
          final customerName = data['customerName'] ?? '';
          final items = (data['items'] as List?) ?? [];
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final dateStr = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
            : '—';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // === ORDER SUMMARY CARD ===
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderGold),
                  boxShadow: [BoxShadow(color: AppTheme.ember.withOpacity(0.08), blurRadius: 20)],
                ),
                child: Column(children: [
                  _infoRow('رقم الطلب', '#${orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId}',
                    valueColor: AppTheme.primary),
                  const SizedBox(height: 8),
                  _infoRow('التاريخ', dateStr),
                  const SizedBox(height: 8),
                  _infoRow('الإجمالي', '${total.toStringAsFixed(0)} ج.م',
                    valueColor: AppTheme.gold),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow('عنوان التوصيل', address),
                  ],
                ]),
              ),

              const SizedBox(height: 20),

              // === STATUS HEADER ===
              Align(
                alignment: Alignment.centerRight,
                child: Text('حالة الطلب',
                  style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 17)),
              ),
              const SizedBox(height: 16),

              // === CANCELLED STATE ===
              if (isCancelled) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Icon(Icons.cancel_rounded, color: AppTheme.red, size: 28)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('تم إلغاء الطلب', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('للاستفسار تواصل معنا', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                    ])),
                  ]),
                ),
              ] else ...[
                // === TRACKING TIMELINE ===
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: List.generate(_steps.length, (i) {
                      final step = _steps[i];
                      final isDone   = i < curIdx;
                      final isActive = i == curIdx;
                      final isPending = i > curIdx;
                      final color = isDone
                        ? const Color(0xFF22C55E)
                        : isActive
                          ? step['color'] as Color
                          : AppTheme.border;
                      final isLast = i == _steps.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: circle + line
                          Column(children: [
                            // Circle
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                              width: isDone ? 34 : isActive ? 38 : 32,
                              height: isDone ? 34 : isActive ? 38 : 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                  ? const Color(0xFF22C55E).withOpacity(0.15)
                                  : isActive
                                    ? (step['color'] as Color).withOpacity(0.15)
                                    : AppTheme.surface2,
                                border: Border.all(
                                  color: color,
                                  width: isActive ? 2.5 : 1.5,
                                ),
                                boxShadow: isActive ? [
                                  BoxShadow(
                                    color: (step['color'] as Color).withOpacity(0.4),
                                    blurRadius: 14, spreadRadius: 1,
                                  )
                                ] : null,
                              ),
                              child: Center(
                                child: isDone
                                  ? const Icon(Icons.check_rounded, color: Color(0xFF22C55E), size: 18)
                                  : Icon(
                                      step['icon'] as IconData,
                                      color: isActive ? (step['color'] as Color) : AppTheme.border,
                                      size: isActive ? 20 : 16,
                                    ),
                              ),
                            ),
                            // Connecting line
                            if (!isLast)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                width: 2.5,
                                height: 48,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: isDone
                                      ? [const Color(0xFF22C55E), const Color(0xFF22C55E).withOpacity(0.4)]
                                      : [AppTheme.border, AppTheme.surface2],
                                  ),
                                ),
                              ),
                          ]),

                          const SizedBox(width: 14),

                          // Right: text
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: isActive ? 6 : 4, bottom: isLast ? 0 : 48),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['label'] as String,
                                    style: TextStyle(
                                      color: isDone
                                        ? const Color(0xFF22C55E)
                                        : isActive
                                          ? (step['color'] as Color)
                                          : AppTheme.muted,
                                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                                      fontSize: isActive ? 16 : 14,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Container(
                                        width: 6, height: 6,
                                        decoration: BoxDecoration(
                                          color: step['color'] as Color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('الحالة الحالية',
                                        style: TextStyle(color: (step['color'] as Color).withOpacity(0.8), fontSize: 11)),
                                    ]),
                                  ],
                                  if (isDone) ...[
                                    const SizedBox(height: 2),
                                    const Text('✓ مكتمل',
                                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // === ITEMS ===
              if (items.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: const Text('الأصناف المطلوبة',
                    style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      ...items.asMap().entries.map((e) {
                        final item = e.value as Map<String, dynamic>;
                        final isLast = e.key == items.length - 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast ? null : Border(bottom: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.surface2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderGold),
                              ),
                              child: const Center(child: Text('🍖', style: TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item['name'] ?? '',
                                style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                              Text('× ${item['qty'] ?? 1}',
                                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                            ])),
                            ShaderMask(
                              shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                              child: Text(
                                '${((item['price'] as num?) ?? 0) * ((item['qty'] as num?) ?? 1)} ج',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                            ),
                          ]),
                        );
                      }),
                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          border: Border(top: BorderSide(color: AppTheme.borderGold)),
                        ),
                        child: Row(children: [
                          const Text('الإجمالي', style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w900, fontSize: 15)),
                          const Spacer(),
                          ShaderMask(
                            shaderCallback: (b) => AppTheme.goldGradient.createShader(b),
                            child: Text('${total.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // === BACK BUTTON ===
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                  label: const Text('رجوع', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),

              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
      Text(value, style: TextStyle(
        color: valueColor ?? AppTheme.textColor,
        fontWeight: FontWeight.w700, fontSize: 13)),
    ],
  );
}
