import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class APIService {
  static final String _baseUrl = 'api.spoonacular.com';
  static final String _apiKey = dotenv.env['SPOONACULAR_API_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> fetchRecipes(List<String> intolerances, {String diet = ''}) async {
    final queryParameters = {
      'apiKey': _apiKey,
      'number': '10',
      'intolerances': intolerances.join(','),
      'diet': diet,
      'addRecipeInformation': 'true',
      'instructionsRequired': 'true',
    };

    final uri = Uri.https(_baseUrl, '/recipes/complexSearch', queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Failed to load recipes: ${response.statusCode}');
    }
  }
}
