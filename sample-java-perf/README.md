# sample-java-perf

Project Java mẫu chứa các anti-pattern performance điển hình, dùng để **test skill**
`review-code-performance`. Mỗi đoạn code được chú thích rule ID tương ứng (`PERF-JAVA-*`,
`PERF-SPRING-*`).

## Chạy skill trên sample này

```bash
# 1) build + chạy SpotBugs plugin (tạo target/spotbugsXml.xml cho skill dùng)
cd sample-java-perf && mvn -DskipTests verify && cd ..

# 2) chạy skill (dùng --deep hoặc --tools để bật đủ tool)
#    từ thư mục gốc repo:
bash .commandcode/skills/review-code-performance/scripts/run_all_performance.sh \
    sample-java-perf --tools pmd,spotbugs,semgrep,sonarqube,biome,eslint
```

Báo cáo nằm ở `sample-java-perf/.perf-reports/<run_id>/` (và symlink `latest`).

## Rule nào được kích hoạt

| File | Rule | Vấn đề |
|---|---|---|
| `service/OrderService.java` | PERF-SPRING-001/004/012 | N+1 query (truy cập association lười trong vòng lặp) |
| `service/OrderService.java` | PERF-SPRING-005/015 | `save()` trong vòng lặp, không batch |
| `service/OrderService.java` | PERF-SPRING-007/013 | `findAll()` / derived query không giới hạn |
| `service/OrderService.java` | PERF-SPRING-008/009 | `Page` (chạy COUNT) + offset lớn |
| `service/OrderService.java` | PERF-JAVA-001/002/003/008/009/012/014 | allocation, array copy, String concat, wrapper, `SimpleDateFormat`/`Pattern` trong loop, `System.gc()` |
| `domain/Order.java` | PERF-SPRING-002/014 | `EAGER` association, collection lớn fetch eager |
| `domain/Customer.java` | PERF-SPRING-004 | collection lười, load từng phần |
| `repository/OrderRepository.java` | PERF-SPRING-007/013 | derived query trả `List` không giới hạn |
| `util/JavaPerfSmells.java` | PERF-JAVA-003/004/005/006/007/010/013 | String concat, `trim().length()==0`, `toString()`, append, `Vector`, `Thread.sleep` |

## Lưu ý

- Sample cố tình viết "sai" để làm test fixture. Không dùng làm code tham chiếu.
- SpotBugs: `pom.xml` đã gắn `spotbugs-maven-plugin` vào phase `verify` → chạy `mvn -DskipTests verify`
  để tạo `target/spotbugsXml.xml` (script của skill tự nhận diện output này). Nếu không build, script
  fallback sang SpotBugs CLI (cần cài `spotbugs`/`SPOTBUGS_HOME`).
- Semgrep/PMD chỉ cần source, không cần build.
