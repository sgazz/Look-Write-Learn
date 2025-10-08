import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Backend API URL - change this based on your environment
  static const String _baseUrl = 'http://localhost:5001';
  
  // For Android emulator, use: http://10.0.2.2:5001
  // For iOS simulator, use: http://localhost:5001
  // For real device, use your computer's IP: http://192.168.x.x:5001
  
  /// Check if backend is healthy
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
  
  /// Send drawing to backend for evaluation
  static Future<EvaluationResult?> evaluateDrawing({
    required Uint8List imageBytes,
    required String letter,
    required String mode, // 'upper', 'lower', or 'number'
  }) async {
    try {
      // Convert image bytes to base64
      final base64Image = base64Encode(imageBytes);
      final dataUrl = 'data:image/png;base64,$base64Image';
      
      // Prepare request
      final response = await http.post(
        Uri.parse('$_baseUrl/api/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': dataUrl,
          'letter': letter,
          'mode': mode,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return EvaluationResult.fromJson(jsonData);
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error evaluating drawing: $e');
      return null;
    }
  }
}

/// Evaluation result model
class EvaluationResult {
  final int score;
  final String feedback;
  final String letter;
  final String accuracy;
  final List<String> tips;
  
  EvaluationResult({
    required this.score,
    required this.feedback,
    required this.letter,
    required this.accuracy,
    required this.tips,
  });
  
  factory EvaluationResult.fromJson(Map<String, dynamic> json) {
    return EvaluationResult(
      score: json['score'] as int,
      feedback: json['feedback'] as String,
      letter: json['letter'] as String,
      accuracy: json['details']['accuracy'] as String,
      tips: List<String>.from(json['details']['tips'] as List),
    );
  }
  
  /// Get color based on score
  String get scoreColor {
    if (score >= 90) return 'green';
    if (score >= 70) return 'blue';
    if (score >= 50) return 'orange';
    return 'red';
  }
  
  /// Get emoji based on score
  String get emoji {
    if (score >= 90) return '🌟';
    if (score >= 70) return '👍';
    if (score >= 50) return '💪';
    return '🎯';
  }
}
