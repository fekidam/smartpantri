import 'package:flutter/material.dart';
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

class AllergySelectionScreen extends StatefulWidget {
  final List<String> selectedAllergies;
  final Function(List<String>) onSelectionChanged;

  const AllergySelectionScreen({
    super.key,
    required this.selectedAllergies,
    required this.onSelectionChanged,
  });

  @override
  _AllergySelectionScreenState createState() => _AllergySelectionScreenState();
}

class _AllergySelectionScreenState extends State<AllergySelectionScreen> {
  final List<String> allergyKeys = [
    'allergyDairy',
    'allergyEgg',
    'allergyGluten',
    'allergyPeanut',
    'allergySeafood',
    'allergySesame',
    'allergyShellfish',
    'allergySoy',
    'allergySulfite',
    'allergyTreeNut',
    'allergyWheat',
  ];
  bool allSelected = false;

  void _toggleSelectAll() {
    setState(() {
      if (allSelected) {
        widget.selectedAllergies.clear();
      } else {
        widget.selectedAllergies
          ..clear()
          ..addAll(allergyKeys.map((key) => AppLocalizations.of(context)!.getString(key)));
      }
      allSelected = !allSelected;
      widget.onSelectionChanged(widget.selectedAllergies);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(l10n.selectAllergies),
        actions: [
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              allSelected ? l10n.deselectAll : l10n.selectAll,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: ListView.separated(
          itemCount: allergyKeys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final key = allergyKeys[index];
            final label = l10n.getString(key);
            final isSelected = widget.selectedAllergies.contains(label);

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(label, style: theme.textTheme.bodyLarge),
                activeColor: theme.primaryColor,
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) widget.selectedAllergies.add(label);
                    else widget.selectedAllergies.remove(label);
                    allSelected = widget.selectedAllergies.length == allergyKeys.length;
                    widget.onSelectionChanged(widget.selectedAllergies);
                  });
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.check),
        onPressed: () => Navigator.pop(context, widget.selectedAllergies),
      ),
    );
  }
}

/// Extension remains unchanged:
extension AppLocalizationsExtension on AppLocalizations {
  String getString(String key) {
    switch (key) {
      case 'allergyDairy':     return allergyDairy;
      case 'allergyEgg':       return allergyEgg;
      case 'allergyGluten':    return allergyGluten;
      case 'allergyPeanut':    return allergyPeanut;
      case 'allergySeafood':   return allergySeafood;
      case 'allergySesame':    return allergySesame;
      case 'allergyShellfish': return allergyShellfish;
      case 'allergySoy':       return allergySoy;
      case 'allergySulfite':   return allergySulfite;
      case 'allergyTreeNut':   return allergyTreeNut;
      case 'allergyWheat':     return allergyWheat;
      default:                 return '';
    }
  }
}
