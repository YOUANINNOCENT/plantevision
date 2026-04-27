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

class EcranResultatAnalyse extends StatefulWidget {
  final Map<String, dynamic>? analysis;

  const EcranResultatAnalyse({super.key, this.analysis});

  @override
  State<EcranResultatAnalyse> createState() => _EcranResultatAnalyseState();
}

class _EcranResultatAnalyseState extends State<EcranResultatAnalyse> {
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

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, color: primary),
            const SizedBox(width: 12),
            Text(
              'Vision',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (analysis != null && analysis['id'] != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Supprimer'),
                    content: const Text('Supprimer cette analyse ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await ApiService.instance.delete(
                      '/analyses/${analysis['id']}',
                    );
                  } catch (_) {}
                  if (!mounted) return;
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: surfaceLowest,
                shape: BoxShape.circle,
                border: Border.all(color: primary.withAlpha(25)),
              ),
              child: ClipOval(
                child: analysis != null && analysis['id'] != null
                    ? Image.network(
                        '${ApiService.instance.baseUrl}/analyses/${analysis['id']}/image',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      )
                    : Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCnJhOSvXRDTeaItBje4VL2E-SwknHLkwIszXXNmKIW9bhgNHm-FyNcg7Mb1u1rUsLG7mN-OVOIVMQVgfyynNyE_03g3PQuxxrC8cLf16SkM-XUtSohK1FNlxn5UxNVK860SVAI7E3LOVKdgTPl5VhN5k_PSCiOi6jyWwW_Nv0nrnpdRtFz2IJx5ShTS0sHAb4lvpyKBTQcycfAzxBNCnvWrSNCs-ladWaZeIHreLJtPU9u8h0Q-sHZZVGF-x2PY7JS6S6Dazy3GOez',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ],
      ),
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
                              : Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDB7dGdE17-9V6cBRNjKIGtf7l8jsiBns-kPTrMm7YH2K-8zn3-zU2fzJW-jF8xU_496dDVz7OsIHc6kfgKgnFVpb4GVzrD__9sHxRVFz0uRWrkXGpYca2UcwBBcNkJNrSI68k3FDY86_Iyov1YteUeMAtlH9JA9sLTG8ERkkRaGtfazimiEroQZN2EEr4XhPxJrTc55aZ0Vn_OnIBHcHyE7sS77PT0cpB0tE2horBOFR4u0-gML6ARLAK-pWlDlkc4tgv7revgLGPt',
                                  fit: BoxFit.cover,
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
                                  Text(
                                    'IDENTIFIÉ',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      color: Color(0xFF0d631b),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    (analysis != null &&
                                            analysis['plant_id'] != null)
                                        ? analysis['plant_id'].toString()
                                        : 'Non identifié',
                                    style: GoogleFonts.manrope(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: onSurface,
                                    ),
                                  ),
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
                                                  ),
                                            ),
                                          );
                                        },
                                        child: _Badge(
                                          text: 'COMESTIBLE',
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
                  const SizedBox(height: 20),

                  // Metadata cards
                  if (analysis != null) ...[
                    Text(
                      'Détails',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _KeyValueCard(
                      title: 'ID',
                      value: '${analysis['id'] ?? ''}',
                    ),
                    const SizedBox(height: 8),
                    _KeyValueCard(
                      title: 'Date',
                      value: analysis['created_at'] ?? '',
                    ),
                    const SizedBox(height: 8),
                    _KeyValueCard(
                      title: 'Plante',
                      value: analysis['plant_id']?.toString() ?? '—',
                    ),
                    const SizedBox(height: 8),
                    _KeyValueCard(
                      title: 'Raw result',
                      value: (() {
                        final r = analysis['result']?.toString() ?? '';
                        if (r.isEmpty) return '—';
                        return r.length > 400 ? '${r.substring(0, 400)}...' : r;
                      })(),
                    ),
                    const SizedBox(height: 20),
                  ],

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
                          bodyTitle: 'Vitalité',
                          bodyValue: (() {
                            if (analysis != null) {
                              if (analysis['health_score'] != null) {
                                return '${analysis['health_score']}%';
                              }
                              if (analysis['health'] != null) {
                                return analysis['health'].toString();
                              }
                            }
                            return '—';
                          })(),
                          bodyText: (() {
                            if (analysis != null) {
                              if (analysis['health_summary'] != null) {
                                return analysis['health_summary'].toString();
                              }
                              final r = analysis['result']?.toString() ?? '';
                              if (r.isNotEmpty) {
                                return r.length > 200
                                    ? '${r.substring(0, 200)}...'
                                    : r;
                              }
                            }
                            return 'Aucune information disponible.';
                          })(),
                          bg: surfaceLowest,
                        ),
                      ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width > 720
                            ? 340
                            : double.infinity,
                        child: _InfoCard(
                          icon: Icons.health_and_safety,
                          iconColor: error,
                          title: 'Toxicité & Sécurité',
                          bodyTitle: '',
                          bodyValue: '',
                          bodyText: (() {
                            if (analysis != null) {
                              if (analysis['toxicity'] != null) {
                                return analysis['toxicity'].toString();
                              }
                              if (analysis['safety_notes'] != null) {
                                return analysis['safety_notes'].toString();
                              }
                              final r = analysis['result']?.toString() ?? '';
                              if (r.isNotEmpty) {
                                // simple heuristic: show short excerpt mentioning toxicity if present
                                final lower = r.toLowerCase();
                                if (lower.contains('tox') ||
                                    lower.contains('danger') ||
                                    lower.contains('attention')) {
                                  return lower.length > 300
                                      ? '${r.substring(0, 300)}...'
                                      : r;
                                }
                              }
                            }
                            return 'Aucune donnée de sécurité disponible.';
                          })(),
                          bg: surfaceLowest,
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: _InfoCard(
                          icon: Icons.history_edu,
                          iconColor: const Color(0xFF2e5c5c),
                          title: 'Usages traditionnels',
                          bodyTitle: '',
                          bodyValue: '',
                          bodyText: (() {
                            if (analysis != null) {
                              if (analysis['usages'] != null) {
                                return analysis['usages'].toString();
                              }
                              if (analysis['usages_list'] != null &&
                                  analysis['usages_list'] is List) {
                                return (analysis['usages_list'] as List).join(
                                  '\n',
                                );
                              }
                              final r = analysis['result']?.toString() ?? '';
                              if (r.isNotEmpty) {
                                return r.length > 300
                                    ? '${r.substring(0, 300)}...'
                                    : r;
                              }
                            }
                            return 'Aucun usage documenté.';
                          })(),
                          bg: surfaceLow,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // IA call to action (card with full-width pill button)
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
              child: const _SmallNav(icon: Icons.home, label: 'ACCUEIL'),
            ),
            const _SmallNav(icon: Icons.center_focus_strong, label: 'ANALYSER'),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranHistorique()),
                );
              },
              child: const _SmallNav(icon: Icons.history, label: 'HISTORIQUE'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranTableau()),
                );
              },
              child: const _SmallNav(
                icon: Icons.dashboard,
                label: 'TABLEAU',
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
                      Text(
                        bodyTitle,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF40493d),
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

class _KeyValueCard extends StatelessWidget {
  final String title;
  final String value;
  const _KeyValueCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value, style: GoogleFonts.inter())),
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
