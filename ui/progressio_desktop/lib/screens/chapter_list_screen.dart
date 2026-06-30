import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/chapter.dart';
import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/chapter_provider.dart';
import 'package:progressio_desktop/providers/content_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';
import 'package:progressio_desktop/utils/utils.dart';

class ChapterListScreen extends StatefulWidget {
  const ChapterListScreen({super.key});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  late ChapterProvider _chapterProvider;
  late ContentProvider _contentProvider;

  final _contentSearchController = TextEditingController();

  List<Content> _contents = [];
  Content? _selectedContent;
  SearchResult<Chapter>? _result;
  bool _loading = false;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chapterProvider = context.read<ChapterProvider>();
    _contentProvider = context.read<ContentProvider>();
    _loadContents();
  }

  @override
  void dispose() {
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

  Future<void> _loadChapters({int page = 1}) async {
    if (_selectedContent == null) return;
    setState(() {
      _loading = true;
      _page = page;
    });
    try {
      final result = await _chapterProvider.get(
        filter: {
          'contentId': _selectedContent!.id,
          'page': page,
          'pageSize': _pageSize,
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

  Future<void> _openChapterDialog({Chapter? chapter}) async {
    if (_selectedContent == null) return;
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          chapter == null ? 'Add Chapter' : 'Edit Chapter',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 420,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'chapterNumber': chapter?.chapterNumber.toString() ?? '',
              'title': chapter?.title ?? '',
              'publishedAt': chapter?.publishedAt,
              'isAvailable': chapter?.isAvailable ?? true,
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'chapterNumber',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Chapter Number *'),
                  keyboardType: TextInputType.number,
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'title',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                FormBuilderDateTimePicker(
                  name: 'publishedAt',
                  inputType: InputType.date,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Published At',
                    suffixIcon: Icon(Icons.calendar_today,
                        color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                FormBuilderSwitch(
                  name: 'isAvailable',
                  title: const Text('Available',
                      style: TextStyle(color: AppColors.textSecondary)),
                  activeColor: AppColors.success,
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
          if (chapter != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteChapter(chapter);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.saveAndValidate() ?? false)) return;
              final values =
                  Map<String, dynamic>.from(formKey.currentState!.value);
              values['contentId'] = _selectedContent!.id;
              values['chapterNumber'] =
                  int.tryParse(values['chapterNumber'].toString()) ?? 1;
              if (values['publishedAt'] is DateTime) {
                values['publishedAt'] =
                    (values['publishedAt'] as DateTime).toIso8601String();
              }
              Navigator.pop(context);
              try {
                if (chapter == null) {
                  await _chapterProvider.insert(values);
                } else {
                  await _chapterProvider.update(chapter.id, values);
                }
                _loadChapters(page: _page);
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(chapter == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChapter(Chapter chapter) async {
  if (!await showDeleteConfirmation(
    context,
    itemName: chapter.title ?? 'Chapter ${chapter.chapterNumber}',
  )) {
    return;
  }
  if (!mounted) return;
  try {
    await _chapterProvider.delete(chapter.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Chapter deleted.'),
          backgroundColor: AppColors.error),
    );
    _loadChapters(page: _page);
  } catch (e) {
    _showError(e.toString());
  }
}

  int get _totalPages =>
      ((_result?.totalCount ?? 0) / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Chapters',
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
                        style: const TextStyle(color: AppColors.textPrimary),
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
                                _contentSearchController.text.toLowerCase()))
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
                                _loadChapters();
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right panel — chapters
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
          Text(
            _selectedContent != null
                ? 'Chapters — ${_selectedContent!.title}'
                : 'Select a content to view chapters',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedContent != null)
            ElevatedButton.icon(
              onPressed: () => _openChapterDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Chapter'),
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
        child: Text('No chapters found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Chapter #')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Published')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: items.map((c) => _buildRow(c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Chapter c) {
    return DataRow(
      cells: [
        DataCell(Text('Ch. ${c.chapterNumber}',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600))),
        DataCell(Text(c.title ?? '-',
            style: const TextStyle(color: AppColors.textPrimary))),
        DataCell(Text(formatDate(c.publishedAt),
            style: const TextStyle(color: AppColors.textMuted))),
        DataCell(_buildStatusChip(c.isAvailable)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
            tooltip: 'Edit',
            onPressed: () => _openChapterDialog(chapter: c),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.15)
            : AppColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(
          color: isAvailable ? AppColors.success : AppColors.error,
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
          Text('Total: ${_result?.totalCount ?? 0} chapters',
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed: _page > 1
                    ? () => _loadChapters(page: _page - 1)
                    : null,
              ),
              Text('Page $_page of $_totalPages',
                  style:
                      const TextStyle(color: AppColors.textSecondary)),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed: _page < _totalPages
                    ? () => _loadChapters(page: _page + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}