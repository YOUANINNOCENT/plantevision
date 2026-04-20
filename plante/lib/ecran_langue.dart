import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EcranLangue extends StatefulWidget {
  const EcranLangue({super.key});

  @override
  State<EcranLangue> createState() => _EcranLangueState();
}

class _EcranLangueState extends State<EcranLangue> {
  String _selection = 'fr';

  Widget _langItem(String code, String label) {
    final bool selected = _selection == code;
    const Color surfaceLowest = Color(0xFFFFFFFF);
    const Color primary = Color(0xFF0d631b);
    const Color outlineVariant = Color(0xFFbfcaba);

    return InkWell(
      onTap: () => setState(() => _selection = code),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? surfaceLowest : surfaceLowest.withAlpha(220),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: selected ? Colors.black : const Color(0xFF40493d),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: outlineVariant),
                color: selected ? primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color surfaceContainerLow = Color(0xFFf5f5dc);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0d631b)),
        ),
        title: Text(
          'Langue',
          style: GoogleFonts.manrope(
            color: const Color(0xFF0d631b),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Langue',
                style: GoogleFonts.manrope(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1b1d0e),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez votre langue préférée',
                style: GoogleFonts.inter(color: const Color(0xFF40493d)),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _langItem('fr', 'Français'),
                            const SizedBox(height: 8),
                            _langItem('en', 'Anglais'),
                            const SizedBox(height: 8),
                            _langItem('es', 'Espagnol'),
                            const SizedBox(height: 8),
                            _langItem('de', 'Allemand'),
                            const SizedBox(height: 8),
                            _langItem('it', 'Italien'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Decorative leaf (smaller to avoid overlap)
                      Center(
                        child: Opacity(
                          opacity: 0.06,
                          child: Icon(
                            Icons.eco,
                            size: 100,
                            color: const Color(0xFF0d631b),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: ElevatedButton(
          onPressed: () {
            Navigator.maybePop(context, _selection);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF0d631b),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            'Enregistrer',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
