# Base image with licensed and licensee, repositories extend it with their ecosystem toolchain

ARG LICENSED_VERSION=5.1.0
ARG LICENSEE_VERSION=9.20.0

FROM golang:1.26-trixie AS deduplicate

ARG DEDUPLICATE_VERSION=v1.0.0
RUN CGO_ENABLED=0 GOBIN=/out go install "github.com/arduino/licensed-notice-deduplicate@${DEDUPLICATE_VERSION}"

FROM debian:trixie-slim AS builder

ARG LICENSED_VERSION
ARG LICENSEE_VERSION

# rugged, a licensee dependency, needs to be compiled
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential cmake pkg-config patch ruby-full ruby-dev libssl-dev zlib1g-dev libzstd-dev; \
    gem install --no-document licensee -v "${LICENSEE_VERSION}"; \
    gem install --no-document licensed -v "${LICENSED_VERSION}"; \
    rm -rf /var/lib/gems/*/cache /var/lib/gems/*/gems/rugged-*/vendor /var/lib/gems/*/gems/rugged-*/ext

# Each patch fixes a licensed source, see its header
COPY patches /patches
RUN for p in /patches/*.patch; do patch -p1 --forward -d /var/lib/gems/*/gems/licensed-${LICENSED_VERSION} < "$p" || exit 1; done

FROM debian:trixie-slim

ARG LICENSED_VERSION
LABEL org.opencontainers.image.source="https://github.com/robgee86/licensed-action" \
      org.opencontainers.image.description="licensed ${LICENSED_VERSION} with the fixes under patches/" \
      io.github.licensee.licensed.version="${LICENSED_VERSION}"

# Ecosystem caches point inside /cache, the directory the action persists between runs
ENV LANG=C.UTF-8 \
    GOMODCACHE=/cache/go/mod \
    GOCACHE=/cache/go/build \
    npm_config_cache=/cache/npm \
    YARN_CACHE_FOLDER=/cache/yarn \
    GRADLE_USER_HOME=/cache/gradle \
    CP_HOME_DIR=/cache/cocoapods \
    UV_CACHE_DIR=/cache/uv \
    PIP_CACHE_DIR=/cache/pip

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates git ruby libssl3t64 zlib1g libzstd1; \
    rm -rf /var/lib/apt/lists/*; \
    git config --system --add safe.directory '*'

COPY --from=builder /var/lib/gems /var/lib/gems
COPY --from=builder /usr/local/bin/licensed /usr/local/bin/licensed
COPY --from=deduplicate /out/licensed-notice-deduplicate /usr/local/bin/licensed-notice-deduplicate
COPY --chmod=755 entrypoint.sh /usr/local/bin/licensed-action
COPY --chmod=755 notices.sh /usr/local/bin/licensed-notices
COPY --chmod=755 check.sh /usr/local/bin/licensed-check

WORKDIR /src

# Images extending this one keep the entrypoint and set their default command with CMD
ENTRYPOINT ["licensed-action"]
