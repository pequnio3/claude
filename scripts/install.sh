#!/usr/bin/env bash
# install.sh — wire wcd + cwt into ~/.zshrc and/or ~/.bashrc (idempotent)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

install_into() {
    local rc="$1" file="$2" label="$3" comment="$4"
    local replaced=0
    if grep -Fq "source \"$file\"" "$rc" 2>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        awk -v target="source \"$file\"" '
            { lines[NR] = $0 }
            END {
                for (i = 1; i <= NR; i++) {
                    if (lines[i] == target) {
                        drop[i] = 1
                        if (i > 1 && substr(lines[i-1], 1, 1) == "#") {
                            drop[i-1] = 1
                            if (i > 2 && lines[i-2] == "") drop[i-2] = 1
                        }
                    }
                }
                for (i = 1; i <= NR; i++) if (!drop[i]) print lines[i]
            }
        ' "$rc" > "$tmp"
        mv "$tmp" "$rc"
        replaced=1
    fi
    {
        printf '\n# %s\n' "$comment"
        printf 'source "%s"\n' "$file"
    } >> "$rc"
    if [[ $replaced -eq 1 ]]; then
        echo "$label: reinstalled in $rc"
    else
        echo "$label: installed in $rc"
    fi
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
install_pair "cwt-rm" "cwt-rm: remove a Claude worktree under ~/.worktrees/<repo>/"

# Deploy the WorktreeCreate hook + settings from this repo into ~/.claude so the
# repo stays the source of truth. The hook is symlinked so future repo edits take
# effect immediately (no manual re-copy / staleness). settings.json is only
# installed when absent — never overwrite an existing config, which may have more
# than this repo's template (plugins, env, push-notif prefs, etc.).
deploy_claude() {
    local repo_claude="$SCRIPT_DIR/../.claude"
    local hook_src="$repo_claude/hooks/create_worktree.sh"
    local hook_dst="$HOME/.claude/hooks/create_worktree.sh"
    local settings_src="$repo_claude/settings.json"
    local settings_dst="$HOME/.claude/settings.json"

    if [[ -f "$hook_src" ]]; then
        mkdir -p "$(dirname "$hook_dst")"
        ln -sfn "$hook_src" "$hook_dst"
        echo "create_worktree.sh: symlinked into ~/.claude/hooks"
        did_install=1
    fi

    if [[ -f "$settings_src" ]]; then
        if [[ -e "$settings_dst" ]]; then
            echo "settings.json: left existing ~/.claude/settings.json untouched"
        else
            mkdir -p "$(dirname "$settings_dst")"
            cp "$settings_src" "$settings_dst"
            echo "settings.json: installed in ~/.claude (was missing)"
        fi
        did_install=1
    fi
}

deploy_claude

if [[ "$did_install" -eq 0 ]]; then
    echo "no shell rc files found (~/.zshrc, ~/.bashrc, ~/.bash_profile)" >&2
    echo "create one of those, or source the scripts manually." >&2
    exit 1
fi

echo
echo "Restart your shell or run: source <your rc file>"
