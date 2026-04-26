// Service Flutter pour appeler le backend Python PlantNet

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PlantResult {
  final String scientificName;
  final List<String> commonNames;
  final String family;
  final String genus;
  final double score;
  final String scorePercent;
  final String? gbifId;
  final String? wikipediaUrl;
  final String? imageUrl;

  PlantResult({
    required this.scientificName,
    required this.commonNames,
    required this.family,
    required this.genus,
    required this.score,
    required this.scorePercent,
    this.gbifId,
    this.wikipediaUrl,
    this.imageUrl,
  });

  factory PlantResult.fromJson(Map<String, dynamic> json) {
    return PlantResult(
      scientificName: json['scientific_name'] ?? '',
      commonNames: List<String>.from(json['common_names'] ?? []),
      family: json['family'] ?? '',
      genus: json['genus'] ?? '',
      score: (json['score'] as num).toDouble(),
      scorePercent: json['score_percent'] ?? '',
      gbifId: json['gbif_id'],
      wikipediaUrl: json['wikipedia_url'],
      imageUrl: json['image_url'],
    );
  }

  String get displayName =>
      commonNames.isNotEmpty ? commonNames.first : scientificName;
}

class IdentifyResponse {
  final bool success;
  final PlantResult? bestMatch;
  final List<PlantResult> alternatives;
  final String message;

  IdentifyResponse({
    required this.success,
    this.bestMatch,
    required this.alternatives,
    required this.message,
  });

  factory IdentifyResponse.fromJson(Map<String, dynamic> json) {
    return IdentifyResponse(
      success: json['success'] ?? false,
      bestMatch: json['best_match'] != null
          ? PlantResult.fromJson(json['best_match'])
          : null,
      alternatives: (json['alternatives'] as List<dynamic>? ?? [])
          .map((e) => PlantResult.fromJson(e))
          .toList(),
      message: json['message'] ?? '',
    );
  }
}

class PlantNetService {
  // ⚠️ Remplacez par l'URL de votre backend déployé
  // Pour test local Android émulateur : http://10.0.2.2:8000
  // Pour test local iOS simulateur  : http://localhost:8000
  static const String _baseUrl = 'http://10.0.2.2:8000';

  /// Identifie une plante depuis un fichier image
  static Future<IdentifyResponse> identifyPlant({
    required File imageFile,
    String organ = 'auto',
    String project = 'all',
    int nbResults = 5,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/identify?organ=$organ&project=$project&nb_results=$nbResults',
    );

    final request = http.MultipartRequest('POST', uri);

    // Détection du type MIME
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return IdentifyResponse.fromJson(json);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Erreur serveur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Impossible de contacter le serveur: $e');
    }
  }
}
