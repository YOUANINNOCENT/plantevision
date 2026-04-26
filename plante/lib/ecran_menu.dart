import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'ecran_accueil.dart';
import 'ecran_profil.dart';
import 'ecran_tableau.dart';
import 'ecran_liste_plantes.dart';
import 'ecran_connexion.dart';

class EcranMenu extends StatefulWidget {
  const EcranMenu({super.key});

  @override
  State<EcranMenu> createState() => _EcranMenuState();
}

class _EcranMenuState extends State<EcranMenu> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Déconnecte l'utilisateur (efface user/token côté ApiService) et
  /// renvoie vers l'écran de connexion en vidant la pile de navigation
  /// pour empêcher tout retour arrière vers les écrans authentifiés.
  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Color(0xFFba1a1a)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    ApiService.instance.logout();
    if (!mounted) return;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const EcranConnexion()),
      (route) => false,
    );
  }

  Future<void> _loadData() async {
    try {
      final pj = await ApiService.instance.getJson('/plants');
      final plants = (pj['results'] as List?) ?? [];
      final cats = <String>[];
      for (final p in plants) {
        try {
          final c = (p['category'] ?? '').toString().trim();
          if (c.isNotEmpty && !cats.contains(c)) {
            cats.add(c);
          }
        } catch (_) {}
      }

      Map<String, dynamic>? user;
      try {
        final uid = ApiService.instance.currentUserId;
        if (uid != null) {
          final uj = await ApiService.instance.getJson('/users/$uid');
          user = Map<String, dynamic>.from(uj);
        }
      } catch (_) {
        user = null;
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          _user = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color surfaceLowest = Color(0xFFFFFFFF);
    const Color onSurfaceVariant = Color(0xFF40493d);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // scrim
          Positioned.fill(child: Container(color: Colors.black.withAlpha(35))),

          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // header from user
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: surfaceLowest,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(6),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child:
                                      (_user?['avatar_url'] != null &&
                                          _user!['avatar_url']
                                              .toString()
                                              .isNotEmpty)
                                      ? Image.network(
                                          _user!['avatar_url'].toString(),
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.account_circle,
                                          size: 56,
                                          color: Color(0xFF8aa88a),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _user?['full_name']?.toString() ??
                                              'Le Botaniste',
                                          style: GoogleFonts.manrope(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ((_user?['is_premium'] ?? false) ==
                                                true)
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: primary.withAlpha(25),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Premium',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: primary,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _user?['role']?.toString() ??
                                          'Expert en flore',
                                      style: GoogleFonts.inter(
                                        color: onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // static core nav
                          _NavItem(
                            icon: Icons.home,
                            label: 'ACCUEIL',
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EcranAccueil(),
                              ),
                            ),
                          ),
                          _NavItem(
                            icon: Icons.dashboard,
                            label: 'TABLEAU',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EcranTableau(),
                              ),
                            ),
                          ),
                          _NavItem(
                            icon: Icons.person,
                            label: 'PROFIL',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EcranProfil(),
                              ),
                            ),
                          ),

                          // dynamic categories
                          if (_categories.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'CATÉGORIES',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final c in _categories)
                              _NavItem(
                                icon: Icons.local_florist,
                                label: c.toUpperCase(),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EcranListePlantes(category: c),
                                  ),
                                ),
                              ),
                          ],

                          const Spacer(),
                          const Divider(color: Color(0xFFbfcaba), height: 1),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _logout(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.logout),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Déconnexion',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: Icon(icon, color: const Color(0xFF576251)),
      title: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF151e11),
        ),
      ),
      dense: true,
      horizontalTitleGap: 4,
    );
  }
}
