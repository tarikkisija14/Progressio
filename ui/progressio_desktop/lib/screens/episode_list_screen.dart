import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/episode.dart';
import 'package:progressio_desktop/model/season.dart';
import 'package:progressio_desktop/providers/episode_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';
import 'package:progressio_desktop/utils/utils.dart';

class EpisodeListScreen extends StatefulWidget {
  final Season season;
  const EpisodeListScreen({super.key, required this.season});

  @override
  State<EpisodeListScreen> createState() => _EpisodeListScreenState();
}

class _EpisodeListScreenState extends State<EpisodeListScreen> {
  late EpisodeProvider _episodeProvider;

  List<Episode> _episodes = [];
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _episodeProvider = context.read<EpisodeProvider>();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() => _loading = true);
    try {
      final items = await _episodeProvider.getAll(
        filter: {'seasonId': widget.season.id},
      );
      if (mounted) setState(() => _episodes = items);
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

  Future<void> _openEpisodeDialog({Episode? episode}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          episode == null ? 'Add Episode' : 'Edit Episode',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 440,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'episodeNumber': episode?.episodeNumber.toString() ?? '',
              'title': episode?.title ?? '',
              'durationMinutes': episode?.durationMinutes?.toString() ?? '',
              'airDate': episode?.airDate,
              'description': episode?.description ?? '',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'episodeNumber',
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Episode Number *'),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.required(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FormBuilderTextField(
                        name: 'durationMinutes',
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'Duration (min)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'title',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 12),
                FormBuilderDateTimePicker(
                  name: 'airDate',
                  inputType: InputType.date,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Air Date',
                    suffixIcon:
                        Icon(Icons.calendar_today, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'description',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Description'),
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
          if (episode != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteEpisode(episode);
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
              values['seasonId'] = widget.season.id;
              values['episodeNumber'] =
                  int.tryParse(values['episodeNumber'].toString()) ?? 1;
              if (values['durationMinutes'] != null &&
                  values['durationMinutes'].toString().isNotEmpty) {
                values['durationMinutes'] =
                    int.tryParse(values['durationMinutes'].toString());
              } else {
                values['durationMinutes'] = null;
              }
              if (values['airDate'] is DateTime) {
                values['airDate'] =
                    (values['airDate'] as DateTime).toIso8601String();
              }
              Navigator.pop(context);
              try {
                if (episode == null) {
                  await _episodeProvider.insert(values);
                } else {
                  await _episodeProvider.update(episode.id, values);
                }
                _loadEpisodes();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(episode == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEpisode(Episode episode) async {
    if (!await showDeleteConfirmation(context, itemName: episode.title)) return;
    if (!mounted) return;
    try {
      await _episodeProvider.delete(episode.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Episode deleted.'),
            backgroundColor: AppColors.error),
      );
      _loadEpisodes();
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title:
          'Episodes — Season ${widget.season.seasonNumber}${widget.season.title != null ? ': ${widget.season.title}' : ''}',
      child: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _buildTable(),
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
            '${_episodes.length} episodes',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _openEpisodeDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Episode'),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_episodes.isEmpty) {
      return const Center(
        child: Text('No episodes found.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Ep #')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Air Date')),
            DataColumn(label: Text('')),
          ],
          rows: _episodes.map((e) => _buildRow(e)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(Episode e) {
    final missingAirDate = e.airDate == null;
    return DataRow(
      cells: [
        DataCell(Text('Ep ${e.episodeNumber}',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w600))),
        DataCell(
          Row(
            children: [
              Text(e.title,
                  style: const TextStyle(color: AppColors.textPrimary)),
              if (missingAirDate) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('No Air Date',
                      style: TextStyle(
                          color: AppColors.warning, fontSize: 11)),
                ),
              ],
            ],
          ),
        ),
        DataCell(Text(
          e.durationMinutes != null ? '${e.durationMinutes} min' : '-',
          style: const TextStyle(color: AppColors.textMuted),
        )),
        DataCell(Text(
          formatDate(e.airDate),
          style: TextStyle(
            color: missingAirDate ? AppColors.warning : AppColors.textSecondary,
          ),
        )),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
            tooltip: 'Edit',
            onPressed: () => _openEpisodeDialog(episode: e),
          ),
        ),
      ],
    );
  }
}