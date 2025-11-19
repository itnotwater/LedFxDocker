# Updated Shirom-based LedFx Dockerfile
FROM python:3.12-bookworm

WORKDIR /app

# Install essential Python tools
RUN pip install --upgrade pip wheel setuptools Cython lastversion

# Add armhf architecture for multi-arch Snapclient support
RUN dpkg --add-architecture armhf || true

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    git \
    libatlas3-base \
    libavformat59 \
    portaudio19-dev \
    avahi-daemon \
    pulseaudio \
    alsa-utils \
    libnss-mdns \
    wget \
    apt-utils \
    squeezelite \
    libavahi-client3:armhf \
    libavahi-common3:armhf \
    libvorbisidec1:armhf \
	libavahi-client3 \
    libavahi-common3 \
    libvorbisfile3 \
    libsoxr0 \
 && rm -rf /var/lib/apt/lists/*

# Configure Avahi for non-root use
RUN mkdir -p /etc/avahi-daemon \
 && echo '*' > /etc/mdns.allow \
 && sed -i "s/hosts:.*/hosts:          files mdns4 dns/g" /etc/nsswitch.conf \
 && printf "[server]\nenable-dbus=no\n" >> /etc/avahi-daemon/avahi-daemon.conf \
 && chmod 777 /etc/avahi-daemon/avahi-daemon.conf \
 && mkdir -p /var/run/avahi-daemon \
 && chown avahi:avahi /var/run/avahi-daemon \
 && chmod 777 /var/run/avahi-daemon

# Install LedFx from GitHub
RUN pip install git+https://github.com/LedFx/LedFx

# Add root to pulse-access group
RUN adduser root pulse-access || true

# Download and install Snapclient based on target platform
ARG TARGETPLATFORM
RUN if [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=armhf; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; \
    else ARCHITECTURE=amd64; fi && \
    lastversion download badaix/snapcast \
        --format assets \
        --filter "snapclient_.*_${ARCHITECTURE}_bookworm.deb" \
        -o snapclient.deb && \
    test -f snapclient.deb && \
    dpkg -i snapclient.deb || apt-get -f install -y && rm -f snapclient.deb
 
# Copy Shirom setup scripts
COPY setup-files/ /app/
RUN chmod a+rx /app/*.sh

# Use Shirom entrypoint
ENTRYPOINT ["./entrypoint.sh"]
