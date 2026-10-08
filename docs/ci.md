# CI runs

The action restores a cache, runs `licensed-check` in the image of your ecosystem, and turns the result into annotations and a step summary. It never rewrites the records, it checks the committed ones:

- `licensed status` fails on a missing or outdated record, a license outside the allowed list, or a record left over from a removed dependency. The last one needs `stale_records_action: error` in `.licensed.yml`, licensed only warns otherwise.
- When the repository commits [NOTICE files](notices.md), each one is compared with a fresh one and fails the job when it differs.

```yaml
- uses: robgee86/licensed-action@v0
  with:
    ecosystem: go
    cache-key-files: go.sum
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `ecosystem` | | Image to run, `go`, `node`, `python`, `gradle-jdk17`, `gradle-jdk21`, `cocoapods` or `swift`, the base image when empty |
| `dockerfile` | | Dockerfile [extending](images.md#extending-an-image) one of the images, built and run in place of the ecosystem image |
| `context` | `.` | Build context of the dockerfile |
| `working-directory` | `.` | Folder holding `.licensed.yml`, relative to the workspace |
| `setup` | | Shell commands run in the container before licensed, such as `npm ci`, replacing the `LICENSED_SETUP` of the image |
| `cache-key-files` | | Newline separated globs of the files whose content keys the cache, caching is off when empty |
| `github-token` | | Token for private dependencies hosted on GitHub |

## Caching

The container keeps the package manager caches, and anything a repository stores there, in `/cache`, which the action saves between runs keyed by the content of `cache-key-files`. When those files change, the closest earlier cache is restored, so whatever lives there must be safe to reuse.

## Private dependencies

Pass a token that can read them, for example a secret:

```yaml
with:
  ecosystem: go
  github-token: ${{ secrets.DEPENDENCIES_TOKEN }}
```

git receives it through environment variables, so it never lands in a file. When Go still looks private modules up in the public proxy or checksum database, list their paths in `GOPRIVATE` from `setup`, as `export GOPRIVATE=github.com/my-org`.

## Configuration in a subfolder

Set `working-directory` to the folder holding `.licensed.yml`, and `root: true` in it: licensed otherwise resolves its paths from the root of the git repository.
