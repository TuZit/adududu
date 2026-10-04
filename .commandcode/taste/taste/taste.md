# Taste
- Prefers container-based scripts to detect an available runtime at execution time: use Docker when it's installed and its daemon is reachable, and fall back to Podman (including `podman-compose`) when Docker is missing or not running. Confidence: 0.85
- Writes requests in Vietnamese, typically mixed with English technical terms. Confidence: 0.85
- Prefers scripts/tooling that use already-set-up tools (auto-started servers, self-contained container images) rather than requiring manual startup steps before running. Confidence: 0.8
- Cares about enterprise licensing/legal compliance when evaluating or choosing developer tools. Confidence: 0.8
- Prefers written deliverables and documentation to be produced in Vietnamese (keeping English technical terms as-is rather than translating them). Confidence: 0.7
- Prefers validating a skill/tool by running it against a purpose-built sample project that exercises the relevant rules/anti-patterns. Confidence: 0.6

- Prefers MCP servers as the mechanism for adding fetch/retrieval tooling to skills, and wants them configured per the official/current docs (e.g. `mcp-server-fetch` via `uvx`, not the deprecated npm `@modelcontextprotocol/server-fetch`). Confidence: 0.7
- Maintains cross-platform tooling/documentation; expects Windows-specific setup guidance (e.g., Git Bash/WSL2, winget/choco, Docker Desktop caveats) alongside macOS/Linux instructions. Confidence: 0.6
- Uses Podman (no Docker installed) as the container runtime in their environment; container commands and docs should be Podman-compatible (`podman run`, `podman compose`). Confidence: 0.7
- Maintains a self-hosted SonarQube (community edition) instance running locally via Podman at http://localhost:9000. Confidence: 0.6
- When checking a skill/tool's dependencies, prefers the agent to proactively self-install anything missing rather than only report gaps; expects a final summary of what was installed and what remains manual (e.g. secrets/tokens). Confidence: 0.8
cking a skill/tool's dependencies, prefers the agent to proactively self-install anything missing rather than only report gaps; expects a final summary of what was installed and what remains manual (e.g. secrets/tokens). Confidence: 0.7
