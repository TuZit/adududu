# Performance Review Report

| Field | Value |
|---|---|
| Project | `{{PROJECT_DIR}}` |
| Run ID | `{{RUN_ID}}` |
| Generated at | `{{GENERATED_AT}}` |
| Git ref | `{{GIT_REF}}` |
| Rule set | `references/performance-rule-list.md` ({{RULE_COUNT}} rules) |
| Rule refresh | `{{GATE_CHOICE}}` |
| Tools run | `{{TOOLS_SUMMARY}}` |

## Verdict

> {{VERDICT}}

<!-- One of: "No material performance risks found ..." / "N material performance finding(s)" -->

## Summary

| Severity | Count |
|---|---|
| Critical | {{COUNT_CRITICAL}} |
| High | {{COUNT_HIGH}} |
| Medium | {{COUNT_MEDIUM}} |
| Low | {{COUNT_LOW}} |

## Findings

<!-- Repeat this block per finding, ordered by severity then confidence. -->

### [PERF-XXX-NNN] Short title

- **Severity:** High
- **Confidence:** High
- **Location:** `path/to/File.java:123`
- **Rule:** `PERF-XXX-NNN`
- **Reference:** `REF-XXX-NN` — exact source locator

**Why it matters:** <performance mechanism and likely consequence>

**Evidence:** <code symbol / line / tool evidence>

**Recommendation:** <concrete remediation>

**False-positive / caveat:** <context where this may be acceptable>

---

## Excluded (non-PERF)

<!-- Findings from tools that are style/correctness/security/a11y, not performance. -->

- `path:line` — <tool> `<rule>` — <reason excluded>

## Tool evidence

| Tool | Status | Report |
|---|---|---|
| pmd | SKIP | — |
| spotbugs | SKIP | — |
| semgrep | SKIP | — |
| sonarqube | SKIP | — |
| biome | OK | `biome-report.json` |

## Coverage & limitations

- Rules evaluated: {{RULE_COUNT}}
- Stacks covered: <Java / Spring-JPA / React-JS / frontend>
- Runtime evidence: <none | profiler | benchmark>
- What static evidence cannot prove: <note>

> This report reflects static/contextual review against the configured PERF taxonomy. It does not claim
> "all performance issues"; it reports material risks found within this scope and evidence.
