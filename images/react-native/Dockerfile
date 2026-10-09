# React Native apps: the CocoaPods image for the iOS pods, Node.js for the JavaScript packages, which the Podfile and
# the Gradle build run too, and JDK 17 with the Android SDK and build tools for the Android dependencies
FROM node AS node
FROM android AS android

FROM cocoapods

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
ENV COREPACK_HOME=/cache/corepack COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN set -ex; \
    ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm; \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx; \
    ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack; \
    corepack enable --install-directory /usr/local/bin yarn pnpm
COPY --from=android /opt/java/openjdk /opt/java/openjdk
COPY --from=android /opt/android-sdk /opt/android-sdk
# React Native runs xcodebuild and command while it installs the pods, which Linux lacks
COPY --chmod=755 bin/ /opt/react-native/bin/
COPY --chmod=755 licensed-react-native-setup /usr/local/bin/

ENV JAVA_HOME=/opt/java/openjdk \
    ANDROID_HOME=/opt/android-sdk \
    LICENSED_CACHE_LINKS=/opt/android-sdk/ndk \
    LICENSED_SETUP=licensed-react-native-setup
ENV PATH=$JAVA_HOME/bin:/opt/react-native/bin:$PATH
