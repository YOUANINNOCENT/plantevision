import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async' show TimeoutException;

import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'ecran_accueil.dart';
import 'ecran_historique.dart';
import 'ecran_tableau.dart';
import 'ecran_resultat_analyse.dart';
import 'package:plante/services/api_service.dart';

class EcranScanner extends StatefulWidget {
  const EcranScanner({super.key});

  @override
  State<EcranScanner> createState() => _EcranScannerState();
}

class _EcranScannerState extends State<EcranScanner>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Uint8List? _pickedImageBytes;
  // Dynamic config from backend
  String? _avatarUrl;
  bool _isExpert = false;
  String _hintTitle = 'Mode Expert Activé';
  String _hintSubtitle = 'Analyse taxonomique automatique en cours...';
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      // load user info
      try {
        final uRaw = await ApiService.instance.getJson('/users/1');
        final u = Map<String, dynamic>.from(uRaw as Map);
        setState(() {
          _avatarUrl = u['avatar_url']?.toString();
          _isExpert = (u['is_premium'] == true) || (u['is_expert'] == true);
        });
      } catch (_) {
        // ignore missing user or fields
      }

      // load dashboard to customize hints/background
      try {
        final dRaw = await ApiService.instance.getJson('/dashboard');
        final d = Map<String, dynamic>.from(dRaw as Map);
        final stats = d['stats'] != null
            ? Map<String, dynamic>.from(d['stats'] as Map)
            : <String, dynamic>{};
        final donut = d['donut'] != null
            ? Map<String, dynamic>.from(d['donut'] as Map)
            : <String, dynamic>{};
        setState(() {
          _hintTitle = _isExpert ? 'Mode Expert Activé' : 'Mode Normal';
          _hintSubtitle =
              'Scans: ${stats['total_scans'] ?? '—'} • Espèces: ${stats['species_count'] ?? '—'}';
          _backgroundImageUrl = donut['background_image']?.toString();
        });
      } catch (_) {
        // ignore
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      // Prefer back camera
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      // ignore errors for now; keep placeholder
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // capture context to use after await to satisfy analyzer
      final useContext = context;
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final pickedBytes = await picked.readAsBytes();
      _pickedImageBytes = pickedBytes;
      if (!mounted) return;
      // Show preview dialog; return true if user confirms send
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Image sélectionnée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _pickedImageBytes != null
                    ? Image.memory(_pickedImageBytes!, fit: BoxFit.contain)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      );

      // If user confirmed, perform upload outside of dialog builder (no BuildContext across await)
      if (shouldSend == true) {
        if (!mounted || !useContext.mounted) return;
        ScaffoldMessenger.of(
          useContext,
        ).showSnackBar(const SnackBar(content: Text('Envoi en cours...')));
        try {
          // encode image as base64 and call backend identify endpoint
          final bytes = _pickedImageBytes; // already read via XFile
          if (bytes == null) throw 'Image introuvable';
          final b64 = base64Encode(bytes);
          if (ApiService.instance.baseUrl == 'https://api.example.com') {
            ApiService.instance.baseUrl = 'http://127.0.0.1:8000';
          }
          final resp = await _sendIdentify(b64);
          final analysis = resp['analysis'];
          if (!mounted || !useContext.mounted) return;
          ScaffoldMessenger.of(
            useContext,
          ).showSnackBar(const SnackBar(content: Text('Analyse terminée')));
          Navigator.of(useContext).push(
            MaterialPageRoute(
              builder: (_) => EcranResultatAnalyse(analysis: analysis),
            ),
          );
        } catch (e) {
          if (!mounted || !useContext.mounted) return;
          String msg = 'Erreur lors de l\'analyse';
          try {
            if (e is ApiException) {
              if (e.statusCode == 502) {
                msg = 'Serveur temporairement indisponible';
              } else if (e.statusCode == 504) {
                msg = 'Le serveur ne répond pas';
              } else if (e.statusCode == 401) {
                msg = 'Problème de clé API';
              } else if (e.statusCode == 403) {
                msg = 'Accès refusé';
              } else if (e.statusCode == 429) {
                msg = 'Trop de requêtes, réessaye plus tard';
              } else {
                msg = e.message;
              }
            } else if (e is TimeoutException) {
              msg = 'Le serveur ne répond pas';
            } else if (e is Exception && e.toString().isNotEmpty) {
              msg = e.toString();
            }
          } catch (_) {}
          ScaffoldMessenger.of(
            useContext,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    final useContext = context;
    try {
      final xfile = await _cameraController!.takePicture();
      if (!mounted || !useContext.mounted) return;
      ScaffoldMessenger.of(
        useContext,
      ).showSnackBar(const SnackBar(content: Text('Capture en cours...')));
      try {
        // encode file as base64 and call identify endpoint
        final bytes = await xfile.readAsBytes();
        final b64 = base64Encode(bytes);
        if (ApiService.instance.baseUrl == 'https://api.example.com') {
          ApiService.instance.baseUrl = 'http://127.0.0.1:8000';
        }
        final resp = await _sendIdentify(b64);
        final analysis = resp['analysis'];
        if (!mounted || !useContext.mounted) return;
        ScaffoldMessenger.of(
          useContext,
        ).showSnackBar(const SnackBar(content: Text('Analyse terminée')));
        Navigator.of(useContext).push(
          MaterialPageRoute(
            builder: (_) => EcranResultatAnalyse(analysis: analysis),
          ),
        );
      } catch (e) {
        if (!mounted || !useContext.mounted) return;
        String msg = 'Erreur lors de l\'analyse';
        try {
          if (e is ApiException) {
            if (e.statusCode == 502) {
              msg = 'Serveur temporairement indisponible';
            } else if (e.statusCode == 504) {
              msg = 'Le serveur ne répond pas';
            } else if (e.statusCode == 401) {
              msg = 'Problème de clé API';
            } else if (e.statusCode == 403) {
              msg = 'Accès refusé';
            } else if (e.statusCode == 429) {
              msg = 'Trop de requêtes, réessaye plus tard';
            } else {
              msg = e.message;
            }
          } else if (e is TimeoutException) {
            msg = 'Le serveur ne répond pas';
          } else if (e is Exception && e.toString().isNotEmpty) {
            msg = e.toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(
          useContext,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      // ignore camera errors
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _sendIdentify(String b64) async {
    int attempts = 0;
    while (true) {
      attempts += 1;
      try {
        // prefer a shorter timeout for UI responsiveness
        final respFuture = ApiService.instance.postJson('/identify', {
          'images': [b64],
          'user_id': 1,
        });
        final resp = await respFuture.timeout(const Duration(seconds: 10));
        return resp;
      } on TimeoutException {
        // map to ApiException-like for upstream handling
        throw ApiException(504, 'Le serveur ne répond pas');
      } on ApiException catch (e) {
        // retry once on 502
        if (e.statusCode == 502 && attempts == 1) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFFfbfbe2);
    const Color primaryContainer = Color(0xFF2e7d32);
    const Color surfaceContainerHigh = Color(0xFFefefd7);
    const Color onSurfaceVariant = Color(0xFF40493d);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(Icons.menu, color: Color(0xFF0d631b)),
        ),
        centerTitle: true,
        title: Text(
          'Vision',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0d631b),
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(_avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: surfaceContainerHigh,
                    child: const Icon(Icons.person, color: Color(0xFF0d631b)),
                  ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview area (falls back to placeholder image)
          Positioned.fill(
            child: _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          _backgroundImageUrl ??
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuC3p39lg_poGz9-pFe1w8-85uRtNaz1lwXBBdOfL71sdI85ZNVT53CbY91tgstIKVoHL5tybrABZQCtIF6A35ZhiJNnAE37rwdaDAQn3yTHyF1xF7cPA17K3TjW5llFNAdQic-EJDnEIQVjCrqjH3yNvaQzWCxciaBaYZ9sI6oRgfl0fjlzkPr924ujAFIyUUQQTrSlwPQeCPcrUoCmOvnvtmXeO-i8htB3jeFwapehv_CHzHwA9ZChI0ntb1ngu36N6DBzPn_-cttY',
                        ),
                      ),
                    ),
                  ),
          ),

          // Overlay UI
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Hint card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _hintTitle,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hintSubtitle,
                                style: GoogleFonts.inter(
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
                ),

                // Viewfinder area (flexible to avoid bottom overflow on small screens)
                Flexible(
                  flex: 1,
                  child: Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        children: [
                          // Corners
                          Positioned(top: 0, left: 0, child: _Corner()),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _Corner(rotated: true),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: _Corner(rotated: true, invert: true),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _Corner(invert: true),
                          ),
                          // Scanning line (green, subtle glow)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: 3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryContainer.withAlpha(220),
                                      primaryContainer.withAlpha(120),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryContainer.withAlpha(100),
                                      blurRadius: 12,
                                      spreadRadius: 1,
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

                // Center hint pill
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: Center(
                      child: Text(
                        'PLACER LE SPÉCIMEN AU CENTRE',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(160),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Importer',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Shutter
                      GestureDetector(
                        onTap: _captureAndAnalyze,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(200),
                          ),
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryContainer,
                                width: 6,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.center_focus_strong,
                                color: Color(0xFF0d631b),
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(160),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flash_on,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Flash',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom nav spacer
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        decoration: BoxDecoration(color: background.withAlpha(230)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranAccueil()),
                );
              },
              child: const _SmallNav(icon: Icons.home, label: 'Accueil'),
            ),
            const _SmallNav(
              icon: Icons.center_focus_strong,
              label: 'Analyser',
              active: true,
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranHistorique()),
                );
              },
              child: const _SmallNav(icon: Icons.history, label: 'Historique'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranTableau()),
                );
              },
              child: const _SmallNav(icon: Icons.dashboard, label: 'Tableau'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool rotated;
  final bool invert;
  const _Corner({this.rotated = false, this.invert = false});

  @override
  Widget build(BuildContext context) {
    // Compute rotation angle so the same widget can be reused for all corners
    double angle = 0;
    if (rotated && !invert) {
      angle = 90 * 3.1415926535 / 180;
    } else if (rotated && invert) {
      angle = 270 * 3.1415926535 / 180;
    } else if (!rotated && invert) {
      angle = 180 * 3.1415926535 / 180;
    }

    const double size = 64;
    const double thickness = 6;

    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(width: thickness, color: Colors.white),
            left: BorderSide(width: thickness, color: Colors.white),
          ),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _SmallNav({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0d631b) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : const Color(0xFF576251),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: active ? const Color(0xFF0d631b) : const Color(0xFF576251),
          ),
        ),
      ],
    );
  }
}
