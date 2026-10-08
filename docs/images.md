# Images

## The container

- The workspace is mounted at `/src/<folder name>`, so the app names licensed derives from folder names, and with them the records layout, match a native run.
- `/cache` is the one directory kept between runs. The images point the Go, npm, corepack, Yarn, Gradle, CocoaPods, uv and pip caches inside it, and a repository can keep anything else there, such as virtual environments.
- The tools run as root, and on exit the files they created in the workspace and in `/cache` go back to the owner of the workspace.

## Commands

Besides licensed and licensed-notice-deduplicate, each image holds three commands, run by passing them after the image name:

| Command | What it does |
| --- | --- |
| `licensed-action` | The entrypoint, it evaluates `LICENSED_SETUP`, so the variables it exports reach licensed, then runs the given command, or without one runs `licensed cache`, `licensed-notices` when there are NOTICE files, and `licensed status` |
| `licensed-check` | What the action runs, `licensed status` plus, when there are NOTICE files, their comparison with fresh ones |
| `licensed-notices` | Writes the NOTICE files with `licensed notices`, then deduplicates them |

## Extending an image

A repository that needs more than an image holds, such as system headers or its own preparation script, extends it with a Dockerfile, passed as `dockerfile` to the action and built with `docker build` locally. Setting `LICENSED_SETUP` in it gives CI and local runs the same setup without repeating it:

```dockerfile
FROM ghcr.io/robgee86/licensed-python-action:v0

RUN apt-get update && apt-get install -y --no-install-recommends libasound2-dev && rm -rf /var/lib/apt/lists/*
COPY prepare.py /prepare.py
ENV LICENSED_SETUP=/prepare.py
```

Keep the `licensed-action` entrypoint of the image.

## Patched licensed

The base image applies these [patches](../images/base/patches) to licensed:

- **pip**: package folders are matched with PEP 503 name folding, so packages with dots in their names are found.
- **Gradle**: the configurations licensed copies keep the variant attributes, without which multi-module Android projects fail to resolve. Plain Java projects resolve as before.
- **Swift**: `Package.resolved` format version 2, written by Swift 5.6 and later, is read.
- **Record file names**: the colon of Gradle coordinates becomes `__` in record file names, such as `org.apache.commons__commons-lang3.dep.yml`, because Windows cannot create files containing a colon and Git for Windows refuses to check them out.

The CocoaPods image also patches the cocoapods-dependencies-list plugin, which recursed forever on pod versions with ActiveSupport 7.
