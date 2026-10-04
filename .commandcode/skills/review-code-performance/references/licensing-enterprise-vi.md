# Đánh giá Bản quyền & Pháp lý khi dùng cho Enterprise

Phạm vi: dùng bộ công cụ của skill `review-code-performance` **trong môi trường enterprise** (công ty,
không phải cá nhân). Tài liệu này nêu rõ các rủi ro bản quyền/pháp lý **không áp dụng** cho việc
phát triển cá nhân, và đề xuất lựa chọn an toàn cho enterprise cho từng công cụ.

> **Lưu ý.** Đây là bản tổng hợp kỹ thuật về điều khoản license công khai hiện tại, **không phải tư
> vấn pháp lý**. Hãy xác nhận với đội legal/compliance trước khi chốt bất kỳ quyết định nào. Điều
> khoản license có thể thay đổi.

## Tóm tắt nhanh

| Công cụ | License | Dùng cho enterprise? | Cần lưu ý |
|---|---|---|---|
| PMD | BSD-style (một phần Apache-2.0) | ✅ Miễn phí, không hạn chế | Không có gì đáng kể |
| SpotBugs | LGPL-2.1 | ✅ Miễn phí | Chỉ khi bạn *phân phối/sửa đổi* thư viện |
| Semgrep | Engine LGPL-2.1 · Rules "Semgrep Rules License v1.0" | ⚠️ Chỉ dùng nội bộ | Rules không được phân phối/bán lại/làm service; Pro rules trả phí |
| SonarQube Community Build | LGPL-3.0 | ✅ Miễn phí | Ít ngôn ngữ; bản thương mại là proprietary/trả phí |
| Biome | MIT OR Apache-2.0 | ✅ Miễn phí | Không có gì đáng kể |
| ESLint | MIT | ✅ Miễn phí | Không có gì đáng kể |
| **Docker Desktop** | Proprietary subscription | ❌ **Trả phí khi ≥250 nhân viên hoặc doanh thu ≥$10M** | Rủi ro lớn nhất — nên dùng Podman |
| **Podman** | Apache-2.0 | ✅ Miễn phí, không hạn chế | Runtime container ưu tiên cho enterprise |

**Kết luận một câu:** mọi *analyzer* đều miễn phí cho enterprise; rủi ro tuân thủ thực sự chỉ nằm ở
**Docker Desktop** (ngưỡng trả phí) và **Semgrep rules** (license chỉ dùng nội bộ), cộng thêm nghĩa vụ
LGPL chỉ phát sinh khi bạn phân phối lại hoặc sửa đổi chính công cụ đó.

## Phân tích từng công cụ

### PMD — ✅ không vấn đề
- **License:** BSD-style (một phần hỗ trợ Velocity template là Apache-2.0).
- **Enterprise:** miễn phí cho mục đích thương mại và closed-source. Không copyleft, không nghĩa vụ
  phân phối lại, không hạn chế sử dụng.
- **Nghĩa vụ:** giữ lại thông báo copyright/license nếu bạn tự phân phối PMD.

### SpotBugs — ✅ không vấn đề trong cách dùng thông thường
- **License:** LGPL-2.1.
- **Enterprise:** chạy SpotBugs như một công cụ standalone (CLI, plugin Maven/Gradle) là không hạn
  chế. Copyleft LGPL chỉ kích hoạt khi bạn *link vào, sửa đổi và phân phối lại* thư viện SpotBugs —
  điều không xảy ra khi chỉ chạy nó như một công cụ.
- **Nghĩa vụ:** nếu nhúng/phân phối SpotBugs đã sửa đổi, bạn phải license phần thay đổi theo LGPL và
  cung cấp source. Không áp dụng cho việc scan thông thường.

### Semgrep Community Edition — ⚠️ đọc kỹ
Semgrep được chia thành hai lớp với license khác nhau:

| Lớp | License | Hệ quả cho enterprise |
|---|---|---|
| Engine (`semgrep` CLI) | LGPL-2.1 | Miễn phí cho mọi mục đích, kể cả thương mại. |
| Rules (Semgrep Registry, cả Community **và** Pro) | Semgrep Rules License v1.0 | **Chỉ dùng cho mục đích kinh doanh nội bộ** — không phân phối lại, không bán lại, không cung cấp rules như một service, không dùng trong sản phẩm cạnh tranh. |
| Pro rules / Pro engine / nền tảng AppSec | Thương mại (trả phí) | Cần subscription Semgrep; bản free của *nền tảng quản lý* có giới hạn số developer. |

- **Skill này dùng gì:** `p/java`, `p/javascript`, `p/react` (các pack Community) chạy qua CLI LGPL.
  Điều này là miễn phí và hợp pháp cho việc scan **nội bộ** của enterprise.
- **KHÔNG được phép:** ship rules vào sản phẩm của bạn, gói việc scan thành SaaS cho người khác, hoặc
  xây một linter cạnh tranh trên nền rules do Semgrep duy trì.
- **Khuyến nghị:** giữ các Community ruleset và OSS CLI; không phân phối lại rule pack. Nếu cần
  Pro/AppSec rules ở quy mô lớn, mua subscription.

### SonarQube Community Build — ✅ không vấn đề
- **License:** LGPL-3.0.
- **Enterprise:** được phép dùng rõ ràng cho dự án thương mại/proprietary; bản community build là
  miễn phí và open source, không có hạn chế license cho việc dùng nội bộ thương mại.
- **Đánh đổi (không phải pháp lý):** Community Build hỗ trợ ít ngôn ngữ/rules hơn các bản trả phí
  Developer/Enterprise/Data Center. Các bản thương mại đó là proprietary và trả phí, chỉ cần nếu bạn
  muốn tính năng/support độc quyền của chúng.

### Biome — ✅ không vấn đề
- **License:** MIT OR Apache-2.0 (dual, tùy bạn chọn).
- **Enterprise:** miễn phí cho mục đích thương mại và closed-source, có cấp quyền patent rõ ràng theo
  Apache-2.0. Không copyleft.

### ESLint — ✅ không vấn đề
- **License:** MIT.
- **Enterprise:** miễn phí cho mục đích thương mại và closed-source. Không copyleft. Các plugin
  (ví dụ `eslint-plugin-react-hooks`) cũng là MIT.

### Docker Desktop — ❌ rủi ro chính
- **License:** Docker Subscription Service Agreement (proprietary). **Docker Desktop chỉ miễn phí cho:**
  cá nhân, giáo dục, dự án open-source phi thương mại, và doanh nghiệp nhỏ với **dưới 250 nhân viên
  VÀ doanh thu dưới $10M/năm**.
- **Enterprise:** công ty **≥250 nhân viên HOẶC doanh thu ≥$10M** phải mua subscription **Docker
  Business** (khoảng $24/user/tháng) để dùng Docker Desktop hợp pháp. Không tuân thủ là vi phạm
  license và có rủi ro bị kiểm toán.
- **Khuyến nghị:** với enterprise, dùng **Podman** (Apache-2.0, không có hạn chế đó) làm container
  runtime. Đây là lý do script của skill tự phát hiện runtime khả dụng và ưu tiên **Docker → Podman**
  fallback; hãy đặt Podman làm mặc định trong môi trường enterprise.

### Podman — ✅ runtime ưu tiên cho enterprise
- **License:** Apache-2.0.
- **Enterprise:** miễn phí và không hạn chế cho mục đích thương mại. `podman` + `podman-compose` là
  thay thế tương đương cho `docker` + `docker compose` đối với các image mà skill này dùng.

## MCP servers

Skill chỉ dùng một **MCP fetch/HTTP server** tùy chọn (phần refresh rules ở Section 8). Hầu hết MCP
server chính thức (ví dụ `@modelcontextprotocol/server-fetch`) là MIT/Apache-2.0 — miễn phí cho
enterprise. Hãy kiểm tra license của từng server trước khi đưa vào môi trường được quản lý; rủi ro ở
đây thấp và chủ yếu là về quản trị supply-chain, không phải chi phí license.

## Khuyến nghị cho enterprise (tổng kết)

1. **Đặt container runtime mặc định là Podman** (hoặc dùng Docker Engine/CI runner không kèm Docker
   Desktop) để tránh ngưỡng trả phí của Docker Desktop.
2. **Giữ analyzer chạy local hoặc trong container tự quản** — PMD, SpotBugs, SonarQube Community
   Build, Biome, ESLint đều miễn phí cho enterprise.
3. **Semgrep:** chỉ dùng OSS CLI + Community rules cho việc scan nội bộ; không phân phối rules hoặc
   bán lại việc scan.
4. **SonarQube:** Community Build là đủ và miễn phí; chỉ cần bản thương mại nếu cần độ phủ ngôn ngữ
   hoặc support của nó.
5. **Ghi lại version** của tất cả công cụ trong `meta.json`/report để nghĩa vụ license (notices,
   nguồn LGPL) luôn có thể kiểm toán được.

## Nguồn tham khảo

- [Semgrep — Licensing](https://docs.semgrep.dev/licensing)
- [Semgrep Rules License v1.0](https://semgrep.dev/legal/rules-license/)
- [Semgrep — Important updates to Semgrep OSS](https://semgrep.dev/blog/2024/important-updates-to-semgrep-oss/)
- [SonarSource — License (LGPL v3)](https://www.sonarsource.com/license/)
- [SonarQube Community for commercial use](https://community.sonarsource.com/t/sonarqube-community-for-commercial-use/148903)
- [Docker Desktop license agreement](https://docs.docker.com/subscription-billing/desktop-license/)
- [PMD — License](https://pmd.github.io/pmd/license.html)
- [SpotBugs — LICENSE (LGPL-2.1)](https://github.com/spotbugs/spotbugs/blob/master/LICENSE)
- [Biome — LICENSE-MIT](https://github.com/biomejs/biome/blob/main/LICENSE-MIT) / [LICENSE-APACHE](https://github.com/biomejs/biome/blob/main/LICENSE-APACHE)
