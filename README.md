# licensed-action

Checks the licenses of your dependencies with [licensed](https://github.com/licensee/licensed), the same way in CI and on your machine, for Go, Node, Python, Gradle and Android, CocoaPods and Swift. Everything runs inside a published Docker image, so nothing but Docker is needed.

There are two ways of working:

- **In CI**, the GitHub Action checks the committed license records and fails the job when they need attention.
- **Locally**, the same image updates the records, which you then review and commit.

## Quickstart

### 1. Configure licensed

Add a `.licensed.yml` at the root of your repository, with the sources to scan and the licenses you allow:

```yaml
sources:
  go: true
stale_records_action: error
allowed:
  - apache-2.0
  - bsd-3-clause
  - mit
```

See the [licensed configuration](https://github.com/licensee/licensed/blob/main/docs/configuration.md) for everything else.

### 2. Run it locally

Write the records under `.licenses/`, then review and commit them:

```sh
docker run --rm -v "$PWD:/src" -v licensed-cache:/cache ghcr.io/robgee86/licensed-go:v0
```

Replace `go` with your ecosystem. Run it again whenever dependencies change, later runs take seconds thanks to the cache volume, which all your repositories share. [Local runs](docs/local.md) covers checking, notices and Taskfile tasks.

### 3. Check it in CI

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

The job fails when a record is missing, outdated, left over from a removed dependency, or carries a license outside the allowed list. [CI runs](docs/ci.md) lists every input.

## Ecosystems

| `ecosystem` | `setup` | `cache-key-files` | Dependency folder |
| --- | --- | --- | --- |
| `go` | | `go.sum` | |
| `node` | `npm ci --ignore-scripts --omit=dev` | `package-lock.json` | `node_modules` |
| `python` | `UV_PROJECT_ENVIRONMENT=.venv uv sync --frozen --no-dev --no-install-project && uv pip install --python .venv pip` | `uv.lock` | `.venv` |
| `gradle-jdk17`, `gradle-jdk21` | | `**/*.gradle*` | |
| `cocoapods` | `pod install` | `Podfile.lock` | `Pods` |
| `swift` | `swift package resolve` | `Package.resolved` | `.build` |
| `react-native` | set by the image | `yarn.lock`, `ios/Podfile.lock`, `android/**/*.gradle*` | `node_modules`, `ios/Pods` |

`setup` prepares the dependencies licensed reads, pass it as the action input in CI and as `-e LICENSED_SETUP="..."` locally. It installs them in the dependency folder, which the runs keep in the cache instead of your working tree, so your own copy is never touched. [Ecosystems](docs/ecosystems.md) has the details of each one.

## Documentation

- [CI runs](docs/ci.md): the action, its inputs and its report
- [Local runs](docs/local.md): updating and checking records, Taskfile tasks
- [Ecosystems](docs/ecosystems.md): what each image holds and how to configure it
- [Notices](docs/notices.md): keeping deduplicated NOTICE files next to the records
- [Images](docs/images.md): how the container works, its commands and how to extend it
- [Development](docs/development.md): building, testing and releasing this repository
