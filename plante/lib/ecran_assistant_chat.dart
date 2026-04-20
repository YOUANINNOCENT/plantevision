import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async' show TimeoutException;
import 'services/api_service.dart';

/// Retourne l'URL de base du backend selon la plateforme ou la configuration.
// Utiliser `ApiService.instance` pour les appels réseau et l'URL de base.

// Écran assistant (chat) - fichier en français
class EcranAssistantChat extends StatefulWidget {
  const EcranAssistantChat({super.key});

  @override
  State<EcranAssistantChat> createState() => _EcranAssistantChatState();
}

class _EcranAssistantChatState extends State<EcranAssistantChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  String _agentName = 'AGENT IA';
  String _agentRole = 'Assistant';
  String? _agentAvatar;
  bool _loadingAgent = true;
  bool _loadingConversations = true;
  List<Map<String, dynamic>> _conversations = [];
  int? _currentConversationId;

  @override
  void initState() {
    super.initState();
    _loadAgentInfo();
    _loadConversations();
  }

  Future<void> _loadAgentInfo() async {
    try {
      final j = await ApiService.instance.getJson('/admin/agent_info');
      setState(() {
        _agentName = j['name']?.toString() ?? _agentName;
        _agentRole = j['role']?.toString() ?? _agentRole;
        _agentAvatar = j['avatar_url']?.toString();
      });
    } catch (_) {
      // ignore - endpoint optional
    } finally {
      if (mounted) {
        setState(() => _loadingAgent = false);
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final j = await ApiService.instance.getJson('/conversations/1');
      final results = (j['results'] as List?) ?? [];
      setState(() {
        _conversations = results
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (_conversations.isNotEmpty) {
          _currentConversationId = _conversations.first['id'] as int?;
        }
      });
      if (_currentConversationId != null) {
        await _loadConversationMessages(_currentConversationId!);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _loadingConversations = false);
      }
    }
  }

  Future<void> _loadConversationMessages(int convId) async {
    try {
      final j = await ApiService.instance.getJson(
        '/conversations/$convId/messages',
      );
      final results = (j['results'] as List?) ?? [];
      setState(() {
        _messages.clear();
        for (final m in results) {
          final role = (m['role'] ?? 'assistant').toString();
          _messages.add({
            'role': role == 'user' ? 'user' : 'ai',
            'text': m['content'] ?? '',
            'time': (m['created_at'] ?? '') is String
                ? (m['created_at'] as String).substring(11, 16)
                : '',
          });
        }
      });
      _scrollToEnd();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFfbfbe2);
    const primary = Color(0xFF0d631b);
    const surfaceLowest = Color(0xFFFFFFFF);
    const surfaceContainerHigh = Color(0xFFefefd7);
    const outlineVariant = Color(0xFFbfcaba);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, color: primary),
              onPressed: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 8),
            Text(
              'VISION',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _agentName,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                    Text(
                      _agentRole,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF40493d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _loadingAgent
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_agentAvatar != null && _agentAvatar!.isNotEmpty)
                        ? Image.network(_agentAvatar!, fit: BoxFit.cover)
                        : const Icon(Icons.smart_toy, color: Color(0xFF0d631b)),
                  ),
                ),
                const SizedBox(width: 8),
                // show small loader when conversation list is loading
                if (_loadingConversations)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, idx) {
                    if (idx >= _messages.length) return const SizedBox.shrink();
                    final m = _messages[idx];
                    if (m['role'] == 'date') {
                      return Column(
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                m['text'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF40493d),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    if (m['role'] == 'user') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(8),
                                  bottomLeft: Radius.circular(24),
                                ),
                              ),
                              child: Text(
                                m['text'],
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            m['time'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF40493d),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.92,
                          decoration: BoxDecoration(
                            color: surfaceLowest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: outlineVariant.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.science,
                                    color: primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    m['title']?.toString() ?? 'Réponse',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // If the AI message contains an image, render it
                              if (m.containsKey('image_b64')) ...[
                                if ((m['text'] ?? '').isNotEmpty) ...[
                                  Text(
                                    m['text'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF1b1d0e),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Builder(
                                  builder: (c) {
                                    try {
                                      final bytes = base64Decode(
                                        m['image_b64'],
                                      );
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          bytes,
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.8,
                                          height: 240,
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    } catch (e) {
                                      return Text('Erreur affichage image: $e');
                                    }
                                  },
                                ),
                                const SizedBox(height: 14),
                              ] else ...[
                                Text(
                                  m['text'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF1b1d0e),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                              const SizedBox(height: 14),
                              if (m['suggestions'] is List &&
                                  (m['suggestions'] as List).isNotEmpty)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (final s
                                          in (m['suggestions'] as List)) ...[
                                        _chip(s.toString()),
                                        const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          m['time'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF40493d),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Bottom input area
            Container(
              color: bg.withValues(alpha: 0.95),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF40493d),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                    hintText: 'Posez votre question...',
                                    hintStyle: GoogleFonts.inter(
                                      color: const Color(0xFF808080),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.auto_awesome,
                                  color: primary,
                                ),
                              ),
                              // Image generation button
                              IconButton(
                                onPressed: _handleGenerateImage,
                                icon: const Icon(
                                  Icons.image,
                                  color: Color(0xFF0d631b),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleSend,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          backgroundColor: primary,
                          padding: const EdgeInsets.all(14),
                        ),
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'L\'IA peut faire des erreurs. Consultez toujours un professionnel avant consommation.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Color(0xFF9aa092),
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text, 'time': _now()});
      _controller.clear();
    });
    _scrollToEnd();
    try {
      final answerJ = await _askBackend(text);
      final answer = answerJ['answer']?.toString() ?? '';
      // update conversation id if returned
      if (answerJ['conversation_id'] != null) {
        final cid =
            int.tryParse(answerJ['conversation_id'].toString()) ??
            answerJ['conversation_id'];
        if (cid is int) {
          _currentConversationId = cid;
        }
      }
      setState(() {
        _messages.add({'role': 'ai', 'text': answer, 'time': _now()});
      });
      _scrollToEnd();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Erreur: $e', 'time': _now()});
      });
      _scrollToEnd();
    }
  }

  Future<void> _handleGenerateImage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez d\'abord une description pour l\'image'),
        ),
      );
      return;
    }
    setState(() {
      _messages.add({'role': 'user', 'text': prompt, 'time': _now()});
      _controller.clear();
    });
    _scrollToEnd();

    // add placeholder
    setState(() {
      _messages.add({
        'role': 'ai',
        'text': 'Génération d\'image en cours...',
        'time': _now(),
        'loading': true,
      });
    });
    _scrollToEnd();

    try {
      final imgB64 = await _generateImageBackend(prompt, '512x512');
      setState(() {
        _messages.removeWhere((m) => m['loading'] == true);
        _messages.add({
          'role': 'ai',
          'image_b64': imgB64,
          'text': '',
          'time': _now(),
        });
      });
      _scrollToEnd();
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m['loading'] == true);
        _messages.add({
          'role': 'ai',
          'text': 'Erreur génération image: $e',
          'time': _now(),
        });
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _now() => DateTime.now().toLocal().toIso8601String().substring(11, 16);

  Future<Map<String, dynamic>> _askBackend(String message) async {
    try {
      final Map<String, dynamic> payload = {'message': message};
      if (_currentConversationId != null) {
        payload['conversation_id'] = _currentConversationId;
      }
      final j = await ApiService.instance
          .postJson('/ask', payload)
          .timeout(const Duration(seconds: 30));
      return Map<String, dynamic>.from(j);
    } on TimeoutException {
      throw 'Délai d\'attente dépassé — le serveur n\'a pas répondu';
    } catch (e) {
      throw 'Erreur de connexion — ${e.toString()}';
    }
  }

  Future<String> _generateImageBackend(String prompt, String size) async {
    try {
      final j = await ApiService.instance
          .postJson('/generate_image', {'prompt': prompt, 'size': size})
          .timeout(const Duration(seconds: 60));
      return j['image_b64']?.toString() ?? '';
    } on TimeoutException {
      throw 'Délai d\'attente dépassé — le serveur n\'a pas répondu';
    } catch (e) {
      throw 'Erreur de connexion — ${e.toString()}';
    }
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFdae6d1).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF151e11)),
      ),
    );
  }
}
