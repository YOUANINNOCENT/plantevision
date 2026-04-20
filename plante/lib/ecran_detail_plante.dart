import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

class EcranDetailPlante extends StatefulWidget {
  final int plantId;
  const EcranDetailPlante({super.key, required this.plantId});

  @override
  State<EcranDetailPlante> createState() => _EcranDetailPlanteState();
}

class _EcranDetailPlanteState extends State<EcranDetailPlante> {
  Map<String, dynamic>? _plant;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final j = await ApiService.instance.getJson('/plants/${widget.plantId}');
      setState(() {
        _plant = Map<String, dynamic>.from(j);
      });
    } catch (_) {
      setState(() {
        _plant = null;
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
        iconTheme: const IconThemeData(color: primary),
        title: Text('Fiche plante', style: GoogleFonts.manrope(color: primary)),
      ),
      backgroundColor: bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_plant == null)
            ? Center(
                child: Text('Plante introuvable', style: GoogleFonts.inter()),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plant!['scientific_name']?.toString() ??
                          'Nom scientifique inconnu',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _plant!['common_name']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if ((_plant!['category'] ?? '').toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFdae6d1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (_plant!['category'] ?? '').toString(),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _plant!['description']?.toString() ??
                          'Aucune description disponible',
                      style: GoogleFonts.inter(height: 1.4),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
