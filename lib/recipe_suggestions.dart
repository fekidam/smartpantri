import 'package:flutter/material.dart';
import 'allergie_selection.dart';
import 'recipe_service.dart';

class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  _RecipeSuggestionsScreenState createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen> {
  final List<String> selectedAllergies = [];
  List<Map<String, dynamic>> recipes = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipes(); // Lekér minden receptet az alkalmazás első betöltésekor
  }

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
      _fetchRecipes();
    }
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Ha nincs allergia kiválasztva, akkor az összes receptet lekéri
      recipes = await RecipeService().fetchRecipes(selectedAllergies);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recipes: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Recipe Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToAllergySelection,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? const Center(child: Text('No available recipes.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Image.network(
                            recipes[index]['image'] ?? 'https://via.placeholder.com/150',
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              recipes[index]['name'] ?? 'Unknown Recipe',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
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
