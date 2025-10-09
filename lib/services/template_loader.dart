import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

/// Service za učitavanje character templates iz assets
class TemplateLoader {
  // Cache loaded templates to avoid repeated loading
  static final Map<String, List<img.Image>> _cache = {};

  /// Get folder name based on character type
  static String _getFolder(String character) {
    if (RegExp(r'[A-Z]').hasMatch(character)) {
      return 'uppercase';
    } else if (RegExp(r'[a-z]').hasMatch(character)) {
      return 'lowercase';
    } else if (RegExp(r'[0-9]').hasMatch(character)) {
      return 'numbers';
    }
    return 'uppercase'; // default
  }

  /// Load all templates for a given character
  static Future<List<img.Image>> loadTemplates(String character) async {
    // Check cache first
    if (_cache.containsKey(character)) {
      return _cache[character]!;
    }

    List<img.Image> templates = [];
    String folder = _getFolder(character);

    // Load 10 templates (t01.png to t10.png)
    for (int i = 1; i <= 10; i++) {
      String templateNum = i.toString().padLeft(2, '0');
      String assetPath =
          'assets/templates/$folder/$character/t$templateNum.png';

      try {
        // Load from assets
        ByteData data = await rootBundle.load(assetPath);
        Uint8List bytes = data.buffer.asUint8List();

        // Decode image
        img.Image? template = img.decodeImage(bytes);
        if (template != null) {
          templates.add(template);
        }
      } catch (e) {
        // If template doesn't exist, skip (some characters might have fewer templates)
        // print('Warning: Could not load template $assetPath: $e');
        continue;
      }
    }

    // Cache for future use
    if (templates.isNotEmpty) {
      _cache[character] = templates;
    }

    return templates;
  }

  /// Preload templates for all characters (optional, for performance)
  static Future<void> preloadAll() async {
    List<String> allCharacters = [
      ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      ...'abcdefghijklmnopqrstuvwxyz'.split(''),
      ...'0123456789'.split(''),
    ];

    for (String char in allCharacters) {
      await loadTemplates(char);
    }
  }

  /// Clear cache (if needed)
  static void clearCache() {
    _cache.clear();
  }
}

