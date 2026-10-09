# React Native apps: Node.js for the JavaScript packages, which the Podfile and the Gradle build run too, CocoaPods
# for the iOS pods, and JDK 17 with the Android SDK and build tools for the Android dependencies
FROM android AS android
FROM cocoapods AS cocoapods

FROM node

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl rsync unzip; \
    rm -rf /var/lib/apt/lists/*
COPY --from=cocoapods /var/lib/gems /var/lib/gems
COPY --from=cocoapods /usr/local/bin/pod /usr/local/bin/pod
COPY --from=android /opt/java/openjdk /opt/java/openjdk
COPY --from=android /opt/android-sdk /opt/android-sdk
# React Native runs xcodebuild and command while it installs the pods, which Linux lacks
COPY --chmod=755 bin/ /opt/react-native/bin/
COPY --chmod=755 licensed-react-native-setup /usr/local/bin/

ENV JAVA_HOME=/opt/java/openjdk \
    ANDROID_HOME=/opt/android-sdk \
    COCOAPODS_ALLOW_ROOT=1 \
    LICENSED_CACHE_LINKS=/opt/android-sdk/ndk \
    LICENSED_SETUP=licensed-react-native-setup
ENV PATH=$JAVA_HOME/bin:/opt/react-native/bin:$PATH
