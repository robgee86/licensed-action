# licensed-action

Checks dependency licenses with [licensed](https://github.com/licensee/licensed) inside Docker, so the same image runs on developer machines and in CI, for any ecosystem licensed supports.

licensed runs each ecosystem's own tools (`go list`, `npm list`, `pip`, Gradle, `pod`, `swift package`), so the scan needs those tools and the installed dependencies. This repository publishes them as images, for amd64 and arm64:

| Image | Adds to the base image |
| --- | --- |
| `ghcr.io/robgee86/licensed-action` | licensed, licensee and the [fixes](#patched-licensed) the upstream release lacks |
| `ghcr.io/robgee86/licensed-go-action` | Go, which can fetch the newer toolchain a `go.mod` asks for |
| `ghcr.io/robgee86/licensed-node-action` | Node.js and npm, with yarn and pnpm shims through corepack, validated with npm only |
| `ghcr.io/robgee86/licensed-python-action` | uv, Python 3.13 and a C toolchain, uv can download another Python on each run |
| `ghcr.io/robgee86/licensed-gradle-action` | JDK 17 and the Android SDK |
| `ghcr.io/robgee86/licensed-cocoapods-action` | CocoaPods with the cocoapods-dependencies-list plugin |
| `ghcr.io/robgee86/licensed-swift-action` | The Swift toolchain |

All images share the version of the action that runs them.

## Usage

```yaml
jobs:
  licenses:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: robgee86/licensed-action@v0
        with:
          ecosystem: go
          cache-key-files: go.sum
```

The action restores the cache directory, runs `licensed-check` in the image, and reports the problems as annotations and a step summary. It checks the committed records with `licensed status`, without rewriting them, failing on a missing or outdated record, a license outside the allowed list, or a record of a removed dependency. That last check needs `stale_records_action: error` in the licensed configuration, licensed only warns otherwise. When the repository commits [NOTICE files](#notices), it also fails on one that no longer matches the records.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `ecosystem` | | Image to run, `go`, `node`, `python`, `gradle`, `cocoapods` or `swift`, the base image when empty |
| `dockerfile` | | Dockerfile extending one of the images, built and run in place of the ecosystem image |
| `context` | `.` | Build context of the dockerfile |
| `working-directory` | `.` | Folder holding the licensed configuration, relative to the workspace |
| `setup` | | Shell commands run in the container before licensed, such as `npm ci` or `pod install`, replacing the `LICENSED_SETUP` of the image |
| `cache-key-files` | | Newline separated globs of the files whose content keys the cache, caching is off when empty |
| `github-token` | | Token for private dependencies hosted on GitHub |

## Ecosystems

Each row was validated against real repositories and runs on a [test](test) fixture in CI, except CocoaPods, whose pods need an Xcode project.

| `ecosystem` | `setup` | `cache-key-files` | Notes |
| --- | --- | --- | --- |
| `go` | | `go.sum` | Generated code must exist, for example `go generate` as setup |
| `node` | `npm ci --ignore-scripts --omit=dev` | `package-lock.json` | |
| `python` | `UV_PROJECT_ENVIRONMENT=.venv uv sync --frozen --no-dev --no-install-project && uv pip install --python .venv pip` | `uv.lock` | licensed reads the venv set in `python.virtual_env_dir`, which needs pip |
| `gradle` | | `**/*.gradle*` | See [Gradle and Android](#gradle-and-android) |
| `cocoapods` | `pod install` | `Podfile.lock` | `pod install` also integrates the Xcode project in the working tree |
| `swift` | `swift package resolve` | `Package.resolved` | Only packages with a `Package.swift`, not Xcode projects |

### Gradle and Android

- Set `gradle.configurations` to the variant to scan, such as `releaseRuntimeClasspath`, the licensed defaults do not exist in Android projects.
- When the Gradle project is in a subfolder, set licensed's `root` to it, the Gradle plugin writes its report next to the Gradle root.
- Older Android Gradle plugins install the SDK packages they miss and print to the output licensed parses, a setup such as `./gradlew -q help` lets them do it first.
- A plugin that needs another JDK gets it from a Dockerfile extending the image, see below.

## Notices

Committing NOTICE files turns them on. The images write them with `licensed-notices`, which runs `licensed notices` and then [licensed-notice-deduplicate](https://github.com/arduino/licensed-notice-deduplicate), merging the packages that share a license text into one entry. A repository enables them once by running `licensed-notices` in the image, as in [local runs](#local-runs), and committing the NOTICE files it writes next to the records. From then on the default local run keeps them current and the action checks them, comparing them with fresh ones. Deleting them turns notices off.

## Extending an image

A repository that needs more than an image holds, such as system headers or its own preparation script, extends it with a Dockerfile and passes it as `dockerfile`. Setting `LICENSED_SETUP` in the image gives CI and local runs the same setup without repeating it:

```dockerfile
FROM ghcr.io/robgee86/licensed-python-action:v0

RUN apt-get update && apt-get install -y --no-install-recommends libasound2-dev && rm -rf /var/lib/apt/lists/*
COPY prepare.py /prepare.py
ENV LICENSED_SETUP=/prepare.py
```

The images run `licensed-action` as their entrypoint, which a Dockerfile keeps.

## The container

- The workspace is mounted at `/src/<folder name>`, so the app names licensed derives from folder names, and with them the records layout, match a native run. The commands run in `working-directory`, and as licensed resolves paths from the git repository root by default, a configuration in a subfolder sets `root: true`.
- `/cache` is the one directory kept between runs. The images already point the Go, npm, corepack, Yarn, Gradle, CocoaPods, uv and pip caches inside it. A repository can keep anything else there, such as virtual environments. What lives inside is up to the repository, and a stale cache must be safe to reuse, since a run restores the closest earlier cache when the key files changed.
- The entrypoint evaluates `LICENSED_SETUP`, so the variables it exports reach licensed, then runs its arguments, `licensed-check` in the action. Without arguments it runs `licensed cache`, `licensed-notices` when there are NOTICE files, and `licensed status`. On exit it hands the files created in the workspace and in `/cache` to the owner of the workspace, since the tools run as root.
- `github-token` reaches git through `GIT_CONFIG_*` variables, so private Go modules resolve without writing credentials anywhere.

## Local runs

The images run the same way on a developer machine, the action only adds the cache restore and the report. For example from a Taskfile, with the repository name written out since `basename` is missing on Windows:

```yaml
licenses:
  cmds:
    - docker run --rm -v "$PWD:/src/my-repo" -w /src/my-repo -v my-repo-licensed:/cache ghcr.io/robgee86/licensed-go-action:v0
```

Without arguments the image updates the records and the NOTICE files, and `licensed-check` after the image checks them as CI does. The cache volume keeps the tooling and dependency caches between runs, so later runs take seconds. A repository with its own Dockerfile builds it first with `docker build` and runs that image instead, `-e LICENSED_SETUP=...` passes the setup to an image that sets none.

## Patched licensed

The base image applies these [patches](images/base/patches) to licensed:

- **pip**: package folders are matched with PEP 503 name folding, so packages with dots in their names are found.
- **Gradle**: the configurations licensed copies keep the variant attributes, without which multi-module Android projects fail to resolve. Plain Java projects resolve as before.
- **Swift**: `Package.resolved` format version 2, written by Swift 5.6 and later, is read.

The CocoaPods image also patches the cocoapods-dependencies-list plugin, which recursed forever on pod versions with ActiveSupport 7.

## Development

`docker buildx bake --load` builds every image tagged `local`, `docker buildx bake --load go` only the base and the Go images. The [test](.github/workflows/test.yml) workflow builds the images of each commit and runs the action on the fixtures under [test](test), on both platforms.

## Releasing

[release-please](https://github.com/googleapis/release-please) keeps a release pull request open from the Conventional Commits on main. Merging it tags `vX.Y.Z`, publishes every image as `vX.Y.Z`, `vX.Y` and `vX`, then moves the `vX` and `vX.Y` git tags, so `@vX` users get the action and its images together. Each action release runs the exact image version it was released with.
