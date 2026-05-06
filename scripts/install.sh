#!/usr/bin/env bash
# install.sh — wire wcd + cwt into ~/.zshrc and/or ~/.bashrc (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

install_into() {
    local rc="$1" file="$2" label="$3" comment="$4"
    if grep -Fq "$file" "$rc" 2>/dev/null; then
        echo "$label: already installed in $rc"
        return 0
    fi
    {
        printf '\n# %s\n' "$comment"
        printf 'source "%s"\n' "$file"
    } >> "$rc"
    echo "$label: installed in $rc"
}

bash_rc=""
if [[ -f "$HOME/.bashrc" ]]; then
    bash_rc="$HOME/.bashrc"
elif [[ -f "$HOME/.bash_profile" ]]; then
    bash_rc="$HOME/.bash_profile"
fi

did_install=0

install_pair() {
    local name="$1" comment="$2"
    local zsh_file="$SCRIPT_DIR/$name.zsh"
    local bash_file="$SCRIPT_DIR/$name.bash"

    if [[ -f "$zsh_file" && -f "$HOME/.zshrc" ]]; then
        install_into "$HOME/.zshrc" "$zsh_file" "$name" "$comment"
        did_install=1
    fi
    if [[ -f "$bash_file" && -n "$bash_rc" ]]; then
        install_into "$bash_rc" "$bash_file" "$name" "$comment"
        did_install=1
    fi
}

install_pair "wcd" "wcd: cd to ~/.worktrees/<repo>/<worktree>"
install_pair "cwt" "cwt: open/resume a Claude worktree under ~/.worktrees/<repo>/"

if [[ "$did_install" -eq 0 ]]; then
    echo "no shell rc files found (~/.zshrc, ~/.bashrc, ~/.bash_profile)" >&2
    echo "create one of those, or source the scripts manually." >&2
    exit 1
fi

echo
echo "Restart your shell or run: source <your rc file>"
