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
