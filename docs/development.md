# Development

## Building

`docker buildx bake --load` builds every image tagged `local`, and `docker buildx bake --load go` only the base and the Go images. Each ecosystem image builds on the base image of the same build, see [docker-bake.hcl](../docker-bake.hcl).

## Testing

The [test](../.github/workflows/test.yml) workflow builds the images of each commit and runs the action on the fixtures under [test](../test), on amd64 and arm64. It also checks that a missing or stale record and an outdated NOTICE file fail the action.

To run a fixture by hand, from the root of this repository:

```sh
LICENSED_WORKING_DIRECTORY=test/go LICENSED_IMAGE=ghcr.io/robgee86/licensed-go:local scripts/run.sh licensed-check
```

## Releasing

[release-please](https://github.com/googleapis/release-please) keeps a release pull request open from the Conventional Commits on main. Merging it tags `vX.Y.Z`, publishes every image as `vX.Y.Z`, `vX.Y` and `vX`, then moves the `vX` and `vX.Y` git tags, so `@vX` users get the action and its images together. Each action release runs the exact image version it was released with.
