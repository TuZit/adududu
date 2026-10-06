# Performance Skill – Trusted Source Registry

This registry is the **knowledge foundation** for LLM-generated performance rules. It is also the
fetch list used by the Section 8 rule refresh.

## Source tiers

- **Tier 1 – Core Authority:** official framework/tool documentation that describes performance behavior or explicit performance rules.
- **Tier 2 – Supporting Evidence:** respected engineering methodology or production-scale case studies.
- **Tier 3 – Detection Tooling:** tools used to detect or validate patterns; not the sole authority for a performance claim.

## How to fetch (refresh mode)

When the run-time gate (SKILL.md Section 0) selects a refresh, fetch the URLs below with, in order:

1. the built-in `web_fetch` / `web_search` tools;
2. an installed MCP fetch/HTTP server (e.g. `mcp__*fetch*`);
3. any other configured retriever.

Fetch only the sections relevant to the changed technology. Record the exact URL and access date
for every extracted rule. Prefer exact rule/section URLs when the source provides them.

## Core sources

| Select | ID | Tier | Source | Current / version policy | Main use | Exact/related performance areas | Detection support |
|---|---|---|---|---|---|---|---|
| [x] | REF-JAVA-01 | 1 | [PMD – Java Performance](https://pmd.github.io/pmd/pmd_rules_java_performance.html) | Use installed PMD version; record version when generated | Java code-level performance rules | String operations, array loops/copying, object creation/allocation, collections, inefficient APIs | PMD CLI, Maven/Gradle, IDE plugins |
| [x] | REF-JAVA-02 | 1 | [SpotBugs – Bug Descriptions](https://spotbugs.readthedocs.io/en/stable/bugDescriptions.html) | Use installed SpotBugs version; record version when generated | Java static/bytecode performance patterns | `PERFORMANCE` findings, inefficient operations, blocking/expensive patterns | SpotBugs CLI, Maven/Gradle |
| [x] | REF-SPRING-01 | 1 | [Hibernate ORM User Guide](https://docs.hibernate.org/orm/current/userguide/html_single/) | Match project Hibernate version where possible | JPA/Hibernate/DB performance | fetching, N+1, batch fetching, JDBC batching, result fetching, persistence context | Query logs, Hibernate statistics, p6spy/datasource-proxy for evidence |
| [x] | REF-SPRING-02 | 1 | [Spring Data JPA Reference](https://docs.spring.io/spring-data/jpa/reference/) | Match project Spring Data JPA version where possible | Repository/query performance | paging, `Page` vs `Slice`, count queries, offset pagination, scrolling, limits | Repository/query analysis, SQL observation tools |
| [x] | REF-REACT-01 | 1 | [React `memo`](https://react.dev/reference/react/memo) · [React `useMemo`](https://react.dev/reference/react/useMemo) · [React `useCallback`](https://react.dev/reference/react/useCallback) | Match project React version where possible | React rendering/memoization | unnecessary re-renders, expensive calculations, unstable identities, appropriate memoization | React DevTools Profiler, AST/ESLint |
| [x] | REF-REACT-02 | 1 | [React – eslint-plugin-react-hooks](https://react.dev/reference/eslint-plugin-react-hooks) | Match installed plugin version | Machine-detectable React patterns with performance implications | `set-state-in-effect`, `set-state-in-render`, `static-components`, `use-memo`, memoization-related diagnostics | ESLint + `eslint-plugin-react-hooks` |
| [x] | REF-REACT-03 | 1 | [Vercel – React Best Practices (agent-skills)](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices) | Vendor-curated, impact-tagged rule set (MIT); rule files under `rules/` are the locators. Use for client-side React/JS only — **not** the `async-*`/`server-*` (Next.js/RSC) families | React/JS client-side performance patterns | re-render optimization, rendering performance, bundle size, client data fetching, JS micro-performance | ESLint/Biome, React DevTools Profiler, bundle analyzer |
| [x] | REF-FE-01 | 1 | [web.dev – Optimize long tasks](https://web.dev/articles/optimize-long-tasks) · [web.dev – Code splitting](https://web.dev/articles/reduce-javascript-payloads-with-code-splitting) | Current published guidance | Browser/frontend performance | main-thread blocking, long tasks, JavaScript startup payload, code splitting | Lighthouse, Chrome DevTools |

## Supporting sources

| Select | ID | Tier | Source | Main use | Do not use as |
|---|---|---|---|---|---|
| [x] | REF-ARCH-01 | 2 | [AWS Well-Architected – Performance Efficiency](https://docs.aws.amazon.com/wellarchitected/latest/performance-efficiency-pillar/welcome.html) · [PERF01-BP06 Benchmarking](https://docs.aws.amazon.com/wellarchitected/2024-06-27/framework/perf_architecture_use_benchmarking.html) | Benchmarking, evidence-driven performance decisions, performance methodology | Sole source for a syntax-level performance rule |
| [x] | REF-ARCH-02 | 2 | [Meta Engineering – Tech stack rebuild for Facebook.com](https://engineering.fb.com/2020/05/08/web/facebook-redesign/) | Production-scale frontend evidence, code-splitting/loading strategy | Sole source for a generic React rule |

## Detection tools

| Select | ID | Tier | Tool | Role | License / availability | Authority? |
|---|---|---|---|---|---|---|
| [x] | TOOL-SEMGREP | 3 | [Semgrep Community Edition](https://semgrep.dev/products/community-edition/) | Custom AST/pattern detection for rules synthesized from the trusted references | Engine LGPL-2.1; rules "Semgrep Rules License v1.0" (internal use only) | No |
| [x] | TOOL-PMD | 3 | [PMD](https://pmd.github.io/) | Deterministic Java pattern detection | Open source | Yes, only for its own documented rules; still preserve provenance |
| [x] | TOOL-SPOTBUGS | 3 | [SpotBugs](https://spotbugs.readthedocs.io/) | Bytecode/static Java evidence | Open source | Yes, only for its own documented findings; still preserve provenance |
| [x] | TOOL-SONAR | 3 | [SonarQube Community Build – Rules](https://docs.sonarsource.com/sonarqube-community-build/quality-standards-administration/managing-rules/rules) | Aggregation/detection; use only explicit performance mechanisms | LGPL-3.0 (Community Build) | No |
| [x] | TOOL-ESLINT | 3 | [ESLint](https://eslint.org/) + [React hooks plugin](https://react.dev/reference/eslint-plugin-react-hooks) | React/JS static detection | Open source | No, unless a specific documented rule is itself the authority |
| [x] | TOOL-BIOME | 3 | [Biome](https://biomejs.dev/) | Fast JS/TS/React lint detection used as evidence | Open source | No |

## Source-selection principles

1. Prefer official documentation from the framework/tool maintainer.
2. Prefer a source that explains **why** the pattern affects performance, not just that it is a style preference.
3. Prefer sources that expose exact examples or named rules.
4. Prefer current versioned documentation and record the project dependency version.
5. Keep production case studies separate from normative framework rules.
6. Never treat security, clean-code, naming, architecture-only, or maintainability sources as Phase-1 performance authority.

## Licensing (enterprise)

For the licensing/legal status of each detection tool in an enterprise (not individual) setting,
see `references/licensing-enterprise.md`. Key points: all analyzers are free for enterprise use, but
**Docker Desktop** is a paid subscription at 250+ employees / $10M+ revenue (prefer Podman), and
**Semgrep rules** are licensed for internal business use only.

## Reference verification date

- Verified against accessible official source pages: **2026-10-04**.
- Dynamic refresh is still required when the agent needs current/version-specific information.
