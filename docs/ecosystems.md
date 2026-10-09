# Ecosystems

licensed runs the tools of each ecosystem, so each one has its image, built on the base image `ghcr.io/robgee86/licensed`. All images are published for amd64 and arm64 and share the version of the action.

| `ecosystem` | Image | Holds |
| --- | --- | --- |
| `go` | `ghcr.io/robgee86/licensed-go` | Go, which can fetch the newer toolchain a `go.mod` asks for |
| `node` | `ghcr.io/robgee86/licensed-node` | Node.js and npm, with yarn and pnpm shims through corepack, validated with npm only |
| `python` | `ghcr.io/robgee86/licensed-python` | uv, Python 3.13 and a C toolchain, uv can download another Python on each run |
| `gradle-jdk17` | `ghcr.io/robgee86/licensed-gradle-jdk17` | JDK 17 and the Android SDK |
| `gradle-jdk21` | `ghcr.io/robgee86/licensed-gradle-jdk21` | JDK 21 and the Android SDK |
| `cocoapods` | `ghcr.io/robgee86/licensed-cocoapods` | CocoaPods with the cocoapods-dependencies-list plugin |
| `swift` | `ghcr.io/robgee86/licensed-swift` | The Swift toolchain |
| `react-native` | `ghcr.io/robgee86/licensed-react-native` | Node.js, CocoaPods, JDK 17, the Android SDK and build tools |

Up to v0.3 the images carried an `-action` suffix, such as `ghcr.io/robgee86/licensed-go-action`. A Dockerfile extending one of them needs the new name to receive updates.

All but CocoaPods and React Native run on a fixture under [test](../test) in CI, as both need an Xcode project.

## Go

No setup is needed. Code generated at build time must exist before the scan, run its generator as setup, such as `go generate`.

## Node

`npm ci --ignore-scripts --omit=dev` installs the production dependencies that `npm list` reads.

## Python

licensed reads the installed packages of the venv set in `python.virtual_env_dir`, and needs pip inside it. Name it `.venv`, the folder the runs keep in the cache. With uv:

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
- The Android Gradle plugin downloads the NDK of the `ndkVersion` a project sets, the cache keeps it, so only the first run downloads it.
- Records are named `group__artifact.dep.yml`, with `__` in place of the colon, so repositories can be cloned on Windows. Other licensed builds name them `group:artifact.dep.yml`, rename the files when moving to this image.

## CocoaPods

`pod install --deployment` downloads the pods licensed reads and checks the committed `Podfile.lock`, failing instead of rewriting it, as `npm ci` does with `package-lock.json`. It also integrates the Xcode project in the working tree.

- A repository that pins CocoaPods and its plugins in a `Gemfile` installs and runs them, with the Ruby of its `.ruby-version`: set `mise install && BUNDLE_FROZEN=true bundle install && bundle exec pod install --deployment` as setup, and `cocoapods.command: bundle exec pod` in `.licensed.yml` so licensed runs the same CocoaPods. mise installs that Ruby into the cache, and its shims select it in the repository and the image's Ruby elsewhere.
- licensed needs the cocoapods-dependencies-list plugin, which the image holds, patched, and loads into whichever CocoaPods licensed runs, so the `Gemfile` needs no entry for it.
- Without a `Gemfile`, the CocoaPods of the image, 1.16.2, installs the pods, and as `Podfile.lock` records the CocoaPods version that wrote it, `--deployment` fails on a lockfile written by another version. Pin CocoaPods in a `Gemfile`, as most iOS projects do.
- A `Podfile.lock` that `pod install` would change fails the run, for example when a podspec embeds the path of the checkout, which differs between machines. Such a lockfile also changes between developers, fix the podspec rather than the run.

## React Native

The Podfile and the Gradle build of a React Native app run Node.js, so one image holds all three toolchains and one configuration checks the three parts:

```yaml
apps:
  - name: js
    source_path: .
    sources:
      npm: true
  - name: ios
    source_path: ios
    sources:
      cocoapods: true
    cocoapods:
      targets:
        - MyApp
      # The CocoaPods of the Gemfile, as the setup installs the pods with it
      command: bundle exec pod
  - name: android
    root: android
    source_path: app
    cache_path: ../.licenses
    sources:
      gradle: true
    gradle:
      configurations:
        - releaseRuntimeClasspath
```

- The setup of the image, `licensed-react-native-setup`, installs the JavaScript packages from the lockfile, development ones included since the Podfile and the Gradle build run the React Native CLI, then the pods with `pod install --deployment`, through the Ruby and the bundle of its `Gemfile` when it has one, see [CocoaPods](#cocoapods). A project that needs more prepends its own commands to it.
- The pods React Native builds from `node_modules` are covered by the records of their npm packages, list them under `ignored`.
- Some React Native podspecs embed the path of the checkout, such as the Hermes compiler path of `hermes-engine`, so their checksums in `ios/Podfile.lock` differ on every machine and `pod install --deployment` fails. Make them relative to the pods folder, with a patch-package patch until React Native does it.

## Swift

Only packages with a `Package.swift` are supported, set `swift package resolve` as setup. Packages added to an Xcode project have no `Package.swift`, and only `xcodebuild` on macOS resolves them.
