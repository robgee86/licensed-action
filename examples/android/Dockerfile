# The JDK the Android Gradle plugin needs and every SDK package it would otherwise install itself, printing to the
# output licensed parses: the platform matching compileSdk, plus build-tools and platform-tools for older plugins
ARG JDK=17
ARG SDK_PACKAGES="platforms;android-36"

FROM eclipse-temurin:${JDK}-jdk AS jdk

# sdkmanager needs JDK 17 whatever the project uses, so the SDK is installed apart
FROM eclipse-temurin:17-jdk AS sdk

ARG SDK_PACKAGES
ARG CMDLINE_TOOLS=13114758
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip; \
    curl -fsSLo /tmp/tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS}_latest.zip"; \
    unzip -q /tmp/tools.zip -d /tmp; \
    yes | /tmp/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk --licenses > /dev/null; \
    /tmp/cmdline-tools/bin/sdkmanager --sdk_root=/opt/android-sdk ${SDK_PACKAGES}

FROM ghcr.io/robgee86/licensed-action:v0

COPY --from=jdk /opt/java/openjdk /opt/java/openjdk
COPY --from=sdk /opt/android-sdk /opt/android-sdk
ENV JAVA_HOME=/opt/java/openjdk ANDROID_HOME=/opt/android-sdk
ENV PATH=$JAVA_HOME/bin:$PATH
