# LookWriteLearn

Minimal Flutter app for kids to practice handwriting letters and numbers.

## Features
- Large drawing canvas with pen support
- Toggle uppercase/lowercase and numbers
- Guide letter overlay in a freehand-style font (Google Fonts: Caveat)
- Color picker, stroke width slider, Clear button
- Runs on Android, iOS, macOS, Linux, Windows (and Flutter web/dev if needed)

## Docker Development
Prerequisites: Docker and docker-compose.

Build and open a shell:
```bash
docker compose build
docker compose run --rm flutter bash
```

Inside the container, run Flutter doctor and get packages:
```bash
flutter doctor -v
flutter pub get
```

### Running
- Mobile/Desktop builds require platform SDKs/tools on the host; Docker is best for dependency consistency and CI tasks. On macOS for iOS, you still need Xcode on host.
- For quick web preview (dev only):
```bash
flutter run -d web-server --web-port 8080 --web-renderer canvaskit
```
Then open `http://localhost:8080`.

### Notes
- Volumes are mounted, so your edits on host are reflected in the container.
- CI can reuse this image to run `flutter analyze`, tests, and web builds.

## License
MIT
