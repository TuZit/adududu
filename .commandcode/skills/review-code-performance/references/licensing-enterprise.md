# Enterprise Licensing & Legal Evaluation

Scope: using the `review-code-performance` skill's tool set **inside an enterprise** (a company,
not an individual developer). This document flags licensing/legal risks that do not apply to
personal development and recommends the enterprise-safe default for each tool.

> **Disclaimer.** This is an engineering summary of current public license terms, not legal advice.
> Confirm with your own legal/compliance team before shipping any decision. License terms can change.

## TL;DR

| Tool | License | Enterprise use? | Watch out |
|---|---|---|---|
| PMD | BSD-style (partly Apache-2.0) | ✅ Free, unrestricted | None material |
| SpotBugs | LGPL-2.1 | ✅ Free | Only if you *redistribute/modify* the library |
| Semgrep | Engine LGPL-2.1 · Rules "Semgrep Rules License v1.0" | ⚠️ Internal use only | Rules cannot be redistributed/resold/offered as a service; Pro rules are paid |
| SonarQube Community Build | LGPL-3.0 | ✅ Free | Limited languages; commercial editions are proprietary/paid |
| Biome | MIT OR Apache-2.0 | ✅ Free | None material |
| ESLint | MIT | ✅ Free | None material |
| **Docker Desktop** | Proprietary subscription | ❌ **Paid at 250+ employees or $10M+ revenue** | Biggest risk — use Podman instead |
| **Podman** | Apache-2.0 | ✅ Free, unrestricted | Preferred enterprise container runtime |

**One-sentence verdict:** every *analyzer* is free for enterprise use; the only real compliance
risks are **Docker Desktop** (paid subscription threshold) and **Semgrep rules** (internal-use-only
license), plus the usual LGPL obligations only if you redistribute or modify those tools.

## Per-tool analysis

### PMD — ✅ no issue
- **License:** BSD-style license (a portion of the Velocity template support is Apache-2.0).
- **Enterprise:** free for commercial and closed-source use. No copyleft, no redistribution
  obligation, no usage restriction.
- **Obligation:** retain copyright/license notices if you distribute PMD itself.

### SpotBugs — ✅ no issue for normal use
- **License:** LGPL-2.1.
- **Enterprise:** running SpotBugs as a standalone analyzer (CLI, Maven/Gradle plugin) is
  unrestricted. LGPL copyleft only triggers when you *link against, modify and redistribute* the
  SpotBugs library — which you do not do by running it as a tool.
- **Obligation:** if you ever embed/distribute a modified SpotBugs, you must license the changes
  under LGPL and provide source. Not applicable to normal scanning.

### Semgrep Community Edition — ⚠️ read carefully
Semgrep is split into two differently-licensed layers:

| Layer | License | Enterprise consequence |
|---|---|---|
| Engine (`semgrep` CLI) | LGPL-2.1 | Free for any use, including commercial. |
| Rules (Semgrep Registry, Community **and** Pro) | Semgrep Rules License v1.0 | **Internal business use only** — no redistribution, no reselling, no offering the rules as a service, no use in a competing product. |
| Pro rules / Pro engine / AppSec platform | Commercial (paid) | Requires a Semgrep subscription; the free tier of the *managed platform* has developer limits. |

- **What the skill uses:** `p/java`, `p/javascript`, `p/react` (Community packs) run through the
  LGPL CLI. This is free and legal for enterprise **internal** scanning.
- **What is NOT allowed:** shipping the rules in your own product, wrapping the scan as a SaaS for
  others, or building a competing linter on top of Semgrep-maintained rules.
- **Recommendation:** keep the Community rulesets and the OSS CLI; do not redistribute rule packs.
  If you need Pro/AppSec rules at scale, buy the subscription.

### SonarQube Community Build — ✅ no issue
- **License:** LGPL-3.0.
- **Enterprise:** explicitly allowed for commercial/proprietary projects; the community build is
  free and open source with no licensing restriction on internal commercial use.
- **Trade-off (not legal):** the Community Build supports fewer languages/rules than the paid
  Developer/Enterprise/Data Center editions. Those commercial editions are proprietary and paid,
  and are only needed if you want their exclusive features/support.

### Biome — ✅ no issue
- **License:** MIT OR Apache-2.0 (dual, your choice).
- **Enterprise:** free for commercial and closed-source use, with an express patent grant under
  Apache-2.0. No copyleft.

### ESLint — ✅ no issue
- **License:** MIT.
- **Enterprise:** free for commercial and closed-source use. No copyleft. Plugins
  (e.g. `eslint-plugin-react-hooks`) are also MIT.

### Docker Desktop — ❌ the main risk
- **License:** Docker Subscription Service Agreement (proprietary). **Docker Desktop is free only
  for:** personal use, education, non-commercial open-source projects, and small businesses with
  **fewer than 250 employees AND less than $10M annual revenue**.
- **Enterprise:** a company at **250+ employees OR $10M+ revenue** must buy a paid **Docker
  Business** subscription (~$24/user/month) to keep using Docker Desktop legally. Non-compliance is
  a licensing violation with audit risk.
- **Recommendation:** for enterprise, use **Podman** (Apache-2.0, no such restriction) as the
  container runtime. This is why the skill's scripts detect a usable engine at run time and prefer
  **Docker → Podman** fallback; set Podman as the default in enterprise environments.

### Podman — ✅ preferred enterprise runtime
- **License:** Apache-2.0.
- **Enterprise:** free and unrestricted for commercial use. `podman` + `podman-compose` are
  drop-in replacements for `docker` + `docker compose` for the images this skill uses.

## MCP servers

The skill only uses an optional **MCP fetch/HTTP server** (Section 8 rule refresh). Most official
MCP servers (e.g. `@modelcontextprotocol/server-fetch`) are MIT/Apache-2.0 — free for enterprise
use. Verify each server's license individually before onboarding it into a managed environment; the
risk is low and is about supply-chain governance, not license fees.

## Enterprise recommendations (summary)

1. **Default the container runtime to Podman** (or use Docker Engine/CI runners without Docker
   Desktop) to avoid the Docker Desktop paid-seat threshold.
2. **Keep analyzers local or in self-managed containers** — PMD, SpotBugs, SonarQube Community
   Build, Biome, ESLint are all free for enterprise.
3. **Semgrep:** use the OSS CLI + Community rules for internal scanning only; do not redistribute
   rules or resell scans.
4. **SonarQube:** Community Build is fine and free; budget for a commercial edition only if you need
   its language coverage or support.
5. **Record versions** of all tools in `meta.json`/reports so license obligations (notices,
   LGPL source availability) stay auditable.

## Sources

- [Semgrep — Licensing](https://docs.semgrep.dev/licensing)
- [Semgrep Rules License v1.0](https://semgrep.dev/legal/rules-license/)
- [Semgrep — Important updates to Semgrep OSS](https://semgrep.dev/blog/2024/important-updates-to-semgrep-oss/)
- [SonarSource — License (LGPL v3)](https://www.sonarsource.com/license/)
- [SonarQube Community for commercial use](https://community.sonarsource.com/t/sonarqube-community-for-commercial-use/148903)
- [Docker Desktop license agreement](https://docs.docker.com/subscription-billing/desktop-license/)
- [PMD — License](https://pmd.github.io/pmd/license.html)
- [SpotBugs — LICENSE (LGPL-2.1)](https://github.com/spotbugs/spotbugs/blob/master/LICENSE)
- [Biome — LICENSE-MIT](https://github.com/biomejs/biome/blob/main/LICENSE-MIT) / [LICENSE-APACHE](https://github.com/biomejs/biome/blob/main/LICENSE-APACHE)
