# licensed-action

Checks dependency licenses with [licensed](https://github.com/licensee/licensed) inside Docker, so the same image runs on developer machines and in CI, for any ecosystem licensed supports.

licensed runs each ecosystem's own tools (`go list`, `npm list`, `pip`, Gradle, `pod`, `swift package`), so the scan needs those tools and the installed dependencies. The action splits the job in two:

- A **base image**, `ghcr.io/robgee86/licensed-action:v0`, published from this repository. It holds licensed, licensee and the [fixes](#patched-licensed) the upstream release lacks, for amd64 and arm64.
- A **repository image**, a short Dockerfile in each repository that extends the base image with its toolchain. The [examples](examples) cover Go, Node, Python, Android, CocoaPods and SwiftPM.

## Usage

```yaml
jobs:
  licenses:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: robgee86/licensed-action@v0
        with:
          dockerfile: .github/licensed/Dockerfile
          cache-key-files: go.sum
```

The action builds the repository image with the GitHub Actions cache, restores the cache directory, runs `licensed cache` then `licensed status`, and reports the problems as annotations and a step summary. It fails when licensed reports a problem or when `licensed cache` changed a committed record.

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `dockerfile` | | Dockerfile extending the base image, the base image is used when empty |
| `context` | `.` | Build context of the dockerfile |
| `working-directory` | `.` | Folder holding the licensed configuration, relative to the workspace |
| `setup` | | Shell commands run in the container before licensed, such as `npm ci` or `pod install` |
| `command` | `licensed cache` + `licensed status` | Shell commands replacing the licensed run |
| `cache-key-files` | | Newline separated globs of the files whose content keys the cache, caching is off when empty |
| `github-token` | | Token for private dependencies hosted on GitHub |
| `outdated-records` | `error` | How records changed by `licensed cache` are reported, `error` or `warning` |
| `fix-hint` | `run licensed cache locally` | How developers fix the records, shown in the summary |

## The container

- The workspace is mounted at `/src/<folder name>`, so the app names licensed derives from folder names, and with them the records layout, match a native run. The commands run in `working-directory`, and as licensed resolves paths from the git repository root by default, a configuration in a subfolder sets `root: true`.
- `/cache` is the one directory kept between runs. The base image already points the Go, npm, Yarn, Gradle, CocoaPods, uv and pip caches inside it. A repository can keep anything else there, such as virtual environments. What lives inside is up to the repository, and a stale cache must be safe to reuse, since a run restores the closest earlier cache when the key files changed.
- `github-token` reaches git through `GIT_CONFIG_*` variables, so private Go modules resolve without writing credentials anywhere. The repository image sets `GOPRIVATE`.
- The tools run as root, and the files they create in the workspace and in `/cache` are handed back to the runner user at the end.

## Ecosystems

Each row was validated locally against a real repository or a sample project, see the example Dockerfile for the image.

| Ecosystem | Example | `setup` | `cache-key-files` | Notes |
| --- | --- | --- | --- | --- |
| Go | [go](examples/go/Dockerfile) | | `go.sum` | Generated code must exist, for example `go generate` |
| Node | [node](examples/node/Dockerfile) | `npm ci --ignore-scripts --omit=dev` | `package-lock.json` | |
| Python | [python](examples/python/Dockerfile) | `UV_PROJECT_ENVIRONMENT=.venv-licensed uv sync --frozen --no-dev` then `uv pip install --python .venv-licensed pip` | `uv.lock` | licensed reads the venv set in `python.virtual_env_dir`, which needs pip |
| Gradle and Android | [android](examples/android/Dockerfile) | | `**/*.gradle*`, `gradle/wrapper/gradle-wrapper.properties` | See [Android](#android) |
| CocoaPods | [cocoapods](examples/cocoapods/Dockerfile) | `pod install` | `Podfile.lock` | `pod install` also integrates the Xcode project in the working tree |
| SwiftPM | [swift](examples/swift/Dockerfile) | `swift package resolve` | `Package.resolved` | Only packages with a `Package.swift`, not Xcode projects |

### Android

- Set `gradle.configurations` to the variant to scan, such as `releaseRuntimeClasspath`, the licensed defaults do not exist in Android projects.
- When the Gradle project is in a subfolder, set licensed's `root` to it, the Gradle plugin writes its report next to the Gradle root.
- List in `SDK_PACKAGES` every SDK package the Android Gradle plugin would otherwise install by itself, older plugins install build-tools and platform-tools and print to the output licensed parses.
- Pick the JDK the Android Gradle plugin needs with the `JDK` build argument.

## Patched licensed

The base image applies these [patches](image/patches) to licensed:

- **pip**: package folders are matched with PEP 503 name folding, so packages with dots in their names are found.
- **Gradle**: the configurations licensed copies keep the variant attributes, without which multi-module Android projects fail to resolve. Plain Java projects resolve as before.
- **Swift**: `Package.resolved` format version 2, written by Swift 5.6 and later, is read.

## Local runs

The repository image runs the same way on a developer machine, for example from a Taskfile, with the `setup` commands, if any, before licensed:

```yaml
licenses:
  cmds:
    - docker build -t licensed -f .github/licensed/Dockerfile .
    - docker run --rm -v "$PWD:/src/$(basename "$PWD")" -w "/src/$(basename "$PWD")" -v licensed-cache:/cache --entrypoint bash licensed -c "trap 'chown -R $(id -u):$(id -g) .' EXIT; licensed cache && licensed status"
```

The trap hands the files back to the host user, as the action does, since the tools run as root.

## Releasing

[release-please](https://github.com/googleapis/release-please) keeps a release pull request open from the Conventional Commits on main. Merging it tags `vX.Y.Z`, publishes the base image as `vX.Y.Z`, `vX.Y` and `vX`, then moves the `vX` and `vX.Y` git tags, so `@vX` users get the action and its image together. Each action release runs the exact image version it was released with.

Each push to main that touches the image publishes it as `edge`, which the [test](.github/workflows/test.yml) fixture builds on.
