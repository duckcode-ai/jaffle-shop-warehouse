# Jaffle Shop warehouse — ZLens without dbt

A sample for [ZLens](https://github.com/duckcode-ai-labs/zlens) that starts
from a database, not a dbt project: the Jaffle Shop as a plain DuckDB file,
with a ready-made ZLens **database-only** workspace on top. You can sync the
schema, see the drafted and certified joins, run a notebook and get a first
answer from Ask on your laptop, without a warehouse account and without dbt.

It is the same data as the dbt sample,
[jaffle-shop-duckdb](https://github.com/duckcode-ai/jaffle-shop-duckdb), so you
can compare the two paths side by side.

> [!IMPORTANT]
> This folder **is already a ZLens workspace** (`dql.config.json` is at the
> root). Install ZLens into it with `npm install`; do not run
> `npx create-zlens-app` here.

## What is in it

| Path | What it is |
|---|---|
| `jaffle_shop.duckdb` | The warehouse (16 MB). Schema `dev`: `customers`, `orders`, `order_items`, `products`, `locations`, `supplies`, a time spine and six staging views. Schema `raw`: the source tables. |
| `dql.config.json` | Workspace config: the DuckDB connection, `modeling.mode: "warehouse-first"`, the synced schema `dev`, project owner `analytics@jaffle.shop`. |
| `.dql/warehouse-catalog.json` | The synced catalog: tables, views, columns and keys (metadata only, no rows). |
| `domains/dev/modeling/` | Entities and joins drafted from the catalog. Five joins are checked on the data and certified; the staging views stay drafts. |
| `notebooks/welcome.dqlnb` | A starter notebook with two queries. |
| `skills/` | The starter guidance `zlens init` writes for Ask. |
| `scripts/rebuild-warehouse.sh` | How `jaffle_shop.duckdb` was built, and a way to build it again. |

There are no dbt files. Nothing here needs Python.

## Before you start

- Node.js 20, 22 or 24, with 24 LTS recommended (`node -v`). Node 25 and 26
  are not supported yet: ZLens's DuckDB driver has no prebuilt binary for them.
- git

## 1. Install ZLens and open the workbench

```bash
git clone https://github.com/duckcode-ai/jaffle-shop-warehouse.git
cd jaffle-shop-warehouse
npm install
npm install --prefix .dql/connectors duckdb
npm run sync
npm run notebook
```

- `npm install` installs the ZLens CLI (`@zlens/cli`) into this folder.
  `npx zlens …` runs it; no global install is needed.
- The second command installs the DuckDB driver ZLens queries with.
- `npm run sync` runs `zlens sync warehouse`: it reads the schema `dev` again
  and ends with `✓ Warehouse catalog: 13 relation(s) → .dql/warehouse-catalog.json`.
  On this unchanged file only the catalog's `capturedAt` time changes.
- `npm run notebook` prints `Notebook ready: http://127.0.0.1:3474` and opens
  your browser. Leave it running; press `Ctrl+C` to stop it.

## 2. Guided Setup: database only

The first time, ZLens opens **Guided Setup**:

1. **Where does your data model live?** **Open an existing ZLens project**
   is already selected: this folder's `dql.config.json` sets up the data
   model as **Database only**. Click **Continue to credentials**.
2. **Connect and synchronize.** The sample's DuckDB connection is already set
   up: you see **DuckDB · configured** and **Test passed**. Under **Which
   schemas should ZLens read?** the modeling catalog already has 13 tables
   and views (`npm run sync` synchronized it), so there is nothing to
   synchronize. This sample's models are already drafted and reviewed.
   Click **Continue to optional AI**.
3. **Set up an AI provider.** Optional: without one, setup, the notebook,
   Modeling and lineage work, and the AI features (Ask, Ask about an App,
   Notebook AI) say they need a provider. For example
   **Anthropic Claude → Subscription**: if the `claude` CLI is signed in on
   this machine, open **Prefer the CLI?**, then **Test, save & activate**. An
   API key works too; see
   [Set up an AI provider](https://duckcode-ai-labs.github.io/zlens/get-started/ai-provider/).
   Keys stay in `.dql/` on your machine and are ignored by git. Click
   **Continue to finish**.
4. Click **Finish setup**. ZLens opens **Ask**.

## 3. First answer

In **Ask**, try:

```text
Which store locations had the most revenue in 2025?
```

The answer is a table (Philadelphia 354,577.87, Brooklyn 220,455.72) labelled
**AI-drafted answer**: no certified block or metric covers this question, so
the AI wrote the SQL from the schema and joined `orders` to `locations` on the
certified key. Ask says so, and asks you to review the SQL before relying on
it. Ask also saves the answer as a draft block under `blocks/_drafts/`.

More to try:

```text
Who are the top 10 customers by lifetime spend?
How many orders did each store take per month?
Which products bring in the most revenue?
```

## 4. Look around

1. **Modeling.** The map shows the 13 entities ZLens drafted from the
   catalog. The joins in green are **certified**: order lines → orders,
   order lines → products, orders → customers, orders → locations,
   supplies → products. Click one to see the warehouse check behind it
   (every row matched, no null keys, the cardinality it saw).
2. **Notebooks → Domains → dev → welcome.** Click **Run all**: top customers
   by lifetime spend, and monthly revenue by store.
3. **Lineage.** Pick the draft block your first Ask answer saved. The graph
   runs from the warehouse tables (`jaffle_shop.dev.orders`,
   `jaffle_shop.dev.locations`) to the block.

## How this workspace was made

With the ZLens CLI 0.1.0, on the database above, as a database-only team
would:

```bash
npx zlens init --warehouse-first          # modeling.mode: warehouse-first
# identity.owner in dql.config.json set to the project's analytics@jaffle.shop
npx zlens sync warehouse --schemas dev    # catalog: 13 relations
npx zlens model discover --validate       # preview: 13 entities, 23 joins
npx zlens model apply-discovery --apply --validate   # write them as drafts
```

Then the drafts were reviewed in **Modeling**:

- the `product` grain was set to `product_id` and the `supplies` grain to
  `supply_uuid` (both unique on the data; discovery had proposed
  `product_name` and nothing);
- the five joins between the mart tables, each of which passed the warehouse
  check, were certified with owner `analytics@jaffle.shop`
  (`domains/dev/modeling/areas/core.dql.yaml`). In ZLens 0.1.0 the Modeling
  page saves a certified join into that area file and leaves the draft in
  `model.dql.yaml`; the superseded drafts were removed so
  `npm run validate` passes;
- the joins to and between the staging views stay drafts.

To draft again after the schema changes: `npm run sync`, then `npm run draft`
(`zlens model discover --validate`). Discovery never overwrites a human edit or
a certification.

## The warehouse

`jaffle_shop.duckdb` is the database the dbt sample
[jaffle-shop-duckdb](https://github.com/duckcode-ai/jaffle-shop-duckdb) builds
at commit `a9ec277` (`dbt deps`, `dbt seed`, `dbt build` with dbt-duckdb).
`scripts/rebuild-warehouse.sh` repeats that build in a temporary folder and
copies the result here (needs Python 3.9–3.14 for dbt). It builds with
DuckDB 1.4 (`duckdb>=1.4,<1.5`), the release line ZLens reads. Stop the workbench
first, then refresh the catalog with `npm run sync`.

## Useful commands

| Command | Runs |
|---|---|
| `npm run notebook` | `zlens notebook` — the workbench at <http://127.0.0.1:3474> |
| `npm run sync` | `zlens sync warehouse` — re-read the saved schemas into the catalog |
| `npm run draft` | `zlens model discover --validate` — preview new drafts from the catalog |
| `npm run validate` | `zlens validate` and `zlens model validate` |
| `npm run compile` | `zlens compile` — write `dql-manifest.json` |
| `npm run lineage` | `zlens lineage` |
| `npm run doctor` | `zlens doctor` — check Node, the CLI and the DuckDB driver |

## Troubleshooting

- **`ZLens's DuckDB driver has no prebuilt binary for Node 26 yet`.** You are
  on Node 25 or 26. Switch to Node 24 LTS or 22 (`nvm install 24`, or
  `fnm use 24`), then run `npm run notebook` again: the driver installs on its
  own.
- **`Could not set lock on file ".../jaffle_shop.duckdb"`.** Another process
  has the database open, usually the running workbench. Stop it with `Ctrl+C`,
  run your command, then start `npm run notebook` again. (`npm run doctor`
  reports this too while the workbench runs.)
- **`Trying to read a database file with version number 999, but we can only
  read versions between 64 and 67. The database file was created with an
  newer version of DuckDB.`** (in the Setup "Test" button, Settings or
  `npm run doctor`). `jaffle_shop.duckdb` was rewritten by DuckDB 2.0 (for
  example the `duckdb` CLI or Python `duckdb` 2.0), and ZLens reads files from
  DuckDB 1.4. Restore the shipped file with
  `git checkout -- jaffle_shop.duckdb`, or rebuild it with
  `./scripts/rebuild-warehouse.sh`, which pins `duckdb>=1.4,<1.5`. To change
  the file yourself, use DuckDB 1.4 (`pip install 'duckdb>=1.4,<1.5'`).
- **Port 3474 is in use.** Stop the other workbench, or run
  `npx zlens notebook . --port 3480`.
- **Ask says no AI provider is configured.** Finish step 3 of Guided Setup,
  or open **Settings → AI provider**.
- **`git status` shows `.dql/warehouse-catalog.json` changed after a sync.**
  Only its `capturedAt` time changed; the fingerprint stays the same while the
  schema does.

## Licence and credit

MIT, like [jaffle-shop-duckdb](https://github.com/duckcode-ai/jaffle-shop-duckdb);
see [LICENSE](LICENSE). The Jaffle Shop — its story, seed data and models — is
dbt Labs' open-source sandbox project
[dbt-labs/jaffle-shop](https://github.com/dbt-labs/jaffle-shop); see
[NOTICE](NOTICE).
