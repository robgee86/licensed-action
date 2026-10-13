ARG COCOAPODS_VERSION=1.16.2
ARG MISE_VERSION=2026.10.5

FROM base AS gems

ARG COCOAPODS_VERSION
# licensed enumerates pods through the cocoapods-dependencies-list plugin, ffi needs to be compiled
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential patch ruby-dev; \
    gem install --no-document cocoapods -v "${COCOAPODS_VERSION}"; \
    gem install --no-document cocoapods-dependencies-list

COPY dependencies-list-version.patch /tmp/
RUN patch -p1 --forward -d /var/lib/gems/*/gems/cocoapods-dependencies-list-1.0.0 < /tmp/dependencies-list-version.patch

FROM base

ARG MISE_VERSION
ARG TARGETARCH
# A compiler and the Ruby headers for the native gems of a repository bundle, mise, which installs the Ruby of its
# .ruby-version, and the unversioned bundle command of the image's Ruby, for a repository that pins no Ruby
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl rsync unzip build-essential ruby-dev libssl-dev libyaml-dev zlib1g-dev libffi-dev; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSLo /usr/local/bin/mise "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-$([ "$TARGETARCH" = arm64 ] && echo arm64 || echo x64)"; \
    chmod +x /usr/local/bin/mise; \
    ln -s "$(ls /usr/bin/bundle3.*)" /usr/local/bin/bundle

COPY --from=gems /var/lib/gems /var/lib/gems
COPY --from=gems /usr/local/bin/pod /usr/local/bin/pod
COPY dependencies-list-loader.rb /opt/licensed/cocoapods/dependencies-list-loader.rb
COPY --chmod=755 licensed-setup-guard /usr/local/bin/licensed-setup-guard
COPY compare-podfile-lock.rb /opt/licensed/cocoapods/compare-podfile-lock.rb

# mise keeps its tools in the cache and its shims pick the version of a .ruby-version, the image's Ruby otherwise. The
# ruby line of a Gemfile is a requirement Bundler checks, such as the >= 2.6.10 of the React Native template, not a
# version for mise to install
ENV MISE_DATA_DIR=/cache/mise \
    MISE_IDIOMATIC_VERSION_FILE_ENABLE_TOOLS=ruby \
    MISE_IDIOMATIC_VERSION_FILE_DISABLE_FILES=ruby:Gemfile \
    MISE_YES=1 \
    LICENSED_COCOAPODS_PRELOAD=/opt/licensed/cocoapods/dependencies-list-loader.rb
ENV PATH=/cache/mise/shims:$PATH
# The container runs as root, which CocoaPods refuses by default
ENV COCOAPODS_ALLOW_ROOT=1
