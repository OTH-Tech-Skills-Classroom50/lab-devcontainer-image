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

# Student CLI, baked in so no network install is needed at Codespace creation time.
# `gh extension install` hits the GitHub API to resolve the latest release;
# unauthenticated calls share a 60/hr limit per source IP, which Actions'
# shared runner IPs blow through easily (confirmed: 403 rate-limit here on a
# clean run). The workflow passes its own token in as a build secret so this
# runs authenticated instead.
RUN --mount=type=secret,id=gh_token \
    GH_TOKEN="$(cat /run/secrets/gh_token)" gh extension install foundation50/gh-student

# check: reads the assignment slug from .classroom50.yaml (written by `gh student accept`)
# and runs the matching check50 checks from the course's public checks repo.
RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'ASSIGNMENT=$(grep '"'"'^assignment:'"'"' .classroom50.yaml | sed -E '"'"'s/^assignment:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/'"'"')' \
    'check50 --local "OTH-Tech-Skills-Classroom50/technology-skills-checks/main/$ASSIGNMENT"' \
    > /usr/local/bin/check \
    && chmod +x /usr/local/bin/check

# submit: thin alias for `gh student submit` -- gh-student already reads all
# the context it needs (repo, .classroom50.yaml) itself, so this just saves
# students from having to know the real command name.
RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'exec gh student submit "$@"' \
    > /usr/local/bin/submit \
    && chmod +x /usr/local/bin/submit
