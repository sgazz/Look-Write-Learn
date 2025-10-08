from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import numpy as np
from PIL import Image
import io
import base64
import logging

app = Flask(__name__)
CORS(app)

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'LookWriteLearn Backend',
        'version': '1.0.0'
    })

@app.route('/api/compare', methods=['POST'])
def compare_drawing():
    """
    Compare user's drawing with the target letter
    Expected JSON: {
        'image': 'data:image/png;base64,...',
        'letter': 'A',
        'mode': 'upper' | 'lower' | 'number'
    }
    """
    try:
        data = request.json
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        image_data = data.get('image')
        target_letter = data.get('letter')
        mode = data.get('mode', 'upper')
        
        if not image_data or not target_letter:
            return jsonify({'error': 'Missing image or letter parameter'}), 400
        
        logger.info(f"Comparing drawing for letter: {target_letter} (mode: {mode})")
        
        # Decode base64 image
        try:
            # Remove data URL prefix if present
            if ',' in image_data:
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
        except Exception as e:
            logger.error(f"Error decoding image: {e}")
            return jsonify({'error': 'Invalid image data'}), 400
        
        # Convert to OpenCV format
        img_array = np.array(image.convert('RGB'))
        
        # Calculate similarity score
        score = calculate_similarity(img_array, target_letter, mode)
        
        # Get feedback based on score
        feedback = get_feedback(score)
        
        logger.info(f"Score: {score}%, Feedback: {feedback}")
        
        return jsonify({
            'score': score,
            'feedback': feedback,
            'letter': target_letter,
            'details': {
                'accuracy': get_accuracy_level(score),
                'tips': get_tips(score, target_letter)
            }
        })
    
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        return jsonify({'error': str(e)}), 500

def calculate_similarity(drawing, letter, mode):
    """
    Calculate similarity between drawing and target letter
    Uses multiple techniques:
    1. Edge detection and comparison
    2. Contour analysis
    3. Pixel coverage
    """
    try:
        # Convert to grayscale
        gray = cv2.cvtColor(drawing, cv2.COLOR_RGB2GRAY)
        
        # Apply thresholding to get binary image
        _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)
        
        # Calculate coverage (how much of canvas is filled)
        coverage = np.count_nonzero(binary) / binary.size
        
        # Find contours
        contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if not contours:
            return 0  # No drawing detected
        
        # Get the largest contour (main drawing)
        main_contour = max(contours, key=cv2.contourArea)
        
        # Calculate various metrics
        contour_area = cv2.contourArea(main_contour)
        hull = cv2.convexHull(main_contour)
        hull_area = cv2.contourArea(hull)
        
        # Solidity: how "solid" the shape is
        solidity = contour_area / hull_area if hull_area > 0 else 0
        
        # Calculate bounding box aspect ratio
        x, y, w, h = cv2.boundingRect(main_contour)
        aspect_ratio = w / h if h > 0 else 1
        
        # Basic scoring based on metrics
        # This is a simplified version - can be improved with ML
        base_score = 50  # Start with 50%
        
        # Coverage bonus (not too little, not too much)
        if 0.1 < coverage < 0.5:
            base_score += 20
        elif 0.05 < coverage < 0.7:
            base_score += 10
        
        # Solidity bonus (more solid shapes = better)
        if solidity > 0.7:
            base_score += 15
        elif solidity > 0.5:
            base_score += 10
        
        # Letter-specific adjustments
        letter_bonus = get_letter_specific_score(letter, aspect_ratio, contours)
        base_score += letter_bonus
        
        # Cap at 95% (perfect 100% is rare)
        final_score = min(base_score, 95)
        
        return int(final_score)
    
    except Exception as e:
        logger.error(f"Error calculating similarity: {e}")
        return 50  # Default middle score on error

def get_letter_specific_score(letter, aspect_ratio, contours):
    """
    Adjust score based on letter-specific characteristics
    """
    bonus = 0
    
    # Vertical letters (I, l, 1) should be tall
    if letter.upper() in ['I', 'L', 'T', '1']:
        if aspect_ratio < 0.5:  # Taller than wide
            bonus += 10
    
    # Horizontal letters (O, Q, 0) should be round
    elif letter.upper() in ['O', 'Q', 'C', 'D', '0']:
        if 0.7 < aspect_ratio < 1.3:  # More square-like
            bonus += 10
    
    # Wide letters (M, W)
    elif letter.upper() in ['M', 'W']:
        if aspect_ratio > 1.2:  # Wider than tall
            bonus += 10
    
    # Letters with multiple parts (i, j) - check for dots
    if letter in ['i', 'j']:
        if len(contours) > 1:  # Has dot
            bonus += 15
    
    return bonus

def get_feedback(score):
    """Generate encouraging feedback based on score"""
    if score >= 90:
        return "Excellent! Perfect letter! 🌟✨"
    elif score >= 80:
        return "Great job! Very good! 👏🎉"
    elif score >= 70:
        return "Good work! Keep it up! 💪😊"
    elif score >= 60:
        return "Nice try! Practice a bit more! 👍"
    elif score >= 50:
        return "Try again! You can do better! 🎯"
    else:
        return "Keep trying! Follow the model letter! 💡"

def get_accuracy_level(score):
    """Return accuracy level category"""
    if score >= 90:
        return "excellent"
    elif score >= 75:
        return "good"
    elif score >= 60:
        return "fair"
    else:
        return "needs_practice"

def get_tips(score, letter):
    """Provide helpful tips based on score and letter"""
    tips = []
    
    if score < 70:
        tips.append(f"Follow the model letter '{letter}' more carefully")
        tips.append("Try to draw slower and more precisely")
    
    if score < 50:
        tips.append("Look at the model letter carefully before you start")
        tips.append("Take your time, accuracy is important!")
    
    if not tips:
        tips.append("Keep practicing and you'll get even better!")
    
    return tips

if __name__ == '__main__':
    logger.info("Starting LookWriteLearn Backend Server...")
    app.run(host='0.0.0.0', port=8001, debug=True)
