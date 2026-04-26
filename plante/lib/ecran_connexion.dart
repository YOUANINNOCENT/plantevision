import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_accueil.dart';
import 'ecran_inscription.dart';
import 'ecran_mot_de_passe_oublie.dart';
import 'services/api_service.dart';
import 'services/i18n.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Reset les erreurs spécifiques champ
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final user = await ApiService.instance.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bienvenue ${user['email'] ?? ''}')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EcranAccueil()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // 404 = email inconnu, 401 = mauvais mot de passe
      if (e.statusCode == 404) {
        setState(() => _emailError = 'Email incorrect');
      } else if (e.statusCode == 401) {
        setState(() => _passwordError = 'Mot de passe incorrect');
      } else if (e.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ${e.statusCode} — ${e.message}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      // Re-valide le formulaire pour afficher _emailError / _passwordError
      _formKey.currentState?.validate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de joindre le serveur — $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                // Carte visuelle (image jungle locale)
                Container(
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/images/connexion_jungle.jpg'),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Voile sombre dégradé : assombrit l'image pour que le
                      // texte blanc reste lisible quel que soit le contenu de
                      // la photo de fond.
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withAlpha(80),
                              Colors.black.withAlpha(150),
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
                              I18n.tr('login.welcome'),
                              style: GoogleFonts.manrope(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(180),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              I18n.tr('login.brandSubtitle'),
                              style: GoogleFonts.inter(
                                letterSpacing: 4,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(230),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(160),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
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

                // Titre et sous-texte
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      I18n.tr('login.title'),
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      I18n.tr('login.subtitle'),
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
                          I18n.tr('login.email'),
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
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Veuillez entrer un email';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Email invalide';
                          }
                          return _emailError;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Mot de passe
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            I18n.tr('login.password'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EcranMotDePasseOublie(),
                                ),
                              );
                            },
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
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Veuillez entrer un mot de passe';
                          }
                          return _passwordError;
                        },
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
                          onTap: _loading ? null : _submit,
                          borderRadius: BorderRadius.circular(16),
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
                                        I18n.tr('login.submit'),
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
                            I18n.tr('login.newUser'),
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
                              I18n.tr('login.createAccount'),
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
