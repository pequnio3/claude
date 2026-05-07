# cwt-rm <name>  —  remove a Claude worktree under ~/.worktrees/<repo>/
#
# - Removes the worktree directory and the matching `worktree-<name>` branch.
# - Refuses to operate on the cwd; cd out of the worktree first.
# - Pass -f / --force to allow git to remove a worktree with uncommitted changes.
#
# Tab completion: lists existing worktrees under ~/.worktrees/<current-repo>/.
#
# Usage:
#   source /path/to/cwt-rm.zsh    # from ~/.zshrc
#   cwt-rm <name>

: ${CWT_ROOT:=$HOME/.worktrees}

cwt-rm() {
    emulate -L zsh
    local -a force_args
    if [[ "$1" == "-f" || "$1" == "--force" ]]; then
        force_args=(--force); shift
    fi
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: cwt-rm [-f|--force] <name>" >&2
        return 1
    fi

    local toplevel
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "cwt-rm: not in a git repository" >&2
        return 1
    }

    # If we're inside an existing worktree, derive the *original* repo name
    # from the $CWT_ROOT/<repo>/<wt> path; otherwise use the toplevel basename.
    local repo
    if [[ "$toplevel" == "$CWT_ROOT"/*/* ]]; then
        local rel="${toplevel#$CWT_ROOT/}"
        repo="${rel%%/*}"
    else
        repo="${toplevel:t}"
    fi
    local target="$CWT_ROOT/$repo/$name"

    if [[ "$PWD" == "$target" || "$PWD" == "$target"/* ]]; then
        echo "cwt-rm: cd out of $target before removing it" >&2
        return 1
    fi
    if [[ ! -d "$target" ]]; then
        echo "cwt-rm: no worktree at $target" >&2
        return 1
    fi

    git -C "$toplevel" worktree remove "${force_args[@]}" "$target" || return 1
    git -C "$toplevel" branch -D "worktree-$name" 2>/dev/null
    echo "removed worktree-$name"
}

_cwt_rm_complete() {
    case $CURRENT in
        2)
            local toplevel repo
            toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
            if [[ "$toplevel" == "$CWT_ROOT"/*/* ]]; then
                local rel="${toplevel#$CWT_ROOT/}"
                repo="${rel%%/*}"
            else
                repo="${toplevel:t}"
            fi
            local dir="$CWT_ROOT/$repo"
            [[ -d "$dir" ]] || return 0
            local -a candidates
            candidates=("$dir"/*(/N:t))
            compadd -a candidates
            ;;
    esac
}

if ! (( ${+_comps} )); then
    autoload -Uz compinit
    compinit -C
fi
compdef _cwt_rm_complete cwt-rm
zstyle ':completion:*:*:cwt-rm:*' menu yes select
