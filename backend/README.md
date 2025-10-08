# LookWriteLearn Backend

Backend API za prepoznavanje i ocenjivanje crteža slova.

## Funkcionalnost

- ✅ Prepoznavanje crteža korisnika
- ✅ Poređenje sa model slovima
- ✅ Ocenjivanje (0-100%)
- ✅ Povratne informacije na srpskom jeziku
- ✅ Saveti za poboljšanje

## API Endpoints

### Health Check
```
GET /health
```

Response:
```json
{
  "status": "healthy",
  "service": "LookWriteLearn Backend",
  "version": "1.0.0"
}
```

### Compare Drawing
```
POST /api/compare
```

Request Body:
```json
{
  "image": "data:image/png;base64,...",
  "letter": "A",
  "mode": "upper"
}
```

Response:
```json
{
  "score": 85,
  "feedback": "Super! Veoma dobro! 👏🎉",
  "letter": "A",
  "details": {
    "accuracy": "good",
    "tips": ["Nastavi vežbati i biće još bolje!"]
  }
}
```

## Lokalno Pokretanje

```bash
# Instaliraj dependencies
pip install -r requirements.txt

# Pokreni server
python app.py
```

Server će biti dostupan na: `http://localhost:5000`

## Docker Pokretanje

```bash
# Build image
docker build -t lookwritelearn-backend .

# Run container
docker run -p 5000:5000 lookwritelearn-backend
```

## Tehnologije

- **Flask** - Web framework
- **OpenCV** - Image processing
- **NumPy** - Numerical operations
- **Pillow** - Image handling
