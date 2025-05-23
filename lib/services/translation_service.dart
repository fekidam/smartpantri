import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smartpantri/generated/l10n.dart';

// HTML tagek eltávolítása szövegből
String stripHtml(String htmlText) {
  return htmlText.replaceAll(RegExp(r'<[^>]+>'), '');
}

// Szöveg fordítása magyarrá a Google Translate API-val
Future<String> translateToHungarian(BuildContext context, String text, {bool isHtml = false}) async {
  if (text.isEmpty) return text;

  final apiKey = dotenv.env['GOOGLE_TRANSLATE_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    throw Exception(AppLocalizations.of(context)!.translationApiKeyMissing);
  }

  final uri = Uri.parse(
    'https://translation.googleapis.com/language/translate/v2?key=$apiKey',
  );

  final textToTranslate = isHtml ? stripHtml(text) : text;

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': [textToTranslate], // Szöveg listába csomagolva az API követelménye szerint
        'source': 'en',
        'target': 'hu',
        'format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String translatedText = data['data']['translations'][0]['translatedText'];
      translatedText = _handleUnits(translatedText); // Mértékegységek kezelése
      return isHtml ? '<p>$translatedText</p>' : translatedText; // HTML formátumú szöveg esetén p tag hozzáadása
    } else {
      throw Exception(AppLocalizations.of(context)!.failedToTranslateText(response.statusCode.toString(), response.body));
    }
  } catch (e) {
    throw Exception(AppLocalizations.of(context)!.translationError(e.toString()));
  }
}

// Szöveglista fordítása magyarrá
Future<List<String>> translateListToHungarian(BuildContext context, List<String> texts) async {
  if (texts.isEmpty) return texts;

  final apiKey = dotenv.env['GOOGLE_TRANSLATE_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    throw Exception(AppLocalizations.of(context)!.translationApiKeyMissing);
  }

  final uri = Uri.parse(
    'https://translation.googleapis.com/language/translate/v2?key=$apiKey',
  );

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': texts,
        'source': 'en',
        'target': 'hu',
        'format': 'text',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['data']['translations'].map((t) => _handleUnits(t['translatedText'])));
    } else {
      throw Exception(AppLocalizations.of(context)!.failedToTranslateText(response.statusCode.toString(), response.body));
    }
  } catch (e) {
    throw Exception(AppLocalizations.of(context)!.translationError(e.toString()));
  }
}

// Mértékegységek konvertálása és magyarosítása
String _handleUnits(String text) {
  return text
      .replaceAll('cup', 'csésze')
      .replaceAll('tablespoon', 'evőkanál')
      .replaceAll('teaspoon', 'teáskanál')
      .replaceAll('ounce', 'uncia')
      .replaceAll('pound', 'font')
      .replaceAllMapped(RegExp(r'(\d+)\s*°F'), (match) {
    final fahrenheit = int.parse(match[1]!);
    final celsius = ((fahrenheit - 32) * 5 / 9).round();
    return '$celsius °C';
  });
}