import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:progressio_desktop/layouts/master_screen.dart';
import 'package:progressio_desktop/model/city.dart';
import 'package:progressio_desktop/model/country.dart';
import 'package:progressio_desktop/model/search_result.dart';
import 'package:progressio_desktop/providers/city_provider.dart';
import 'package:progressio_desktop/providers/country_provider.dart';
import 'package:progressio_desktop/utils/app_colors.dart';
import 'package:progressio_desktop/widgets/app_ui.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  late CountryProvider _countryProvider;
  late CityProvider _cityProvider;

  final _countrySearchController = TextEditingController();
  final _citySearchController = TextEditingController();

  List<Country> _countries = [];
  Country? _selectedCountry;
  SearchResult<City>? _cityResult;
  bool _loadingCountries = false;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _countryProvider = context.read<CountryProvider>();
      _cityProvider = context.read<CityProvider>();
      _loadCountries();
    });
  }

  @override
  void dispose() {
    _countrySearchController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    try {
      final items = await _countryProvider.getAll();
      if (mounted) setState(() => _countries = items);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loadingCountries = false);
    }
  }

  Future<void> _loadCities() async {
    if (_selectedCountry == null) return;
    setState(() => _loadingCities = true);
    try {
      final items = await _cityProvider.getAll(
        filter: {
          'countryId': _selectedCountry!.id,
          if (_citySearchController.text.trim().isNotEmpty)
            'name': _citySearchController.text.trim(),
        },
      );
      if (mounted) {
        setState(() {
          _cityResult = SearchResult<City>(
            totalCount: items.length,
            items: items,
          );
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _loadingCities = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _openCountryDialog({Country? country}) async {
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          country == null ? 'Add Country' : 'Edit Country',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 360,
          child: FormBuilder(
            key: formKey,
            initialValue: {
              'name': country?.name ?? '',
              'code': country?.code ?? '',
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormBuilderTextField(
                  name: 'name',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(
                  name: 'code',
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Code (e.g. BA, US)'),
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
          if (country != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCountry(country);
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
                if (country == null) {
                  await _countryProvider.insert(values);
                } else {
                  await _countryProvider.update(country.id, values);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(country == null
                      ? 'Country created.'
                      : 'Country updated.'),
                  backgroundColor: AppColors.success,
                ));
                _loadCountries();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(country == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCityDialog({City? city}) async {
    if (_selectedCountry == null) return;
    final formKey = GlobalKey<FormBuilderState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          city == null ? 'Add City' : 'Edit City',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: 360,
          child: FormBuilder(
            key: formKey,
            initialValue: {'name': city?.name ?? ''},
            child: FormBuilderTextField(
              name: 'name',
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'City Name *'),
              validator: FormBuilderValidators.required(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          if (city != null)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCity(city);
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
              values['countryId'] = _selectedCountry!.id;
              Navigator.pop(context);
              try {
                if (city == null) {
                  await _cityProvider.insert(values);
                } else {
                  await _cityProvider.update(city.id, values);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      city == null ? 'City created.' : 'City updated.'),
                  backgroundColor: AppColors.success,
                ));
                _loadCities();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(city == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCountry(Country country) async {
    if (!await showDeleteConfirmation(context, itemName: country.name)) return;
    try {
      await _countryProvider.delete(country.id);
      if (_selectedCountry?.id == country.id) {
        setState(() {
          _selectedCountry = null;
          _cityResult = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Country deleted.'),
            backgroundColor: AppColors.error),
      );
      _loadCountries();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteCity(City city) async {
    if (!await showDeleteConfirmation(context, itemName: city.name)) return;
    try {
      await _cityProvider.delete(city.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('City deleted.'),
            backgroundColor: AppColors.error),
      );
      _loadCities();
    } catch (e) {
      _showError(e.toString());
    }
  }

  List<Country> get _filteredCountries {
    final q = _countrySearchController.text.toLowerCase();
    if (q.isEmpty) return _countries;
    return _countries
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: 'Countries & Cities',
      child: Row(
        children: [
          // Left — countries
          Container(
            width: 300,
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COUNTRIES',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _countrySearchController,
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search countries...',
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textMuted, size: 18),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openCountryDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Country'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: _loadingCountries
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary))
                      : ListView(
                          children: _filteredCountries
                              .map((c) => ListTile(
                                    dense: true,
                                    selected:
                                        _selectedCountry?.id == c.id,
                                    selectedTileColor: AppColors.primary
                                        .withOpacity(0.15),
                                    title: Text(
                                      c.name,
                                      style: TextStyle(
                                        color:
                                            _selectedCountry?.id == c.id
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: c.code != null
                                        ? Text(c.code!,
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11))
                                        : null,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.primary,
                                          size: 16),
                                      onPressed: () =>
                                          _openCountryDialog(country: c),
                                    ),
                                    onTap: () {
                                      setState(
                                          () => _selectedCountry = c);
                                      _loadCities();
                                    },
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          // Right — cities
          Expanded(
            child: Column(
              children: [
                _buildCityToolbar(),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(child: _buildCityContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _citySearchController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: _selectedCountry != null
                    ? 'Search cities in ${_selectedCountry!.name}...'
                    : 'Select a country first...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textMuted),
              ),
              enabled: _selectedCountry != null,
              onSubmitted: (_) => _loadCities(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed:
                _selectedCountry != null ? () => _loadCities() : null,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed:
                _selectedCountry != null ? () => _openCityDialog() : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add City'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildCityContent() {
    if (_selectedCountry == null) {
      return const Center(
        child: Text('Select a country to view its cities.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    if (_loadingCities) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final cities = _cityResult?.items ?? [];
    if (cities.isEmpty) {
      return Center(
        child: Text(
          'No cities found for ${_selectedCountry!.name}.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('City Name')),
            DataColumn(label: Text('Actions')),
          ],
          rows: cities
              .map((c) => DataRow(cells: [
                    DataCell(Text(c.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500))),
                    DataCell(IconButton(
                      icon: const Icon(Icons.edit,
                          color: AppColors.primary, size: 18),
                      tooltip: 'Edit',
                      onPressed: () => _openCityDialog(city: c),
                    )),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}