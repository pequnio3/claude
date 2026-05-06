# wcd <repo> <worktree>  —  cd to ~/.worktrees/<repo>/<worktree>
#
# Tab completion:
#   1st arg: if inside a git repo, autofill the current repo's name;
#            otherwise list dirs under ~/.worktrees/
#   2nd arg: list dirs under ~/.worktrees/<repo>/
#
# Usage:
#   source /path/to/wcd.bash   # from ~/.bashrc

: ${WCD_ROOT:=$HOME/.worktrees}

wcd() {
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

_wcd_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=()
    case $COMP_CWORD in
        1)
            local top names=() d
            top=$(git rev-parse --show-toplevel 2>/dev/null)
            if [[ -n "$top" ]]; then
                names=("${top##*/}")
            elif [[ -d "$WCD_ROOT" ]]; then
                for d in "$WCD_ROOT"/*/; do
                    [[ -d "$d" ]] || continue
                    d="${d%/}"
                    names+=("${d##*/}")
                done
            fi
            COMPREPLY=( $(compgen -W "${names[*]}" -- "$cur") )
            ;;
        2)
            local repo="${COMP_WORDS[1]}"
            local dir="$WCD_ROOT/$repo"
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

complete -F _wcd_complete wcd
