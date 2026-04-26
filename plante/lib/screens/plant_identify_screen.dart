import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/plantnet_service.dart';

class PlantIdentifyScreen extends StatefulWidget {
  const PlantIdentifyScreen({super.key});

  @override
  State<PlantIdentifyScreen> createState() => _PlantIdentifyScreenState();
}

class _PlantIdentifyScreenState extends State<PlantIdentifyScreen> {
  File? _selectedImage;
  IdentifyResponse? _result;
  bool _isLoading = false;
  String _selectedOrgan = 'auto';
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> _organs = [
    {'value': 'auto', 'label': '🤖 Auto'},
    {'value': 'leaf', 'label': '🍃 Feuille'},
    {'value': 'flower', 'label': '🌸 Fleur'},
    {'value': 'fruit', 'label': '🍎 Fruit'},
    {'value': 'bark', 'label': '🌳 Écorce'},
    {'value': 'habit', 'label': '🌿 Plante entière'},
  ];

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
    });

    await _identify();
  }

  Future<void> _identify() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await PlantNetService.identifyPlant(
        imageFile: _selectedImage!,
        organ: _selectedOrgan,
      );
      setState(() => _result = response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('🌿 Identifier une plante'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OrganSelector(
              organs: _organs,
              selected: _selectedOrgan,
              onChanged: (v) => setState(() => _selectedOrgan = v),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt,
                    label: 'Caméra',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImage!,
                  height: 240,
                  fit: BoxFit.cover,
                ),
              ),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    SizedBox(height: 12),
                    Text('Identification en cours...'),
                  ],
                ),
              ),
            ],

            if (_result != null && !_isLoading) ...[
              const SizedBox(height: 16),
              _ResultCard(response: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrganSelector extends StatelessWidget {
  final List<Map<String, String>> organs;
  final String selected;
  final ValueChanged<String> onChanged;

  const _OrganSelector({
    required this.organs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organe photographié',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: organs.map((organ) {
            final isSelected = organ['value'] == selected;
            return ChoiceChip(
              label: Text(organ['label']!),
              selected: isSelected,
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
              onSelected: (_) => onChanged(organ['value']!),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF388E3C),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IdentifyResponse response;
  const _ResultCard({required this.response});

  @override
  Widget build(BuildContext context) {
    if (!response.success || response.bestMatch == null) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            response.message,
            style: TextStyle(color: Colors.orange.shade800),
          ),
        ),
      );
    }

    final best = response.bestMatch!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    const Text(
                      'Meilleur résultat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _scoreColor(best.score),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        best.scorePercent,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _InfoRow('Nom scientifique', best.scientificName, italic: true),
                if (best.commonNames.isNotEmpty)
                  _InfoRow('Nom commun', best.commonNames.join(', ')),
                _InfoRow('Famille', best.family),
                _InfoRow('Genre', best.genus),
                if (best.wikipediaUrl != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '🔗 ${best.wikipediaUrl}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (response.alternatives.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Autres possibilités',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...response.alternatives.map(
            (alt) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _scoreColor(alt.score),
                  child: Text(
                    alt.scorePercent.replaceAll('%', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  alt.scientificName,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
                subtitle: alt.commonNames.isNotEmpty
                    ? Text(alt.commonNames.first)
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return Colors.green.shade700;
    if (score >= 0.4) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool italic;

  const _InfoRow(this.label, this.value, {this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
