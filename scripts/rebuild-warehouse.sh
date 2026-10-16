#!/usr/bin/env bash
# Rebuild jaffle_shop.duckdb, the warehouse this sample ships.
#
# The file is the database the dbt sample duckcode-ai/jaffle-shop-duckdb builds,
# at a pinned commit. This sample keeps only the result: no dbt files. This
# script documents (and repeats) how it was made:
#
#   1. clone jaffle-shop-duckdb at the pinned commit into a temporary folder
#   2. create a Python virtual environment with its requirements (dbt-duckdb)
#   3. dbt deps, dbt seed, dbt build (the steps in that repo's README)
#   4. copy its jaffle_shop.duckdb here
#
# Needs git, Python 3.9-3.14 and network access (pip and dbt packages).
# Stop `npm run notebook` first: it holds the database open.
#
#   ./scripts/rebuild-warehouse.sh            # rebuild in place
#   PYTHON=python3.13 ./scripts/rebuild-warehouse.sh
set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-https://github.com/duckcode-ai/jaffle-shop-duckdb.git}"
SOURCE_COMMIT="${SOURCE_COMMIT:-a9ec27779995708d961a6cfcad9ee5c049573e6e}"
PYTHON_BIN="${PYTHON:-python3}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/jaffle-shop-warehouse.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

export DBT_SEND_ANONYMOUS_USAGE_STATS=false

echo "[1/4] Cloning $SOURCE_REPO at ${SOURCE_COMMIT:0:7}…"
git clone --quiet "$SOURCE_REPO" "$WORK_DIR/jaffle-shop-duckdb"
git -C "$WORK_DIR/jaffle-shop-duckdb" checkout --quiet "$SOURCE_COMMIT"
cd "$WORK_DIR/jaffle-shop-duckdb"

echo "[2/4] Installing dbt-duckdb into a virtual environment…"
"$PYTHON_BIN" -m venv .venv
.venv/bin/python -m pip install --quiet --upgrade pip --progress-bar off
.venv/bin/python -m pip install --quiet -r requirements.txt --progress-bar off

echo "[3/4] Building the dbt project (deps, seed, build)…"
.venv/bin/dbt deps --profiles-dir .
.venv/bin/dbt seed --profiles-dir .
.venv/bin/dbt build --profiles-dir . --exclude resource_type:seed

echo "[4/4] Copying jaffle_shop.duckdb into $ROOT_DIR…"
cp jaffle_shop.duckdb "$ROOT_DIR/jaffle_shop.duckdb"

cat <<DONE

Rebuilt $ROOT_DIR/jaffle_shop.duckdb from jaffle-shop-duckdb@${SOURCE_COMMIT:0:7}.
Refresh the ZLens catalog with: npm run sync
DONE
