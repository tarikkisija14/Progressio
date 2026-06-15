import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/language.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/language_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late LanguageProvider _provider;
  final _searchController = TextEditingController();
  SearchResult<Language>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<LanguageProvider>();
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
      final result = await _provider.get(
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _openDialog({Language? language}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(language == null ? 'Add Language' : 'Edit Language'),
        content: SizedBox(
          width: 380,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'name': language?.name ?? '',
              'code': language?.code ?? '',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'name',
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Enter a language name.',
                    ),
                    FormBuilderValidators.maxLength(
                      100,
                      errorText: 'Name can contain at most 100 characters.',
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                FormBuilderTextField(
                  name: 'code',
                  decoration: const InputDecoration(
                    labelText: 'Language code *',
                    helperText: 'Use a short code such as en, bs or ja.',
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Enter a language code.',
                    ),
                    FormBuilderValidators.maxLength(
                      10,
                      errorText: 'Code can contain at most 10 characters.',
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          if (language != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _delete(language);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.saveAndValidate() ?? false)) return;

              final values = formKey.currentState!.value;
              final request = {
                'name': (values['name'] as String).trim(),
                'code': (values['code'] as String).trim().toLowerCase(),
              };

              Navigator.pop(dialogContext);
              try {
                if (language == null) {
                  await _provider.insert(request);
                } else {
                  await _provider.update(language.id, request);
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      language == null
                          ? 'Language created successfully.'
                          : 'Language updated successfully.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                await _search(page: _page);
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(language == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Language language) async {
    if (!await showDeleteConfirmation(context, itemName: language.name)) return;

    try {
      await _provider.delete(language.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Language deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      await _search(page: _page);
    } catch (e) {
      _showError(e.toString());
    }
  }

  int get _totalPages => ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final items = _result?.items ?? const <Language>[];

    return MasterScreen(
      title: 'Languages',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search languages...',
                      prefixIcon: Icon(Icons.search),
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
                  label: const Text('Add Language'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('No languages found.'))
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Code')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: items
                                .map(
                                  (language) => DataRow(
                                    cells: [
                                      DataCell(Text(language.name)),
                                      DataCell(Text(language.code.toUpperCase())),
                                      DataCell(
                                        IconButton(
                                          tooltip: 'Edit language',
                                          icon: const Icon(
                                            Icons.edit,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () =>
                                              _openDialog(language: language),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
          ),
          if ((_result?.totalCount ?? 0) > _pageSize)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: ${_result?.totalCount ?? 0} languages'),
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            _page > 1 ? () => _search(page: _page - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Page $_page of $_totalPages'),
                      IconButton(
                        onPressed: _page < _totalPages
                            ? () => _search(page: _page + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}