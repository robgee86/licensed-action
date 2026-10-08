# Ecosystems

licensed runs the tools of each ecosystem, so each one has its image, built on the base image `ghcr.io/robgee86/licensed-action`. All images are published for amd64 and arm64 and share the version of the action.

| `ecosystem` | Image | Holds |
| --- | --- | --- |
| `go` | `ghcr.io/robgee86/licensed-go-action` | Go, which can fetch the newer toolchain a `go.mod` asks for |
| `node` | `ghcr.io/robgee86/licensed-node-action` | Node.js and npm, with yarn and pnpm shims through corepack, validated with npm only |
| `python` | `ghcr.io/robgee86/licensed-python-action` | uv, Python 3.13 and a C toolchain, uv can download another Python on each run |
| `gradle` | `ghcr.io/robgee86/licensed-gradle-action` | JDK 17 and the Android SDK |
| `cocoapods` | `ghcr.io/robgee86/licensed-cocoapods-action` | CocoaPods with the cocoapods-dependencies-list plugin |
| `swift` | `ghcr.io/robgee86/licensed-swift-action` | The Swift toolchain |

All but CocoaPods run on a fixture under [test](../test) in CI, CocoaPods pods need an Xcode project.

## Go

No setup is needed. Code generated at build time must exist before the scan, run its generator as setup, such as `go generate`.

## Node

`npm ci --ignore-scripts --omit=dev` installs the production dependencies that `npm list` reads.

## Python

licensed reads the installed packages of the venv set in `python.virtual_env_dir`, and needs pip inside it. With uv:

```yaml
python:
  virtual_env_dir: .venv
ignored:
  pip:
    - pip
```

and as setup `UV_PROJECT_ENVIRONMENT=.venv uv sync --frozen --no-dev --no-install-project && uv pip install --python .venv pip`.

## Gradle and Android

- Set `gradle.configurations` to the variant to scan, such as `releaseRuntimeClasspath`, the licensed defaults do not exist in Android projects.
- When the Gradle project is in a subfolder, set licensed's `root` to it, the Gradle plugin writes its report next to the Gradle root.
- Older Android Gradle plugins install the SDK packages they miss and print to the output licensed parses, a setup such as `./gradlew -q help` lets them do it first.
- A plugin that needs another JDK gets it from a Dockerfile [extending](images.md#extending-an-image) the image.

## CocoaPods

`pod install` downloads the pods licensed reads, and also integrates the Xcode project in the working tree.

## Swift

Only packages with a `Package.swift` are supported, set `swift package resolve` as setup. Packages added to an Xcode project have no `Package.swift`, and only `xcodebuild` on macOS resolves them.
