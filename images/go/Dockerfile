ARG GO_VERSION=1.26

FROM golang:${GO_VERSION}-trixie AS go

FROM base

# Go fetches the toolchain a go.mod asks for into the module cache, so this one serves any version
COPY --from=go /usr/local/go /usr/local/go
ENV PATH=/usr/local/go/bin:$PATH
