ARG NODE_VERSION=24

FROM node:${NODE_VERSION}-trixie-slim AS node

FROM base

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
# corepack provides the yarn and pnpm versions a package.json asks for, caching them in /cache
ENV COREPACK_HOME=/cache/corepack COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN set -ex; \
    ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm; \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx; \
    ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack; \
    corepack enable --install-directory /usr/local/bin yarn pnpm
