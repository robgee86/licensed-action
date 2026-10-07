ARG PYTHON_VERSION=3.13

FROM ghcr.io/astral-sh/uv:0.12.21@sha256:a7aed3216253ee804de3e2d8afa5073baa1a177335345d43845cd4165e43b711 AS uv

FROM ghcr.io/robgee86/licensed-action:v0

ARG PYTHON_VERSION
ENV UV_PYTHON_INSTALL_DIR=/opt/python UV_PYTHON_BIN_DIR=/usr/local/bin

COPY --from=uv /uv /usr/local/bin/uv

# Compilers serve the packages that ship no wheel, add the headers they need
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential pkg-config; \
    rm -rf /var/lib/apt/lists/*; \
    uv python install --default "${PYTHON_VERSION}"

ENV UV_PYTHON_DOWNLOADS=never
