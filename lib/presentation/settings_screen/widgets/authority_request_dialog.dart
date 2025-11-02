import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Authority Request Dialog
/// Form dialog for requesting authority role
class AuthorityRequestDialog extends StatefulWidget {
  const AuthorityRequestDialog({super.key});

  @override
  State<AuthorityRequestDialog> createState() => _AuthorityRequestDialogState();
}

class _AuthorityRequestDialogState extends State<AuthorityRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  final _organizationController = TextEditingController();
  final _referrerCodeController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedLocation;

  // Malaysia states and federal territories
  final List<Map<String, String>> _malaysiaLocations = [
    {'key': 'johor', 'value': 'Johor'},
    {'key': 'kedah', 'value': 'Kedah'},
    {'key': 'kelantan', 'value': 'Kelantan'},
    {'key': 'malacca', 'value': 'Malacca'},
    {'key': 'negeriSembilan', 'value': 'Negeri Sembilan'},
    {'key': 'pahang', 'value': 'Pahang'},
    {'key': 'penang', 'value': 'Penang'},
    {'key': 'perak', 'value': 'Perak'},
    {'key': 'perlis', 'value': 'Perlis'},
    {'key': 'sabah', 'value': 'Sabah'},
    {'key': 'sarawak', 'value': 'Sarawak'},
    {'key': 'selangor', 'value': 'Selangor'},
    {'key': 'terengganu', 'value': 'Terengganu'},
    {'key': 'kualaLumpur', 'value': 'Kuala Lumpur'},
    {'key': 'labuan', 'value': 'Labuan'},
    {'key': 'putrajaya', 'value': 'Putrajaya'},
  ];

  @override
  void dispose() {
    _idNumberController.dispose();
    _organizationController.dispose();
    _referrerCodeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  String _getLocalizedLocation(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'johor':
        return l10n.location_johor;
      case 'kedah':
        return l10n.location_kedah;
      case 'kelantan':
        return l10n.location_kelantan;
      case 'malacca':
        return l10n.location_malacca;
      case 'negeriSembilan':
        return l10n.location_negeriSembilan;
      case 'pahang':
        return l10n.location_pahang;
      case 'penang':
        return l10n.location_penang;
      case 'perak':
        return l10n.location_perak;
      case 'perlis':
        return l10n.location_perlis;
      case 'sabah':
        return l10n.location_sabah;
      case 'sarawak':
        return l10n.location_sarawak;
      case 'selangor':
        return l10n.location_selangor;
      case 'terengganu':
        return l10n.location_terengganu;
      case 'kualaLumpur':
        return l10n.location_kualaLumpur;
      case 'labuan':
        return l10n.location_labuan;
      case 'putrajaya':
        return l10n.location_putrajaya;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.settings_requestAuthorityDialog),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settings_requestAuthorityDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // ID Number *
              TextFormField(
                controller: _idNumberController,
                decoration: InputDecoration(
                  labelText: '${l10n.settings_idNumber} *',
                  hintText: l10n.settings_idNumberHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.settings_idNumberRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Organization *
              TextFormField(
                controller: _organizationController,
                decoration: InputDecoration(
                  labelText: '${l10n.settings_organization} *',
                  hintText: l10n.settings_organizationHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.settings_organizationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location *
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '${l10n.settings_location} *',
                  hintText: l10n.settings_locationHint,
                  border: const OutlineInputBorder(),
                ),
                items: _malaysiaLocations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location['value'],
                    child: Text(
                      _getLocalizedLocation(context, location['key']!),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.settings_locationRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Referrer Code (optional)
              TextFormField(
                controller: _referrerCodeController,
                decoration: InputDecoration(
                  labelText: l10n.settings_referrerCode,
                  hintText: l10n.settings_referrerCodeHint,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length != 6 ||
                        !RegExp(r'^\d{6}$').hasMatch(value)) {
                      return l10n.settings_referrerCodeInvalid;
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Remarks (optional)
              TextFormField(
                controller: _remarksController,
                decoration: InputDecoration(
                  labelText: l10n.settings_remarks,
                  hintText: l10n.settings_remarksHint,
                  border: const OutlineInputBorder(),
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
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final data = {
                'idNumber': _idNumberController.text.trim(),
                'organization': _organizationController.text.trim(),
                'location': _selectedLocation!,
                if (_referrerCodeController.text.trim().isNotEmpty)
                  'referrerCode': _referrerCodeController.text.trim(),
                if (_remarksController.text.trim().isNotEmpty)
                  'remarks': _remarksController.text.trim(),
              };
              Navigator.pop(context, data);
            }
          },
          child: Text(l10n.common_submit),
        ),
      ],
    );
  }
}
