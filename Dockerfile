FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:99
ENV WINEPREFIX=/wine-prefix
ENV WINEDLLOVERRIDES="mscoree,mshtml="

# Install essential tools (no Wine needed - Proton includes it)
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    zip \
    tar \
    xvfb \
    cabextract \
    p7zip-full \
    python3 \
    python3-pip \
    uuid-runtime \
    && rm -rf /var/lib/apt/lists/*

# Install Winetricks (will use Proton's Wine)
RUN wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/local/bin/winetricks

# Create directories
RUN mkdir -p /wine-prefix /scripts /output

# Copy build scripts
COPY docker-scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/scripts/build-prefix.sh"]