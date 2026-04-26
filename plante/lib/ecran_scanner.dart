import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'dart:async' show TimeoutException;

import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'ecran_accueil.dart';
import 'ecran_historique.dart';
import 'ecran_tableau.dart';
import 'ecran_resultat_analyse.dart';
import 'package:plante/services/api_service.dart';
import 'package:plante/services/i18n.dart';

class EcranScanner extends StatefulWidget {
  const EcranScanner({super.key});

  @override
  State<EcranScanner> createState() => _EcranScannerState();
}

class _EcranScannerState extends State<EcranScanner>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  Uint8List? _pickedImageBytes;
  // Dynamic config from backend
  String? _backgroundImageUrl;
  late final AnimationController _scanController;
  late final Animation<double> _scanAnimation;
  // État de la lampe torche
  bool _flashOn = false;
  // Arrête l'animation de la ligne verte pendant capture/upload
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _loadConfig();
    // Scanning line animation: moves the green line up and down
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );
    _scanController.repeat(reverse: true);
  }

  Future<void> _loadConfig() async {
    try {
      // load dashboard to customize hints/background
      try {
        final dRaw = await ApiService.instance.getJson('/dashboard');
        final d = Map<String, dynamic>.from(dRaw as Map);
        final donut = d['donut'] != null
            ? Map<String, dynamic>.from(d['donut'] as Map)
            : <String, dynamic>{};
        setState(() {
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
      // Résolution élevée : meilleur taux d'identification PlantNet
      // (les détails fins des feuilles/nervures comptent énormément).
      _cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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

  /// Allume / éteint la lampe torche du téléphone via le CameraController.
  Future<void> _toggleFlash() async {
    final c = _cameraController;
    if (c == null || !_isCameraInitialized) return;
    try {
      final next = !_flashOn;
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _flashOn = next);
    } catch (e) {
      debugPrint('[scanner] setFlashMode erreur: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lampe torche indisponible sur cet appareil')),
      );
    }
  }

  /// Construit un SnackBar dont le ton (couleur + message) reflète le niveau
  /// de confiance retourné par le backend.
  SnackBar _buildConfidenceSnackBar({
    required String level,
    required bool ambiguous,
  }) {
    String text;
    Color bg;
    if (level == 'high' && !ambiguous) {
      text = 'Analyse terminée — identification fiable';
      bg = const Color(0xFF0d631b); // vert
    } else if (level == 'high' && ambiguous) {
      text = 'Analyse terminée — plusieurs espèces très proches, vérifie';
      bg = const Color(0xFF2e5c5c); // bleu-vert
    } else if (level == 'medium') {
      text = 'Analyse terminée — confiance moyenne, vérifie le résultat';
      bg = const Color(0xFFb58900); // ocre
    } else {
      text = 'Analyse terminée — confiance faible, photo douteuse';
      bg = const Color(0xFFc94f00); // orange foncé
    }
    return SnackBar(content: Text(text), backgroundColor: bg);
  }

  /// Met l'animation de la ligne de scan en pause (pendant capture/envoi).
  void _pauseScan() {
    if (!mounted) return;
    setState(() => _scanning = true);
    _scanController.stop();
  }

  /// Redémarre l'animation après réception du résultat.
  void _resumeScan() {
    if (!mounted) return;
    setState(() => _scanning = false);
    if (!_scanController.isAnimating) {
      _scanController.repeat(reverse: true);
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
          final level = resp['confidence_level']?.toString() ?? 'medium';
          final ambiguous = resp['ambiguous'] == true;
          if (!mounted || !useContext.mounted) return;
          ScaffoldMessenger.of(useContext).showSnackBar(
            _buildConfidenceSnackBar(level: level, ambiguous: ambiguous),
          );
          final candidates = (resp['candidates'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          Navigator.of(useContext).push(
            MaterialPageRoute(
              builder: (_) => EcranResultatAnalyse(
                analysis: analysis,
                confidenceLevel: level,
                candidates: candidates,
                ambiguous: ambiguous,
              ),
            ),
          );
        } catch (e) {
          if (!mounted || !useContext.mounted) return;
          String msg = 'Erreur lors de l\'analyse';
          try {
            if (e is ApiException) {
              if (e.statusCode == 422) {
                msg = e.message; // "Ce n'est pas une plante. Réessaye…"
              } else if (e.statusCode == 502) {
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
          final isNotPlant = e is ApiException && e.statusCode == 422;
          await _showErrorDialog(
            useContext,
            title: isNotPlant ? 'Pas une plante' : 'Erreur',
            message: msg,
            onRetry: () async {
              // retry sending the same image
              try {
                ScaffoldMessenger.of(useContext).showSnackBar(
                  const SnackBar(content: Text('Envoi en cours...')),
                );
                final bytes = _pickedImageBytes;
                if (bytes == null) throw 'Image introuvable';
                final b64 = base64Encode(bytes);
                final resp = await _sendIdentify(b64);
                final analysis = resp['analysis'];
                if (!mounted || !useContext.mounted) return;
                ScaffoldMessenger.of(useContext).showSnackBar(
                  const SnackBar(content: Text('Analyse terminée')),
                );
                Navigator.of(useContext).push(
                  MaterialPageRoute(
                    builder: (_) => EcranResultatAnalyse(analysis: analysis),
                  ),
                );
              } catch (e) {
                String msg2 = 'Échec du nouvel envoi';
                if (e is ApiException && e.statusCode == 504) {
                  msg2 = 'Le serveur ne répond toujours pas';
                }
                ScaffoldMessenger.of(
                  useContext,
                ).showSnackBar(SnackBar(content: Text(msg2)));
              }
            },
          );
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
        final level = resp['confidence_level']?.toString() ?? 'medium';
        final ambiguous = resp['ambiguous'] == true;
        if (!mounted || !useContext.mounted) return;
        ScaffoldMessenger.of(useContext).showSnackBar(
          _buildConfidenceSnackBar(level: level, ambiguous: ambiguous),
        );
        final candidates = (resp['candidates'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        Navigator.of(useContext).push(
          MaterialPageRoute(
            builder: (_) => EcranResultatAnalyse(
              analysis: analysis,
              confidenceLevel: level,
              candidates: candidates,
              ambiguous: ambiguous,
            ),
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
        await _showErrorDialog(
          useContext,
          title: 'Erreur',
          message: msg,
          onRetry: () async {
            // retry capture send
            try {
              ScaffoldMessenger.of(useContext).showSnackBar(
                const SnackBar(content: Text('Envoi en cours...')),
              );
              final xfile2 = await _cameraController!.takePicture();
              final bytes2 = await xfile2.readAsBytes();
              final b642 = base64Encode(bytes2);
              final resp2 = await _sendIdentify(b642);
              final analysis2 = resp2['analysis'];
              if (!mounted || !useContext.mounted) return;
              ScaffoldMessenger.of(
                useContext,
              ).showSnackBar(const SnackBar(content: Text('Analyse terminée')));
              Navigator.of(useContext).push(
                MaterialPageRoute(
                  builder: (_) => EcranResultatAnalyse(analysis: analysis2),
                ),
              );
            } catch (e) {
              String msg2 = 'Échec du nouvel envoi';
              if (e is ApiException && e.statusCode == 504) {
                msg2 = 'Le serveur ne répond toujours pas';
              }
              ScaffoldMessenger.of(
                useContext,
              ).showSnackBar(SnackBar(content: Text(msg2)));
            }
          },
        );
      }
    } catch (e) {
      // ignore camera errors
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(
    BuildContext ctx, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) async {
    return showDialog<void>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
            },
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(dctx).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Vérifiez que le backend est démarré et accessible sur le réseau.',
                  ),
                ),
              );
            },
            child: const Text('Aide'),
          ),
        ],
      ),
    );
  }

  /// Récupère la position GPS actuelle de l'utilisateur (best-effort).
  /// Renvoie null si l'utilisateur refuse la permission, si le GPS est
  /// désactivé, ou si aucune position n'est disponible dans le délai imparti.
  Future<Position?> _getCurrentPosition() async {
    try {
      // Vérifier que le service de localisation est activé
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        debugPrint('[geo] Service de localisation désactivé');
        return null;
      }

      // Vérifier/demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[geo] Permission refusée: $permission');
        return null;
      }

      // Récupérer la position, avec un timeout raisonnable.
      // On utilise l'API classique (desiredAccuracy + timeLimit) qui est
      // supportée par toutes les versions de geolocator.
      final pos = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      debugPrint('[geo] Position ${pos.latitude}, ${pos.longitude}');
      return pos;
    } catch (e) {
      debugPrint('[geo] Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  /// Résout des coordonnées en label humain (ex. "Quartier, Ville, Région").
  /// Utilise le géocodeur natif via le package geocoding. Renvoie null si
  /// la résolution échoue (hors-ligne, zone non couverte, erreur).
  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      // Force le français si possible
      try {
        await geocoding.setLocaleIdentifier('fr_FR');
      } catch (_) {}
      final placemarks = await geocoding
          .placemarkFromCoordinates(lat, lon)
          .timeout(const Duration(seconds: 6));
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      // Construit un label concis : quartier, ville, pays.
      final parts = <String>[];
      if ((p.subLocality ?? '').isNotEmpty) parts.add(p.subLocality!);
      if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
      if ((p.administrativeArea ?? '').isNotEmpty &&
          !parts.contains(p.administrativeArea)) {
        parts.add(p.administrativeArea!);
      }
      if ((p.country ?? '').isNotEmpty && parts.length < 3) {
        parts.add(p.country!);
      }
      if (parts.isEmpty) return null;
      final label = parts.join(', ');
      debugPrint('[geo] Label résolu: $label');
      return label;
    } catch (e) {
      debugPrint('[geo] reverseGeocode erreur: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _sendIdentify(String b64) async {
    // Met l'animation de scan en pause pendant capture + envoi.
    _pauseScan();
    try {
      return await _sendIdentifyInner(b64);
    } finally {
      _resumeScan();
    }
  }

  Future<Map<String, dynamic>> _sendIdentifyInner(String b64) async {
    // Essaye de récupérer la position, mais avec un timeout GLOBAL très court
    // pour ne JAMAIS retarder l'analyse : si pas de GPS en 3s, on part sans.
    Position? pos;
    String? label;
    try {
      pos = await _getCurrentPosition().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('[geo] GPS global timeout (3s) — scan sans position');
          return null;
        },
      );
    } catch (e) {
      debugPrint('[geo] GPS erreur (ignoré): $e');
      pos = null;
    }
    if (pos != null) {
      try {
        label = await _reverseGeocode(pos.latitude, pos.longitude).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('[geo] reverse-geocode timeout (3s)');
            return null;
          },
        );
      } catch (e) {
        debugPrint('[geo] reverse-geocode erreur (ignoré): $e');
        label = null;
      }
    }

    final payload = <String, dynamic>{
      'images': [b64],
      // Utilise l'utilisateur connecté pour rattacher l'analyse au bon compte.
      'user_id': ApiService.instance.currentUserId ?? 0,
    };
    if (pos != null) {
      payload['latitude'] = pos.latitude;
      payload['longitude'] = pos.longitude;
    }
    if (label != null && label.isNotEmpty) {
      payload['location_label'] = label;
    }
    debugPrint(
      '[scan] POST /identify_plantnet pos=${pos?.latitude},${pos?.longitude} label=$label',
    );

    int attempts = 0;
    while (true) {
      attempts += 1;
      try {
        debugPrint(
          'Calling: ${ApiService.instance.baseUrl}/identify_plantnet (tentative $attempts)',
        );
        final respFuture = ApiService.instance.postJson(
          '/identify_plantnet',
          payload,
        );
        final resp = await respFuture.timeout(const Duration(seconds: 25));
        debugPrint(
          '[scan] Réponse OK — clés=${resp.keys.toList()} '
          'analysis?=${resp['analysis'] != null}',
        );
        return resp;
      } on TimeoutException {
        throw ApiException(504, 'Le serveur ne répond pas');
      } on ApiException catch (e) {
        debugPrint('[scan] ApiException ${e.statusCode}: ${e.message}');
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

    return Scaffold(
      backgroundColor: background,
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
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuC3p39lg_poGz9-pFe1w8-85uRt Naz1lwXBBdOfL71sdI85ZNVT53CbY91tgstIKVoHL5tybrABZQCtIF6A35ZhiJNnAE37rwdaDAQn3yTHyF1xF7cPA17K3TjW5llFNAdQic-EJDnEIQVjCrqjH3yNvaQzWCxciaBaYZ9sI6oRgfl0fjlzkPr924ujAFIyUUQQTrSlwPQeCPcrUoCmOvnvtmXeO-i8htB3jeFwapehv_CHzHwA9ZChI0ntb1ngu36N6DBzPn_-cttY',
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
                // Hint card removed to avoid overlay on image

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
                          // Scanning line (green, animated). Cachée dès qu'une
                          // capture/analyse est en cours pour signaler que
                          // l'image est en cours d'envoi.
                          if (!_scanning)
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                // SizedBox uses a fixed height of 280 here; match movement range
                                const double boxHeight = 280.0;
                                const double lineHeight = 3.0;
                                final top =
                                    _scanAnimation.value *
                                    (boxHeight - lineHeight);
                                return Positioned(
                                  top: top,
                                  left: 0,
                                  right: 0,
                                  child: child!,
                                );
                              },
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
                        I18n.tr('scanner.hint'),
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
                              I18n.tr('scanner.import'),
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

                      GestureDetector(
                        onTap: _toggleFlash,
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _flashOn
                                    ? const Color(0xFFFFEB3B)
                                    : Colors.white.withAlpha(160),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _flashOn ? Icons.flash_on : Icons.flash_off,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              I18n.tr('scanner.flash'),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
              child: _SmallNav(icon: Icons.home, label: I18n.tr('nav.home')),
            ),
            _SmallNav(
              icon: Icons.center_focus_strong,
              label: I18n.tr('nav.analyse'),
              active: true,
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranHistorique()),
                );
              },
              child: _SmallNav(
                icon: Icons.history,
                label: I18n.tr('nav.history'),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranTableau()),
                );
              },
              child: _SmallNav(
                icon: Icons.dashboard,
                label: I18n.tr('nav.dashboard'),
              ),
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
