#!/usr/bin/env bash
#
# Curl each route and report pass/fail. Exits 0 if all pass, 1 if any fail.

set -uo pipefail

FAIL=0

check() {
    local url="$1"
    shift
    local expected=("$@")
    local code
    code="$(curl -s -o /dev/null -w '%{http_code}' "$url")"

    for ok in "${expected[@]}"; do
        if [[ "$code" == "$ok" ]]; then
            echo "PASS  $url -> $code"
            return 0
        fi
    done

    echo "FAIL  $url -> $code (expected one of: ${expected[*]})"
    FAIL=1
}

check "http://localhost/" 200
check "http://localhost/jp-drill" 200 301
check "http://localhost/song-drill" 200 301
check "http://localhost/api/jp-drill/health" 200
check "http://localhost/api/song-drill/health" 200

exit "$FAIL"
