# Base image with minimal dependencies
FROM ubuntu:20.04

# Set DEBIAN_FRONTEND to noninteractive to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# "13114758" as of 2025/07/20
ENV ANDROID_SDK_TOOLS_VERSION="13114758"
# ENV NDK_VERSION="26.2.11394342"

# Environment variables for Flutter and FVM
ENV PATH="$PATH:/fvm/default/bin"
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin"
# Update package lists and install core dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    zip \
    wget \
    openjdk-17-jdk \
    ruby \
    ruby-dev \
    build-essential \
    apt-transport-https \
    ca-certificates \
    gnupg \
    jq

# Set JAVA_HOME to OpenJDK 17
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install Bundler for Ruby
RUN gem install bundler -v 2.4.22

# Install Flutter Version Manager (FVM)
RUN curl -fsSL https://fvm.app/install.sh | bash

# Add FVM to PATH
ENV PATH="$PATH:/root/.pub-cache/bin"

# Default Flutter version (hardcoded to 3.24.5)
ARG FLUTTER_VERSION=3.24.5
RUN fvm install $FLUTTER_VERSION && fvm global $FLUTTER_VERSION

# Install Android SDK command-line tools
RUN wget --quiet --output-document=sdk-tools.zip \
    "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip"

RUN mkdir -p "$ANDROID_HOME" && \
    unzip -q sdk-tools.zip -d "$ANDROID_HOME" && \
    cd "$ANDROID_HOME" && \
    mv cmdline-tools latest && \
    mkdir cmdline-tools && \
    mv latest cmdline-tools

# Validate SDK tools
RUN ls -l $ANDROID_HOME/cmdline-tools/latest/bin && chmod +x $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager

# Accept Android SDK licenses
RUN yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

# Install necessary Android SDK components
RUN $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-30" \
    "platforms;android-31" \
    "platforms;android-32" \
    "platforms;android-33" \
    "platforms;android-34" \
    "platforms;android-35" \
    "build-tools;30.0.3" \
    "build-tools;31.0.0" \
    "build-tools;32.0.0" \
    "build-tools;33.0.0" \
    "build-tools;34.0.0" \
    "build-tools;35.0.0" \
    "build-tools;36.0.0" 
    # "ndk;${NDK_VERSION}"

# Install Google Cloud SDK
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update -y && \
    apt-get install -y google-cloud-sdk

# Validate Flutter installation
RUN fvm flutter doctor

# Accept licenses for Flutter
RUN yes | fvm flutter doctor --android-licenses

# Validate all installations
RUN ruby --version && \
    bundler --version && \
    gcloud --version && \
    fvm flutter --version && \
    fvm dart --version

# Clean up unnecessary files to reduce image size
RUN rm -rf /var/lib/apt/lists/* sdk-tools.zip

# Set the working directory
WORKDIR /app

# Default command
CMD ["/bin/bash"]
