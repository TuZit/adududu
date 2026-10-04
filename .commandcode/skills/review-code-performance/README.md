# review-code-performance

AI-agent skill for **performance-focused code review** of Java, JavaScript and React code,
including Spring Boot / JPA / Hibernate where applicable.

## What it does

1. **Asks first** whether to refresh the rule sets from trusted sources (web or MCP fetch) or to
   review with the existing rules (see `SKILL.md` Section 0).
2. Runs the free static analyzers through the scripts in `scripts/` (missing tools are skipped,
   never fatal).
3. Applies the contextual `PERF-*` rules in `references/performance-rule-list.md`, with source
   provenance and a separate confidence rating.
4. Ends every run with one **report folder** per run: `<project>/.perf-reports/<run_id>/`
   (`report.md` + `findings.json` + `meta.json` + tool evidence), linked from `.perf-reports/latest`.

## Structure

```text
review-code-performance/
├── SKILL.md
├── INSTALL.md                           # installing tools + MCP servers
├── references/
│   ├── performance-source-registry.md   # trusted sources + fetch list
│   ├── performance-rule-list.md         # living PERF rule registry (updated on refresh)
│   └── licensing-enterprise.md          # enterprise licensing/legal evaluation
└── scripts/
    ├── run_all_performance.sh           # orchestrator: runs every available tool
    ├── run_pmd_performance.sh           # PMD  (Java, performance ruleset)
    ├── run_spotbugs_performance.sh      # SpotBugs (Java bytecode, PERFORMANCE category)
    ├── run_semgrep_performance.sh       # Semgrep CE (Java + React/JS)
    ├── run_sonarqube_performance.sh     # SonarQube Community Build (fallback; MCP is primary)
    ├── run_eslint_performance.sh        # ESLint (JS/TS/React; fallback; MCP is primary)
    ├── run_biome_performance.sh         # Biome (JS/TS/React)
    ├── container_engine.sh              # Docker → Podman runtime detection (sourced)
    ├── validate_rule_registry.py        # structural check of the rule/source registries
    ├── perf_report.sh                   # per-run report folder: init / latest
    └── docker-compose.yml               # free SonarQube + Postgres stack
```

`assets/report-template.md` is the `report.md` template pre-filled by `perf_report.sh init`.

## Runtime model

1. Ask the rule-set gate question (Section 0).
2. Read `SKILL.md`.
3. Read `references/performance-source-registry.md`.
4. Read `references/performance-rule-list.md`.
5. Inspect the changed code.
6. Run detection: SonarQube + ESLint via their MCP servers, then
   `scripts/run_all_performance.sh` for the remaining scripts (PMD, SpotBugs, Semgrep, Biome).
7. Refresh trusted references when the gate selected it (Section 8).
8. Synthesize/contextualize missing rules and validate provenance.
9. Append eligible rules to the dynamic registry.
10. Produce findings with source provenance and confidence.
11. Validate the registry with `scripts/validate_rule_registry.py`.
12. Write the run report folder via `bash scripts/perf_report.sh init` and fill `report.md` +
    `findings.json` (SKILL.md Step 9) — mandatory even with zero findings.

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
