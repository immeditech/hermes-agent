#!/bin/bash
# filepath: /workspace/.devcontainer/workspace/entrypoint.sh

# Claude Code wird per nativem Installer (Dockerfile) bereitgestellt und via
# `claude update` im postStartCommand aktuell gehalten — hier kein Reinstall.

# Keep the container running for the devcontainer session
exec sleep infinity
