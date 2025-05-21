import 'package:flutter/material.dart';
import 'package:smartpantri/generated/l10n.dart';

// Képernyő az allergiák kiválasztására
class AllergySelectionScreen extends StatefulWidget {
  final List<String> selectedAllergies; // Kiválasztott allergiák listája
  final Function(List<String>) onSelectionChanged; // Callback a kiválasztás változásakor

  const AllergySelectionScreen({
    super.key,
    required this.selectedAllergies,
    required this.onSelectionChanged,
  });

  @override
  _AllergySelectionScreenState createState() => _AllergySelectionScreenState();
}

class _AllergySelectionScreenState extends State<AllergySelectionScreen> {
  // Elérhető allergiák kulcsai a lokalizációhoz
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
  bool allSelected = false; // Minden allergia kiválasztva állapot

  // Összes allergia ki-/bekapcsolása
  void _toggleSelectAll() {
    setState(() {
      if (allSelected) {
        widget.selectedAllergies.clear(); // Minden allergia törlése
      } else {
        // Összes allergia hozzáadása a lokalizált nevekkel
        widget.selectedAllergies
          ..clear()
          ..addAll(allergyKeys.map((key) => AppLocalizations.of(context)!.getString(key)));
      }
      allSelected = !allSelected; // Állapot váltása
      widget.onSelectionChanged(widget.selectedAllergies); // Callback hívása
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
        // Allergiák listájának megjelenítése
        child: ListView.separated(
          itemCount: allergyKeys.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final key = allergyKeys[index];
            final label = l10n.getString(key); // Allergia neve lokalizáltan
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
                    if (v == true) widget.selectedAllergies.add(label); // Allergia hozzáadása
                    else widget.selectedAllergies.remove(label); // Allergia eltávolítása
                    allSelected = widget.selectedAllergies.length == allergyKeys.length;
                    widget.onSelectionChanged(widget.selectedAllergies); // Callback hívása
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
        onPressed: () => Navigator.pop(context, widget.selectedAllergies), // Kiválasztás mentése és vissza navigálás
      ),
    );
  }
}

// AppLocalizations kiterjesztés az allergia kulcsok kezelésére
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