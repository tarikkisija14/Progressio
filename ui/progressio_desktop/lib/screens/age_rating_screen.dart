import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';

import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/age_rating.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/age_rating_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class AgeRatingScreen extends StatefulWidget {
  const AgeRatingScreen({super.key});

  @override
  State<AgeRatingScreen> createState() => _AgeRatingScreenState();
}

class _AgeRatingScreenState extends State<AgeRatingScreen> {
  late AgeRatingProvider _provider;
  final _searchController = TextEditingController();
  SearchResult<AgeRating>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider = context.read<AgeRatingProvider>();
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

  Future<void> _openDialog({AgeRating? rating}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(rating == null ? 'Add Age Rating' : 'Edit Age Rating'),
        content: SizedBox(
          width: 380,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'name': rating?.name ?? '',
              'minAge': rating?.minAge.toString() ?? '0',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'name',
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Enter an age rating name.',
                    ),
                    FormBuilderValidators.maxLength(
                      50,
                      errorText: 'Name can contain at most 50 characters.',
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                FormBuilderTextField(
                  name: 'minAge',
                  decoration: const InputDecoration(
                    labelText: 'Minimum age *',
                    helperText: 'Enter a whole number from 0 to 21.',
                  ),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Enter the minimum age.',
                    ),
                    FormBuilderValidators.integer(
                      errorText: 'Minimum age must be a whole number.',
                    ),
                    FormBuilderValidators.min(
                      0,
                      errorText: 'Minimum age cannot be below 0.',
                    ),
                    FormBuilderValidators.max(
                      21,
                      errorText: 'Minimum age cannot exceed 21.',
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
          if (rating != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _delete(rating);
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
                'minAge': int.parse(values['minAge'] as String),
              };

              Navigator.pop(dialogContext);
              try {
                if (rating == null) {
                  await _provider.insert(request);
                } else {
                  await _provider.update(rating.id, request);
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      rating == null
                          ? 'Age rating created successfully.'
                          : 'Age rating updated successfully.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                await _search(page: _page);
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(rating == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(AgeRating rating) async {
    if (!await showDeleteConfirmation(context, itemName: rating.name)) return;

    try {
      await _provider.delete(rating.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Age rating deleted successfully.'),
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
    final items = _result?.items ?? const <AgeRating>[];

    return MasterScreen(
      title: 'Age Ratings',
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
                      hintText: 'Search age ratings...',
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
                  label: const Text('Add Age Rating'),
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
                    ? const Center(child: Text('No age ratings found.'))
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Minimum age')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: items
                                .map(
                                  (rating) => DataRow(
                                    cells: [
                                      DataCell(Text(rating.name)),
                                      DataCell(Text('${rating.minAge}+')),
                                      DataCell(
                                        IconButton(
                                          tooltip: 'Edit age rating',
                                          icon: const Icon(
                                            Icons.edit,
                                            color: AppColors.primary,
                                          ),
                                          onPressed: () =>
                                              _openDialog(rating: rating),
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
                  Text('Total: ${_result?.totalCount ?? 0} age ratings'),
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