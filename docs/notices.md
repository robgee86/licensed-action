# Notices

A NOTICE file collects the license texts of all the dependencies of an app, ready to ship, for example in a Debian copyright file. The images write them with `licensed-notices`, which runs `licensed notices` and then [licensed-notice-deduplicate](https://github.com/arduino/licensed-notice-deduplicate), merging the packages that share a license text into one entry.

Committing NOTICE files is what turns them on. Write them once, then commit them next to the records:

```sh
docker run --rm -v "$PWD:/src/my-repo" -w /src/my-repo -v my-repo-licensed:/cache ghcr.io/robgee86/licensed-go-action:v0 licensed-notices
```

or `task fix:licenses -- licensed-notices` with the tasks of [local runs](local.md#taskfile). From then on:

- the default local run writes them again with the records, and removes those licensed no longer writes,
- `licensed-check`, in CI and locally, fails when one is missing, outdated or left over, without touching them.

Delete them to turn notices off.
