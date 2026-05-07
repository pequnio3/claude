#!/usr/bin/env bash
# Smoke test for cwt setup-script wiring.
# $1 is the worktree path passed in by the WorktreeCreate hook / cwt.
echo "hello from setup.sh"
echo "worktree: $1"
