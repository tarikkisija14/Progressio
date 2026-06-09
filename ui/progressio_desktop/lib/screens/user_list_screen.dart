import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/model/user.dart';
import 'package:progressio_desktop/providers/user_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/utils/utils.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late UserProvider _userProvider;

  final _searchController = TextEditingController();
  SearchResult<AppUser>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;
  bool? _filterIsActive;
  bool? _filterIsPremium;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userProvider = context.read<UserProvider>();
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
      final result = await _userProvider.get(
        filter: {
          'page': page,
          'pageSize': _pageSize,
          if (_searchController.text.trim().isNotEmpty)
            'searchQuery': _searchController.text.trim(),
          if (_filterIsActive != null) 'isActive': _filterIsActive,
          if (_filterIsPremium != null) 'isPremium': _filterIsPremium,
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

  void _showUserDetail(AppUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Row(
          children: [
            _buildAvatar(user, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user.fullName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text('@${user.username}',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: AppColors.divider),
              _infoRow('ID', '#${user.id}'),
              _infoRow('Email', user.email),
              _infoRow('Member Since', formatDate(user.createdAt)),
              _infoRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _infoRow('Premium', user.isPremium ? 'Yes' : 'No'),
              _infoRow('Plan', user.activePlanType ?? '-'),
              _infoRow('Completed', '${user.totalCompleted}'),
              _infoRow('In Progress', '${user.totalInProgress}'),
              _infoRow('Profile',
                  user.isProfilePublic ? 'Public' : 'Private'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  int get _totalPages =>
      ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Users',
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
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search by name, username, email...',
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMuted),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 12),
          _filterDropdown<bool?>(
            value: _filterIsActive,
            hint: 'Status',
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Active')),
              DropdownMenuItem(value: false, child: Text('Inactive')),
            ],
            onChanged: (v) {
              setState(() => _filterIsActive = v);
              _search();
            },
          ),
          const SizedBox(width: 8),
          _filterDropdown<bool?>(
            value: _filterIsPremium,
            hint: 'Plan',
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: true, child: Text('Premium')),
              DropdownMenuItem(value: false, child: Text('Free')),
            ],
            onChanged: (v) {
              setState(() => _filterIsPremium = v);
              _search();
            },
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _search(),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search'),
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
        child: Text('No users found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Username')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Plan')),
            DataColumn(label: Text('Completed')),
            DataColumn(label: Text('Joined')),
          ],
          rows: items.map((u) => _buildRow(u)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(AppUser u) {
    return DataRow(
      onSelectChanged: (_) => _showUserDetail(u),
      cells: [
        DataCell(_buildAvatar(u, size: 32)),
        DataCell(Text(u.fullName,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500))),
        DataCell(Text('@${u.username}',
            style: const TextStyle(color: AppColors.primary))),
        DataCell(Text(u.email,
            style: const TextStyle(color: AppColors.textMuted))),
        DataCell(_statusChip(u.isActive)),
        DataCell(_planChip(u.isPremium, u.activePlanType)),
        DataCell(Text('${u.totalCompleted}',
            style: const TextStyle(color: AppColors.textSecondary))),
        DataCell(Text(formatDate(u.createdAt),
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12))),
      ],
    );
  }

  Widget _buildAvatar(AppUser user, {double size = 36}) {
    if (user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _defaultAvatar(user, size),
          errorWidget: (_, __, ___) => _defaultAvatar(user, size),
        ),
      );
    }
    return _defaultAvatar(user, size);
  }

  Widget _defaultAvatar(AppUser user, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.firstName.isNotEmpty
              ? user.firstName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.15)
            : AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
            color: isActive ? AppColors.success : AppColors.error,
            fontSize: 12),
      ),
    );
  }

  Widget _planChip(bool isPremium, String? planType) {
    if (!isPremium) {
      return const Text('Free',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.premium.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        planType ?? 'Premium',
        style: const TextStyle(color: AppColors.premium, fontSize: 12),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
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
          Text('Total: ${_result?.totalCount ?? 0} users',
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