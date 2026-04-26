import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

class EcranDetailComestible extends StatefulWidget {
  final Map<String, dynamic>? analysis;
  final Map<String, dynamic>? plantInfo;
  final String? plantName;
  const EcranDetailComestible({
    super.key,
    this.analysis,
    this.plantInfo,
    this.plantName,
  });

  @override
  State<EcranDetailComestible> createState() => _EcranDetailComestibleState();
}

class _EcranDetailComestibleState extends State<EcranDetailComestible> {
  Map<String, dynamic>? _info;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _info = widget.plantInfo;
    // Si on n'a pas reçu d'info, essayer de la récupérer avec plantName
    if (_info == null && (widget.plantName ?? '').isNotEmpty) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await ApiService.instance.getPlantInfo(widget.plantName!);
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _s(String key, [String fallback = '']) {
    final v = _info?[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty ||
        s.toLowerCase() == 'inconnu' ||
        s.toLowerCase() == 'inconnue') {
      return fallback;
    }
    return s;
  }

  List<String> _l(String key) {
    final v = _info?[key];
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color surfaceLowest = Color(0xFFFFFFFF);

    final id = widget.analysis != null ? widget.analysis!['id'] : null;
    final imageUrl = (id != null)
        ? '${ApiService.instance.baseUrl}/analyses/$id/image'
        : null;

    final plantName = widget.plantName ?? _s('nom_scientifique', 'Plante');
    final commonNames = _l('noms_communs');
    final famille = _s('famille');
    final estComestible = _s('est_comestible', 'inconnu');
    final details = _s(
      'comestible_details',
      'Aucune information disponible sur la comestibilité de cette plante.',
    );
    final toxicite = _s('toxicite', 'inconnue');
    final toxiciteDetails = _s('toxicite_details', '');

    // Couleur du badge selon comestibilité
    Color badgeColor = onSurfaceVariant;
    String badgeLabel = 'Comestibilité : ${estComestible.toUpperCase()}';
    if (estComestible == 'oui') {
      badgeColor = primary;
    } else if (estComestible == 'non') {
      badgeColor = const Color(0xFFba1a1a);
    } else if (estComestible == 'partiellement') {
      badgeColor = const Color(0xFFb58900);
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: primary),
        title: Text(
          'Comestible',
          style: GoogleFonts.manrope(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                plantName,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              if (commonNames.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  commonNames.take(4).join(', '),
                  style: GoogleFonts.inter(color: onSurfaceVariant),
                ),
              ],
              if (famille.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Famille : $famille',
                  style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeColor.withAlpha(120)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restaurant, size: 16, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: GoogleFonts.inter(
                        color: badgeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null && !_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFb58900)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Infos indisponibles (${_error!})',
                          style: GoogleFonts.inter(color: onSurfaceVariant),
                        ),
                      ),
                      TextButton(onPressed: _fetch, child: const Text('Réessayer')),
                    ],
                  ),
                ),
              _SectionCard(
                icon: Icons.eco,
                iconColor: primary,
                title: 'Détails de la comestibilité',
                text: details,
                bg: surfaceLowest,
              ),
              const SizedBox(height: 12),
              if (toxiciteDetails.isNotEmpty)
                _SectionCard(
                  icon: Icons.health_and_safety,
                  iconColor: const Color(0xFFba1a1a),
                  title: 'Précautions (toxicité : ${toxicite.toLowerCase()})',
                  text: toxiciteDetails,
                  bg: surfaceLowest,
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFb58900).withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFb58900)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ne consomme jamais une plante sans certitude absolue de son identification. '
                        'En cas de doute, demande l\'avis d\'un botaniste ou d\'un professionnel.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6b4c00),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Retour',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;
  final Color bg;
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF40493d),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
