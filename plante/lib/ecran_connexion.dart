import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_accueil.dart';
import 'ecran_inscription.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Couleurs depuis votre thème Tailwind
    const Color background = Color(0xFFfbfbe2);
    const Color surfaceContainerHigh = Color(0xFFeaead1);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color primary = Color(0xFF0d631b);
    const Color primaryContainer = Color(0xFF2e7d32);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa, color: primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Vision',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte visuelle
                Container(
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAFfdjh5X2eUYJu6pauXurmPuFl_5xLaMsArLhIc4s1DSnIzHvR6KDG8XvH55uErl9acAOvRVLBKvMrpLUsCBchg9AASBxa-kdicnXybMnXO5dfM3SMyDgC6UB_kD32kx6J3mbYyPuIg5zHgAxP_JqHpH83_ntTvCNPz5gow-VmZCniW4uSct_uoXxzfqrDZhgNaLNCxieaCskCGUD47KpZOkiO0ZiheAydxMX1nwecVA12Lj4A8D5-h4CxIZVMnursOLdcWcPrTIew',
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(26),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bienvenue',
                              style: GoogleFonts.manrope(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Le Botaniste Digital',
                              style: GoogleFonts.inter(
                                letterSpacing: 4,
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

                // Titre et sous-texte
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Connectez-vous à votre guide',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explorez le monde végétal avec précision.',
                      style: GoogleFonts.inter(
                        color: onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Formulaire
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'EMAIL',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withAlpha(230),
                          hintText: 'nom@exemple.com',
                          prefixIcon: Icon(
                            Icons.mail_outline,
                            color: onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: GoogleFonts.inter(color: onSurface),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Veuillez entrer un email'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Mot de passe
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MOT DE PASSE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Oublié ?',
                              style: GoogleFonts.inter(color: primary),
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withAlpha(230),
                          hintText: '••••••••',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: GoogleFonts.inter(color: onSurface),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Veuillez entrer un mot de passe'
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // Bouton principal avec dégradé
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [primary, primaryContainer],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const EcranAccueil(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Se connecter',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Lien secondaire
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nouveau sur Vision ? ',
                            style: GoogleFonts.inter(color: onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EcranInscription(),
                                ),
                              );
                            },
                            child: Text(
                              'Créer un compte',
                              style: GoogleFonts.inter(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Footer
                Center(
                  child: Text(
                    'Édition Botanique Digitale v1.0',
                    style: GoogleFonts.inter(
                      color: onSurfaceVariant.withAlpha(150),
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
