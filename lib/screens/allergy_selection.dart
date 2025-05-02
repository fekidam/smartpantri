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
        widget.selectedAllergies.clear();
        widget.selectedAllergies.addAll(allergyKeys.map((key) => AppLocalizations.of(context)!.getString(key)).toList());
      }
      allSelected = !allSelected;
      widget.onSelectionChanged(widget.selectedAllergies);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectAllergies),
        actions: [
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              allSelected ? AppLocalizations.of(context)!.deselectAll : AppLocalizations.of(context)!.selectAll,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allergyKeys.length,
        itemBuilder: (context, index) {
          final allergyKey = allergyKeys[index];
          final allergy = AppLocalizations.of(context)!.getString(allergyKey);
          final isSelected = widget.selectedAllergies.contains(allergy);
          return CheckboxListTile(
            title: Text(allergy),
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true && !widget.selectedAllergies.contains(allergy)) {
                  widget.selectedAllergies.add(allergy);
                } else if (value == false) {
                  widget.selectedAllergies.remove(allergy);
                }
                allSelected = widget.selectedAllergies.length == allergyKeys.length;
                widget.onSelectionChanged(widget.selectedAllergies);
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, widget.selectedAllergies);
        },
      ),
    );
  }
}

extension AppLocalizationsExtension on AppLocalizations {
  String getString(String key) {
    switch (key) {
      case 'allergyDairy':
        return allergyDairy;
      case 'allergyEgg':
        return allergyEgg;
      case 'allergyGluten':
        return allergyGluten;
      case 'allergyPeanut':
        return allergyPeanut;
      case 'allergySeafood':
        return allergySeafood;
      case 'allergySesame':
        return allergySesame;
      case 'allergyShellfish':
        return allergyShellfish;
      case 'allergySoy':
        return allergySoy;
      case 'allergySulfite':
        return allergySulfite;
      case 'allergyTreeNut':
        return allergyTreeNut;
      case 'allergyWheat':
        return allergyWheat;
      default:
        return '';
    }
  }
}