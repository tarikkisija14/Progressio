import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/achievement.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/achievement_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class AchievementListScreen extends StatefulWidget {
  const AchievementListScreen({super.key});

  @override
  State<AchievementListScreen> createState() => _AchievementListScreenState();
}

class _AchievementListScreenState extends State<AchievementListScreen> {
  late AchievementProvider _achievementProvider;

  final _searchController = TextEditingController();
  SearchResult<Achievement>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _achievementProvider = context.read<AchievementProvider>();
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
      final result = await _achievementProvider.get(
        filter: {
          'page': page,
          'pageSize': _pageSize,
          if (_searchController.text.trim().isNotEmpty)
            'name': _searchController.text.trim(),
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

  Future<void> _openDialog({Achievement? achievement}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          achievement == null ? 'Add Achievement' : 'Edit Achievement',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 480,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'code': achievement?.code ?? '',
              'name': achievement?.name ?? '',
              'description': achievement?.description ?? '',
              'iconUrl': achievement?.iconUrl ?? '',
              'conditionJson': achievement?.conditionJson ?? '',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'code',
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'Code *'),
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'name',
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'Name *'),
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'description',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'iconUrl',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Icon URL'),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'conditionJson',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Condition JSON',
                    hintText: '{"type":"completed","count":10}',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          if (achievement != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _delete(achievement);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.saveAndValidate() ?? false))
                return;
              final values = Map<String, dynamic>.from(
                  formKey.currentState!.value);
              Navigator.pop(context);
              try {
                if (achievement == null) {
                  await _achievementProvider.insert(values);
                } else {
                  await _achievementProvider.update(achievement.id, values);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(achievement == null
                      ? 'Achievement created.'
                      : 'Achievement updated.'),
                  backgroundColor: AppColors.success,
                ));
                _search(page: _page);
              } catch (e) {
                _showError(e.toString());
              }
            },
            child:
                Text(achievement == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Achievement achievement) async {
    try {
      await _achievementProvider.delete(achievement.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Achievement deleted.'),
            backgroundColor: AppColors.error),
      );
      _search(page: _page);
    } catch (e) {
      _showError(e.toString());
    }
  }

  int get _totalPages =>
      ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Achievements',
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
                hintText: 'Search by name...',
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textMuted),
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
            label: const Text('Add Achievement'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
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
        child: Text('No achievements found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('')),
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Condition')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((a) => _buildRow(a)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Achievement a) {
    return DataRow(
      cells: [
        DataCell(_buildIcon(a.iconUrl)),
        DataCell(
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(a.code,
                style: const TextStyle(
                    color: AppColors.secondary, fontSize: 12)),
          ),
        ),
        DataCell(Text(a.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500))),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(a.description ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
        ),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(a.conditionJson ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit,
                color: AppColors.primary, size: 18),
            tooltip: 'Edit',
            onPressed: () => _openDialog(achievement: a),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(String? url) {
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          placeholder: (_, __) => _defaultIcon(),
          errorWidget: (_, __, ___) => _defaultIcon(),
        ),
      );
    }
    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.premium.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.emoji_events,
          color: AppColors.premium, size: 18),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${_result?.totalCount ?? 0} achievements',
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