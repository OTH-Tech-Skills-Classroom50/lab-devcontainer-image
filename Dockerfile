# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/devcontainers/python:3.12

# GitHub CLI, installed from the .deb release asset rather than cli.github.com's
# own apt repo -- that repo has been returning 404 on dists/stable/Release since
# at least 2026-08-06 (external outage, unrelated to this Dockerfile; confirmed
# via https://github.com/orgs/community/discussions/184211, an ongoing GitHub
# Pages/Actions-adjacent infra issue others have hit too). This path uses
# GitHub Releases instead, a different, currently-working infrastructure.
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl sqlite3 nodejs npm \
    && GH_VERSION=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+') \
    && ARCH=$(dpkg --print-architecture) \
    && curl -fsSL -o /tmp/gh.deb "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${ARCH}.deb" \
    && apt-get install -y /tmp/gh.deb \
    && rm -f /tmp/gh.deb \
    && rm -rf /var/lib/apt/lists/*

# Live-preview server for HTML/CSS/JS labs (mirrors the live-server devcontainer feature)
RUN npm install -g live-server

# Course-wide Python baseline (same set every lab template installs, kept consistent on purpose)
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir pytest cs50 flask requests check50

# Student CLI, baked in as a convenience for students who want `gh student
# accept`/other subcommands directly -- not used by our own `submit` script
# (see below) since gh-student login requests admin:org/read:org/repo/workflow,
# none of which a submission tag push actually needs.
# `gh extension install` hits the GitHub API to resolve the latest release;
# unauthenticated calls share a 60/hr limit per source IP, which Actions'
# shared runner IPs blow through easily (confirmed: 403 rate-limit here on a
# clean run). The workflow passes its own token in as a build secret so this
# runs authenticated instead.
#
# Installed as the `vscode` user specifically, not root: `gh extension
# install` writes into the invoking user's own $HOME/.local/share/gh, and
# Codespaces run as `vscode` at runtime -- installing as root (the default
# build user) put the extension somewhere the runtime user's `gh` never
# looks. Confirmed: this caused `gh student submit` / the `submit` alias to
# fail with 'unknown command "student"' even though the install step itself
# succeeded during the build and `check` (a plain /usr/local/bin script,
# user-independent) worked fine.
USER vscode
RUN --mount=type=secret,id=gh_token,mode=0444 \
    GH_TOKEN="$(cat /run/secrets/gh_token)" gh extension install foundation50/gh-student
USER root

# check: reads the assignment slug from .classroom50.yaml (written by `gh student accept`),
# runs the matching check50 checks from the course's public checks repo, and
# reformats check50's own JSON output to match the course's original
# pytest-based output style (colored "label: PASSED/FAILED" lines using each
# check's docstring, no "expected X, not Y" diff detail, no HTML-report
# trailer line). See ./check for the actual script.
COPY check /usr/local/bin/check
RUN chmod +x /usr/local/bin/check

# submit: plain git commit+push+tag, not `gh student submit`. Confirmed
# directly that a bare tag push triggers real grading with no elevated auth
# at all -- matches Classroom50's own documented tag-mode baseline contract
# (foundation50/classroom50#477: "plain git, no tooling required" is the
# real mechanism; gh student submit is described as just a convenience
# automating the same). Students following this course's web-UI accept flow
# never need to run `gh student login` at all this way. See ./submit.
COPY submit /usr/local/bin/submit
RUN chmod +x /usr/local/bin/submit
