ARG COCOAPODS_VERSION=1.16.2

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

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl rsync unzip; \
    rm -rf /var/lib/apt/lists/*

COPY --from=gems /var/lib/gems /var/lib/gems
COPY --from=gems /usr/local/bin/pod /usr/local/bin/pod
# The container runs as root, which CocoaPods refuses by default
ENV COCOAPODS_ALLOW_ROOT=1
