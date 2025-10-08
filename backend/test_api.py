#!/usr/bin/env python3
"""
Test script za LookWriteLearn Backend API
"""
import requests
import base64
from PIL import Image, ImageDraw, ImageFont
import io
import json

def create_test_image(letter='A', quality='good'):
    """
    Kreira test sliku sa slovom
    quality: 'good', 'medium', 'poor'
    """
    # Kreiraj belu pozadinu
    img = Image.new('RGB', (400, 400), color='white')
    draw = ImageDraw.Draw(img)
    
    if quality == 'good':
        # Dobro nacrtano slovo
        try:
            font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 280)
        except:
            font = ImageFont.load_default()
        draw.text((70, 30), letter, fill='black', font=font)
        
    elif quality == 'medium':
        # Srednje nacrtano slovo (malo iskrivljeno)
        try:
            font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 250)
        except:
            font = ImageFont.load_default()
        draw.text((80, 50), letter, fill='gray', font=font)
        # Dodaj malo "suma"
        draw.ellipse([50, 50, 70, 70], fill='lightgray')
        
    else:  # poor
        # Loše nacrtano slovo (vrlo malo)
        try:
            font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 100)
        except:
            font = ImageFont.load_default()
        draw.text((150, 200), letter, fill='lightgray', font=font)
    
    return img

def image_to_base64(img):
    """Konvertuje PIL Image u base64 string"""
    buffered = io.BytesIO()
    img.save(buffered, format="PNG")
    img_bytes = buffered.getvalue()
    img_base64 = base64.b64encode(img_bytes).decode()
    return f"data:image/png;base64,{img_base64}"

def test_backend(api_url='http://localhost:5001'):
    """Testira backend API sa različitim test slučajevima"""
    
    print("=" * 60)
    print("🧪 TESTIRANJE LOOKWRITELEARN BACKEND API")
    print("=" * 60)
    
    # Test 1: Health check
    print("\n📊 Test 1: Health Check")
    print("-" * 60)
    try:
        response = requests.get(f"{api_url}/health", timeout=5)
        if response.status_code == 200:
            print("✅ Health check PASSED")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health check FAILED: Status {response.status_code}")
            return
    except Exception as e:
        print(f"❌ Health check FAILED: {e}")
        return
    
    # Test 2-4: Compare drawings sa različitim kvalitetima
    test_cases = [
        ('A', 'good', "Dobro nacrtano slovo A"),
        ('B', 'medium', "Srednje nacrtano slovo B"),
        ('C', 'poor', "Loše nacrtano slovo C"),
    ]
    
    for i, (letter, quality, description) in enumerate(test_cases, start=2):
        print(f"\n📊 Test {i}: {description}")
        print("-" * 60)
        
        # Kreiraj test sliku
        img = create_test_image(letter, quality)
        img_base64 = image_to_base64(img)
        
        # Sačuvaj test sliku
        img.save(f'/tmp/test_{letter}_{quality}.png')
        print(f"   💾 Test slika sačuvana: /tmp/test_{letter}_{quality}.png")
        
        # Pošalji na API
        try:
            payload = {
                'image': img_base64,
                'letter': letter,
                'mode': 'upper'
            }
            
            response = requests.post(
                f"{api_url}/api/compare",
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                score = result['score']
                feedback = result['feedback']
                accuracy = result['details']['accuracy']
                tips = result['details']['tips']
                
                print(f"   ✅ API Response PASSED")
                print(f"   📈 Score: {score}%")
                print(f"   💬 Feedback: {feedback}")
                print(f"   🎯 Accuracy: {accuracy}")
                print(f"   💡 Tips: {', '.join(tips)}")
                
                # Očekivani rezultati
                if quality == 'good' and score >= 70:
                    print(f"   ✅ Score validation PASSED (očekivano >=70%)")
                elif quality == 'medium' and 40 <= score < 80:
                    print(f"   ✅ Score validation PASSED (očekivano 40-80%)")
                elif quality == 'poor' and score < 60:
                    print(f"   ✅ Score validation PASSED (očekivano <60%)")
                else:
                    print(f"   ⚠️  Score je {score}% za {quality} kvalitet")
                    
            else:
                print(f"   ❌ API Response FAILED: Status {response.status_code}")
                print(f"   Response: {response.text}")
                
        except Exception as e:
            print(f"   ❌ Request FAILED: {e}")
    
    # Test 5: Invalid request (bez image parametra)
    print(f"\n📊 Test 5: Invalid request (bez image parametra)")
    print("-" * 60)
    try:
        payload = {
            'letter': 'A',
            'mode': 'upper'
        }
        response = requests.post(f"{api_url}/api/compare", json=payload, timeout=5)
        
        if response.status_code == 400:
            print(f"   ✅ Error handling PASSED (očekivano 400)")
            print(f"   Response: {response.json()}")
        else:
            print(f"   ⚠️  Unexpected status: {response.status_code}")
            
    except Exception as e:
        print(f"   ❌ Request FAILED: {e}")
    
    # Test 6: Different modes
    print(f"\n📊 Test 6: Različiti modovi (upper, lower, number)")
    print("-" * 60)
    modes_test = [
        ('A', 'upper', 'Veliko slovo'),
        ('a', 'lower', 'Malo slovo'),
        ('5', 'number', 'Broj'),
    ]
    
    for letter, mode, desc in modes_test:
        img = create_test_image(letter, 'good')
        img_base64 = image_to_base64(img)
        
        try:
            payload = {
                'image': img_base64,
                'letter': letter,
                'mode': mode
            }
            response = requests.post(f"{api_url}/api/compare", json=payload, timeout=10)
            
            if response.status_code == 200:
                result = response.json()
                print(f"   ✅ {desc} ({letter}): Score {result['score']}%")
            else:
                print(f"   ❌ {desc} FAILED: {response.status_code}")
                
        except Exception as e:
            print(f"   ❌ {desc} FAILED: {e}")
    
    print("\n" + "=" * 60)
    print("✅ TESTIRANJE ZAVRŠENO!")
    print("=" * 60)

if __name__ == '__main__':
    test_backend()
