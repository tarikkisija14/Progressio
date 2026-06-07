import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/model/content_type.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/content_provider.dart';
import 'package:progressio_desktop/providers/content_type_provider.dart';
import 'package:progressio_desktop/screens/content_form_screen.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class ContentListScreen extends StatefulWidget {
  const ContentListScreen({super.key});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  late ContentProvider _contentProvider;
  late ContentTypeProvider _contentTypeProvider;

  final _searchController = TextEditingController();

  SearchResult<Content>? _result;
  List<ContentType> _contentTypes = [];
  int? _selectedContentTypeId;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contentProvider = context.read<ContentProvider>();
    _contentTypeProvider = context.read<ContentTypeProvider>();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final types = await _contentTypeProvider.get();
      _contentTypes = types.items ?? [];
    } catch (_) {}
    await _search();
  }

  Future<void> _search({int page = 1}) async {
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final filter = <String, dynamic>{
        'page': page,
        'pageSize': _pageSize,
        if (_searchController.text.trim().isNotEmpty)
          'title': _searchController.text.trim(),
        if (_selectedContentTypeId != null)
          'contentTypeId': _selectedContentTypeId,
      };
      final result = await _contentProvider.get(filter: filter);
      setState(() => _result = result);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
  }

  Future<void> _openForm(Content? content) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContentFormScreen(content: content)),
    );
    _search(page: _page);
  }

  int get _totalPages => ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Content',
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
                hintText: 'Search by title...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedContentTypeId,
                dropdownColor: AppColors.card,
                hint: const Text('All Types',
                    style: TextStyle(color: AppColors.textMuted)),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Types',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  ..._contentTypes.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _selectedContentTypeId = v);
                  _search();
                },
              ),
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
            onPressed: () => _openForm(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Content'),
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
        child: Text('No content found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Genres')),
            DataColumn(label: Text('Year')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Status')),
          ],
          rows: items.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Content c) {
    return DataRow(
      onSelectChanged: (_) => _openForm(c),
      cells: [
        DataCell(_buildThumbnail(c.coverImageUrl)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(c.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ),
        DataCell(_buildTypeChip(c.contentTypeName)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(c.genres.join(', '),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ),
        DataCell(Text(c.releaseYear?.toString() ?? '-',
            style: const TextStyle(color: AppColors.textMuted))),
        DataCell(Text(c.avgRating.toStringAsFixed(1),
            style: const TextStyle(color: AppColors.premium))),
        DataCell(_buildStatusChip(c.isActive)),
      ],
    );
  }

  Widget _buildThumbnail(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 36,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.image_not_supported,
            color: AppColors.textMuted, size: 16),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 36,
          height: 52,
          color: AppColors.divider,
        ),
        errorWidget: (_, __, ___) => Container(
          width: 36,
          height: 52,
          color: AppColors.divider,
          child: const Icon(Icons.broken_image,
              color: AppColors.textMuted, size: 16),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String? name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(name ?? '-',
          style: const TextStyle(color: AppColors.primary, fontSize: 12)),
    );
  }

  Widget _buildStatusChip(bool isActive) {
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
          fontSize: 12,
        ),
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
          Text(
            'Total: ${_result?.totalCount ?? 0} items',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
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