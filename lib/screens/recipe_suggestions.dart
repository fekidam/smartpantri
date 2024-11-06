import 'package:flutter/material.dart';
import 'package:smartpantri/screens/recipe_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartpantri/services/api_services.dart';

class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  _RecipeSuggestionsScreenState createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen> {
  List<Map<String, dynamic>> recipes = [];
  List<String> selectedAllergies = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch recipes from API
      recipes = await APIService().fetchRecipes(selectedAllergies);

      // Fetch images via your Node.js server
      List<String> imageUrls = recipes.map((recipe) => 'https://img.spoonacular.com/recipes/${recipe['id']}-312x231.${recipe['imageType']}').toList();
      final response = await http.post(
        Uri.parse('http://localhost:3000/load-images'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'images': imageUrls}),
      );

      if (response.statusCode == 200) {
        final imageData = jsonDecode(response.body)['images'];
        for (int i = 0; i < recipes.length; i++) {
          recipes[i]['base64Image'] = imageData[i];
        }
      } else {
        throw Exception('Failed to load images');
      }

      setState(() {
        recipes.sort((a, b) => a['title'].compareTo(b['title']));
      });
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
        title: const Text('Recipe Suggestions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipes.isEmpty
              ? const Center(child: Text('No recipes available'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Adjust for more/less columns
                    childAspectRatio: 0.8,
                  ),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(recipeId: recipe['id']),
                          ),
                        );

                      },
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: recipe['base64Image'] != null
                                  ? Image.memory(
                                      base64Decode(recipe['base64Image'].split(',')[1]),
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.broken_image, size: 100),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                recipe['title'] ?? 'Unnamed Recipe',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
