import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_reinitialiser_mot_de_passe.dart';
import 'services/api_service.dart';

/// Écran "Mot de passe oublié ?" — reproduit fidèlement la maquette HTML :
///   - Header beige avec flèche retour + titre "Réinitialisation" + logo VISION
///   - Icône décorative lock_reset dans un carré arrondi vert clair
///   - Titre "Mot de passe oublié ?" + sous-titre
///   - Carte beige arrondie avec champ email et bouton "Envoyer le lien"
///   - Lien "← Retour à la connexion"
///   - Footer avec 3 points et "DIGITAL BOTANIST — EDITION 2026"
///   - Décorations fern en arrière-plan (haut-gauche et bas-droite)
class EcranMotDePasseOublie extends StatefulWidget {
  const EcranMotDePasseOublie({super.key});

  @override
  State<EcranMotDePasseOublie> createState() => _EcranMotDePasseOublieState();
}

class _EcranMotDePasseOublieState extends State<EcranMotDePasseOublie> {
  final TextEditingController _emailCtrl = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _loading = false;
  bool _sent = false;

  // Palette de la maquette
  static const Color _surface = Color(0xFFfbfbe2);
  static const Color _surfaceContainerLow = Color(0xFFf5f5dc);
  static const Color _surfaceContainerHigh = Color(0xFFeaead1);
  static const Color _onSurface = Color(0xFF1b1d0e);
  static const Color _onSurfaceVariant = Color(0xFF40493d);
  static const Color _primary = Color(0xFF0d631b);
  static const Color _primaryContainer = Color(0xFF2e7d32);
  static const Color _outline = Color(0xFF707a6c);
  static const Color _outlineVariant = Color(0xFFbfcaba);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email invalide'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.postJson('/auth/forgot_password', {
        'email': email,
      });
      if (!mounted) return;
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si un compte existe avec cet email, un code de réinitialisation a été envoyé.',
          ),
          backgroundColor: _primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion — $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Décoration fern arrière-plan haut-gauche
          Positioned(
            top: 80,
            left: -64,
            child: Opacity(
              opacity: 0.10,
              child: Icon(Icons.spa, size: 256, color: _primary),
            ),
          ),
          // Décoration fern arrière-plan bas-droite
          Positioned(
            bottom: -48,
            right: -48,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.eco, size: 384, color: _primary),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ===== HEADER =====
                Container(
                  width: double.infinity,
                  color: _surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Bouton retour
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.maybePop(context),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: _primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Réinitialisation',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'VISION',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ===== CONTENU PRINCIPAL =====
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            // Icône décorative lock_reset
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Halo flou en arrière
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFdae6d1,
                                    ).withAlpha(80),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                // Carré arrondi avec icône
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: _primary.withAlpha(25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _outlineVariant.withAlpha(25),
                                    ),
                                  ),
                                  child: Icon(
                                    _sent
                                        ? Icons.mark_email_read
                                        : Icons.lock_reset,
                                    color: _primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 48),

                            // Titre principal
                            Text(
                              _sent
                                  ? 'Email envoyé !'
                                  : 'Mot de passe oublié ?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _onSurface,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Sous-titre
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 280),
                              child: Text(
                                _sent
                                    ? 'Vérifie ta boîte de réception et clique sur le lien pour définir un nouveau mot de passe.'
                                    : 'Entrez votre adresse email pour recevoir un lien de réinitialisation sécurisé.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: _onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ===== CARTE FORMULAIRE =====
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _surfaceContainerLow,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Cercle décoratif coin haut-droite
                                  Positioned(
                                    top: -32,
                                    right: -32,
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: _primary.withAlpha(13),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  // Form
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Label ADRESSE EMAIL
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          'ADRESSE EMAIL',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                            color: _onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      // Champ email avec icône mail à droite
                                      TextField(
                                        controller: _emailCtrl,
                                        focusNode: _emailFocus,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _submit(),
                                        enabled: !_sent && !_loading,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          color: _onSurface,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'nom@exemple.fr',
                                          hintStyle: GoogleFonts.inter(
                                            color: _outline,
                                          ),
                                          filled: true,
                                          fillColor: _surfaceContainerHigh,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: _primary.withAlpha(80),
                                              width: 2,
                                            ),
                                          ),
                                          suffixIcon: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            child: Icon(
                                              Icons.mail_outline,
                                              size: 18,
                                              color: _emailFocus.hasFocus
                                                  ? _primary
                                                  : _outline.withAlpha(120),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Bouton principal : "Envoyer le code" puis
                                      // "J'ai reçu mon code" après envoi.
                                      Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              _primary,
                                              _primaryContainer,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primary.withAlpha(50),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _loading
                                                ? null
                                                : (_sent
                                                      ? () => Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                EcranReinitialiserMotDePasse(
                                                                  email:
                                                                      _emailCtrl
                                                                          .text
                                                                          .trim(),
                                                                ),
                                                          ),
                                                        )
                                                      : _submit),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Center(
                                              child: _loading
                                                  ? const SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _sent
                                                              ? 'J\'ai reçu mon code'
                                                              : 'Envoyer le code',
                                                          style:
                                                              GoogleFonts.manrope(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                        if (_sent) ...[
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          const Icon(
                                                            Icons.arrow_forward,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            // Lien "← Retour à la connexion"
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.maybePop(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back,
                                        size: 16,
                                        color: _onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Retour à la connexion',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ===== FOOTER =====
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _primary.withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _primary.withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DIGITAL BOTANIST — EDITION 2026',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                          color: _onSurfaceVariant.withAlpha(150),
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
    );
  }
}
