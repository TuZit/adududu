# Cài đặt các tool scan trên Windows

Hướng dẫn cài đặt bộ công cụ của skill `review-code-performance` trên môi trường **Windows**.
Bản này bổ sung cho `INSTALL.md` (viết chủ yếu cho macOS/Linux).

> **Cảnh báo quan trọng đầu tiên:** toàn bộ script của skill là **bash** (`.sh`), nên trên
> Windows bạn cần chạy chúng qua **Git Bash** (đi kèm Git for Windows) hoặc **WSL2** — không chạy
> trực tiếp bằng PowerShell/CMD.

## 0. Yêu cầu trước (prerequisite)

Cài một trong hai (hoặc cả hai):

| Thành phần | Vì sao cần | Cách cài |
|---|---|---|
| Git for Windows (Git Bash) | Chạy các script `.sh` | `winget install --id Git.Git` |
| WSL2 (Ubuntu) — khuyến nghị | Chạy native Linux: Semgrep, SonarQube scanner, volume mount container ổn định hơn | `wsl --install` |

Nếu dùng WSL2, bạn có thể cài toàn bộ tool bên trong WSL giống như hướng dẫn macOS/Linux
(`INSTALL.md`) và bỏ qua phần Windows-native bên dưới. Phần còn lại của file này tập trung vào
cài **native trên Windows**.

## 1. Container runtime

| Lựa chọn | Cài đặt | Enterprise OK? |
|---|---|---|
| Podman Desktop (khuyến nghị cho enterprise) | `winget install --id RedHat.Podman-Desktop` | ✅ Apache-2.0, không giới hạn seat |
| Docker Desktop | `winget install --id Docker.DockerDesktop` | ⚠️ trả phí khi ≥250 nhân viên / doanh thu ≥$10M |

**Lưu ý đặc thù Windows:**
- Docker Desktop cần backend **WSL2** (hoặc Hyper-V) để chạy.
- Script dùng `-v "$PROJECT_DIR:/src"` để mount thư mục project vào container. Từ Git Bash,
  `$(pwd)` trả về đường dẫn kiểu `/c/Users/...`; Docker Desktop đôi khi không nhận dạng này. Đây
  là điểm hay vướng — nếu gặp lỗi mount, chuyển sang **Podman Desktop** (tự chuyển đổi path) hoặc
  chạy script **trong WSL2**.
- Cờ `--network host` (script SonarQube dùng cho scanner container) **không được hỗ trợ** trên
  Docker Desktop cho Windows/macOS → xem mục SonarQube bên dưới.

## 2. JDK + Maven (cần để build bytecode cho SpotBugs)

SpotBugs phân tích bytecode, nên cần compile project trước.

```powershell
# JDK 17 (Temurin/Adoptium)
winget install --id EclipseAdoptium.Temurin.17.JDK
# Maven (hoặc tải zip từ maven.apache.org/download.cgi rồi thêm vào PATH)
winget install --id Apache.Maven
# hoặc: choco install maven
```

## 3. Node.js + jq (cho Biome/ESLint + parse JSON)

```powershell
winget install --id OpenJS.NodeJS.LTS
winget install --id jqlang.jq
```

## 4. Từng analyzer

Bạn **không cần** cài hết — mỗi script tự `SKIP` khi thiếu tool, và container image là đường
"đã setup sẵn" mặc định. Cài local chỉ khi muốn chạy native (hoặc đặt `PERF_PREFER_LOCAL=1`).

### PMD (Java) — BSD-style

```powershell
choco install pmd                      # hoặc
# tải zip chính thức: https://github.com/pmd/pmd/releases → giải nén → thêm bin/ vào PATH
```

### SpotBugs (Java bytecode) — LGPL-2.1

Không có installer; dùng file zip chính thức:

```powershell
# 1) tải zip từ https://github.com/spotbugs/spotbugs/releases
# 2) giải nén, ví dụ vào C:\tools\spotbugs
# 3) đặt biến môi trường:
setx SPOTBUGS_HOME "C:\tools\spotbugs"
```

Hoặc dùng Maven/Gradle plugin (đã có sẵn trong `sample-java-perf/pom.xml`) — đây là cách "đã
setup sẵn", không cần cài SpotBugs riêng. Script của skill tự nhận diện `target/spotbugsXml.xml`.

### Semgrep CE (Java + JS/React) — engine LGPL-2.1, rules "Semgrep Rules License v1.0"

**Native Windows không được hỗ trợ tốt.** Khuyến nghị theo thứ tự:

1. Container image `semgrep/semgrep` (mặc định của script, cần Docker/Podman).
2. Cài trong **WSL2**: `pipx install semgrep`.
3. `pip install semgrep` (hỗ trợ hạn chế trên Windows native).

### SonarQube Community Build (Java + JS/React) — LGPL-3.0

Server được auto-start qua compose (Docker/Podman). Riêng phần scanner:

- **Scanner container** (`sonarsource/sonar-scanner-cli` + `--network host`) **không chạy trên
  Docker Desktop Windows** (thiếu host networking). Thay vào đó cài `sonar-scanner` native:

```powershell
# tải zip: https://docs.sonarsource.com/sonarqube-community-build/analyzing-source-code/scanners/sonarscanner/
# giải nén → thêm sonar-scanner/bin vào PATH
```

- Tạo token lần đầu giống mọi nền tảng: mở `http://localhost:9000`, đăng nhập `admin`/`admin`,
  vào **My Account → Security → Generate Tokens** (type **Global Analysis**), rồi:

```powershell
setx SONAR_TOKEN "<token>"
```

### Biome (JS/TS/React) — MIT OR Apache-2.0

Không cần cài riêng, chạy qua `npx` (cần Node.js ở mục 3).

### ESLint (JS/TS/React) — MIT

Chạy qua **CLI** (không phải MCP). Thêm vào project (cần Node.js):

```powershell
npm install --save-dev eslint eslint-plugin-react-hooks
```

Nếu project chưa có config ESLint, script sẽ SKIP và Biome đảm nhận JS/TS.

## 5. MCP server `fetch` (lấy rules khi refresh)

Giống mọi nền tảng — chạy từ Git Bash/PowerShell:

```powershell
cmd mcp add --scope project fetch -- npx -y @modelcontextprotocol/server-fetch
```

Server lộ tool `mcp__fetch__fetch`, dùng cho Section 8 khi chạy `--refresh-rules`.

## 6. Kiểm tra toàn bộ

Chạy từ **Git Bash** (không phải PowerShell):

```bash
# build + SpotBugs plugin trước (từ Git Bash)
cd sample-java-perf && mvn -DskipTests verify && cd ..

# chạy skill
bash .commandcode/skills/review-code-performance/scripts/run_all_performance.sh \
    sample-java-perf --tools pmd,spotbugs,semgrep,sonarqube,biome,eslint
```

Mỗi tool in một dòng `STATUS: OK | SKIP | FAIL`. `SKIP` nghĩa là tool chưa cài — cài thêm hoặc dựa
vào container image rồi chạy lại.

## Khuyến nghị cho Windows

1. **Ưu tiên WSL2** nếu có thể: cài tool + chạy script trong WSL tránh hầu hết vướng mắc về path
   và host networking.
2. **Container runtime:** dùng Podman (Desktop) cho enterprise để tránh ngưỡng trả phí Docker
   Desktop; xem `references/licensing-enterprise.md`.
3. **SonarQube:** cài `sonar-scanner` native (đừng dùng scanner container trên Docker Desktop).
4. **Semgrep:** chạy qua container hoặc WSL, không dùng native Windows.
