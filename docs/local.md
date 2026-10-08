# Local runs

Locally you run the image yourself, with your repository mounted under `/src` and a volume for `/cache`. The action runs the very same image, so what passes locally passes in CI.

```sh
docker run --rm -v "$PWD:/src/my-repo" -w /src/my-repo -v my-repo-licensed:/cache ghcr.io/robgee86/licensed-go-action:v0 [command]
```

| Command | What it does |
| --- | --- |
| none | Updates the records, and the NOTICE files when there are any, then checks them. Run it after changing dependencies, then review and commit `.licenses/` |
| `licensed-check` | Checks without changing anything, exactly as CI does |
| `licensed-notices` | Writes the [NOTICE files](notices.md), once, to turn them on |

Keep the folder name after `/src/` equal to your repository folder: licensed names the records after it.

## Dependency folder

Node, Python, CocoaPods and Swift install the dependencies licensed reads into a folder of your project, `node_modules`, `.venv`, `Pods` or `.build`. Mount a volume over it, so the container installs there instead of overwriting your own copy, built for your machine:

```sh
docker run --rm -e LICENSED_SETUP="npm ci --ignore-scripts --omit=dev" -v "$PWD:/src/my-repo" -w /src/my-repo -v my-repo-licensed:/cache -v my-repo-licensed-deps:/src/my-repo/node_modules ghcr.io/robgee86/licensed-node-action:v0
```

When your project has no such folder, Docker leaves an empty one behind, already ignored by git in most projects.

## Fast runs

The volumes keep the package manager caches, the installed dependencies, and anything your setup stores in `/cache`, between runs. The first run downloads the dependencies, later ones take seconds.

Docker stores the volumes, not your repository: under `/var/lib/docker/volumes` on Linux, inside the virtual disk of Docker Desktop or OrbStack on macOS and Windows. `docker system df -v` shows their size, and `docker volume rm my-repo-licensed my-repo-licensed-deps` starts over.

## Setup

Pass the setup of your ecosystem with `-e LICENSED_SETUP="..."`, as above. A repository that extends an image sets `LICENSED_SETUP` in its Dockerfile instead, see [Images](images.md#extending-an-image).

## Taskfile

Tasks spare everyone the long command lines. The repository name is written out, since `basename` is missing on Windows, and extra arguments after `--` reach the image:

```yaml
tasks:
  fix:licenses:
    desc: Update the dependency license records, task fix:licenses -- licensed-notices turns notices on
    cmds:
      - docker run --rm -v "$PWD:/src/my-repo" -w /src/my-repo -v my-repo-licensed:/cache ghcr.io/robgee86/licensed-go-action:v0 {{.CLI_ARGS}}

  check:licenses:
    desc: Check the dependency license records as CI does
    cmds:
      - docker run --rm -v "$PWD:/src/my-repo" -w /src/my-repo -v my-repo-licensed:/cache ghcr.io/robgee86/licensed-go-action:v0 licensed-check
```

A repository with its own Dockerfile adds a `docker build -t my-repo-licensed <folder>` command first and runs that image instead.
