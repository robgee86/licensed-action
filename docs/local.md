# Local runs

Locally you run the image yourself, with your repository mounted under `/src` and a volume for `/cache`. The action runs the very same image, so what passes locally passes in CI.

```sh
docker run --rm -v "$PWD:/src" -v licensed-cache:/cache ghcr.io/robgee86/licensed-go:v0 [command]
```

| Command | What it does |
| --- | --- |
| none | Updates the records, and the NOTICE files when there are any, then checks them. Run it after changing dependencies, then review and commit `.licenses/` |
| `licensed-check` | Checks without changing anything, exactly as CI does |
| `licensed-notices` | Writes the [NOTICE files](notices.md), once, to turn them on |

## Dependency folder

Node, Python, CocoaPods and Swift install the dependencies licensed reads into a folder of your project, `node_modules`, `.venv`, `Pods` or `.build`. Mount a volume over it, so the container installs there instead of overwriting your own copy, built for your machine:

```sh
docker run --rm -e LICENSED_SETUP="npm ci --ignore-scripts --omit=dev" -v "$PWD:/src" -v licensed-cache:/cache -v my-repo-licensed-deps:/src/node_modules ghcr.io/robgee86/licensed-node:v0
```

When your project has no such folder, Docker leaves an empty one behind, already ignored by git in most projects. A React Native app has two, each with its own volume, and a registry token goes in by name with `-e`:

```sh
docker run --rm -e NPM_TOKEN -v "$PWD:/src" -v licensed-cache:/cache -v my-repo-licensed-deps:/src/node_modules -v my-repo-licensed-pods:/src/ios/Pods ghcr.io/robgee86/licensed-react-native:v0
```

## Fast runs

The volumes keep their content between runs, so the first run downloads the dependencies and later ones take seconds:

- `licensed-cache` holds the package manager caches and serves all your repositories. The Go, npm, Yarn, Gradle, CocoaPods, uv and pip caches are made to be shared, so what one repository downloads the others reuse. Anything your setup stores in `/cache` itself belongs in a folder named after the repository, so repositories do not overwrite each other.
- `my-repo-licensed-deps` holds the dependencies installed for one repository, so each repository with a dependency folder has its own.

Docker stores the volumes, not your repository: under `/var/lib/docker/volumes` on Linux, inside the virtual disk of Docker Desktop or OrbStack on macOS and Windows. `docker system df -v` shows their size. `docker volume rm my-repo-licensed-deps` starts a repository over, and `docker volume rm licensed-cache` empties the shared caches.

## Setup

Pass the setup of your ecosystem with `-e LICENSED_SETUP="..."`, as above. A repository that extends an image sets `LICENSED_SETUP` in its Dockerfile instead, see [Images](images.md#extending-an-image).

## Taskfile

Tasks spare everyone the long command lines, extra arguments after `--` reach the image:

```yaml
tasks:
  fix:licenses:
    desc: Update the dependency license records, task fix:licenses -- licensed-notices turns notices on
    cmds:
      - docker run --rm -v "$PWD:/src" -v licensed-cache:/cache ghcr.io/robgee86/licensed-go:v0 {{.CLI_ARGS}}

  check:licenses:
    desc: Check the dependency license records as CI does
    cmds:
      - docker run --rm -v "$PWD:/src" -v licensed-cache:/cache ghcr.io/robgee86/licensed-go:v0 licensed-check
```

A repository with its own Dockerfile adds a `docker build -t my-repo-licensed <folder>` command first and runs that image instead.
