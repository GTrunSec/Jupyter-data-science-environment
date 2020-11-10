#!/usr/bin/env bash
set -euo pipefail
mv shell.nix _shell.nix
mv ./nix/shell-test.nix shell.nix
