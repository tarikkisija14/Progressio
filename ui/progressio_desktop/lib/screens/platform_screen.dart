import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/platform.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/platform_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class PlatformScreen extends StatefulWidget {
  const PlatformScreen({super.key});

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  late PlatformProvider _platformProvider;

  final _searchController = TextEditingController();
  SearchResult<Platform>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _platformProvider = context.read<PlatformProvider>();
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
      final result = await _platformProvider.get(
        filter: {
          'page': page,
          'pageSize': _pageSize,
          if (_searchController.text.trim().isNotEmpty)
            'name': _searchController.text.trim(),
        },
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  Future<void> _openDialog({Platform? platform}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          platform == null ? 'Add Platform' : 'Edit Platform',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 360,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'name': platform?.name ?? '',
            },
            child: FormBuilderTextField(
              name: 'name',
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(2),
              ]),
            ),
          ),
        ),
        actions: [
          if (platform != null)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _delete(platform);
              },
              icon: const Icon(Icons.delete, color: AppColors.error, size: 18),
              label: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.saveAndValidate() ?? false) {
                final values = formKey.currentState!.value;
                Navigator.pop(dialogContext);
                await _save(platform, values);
              }
            },
            child: Text(platform == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(Platform? existing, Map<String, dynamic> values) async {
    try {
      final request = {'name': values['name']};
      if (existing == null) {
        await _platformProvider.insert(request);
        _showSuccess('Platform added successfully.');
      } else {
        await _platformProvider.update(existing.id, request);
        _showSuccess('Platform updated successfully.');
      }
      if (mounted) _search(page: _page);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _delete(Platform platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Platform',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${platform.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _platformProvider.delete(platform.id);
        _showSuccess('Platform deleted.');
        if (mounted) _search(page: _page);
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  int get _totalPages => ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Platforms',
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
                hintText: 'Search platforms...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _search(),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Platform'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildTable() {
    final items = _result?.items ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices_other, color: AppColors.textMuted, size: 48),
            SizedBox(height: 12),
            Text('No platforms found.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Actions')),
          ],
          rows: items.map((p) => _buildRow(p)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Platform p) {
    return DataRow(
      cells: [
        DataCell(
          Text(p.name,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                tooltip: 'Edit',
                onPressed: () => _openDialog(platform: p),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 18),
                tooltip: 'Delete',
                onPressed: () => _delete(p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${_result?.totalCount ?? 0} items',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed: _page > 1 ? () => _search(page: _page - 1) : null,
              ),
              Text('Page $_page of $_totalPages',
                  style: const TextStyle(color: AppColors.textSecondary)),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed:
                    _page < _totalPages ? () => _search(page: _page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}