import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

class EcranDetailComestible extends StatefulWidget {
  final Map<String, dynamic>? analysis;
  const EcranDetailComestible({super.key, this.analysis});

  @override
  State<EcranDetailComestible> createState() => _EcranDetailComestibleState();
}

class _EcranDetailComestibleState extends State<EcranDetailComestible> {
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    _loadFromAnalysis();
  }

  void _loadFromAnalysis() {
    final a = widget.analysis;
    if (a == null) {
      return;
    }
    final raw = a['result'];
    try {
      if (raw is String && raw.isNotEmpty) {
        _resultData = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        _resultData = Map<String, dynamic>.from(raw);
      }
    } catch (_) {
      _resultData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color onSurface = Color(0xFF1b1d0e);

    final id = widget.analysis != null ? widget.analysis!['id'] : null;
    final imageUrl = (id != null)
        ? '${ApiService.instance.baseUrl}/analyses/$id/image'
        : null;

    String title = 'Détails — Comestible';
    String description = '';
    List<String> commonNames = [];

    try {
      final suggestions =
          _resultData?['result']?['classification']?['suggestions'] as List?;
      if (suggestions != null && suggestions.isNotEmpty) {
        final top = suggestions[0];
        title = top['name'] ?? title;
        final details = top['details'] ?? {};
        description = (details['description'] is Map)
            ? (details['description']['value'] ?? '')
            : (details['description'] ?? '');
        final commons = details['common_names'] as List?;
        if (commons != null) {
          commonNames = commons.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0d631b)),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 260,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 14),
              if (commonNames.isNotEmpty) ...[
                Text(
                  'Noms communs: ${commonNames.join(', ')}',
                  style: GoogleFonts.inter(color: onSurface),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                description.isNotEmpty
                    ? description
                    : 'Aucune description disponible.',
                style: GoogleFonts.inter(color: onSurface),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Retour',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
