# Ecosystems

licensed runs the tools of each ecosystem, so each one has its image, built on the base image `ghcr.io/robgee86/licensed-action`. All images are published for amd64 and arm64 and share the version of the action.

| `ecosystem` | Image | Holds |
| --- | --- | --- |
| `go` | `ghcr.io/robgee86/licensed-go-action` | Go, which can fetch the newer toolchain a `go.mod` asks for |
| `node` | `ghcr.io/robgee86/licensed-node-action` | Node.js and npm, with yarn and pnpm shims through corepack, validated with npm only |
| `python` | `ghcr.io/robgee86/licensed-python-action` | uv, Python 3.13 and a C toolchain, uv can download another Python on each run |
| `gradle-jdk17` | `ghcr.io/robgee86/licensed-gradle-jdk17-action` | JDK 17 and the Android SDK |
| `gradle-jdk21` | `ghcr.io/robgee86/licensed-gradle-jdk21-action` | JDK 21 and the Android SDK |
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

Pick the image of the JDK your build runs on: JDK 17 for the Android Gradle plugin 8 and later, JDK 21 for projects that require it. Each image holds a single JDK, so you only pull the one you use.

- Set `gradle.configurations` to the variant to scan, such as `releaseRuntimeClasspath`, the licensed defaults do not exist in Android projects.
- When the Gradle project is in a subfolder, set licensed's `root` to it, the Gradle plugin writes its report next to the Gradle root.
- Older Android Gradle plugins install the SDK packages they miss and print to the output licensed parses, a setup such as `./gradlew -q help` lets them do it first.
- Android Gradle plugins older than 8 run on JDK 11, which a Dockerfile [extending](images.md#extending-an-image) an image adds.
- Records are named `group__artifact.dep.yml`, with `__` in place of the colon, so repositories can be cloned on Windows. Other licensed builds name them `group:artifact.dep.yml`, rename the files when moving to this image.

## CocoaPods

`pod install` downloads the pods licensed reads, and also integrates the Xcode project in the working tree.

## Swift

Only packages with a `Package.swift` are supported, set `swift package resolve` as setup. Packages added to an Xcode project have no `Package.swift`, and only `xcodebuild` on macOS resolves them.
