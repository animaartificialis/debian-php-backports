#!/bin/bash
# Replacement for "dpkg --search" on releases whose dpkg crashes on it inside
# containers (squeeze dpkg 1.15 segfaults). Other dpkg calls go to the real dpkg.
# Output format matches dpkg: "package: /path".
if [ "${1:-}" = "--search" ] || [ "${1:-}" = "-S" ]; then
    shift
    [ "${1:-}" = "--" ] && shift
    rc=1
    for pattern in "$@"; do
        if [ "${pattern#/}" != "$pattern" ]; then
            matches=$(grep -lxF -- "$pattern" /var/lib/dpkg/info/*.list 2>/dev/null)
        else
            matches=$(grep -lF -- "$pattern" /var/lib/dpkg/info/*.list 2>/dev/null)
        fi
        for list in $matches; do
            pkg=$(basename "$list" .list)
            if [ "${pattern#/}" != "$pattern" ]; then
                echo "${pkg%%:*}: $pattern"
            else
                grep -F -- "$pattern" "$list" | sed "s|^|${pkg%%:*}: |"
            fi
            rc=0
        done
        [ -n "$matches" ] || echo "dpkg: $pattern not found." >&2
    done
    exit $rc
fi
exec /usr/bin/dpkg "$@"
