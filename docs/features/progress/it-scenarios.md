# progress — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: Kịch bản IT — Khởi động, điều hướng và tiếp tục

## IT-NAV-011 — Bốn destination top-level, Tiến độ chỉ-đọc và một placeholder không tạo phiên, không ghi DB

- **Ưu tiên:** P1
- **Tiền điều kiện:** App đã cài, dữ liệu bất kỳ; không có phiên Study đang dở.
- **Liên kết:** UC-DECK-003 cho cold start; UC-PROGRESS-001 và BR-PROGRESS-009 cho branch Tiến độ.
- **Phạm vi deep link:** các bước 4–5 là điều hướng **in-process** — router phân
  giải `/progress`/`/settings` làm initial location (URL development, cùng cơ
  chế IT-NAV-005). OS handoff của deep link `memox://app/<route>` (FE-D3,
  [spec](../../superpowers/specs/2026-09-28-device-e2e-design.md) D4) được kiểm
  ở IT-PLAT-004 cho màn deck; `/progress` và `/settings` đi cùng đường đó. Nếu
  cần chứng minh riêng cho hai route này, MUST tách thành một kịch bản
  `DEVICE-E2E` như cặp IT-NAV-005 · IT-PLAT-004.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở app và quan sát bottom navigation | Đúng bốn destination theo thứ tự Thư viện · Học · Tiến độ · Cài đặt; tab Thư viện đang được chọn |
| 2 | Chạm tab Tiến độ | Màn Tiến độ mở: chuỗi ngày hiện tại, tổng hôm nay tách Learning/Reviewing và bảy ngày gần nhất (UC-PROGRESS-001), rồi bên dưới là bộ chọn 7/30 ngày, bảng tổng và một hàng cho mỗi root deck (UC-PROGRESS-002) — hoặc mặt lifetime-empty khi chưa từng học. Không tạo phiên Study; không có ghi database nào (BR-PROGRESS-009, BR-PROGRESS-007) |
