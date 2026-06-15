import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/content_type.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/content_type_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class ContentTypeScreen extends StatefulWidget {
  const ContentTypeScreen({super.key});

  @override
  State<ContentTypeScreen> createState() => _ContentTypeScreenState();
}

class _ContentTypeScreenState extends State<ContentTypeScreen> {
  late ContentTypeProvider _contentTypeProvider;

  final _searchController = TextEditingController();
  SearchResult<ContentType>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentTypeProvider = context.read<ContentTypeProvider>();
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
      final result = await _contentTypeProvider.get(
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

  Future<void> _openDialog({ContentType? contentType}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          contentType == null ? 'Add Content Type' : 'Edit Content Type',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 360,
          child: FormBuilder(
            key: formKey,
            initialValue: {'name': contentType?.name ?? ''},
            child: FormBuilderTextField(
              name: 'name',
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: FormBuilderValidators.required(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          if (contentType != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _delete(contentType);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.saveAndValidate() ?? false)) return;
              final values =
                  Map<String, dynamic>.from(formKey.currentState!.value);
              Navigator.pop(dialogContext);
              try {
                if (contentType == null) {
                  await _contentTypeProvider.insert(values);
                } else {
                  await _contentTypeProvider.update(contentType.id, values);
                }
                showSuccessSnackBar(
                  context,
                  contentType == null
                      ? 'Content type created.'
                      : 'Content type updated.',
                );
                if (mounted) _search(page: _page);
              } catch (e) {
                showErrorSnackBar(context, e);
              }
            },
            child: Text(contentType == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(ContentType contentType) async {
    if (!await showDeleteConfirmation(context, itemName: contentType.name)) return;
    try {
      await _contentTypeProvider.delete(contentType.id);
      showSuccessSnackBar(context, 'Content type deleted.');
      if (mounted) _search(page: _page);
    } catch (e) {
      showErrorSnackBar(context, e);
    }
  }

  int get _totalPages => ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Content Types',
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
                hintText: 'Search content types...',
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
            label: const Text('Add Content Type'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
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
        child: Text('No content types found.',
            style: TextStyle(color: AppColors.textMuted)),
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
          rows: items.map((t) => _buildRow(t)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(ContentType t) {
    return DataRow(
      cells: [
        DataCell(Text(t.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500))),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
            tooltip: 'Edit',
            onPressed: () => _openDialog(contentType: t),
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
          Text('Total: ${_result?.totalCount ?? 0} content types',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
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