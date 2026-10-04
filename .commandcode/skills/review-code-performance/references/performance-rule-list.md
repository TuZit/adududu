# Performance Rule List – Phase 1 + Dynamic Registry

This file is the **living rule registry** referenced by `SKILL.md` Section 3.2. It is the file
updated by the Section 8 refresh.

Legend:

- `[x] selected` = active rule family the agent may use.
- `[ ] proposed` = discovered but not yet promoted.
- `[~] contextual` = use only when the listed context is established.
- `[d] deprecated` = retained for provenance but should no longer generate new findings.

The LLM may add rules during a Section 8 refresh when all promotion gates pass. Existing selected
rules MUST NOT be removed merely because a refresh does not rediscover them.

---

## Java

| Select | Rule ID | Rule | Type | Default severity | Source(s) | Detection | Coverage intent |
|---|---|---|---|---|---|---|---|
| [x] | PERF-JAVA-001 | Object allocation inside repeated loops | direct/contextual | Medium | REF-JAVA-01 | AST/PMD + context | Cover avoidable per-iteration allocation |
| [x] | PERF-JAVA-002 | Manual array copying where optimized array-copy API applies | direct | Medium | REF-JAVA-01 | AST/PMD | Cover inefficient data movement |
| [x] | PERF-JAVA-003 | Inefficient String construction/conversion | direct | Medium | REF-JAVA-01, REF-JAVA-02 | AST/static | Cover unnecessary temporary String objects |
| [x] | PERF-JAVA-004 | Inefficient empty/blank String check that creates avoidable temporary values | direct | Medium | REF-JAVA-01 | AST/PMD | Cover avoidable String work for simple checks |
| [x] | PERF-JAVA-005 | Redundant String conversion / `toString()` | direct | Low | REF-JAVA-01 | AST/PMD | Cover unnecessary conversion work |
| [x] | PERF-JAVA-006 | Consecutive String append pattern that can be reused/consolidated | direct | Low | REF-JAVA-01 | AST/PMD | Cover avoidable StringBuilder/StringBuffer overhead |
| [x] | PERF-JAVA-007 | Literal/string append pattern with cheaper equivalent | direct | Low | REF-JAVA-01 | AST/PMD | Cover small but deterministic String append inefficiencies |
| [x] | PERF-JAVA-008 | Inefficient wrapper/value construction where documented alternatives exist | direct/contextual | Low | REF-JAVA-01, REF-JAVA-02 | AST/static | Cover unnecessary wrapper/value allocation |
| [x] | PERF-JAVA-009 | Repeated heavyweight object creation on a repeated path | contextual | Medium | REF-JAVA-01 | AST + call-path + LLM | Cover avoidable construction cost when reuse is safe |
| [x] | PERF-JAVA-010 | Inefficient collection implementation/API usage | contextual | Medium | REF-JAVA-01 | AST + context | Cover data-structure overhead while preserving semantics |
| [x] | PERF-JAVA-011 | Avoidable `toArray` allocation/copy pattern | direct | Low | REF-JAVA-01 | AST/PMD | Cover unnecessary array allocation/copy |
| [x] | PERF-JAVA-012 | Explicit `System.gc()` outside justified benchmarking/tooling | direct/contextual | Medium | REF-JAVA-02, REF-JAVA-01 | AST + context | Cover forced GC interference in application code |
| [x] | PERF-JAVA-013 | Blocking/expensive library operation in a high-frequency or repeated path | contextual/runtime_evidence | High | REF-JAVA-02 | static + call-path + runtime | Cover potentially expensive standard-library operations only with evidence of a meaningful path |
| [x] | PERF-JAVA-014 | Pattern-compilation or similar setup repeated in a loop | direct/contextual | Medium | REF-JAVA-02 | static/bytecode | Cover repeated setup work documented by SpotBugs |
| [x] | PERF-JAVA-015 | Repeated preparation of DB statements in loops when batching/reuse is applicable | contextual | High | REF-JAVA-02, REF-SPRING-01 | AST + JDBC context | Cover repeated DB setup / round trips |

---

## Spring Boot / JPA / Hibernate

| Select | Rule ID | Rule | Type | Default severity | Source(s) | Detection | Coverage intent |
|---|---|---|---|---|---|---|---|
| [x] | PERF-SPRING-001 | Potential N+1 query | contextual | High | REF-SPRING-01 | AST + ORM relationship + call path + LLM | Cover repeated SELECTs caused by association/query access per item |
| [x] | PERF-SPRING-002 | EAGER association causing hidden secondary selects | contextual | Medium | REF-SPRING-01 | entity metadata + SQL evidence | Cover hidden fetch amplification |
| [x] | PERF-SPRING-003 | Missing query-specific fetch plan for required relational data | contextual | Medium | REF-SPRING-01, REF-SPRING-02 | repository/query + entity graph analysis | Cover avoidable secondary queries / over-fetching trade-offs |
| [x] | PERF-SPRING-004 | Batch-fetching opportunity for repeated association loads | contextual | Medium | REF-SPRING-01 | ORM metadata + access pattern | Cover repeated association loading where batching can reduce round trips |
| [x] | PERF-SPRING-005 | Avoidable JDBC round trips for bulk writes | contextual | High | REF-SPRING-01 | transaction/loop + JDBC context | Cover repeated insert/update operations that are batchable |
| [x] | PERF-SPRING-006 | Oversized transaction / unit of work causing unnecessary persistence-context growth | contextual | Medium | REF-SPRING-01 | transaction + loop + persistence-context analysis | Cover memory pressure and flush overhead in large batches |
| [x] | PERF-SPRING-007 | Unbounded result retrieval | contextual | High | REF-SPRING-02 | repository signature + query/caller context | Cover accidental full-dataset materialisation |
| [x] | PERF-SPRING-008 | `Page` used when total-count metadata is unnecessary | contextual | Medium | REF-SPRING-02 | repository + caller context | Cover avoidable `COUNT` query cost |
| [x] | PERF-SPRING-009 | Large-offset pagination | contextual | Medium | REF-SPRING-02 | pagination + query context | Cover offset inefficiency at scale |
| [x] | PERF-SPRING-010 | Missing result limiting when caller only needs top/first-N | contextual | Medium | REF-SPRING-02 | repository + caller intent | Cover unnecessary result processing and transfer |
| [x] | PERF-SPRING-011 | Large result-set materialisation where scrolling/chunking is more appropriate | contextual | High | REF-SPRING-02 | repository return type + caller flow | Cover memory pressure and large result processing |
| [x] | PERF-SPRING-012 | Repository/query call repeated inside iteration | contextual | High | REF-SPRING-01, REF-SPRING-02 | call graph + loop + query semantics | Generalize repeated round-trip detection beyond associations |
| [x] | PERF-SPRING-013 | Excessive fetch graph / over-fetching | contextual | Medium | REF-SPRING-01 | entity/query graph + DTO requirements | Cover fetching substantially more data than the use case requires |
| [x] | PERF-SPRING-014 | Large collection fetched eagerly when use case does not require it | contextual | Medium | REF-SPRING-01 | entity mapping + call context | Cover unnecessary data loading and persistence-context cost |
| [x] | PERF-SPRING-015 | Large batch insert/update without periodic flush/clear where memory pressure is credible | contextual | Medium | REF-SPRING-01 | transaction + loop + entity count context | Cover first-level-cache growth in large batches |

---

## React / JavaScript

| Select | Rule ID | Rule | Type | Default severity | Source(s) | Detection | Coverage intent |
|---|---|---|---|---|---|---|---|
| [x] | PERF-REACT-001 | Synchronous state update inside Effect | direct | Medium | REF-REACT-02 | ESLint/static | Cover extra render cycles explicitly documented by React |
| [x] | PERF-REACT-002 | Unconditional state update during render | direct | High | REF-REACT-02 | ESLint/static | Cover repeated/infinite render work |
| [x] | PERF-REACT-003 | Component recreation during render | direct | Medium | REF-REACT-02 | ESLint/static | Cover component remounting/re-render overhead |
| [x] | PERF-REACT-004 | Object/array prop identity defeats child memoization | contextual | Medium | REF-REACT-01 | AST/data-flow + LLM | Cover ineffective `memo` when references change every render |
| [x] | PERF-REACT-005 | Function prop identity defeats child memoization | contextual | Medium | REF-REACT-01 | AST/data-flow + LLM | Cover ineffective memoization from unstable callbacks |
| [x] | PERF-REACT-006 | Expensive calculation repeated on render | contextual | Medium | REF-REACT-01 | AST heuristic + LLM | Cover repeated compute only when cost and rerender frequency make it meaningful |
| [x] | PERF-REACT-007 | Effect-driven derived-state render chain | contextual | Medium | REF-REACT-02, REF-REACT-01 | AST + LLM | Cover avoidable extra rendering from derivable state |
| [x] | PERF-REACT-008 | Hook dependency pattern with concrete repeated-work performance impact | contextual | Medium | REF-REACT-02 | ESLint + LLM | Only classify as PERF when dependency behavior demonstrably causes extra work |
| [x] | PERF-REACT-009 | Ineffective or unnecessary manual memoization | contextual | Low | REF-REACT-01 | LLM + render evidence | Avoid both over-memoization and false positives; require contextual justification |
| [x] | PERF-REACT-010 | Large synchronous transformation on interaction/render path | contextual/runtime_evidence | High | REF-REACT-01, REF-FE-01 | AST + cardinality + runtime | Cover main-thread blocking patterns when work is meaningfully large |
| [x] | PERF-REACT-011 | Expensive rendering of large collections without a justified strategy | contextual | High | REF-REACT-01, REF-FE-01 | JSX/list analysis + LLM | Cover render amplification on large datasets; do not assume virtualization is always required |

---

## Frontend loading / browser

| Select | Rule ID | Rule | Type | Default severity | Source(s) | Detection | Coverage intent |
|---|---|---|---|---|---|---|---|
| [x] | PERF-FE-001 | Excessive initial JavaScript payload | contextual | High | REF-FE-01, REF-ARCH-02 | bundle graph + build stats + LLM | Cover unnecessary startup JS on critical paths |
| [x] | PERF-FE-002 | Missing code splitting for clearly deferred/rarely used feature | contextual | Medium | REF-FE-01, REF-ARCH-02 | import graph + route/feature context | Cover opportunities for incremental loading |
| [x] | PERF-FE-003 | Ineffective dynamic-loading strategy that still pulls non-critical code into startup | contextual | Medium | REF-FE-01 | bundle graph + runtime loading evidence | Cover fake/degraded code-splitting patterns |
| [x] | PERF-FE-004 | Large synchronous main-thread computation | contextual/runtime_evidence | High | REF-FE-01 | static heuristic + Chrome DevTools/Lighthouse | Cover likely long-task work without pretending source proves duration |
| [x] | PERF-FE-005 | Large synchronous loop/transformation on user interaction path | contextual/runtime_evidence | High | REF-FE-01 | AST + data size + runtime evidence | Cover interaction blocking when cardinality/work is non-trivial |
| [x] | PERF-FE-006 | Critical-path feature ships substantial code that can be deferred | contextual | Medium | REF-FE-01, REF-ARCH-02 | route/import analysis | Cover startup optimization opportunities |

---

## Evidence / methodology

| Select | Rule ID | Rule | Type | Default severity | Source(s) | Detection | Coverage intent |
|---|---|---|---|---|---|---|---|
| [x] | PERF-EVIDENCE-001 | Static pattern is insufficient to claim actual runtime degradation | runtime_evidence | Low | REF-ARCH-01 | policy/LLM | Prevent overconfident static claims; recommend benchmark/profile |
| [x] | PERF-EVIDENCE-002 | Performance optimization recommendation lacks workload/cardinality evidence | contextual | Low | REF-ARCH-01 | LLM | Encourage measurement-driven review for contextual optimizations |

---

## Explicit non-rules

These are intentionally NOT selected:

```text
[ ] Every loop is a performance problem
[ ] Every findAll() is a performance problem
[ ] Missing memo/useMemo/useCallback is automatically a performance problem
[ ] Any function over a static time threshold is a static violation
[ ] CPU > 80% is a code rule
[ ] GC pause > X ms is a code rule
[ ] P99 > X ms is a code rule
[ ] INP > X ms is a source-code rule
[ ] Add caching everywhere
[ ] Generic clean-code rules
[ ] Generic Sonar maintainability/code-smell rules
[ ] Security rules
[ ] Naming/formatting/convention rules
```

---

## Dynamic additions

New rules discovered during a refresh are appended below this line.

Rules added here must include:

- `status`
- `introduced_at`
- `last_verified_at`
- `source_ids`
- `source_locator`
- `performance_mechanism`
- `detection`
- `false_positive`
- `golden_set`

---

### PERF-JAVA-016 — FileInputStream/FileOutputStream finalizer GC pauses

- status: selected
- introduced_at: 2026-10-05
- last_verified_at: 2026-10-05
- source_ids: [REF-JAVA-01]
- source_locator: PMD `AvoidFileStream` (category/java/performance.xml/AvoidFileStream)
- performance_mechanism: `java.io.FileInputStream`/`FileOutputStream` (and `FileReader`/`FileWriter`) have finalizer methods that cause garbage-collection pauses; use `Files.newInputStream/newOutputStream/newBufferedReader/newBufferedWriter` (java.nio) instead.
- detection: AST — constructor calls of `java.io.FileInputStream` / `FileOutputStream` / `FileReader` / `FileWriter`
- false_positive: code that must keep `FileNotFoundException` semantics (NIO throws `NoSuchFileException`), or rare/one-shot use where the pause is negligible
- golden_set: positive `new FileInputStream(path)`; negative `Files.newInputStream(Paths.get(path))`; edge: `FileReader` replaced by `Files.newBufferedReader` changes the thrown exception type

### PERF-JAVA-017 — Heavyweight Calendar/Date construction

- status: selected
- introduced_at: 2026-10-05
- last_verified_at: 2026-10-05
- source_ids: [REF-JAVA-01]
- source_locator: PMD `AvoidCalendarDateCreation` (category/java/performance.xml/AvoidCalendarDateCreation)
- performance_mechanism: `java.util.Calendar` (and `getInstance()`/`getTime()`) is a heavyweight object to create; use `new Date()`, `System.currentTimeMillis()`, or `java.time` when no calendar arithmetic is needed.
- detection: AST — `Calendar.getInstance()` / `GregorianCalendar` construction chained to `getTime()` / `getTimeInMillis()`
- false_positive: code genuinely requiring calendar arithmetic (`set`/`add`/`roll`/`clear`) or specific timezone/calendar semantics
- golden_set: positive `Calendar.getInstance().getTime()`; negative `new Date()` / `LocalDateTime.now()`; edge: `Calendar.getInstance()` used for arithmetic → not a violation

---

_Registry verified: 2026-10-05._
