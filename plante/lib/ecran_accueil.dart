import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_scanner.dart';
import 'ecran_resultat_analyse.dart';
import 'ecran_historique.dart';
import 'services/i18n.dart';
import 'ecran_tableau.dart';
import 'ecran_tout.dart';
import 'ecran_menu.dart';
import 'services/api_service.dart';
import 'ecran_liste_plantes.dart';

class EcranAccueil extends StatefulWidget {
  const EcranAccueil({super.key});

  @override
  State<EcranAccueil> createState() => _EcranAccueilState();
}

class _EcranAccueilState extends State<EcranAccueil> {
  List<dynamic> _analyses = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentAnalyses();
  }

  Future<void> _fetchRecentAnalyses() async {
    try {
      if (ApiService.instance.baseUrl == 'https://api.example.com') {
        ApiService.instance.baseUrl = 'http://127.0.0.1:8000';
      }
      final uid = ApiService.instance.currentUserId;
      if (uid == null) {
        if (mounted) setState(() => _analyses = []);
        return;
      }
      final resp = await ApiService.instance.getJson('/analyses/$uid');
      setState(() {
        _analyses = resp['results'] ?? [];
      });
    } catch (e) {
      setState(() {
        _analyses = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color primaryContainer = Color(0xFF2e7d32);
    const Color surfaceContainerLowest = Color(0xFFFFFFFF);
    const Color onSurfaceVariant = Color(0xFF40493d);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const EcranMenu()));
              },
              child: Icon(Icons.menu, color: primary),
            ),
            const Spacer(),
            CircleAvatar(
              radius: 18,
              backgroundImage: _analyses.isNotEmpty
                  ? NetworkImage(
                      '${ApiService.instance.baseUrl}/analyses/${_analyses[0]['id']}/image',
                    )
                  : null,
              child: _analyses.isEmpty ? const Icon(Icons.person) : null,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchRecentAnalyses,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            children: [
              const SizedBox(height: 20),

              // CTA button
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EcranScanner()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: primary,
                    shadowColor: primaryContainer.withAlpha(40),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_camera,
                        size: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Scanner une plante',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Categories quick access
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const EcranListePlantes(category: 'COMESTIBLE'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdae6d1),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Comestible',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const EcranListePlantes(category: 'MÉDICINALE'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF477575),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Médicinale',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Scans récents header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scans récents',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EcranTout()),
                      );
                    },
                    child: Text(
                      'Voir tout',
                      style: GoogleFonts.inter(color: onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dynamic Grid of analyses
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _analyses.isNotEmpty ? _analyses.length : 4,
                itemBuilder: (ctx, i) {
                  if (_analyses.isEmpty || i >= _analyses.length) {
                    // placeholder
                    return Container(
                      decoration: BoxDecoration(
                        color: surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    );
                  }

                  final a = _analyses[i] as Map<String, dynamic>;
                  final id = a['id'];
                  final title = (a['plant_id'] != null)
                      ? a['plant_id'].toString()
                      : 'Inconnu';
                  final date = a['created_at'] ?? '';
                  final imageUrl =
                      '${ApiService.instance.baseUrl}/analyses/$id/image';

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EcranResultatAnalyse(analysis: a),
                        ),
                      );
                      // refresh after returning
                      await _fetchRecentAnalyses();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (c, e, s) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation - simplified
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        decoration: BoxDecoration(color: background.withAlpha(230)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home, label: I18n.tr('nav.home'), active: true),
            _NavItem(
              icon: Icons.center_focus_strong,
              label: I18n.tr('nav.analyse'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EcranResultatAnalyse(),
                  ),
                );
              },
            ),
            _NavItem(
              icon: Icons.history,
              label: I18n.tr('nav.history'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EcranHistorique()),
                );
              },
            ),
            _NavItem(
              icon: Icons.dashboard,
              label: I18n.tr('nav.dashboard'),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const EcranTableau()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Column(
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
      ),
    );
  }
}
