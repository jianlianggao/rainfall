#!/usr/bin/env bash
set -uo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)" || exit 1
cd -- "$repo_root" || exit 1

if [[ -d "$repo_root/.venv/bin" ]]; then
    export PATH="$repo_root/.venv/bin:$PATH"
fi

exec 1>&2
status=0

run_check() {
    printf '\nRunning:'
    printf ' %s' "$@"
    printf '\n'
    if ! "$@"; then
        printf 'FAILED:'
        printf ' %s' "$@"
        printf '\n'
        status=1
    fi
}

run_check ruff check .
run_check ruff format --check .
run_check mypy
run_check python -m pytest

exit "$status"