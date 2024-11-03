import 'package:openapi/api/recipes_api.dart';

class RecipeService {
  final Openapi spoonacularClient;

  RecipeService(String apiKey) : spoonacularClient = Openapi(apiKey);

  Future<List<Map<String, dynamic>>> fetchRecipes(List<String> allergies, {int maxUsedIngredients = 5}) async {
    try {
      final response = await spoonacularClient.getRecipesComplexSearch(
        maxUsedIngredients: maxUsedIngredients,
        intolerances: allergies.isNotEmpty ? allergies.join(',') : null,
        number: 10,
        sort: 'max-used-ingredients',
      );

      // Convert the response to a list of recipes as needed
      return List<Map<String, dynamic>>.from(response['results']);
    } catch (e) {
      throw Exception('Failed to load recipes: $e');
    }
  }
}
