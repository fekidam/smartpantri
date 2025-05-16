import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:smartpantri/generated/l10n.dart';
import '../../Providers/theme_provider.dart';
import '../../services/translation_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  final Color groupColor; // Hozzáadva a groupColor

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.groupColor, // Kötelező paraméter
  });

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecipeDetails();
    });
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final locale = Localizations.localeOf(context);
      final isHungarian = locale.languageCode == 'hu';

      final apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';
      final url =
          'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load recipe details: ${response.statusCode}');
      }

      final fetchedDetails =
      jsonDecode(response.body) as Map<String, dynamic>;

      final ingredients = (fetchedDetails['extendedIngredients']
      as List<dynamic>)
          .map((e) =>
      (e as Map<String, dynamic>)['original'] as String? ?? '')
          .toList();

      if (isHungarian) {
        fetchedDetails['title'] = await translateToHungarian(
          context,
          fetchedDetails['title'] as String? ?? '',
        );

        final rawInstr =
            fetchedDetails['instructions'] as String? ?? '';
        fetchedDetails['instructions'] = rawInstr.isNotEmpty
            ? await translateToHungarian(
          context,
          stripHtml(rawInstr),
          isHtml: true,
        )
            : null;

        final translatedIngredients =
        await translateListToHungarian(context, ingredients);
        for (var i = 0;
        i < fetchedDetails['extendedIngredients'].length;
        i++) {
          (fetchedDetails['extendedIngredients'][i]
          as Map<String, dynamic>)['original'] =
          translatedIngredients[i];
        }
      }

      setState(() {
        recipeDetails = fetchedDetails;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      final fontSizeScale = theme.fontSizeScale;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.unknownError}: $e',
            style: TextStyle(fontSize: 14 * fontSizeScale),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Provider.of<ThemeProvider>(context);
    final fontSizeScale = theme.fontSizeScale;
    final gradientOpacity = theme.gradientOpacity;
    final effectiveColor = theme.useGlobalTheme ? theme.primaryColor : widget.groupColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          recipeDetails?['title'] as String? ?? l10n.recipes,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 20 * fontSizeScale,
          ),
        ),
        backgroundColor: effectiveColor,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
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
            : recipeDetails == null
            ? Center(
          child: Text(
            l10n.failedToLoadRecipeDetails,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16 * fontSizeScale,
            ),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipeDetails!['image'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    recipeDetails!['image'] as String,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(
                          Icons.broken_image,
                          size: 150,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                '${l10n.servingsLabel}: ${recipeDetails!['servings']}',
                style: TextStyle(
                  fontSize: 18 * fontSizeScale,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.ingredientsLabel,
                style: TextStyle(
                  fontSize: 20 * fontSizeScale,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...((recipeDetails!['extendedIngredients']
              as List<dynamic>)
                  .map<Widget>((ing) {
                final orig =
                    (ing as Map<String, dynamic>)['original']
                    as String? ??
                        '';
                return Text(
                  '- $orig',
                  style: TextStyle(
                    fontSize: 16 * fontSizeScale,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              })).toList(),
              const SizedBox(height: 16),
              Text(
                l10n.instructionsLabel,
                style: TextStyle(
                  fontSize: 20 * fontSizeScale,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if ((recipeDetails!['instructions'] as String?)
                  ?.isNotEmpty ==
                  true)
                Html(
                  data: recipeDetails!['instructions'] as String,
                  style: {
                    '*': Style(
                      fontSize: FontSize(16 * fontSizeScale),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  },
                )
              else
                Text(
                  l10n.noInstructionsAvailable,
                  style: TextStyle(
                    fontSize: 16 * fontSizeScale,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}