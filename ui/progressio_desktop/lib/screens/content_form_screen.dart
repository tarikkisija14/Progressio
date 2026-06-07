import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/age_rating.dart';
import 'package:progressio_desktop/model/content.dart';
import 'package:progressio_desktop/model/content_type.dart';
import 'package:progressio_desktop/model/genre.dart';
import 'package:progressio_desktop/model/language.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/age_rating_provider.dart';
import 'package:progressio_desktop/providers/content_provider.dart';
import 'package:progressio_desktop/providers/content_type_provider.dart';
import 'package:progressio_desktop/providers/genre_provider.dart';
import 'package:progressio_desktop/providers/language_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';

class ContentFormScreen extends StatefulWidget {
  final Content? content;
  const ContentFormScreen({super.key, this.content});

  @override
  State<ContentFormScreen> createState() => _ContentFormScreenState();
}

class _ContentFormScreenState extends State<ContentFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  late ContentProvider _contentProvider;
  late ContentTypeProvider _contentTypeProvider;
  late GenreProvider _genreProvider;
  late AgeRatingProvider _ageRatingProvider;
  late LanguageProvider _languageProvider;

  List<ContentType> _contentTypes = [];
  List<Genre> _genres = [];
  List<AgeRating> _ageRatings = [];
  List<Language> _languages = [];

  bool _loading = true;
  bool _saving = false;
  String? _previewUrl;

  bool get _isEdit => widget.content != null;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.content?.coverImageUrl;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    _contentProvider = context.read<ContentProvider>();
    _contentTypeProvider = context.read<ContentTypeProvider>();
    _genreProvider = context.read<GenreProvider>();
    _ageRatingProvider = context.read<AgeRatingProvider>();
    _languageProvider = context.read<LanguageProvider>();

    try {
      final results = await Future.wait([
        _contentTypeProvider.get(filter: {'pageSize': 100}),
        _genreProvider.get(filter: {'pageSize': 100}),
        _ageRatingProvider.get(filter: {'pageSize': 100}),
        _languageProvider.get(filter: {'pageSize': 100}),
      ]);
      setState(() {
        _contentTypes = (results[0] as SearchResult<ContentType>).items ?? [];
        _genres = (results[1] as SearchResult<Genre>).items ?? [];
        _ageRatings = (results[2] as SearchResult<AgeRating>).items ?? [];
        _languages = (results[3] as SearchResult<Language>).items ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Map<String, dynamic> get _initialValue => {
        'title': widget.content?.title ?? '',
        'description': widget.content?.description ?? '',
        'coverImageUrl': widget.content?.coverImageUrl ?? '',
        'contentTypeId': widget.content?.contentTypeId,
        'ageRatingId': widget.content?.ageRatingId,
        'languageId': widget.content?.languageId,
        'releaseYear': widget.content?.releaseYear?.toString() ?? '',
        'isActive': widget.content?.isActive ?? true,
      };

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final values = Map<String, dynamic>.from(_formKey.currentState!.value);
      if (values['releaseYear'] != null &&
          values['releaseYear'].toString().isNotEmpty) {
        values['releaseYear'] = int.tryParse(values['releaseYear'].toString());
      } else {
        values['releaseYear'] = null;
      }

      if (_isEdit) {
        await _contentProvider.update(widget.content!.id, values);
      } else {
        await _contentProvider.insert(values);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Content updated.' : 'Content created.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Content',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${widget.content?.title}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _contentProvider.delete(widget.content!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Content deleted.'),
              backgroundColor: AppColors.error),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: _isEdit ? 'Edit Content' : 'Add Content',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FormBuilder(
        key: _formKey,
        initialValue: _initialValue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildLeftColumn()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildRightColumn()),
              ],
            ),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Basic Info'),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: 'title',
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Title *'),
          validator: FormBuilderValidators.required(),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: 'description',
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: 'releaseYear',
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Release Year'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        FormBuilderSwitch(
          name: 'isActive',
          title: const Text('Active',
              style: TextStyle(color: AppColors.textSecondary)),
          activeColor: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Metadata'),
        const SizedBox(height: 12),
        FormBuilderDropdown<int>(
          name: 'contentTypeId',
          decoration: const InputDecoration(labelText: 'Content Type *'),
          validator: FormBuilderValidators.required(),
          items: _contentTypes
              .map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.name,
                        style:
                            const TextStyle(color: AppColors.textPrimary)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        FormBuilderDropdown<int>(
          name: 'ageRatingId',
          decoration: const InputDecoration(labelText: 'Age Rating'),
          items: _ageRatings
              .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name,
                        style:
                            const TextStyle(color: AppColors.textPrimary)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        FormBuilderDropdown<int>(
          name: 'languageId',
          decoration: const InputDecoration(labelText: 'Language'),
          items: _languages
              .map((l) => DropdownMenuItem(
                    value: l.id,
                    child: Text(l.name,
                        style:
                            const TextStyle(color: AppColors.textPrimary)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Cover Image'),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: 'coverImageUrl',
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Cover Image URL'),
          onChanged: (v) => setState(() => _previewUrl = v),
        ),
        const SizedBox(height: 12),
        _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_previewUrl == null || _previewUrl!.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('No image', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: _previewUrl!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 160,
          color: AppColors.divider,
          child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 160,
          color: AppColors.divider,
          child: const Center(
              child: Text('Invalid URL',
                  style: TextStyle(color: AppColors.textMuted))),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save, size: 18),
          label: Text(_isEdit ? 'Update' : 'Create'),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.divider),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Cancel'),
        ),
        if (_isEdit) ...[
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }
}