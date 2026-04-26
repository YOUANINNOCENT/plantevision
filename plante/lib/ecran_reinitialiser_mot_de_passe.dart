import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_connexion.dart';
import 'services/api_service.dart';

/// Écran "Réinitialiser le mot de passe" — reproduction fidèle de la maquette
/// HTML. Permet à l'utilisateur de définir un nouveau mot de passe après avoir
/// reçu un lien de réinitialisation (oublié).
///
/// Flux : [EcranMotDePasseOublie] → [EcranReinitialiserMotDePasse] → [EcranConnexion].
///
/// Composants :
///   - Header VISION en haut à gauche
///   - Titre "Réinitialiser le mot de passe" + sous-titre
///   - Champ "NOUVEAU MOT DE PASSE" avec icône œil pour afficher/cacher
///   - Carte "Force du mot de passe" : badge SÉCURISÉ, 4 barres, 4 critères
///     (8+ caractères, Majuscule, Symbole spécial, Un chiffre)
///   - Champ "CONFIRMER LE MOT DE PASSE" avec icône œil
///   - Bouton dégradé "Réinitialiser le mot de passe →"
///   - Lien "Retour à la connexion"
///   - Footer THE DIGITAL BOTANIST
class EcranReinitialiserMotDePasse extends StatefulWidget {
  /// Email du compte dont on réinitialise le mot de passe (passé depuis
  /// l'écran "Mot de passe oublié").
  final String email;

  const EcranReinitialiserMotDePasse({super.key, required this.email});

  @override
  State<EcranReinitialiserMotDePasse> createState() =>
      _EcranReinitialiserMotDePasseState();
}

class _EcranReinitialiserMotDePasseState
    extends State<EcranReinitialiserMotDePasse> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _loading = false;

  // Palette de la maquette
  static const Color _surface = Color(0xFFfbfbe2);
  static const Color _surfaceContainerLow = Color(0xFFf5f5dc);
  static const Color _surfaceContainerHigh = Color(0xFFeaead1);
  static const Color _onSurface = Color(0xFF1b1d0e);
  static const Color _onSurfaceVariant = Color(0xFF40493d);
  static const Color _secondary = Color(0xFF576251);
  static const Color _primary = Color(0xFF0d631b);
  static const Color _primaryContainer = Color(0xFF2e7d32);
  static const Color _outline = Color(0xFF707a6c);
  static const Color _outlineVariant = Color(0xFFbfcaba);

  @override
  void initState() {
    super.initState();
    // Re-render à chaque frappe pour mettre à jour la jauge de force
    _newCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _codeFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ---- Critères de force ----
  bool get _hasMinLength => _newCtrl.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_newCtrl.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_newCtrl.text);
  bool get _hasSpecial =>
      RegExp(r"""[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/;`~']""").hasMatch(_newCtrl.text);

  /// Score 0–4 selon le nombre de critères validés.
  int get _strengthScore {
    var n = 0;
    if (_hasMinLength) n++;
    if (_hasUppercase) n++;
    if (_hasDigit) n++;
    if (_hasSpecial) n++;
    return n;
  }

  /// Libellé du badge de force ("Faible", "Moyen", "Solide", "Sécurisé").
  String get _strengthLabel {
    switch (_strengthScore) {
      case 0:
      case 1:
        return 'FAIBLE';
      case 2:
        return 'MOYEN';
      case 3:
        return 'SOLIDE';
      case 4:
      default:
        return 'SÉCURISÉ';
    }
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 0:
      case 1:
        return const Color(0xFFba1a1a);
      case 2:
        return const Color(0xFFb58900);
      case 3:
        return const Color(0xFF2e7d32);
      case 4:
      default:
        return _primary;
    }
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    final pwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (code.length != 6 || int.tryParse(code) == null) {
      _snack('Saisis le code à 6 chiffres reçu par email', error: true);
      return;
    }
    if (pwd.length < 6) {
      _snack('Le mot de passe doit contenir au moins 6 caractères',
          error: true);
      return;
    }
    if (pwd != confirm) {
      _snack('Les deux mots de passe ne correspondent pas', error: true);
      return;
    }
    if (_strengthScore < 3) {
      _snack(
        'Mot de passe trop faible. Combine au moins 3 critères (longueur, majuscule, chiffre, symbole).',
        error: true,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.resetPassword(
        email: widget.email,
        code: code,
        newPassword: pwd,
      );
      if (!mounted) return;
      _snack('Mot de passe réinitialisé. Connecte-toi.');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EcranConnexion()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 400) {
        _snack(e.message, error: true);
      } else {
        _snack('Erreur ${e.statusCode} — ${e.message}', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Erreur de connexion — $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : _primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Décoration botanique de fond (bas-droite)
          Positioned(
            bottom: -64,
            right: -64,
            child: Opacity(
              opacity: 0.04,
              child: Transform.rotate(
                angle: -0.26,
                child: const Icon(Icons.eco, size: 320, color: _primary),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ===== Header VISION =====
                Container(
                  height: 56,
                  width: double.infinity,
                  color: _surface,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VISION',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: _primary,
                    ),
                  ),
                ),

                // ===== Contenu principal =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          // Titre
                          Text(
                            'Réinitialiser le mot de passe',
                            style: GoogleFonts.manrope(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: _onSurface,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Saisis le code reçu par email puis ton nouveau mot de passe.',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: _onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email rappel (lecture seule)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.mail_outline,
                                    size: 16, color: _primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.email,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: _primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ===== CODE DE VÉRIFICATION =====
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'CODE DE VÉRIFICATION (6 CHIFFRES)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: _secondary,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _codeCtrl,
                              focusNode: _codeFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _onSurface,
                                letterSpacing: 8,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••',
                                hintStyle: GoogleFonts.manrope(
                                  fontSize: 22,
                                  color: _outlineVariant,
                                  letterSpacing: 8,
                                ),
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _primary.withAlpha(80),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ===== NOUVEAU MOT DE PASSE =====
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'NOUVEAU MOT DE PASSE',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: _secondary,
                              ),
                            ),
                          ),
                          _buildPasswordField(
                            controller: _newCtrl,
                            focusNode: _newFocus,
                            obscure: !_showNew,
                            onToggle: () => setState(() => _showNew = !_showNew),
                          ),

                          const SizedBox(height: 16),

                          // ===== Carte FORCE DU MOT DE PASSE =====
                          _buildStrengthCard(),

                          const SizedBox(height: 24),

                          // ===== CONFIRMER LE MOT DE PASSE =====
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'CONFIRMER LE MOT DE PASSE',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                                color: _secondary,
                              ),
                            ),
                          ),
                          _buildPasswordField(
                            controller: _confirmCtrl,
                            focusNode: _confirmFocus,
                            obscure: !_showConfirm,
                            onToggle: () =>
                                setState(() => _showConfirm = !_showConfirm),
                          ),

                          const SizedBox(height: 24),

                          // ===== Bouton principal =====
                          _buildPrimaryButton(),

                          const SizedBox(height: 24),

                          // ===== Lien retour =====
                          Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context)
                                    .pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const EcranConnexion(),
                                  ),
                                  (route) => false,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _secondary.withAlpha(50),
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'Retour à la connexion',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // ===== Footer THE DIGITAL BOTANIST =====
                          Center(
                            child: Opacity(
                              opacity: 0.20,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.eco,
                                      size: 28, color: _onSurface),
                                  const SizedBox(width: 8),
                                  Container(
                                    height: 1,
                                    width: 32,
                                    color: _onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'THE DIGITAL BOTANIST',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                      color: _onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
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

  // ---- Helpers UI ----

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: _onSurface,
              letterSpacing: obscure ? 4 : 0,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.inter(
                color: _outlineVariant,
                letterSpacing: 4,
              ),
              filled: false,
              isDense: false,
              contentPadding: const EdgeInsets.fromLTRB(16, 18, 56, 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _primary.withAlpha(80),
                  width: 2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
                color: _outline,
                size: 22,
              ),
              splashRadius: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthCard() {
    final score = _strengthScore;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FORCE DU MOT DE PASSE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _secondary,
                ),
              ),
              Text(
                _strengthLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 4 barres
          Row(
            children: List.generate(4, (i) {
              final filled = i < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: filled
                        ? _strengthColor
                        : _outlineVariant.withAlpha(80),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          // Grille 2x2 des critères
          Row(
            children: [
              Expanded(child: _criteriaRow(_hasMinLength, '8+ caractères')),
              Expanded(child: _criteriaRow(_hasUppercase, 'Majuscule')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _criteriaRow(_hasSpecial, 'Symbole spécial')),
              Expanded(child: _criteriaRow(_hasDigit, 'Un chiffre')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criteriaRow(bool ok, String label) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: ok ? _primary : _outlineVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ok ? _onSurfaceVariant : _outlineVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryContainer],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primary.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Réinitialiser le mot de passe',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
