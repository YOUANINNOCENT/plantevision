import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EcranChangerMotDePasse extends StatefulWidget {
  const EcranChangerMotDePasse({super.key});

  @override
  State<EcranChangerMotDePasse> createState() => _EcranChangerMotDePasseState();
}

class _EcranChangerMotDePasseState extends State<EcranChangerMotDePasse> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _nouveau = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNouveau = false;

  int _passwordStrength(String s) {
    var score = 0;
    if (s.length >= 8) {
      score += 1;
    }
    if (RegExp(r'[A-Z]').hasMatch(s)) {
      score += 1;
    }
    if (RegExp(r'\d').hasMatch(s)) {
      score += 1;
    }
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) {
      score += 1;
    }
    return score; // 0..4
  }

  @override
  void dispose() {
    _current.dispose();
    _nouveau.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color primaryContainer = Color(0xFF2e7d32);
    const Color surfaceHigh = Color(0xFFefefd7);
    const Color surfaceLow = Color(0xFFf5f5dc);
    const Color surfaceLowest = Color(0xFFFFFFFF);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color outlineVariant = Color(0xFFbfcaba);

    Widget field({
      required String hint,
      required TextEditingController controller,
      required bool obscure,
      required VoidCallback toggle,
      Widget? suffix,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: surfaceHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  onPressed: toggle,
                  icon: suffix ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final strength = _passwordStrength(_nouveau.text);

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
          'Changer le mot de passe',
          style: GoogleFonts.manrope(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Sécurisez votre compte',
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Maintenez l'accès à votre herbier numérique en utilisant un mot de passe robuste et unique.",
                style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Mot de passe actuel
              Text(
                'MOT DE PASSE ACTUEL',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              field(
                hint: '••••••••',
                controller: _current,
                obscure: !_showCurrent,
                toggle: () => setState(() => _showCurrent = !_showCurrent),
                suffix: Icon(
                  _showCurrent ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 18),
              // Divider concept
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: outlineVariant.withValues(alpha: 0.18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 1,
                    color: outlineVariant.withValues(alpha: 0.18),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              // Nouveau mot de passe
              Text(
                'NOUVEAU MOT DE PASSE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              field(
                hint: '••••••••',
                controller: _nouveau,
                obscure: !_showNouveau,
                toggle: () => setState(() => _showNouveau = !_showNouveau),
                suffix: Icon(
                  _showNouveau ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 12),
              // Strength
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Force du mot de passe',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        Text(
                          'Modéré',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(4, (i) {
                        final active = i < strength;
                        return Expanded(
                          child: Container(
                            height: 8,
                            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                            decoration: BoxDecoration(
                              color: active ? primary : surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              // Confirm
              Text(
                'CONFIRMER LE NOUVEAU MOT DE PASSE',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              field(
                hint: '••••••••',
                controller: _confirm,
                obscure: true,
                toggle: () {},
              ),

              const SizedBox(height: 18),
              // Security tips card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: outlineVariant.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_user, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conseils de sécurité',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Utilisez au moins 8 caractères, dont une majuscule et un chiffre pour une protection optimale.',
                            style: GoogleFonts.inter(
                              color: onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        color: Colors.transparent,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sync_lock),
            label: Text(
              'Mettre à jour le mot de passe',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 10,
            ),
          ),
        ),
      ),
    );
  }
}
