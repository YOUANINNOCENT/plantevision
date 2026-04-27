import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_connexion.dart';

class EcranSplash extends StatefulWidget {
  const EcranSplash({super.key});

  @override
  State<EcranSplash> createState() => _EcranSplashState();
}

class _EcranSplashState extends State<EcranSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() => setState(() {}))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const EcranConnexion()),
              );
            }
          });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs (d'après votre configuration Tailwind)
    const Color background = Color(0xFFfbfbe2);
    const Color primaryContainer = Color(0xFF2e7d32);
    const Color outlineVariant = Color(0xFFbfcaba);
    const Color tertiaryContainer = Color(0xFF477575);

    final width = MediaQuery.of(context).size.width;
    // équivalent de 15vw pour le titre
    final double titreFontSize = width * 0.15;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Éléments décoratifs floutés (ronds botaniques)
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                color: primaryContainer.withAlpha(15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryContainer.withAlpha(15),
                    blurRadius: 120,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                color: tertiaryContainer.withAlpha(15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: tertiaryContainer.withAlpha(15),
                    blurRadius: 100,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),

          // Contenu centré
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre "VISION"
                  Text(
                    'VISION',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: titreFontSize,
                      letterSpacing: 8,
                      color: primaryContainer,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Barre de progression animée (10s)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: outlineVariant.withAlpha(77),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _controller.value.clamp(0.0, 1.0),
                          child: Container(color: primaryContainer),
                        ),
                      ),
                    ),
                  ),

                  // Texte caché pour lecteurs d'écran
                  Semantics(
                    label: 'Chargement de l\'application Vision',
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
