#!/usr/bin/env bash
# Disabled until the byte request and receipt can be driven by published schemas.
# Do not inspect the file, credentials or arguments, and do not contact Nurture.
set +x
unset NURTURE_API_KEY
printf 'UNAVAILABLE: Direct local-file upload is disabled pending a published request and receipt contract; use the confirmed Chrome workflow in guides/filing.md.\n' >&2
exit 1
