# Installing the tools & MCP servers

This guide covers everything the `review-code-performance` skill needs to run its free static
analyzers, and how to set up the MCP servers (SonarQube, ESLint, fetch) used for detection.

> **Windows?** See [`INSTALL-windows.md`](INSTALL-windows.md) for Windows-specific setup (Git Bash
> / WSL2, package managers, and the Docker Desktop / Semgrep caveats).

## Two ways to run the tools

Every analyzer script works two ways, and picks automatically:

1. **Container image** (default, "already set up") — a pre-built image that bundles the tool, so
   nothing needs to be installed locally. Requires a container runtime (below).
2. **Local binary** (opt-in with `PERF_PREFER_LOCAL=1`) — a tool you installed on the host.

> **Enterprise note:** see [`references/licensing-enterprise.md`](references/licensing-enterprise.md)
> for the licensing status of every tool. The short version: all analyzers are free for enterprise
> use, but **Docker Desktop** requires a paid subscription at 250+ employees or $10M+ revenue, so
> prefer **Podman**.

## 1. Container runtime (needed for the zero-install path)

The scripts detect a usable engine at run time: **Docker first, then Podman** (only when its
daemon/`info` is reachable). Install either:

| Option | Install (macOS) | Enterprise OK? |
|---|---|---|
| Podman (recommended for enterprise) | `brew install podman` then `podman machine init && podman machine start` | ✅ Apache-2.0, no seat limit |
| Docker Desktop | `brew install --cask docker` | ⚠️ paid at 250+ employees / $10M+ revenue |
| Docker Engine (Linux, no Desktop) | distro package (`docker-ce`) | ✅ Apache-2.0 (engine only) |

Verify:

```bash
docker info   # or: podman info
```

If neither engine is usable, the container-based scripts report `SKIP` (never a review failure) and
fall back to any local binary.

## 2. Analyzers

You do **not** need to install all of these — each script SKIPs gracefully when a tool is absent.
Install only the ones you want as local binaries; otherwise the container image is used.

### PMD (Java) — BSD-style license

```bash
brew install pmd                                    # local
# or container (automatic): pmd/pmd
```

### SpotBugs (Java bytecode) — LGPL-2.1

SpotBugs analyzes compiled classes, so build the project first (`mvn -DskipTests package` or
`gradle classes`). Then either:

```bash
brew install spotbugs                               # local, sets SPOTBUGS_HOME
# or point at a downloaded jar:
export SPOTBUGS_JAR=/path/to/spotbugs/lib/spotbugs.jar
# or add the Maven/Gradle SpotBugs plugin to the build
```

There is no official container image; SpotBugs is inherently tied to the project's compiled output.

### Semgrep Community Edition (Java + JS/React) — engine LGPL-2.1, rules "Semgrep Rules License v1.0"

```bash
pipx install semgrep                                # local (recommended on macOS)
# or: brew install semgrep
# or container (automatic): semgrep/semgrep
```

The Community rules (`p/java`, `p/javascript`, `p/react`) are free for **internal** enterprise use;
do not redistribute or resell them.

### SonarQube Community Build (Java + JS/React) — LGPL-3.0

The script auto-starts the server when it is not already running:

```bash
bash scripts/run_sonarqube_performance.sh /path/to/project
```

First run only — create a token:

1. The script starts the stack (`docker compose`/`podman-compose` + `scripts/docker-compose.yml`)
   and waits for `http://localhost:9000`.
2. Sign in as `admin` / `admin`.
3. Go to **My Account → Security → Generate Tokens** → type **Global Analysis** → generate.
4. Export it:

```bash
export SONAR_TOKEN=<token>
```

Optional local scanner (the script falls back to the container scanner otherwise):

```bash
brew install sonar-scanner
```

### Biome (JS/TS/React) — MIT OR Apache-2.0

Comes via Node with no install:

```bash
# automatic: npx @biomejs/biome
```

Requires Node.js + `npx` (see below).

### ESLint (JS/TS/React) — MIT

Runs **via the ESLint MCP server** (`mcp__ESLint__lint-files`) as the primary channel, with the CLI
script `run_eslint_performance.sh` as a fallback. Both reuse the project's own ESLint config, so add
the React hooks plugin to the project:

```bash
npm install --save-dev eslint eslint-plugin-react-hooks
```

If the project has no ESLint config, the tool SKIPs and Biome covers JS/TS.

### Node.js / npx (for Biome + ESLint)

```bash
brew install node
```

### jq (for JSON parsing in the JS/TS scripts)

```bash
brew install jq
```

## 3. MCP servers (preferred detection channel)

The skill detects evidence through the configured MCP servers, called directly by the agent:

| Server | Tool(s) | Role |
|---|---|---|
| `sonarqube` | `mcp__sonarqube__*` (`analyze_code_snippet`, `search_sonar_issues_in_projects`, `get_component_measures`, …) | Java + JS/React scan (replaces `run_sonarqube_performance.sh`) |
| `ESLint` | `mcp__ESLint__lint-files` | React / JS / TS lint (replaces `run_eslint_performance.sh`) |
| `fetch` | `mcp__fetch__fetch` | retrieve trusted sources during a Section 8 rule refresh |

When a server is not configured, the agent falls back to the matching script (SonarQube / ESLint)
or the built-in `web_fetch` / `web_search` (fetch).

### Fetch MCP server

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    }
  }
}
```

### ESLint MCP server

```json
{
  "mcpServers": {
    "ESLint": {
      "command": "npx",
      "args": ["@eslint/mcp@latest"]
    }
  }
}
```

### SonarQube MCP server

Point it at your SonarQube Community Build instance (the same `http://localhost:9000` the script
would auto-start) with a `SONAR_TOKEN`:

```json
{
  "mcpServers": {
    "sonarqube": {
      "command": "npx",
      "args": ["-y", "@sonarsource/sonarqube-mcp-server"]
    }
  }
}
```

Scopes: `--scope project` (committed to `.mcp.json`, shared with the team), `--scope user`
(`~/.commandcode/mcp.json`, global), or omit `--scope` for local-per-project. To add a server via
the CLI, e.g. `cmd mcp add fetch -- uvx mcp-server-fetch`.

## 4. Verify the whole stack

```bash
bash scripts/run_all_performance.sh /path/to/project
```

Every tool prints one `STATUS: OK | SKIP | FAIL` line. `SKIP` means the tool is missing — install it
or rely on the container image, then re-run.
