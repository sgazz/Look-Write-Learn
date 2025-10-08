# 🎨 LookWriteLearn - Backend Setup

Backend API za prepoznavanje i ocenjivanje crteža slova.

## 🚀 Brzo pokretanje

```bash
# Pokreni backend servis
docker-compose up -d backend

# Proveri status
curl http://localhost:5001/health
```

## 📊 API Dokumentacija

### 🔍 Health Check
```bash
GET http://localhost:5001/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "LookWriteLearn Backend",
  "version": "1.0.0"
}
```

### 🎯 Compare Drawing
```bash
POST http://localhost:5001/api/compare
Content-Type: application/json
```

**Request Body:**
```json
{
  "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgA...",
  "letter": "A",
  "mode": "upper"
}
```

**Response:**
```json
{
  "score": 85,
  "feedback": "Super! Veoma dobro! 👏🎉",
  "letter": "A",
  "details": {
    "accuracy": "good",
    "tips": [
      "Nastavi vežbati i biće još bolje!"
    ]
  }
}
```

## 📁 Struktura Projekta

```
backend/
├── app.py              # Flask API server
├── requirements.txt    # Python dependencies
├── Dockerfile         # Docker image config
├── .dockerignore      # Docker ignore patterns
└── README.md          # Backend dokumentacija
```

## 🧠 Kako Radi Backend

### 1. Image Processing Pipeline

```python
User Drawing (PNG) 
    ↓
Base64 Decode 
    ↓
OpenCV Processing
    ↓
Analysis (edges, contours, coverage)
    ↓
Scoring Algorithm
    ↓
Feedback Response
```

### 2. Scoring Algoritam

Backend koristi više tehnika za ocenjivanje:

- **Coverage Analysis** - Koliko je canvas-a popunjeno
- **Contour Detection** - Analiza oblika crteža
- **Solidity** - Koliko je oblik "solidan"
- **Aspect Ratio** - Odnos širine i visine
- **Letter-Specific Rules** - Pravila specifična za svako slovo

### 3. Feedback Sistem

| Score Range | Nivo | Feedback |
|-------------|------|----------|
| 90-100% | Excellent | "Odlično! Savršeno si napisao/la slovo! 🌟✨" |
| 80-89% | Good | "Super! Veoma dobro! 👏🎉" |
| 70-79% | Fair | "Bravo! Nastavi tako! 💪😊" |
| 60-69% | Needs Practice | "Dobro! Vežbaj još malo! 👍" |
| 50-59% | Try Again | "Pokušaj ponovo! Možeš bolje! 🎯" |
| <50% | Keep Trying | "Polako! Prati model slovo! 💡" |

## 🔧 Development

### Lokalno Pokretanje (bez Docker-a)

```bash
cd backend

# Kreiraj virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# ili
venv\Scripts\activate  # Windows

# Instaliraj dependencies
pip install -r requirements.txt

# Pokreni server
python app.py
```

Server će biti dostupan na: `http://localhost:5000`

### Docker Pokretanje

```bash
# Build image
docker-compose build backend

# Pokreni container
docker-compose up -d backend

# Prati logove
docker-compose logs -f backend

# Zaustavi container
docker-compose stop backend
```

## 🧪 Testiranje

### Curl Test

```bash
# Health check
curl http://localhost:5001/health

# Test sa primerom
curl -X POST http://localhost:5001/api/compare \
  -H "Content-Type: application/json" \
  -d '{
    "image": "data:image/png;base64,iVBORw0KGgo...",
    "letter": "A",
    "mode": "upper"
  }'
```

### Python Test Script

```python
import requests
import base64

# Učitaj sliku
with open('test_drawing.png', 'rb') as f:
    image_data = base64.b64encode(f.read()).decode()

# Pošalji na API
response = requests.post(
    'http://localhost:5001/api/compare',
    json={
        'image': f'data:image/png;base64,{image_data}',
        'letter': 'A',
        'mode': 'upper'
    }
)

print(response.json())
```

## 🔐 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLASK_ENV` | `development` | Flask environment |
| `PYTHONUNBUFFERED` | `1` | Python output buffering |

## 🐛 Troubleshooting

### Problem: Port 5001 je zauzet

```bash
# Proveri koji proces koristi port
lsof -i :5001  # Linux/Mac
netstat -ano | findstr :5001  # Windows

# Promeni port u docker-compose.yml
ports:
  - "5002:5000"  # Mapira host port 5002 na container port 5000
```

### Problem: Container se ne pokreće

```bash
# Proveri logove
docker-compose logs backend

# Rebuild image
docker-compose build --no-cache backend
docker-compose up -d backend
```

### Problem: OpenCV greške

Ako dobijaš greške vezane za OpenCV biblioteke:

```bash
# Rebuild sa svim dependencies
docker-compose build --no-cache backend
```

## 📦 Dependencies

- **Flask 3.0.0** - Web framework
- **Flask-CORS 4.0.0** - Cross-Origin Resource Sharing
- **OpenCV 4.8.1** - Computer vision library
- **Pillow 10.1.0** - Python Imaging Library
- **NumPy 1.26.2** - Numerical computing
- **Gunicorn 21.2.0** - Production WSGI server

## 🚀 Deployment

Za produkciju, koristi Gunicorn umesto Flask development servera:

```bash
# U Dockerfile, zameni CMD sa:
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

## 🎯 Sledeći Koraci

1. **Machine Learning Integration**
   - Treniraj model sa pravim crtežima dece
   - Koristi CNN za bolje prepoznavanje

2. **Advanced Features**
   - Stroke order detection
   - Real-time feedback tokom crtanja
   - Analiza brzine crtanja

3. **Performance Optimizations**
   - Caching frequently requested letters
   - Async processing za velike slike
   - Redis za session storage

## 📄 Licenca

MIT License - Slobodno koristi i menjaj!

---

**Napravljeno sa ❤️ za decu koja uče da pišu!**
