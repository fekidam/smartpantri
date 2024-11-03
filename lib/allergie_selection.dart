import 'package:flutter/material.dart';

class AllergySelectionScreen extends StatefulWidget {
  final List<String> selectedAllergies;

  const AllergySelectionScreen({super.key, required this.selectedAllergies});

  @override
  _AllergySelectionScreenState createState() => _AllergySelectionScreenState();
}

class _AllergySelectionScreenState extends State<AllergySelectionScreen> {
  final List<String> allergies = [
    'Peanuts',
    'Shellfish',
    'Lactose',
    'Gluten',
    'Soy',
    'Eggs',
    'Fish',
    'Tree Nuts',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Allergies'),
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
                if (value == true) {
                  widget.selectedAllergies.add(allergy);
                } else {
                  widget.selectedAllergies.remove(allergy);
                }
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
