# lab-devcontainer-image

The prebuilt devcontainer image every "Technology Skills" lab template's
`devcontainer.json` points at, instead of installing packages/features fresh
on every student's Codespace creation.

Contains: `cs50`, `flask`, `requests`, `check50`, `pytest`, GitHub CLI +
`gh-student` extension, `sqlite3`, `live-server`, and the `check` command
(slug-agnostic — reads the assignment from `.classroom50.yaml` at runtime).

## Updating

Edit the `Dockerfile`, push to `main` — GitHub Actions rebuilds and pushes
`ghcr.io/oth-tech-skills-classroom50/lab-devcontainer:latest` automatically.
Every lab template picks up the change on next Codespace *creation* (already-
running Codespaces don't repull automatically).

## Image

`ghcr.io/oth-tech-skills-classroom50/lab-devcontainer:latest` (public).
