import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'ecran_resultat_analyse.dart';

class EcranTout extends StatefulWidget {
  const EcranTout({super.key});

  @override
  State<EcranTout> createState() => _EcranToutState();
}

class _EcranToutState extends State<EcranTout> {
  List<dynamic> _analyses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      if (ApiService.instance.baseUrl == 'https://api.example.com') {
        ApiService.instance.baseUrl = 'http://127.0.0.1:8000';
      }
      final resp = await ApiService.instance.getJson('/analyses/1');
      setState(() {
        _analyses = resp['results'] ?? [];
      });
    } catch (e) {
      setState(() {
        _analyses = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: Text(
          'Tous les scans',
          style: GoogleFonts.manrope(
            color: onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0d631b)),
      ),
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAll,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: _analyses.length,
                    itemBuilder: (context, i) {
                      final a = _analyses[i] as Map<String, dynamic>;
                      final id = a['id'];
                      final title = a['plant_id'] != null
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
                          await _fetchAll();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                      'DÉTAIL',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
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
          ),
        ),
      ),
    );
  }
}
