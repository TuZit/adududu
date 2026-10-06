# review-code-performance

AI-agent skill for **performance-focused code review** of Java, JavaScript and React code,
including Spring Boot / JPA / Hibernate where applicable.

## What it does

1. **Asks first** whether to refresh the rule sets from trusted sources (web or MCP fetch) or to
   review with the existing rules (see `SKILL.md` Section 0).
2. **Resolves the scope deterministically** with `scripts/perf_scope.sh`: which files to review,
   what is excluded (and why), and the exact PERF rules that apply to each file. No file is dropped
   silently — every changed file ends up reviewed or excluded with a reason.
3. Runs the free static analyzers through the scripts in `scripts/` (missing tools are skipped,
   never fatal).
4. Applies the per-file contextual `PERF-*` rules in `references/performance-rule-list.md`, with a
   **positioning pass** (exact `file:line`) and a **reflection pass**, plus source provenance and a
   separate confidence rating.
5. Ends every run with one **report folder** per run: `<project>/.perf-reports/<run_id>/`
   (`scope.json` + `coverage.json` + `report.md` + `findings.json` + `meta.json` + tool evidence),
   linked from `.perf-reports/latest`. The **coverage ledger** must close: no file left `pending`.

## Structure

```text
review-code-performance/
├── SKILL.md
├── INSTALL.md                           # installing tools + MCP servers
├── references/
│   ├── performance-source-registry.md   # trusted sources + fetch list
│   ├── performance-rule-list.md         # living PERF rule registry (updated on refresh)
│   ├── perf-path-rules.json             # glob → PERF rule families (per-file rule matching)
│   └── licensing-enterprise.md          # enterprise licensing/legal evaluation
└── scripts/
    ├── perf_scope.sh                    # deterministic scope + per-file rules + coverage skeleton
    ├── run_all_performance.sh           # orchestrator: runs every available tool
    ├── run_pmd_performance.sh           # PMD  (Java, performance ruleset)
    ├── run_spotbugs_performance.sh      # SpotBugs (Java bytecode, PERFORMANCE category)
    ├── run_semgrep_performance.sh       # Semgrep CE (Java + React/JS)
    ├── run_sonarqube_performance.sh     # SonarQube Community Build (fallback; MCP is primary)
    ├── run_eslint_performance.sh        # ESLint (JS/TS/React; fallback; MCP is primary)
    ├── run_biome_performance.sh         # Biome (JS/TS/React)
    ├── container_engine.sh              # Docker → Podman runtime detection (sourced)
    ├── validate_rule_registry.py        # structural check of the rule/source registries
    ├── perf_report.sh                   # per-run report folder: init (reuse via PERF_RUN_DIR) / latest
    └── docker-compose.yml               # free SonarQube + Postgres stack
```

`assets/report-template.md` is the `report.md` template pre-filled by `perf_report.sh init`.

## Runtime model

1. Ask the rule-set gate question (Section 0).
2. Read `SKILL.md`.
3. **Run `scripts/perf_scope.sh preview`** → reviewable files, exclusions, per-file `rule_ids`,
   `scope.json` + `coverage.json`. Capture `RUN_DIR` and `export PERF_RUN_DIR=<RUN_DIR>`.
4. Read `references/performance-source-registry.md`.
5. Read only the rules resolved for the changed files from `references/performance-rule-list.md`.
6. Inspect the changed code.
7. Run detection: SonarQube + ESLint via their MCP servers, then
   `scripts/run_all_performance.sh` for the remaining scripts (PMD, SpotBugs, Semgrep, Biome) —
   it reuses `PERF_RUN_DIR`, so the run keeps one `run_id`.
8. Refresh trusted references when the gate selected it (Section 8).
9. Synthesize/contextualize missing rules and validate provenance.
10. Apply the **positioning pass** and the **reflection pass** to candidate findings.
11. Produce findings with source provenance and confidence.
12. Validate the registry with `scripts/validate_rule_registry.py`.
13. **Close the coverage ledger** (no file left `pending`) and write the run report folder via
    `bash scripts/perf_report.sh init` + fill `report.md`, `coverage.json`, `findings.json`
    (SKILL.md Step 9) — mandatory even with zero findings.

## Deterministic scope

```bash
bash scripts/perf_scope.sh preview . [--from main --to feature] [--commit abc123] \
     [--exclude '**/generated/**,**/testdata/**'] [--format json|text]
```

- Prints scope JSON to stdout; `RUN_DIR=<path>` to stderr; writes `scope.json` + `coverage.json`.
- Excludes build output, vendored, generated, lockfiles, snapshots, deleted files, non
  Java/JS/React files (all with a reason), plus `--exclude` patterns and a project
  `.perf-excludes` file (one pattern per line).
- Resolves each file's PERF rules via `references/perf-path-rules.json` (glob → rule family;
  Spring/JPA families attach only when a Spring project is detected).

## Free tooling

All analyzers are free/open source. Each script prints one `STATUS: OK | SKIP | FAIL` line and
writes evidence to `<PROJECT_DIR>/.perf-reports/`:

```bash
bash scripts/run_all_performance.sh . --tools pmd,spotbugs,semgrep,biome,eslint
```

- PMD: container image `pmd/pmd`, or `brew install pmd`
- SpotBugs: `brew install spotbugs`, `SPOTBUGS_HOME`, or a project Maven/Gradle plugin
- Semgrep: container image `semgrep/semgrep`, or `pipx install semgrep` / `brew install semgrep`
- SonarQube: **via MCP** (`mcp__sonarqube__*`) when configured; otherwise the script auto-starts it via `docker compose`/`podman-compose` + `scripts/docker-compose.yml`, then set `SONAR_TOKEN`
- ESLint: **via MCP** (`mcp__ESLint__lint-files`) when configured; otherwise the CLI script (`eslint --format json`, project config) or `npx`
- Biome: comes with Node via `npx @biomejs/biome`

Tool execution model: the scripts prefer a **self-contained container image** (nothing to install) and
fall back to a local binary; `PERF_PREFER_LOCAL=1` reverses that order. `scripts/container_engine.sh`
prefers **Docker** and falls back to **Podman** (`docker`/`podman` plus `docker compose`/`podman-compose`
are all supported). An engine is used only when its CLI exists and `<engine> info` succeeds; if neither
is usable, the tool reports `SKIP` instead of failing.

## Licensing (enterprise)

All analyzers are free for enterprise use. The only real risks are **Docker Desktop** (paid
subscription at 250+ employees / $10M+ revenue — prefer Podman) and **Semgrep rules**
(internal-use-only). See `references/licensing-enterprise.md` for the full evaluation.

## Installing

See `INSTALL.md` for installing each tool and the MCP servers (SonarQube, ESLint, fetch).

## Important

The Python validator does not call an LLM or the public web. It validates the artifact produced
by the agent runtime. The active agent/model is responsible for web fetching (built-in
`web_fetch` or an MCP fetch server) and rule synthesis.
