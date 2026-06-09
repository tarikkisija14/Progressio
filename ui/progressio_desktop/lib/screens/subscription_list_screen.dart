import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/model/subscription.dart';
import 'package:progressio_desktop/providers/subscription_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/utils/utils.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  State<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  late SubscriptionProvider _subscriptionProvider;

  final _searchController = TextEditingController();
  SearchResult<Subscription>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;
  String? _filterPlanType;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptionProvider = context.read<SubscriptionProvider>();
      _search();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search({int page = 1}) async {
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final result = await _subscriptionProvider.get(
        filter: {
          'page': page,
          'pageSize': _pageSize,
          if (_filterPlanType != null) 'planType': _filterPlanType,
          if (_filterStatus != null) 'status': _filterStatus,
        },
      );
      setState(() => _result = result);
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

  int get _totalPages =>
      ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Subscriptions',
      child: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(child: _loading ? _buildLoading() : _buildTable()),
          if ((_result?.totalCount ?? 0) > _pageSize) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _filterDropdown<String?>(
            value: _filterPlanType,
            hint: 'Plan Type',
            items: const [
              DropdownMenuItem(value: null, child: Text('All Plans')),
              DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
              DropdownMenuItem(value: 'Annual', child: Text('Annual')),
            ],
            onChanged: (v) {
              setState(() => _filterPlanType = v);
              _search();
            },
          ),
          const SizedBox(width: 8),
          _filterDropdown<String?>(
            value: _filterStatus,
            hint: 'Status',
            items: const [
              DropdownMenuItem(value: null, child: Text('All Status')),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Expired', child: Text('Expired')),
              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
            onChanged: (v) {
              setState(() => _filterStatus = v);
              _search();
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _search(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.card,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textMuted)),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item.value,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                          color: AppColors.textSecondary),
                      child: item.child!,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
  }

  Widget _buildTable() {
    final items = _result?.items ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('No subscriptions found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Plan')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Start')),
            DataColumn(label: Text('End')),
            DataColumn(label: Text('Auto Renew')),
            DataColumn(label: Text('Stripe ID')),
          ],
          rows: items.map((s) => _buildRow(s)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Subscription s) {
    final isExpired = s.endDate.isBefore(DateTime.now());
    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.userFullName,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
            Text('@${s.username}',
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 11)),
          ],
        )),
        DataCell(Text(s.userEmail,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12))),
        DataCell(_planChip(s.planType)),
        DataCell(_statusChip(s.status, isExpired)),
        DataCell(Text(formatDate(s.startDate),
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12))),
        DataCell(Text(
          formatDate(s.endDate),
          style: TextStyle(
            color: isExpired ? AppColors.error : AppColors.textMuted,
            fontSize: 12,
          ),
        )),
        DataCell(Icon(
          s.autoRenew ? Icons.check_circle : Icons.cancel,
          color: s.autoRenew ? AppColors.success : AppColors.textMuted,
          size: 18,
        )),
        DataCell(
          s.stripePaymentIntentId != null
              ? Tooltip(
                  message: s.stripePaymentIntentId!,
                  child: Text(
                    s.stripePaymentIntentId!.length > 16
                        ? '${s.stripePaymentIntentId!.substring(0, 16)}...'
                        : s.stripePaymentIntentId!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                )
              : const Text('-',
                  style: TextStyle(color: AppColors.textMuted)),
        ),
      ],
    );
  }

  Widget _planChip(String planType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.premium.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(planType,
          style:
              const TextStyle(color: AppColors.premium, fontSize: 12)),
    );
  }

  Widget _statusChip(String status, bool isExpired) {
    final color = isExpired
        ? AppColors.error
        : status.toLowerCase() == 'active'
            ? AppColors.success
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isExpired ? 'Expired' : status,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${_result?.totalCount ?? 0} subscriptions',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed:
                    _page > 1 ? () => _search(page: _page - 1) : null,
              ),
              Text('Page $_page of $_totalPages',
                  style: const TextStyle(
                      color: AppColors.textSecondary)),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed: _page < _totalPages
                    ? () => _search(page: _page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}