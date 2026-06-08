import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/subscription.dart';
import 'package:progressio_desktop/providers/subscription_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/utils/utils.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  State<SubscriptionListScreen> createState() => _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  late SubscriptionProvider _subscriptionProvider;

  Subscription? _subscription;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptionProvider = context.read<SubscriptionProvider>();
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sub = await _subscriptionProvider.getMySubscription();
      setState(() => _subscription = sub);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Subscriptions',
      child: Column(
        children: [
          _buildNotice(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Backend exposes only GET /api/subscriptions/me. '
              'A GET /api/admin/subscriptions endpoint is required for full admin listing. '
              'Currently showing the logged-in admin subscription.',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh,
                color: AppColors.textSecondary, size: 18),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_subscription == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_off,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text('No active subscription found for this account.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRENT SUBSCRIPTION',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildSubscriptionCard(_subscription!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Subscription sub) {
    final isActive = sub.status.toLowerCase() == 'active';
    final isExpired = sub.endDate.isBefore(DateTime.now());

    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.premium.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: AppColors.premium, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.planType,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subscription #${sub.id}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(sub.status, isActive, isExpired),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 12),
            _infoRow('Plan Type', sub.planType),
            _infoRow('Status', sub.status),
            _infoRow('Start Date', formatDate(sub.startDate)),
            _infoRow('End Date', formatDate(sub.endDate)),
            _infoRow('Auto Renew', sub.autoRenew ? 'Yes' : 'No'),
            _infoRow('Premium Access', sub.isPremium ? 'Yes' : 'No'),
            if (isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'This subscription expired on ${formatDate(sub.endDate)}.',
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isActive, bool isExpired) {
    Color color;
    if (isExpired) {
      color = AppColors.error;
    } else if (isActive) {
      color = AppColors.success;
    } else {
      color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isExpired ? 'Expired' : status,
        style: TextStyle(
            color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}