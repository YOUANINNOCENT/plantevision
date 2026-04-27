import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_accueil.dart';
import 'ecran_resultat_analyse.dart';
import 'ecran_historique.dart';
import 'services/api_service.dart';

class EcranTableau extends StatefulWidget {
  const EcranTableau({super.key});

  @override
  State<EcranTableau> createState() => _EcranTableauState();
}

class _EcranTableauState extends State<EcranTableau> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _donut = {};
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final j = await ApiService.instance.getJson('/dashboard');
      setState(() {
        _stats = Map<String, dynamic>.from(j['stats'] ?? {});
        _donut = Map<String, dynamic>.from(j['donut'] ?? {});
        _alerts = (j['alerts'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      // fallback to defaults if endpoint missing
      setState(() {
        _stats = {
          'total_scans': '—',
          'percent_toxic': '—',
          'species_count': '—',
        };
        _donut = {
          'comestible': '—',
          'medicinal': '—',
          'toxic': '—',
          'dominant': '—',
        };
        _alerts = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color primaryContainer = Color(0xFF2e7d32);
    const Color surfaceLow = Color(0xFFf5f5dc);
    const Color surfaceLowest = Color(0xFFFFFFFF);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color error = Color(0xFFba1a1a);

    final totalScans = _stats['total_scans']?.toString() ?? '—';
    final percentToxic = _stats['percent_toxic']?.toString() ?? '—';
    final speciesCount = _stats['species_count']?.toString() ?? '—';
    final dominant = _donut['dominant']?.toString() ?? '—';

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
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'TABLEAU DE BORD',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Analyse des Données',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 18),

                    GridView.count(
                      crossAxisCount: 1,
                      childAspectRatio: 4.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      children: [
                        _StatCard(
                          title: 'Total Scans',
                          value: totalScans,
                          icon: Icons.eco,
                          bg: surfaceLow,
                          iconBg: primaryContainer.withAlpha(40),
                          iconColor: primary,
                        ),
                        _StatCard(
                          title: '% Toxiques',
                          value: percentToxic,
                          icon: Icons.warning,
                          bg: surfaceLow,
                          iconBg: error.withAlpha(30),
                          iconColor: error,
                        ),
                        _StatCard(
                          title: 'Espèces',
                          value: speciesCount,
                          icon: Icons.biotech,
                          bg: surfaceLow,
                          iconBg: primaryContainer.withAlpha(30),
                          iconColor: const Color(0xFF2e5c5c),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 700;
                        final donutSize = narrow ? 140.0 : 160.0;

                        final donutCard = Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceLowest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Répartition Florale',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: donutSize,
                                height: donutSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const SweepGradient(
                                    colors: [
                                      Color(0xFF0d631b),
                                      Color(0xFFdae6d1),
                                      Color(0xFFba1a1a),
                                    ],
                                    stops: [0.0, 0.65, 0.85],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: donutSize * 0.62,
                                    height: donutSize * 0.62,
                                    decoration: BoxDecoration(
                                      color: surfaceLowest,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Dominant',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            dominant,
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.spaceAround,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  _LegendDot(
                                    color: const Color(0xFF0d631b),
                                    label: 'Comestibles',
                                    value:
                                        _donut['comestible']?.toString() ?? '—',
                                  ),
                                  _LegendDot(
                                    color: const Color(0xFFdae6d1),
                                    label: 'Médicinales',
                                    value:
                                        _donut['medicinal']?.toString() ?? '—',
                                  ),
                                  _LegendDot(
                                    color: const Color(0xFFba1a1a),
                                    label: 'Toxiques',
                                    value: _donut['toxic']?.toString() ?? '—',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        final mapCard = Container(
                          decoration: BoxDecoration(
                            color: surfaceLowest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Localisation des Scans',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Concentration géographique des dernières analyses',
                                style: GoogleFonts.inter(
                                  color: onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: surfaceLow,
                                ),
                                child: const Center(
                                  child: Text('Carte / Image'),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (narrow) {
                          return Column(
                            children: [
                              donutCard,
                              const SizedBox(height: 12),
                              mapCard,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: donutCard),
                            const SizedBox(width: 12),
                            Expanded(flex: 7, child: mapCard),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Alertes Actives',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: _alerts.isNotEmpty
                          ? _alerts
                                .map(
                                  (a) => _AlerteCard(
                                    title: a['title']?.toString() ?? 'Alerte',
                                    subtitle: a['subtitle']?.toString() ?? '',
                                    actionLabel:
                                        a['actionLabel']?.toString() ?? 'Voir',
                                    color: a['color'] != null
                                        ? Color(
                                            int.tryParse(
                                                  a['color'].toString(),
                                                ) ??
                                                0xFFba1a1a,
                                          )
                                        : error,
                                    time: a['time']?.toString() ?? '',
                                  ),
                                )
                                .toList()
                          : [const SizedBox.shrink()],
                    ),
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
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EcranAccueil()),
              ),
              child: const _SmallNav(icon: Icons.home, label: 'Accueil'),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EcranResultatAnalyse()),
              ),
              child: const _SmallNav(
                icon: Icons.center_focus_strong,
                label: 'Analyser',
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EcranHistorique()),
              ),
              child: const _SmallNav(icon: Icons.history, label: 'Historique'),
            ),
            const _SmallNav(
              icon: Icons.dashboard,
              label: 'Tableau',
              active: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bg;
  final Color iconBg;
  final Color iconColor;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bg,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF576251),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF576251),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AlerteCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color color;
  final String time;
  const _AlerteCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.color,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(width: 4, color: color.withAlpha(200))),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning, color: color),
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
                      title,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(color: const Color(0xFF666666)),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      actionLabel.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 11, color: color),
                    ),
                  ),
                ),
              ],
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
