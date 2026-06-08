import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/model/season.dart';
import 'package:progressio_desktop/providers/content_provider.dart';
import 'package:progressio_desktop/providers/season_provider.dart';
import 'package:progressio_desktop/screens/episode_list_screen.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class SeasonListScreen extends StatefulWidget {
  const SeasonListScreen({super.key});

  @override
  State<SeasonListScreen> createState() => _SeasonListScreenState();
}

class _SeasonListScreenState extends State<SeasonListScreen> {
  late SeasonProvider _seasonProvider;
  late ContentProvider _contentProvider;

  final _searchController = TextEditingController();

  List<Content> _contents = [];
  Content? _selectedContent;
  SearchResult<Season>? _result;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _seasonProvider = context.read<SeasonProvider>();
    _contentProvider = context.read<ContentProvider>();
    _loadContents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContents() async {
    try {
      // Load only Series and Anime content types
      final result = await _contentProvider.get(
        filter: {'pageSize': 200},
      );
      setState(() => _contents = result.items ?? []);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadSeasons() async {
    if (_selectedContent == null) return;
    setState(() => _loading = true);
    try {
      final result = await _seasonProvider.get(
        filter: {
          'contentId': _selectedContent!.id,
          'pageSize': 100,
          if (_searchController.text.trim().isNotEmpty)
            'title': _searchController.text.trim(),
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

  Future<void> _openSeasonDialog({Season? season}) async {
    if (_selectedContent == null) return;
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          season == null ? 'Add Season' : 'Edit Season',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 400,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'seasonNumber': season?.seasonNumber.toString() ?? '',
              'title': season?.title ?? '',
              'releaseYear': season?.releaseYear?.toString() ?? '',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'seasonNumber',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Season Number *'),
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
                FormBuilderTextField(
                  name: 'releaseYear',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Release Year'),
                  keyboardType: TextInputType.number,
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
          if (season != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSeason(season);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.saveAndValidate() ?? false)) return;
              final values =
                  Map<String, dynamic>.from(formKey.currentState!.value);
              values['contentId'] = _selectedContent!.id;
              values['seasonNumber'] =
                  int.tryParse(values['seasonNumber'].toString()) ?? 1;
              if (values['releaseYear'] != null &&
                  values['releaseYear'].toString().isNotEmpty) {
                values['releaseYear'] =
                    int.tryParse(values['releaseYear'].toString());
              } else {
                values['releaseYear'] = null;
              }
              Navigator.pop(context);
              try {
                if (season == null) {
                  await _seasonProvider.insert(values);
                } else {
                  await _seasonProvider.update(season.id, values);
                }
                _loadSeasons();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(season == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSeason(Season season) async {
    try {
      await _seasonProvider.delete(season.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Season deleted.'),
            backgroundColor: AppColors.error),
      );
      _loadSeasons();
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Seasons',
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
                        controller: _searchController,
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
                        .where((c) => _searchController.text.isEmpty ||
                            c.title.toLowerCase().contains(
                                _searchController.text.toLowerCase()))
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
                                _loadSeasons();
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right panel — seasons
          Expanded(
            child: Column(
              children: [
                _buildSeasonToolbar(),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(child: _buildSeasonContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            _selectedContent != null
                ? 'Seasons — ${_selectedContent!.title}'
                : 'Select a content to view seasons',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedContent != null)
            ElevatedButton.icon(
              onPressed: () => _openSeasonDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Season'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
            ),
        ],
      ),
    );
  }

  Widget _buildSeasonContent() {
    if (_selectedContent == null) {
      return const Center(
        child: Text(
          'Select a content from the left panel.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final items = _result?.items ?? [];
    if (items.isEmpty) {
      return const Center(
        child:
            Text('No seasons found.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Season #')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Year')),
            DataColumn(label: Text('Episodes')),
            DataColumn(label: Text('Actions')),
          ],
          rows: items.map((s) => _buildSeasonRow(s)).toList(),
        ),
      ),
    );
  }

  DataRow _buildSeasonRow(Season s) {
    return DataRow(
      cells: [
        DataCell(Text('Season ${s.seasonNumber}',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600))),
        DataCell(Text(s.title ?? '-',
            style: const TextStyle(color: AppColors.textPrimary))),
        DataCell(Text(s.releaseYear?.toString() ?? '-',
            style: const TextStyle(color: AppColors.textMuted))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${s.episodeCount} eps',
                style: const TextStyle(
                    color: AppColors.secondary, fontSize: 12)),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                tooltip: 'Edit',
                onPressed: () => _openSeasonDialog(season: s),
              ),
              IconButton(
                icon: const Icon(Icons.video_library,
                    color: AppColors.success, size: 18),
                tooltip: 'View Episodes',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EpisodeListScreen(season: s),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}