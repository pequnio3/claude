# wcd <repo> <worktree>  —  cd to ~/.worktrees/<repo>/<worktree>
#
# Tab completion:
#   1st arg: if inside a git repo, autofill the current repo's name;
#            otherwise list dirs under ~/.worktrees/
#   2nd arg: list dirs under ~/.worktrees/<repo>/
#
# Usage:
#   source /path/to/wcd.zsh   # from ~/.zshrc
#   wcd <repo> <worktree>

: ${WCD_ROOT:=$HOME/.worktrees}

wcd() {
    emulate -L zsh
    local repo="$1" wt="$2"
    if [[ -z "$repo" || -z "$wt" ]]; then
        echo "Usage: wcd <repo> <worktree>" >&2
        return 1
    fi
    local target="$WCD_ROOT/$repo/$wt"
    if [[ ! -d "$target" ]]; then
        echo "wcd: no such worktree: $target" >&2
        return 1
    fi
    cd "$target"
}

_wcd_current_repo() {
    local top
    top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
    print -r -- "${top:t}"
}

_wcd_complete() {
    local -a candidates
    case $CURRENT in
        2)
            local cur_repo
            cur_repo=$(_wcd_current_repo)
            if [[ -n "$cur_repo" ]]; then
                candidates=("$cur_repo")
            elif [[ -d "$WCD_ROOT" ]]; then
                candidates=("$WCD_ROOT"/*(/N:t))
            fi
            compadd -a candidates
            ;;
        3)
            local repo="${words[2]}"
            local dir="$WCD_ROOT/$repo"
            if [[ -d "$dir" ]]; then
                candidates=("$dir"/*(/N:t))
                compadd -a candidates
            fi
            ;;
    esac
}

if ! (( ${+_comps} )); then
    autoload -Uz compinit
    compinit -C
fi
compdef _wcd_complete wcd
zstyle ':completion:*:*:wcd:*' menu yes select
