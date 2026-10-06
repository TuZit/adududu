# Performance Rule List – Phase 1 + Dynamic Registry

This file is the **living rule registry** referenced by `SKILL.md` Section 3.2. It is the file
updated by the Section 8 refresh.

Path → rule matching lives separately in `references/perf-path-rules.json`; `perf_scope.sh` uses it
to attach only the relevant families to each changed file (SKILL.md Step 1/2). Per-file coverage is
tracked in the run's `coverage.json` (SKILL.md Section 6 / Step 6.2).

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
| [x] | PERF-REACT-012 | State read only in callbacks subscribed during render | contextual | Medium | REF-REACT-03 | AST + LLM | Cover unnecessary re-renders from subscribing to state a callback alone consumes (Vercel `rerender-defer-reads`) |
| [x] | PERF-REACT-013 | Expensive work in a parent that a memoized child could isolate | contextual | Medium | REF-REACT-03, REF-REACT-01 | AST + LLM | Cover expensive re-computation not isolated by `memo` (Vercel `rerender-memo`) |
| [x] | PERF-REACT-014 | Non-primitive default prop recreated each render defeats `memo` | contextual | Low | REF-REACT-03 | AST/data-flow | Cover default `[]`/`{}` props defeating child memoization (Vercel `rerender-memo-with-default-value`) |
| [x] | PERF-REACT-015 | Non-primitive effect dependency causes extra effect runs | contextual | Medium | REF-REACT-03 | AST/data-flow + LLM | Cover effect re-runs from object/function deps (Vercel `rerender-dependencies`) |
| [x] | PERF-REACT-016 | Subscribing to a raw value where a derived boolean suffices | contextual | Medium | REF-REACT-03 | AST + LLM | Cover re-renders from raw-value subscriptions (Vercel `rerender-derived-state`) |
| [x] | PERF-REACT-017 | Expensive `useState` initializer invoked on every render | contextual | Medium | REF-REACT-03 | AST | Cover expensive init work repeated by eager initializer (Vercel `rerender-lazy-state-init`) |
| [x] | PERF-REACT-018 | Interaction logic placed in an Effect instead of an event handler | contextual | Medium | REF-REACT-03 | AST + LLM | Cover extra render/effect cycles from effect-driven interactions (Vercel `rerender-move-effect-to-event`) |
| [x] | PERF-REACT-019 | Non-urgent update blocks urgent updates (no `startTransition`) | contextual | Medium | REF-REACT-03 | AST + LLM | Cover main-thread blocking of urgent updates (Vercel `rerender-transitions`) |
| [x] | PERF-REACT-020 | Expensive render driven by input not deferred (`useDeferredValue`) | contextual | Medium | REF-REACT-03 | AST + LLM | Cover input jank from expensive dependent renders (Vercel `rerender-use-deferred-value`) |
| [x] | PERF-REACT-021 | High-frequency transient value kept in state instead of a ref | contextual | Low | REF-REACT-03 | AST + LLM | Cover re-render storms from transient values (Vercel `rerender-use-ref-transient-values`) |
| [x] | PERF-REACT-022 | Long list rendered without `content-visibility` containment | contextual | Medium | REF-REACT-03 | JSX/list + CSS analysis | Cover off-screen rendering cost on long lists (Vercel `rendering-content-visibility`) |
| [x] | PERF-REACT-023 | Static JSX/element tree allocated inside a component each render | contextual | Low | REF-REACT-03 | AST | Cover avoidable per-render element allocation (Vercel `rendering-hoist-jsx`) |

---

## JavaScript

Language-level JavaScript performance patterns (framework-agnostic, client-side only). Source:
Vercel React Best Practices `js-*` family (`REF-REACT-03`), applied to `.js/.jsx/.ts/.tsx`.

| Select | Rule ID | Rule | Type | Default severity | Source(s) | Detection | Coverage intent |
|---|---|---|---|---|---|---|---|
| [x] | PERF-JS-001 | DOM/CSS style changes applied one-by-one causing repeated reflow | contextual | Medium | REF-REACT-03 | AST + context | Cover layout thrashing from per-property style writes (Vercel `js-batch-dom-css`) |
| [x] | PERF-JS-002 | Repeated linear lookups instead of building an index map | contextual | Medium | REF-REACT-03 | AST + loop analysis | Cover O(n·m) `find`/`filter` lookups (Vercel `js-index-maps`) |
| [x] | PERF-JS-003 | Repeated property/array access in a hot loop not cached | contextual | Low | REF-REACT-03 | AST + loop analysis | Cover repeated deep property access in loops (Vercel `js-cache-property-access`) |
| [x] | PERF-JS-004 | Recomputing expensive pure results instead of caching | contextual | Medium | REF-REACT-03 | AST + LLM | Cover repeated expensive pure computation (Vercel `js-cache-function-results`) |
| [x] | PERF-JS-005 | Repeated `localStorage`/`sessionStorage` reads on a hot path | contextual | Low | REF-REACT-03 | AST + context | Cover synchronous storage reads in loops/renders (Vercel `js-cache-storage`) |
| [x] | PERF-JS-006 | Multiple passes over the same array (e.g. `filter().map()`) | contextual | Low | REF-REACT-03 | AST + loop analysis | Cover extra array traversals/allocation (Vercel `js-combine-iterations`) |
| [x] | PERF-JS-007 | `RegExp` constructed inside a loop or hot path | contextual | Low | REF-REACT-03 | AST/static | Cover repeated RegExp compilation (Vercel `js-hoist-regexp`) |
| [x] | PERF-JS-008 | `sort()` used only to compute min/max instead of a loop | contextual | Low | REF-REACT-03 | AST | Cover O(n log n) sort for an O(n) need (Vercel `js-min-max-loop`) |
| [x] | PERF-JS-009 | Array membership scan (`includes`/`indexOf`) instead of `Set`/`Map` | contextual | Medium | REF-REACT-03 | AST + context | Cover O(n) membership checks in loops (Vercel `js-set-map-lookups`) |
| [x] | PERF-JS-010 | Non-critical work not deferred to browser idle time | contextual | Medium | REF-REACT-03 | AST + call context | Cover main-thread work that could use `requestIdleCallback` (Vercel `js-request-idle-callback`) |

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
| [x] | PERF-FE-007 | Missing resource hints (`preload`/`preconnect`) for critical assets | contextual | Medium | REF-REACT-03 | markup/asset graph + LLM | Cover late discovery of critical resources (Vercel `rendering-resource-hints`) |
| [x] | PERF-FE-008 | Blocking third-party/critical-path script without `defer`/`async` | contextual | High | REF-REACT-03, REF-FE-01 | markup analysis | Cover render-blocking scripts on the critical path (Vercel `rendering-script-defer-async`) |
| [x] | PERF-FE-009 | Duplicate in-flight client requests without deduplication/caching | contextual | Medium | REF-REACT-03 | AST + call-site analysis | Cover repeated network round trips for the same data (Vercel `client-swr-dedup`) |
| [x] | PERF-FE-010 | Duplicate / uncleaned global event listeners | contextual | Low | REF-REACT-03 | AST + lifecycle analysis | Cover listener accumulation across mounts (Vercel `client-event-listeners`) |
| [x] | PERF-FE-011 | Non-passive `scroll`/`touch` listener blocking scrolling | contextual | Low | REF-REACT-03 | AST/static | Cover scroll jank from non-passive listeners (Vercel `client-passive-event-listeners`) |

---

## Vercel React Best Practices (REF-REACT-03) — locators, false positives, golden sets

Source: [vercel-labs/agent-skills – react-best-practices](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices)
(MIT). `locator` = the rule file under `rules/`. Vercel `impact` is mapped **down** to the skill's
severity ladder (its `CRITICAL` is not this skill's `Critical`); raise only with runtime evidence per
Section 4.

### Re-render / rendering

| Rule ID | Locator (`rules/…`) | False positive / caveat | Golden set (positive / negative / edge) |
|---|---|---|---|
| PERF-REACT-012 | `rerender-defer-reads` | Value is needed during render, or the state rarely changes | pos: subscribe to state used only in a click handler / neg: value read during render / edge: value read in an effect with rare deps |
| PERF-REACT-013 | `rerender-memo` | Work is already cheap or the component rarely re-renders | pos: expensive formatting recomputed for each child / neg: `memo`-wrapped child with stable props / edge: expensive but re-render frequency is ~1 |
| PERF-REACT-014 | `rerender-memo-with-default-value` | Default is a primitive, or `memo` is not used | pos: `items = []` default recreated each render / neg: default hoisted to a module constant / edge: default never used because the prop is always passed |
| PERF-REACT-015 | `rerender-dependencies` | Object dep is intentional (deep change should re-run) | pos: effect depends on an object literal recreated each render / neg: primitive deps / edge: object memoized with `useMemo` |
| PERF-REACT-016 | `rerender-derived-state` | Component consumes the raw value elsewhere anyway | pos: `width` state used only as `width > 1000` / neg: derived boolean subscription / edge: raw value also rendered |
| PERF-REACT-017 | `rerender-lazy-state-init` | Initializer is cheap | pos: `useState(expensiveCalc())` / neg: `useState(() => expensiveCalc())` / edge: cheap initializer |
| PERF-REACT-018 | `rerender-move-effect-to-event` | Logic must run on mount or on external prop change | pos: submit handled in `useEffect` on state change / neg: handler in `onSubmit` / edge: side effect must sync with an external store |
| PERF-REACT-019 | `rerender-transitions` | Update is genuinely urgent or cheap | pos: filtering a large list on every keystroke without `startTransition` / neg: non-urgent update wrapped / edge: list already small |
| PERF-REACT-020 | `rerender-use-deferred-value` | Dependent render is cheap | pos: heavy chart re-rendered on every keystroke / neg: `useDeferredValue` / edge: child already isolates cost via `memo` |
| PERF-REACT-021 | `rerender-use-ref-transient-values` | Value drives rendering | pos: pointer position stored in state / neg: stored in a ref / edge: value rendered once per gesture end |
| PERF-REACT-022 | `rendering-content-visibility` | List is small or layout measurement depends on rendering all rows | pos: 1000-row list without containment / neg: CSS `content-visibility: auto` / edge: cheap fixed-height rows |
| PERF-REACT-023 | `rendering-hoist-jsx` | JSX depends on props/state each render | pos: static SVG tree recreated each render / neg: hoisted module-level constant / edge: JSX is tiny |

### Frontend loading / client data

| Rule ID | Locator (`rules/…`) | False positive / caveat | Golden set (positive / negative / edge) |
|---|---|---|---|
| PERF-FE-007 | `rendering-resource-hints` | Asset is not on the critical path or already cached | pos: critical hero image without `preload`/`preconnect` / neg: `<link rel="preload">` / edge: asset served from the same edge cache |
| PERF-FE-008 | `rendering-script-defer-async` | Script must run synchronously before render | pos: blocking third-party `<script>` in head / neg: `defer` / edge: inline critical bootstrap |
| PERF-FE-009 | `client-swr-dedup` | Requests are genuinely distinct or already cached | pos: two components fetch the same endpoint on mount / neg: shared cache (SWR/React Query) / edge: one call is a mutation |
| PERF-FE-010 | `client-event-listeners` | Listener count is small and static | pos: `addEventListener` in a component without cleanup on remount / neg: single listener with cleanup / edge: listener added once at app init |
| PERF-FE-011 | `client-passive-event-listeners` | Handler calls `preventDefault` | pos: non-passive `scroll`/`touchmove` listener / neg: `{ passive: true }` / edge: handler needs `preventDefault` → not passive |

### JavaScript

| Rule ID | Locator (`rules/…`) | False positive / caveat | Golden set (positive / negative / edge) |
|---|---|---|---|
| PERF-JS-001 | `js-batch-dom-css` | Single style change, or read-back needed between writes | pos: many `el.style.x = …` writes in a loop / neg: class toggle or `cssText` batch / edge: single write |
| PERF-JS-002 | `js-index-maps` | Collection is tiny or a one-off lookup | pos: `arr.find` inside a loop over another array / neg: prebuilt `Map` / edge: single lookup |
| PERF-JS-003 | `js-cache-property-access` | Access count is trivial | pos: repeated `obj.a.b.c` in a hot loop / neg: cached local / edge: loop body runs few times |
| PERF-JS-004 | `js-cache-function-results` | Result depends on varying input or is cheap | pos: recomputing a pure expensive transform per call / neg: module-level `Map` cache / edge: unbounded input → unbounded cache |
| PERF-JS-005 | `js-cache-storage` | Read is occasional, or freshness is required | pos: repeated `localStorage.getItem` in a render loop / neg: cached in memory / edge: value may change across tabs |
| PERF-JS-006 | `js-combine-iterations` | Passes are small or readability-critical | pos: `arr.filter().map()` over a large array in a hot path / neg: single loop / edge: array tiny |
| PERF-JS-007 | `js-hoist-regexp` | RegExp is created once | pos: `new RegExp`/literal inside a loop / neg: hoisted constant / edge: genuinely dynamic pattern |
| PERF-JS-008 | `js-min-max-loop` | Sorting is actually required | pos: `arr.sort()[0]` to get min / neg: loop or `Math.min` / edge: full sorted order needed |
| PERF-JS-009 | `js-set-map-lookups` | Collection is tiny or ordering matters | pos: `arr.includes` inside a loop / neg: `Set`/`Map` / edge: index/order required |
| PERF-JS-010 | `js-request-idle-callback` | Work must block, or is time-critical | pos: heavy non-critical analytics on load / neg: `requestIdleCallback` / edge: work must finish before navigation |

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
[ ] Vercel `rendering-conditional-render` — correctness (rendering `0`), not performance
[ ] Vercel `rendering-hydration-suppress-warning` — correctness
[ ] Vercel `rendering-hydration-no-flicker` — UX/CLS, not a code-level perf rule
[ ] Vercel `js-tosorted-immutable` — immutability, not performance
[ ] Vercel `client-localstorage-schema` — maintainability/correctness
[ ] Vercel `server-auth-actions` — security
[ ] Vercel `server-no-shared-module-state` — correctness/isolation
[ ] Vercel `async-*` and `server-*` families — Next.js/RSC, out of scope (client-side React/JS only)
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

_Registry verified: 2026-10-06._
