ARG GO_VERSION=1.26

FROM golang:${GO_VERSION}-trixie AS go

FROM ghcr.io/robgee86/licensed-action:v0

COPY --from=go /usr/local/go /usr/local/go
# GOPRIVATE lists the private module paths the github-token input reaches
ENV PATH=/usr/local/go/bin:$PATH GOPRIVATE=github.com/your-org
