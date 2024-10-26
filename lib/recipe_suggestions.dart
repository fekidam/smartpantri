import 'package:flutter/material.dart';
import 'allergie_selection.dart';

class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({Key? key}) : super(key: key);

  @override
  _RecipeSuggestionsScreenState createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen> {
  final List<String> selectedAllergies = [];

  void _navigateToAllergySelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllergySelectionScreen(
          selectedAllergies: selectedAllergies,
        ),
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        selectedAllergies.clear();
        selectedAllergies.addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sample list of recipes
    final List<Map<String, String>> recipes = [
      {
        'name': 'Spaghetti Carbonara',
        'image': 'assets/images/carbonara.jpg'
      },
      {
        'name': 'Chicken Alfredo',
        'image': 'assets/images/chickenalfredo.jpg'
      },
      {
        'name': 'Beef Stroganoff',
        'image': 'assets/images/beefstroganoff.jpg'
      },
      {
        'name': 'Vegetable Stir Fry',
        'image': 'assets/images/vegetablestirfry.jpg'
      },
      // Add more recipes as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _navigateToAllergySelection,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Image.asset(
                  recipes[index]['image']!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    recipes[index]['name']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
