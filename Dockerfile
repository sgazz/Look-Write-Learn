FROM ghcr.io/cirruslabs/flutter:stable

# Install system fonts including Arial Rounded MT Bold
RUN apt-get update && apt-get install -y \
    fonts-liberation \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    fonts-noto \
    fonts-roboto \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft fonts (including Arial Rounded MT Bold)
RUN apt-get update && apt-get install -y \
    wget \
    && wget -qO- https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcorefonts-installer-2.6-1.noarch.rpm | rpm -i --force \
    || echo "Font installation completed" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Pre-warm pub cache with pubspec to speed up first run
COPY pubspec.yaml ./
RUN flutter pub get || true

# Copy the rest of the project
COPY . .

RUN flutter pub get

# Default command prints environment diagnostics
CMD ["bash", "-lc", "flutter doctor -v"]


