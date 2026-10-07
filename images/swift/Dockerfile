ARG SWIFT_VERSION=6.2

FROM debian:trixie-slim AS toolchain

ARG SWIFT_VERSION
ARG TARGETARCH
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl; \
    platform="debian12$([ "$TARGETARCH" = arm64 ] && echo -aarch64 || true)"; \
    mkdir /opt/swift; \
    curl -fsSL "https://download.swift.org/swift-${SWIFT_VERSION}-release/${platform}/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-${platform}.tar.gz" \
      | tar -xz --strip-components=1 -C /opt/swift; \
    # licensed only runs swift package, the debugger, editor and documentation tools are dropped
    cd /opt/swift/usr; \
    rm -rf bin/lldb* lib/liblldb* bin/sourcekit-lsp lib/libsourcekitdInProc* bin/clangd bin/docc lib/swift_static share/doc

FROM base

# SwiftPM compiles Package.swift before describing it, so the toolchain needs a C library and a linker
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends binutils libc6-dev libgcc-14-dev libstdc++-14-dev libcurl4-openssl-dev libxml2-dev libedit-dev libsqlite3-dev libncurses-dev zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*

COPY --from=toolchain /opt/swift /opt/swift
ENV PATH=/opt/swift/usr/bin:$PATH
