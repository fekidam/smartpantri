import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=ecd59cba2ae2429baa2a4186b108b23e',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          recipeDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load recipe details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recipe details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipeDetails?['title'] ?? 'Recipe Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipeDetails == null
              ? const Center(child: Text('Failed to load recipe details'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          'http://192.168.100.5:3000/fetch-image?url=${Uri.encodeComponent(recipeDetails!['image'])}',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 150),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          'Servings: ${recipeDetails!['servings']}',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                            'Ingredients:',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ...recipeDetails!['extendedIngredients'].map<Widget>((ingredient) {
                            return Text(
                              '- ${ingredient['original']}',
                              style: const TextStyle(fontSize: 16),
                            );
                          }).toList(),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Instructions:',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          recipeDetails!['instructions'] != null
                              ? Html(data: recipeDetails!['instructions'])
                              : const Text(
                                  'No instructions available',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
