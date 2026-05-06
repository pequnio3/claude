# cwt <name>  —  open or resume a Claude worktree at ~/.worktrees/<repo>/<name>
#
# - If the worktree exists: cd there, run scripts/setup.sh if present,
#   and resume the most recent Claude session for that directory.
# - If the worktree does not exist: launch `claude --worktree <name>` from
#   the current repo root; the global WorktreeCreate hook creates it (and
#   runs scripts/setup.sh once). When claude exits, cd into the new worktree.
#
# Tab completion: lists existing worktrees under ~/.worktrees/<current-repo>/.
#
# Usage:
#   source /path/to/cwt.bash    # from ~/.bashrc

: ${CWT_ROOT:=$HOME/.worktrees}

cwt() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: cwt <name>" >&2
        return 1
    fi

    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "cwt: not in a git repository" >&2
        return 1
    }
    local repo="${toplevel##*/}"
    local target="$CWT_ROOT/$repo/$name"

    if [[ -d "$target" ]]; then
        cd "$target" || return 1
        if [[ -f "$target/scripts/setup.sh" ]]; then
            bash "$target/scripts/setup.sh" "$target"
        elif [[ -f "$target/setup.sh" ]]; then
            bash "$target/setup.sh" "$target"
        fi
        claude --continue
    else
        ( cd "$toplevel" && claude --worktree "$name" )
        [[ -d "$target" ]] && cd "$target"
    fi
}

_cwt_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=()
    case $COMP_CWORD in
        1)
            local repo
            repo=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
            repo="${repo##*/}"
            local dir="$CWT_ROOT/$repo"
            local names=() d
            if [[ -d "$dir" ]]; then
                for d in "$dir"/*/; do
                    [[ -d "$d" ]] || continue
                    d="${d%/}"
                    names+=("${d##*/}")
                done
                COMPREPLY=( $(compgen -W "${names[*]}" -- "$cur") )
            fi
            ;;
    esac
}

complete -F _cwt_complete cwt
