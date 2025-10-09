#!/usr/bin/env python3
"""
Generate character templates using Google Fonts
Creates templates for A-Z, a-z, 0-9 using Caveat and Comic Neue fonts
"""

import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from pathlib import Path

# Configuration
OUTPUT_DIR = Path("templates")
IMG_SIZE = 28  # Standard size for ML models
FONTS_TO_USE = [
    ("Caveat-Bold.ttf", "caveat"),
    ("ComicNeue-Bold.ttf", "comic"),
]

def get_system_fonts():
    """Get available system fonts"""
    fonts_dir = Path("fonts")
    fonts_dir.mkdir(exist_ok=True)
    
    # Try to find system fonts (macOS)
    system_font_paths = [
        "/System/Library/Fonts/Supplemental/Comic Sans MS Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    
    available_fonts = []
    
    for font_path in system_font_paths:
        if Path(font_path).exists():
            available_fonts.append((Path(font_path), Path(font_path).stem))
            print(f"✓ Found system font: {Path(font_path).name}")
    
    # If no fonts found, use PIL default
    if not available_fonts:
        print("⚠️  No system fonts found, will use PIL default font")
        available_fonts = [(None, "default")]
    
    return available_fonts

def create_template(character, font_path, size=200, canvas_size=280):
    """
    Create a template image for a single character
    """
    # Create white canvas
    img = Image.new('L', (canvas_size, canvas_size), color=255)
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype(str(font_path), size)
    except:
        print(f"Warning: Could not load font {font_path}, using default")
        font = ImageFont.load_default()
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), character, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (canvas_size - text_width) // 2 - bbox[0]
    y = (canvas_size - text_height) // 2 - bbox[1]
    
    # Draw text (black on white)
    draw.text((x, y), character, fill=0, font=font)
    
    # Resize to target size
    img_resized = img.resize((IMG_SIZE, IMG_SIZE), Image.Resampling.LANCZOS)
    
    return img_resized

def create_variations(character, font_path, num_variations=10):
    """
    Create multiple variations of the same character
    with slight modifications (rotation, translation, scale)
    """
    variations = []
    
    for i in range(num_variations):
        # Base template
        img = create_template(character, font_path, size=200)
        
        # Add variations
        if i > 0:  # First one stays as-is
            # Slight rotation (-5 to +5 degrees)
            angle = (i - 5) * 1.0
            img = img.rotate(angle, fillcolor=255, expand=False)
            
            # Slight scale variation (0.9 to 1.1)
            scale_factor = 0.95 + (i * 0.01)
            new_size = int(IMG_SIZE * scale_factor)
            img_scaled = img.resize((new_size, new_size), Image.Resampling.LANCZOS)
            
            # Paste back on 28x28 canvas (centered)
            img_final = Image.new('L', (IMG_SIZE, IMG_SIZE), color=255)
            offset = ((IMG_SIZE - new_size) // 2, (IMG_SIZE - new_size) // 2)
            img_final.paste(img_scaled, offset)
            img = img_final
        
        variations.append(img)
    
    return variations

def generate_all_templates():
    """Generate templates for all characters"""
    
    print("=" * 60)
    print("GENERATING CHARACTER TEMPLATES")
    print("=" * 60)
    
    # Get available fonts
    available_fonts = get_system_fonts()
    
    # Update global fonts list
    global FONTS_TO_USE
    FONTS_TO_USE = available_fonts[:2] if len(available_fonts) >= 2 else available_fonts
    
    # Character sets
    characters = {
        'uppercase': list('ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
        'lowercase': list('abcdefghijklmnopqrstuvwxyz'),
        'numbers': list('0123456789'),
    }
    
    total_chars = sum(len(chars) for chars in characters.values())
    total_templates = 0
    
    print(f"\nGenerating templates for {total_chars} characters...")
    print(f"Output directory: {OUTPUT_DIR.absolute()}\n")
    
    # Create output directory
    OUTPUT_DIR.mkdir(exist_ok=True)
    
    # Generate for each character set
    for category, char_list in characters.items():
        category_dir = OUTPUT_DIR / category
        category_dir.mkdir(exist_ok=True)
        
        print(f"\n📁 {category.upper()} ({len(char_list)} characters)")
        print("-" * 60)
        
        for char in char_list:
            char_dir = category_dir / char
            char_dir.mkdir(exist_ok=True)
            
            # Generate templates using different fonts
            template_num = 1
            
            for font_path, font_name in FONTS_TO_USE:
                # Create 5 variations per font (total 10 templates)
                variations = create_variations(char, font_path, num_variations=5)
                
                for i, img in enumerate(variations):
                    output_path = char_dir / f"t{template_num:02d}.png"
                    img.save(output_path, 'PNG', optimize=True)
                    template_num += 1
                    total_templates += 1
            
            # Calculate size
            char_size = sum(f.stat().st_size for f in char_dir.glob("*.png"))
            print(f"  ✓ {char}: {template_num-1} templates ({char_size/1024:.1f} KB)")
    
    # Summary
    total_size = sum(
        f.stat().st_size 
        for f in OUTPUT_DIR.rglob("*.png")
    )
    
    print("\n" + "=" * 60)
    print("GENERATION COMPLETE!")
    print("=" * 60)
    print(f"Total characters: {total_chars}")
    print(f"Total templates:  {total_templates}")
    print(f"Total size:       {total_size / 1024 / 1024:.2f} MB")
    print(f"Avg per template: {total_size / total_templates / 1024:.2f} KB")
    print(f"Output directory: {OUTPUT_DIR.absolute()}")
    print("=" * 60)
    
    return True

def test_template_quality():
    """Test a few templates to ensure quality"""
    print("\n🧪 Testing template quality...")
    
    test_chars = ['A', 'a', '5']
    
    for char in test_chars:
        # Find the character
        for category_dir in OUTPUT_DIR.iterdir():
            if not category_dir.is_dir():
                continue
            char_dir = category_dir / char
            if char_dir.exists():
                templates = list(char_dir.glob("*.png"))
                if templates:
                    img = Image.open(templates[0])
                    arr = np.array(img)
                    
                    # Check if it's not empty
                    non_white_pixels = np.sum(arr < 250)
                    coverage = non_white_pixels / (IMG_SIZE * IMG_SIZE)
                    
                    print(f"  {char}: {len(templates)} templates, "
                          f"coverage={coverage:.2%}, size={img.size}")

if __name__ == "__main__":
    try:
        # Generate all templates
        success = generate_all_templates()
        
        if success:
            # Test quality
            test_template_quality()
            
            print("\n✅ All done! Templates are ready to use.")
            print("   Copy the 'templates/' folder to your Flutter assets directory.")
    
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

