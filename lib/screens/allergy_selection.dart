import 'package:flutter/material.dart';

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
  final List<String> allergies = [
    'Dairy',
    'Egg',
    'Gluten',
    'Peanut',
    'Seafood',
    'Sesame',
    'Shellfish',
    'Soy',
    'Sulfite',
    'Tree Nut',
    'Wheat',
  ];

  bool allSelected = false;

  void _toggleSelectAll() {
    setState(() {
      if (allSelected) {
        widget.selectedAllergies.clear();
      } else {
        widget.selectedAllergies.clear();
        widget.selectedAllergies.addAll(allergies);
      }
      allSelected = !allSelected;
      widget.onSelectionChanged(widget.selectedAllergies);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Allergies'),
        actions: [
          TextButton(
            onPressed: _toggleSelectAll,
            child: Text(
              allSelected ? 'Deselect All' : 'Select All',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allergies.length,
        itemBuilder: (context, index) {
          final allergy = allergies[index];
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
                allSelected = widget.selectedAllergies.length == allergies.length;
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
