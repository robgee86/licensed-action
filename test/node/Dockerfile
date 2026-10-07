# Built on edge, so main tests the image it just published
FROM node:24-trixie-slim AS node

FROM ghcr.io/robgee86/licensed-action:edge

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
