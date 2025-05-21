import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// API szolgáltatás osztály a Spoonacular API-hoz
class APIService {
  static final String _baseUrl = 'api.spoonacular.com'; // API alap URL
  static final String _apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? ''; // API kulcs

  // Receptek lekérése a Spoonacular API-ból
  Future<List<Map<String, dynamic>>> fetchRecipes(List<String> intolerances, {String diet = ''}) async {
    final queryParameters = {
      'apiKey': _apiKey,
      'number': '10', // Maximum 10 recept lekérése
      'intolerances': intolerances.join(','), // Allergia szűrő
      'diet': diet, // Diéta szűrő
      'addRecipeInformation': 'true',
      'instructionsRequired': 'true',
    };

    final uri = Uri.https(_baseUrl, '/recipes/complexSearch', queryParameters);
    final response = await http.get(uri); // API hívás

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results']); // Sikeres válasz
    } else {
      throw Exception('Failed to load recipes: ${response.statusCode}'); // Hiba esetén kivétel
    }
  }
}