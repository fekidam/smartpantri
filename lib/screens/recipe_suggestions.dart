import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartpantri/screens/recipe_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import 'allergy_selection.dart';

class RecipeSuggestionsScreen extends StatefulWidget {
  final bool fromGroupScreen;
  final bool isGuest;

  const RecipeSuggestionsScreen({super.key, this.fromGroupScreen = false, this.isGuest = false});

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
      final queryParameters = {
        'number': '50',
        'intolerances': selectedAllergies.join(','),
        'addRecipeInformation': 'true',
        'apiKey': dotenv.env['SPOONACULAR_API_KEY'],
      };

      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/complexSearch',
        queryParameters,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recipes = List<Map<String, dynamic>>.from(data['results']);
        });
      } else {
        throw Exception('Failed to fetch recipes');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recipes: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _openAllergySelection() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => AllergySelectionScreen(
          selectedAllergies: List.from(selectedAllergies),
          onSelectionChanged: (updatedAllergies) {},
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedAllergies = result;
      });
      _fetchRecipes();
    }
  }

  void _viewRecipeDetails(int recipeId) {
    if (widget.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view recipe details.'),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(recipeId: recipeId),
        ),
      );
    }
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic image height, reduced to fit better
          recipe['image'] != null
              ? ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
            child: Image.network(
              recipe['image'],
              height: MediaQuery.of(context).size.height * 0.15, // Reduced to 15% of screen height
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 100),
            ),
          )
              : const Icon(Icons.broken_image, size: 100),
          // Recipe title with constrained height
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 30, // Reduced minimum height
                maxHeight: 50, // Reduced maximum height to fit within constraints
              ),
              child: Text(
                recipe['title'] ?? 'Unknown Recipe',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14, // Slightly smaller font size to reduce height
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // View Details button with reduced padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0), // Reduced vertical padding
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Reduced button height
                ),
                onPressed: () => _viewRecipeDetails(recipe['id']),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 12), // Smaller font size for the button
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Recipe Suggestions'),
            backgroundColor: themeProvider.primaryColor, // Use theme's primaryColor
            foregroundColor: Colors.white,
            automaticallyImplyLeading: widget.fromGroupScreen,
            actions: [
              if (!widget.isGuest)
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _openAllergySelection,
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : recipes.isEmpty
              ? const Center(child: Text('No recipes available'))
              : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Increased to provide more height
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _buildRecipeCard(recipe);
            },
          ),
        );
      },
    );
  }
}