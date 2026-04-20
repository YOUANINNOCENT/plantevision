import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_accueil.dart';
import 'ecran_tableau.dart';
import 'ecran_resultat_analyse.dart';
import 'services/api_service.dart';

class EcranHistorique extends StatefulWidget {
  const EcranHistorique({super.key});

  @override
  State<EcranHistorique> createState() => _EcranHistoriqueState();
}

class _EcranHistoriqueState extends State<EcranHistorique> {
  bool _loading = true;
  List<dynamic> _analyses = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalyses();
  }

  Future<void> _fetchAnalyses() async {
    setState(() => _loading = true);
    try {
      if (ApiService.instance.baseUrl == 'https://api.example.com') {
        ApiService.instance.baseUrl = 'http://127.0.0.1:8000';
      }
      final resp = await ApiService.instance.getJson('/analyses/1');
      setState(() {
        _analyses = resp['results'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _analyses = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color surfaceLow = Color(0xFFf5f5dc);
    const Color primary = Color(0xFF0d631b);
    const Color outline = Color(0xFF707a6c);

    // dynamic analyses loaded from backend

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          children: [
            const Icon(Icons.menu, color: Color(0xFF0d631b)),
            const SizedBox(width: 12),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Historique',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1b1d0e),
                ),
              ),
              const SizedBox(height: 12),

              // Search
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: surfaceLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, color: outline),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Rechercher une analyse...',
                          hintStyle: GoogleFonts.inter(color: outline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Items (dynamic)
              RefreshIndicator(
                onRefresh: _fetchAnalyses,
                child: _loading
                    ? SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _analyses.isEmpty
                    ? Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: Text(
                          'Aucun historique',
                          style: GoogleFonts.inter(color: outline),
                        ),
                      )
                    : Column(
                        children: _analyses.map((a) {
                          final id = a['id'];
                          final imageUrl =
                              '${ApiService.instance.baseUrl}/analyses/$id/image';
                          final category =
                              (a['category'] as String?) ?? 'NON DÉFINI';
                          final date = (a['created_at'] as String?) ?? '';
                          final title =
                              (a['plant_id']?.toString() ??
                              a['title']?.toString() ??
                              'Analyse #$id');
                          final categoryColor = category == 'COMESTIBLE'
                              ? const Color(0xFFdae6d1)
                              : category == 'TOXIQUE'
                              ? const Color(0xFFffdad6)
                              : category == 'MÉDICINAL'
                              ? const Color(0xFF477575)
                              : const Color(0xFF576251);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _HistoryItem(
                              imageUrl: imageUrl,
                              category: category,
                              categoryColor: categoryColor,
                              date: date,
                              title: title,
                              statusIcon: Icons.history,
                              statusColor: primary,
                              statusText: a['status']?.toString() ?? 'Terminé',
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EcranResultatAnalyse(analysis: a),
                                  ),
                                );
                                // Refresh list after returning (handles deletion)
                                await _fetchAnalyses();
                              },
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 140),
            ],
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
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EcranResultatAnalyse(),
                  ),
                );
              },
              child: _SmallNav(
                icon: Icons.center_focus_strong,
                label: 'ANALYSER',
              ),
            ),
            // active center
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: Colors.white),
                  const SizedBox(height: 2),
                  Text(
                    'HISTORIQUE',
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranTableau()),
                );
              },
              child: _SmallNav(icon: Icons.dashboard, label: 'TABLEAU'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String imageUrl;
  final String category;
  final Color categoryColor;
  final String date;
  final String title;
  final IconData statusIcon;
  final Color statusColor;
  final String statusText;
  final VoidCallback? onTap;

  const _HistoryItem({
    required this.imageUrl,
    required this.category,
    required this.categoryColor,
    required this.date,
    required this.title,
    required this.statusIcon,
    required this.statusColor,
    required this.statusText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: categoryColor,
                        ),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF707a6c),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF40493d),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF707a6c)),
          ],
        ),
      ),
    );
  }
}

class _SmallNav extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SmallNav({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF576251)),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF576251),
          ),
        ),
      ],
    );
  }
}
