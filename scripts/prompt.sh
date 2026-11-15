#!/usr/bin/env bash
set +x
unset NURTURE_API_KEY
root=$(cd "$(dirname "$0")/.." && pwd -P) || exit 2
bash "$root/scripts/prompt-guard.sh" || exit 2
# This only fetches. A ready notice does not block an already running job.
bash "$root/scripts/update.sh" daily
