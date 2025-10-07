FROM ghcr.io/cirruslabs/flutter:stable

WORKDIR /app

# Pre-warm pub cache with pubspec to speed up first run
COPY pubspec.yaml ./
RUN flutter pub get || true

# Copy the rest of the project
COPY . .

RUN flutter pub get

# Default command prints environment diagnostics
CMD ["bash", "-lc", "flutter doctor -v"]


