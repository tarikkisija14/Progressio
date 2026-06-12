
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'package:progressio_mobile/providers/payment_provider.dart';
import 'package:progressio_mobile/providers/subscription_provider.dart';
import 'package:progressio_mobile/utils/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  // Cijene moraju biti identične PlanCatalog-u na backendu
  static const _plans = {
    'Monthly': _Plan('Monthly', '\$9.99', '/month', null),
    'Yearly':  _Plan('Yearly',  '\$79.99', '/year', 'Save 33%'),
  };

  static const _perks = [
    (Icons.bar_chart_rounded,          'Advanced stats',    'Hours tracked, genre breakdown, activity heatmap'),
    (Icons.wrap_text_rounded,          'Year in Review',    'Your personal Wrapped — top shows, books, games'),
    (Icons.people_alt_rounded,         'Shared lists',      'Collaborate on watchlists with friends'),
    (Icons.notifications_active_outlined, 'Smart alerts',   'Get notified when new episodes drop'),
    (Icons.emoji_events_outlined,      'All achievements',  'Unlock the full achievement catalog'),
  ];

  String _selectedPlan = 'Monthly';
  bool _loading = false;
  String? _error;
  bool _success = false;

  Future<void> _subscribe() async {
    setState(() { _loading = true; _error = null; });

    try {
  
      final clientSecret = await context
          .read<PaymentProvider>()
          .createPaymentIntent(_selectedPlan);

      
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Progressio',
          style: ThemeMode.dark,
        ),
      );

     
      await Stripe.instance.presentPaymentSheet();

      
      await context.read<SubscriptionProvider>().getMine();

      if (mounted) setState(() { _loading = false; _success = true; });

    } on StripeException catch (e) {
     
      if (mounted) {
        final msg = e.error.localizedMessage ?? e.error.message ?? 'Payment cancelled.';
        setState(() { _loading = false; _error = msg; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Go Premium',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _success ? _buildSuccess() : _buildContent(),
    );
  }

  // ─── Success ─────────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.premium.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.premium, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('Welcome to Premium!',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'Your subscription is active.\nEnjoy all premium features!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.premium,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Get Started',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main content ─────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Center(
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB840), Color(0xFFFF7A00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.premium.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Colors.black, size: 38),
                ),
                const SizedBox(height: 16),
                const Text('Unlock everything',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'Track smarter. Discover more.\nShare with friends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Plan selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _plans.entries.map((e) {
                final isSelected = _selectedPlan == e.key;
                final plan = e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlan = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.premium : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(plan.price,
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              )),
                          Text('${plan.label}${plan.period}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black.withValues(alpha: 0.65)
                                    : AppColors.textFaint,
                                fontSize: 12,
                              )),
                          if (plan.badge != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black.withValues(alpha: 0.15)
                                    : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plan.badge!,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Perks list
          const Text('What you get',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: _perks.asMap().entries.map((entry) {
                final i = entry.key;
                final perk = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.premium.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(perk.$1,
                                color: AppColors.premium, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(perk.$2,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(perk.$3,
                                    style: const TextStyle(
                                        color: AppColors.textFaint,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 18),
                        ],
                      ),
                    ),
                    if (i < _perks.length - 1)
                      const Divider(
                          color: AppColors.hairline, height: 1, indent: 68),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Error banner
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // Subscribe CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.premium,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5),
                    )
                  : Text(
                      'Subscribe — ${_plans[_selectedPlan]!.price}${_plans[_selectedPlan]!.period}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),

          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Cancel anytime · Secure payment via Stripe',
              style: TextStyle(color: AppColors.textFaint, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String label;
  final String price;
  final String period;
  final String? badge;
  const _Plan(this.label, this.price, this.period, this.badge);
}