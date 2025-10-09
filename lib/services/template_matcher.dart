import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'template_loader.dart';

/// Service za matching user drawings sa templates
class TemplateMatcher {
  static const int targetSize = 28; // Standard size

  /// Evaluate user drawing against templates
  static Future<int> evaluateDrawing(
    Uint8List drawingBytes,
    String expectedCharacter,
  ) async {
    try {
      // 1. Load templates for expected character
      List<img.Image> templates =
          await TemplateLoader.loadTemplates(expectedCharacter);

      if (templates.isEmpty) {
        print('No templates found for $expectedCharacter');
        return 50; // Default score if no templates
      }

      // 2. Decode and preprocess user drawing
      img.Image? userDrawing = img.decodeImage(drawingBytes);
      if (userDrawing == null) {
        print('Failed to decode user drawing');
        return 0;
      }

      img.Image processedDrawing = preprocessImage(userDrawing);

      // 3. Calculate SSIM with each template
      List<double> ssimScores = [];
      for (img.Image template in templates) {
        double ssim = calculateSSIM(processedDrawing, template);
        ssimScores.add(ssim);
      }

      // 4. Get top 5 best matches
      ssimScores.sort((a, b) => b.compareTo(a));
      List<double> top5 = ssimScores.take(5).toList();
      double avgSSIM = top5.reduce((a, b) => a + b) / top5.length;

      // 5. Calculate shape quality score
      double shapeScore = calculateShapeQuality(processedDrawing);

      // 6. Combined score: 40% SSIM + 60% Shape Quality
      int finalScore = ((avgSSIM * 0.4 + shapeScore * 0.6) * 95).round();

      // Ensure bounds [0, 95]
      return finalScore.clamp(0, 95);
    } catch (e) {
      print('Error in evaluateDrawing: $e');
      return 50; // Default score on error
    }
  }

  /// Preprocess image for matching
  static img.Image preprocessImage(img.Image source) {
    // Convert to grayscale
    img.Image gray = img.grayscale(source);

    // Resize to target size (28x28)
    img.Image resized = img.copyResize(
      gray,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.average,
    );

    // Normalize and invert if needed (white on black)
    int totalPixels = resized.width * resized.height;
    int whitePixels = 0;

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        img.Pixel pixel = resized.getPixel(x, y);
        if (pixel.r > 200) whitePixels++;
      }
    }

    // If mostly white background, invert (make drawing white on black)
    if (whitePixels > totalPixels * 0.7) {
      resized = img.invert(resized);
    }

    return resized;
  }

  /// Calculate Structural Similarity Index (SSIM) between two images
  static double calculateSSIM(img.Image img1, img.Image img2) {
    if (img1.width != img2.width || img1.height != img2.height) {
      // Resize if needed
      img2 = img.copyResize(img2, width: img1.width, height: img1.height);
    }

    // Constants for SSIM calculation
    const double k1 = 0.01;
    const double k2 = 0.03;
    const double L = 255.0; // Dynamic range
    const double c1 = (k1 * L) * (k1 * L);
    const double c2 = (k2 * L) * (k2 * L);

    // Calculate means
    double mu1 = 0, mu2 = 0;
    int pixelCount = img1.width * img1.height;

    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        mu1 += img1.getPixel(x, y).r;
        mu2 += img2.getPixel(x, y).r;
      }
    }

    mu1 /= pixelCount;
    mu2 /= pixelCount;

    // Calculate variances and covariance
    double sigma1Sq = 0, sigma2Sq = 0, sigma12 = 0;

    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        double diff1 = img1.getPixel(x, y).r - mu1;
        double diff2 = img2.getPixel(x, y).r - mu2;

        sigma1Sq += diff1 * diff1;
        sigma2Sq += diff2 * diff2;
        sigma12 += diff1 * diff2;
      }
    }

    sigma1Sq /= pixelCount;
    sigma2Sq /= pixelCount;
    sigma12 /= pixelCount;

    // SSIM formula
    double numerator = (2 * mu1 * mu2 + c1) * (2 * sigma12 + c2);
    double denominator = (mu1 * mu1 + mu2 * mu2 + c1) *
        (sigma1Sq + sigma2Sq + c2);

    double ssim = numerator / denominator;

    // Normalize to [0, 1]
    return ssim.clamp(0.0, 1.0);
  }

  /// Calculate shape quality metrics
  static double calculateShapeQuality(img.Image drawing) {
    double qualityScore = 0.5; // Base score

    // 1. Coverage analysis (how much of canvas is filled)
    int blackPixels = 0;
    int totalPixels = drawing.width * drawing.height;

    for (int y = 0; y < drawing.height; y++) {
      for (int x = 0; x < drawing.width; x++) {
        img.Pixel pixel = drawing.getPixel(x, y);
        if (pixel.r < 128) blackPixels++; // Dark pixels
      }
    }

    double coverage = blackPixels / totalPixels;

    // Optimal coverage (5-40%)
    if (coverage > 0.05 && coverage < 0.4) {
      qualityScore += 0.25;
    } else if (coverage > 0.03 && coverage < 0.5) {
      qualityScore += 0.15;
    }

    // 2. Distribution analysis (is drawing centered/balanced?)
    double centerMassX = 0, centerMassY = 0;
    int mass = 0;

    for (int y = 0; y < drawing.height; y++) {
      for (int x = 0; x < drawing.width; x++) {
        img.Pixel pixel = drawing.getPixel(x, y);
        if (pixel.r < 128) {
          centerMassX += x;
          centerMassY += y;
          mass++;
        }
      }
    }

    if (mass > 0) {
      centerMassX /= mass;
      centerMassY /= mass;

      // Check if center of mass is near center of image
      double centerX = drawing.width / 2;
      double centerY = drawing.height / 2;
      double distanceFromCenter = math.sqrt(
        math.pow(centerMassX - centerX, 2) + math.pow(centerMassY - centerY, 2),
      );

      // Normalized distance (0 = perfect center, 1 = corner)
      double maxDistance = math.sqrt(centerX * centerX + centerY * centerY);
      double centeredness = 1 - (distanceFromCenter / maxDistance);

      if (centeredness > 0.7) {
        qualityScore += 0.25;
      } else if (centeredness > 0.5) {
        qualityScore += 0.15;
      }
    }

    return qualityScore.clamp(0.0, 1.0);
  }

  /// Get feedback message based on score
  static String getFeedback(int score) {
    if (score >= 90) return "Excellent! Perfect letter! 🌟✨";
    if (score >= 80) return "Great job! Very good! 👏🎉";
    if (score >= 70) return "Good work! Keep it up! 💪😊";
    if (score >= 60) return "Nice try! Practice a bit more! 👍";
    if (score >= 50) return "Try again! You can do better! 🎯";
    return "Keep trying! Follow the model letter! 💡";
  }

  /// Get accuracy level
  static String getAccuracy(int score) {
    if (score >= 90) return "excellent";
    if (score >= 75) return "good";
    if (score >= 60) return "fair";
    return "needs_practice";
  }

  /// Get tips based on score
  static List<String> getTips(int score, String letter) {
    List<String> tips = [];

    if (score < 70) {
      tips.add("Follow the model letter '$letter' more carefully");
      tips.add("Try to draw slower and more precisely");
    }

    if (score < 50) {
      tips.add("Look at the model letter carefully before you start");
      tips.add("Take your time, accuracy is important!");
    }

    if (tips.isEmpty) {
      tips.add("Keep practicing and you'll get even better!");
    }

    return tips;
  }
}

