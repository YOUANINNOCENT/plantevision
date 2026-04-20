import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'ecran_detail_plante.dart';

class EcranListePlantes extends StatefulWidget {
  final String category; // e.g. 'COMESTIBLE' or 'MÉDICINALE'
  const EcranListePlantes({super.key, required this.category});

  @override
  State<EcranListePlantes> createState() => _EcranListePlantesState();
}

class _EcranListePlantesState extends State<EcranListePlantes> {
  List<Map<String, dynamic>> _plants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    try {
      final j = await ApiService.instance.getJson(
        '/plants?category=${Uri.encodeComponent(widget.category)}',
      );
      final results = (j['results'] as List?) ?? [];
      setState(() {
        _plants = results.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (_) {
      setState(() {
        _plants = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFfbfbe2);
    const primary = Color(0xFF0d631b);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0d631b)),
        title: Text(
          '${widget.category} - Plantes',
          style: GoogleFonts.manrope(color: primary),
        ),
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _plants.isEmpty
            ? Center(
                child: Text(
                  'Aucune plante trouvée',
                  style: GoogleFonts.inter(),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _plants.length,
                itemBuilder: (ctx, i) {
                  final p = _plants[i];
                  final title =
                      (p['scientific_name'] ?? p['common_name'] ?? 'Inconnu')
                          .toString();
                  final subtitle = (p['common_name'] ?? '').toString();
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        final pid = p['id'];
                        if (pid != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EcranDetailPlante(plantId: pid as int),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFf5f5f5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.eco,
                                    size: 48,
                                    color: Color(0xFF8aa88a),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
