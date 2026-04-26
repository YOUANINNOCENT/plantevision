import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ecran_parametres_compte.dart';
import 'services/api_service.dart';

class EcranProfil extends StatefulWidget {
  const EcranProfil({super.key});

  @override
  State<EcranProfil> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfil> {
  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final uid = ApiService.instance.currentUserId;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }
      final j = await ApiService.instance.getJson('/users/$uid');
      setState(() {
        _user = Map<String, dynamic>.from(j);
      });
    } catch (_) {
      setState(() => _user = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color surfaceContainerLowest = Color(0xFFFFFFFF);
    const Color surfaceContainerLow = Color(0xFFf5f5dc);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color outline = Color(0xFFbfcaba);

    final avatar = _user?['avatar_url']?.toString();
    final name =
        _user?['full_name']?.toString() ??
        _user?['email']?.toString() ??
        'Utilisateur';
    final roleLabel = (_user?['is_premium'] == true) ? 'PREMIUM' : '';
    final scans = (_user?['scans_total'] ?? 0).toString();
    final rarePlants = (_user?['rare_plants'] ?? 0).toString();
    final precision = _user?['precision'] != null
        ? '${_user!['precision']}'
        : '-';

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
          'Profil',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: primary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EcranParametresCompte()),
            ),
            icon: const Icon(Icons.settings, color: Color(0xFF0d631b)),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE4E4CC),
                                width: 6,
                              ),
                            ),
                            child: ClipOval(
                              child: avatar != null && avatar.isNotEmpty
                                  ? Image.network(avatar, fit: BoxFit.cover)
                                  : const Icon(
                                      Icons.account_circle,
                                      size: 120,
                                      color: Color(0xFF8aa88a),
                                    ),
                            ),
                          ),
                          if (roleLabel.isNotEmpty)
                            Positioned(
                              right: -4,
                              bottom: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roleLabel.isNotEmpty ? 'Membre premium' : 'Utilisateur',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(
                          value: scans,
                          label: 'SCANS TOTAUX',
                          primary: primary,
                          background: surfaceContainerLowest,
                          outline: outline,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          value: rarePlants,
                          label: 'PLANTES RARES',
                          primary: primary,
                          background: surfaceContainerLowest,
                          outline: outline,
                        ),
                        const SizedBox(width: 10),
                        _StatCard(
                          value: precision,
                          label: 'PRÉCISION IA',
                          primary: primary,
                          background: surfaceContainerLowest,
                          outline: outline,
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'RÉGLAGES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: outline,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            icon: Icons.account_circle,
                            title: 'Paramètres du compte',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EcranParametresCompte(),
                              ),
                            ),
                          ),
                          const Divider(height: 0),
                          _SettingRow(
                            icon: Icons.lock,
                            title: 'Confidentialité',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Modifier le profil',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color primary;
  final Color background;
  final Color outline;

  const _StatCard({
    required this.value,
    required this.label,
    required this.primary,
    required this.background,
    required this.outline,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF576251)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF1b1d0e),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF707a6c)),
            ],
          ),
        ),
      ),
    );
  }
}
