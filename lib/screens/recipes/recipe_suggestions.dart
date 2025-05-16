import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartpantri/screens/recipes/recipe_detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../Providers/theme_provider.dart';
import '../../services/translation_service.dart';
import 'allergy_selection.dart';
import 'package:smartpantri/generated/l10n.dart';

class RecipeSuggestionsScreen extends StatefulWidget {
  final bool fromGroupScreen;
  final bool isGuest;
  final Color groupColor;

  const RecipeSuggestionsScreen({
    super.key,
    this.fromGroupScreen = false,
    this.isGuest = false,
    required this.groupColor,
  });

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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        List<Map<String, dynamic>> fetchedRecipes =
        List<Map<String, dynamic>>.from(data['results']);

        final locale = Localizations.localeOf(context);
        final isHungarian = locale.languageCode == 'hu';

        if (isHungarian) {
          for (var recipe in fetchedRecipes) {
            recipe['title'] = await translateToHungarian(
                context, recipe['title'] ?? 'Unknown');
          }
        }

        setState(() {
          recipes = fetchedRecipes;
        });
      } else {
        throw Exception(
            'Failed to fetch recipes: ${response.statusCode}');
      }
    } catch (error) {
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final fontSizeScale = theme.fontSizeScale;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.unknownError}: $error',
            style: TextStyle(fontSize: 14 * fontSizeScale),
          ),
        ),
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
          onSelectionChanged: (updated) {
            setState(() {
              selectedAllergies = updated;
            });
            _fetchRecipes();
          },
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;

    if (widget.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.featureRequiresLogin,
            style: TextStyle(fontSize: 14 * fontSizeScale),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            recipeId: recipeId,
            groupColor: widget.groupColor,
          ),
        ),
      );
    }
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final fontSizeScale = theme.fontSizeScale;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          recipe['image'] != null
              ? ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10.0)),
            child: Image.network(
              recipe['image'] as String,
              height: MediaQuery.of(context).size.height * 0.15,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text(
                AppLocalizations.of(context)!.failedToLoadImage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14 * fontSizeScale,
                ),
              ),
            ),
          )
              : Icon(
            Icons.broken_image,
            size: 100,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 30,
                maxHeight: 50,
              ),
              child: Text(
                recipe['title'] ?? AppLocalizations.of(context)!.unknownItem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14 * fontSizeScale,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  backgroundColor: theme.primaryColor,
                ),
                onPressed: () => _viewRecipeDetails(recipe['id'] as int),
                child: Text(
                  AppLocalizations.of(context)!.viewDetails,
                  style: TextStyle(
                    fontSize: 12 * fontSizeScale,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
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
    final theme = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final iconStyle = theme.iconStyle;
    final effectiveColor = widget.fromGroupScreen
        ? widget.groupColor
        : theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.recipeSuggestions,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20 * fontSizeScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: effectiveColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false,
        actions: [
          if (!widget.isGuest)
            IconButton(
              icon: Icon(
                iconStyle == 'filled'
                    ? Icons.filter_list
                    : Icons.filter_list_outlined,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: _openAllergySelection,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectiveColor.withOpacity(gradientOpacity),
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: effectiveColor))
            : recipes.isEmpty
            ? Center(
          child: Text(
            l10n.noRecipesAvailable,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16 * fontSizeScale,
            ),
          ),
        )
            : GridView.builder(
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
          ),
          itemCount: recipes.length,
          itemBuilder: (context, index) => _buildRecipeCard(recipes[index]),
        ),
      ),
    );
  }
}