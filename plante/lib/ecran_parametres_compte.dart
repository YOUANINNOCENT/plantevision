import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async' show TimeoutException;
import 'services/api_service.dart';
import 'ecran_changer_mot_de_passe.dart';

class EcranParametresCompte extends StatefulWidget {
  const EcranParametresCompte({super.key});

  @override
  State<EcranParametresCompte> createState() => _EcranParametresCompteState();
}

class _EcranParametresCompteState extends State<EcranParametresCompte> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final j = await ApiService.instance.getJson('/users/1');
      setState(() {
        _user = Map<String, dynamic>.from(j);
        _nameCtrl.text = _user?['full_name']?.toString() ?? '';
        _emailCtrl.text = _user?['email']?.toString() ?? '';
        _phoneCtrl.text = _user?['phone']?.toString() ?? '';
      });
    } catch (e) {
      // ignore - show defaults
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final payload = {
      'full_name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };
    try {
      setState(() => _loading = true);
      await ApiService.instance
          .putJson('/users/1', payload)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
      await _loadUser();
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Délai d\'attente dépassé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur sauvegarde: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    try {
      setState(() => _loading = true);
      await ApiService.instance.delete('/users/1');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compte supprimé')));
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primary = Color(0xFF0d631b);
    const Color surfaceHigh = Color(0xFFefefd7);
    const Color surfaceLow = Color(0xFFf5f5dc);
    const Color surfaceLowest = Color(0xFFFFFFFF);
    const Color onSurface = Color(0xFF1b1d0e);
    const Color onSurfaceVariant = Color(0xFF40493d);
    const Color outlineVariant = Color(0xFF707a6c);

    InputDecoration inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );

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
          'Paramètres du compte',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations personnelles
                    Text(
                      'INFORMATIONS PERSONNELLES',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gérez les détails de votre profil Digital Botanist.',
                      style: GoogleFonts.inter(color: onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Avatar
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: surfaceLowest,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
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
                            Positioned(
                              right: -6,
                              bottom: -6,
                              child: Material(
                                color: primary,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user?['full_name']?.toString() ?? 'Utilisateur',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _user?['member_since']?.toString() ?? 'Membre',
                              style: GoogleFonts.inter(color: onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    // Inputs
                    Text(
                      'Nom complet',
                      style: GoogleFonts.inter(
                        color: onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: inputDecoration('Votre nom'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email professionnel',
                      style: GoogleFonts.inter(
                        color: onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: inputDecoration('Votre email'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Numéro de téléphone',
                      style: GoogleFonts.inter(
                        color: onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: inputDecoration('Votre numéro'),
                    ),

                    const SizedBox(height: 20),
                    // Sécurité
                    Text(
                      'SÉCURITÉ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: surfaceLowest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Color(0xFF0d631b),
                              ),
                            ),
                            title: Text(
                              'Changer le mot de passe',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              _user?['password_changed_at']?.toString() ??
                                  'Dernière modification inconnue',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: onSurfaceVariant,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: outlineVariant,
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const EcranChangerMotDePasse(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    // Compte
                    Text(
                      'COMPTE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surfaceLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color.fromRGBO(
                            ((outlineVariant.r * 255.0).round())
                                .clamp(0, 255)
                                .toInt(),
                            ((outlineVariant.g * 255.0).round())
                                .clamp(0, 255)
                                .toInt(),
                            ((outlineVariant.b * 255.0).round())
                                .clamp(0, 255)
                                .toInt(),
                            0.1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFe4f4df),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_florist,
                                    color: Color(0xFF0d631b),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _user?['subscription_name']
                                                ?.toString() ??
                                            'Vision',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _user?['subscription_next']
                                                ?.toString() ??
                                            'Aucun abonnement',
                                        style: GoogleFonts.inter(
                                          color: onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Gérer',
                              style: GoogleFonts.inter(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Danger zone
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _deleteAccount,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Color(0xFFba1a1a),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Supprimer le compte',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFba1a1a),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'La suppression de votre compte est définitive et entraînera la perte de tout votre historique d\'analyse de plantes et vos collections sauvegardées.',
                            style: GoogleFonts.inter(
                              color: onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Footer actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _loadUser,
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.inter(color: onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Enregistrer les modifications',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
