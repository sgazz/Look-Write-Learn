"""
Machine Learning model za prepoznavanje handwritten karaktera
Koristi CNN (Convolutional Neural Network) treniran na EMNIST datasetu
"""
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import os
import logging

logger = logging.getLogger(__name__)

class CharacterRecognitionModel:
    def __init__(self, model_path='models/character_model.keras'):
        self.model_path = model_path
        self.model = None
        self.img_size = 28  # EMNIST standard size
        
        # Character mappings (uppercase, lowercase, digits)
        self.char_map = self._create_char_map()
        
    def _create_char_map(self):
        """Kreira mapping između class indices i karaktera"""
        # Uppercase A-Z
        uppercase = [chr(i) for i in range(65, 91)]
        # Lowercase a-z
        lowercase = [chr(i) for i in range(97, 123)]
        # Digits 0-9
        digits = [str(i) for i in range(10)]
        
        return uppercase + lowercase + digits
    
    def create_model(self):
        """
        Kreira CNN model za character recognition
        Arhitektura: Conv2D -> MaxPool -> Conv2D -> MaxPool -> Dense -> Output
        """
        model = keras.Sequential([
            # Input layer
            layers.Input(shape=(self.img_size, self.img_size, 1)),
            
            # First convolutional block
            layers.Conv2D(32, kernel_size=(3, 3), activation='relu', padding='same'),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Dropout(0.25),
            
            # Second convolutional block
            layers.Conv2D(64, kernel_size=(3, 3), activation='relu', padding='same'),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Dropout(0.25),
            
            # Third convolutional block
            layers.Conv2D(128, kernel_size=(3, 3), activation='relu', padding='same'),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Dropout(0.25),
            
            # Flatten and dense layers
            layers.Flatten(),
            layers.Dense(256, activation='relu'),
            layers.Dropout(0.5),
            layers.Dense(len(self.char_map), activation='softmax')
        ])
        
        model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
        )
        
        return model
    
    def load_or_create_model(self):
        """Učitava postojeći model ili kreira novi"""
        if os.path.exists(self.model_path):
            try:
                logger.info(f"Loading existing model from {self.model_path}")
                self.model = keras.models.load_model(self.model_path)
                logger.info("Model loaded successfully!")
                return True
            except Exception as e:
                logger.warning(f"Failed to load model: {e}")
                logger.info("Creating new model instead...")
        
        # Kreiraj novi model
        logger.info("Creating new CNN model...")
        self.model = self.create_model()
        
        # Za proof-of-concept, kreiraj baseline model sa random weights
        # U produkciji, treba trenirati na EMNIST datasetu
        logger.info("Model created with random initialization")
        logger.warning("⚠️  Model nije treniran! Za produkciju treba trenirati na EMNIST datasetu.")
        
        return False
    
    def preprocess_image(self, image_array):
        """
        Priprema sliku za model
        - Konvertuje u grayscale ako nije
        - Resize na 28x28
        - Normalize na [0, 1]
        - Invert ako je potrebno (white on black)
        """
        from PIL import Image
        import cv2
        
        # Konvertuj u grayscale
        if len(image_array.shape) == 3:
            gray = cv2.cvtColor(image_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = image_array
        
        # Resize na 28x28
        resized = cv2.resize(gray, (self.img_size, self.img_size), 
                            interpolation=cv2.INTER_AREA)
        
        # Invert ako je potrebno (EMNIST expects white on black)
        # Proveri da li je pozadina bela
        if np.mean(resized) > 127:
            resized = 255 - resized
        
        # Normalize na [0, 1]
        normalized = resized.astype('float32') / 255.0
        
        # Reshape za model: (1, 28, 28, 1)
        processed = normalized.reshape(1, self.img_size, self.img_size, 1)
        
        return processed
    
    def predict_character(self, image_array):
        """
        Predviđa koji karakter je nacrtan
        Returns: (predicted_char, confidence, top_5_predictions)
        """
        if self.model is None:
            raise ValueError("Model nije učitan! Pozovi load_or_create_model() prvo.")
        
        # Preprocess image
        processed_image = self.preprocess_image(image_array)
        
        # Predict
        predictions = self.model.predict(processed_image, verbose=0)[0]
        
        # Get top prediction
        top_idx = np.argmax(predictions)
        confidence = float(predictions[top_idx])
        predicted_char = self.char_map[top_idx]
        
        # Get top 5 predictions
        top_5_indices = np.argsort(predictions)[-5:][::-1]
        top_5 = [(self.char_map[idx], float(predictions[idx])) 
                 for idx in top_5_indices]
        
        return predicted_char, confidence, top_5
    
    def evaluate_drawing(self, image_array, expected_char):
        """
        Evaluira crtež u odnosu na očekivani karakter
        Returns: (is_correct, confidence, score)
        """
        predicted_char, confidence, top_5 = self.predict_character(image_array)
        
        # Check if prediction is correct
        is_correct = predicted_char.upper() == expected_char.upper()
        
        # Calculate score (0-100%)
        if is_correct:
            # Direct match - high score based on confidence
            score = int(confidence * 95)  # Max 95% for correct prediction
        else:
            # Check if expected char is in top 5
            expected_in_top5 = any(char.upper() == expected_char.upper() 
                                  for char, _ in top_5)
            if expected_in_top5:
                # Close but not exact - medium score
                score = int(confidence * 60)
            else:
                # Wrong prediction - low score
                score = int(confidence * 30)
        
        # Ensure minimum and maximum bounds
        score = max(10, min(score, 95))
        
        return is_correct, confidence, score, top_5


# Global instance
_model_instance = None

def get_model():
    """Singleton pattern za model"""
    global _model_instance
    if _model_instance is None:
        _model_instance = CharacterRecognitionModel()
        _model_instance.load_or_create_model()
    return _model_instance
