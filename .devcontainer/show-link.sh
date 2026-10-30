#!/bin/sh
# Print the link to ZLens in the terminal once it answers. Codespaces also
# opens it in a panel; this link opens it in its own browser tab.
port=3474
i=0
until curl -fs -o /dev/null "http://127.0.0.1:${port}/"; do
  i=$((i + 1))
  if [ "$i" -gt 180 ]; then
    echo "ZLens is still starting. Open the Ports tab below and click the globe next to ZLens (3474)."
    exit 0
  fi
  sleep 1
done
if [ -n "${CODESPACE_NAME:-}" ]; then
  url="https://${CODESPACE_NAME}-${port}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}/"
else
  url="http://localhost:${port}/"
fi
cat <<MSG

  ZLens is running on the Jaffle Shop warehouse, no dbt (Cmd/Ctrl+click):

    ${url}

  Guided Setup opens on "Open an existing ZLens project": this folder is
  already a database-only workspace. Ask needs an AI model: Settings → AI
  provider. Stop the codespace at github.com/codespaces when done.

MSG
