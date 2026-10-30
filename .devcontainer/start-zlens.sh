#!/bin/sh
# Start ZLens in GitHub Codespaces on this folder, which is already a
# database-only workspace. It listens on localhost (no token needed: GitHub
# keeps the forwarded port private to you) and accepts this codespace's
# forwarded address. The first start installs the DuckDB driver.
set -eu
port=3474
if curl -fs -o /dev/null "http://127.0.0.1:${port}/"; then
  exit 0
fi
if [ -n "${CODESPACE_NAME:-}" ]; then
  ZLENS_ALLOWED_ORIGINS="https://${CODESPACE_NAME}-${port}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  export ZLENS_ALLOWED_ORIGINS
fi
cd "$(dirname "$0")/.."
# setsid: Codespaces stops everything the start command launched once the
# command finishes; a new session keeps ZLens running after this script exits.
setsid nohup npx zlens notebook . --port "$port" --no-open > /tmp/zlens.log 2>&1 < /dev/null &
echo "ZLens is starting on port ${port}; it opens in a panel when ready (log: /tmp/zlens.log)."
