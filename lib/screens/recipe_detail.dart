import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // API kulcs kezeléséhez
import 'package:smartpantri/generated/l10n.dart'; // AppLocalizations import

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
      final apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
      final response = await http.get(
        Uri.parse(
          'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey',
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
        SnackBar(content: Text('${AppLocalizations.of(context)!.unknownError}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipeDetails?['title'] ?? AppLocalizations.of(context)!.recipes),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recipeDetails == null
          ? Center(child: Text(AppLocalizations.of(context)!.failedToLoadRecipeDetails))
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
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 150),
              ),
              const SizedBox(height: 16.0),
              Text(
                '${AppLocalizations.of(context)!.servingsLabel}: ${recipeDetails!['servings']}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.ingredientsLabel,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ...recipeDetails!['extendedIngredients'].map<Widget>((ingredient) {
                return Text(
                  '- ${ingredient['original']}',
                  style: const TextStyle(fontSize: 16),
                );
              }).toList(),
              const SizedBox(height: 16.0),
              Text(
                AppLocalizations.of(context)!.instructionsLabel,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              recipeDetails!['instructions'] != null
                  ? Html(data: recipeDetails!['instructions'])
                  : Text(
                AppLocalizations.of(context)!.noInstructionsAvailable,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}