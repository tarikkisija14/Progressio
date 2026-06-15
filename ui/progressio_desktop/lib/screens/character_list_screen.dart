import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/character.dart';
import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/character_provider.dart';
import 'package:progressio_desktop/providers/content_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  late CharacterProvider _characterProvider;
  late ContentProvider _contentProvider;

  final _searchController = TextEditingController();
  final _contentSearchController = TextEditingController();

  List<Content> _contents = [];
  Content? _selectedContent;
  SearchResult<Character>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _characterProvider = context.read<CharacterProvider>();
    _contentProvider = context.read<ContentProvider>();
    _loadContents();
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    _contentSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadContents() async {
    try {
      final items = await _contentProvider.getAll();
      if (mounted) setState(() => _contents = items);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadCharacters({int page = 1}) async {
    if (_selectedContent == null) return;
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final result = await _characterProvider.get(
        filter: {
          'contentId': _selectedContent!.id,
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

  Future<void> _openCharacterDialog({Character? character}) async {
    if (_selectedContent == null) return;
    final formKey = GlobalKey<FormBuilderState>();
    String? previewUrl = character?.imageUrl;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            character == null ? 'Add Character' : 'Edit Character',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SizedBox(
            width: 480,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormBuilder(
                    key: formKey,
                    initialValue: {
                      'name': character?.name ?? '',
                      'description': character?.description ?? '',
                      'imageUrl': character?.imageUrl ?? '',
                      'isMainCharacter': character?.isMainCharacter ?? false,
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FormBuilderTextField(
                          name: 'name',
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              const InputDecoration(labelText: 'Name *'),
                          validator: FormBuilderValidators.required(),
                        ),
                        const SizedBox(height: 12),
                        FormBuilderTextField(
                          name: 'description',
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        FormBuilderTextField(
                          name: 'imageUrl',
                          style:
                              const TextStyle(color: AppColors.textPrimary),
                          decoration:
                              const InputDecoration(labelText: 'Image URL'),
                          onChanged: (v) =>
                              setDialogState(() => previewUrl = v),
                        ),
                        const SizedBox(height: 12),
                        FormBuilderSwitch(
                          name: 'isMainCharacter',
                          title: const Text('Main Character',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                          activeColor: AppColors.premium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildImagePreview(previewUrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            if (character != null)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteCharacter(character);
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
                values['contentId'] = _selectedContent!.id;
                Navigator.pop(context);
                try {
                  if (character == null) {
                    await _characterProvider.insert(values);
                  } else {
                    await _characterProvider.update(character.id, values);
                  }
                  _loadCharacters(page: _page);
                } catch (e) {
                  _showError(e.toString());
                }
              },
              child: Text(character == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCharacter(Character character) async {
    if (!await showDeleteConfirmation(context, itemName: character.name)) return;
    try {
      await _characterProvider.delete(character.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Character deleted.'),
            backgroundColor: AppColors.error),
      );
      _loadCharacters(page: _page);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Widget _buildImagePreview(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.person, color: AppColors.textMuted, size: 32),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 80,
        height: 100,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
            width: 80, height: 100, color: AppColors.divider),
        errorWidget: (_, __, ___) => Container(
          width: 80,
          height: 100,
          color: AppColors.divider,
          child: const Icon(Icons.broken_image,
              color: AppColors.textMuted, size: 24),
        ),
      ),
    );
  }

  int get _totalPages =>
      ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Characters',
      child: Row(
        children: [
          // Left panel — content picker
          Container(
            width: 280,
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT CONTENT',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contentSearchController,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search content...',
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textMuted, size: 18),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: ListView(
                    children: _contents
                        .where((c) =>
                            _contentSearchController.text.isEmpty ||
                            c.title.toLowerCase().contains(
                                _contentSearchController.text
                                    .toLowerCase()))
                        .map((c) => ListTile(
                              dense: true,
                              selected: _selectedContent?.id == c.id,
                              selectedTileColor:
                                  AppColors.primary.withOpacity(0.15),
                              title: Text(
                                c.title,
                                style: TextStyle(
                                  color: _selectedContent?.id == c.id
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                c.contentTypeName ?? '',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11),
                              ),
                              onTap: () {
                                setState(() => _selectedContent = c);
                                _loadCharacters();
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right panel — characters
          Expanded(
            child: Column(
              children: [
                _buildToolbar(),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(child: _buildContent()),
                if ((_result?.totalCount ?? 0) > _pageSize)
                  _buildPagination(),
              ],
            ),
          ),
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
              onSubmitted: (_) => _loadCharacters(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _loadCharacters(),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search'),
          ),
          const SizedBox(width: 8),
          if (_selectedContent != null)
            ElevatedButton.icon(
              onPressed: () => _openCharacterDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Character'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedContent == null) {
      return const Center(
        child: Text('Select a content from the left panel.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final items = _result?.items ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('No characters found.',
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
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Character c) {
    return DataRow(
      cells: [
        DataCell(_buildThumbnail(c.imageUrl)),
        DataCell(Text(c.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500))),
        DataCell(_buildRoleChip(c.isMainCharacter)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
            tooltip: 'Edit',
            onPressed: () => _openCharacterDialog(character: c),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.divider,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person,
            color: AppColors.textMuted, size: 20),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(width: 36, height: 36, color: AppColors.divider),
        errorWidget: (_, __, ___) => Container(
          width: 36,
          height: 36,
          color: AppColors.divider,
          child: const Icon(Icons.person,
              color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  Widget _buildRoleChip(bool isMain) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMain
            ? AppColors.premium.withOpacity(0.15)
            : AppColors.divider.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isMain ? 'Main' : 'Supporting',
        style: TextStyle(
          color: isMain ? AppColors.premium : AppColors.textMuted,
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
          Text('Total: ${_result?.totalCount ?? 0} characters',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed: _page > 1
                    ? () => _loadCharacters(page: _page - 1)
                    : null,
              ),
              Text('Page $_page of $_totalPages',
                  style: const TextStyle(color: AppColors.textSecondary)),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed: _page < _totalPages
                    ? () => _loadCharacters(page: _page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}