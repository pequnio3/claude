#!/bin/bash
# Claude passes a JSON payload via stdin with the worktree 'name' and project 'cwd'
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Define your custom path
TARGET_DIR="$HOME/.worktrees/$PROJECT_NAME/$NAME"

# Create the folder and worktree, branching specifically off origin/main
mkdir -p "$(dirname "$TARGET_DIR")"
git -C "$PROJECT_DIR" fetch origin main

# Guard: if local `main` has commits not yet on origin/main, the new worktree
# (branched from origin/main) will silently miss them. Block and tell the user
# to push. Skip the check if there's no local `main` branch.
if git -C "$PROJECT_DIR" rev-parse --verify --quiet main >/dev/null; then
    if ! git -C "$PROJECT_DIR" merge-base --is-ancestor main origin/main; then
        local_sha=$(git -C "$PROJECT_DIR" rev-parse --short main)
        origin_sha=$(git -C "$PROJECT_DIR" rev-parse --short origin/main)
        ahead=$(git -C "$PROJECT_DIR" rev-list --count origin/main..main)
        behind=$(git -C "$PROJECT_DIR" rev-list --count main..origin/main)
        {
            echo "ERROR: local 'main' is not an ancestor of 'origin/main'."
            echo "  local main:  $local_sha (ahead $ahead)"
            echo "  origin/main: $origin_sha (behind $behind)"
            echo
            if [ "$behind" -eq 0 ]; then
                echo "You have unpushed commits on main. Push them, then re-run:"
                echo "  git -C \"$PROJECT_DIR\" push origin main"
            else
                echo "Local main has diverged from origin/main. Rebase or merge, then re-run:"
                echo "  git -C \"$PROJECT_DIR\" pull --rebase origin main"
                echo "  git -C \"$PROJECT_DIR\" push origin main"
            fi
        } >&2
        exit 1
    fi
fi

git -C "$PROJECT_DIR" worktree add -b "worktree-$NAME" "$TARGET_DIR" origin/main

# Return the path to Claude so it knows where to start the session

# Check for a 'setup.sh' in the newly created worktree
if [ -f "$TARGET_DIR/scripts/setup.sh" ]; then
    echo "Running project setup..."
    bash "$TARGET_DIR/scripts/setup.sh" "$TARGET_DIR"
elif [ -f "$TARGET_DIR/setup.sh" ]; then
    echo "Running project setup..."
    bash "$TARGET_DIR/setup.sh" "$TARGET_DIR"
fi

# Return to Claude
echo "{\"worktree_path\": \"$TARGET_DIR\"}"
