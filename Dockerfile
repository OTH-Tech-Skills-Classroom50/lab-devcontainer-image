FROM mcr.microsoft.com/devcontainers/python:3.12

# GitHub CLI (apt repo per https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
RUN (type -p wget >/dev/null || (apt-get update && apt-get install -y wget)) \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages/deb stable main" \
       | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh sqlite3 nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Live-preview server for HTML/CSS/JS labs (mirrors the live-server devcontainer feature)
RUN npm install -g live-server

# Course-wide Python baseline (same set every lab template installs, kept consistent on purpose)
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir pytest cs50 flask requests check50

# Student CLI, baked in so no network install is needed at Codespace creation time
RUN gh extension install foundation50/gh-student

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
