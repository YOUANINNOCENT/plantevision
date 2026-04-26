import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_assistant_chat.dart';
import 'ecran_accueil.dart';
import 'ecran_tableau.dart';
import 'ecran_historique.dart';
import 'ecran_detail_comestible.dart';
import 'ecran_detail_medicinale.dart';
import 'services/api_service.dart';
import 'services/i18n.dart';

class EcranResultatAnalyse extends StatefulWidget {
  final Map<String, dynamic>? analysis;
  /// 'high' | 'medium' | 'low' (transmis par le scanner après identification)
  final String? confidenceLevel;
  /// Top-3 espèces candidates avec leurs scores (le scanner transmet ce que
  /// PlantNet a renvoyé pour permettre à l'utilisateur de corriger).
  final List<Map<String, dynamic>>? candidates;
  /// True si top1 et top2 sont très proches (identification incertaine).
  final bool ambiguous;

  const EcranResultatAnalyse({
    super.key,
    this.analysis,
    this.confidenceLevel,
    this.candidates,
    this.ambiguous = false,
  });

  @override
  State<EcranResultatAnalyse> createState() => _EcranResultatAnalyseState();
}

class _EcranResultatAnalyseState extends State<EcranResultatAnalyse> {
  Map<String, dynamic>? _plantInfo;
  bool _loadingInfo = false;
  String? _infoError;

  /// Nom le plus fiable de la plante (pour afficher et interroger l'IA)
  String _plantName = 'Non identifié';

  @override
  void initState() {
    super.initState();
    _extractPlantName();
    _fetchPlantInfo();
  }

  void _extractPlantName() {
    final a = widget.analysis;
    if (a == null) return;
    // 1) champ plant_id renseigné par le backend avec scientificNameWithoutAuthor
    final pid = a['plant_id']?.toString();
    if (pid != null && pid.isNotEmpty && pid != 'null') {
      _plantName = pid;
      return;
    }
    // 2) sinon on fouille la réponse PlantNet brute
    try {
      final raw = a['result'];
      Map<String, dynamic>? parsed;
      if (raw is String && raw.isNotEmpty) {
        parsed = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        parsed = Map<String, dynamic>.from(raw);
      }
      if (parsed != null) {
        final results = parsed['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final species = (results.first as Map)['species'] as Map?;
          final sci = species?['scientificNameWithoutAuthor']?.toString();
          if (sci != null && sci.isNotEmpty) _plantName = sci;
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPlantInfo() async {
    debugPrint('[EcranResultat] _fetchPlantInfo plantName="$_plantName"');
    if (_plantName == 'Non identifié' || _plantName.isEmpty) {
      setState(() {
        _infoError =
            'La plante n\'a pas été identifiée par PlantNet. '
            'Réessaye avec une photo plus nette (feuille/fleur centrée).';
      });
      return;
    }
    setState(() {
      _loadingInfo = true;
      _infoError = null;
    });
    try {
      final info = await ApiService.instance.getPlantInfo(_plantName);
      debugPrint('[EcranResultat] getPlantInfo OK keys=${info.keys.toList()}');
      if (!mounted) return;
      setState(() {
        _plantInfo = info;
        _loadingInfo = false;
      });
      // Pousse la catégorie déduite au backend (met à jour la ligne analyses
      // avec la catégorie réelle — alimente le donut du dashboard).
      _pushCategoryToBackend(info);
    } catch (e) {
      debugPrint('[EcranResultat] getPlantInfo ERROR $e');
      if (!mounted) return;
      setState(() {
        _loadingInfo = false;
        _infoError = e.toString();
      });
    }
  }

  /// Déduit une catégorie canonique à partir des infos Groq et la pousse
  /// au backend via PATCH /analyses/{id}. Silencieux en cas d'erreur.
  Future<void> _pushCategoryToBackend(Map<String, dynamic> info) async {
    final a = widget.analysis;
    final id = a?['id'];
    if (id == null) return;
    String pick(String k) => info[k]?.toString().trim().toLowerCase() ?? '';
    final tox = pick('toxicite');
    final comest = pick('est_comestible');
    final med = pick('est_medicinale');

    String category;
    if (tox == 'élevée' || tox == 'elevee' || tox == 'eleveE') {
      category = 'toxique';
    } else if (comest == 'oui' || comest == 'partiellement') {
      category = 'comestible';
    } else if (med == 'oui') {
      category = 'medicinale';
    } else if (tox == 'moyenne') {
      category = 'toxique';
    } else {
      category = 'inconnu';
    }

    try {
      await ApiService.instance.patchJson('/analyses/$id', {
        'category': category,
      });
      debugPrint('[EcranResultat] PATCH category=$category OK');
    } catch (e) {
      debugPrint('[EcranResultat] PATCH category erreur (ignoré): $e');
    }
  }

  String _stringOr(String key, String fallback) {
    final v = _plantInfo?[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty ||
        s.toLowerCase() == 'inconnu' ||
        s.toLowerCase() == 'inconnue') {
      return fallback;
    }
    return s;
  }

  List<String> _listOr(String key) {
    final v = _plantInfo?[key];
    if (v is List) {
      return v
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    const Color background = Color(0xFFfbfbe2);
    const Color surfaceLow = Color(0xFFf5f5dc);
    const Color surfaceLowest = Color(0xFFFFFFFF);
    const Color primary = Color(0xFF0d631b);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color error = Color(0xFFba1a1a);

    // Valeurs tirées des infos IA (avec fallback)
    final commonNames = _listOr('noms_communs');
    final famille = _stringOr('famille', '');
    final santeText = _stringOr(
      'sante_plante',
      'Aucune information disponible.',
    );
    final toxicite = _stringOr('toxicite', 'inconnue');
    final toxiciteDetails = _stringOr(
      'toxicite_details',
      'Aucune donnée de sécurité disponible.',
    );
    final usagesList = _listOr('usages_traditionnels');
    final usagesText = usagesList.isEmpty
        ? _stringOr('medicinale_details', 'Aucun usage documenté.')
        : usagesList.map((u) => '• $u').join('\n');
    final estComestible = _stringOr('est_comestible', 'inconnu');
    final estMedicinale = _stringOr('est_medicinale', 'inconnu');

    // Couleur du badge toxicité selon niveau
    Color toxColor = onSurfaceVariant;
    final tLower = toxicite.toLowerCase();
    if (tLower == 'élevée' || tLower == 'elevee' || tLower == 'élevee') {
      toxColor = error;
    } else if (tLower == 'moyenne') {
      toxColor = const Color(0xFFb58900);
    } else if (tLower == 'faible') {
      toxColor = const Color(0xFF8a8a3a);
    } else if (tLower == 'aucune') {
      toxColor = primary;
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero image + overlay card
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: analysis != null && analysis['id'] != null
                              ? Image.network(
                                  '${ApiService.instance.baseUrl}/analyses/${analysis['id']}/image',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: onSurfaceVariant,
                                        ),
                                      ),
                                )
                              : analysis != null &&
                                    analysis['image_path'] != null
                              ? Image.file(
                                  File(analysis['image_path']),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: surfaceLow,
                                  child: const Center(
                                    child: Icon(
                                      Icons.eco,
                                      size: 64,
                                      color: primary,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(191),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withAlpha(51),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ConfidenceBadge(
                                    level: widget.confidenceLevel,
                                    ambiguous: widget.ambiguous,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _plantName,
                                    style: GoogleFonts.manrope(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: onSurface,
                                    ),
                                  ),
                                  if (commonNames.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      commonNames.take(3).join(', '),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (famille.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Famille : $famille',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EcranDetailComestible(
                                                    analysis: analysis,
                                                    plantInfo: _plantInfo,
                                                    plantName: _plantName,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: _Badge(
                                          text: estComestible == 'oui'
                                              ? 'COMESTIBLE'
                                              : estComestible == 'partiellement'
                                              ? 'COMESTIBLE (partiel)'
                                              : 'COMESTIBLE',
                                          bg: const Color(0xFFdae6d1),
                                          fg: const Color(0xFF3f4a3a),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EcranDetailMedicinale(
                                                    analysis: analysis,
                                                    plantInfo: _plantInfo,
                                                    plantName: _plantName,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: _Badge(
                                          text: 'MÉDICINALE',
                                          bg: const Color(0xFF477575),
                                          fg: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Autres identifications possibles (top-3) — affiché
                  // uniquement si pertinent : ambiguïté ou confiance faible/moyenne.
                  if (widget.candidates != null &&
                      widget.candidates!.length > 1 &&
                      (widget.ambiguous ||
                          widget.confidenceLevel != 'high'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CandidatesSection(
                        candidates: widget.candidates!,
                        currentName: _plantName,
                      ),
                    ),

                  // Loading / error banner
                  if (_loadingInfo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Chargement des informations botaniques…',
                            style: GoogleFonts.inter(color: onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  if (_infoError != null && !_loadingInfo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFb58900),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Infos IA indisponibles (${_infoError!})',
                              style: GoogleFonts.inter(color: onSurfaceVariant),
                            ),
                          ),
                          TextButton(
                            onPressed: _fetchPlantInfo,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),

                  // Cards grid (dynamic)
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width > 720
                            ? 340
                            : double.infinity,
                        child: _InfoCard(
                          icon: Icons.eco,
                          iconColor: primary,
                          title: 'Santé de la plante',
                          bodyTitle: 'Nom scientifique',
                          bodyValue: _plantName,
                          bodyText: santeText,
                          bg: surfaceLowest,
                        ),
                      ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width > 720
                            ? 340
                            : double.infinity,
                        child: _InfoCard(
                          icon: Icons.health_and_safety,
                          iconColor: toxColor,
                          title: 'Toxicité & Sécurité',
                          bodyTitle: 'Niveau',
                          bodyValue: toxicite.toUpperCase(),
                          bodyText: toxiciteDetails,
                          bg: surfaceLowest,
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: _InfoCard(
                          icon: Icons.history_edu,
                          iconColor: const Color(0xFF2e5c5c),
                          title: 'Usages traditionnels',
                          bodyTitle: estMedicinale == 'oui' ? 'Médicinale' : '',
                          bodyValue: estMedicinale == 'oui' ? 'OUI' : '',
                          bodyText: usagesText,
                          bg: surfaceLow,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // IA call to action
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Icon(
                                Icons.smart_toy,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Besoin de conseils d\'expert ?',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w800,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Notre Botaniste IA peut vous guider sur l\'entretien, la récolte ou les bienfaits spécifiques de cette plante.',
                                    style: GoogleFonts.inter(
                                      color: onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EcranAssistantChat(),
                                ),
                              );
                            },
                            child: Text(
                              'Poser une question à l\'IA',
                              style: GoogleFonts.manrope(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Panneau de diagnostic pliable
                  const SizedBox(height: 24),
                  _DebugPanel(
                    analysis: analysis,
                    plantName: _plantName,
                    plantInfo: _plantInfo,
                    loadingInfo: _loadingInfo,
                    infoError: _infoError,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        decoration: BoxDecoration(color: background.withAlpha(230)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranAccueil()),
                );
              },
              child: _SmallNav(icon: Icons.home, label: I18n.tr('nav.home')),
            ),
            _SmallNav(
              icon: Icons.center_focus_strong,
              label: I18n.tr('nav.analyse'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranHistorique()),
                );
              },
              child: _SmallNav(
                icon: Icons.history,
                label: I18n.tr('nav.history'),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranTableau()),
                );
              },
              child: _SmallNav(
                icon: Icons.dashboard,
                label: I18n.tr('nav.dashboard'),
                active: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String bodyTitle;
  final String bodyValue;
  final String bodyText;
  final Color bg;
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.bodyTitle,
    required this.bodyValue,
    required this.bodyText,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...((bodyTitle.isNotEmpty || bodyValue.isNotEmpty)
              ? [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bodyTitle,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF40493d),
                          ),
                        ),
                      ),
                      Text(
                        bodyValue,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ]
              : []),
          Text(
            bodyText,
            style: GoogleFonts.inter(
              color: const Color(0xFF6b6b6b),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _SmallNav({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0d631b) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : const Color(0xFF576251),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: active ? const Color(0xFF0d631b) : const Color(0xFF576251),
          ),
        ),
      ],
    );
  }
}

/// Badge dynamique reflétant le niveau de confiance de l'identification.
class _ConfidenceBadge extends StatelessWidget {
  final String? level; // high | medium | low | null
  final bool ambiguous;
  const _ConfidenceBadge({this.level, this.ambiguous = false});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;
    IconData icon;
    if (ambiguous) {
      label = 'IDENTIFICATION AMBIGUË';
      bg = const Color(0xFF477575);
      fg = Colors.white;
      icon = Icons.help_outline;
    } else {
      switch (level) {
        case 'high':
          label = 'IDENTIFIÉ • CONFIANCE ÉLEVÉE';
          bg = const Color(0xFF0d631b);
          fg = Colors.white;
          icon = Icons.verified;
          break;
        case 'medium':
          label = 'IDENTIFIÉ • CONFIANCE MOYENNE';
          bg = const Color(0xFFb58900);
          fg = Colors.white;
          icon = Icons.info_outline;
          break;
        case 'low':
          label = 'IDENTIFIÉ • CONFIANCE FAIBLE';
          bg = const Color(0xFFc94f00);
          fg = Colors.white;
          icon = Icons.warning_amber_rounded;
          break;
        default:
          label = 'IDENTIFIÉ';
          bg = const Color(0xFF0d631b);
          fg = Colors.white;
          icon = Icons.eco;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section "Autres identifications possibles" — liste les top-3 candidats
/// PlantNet pour permettre à l'utilisateur de confirmer ou corriger.
class _CandidatesSection extends StatelessWidget {
  final List<Map<String, dynamic>> candidates;
  final String currentName;
  const _CandidatesSection({
    required this.candidates,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFb58900).withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Color(0xFFb58900),
              ),
              const SizedBox(width: 8),
              Text(
                'Autres identifications possibles',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF6b4c00),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'PlantNet a hésité entre plusieurs espèces. Si tu connais ta plante, choisis la bonne.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6b4c00),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          ...candidates.map((c) {
            final name = c['scientific_name']?.toString() ?? '?';
            final score = (c['score'] as num?)?.toDouble() ?? 0.0;
            final commons = (c['common_names'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final isCurrent = name == currentName;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF0d631b).withAlpha(30)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF0d631b)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  if (isCurrent) ...[
                    const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF0d631b)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (commons.isNotEmpty)
                          Text(
                            commons.take(2).join(', '),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF40493d),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0d631b).withAlpha(40),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${(score * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0d631b),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Panneau de diagnostic — montre les données brutes reçues du backend
/// et l'état de chaque étape (PlantNet, Groq). Très utile quand rien
/// ne s'affiche pour comprendre POURQUOI.
class _DebugPanel extends StatefulWidget {
  final Map<String, dynamic>? analysis;
  final String plantName;
  final Map<String, dynamic>? plantInfo;
  final bool loadingInfo;
  final String? infoError;
  const _DebugPanel({
    required this.analysis,
    required this.plantName,
    required this.plantInfo,
    required this.loadingInfo,
    required this.infoError,
  });

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    const Color border = Color(0xFFb58900);
    final a = widget.analysis;
    final hasAnalysis = a != null;
    final plantIdRaw = a?['plant_id'];
    final hasPlantId = plantIdRaw != null && plantIdRaw.toString().isNotEmpty;
    final hasInfo = widget.plantInfo != null && widget.plantInfo!.isNotEmpty;

    String statusPlantNet;
    if (!hasAnalysis) {
      statusPlantNet = '❌ Aucune analyse reçue du backend';
    } else if (!hasPlantId) {
      statusPlantNet =
          '⚠️ Analyse reçue mais plant_id vide → PlantNet n\'a rien identifié';
    } else {
      statusPlantNet = '✅ Identifié : $plantIdRaw';
    }

    String statusGroq;
    if (!hasPlantId) {
      statusGroq = '⏭️ Non déclenché (pas de nom de plante)';
    } else if (widget.loadingInfo) {
      statusGroq = '⏳ En cours…';
    } else if (widget.infoError != null) {
      statusGroq = '❌ ${widget.infoError}';
    } else if (!hasInfo) {
      statusGroq = '⚠️ Réponse vide';
    } else {
      statusGroq = '✅ OK (${widget.plantInfo!.keys.length} champs)';
    }

    String rawJson = '';
    if (a != null) {
      try {
        final copy = Map<String, dynamic>.from(a);
        // Tronque le champ result (raw PlantNet) qui peut être énorme
        final r = copy['result']?.toString();
        if (r != null && r.length > 400) {
          copy['result'] =
              '${r.substring(0, 400)}... [${r.length} chars total]';
        }
        const encoder = JsonEncoder.withIndent('  ');
        rawJson = encoder.convert(copy);
      } catch (e) {
        rawJson = 'Erreur encodage : $e';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: border.withAlpha(80)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: border, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Diagnostic (appuie pour ${_open ? "fermer" : "ouvrir"})',
                      style: GoogleFonts.manrope(
                        color: const Color(0xFF6b4c00),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: border,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL backend : ${ApiService.instance.baseUrl}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nom extrait : ${widget.plantName}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Étape 1 — PlantNet :',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    statusPlantNet,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Étape 2 — Groq (getPlantInfo) :',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    statusGroq,
                    style: GoogleFonts.jetBrainsMono(fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Données brutes reçues du backend :',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      rawJson.isEmpty ? '(null)' : rawJson,
                      style: GoogleFonts.jetBrainsMono(fontSize: 10),
                    ),
                  ),
                  if (widget.plantInfo != null &&
                      widget.plantInfo!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Infos IA (Groq) :',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        const JsonEncoder.withIndent(
                          '  ',
                        ).convert(widget.plantInfo),
                        style: GoogleFonts.jetBrainsMono(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
