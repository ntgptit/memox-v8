---
id: UC-PROGRESS-001
title: Xem tiến độ học
status: ready
rules: [BR-MODE-005, BR-PRIVACY-002, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGRESS-012, BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016, BR-PROGRESS-017, BR-PROGRESS-018, BR-STUDY-074]
code: []
---
## Mục tiêu / Actor / Precondition

**Actor:** Người dùng
**Trigger:** Chạm tab **Tiến độ / Progress** ở bottom navigation, hoặc mở deep
link `/progress`
**Preconditions:** Không có. Màn hình mở được kể cả khi chưa từng học một lượt
nào — trạng thái "chưa có gì" là một mặt hợp lệ, không phải lỗi.

## Main flow

**Main flow:**
1. Người dùng mở tab Progress. Hệ thống chụp **một** snapshot của
   `clockProvider` và `utcOffsetProvider` rồi dựng ranh giới ngày theo BR-PROGRESS-013.
2. Hệ thống mở **một** stream đọc lịch sử học, gộp ngay trong SQLite thành các
   hàng *card-day* rồi thành các hàng *active-day* (BR-PROGRESS-011); không tải hàng
   `review_log` thô lên tầng trên và không đọc từng ngày một.
3. Trong lúc chờ emission đầu tiên, màn hình hiện trạng thái loading có nhãn
   cho screen reader.
4. Emission tới. Hệ thống hiển thị ba khối, cùng một snapshot:
   **Current streak** (BR-PROGRESS-016), **Today** với tổng số card cùng phân rã
   Learning/Reviewing (BR-PROGRESS-014), và **Last 7 days** đúng bảy cột theo thứ tự
   cũ → mới, ngày trống là 0 (BR-PROGRESS-015).
   Ba khối này **không chiếm cả màn**: `/progress` là một màn duy nhất, và
   chúng là phần đầu của cấp thư viện trong UC-PROGRESS-002 — cùng một vùng cuộn, dưới
   chúng là bộ chọn khoảng, bảng tổng và danh sách deck. Bố cục chi tiết thuộc
   phạm vi thiết kế UI, ngoài phạm vi tài liệu này; ở đây chỉ ghi rằng hai use
   case dùng chung một màn, vì đọc riêng UC-PROGRESS-001 sẽ hiểu nhầm thành một tab ba khối.
5. Người dùng đọc xong và rời tab. Hệ thống không ghi gì trong toàn bộ luồng
   (BR-PROGRESS-009).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Hôm nay chưa học nhưng hôm qua có:** Today hiện 0, và streak **vẫn
  giữ** chuỗi kết thúc ở hôm qua (BR-PROGRESS-016). Copy nói rõ đây là chuỗi đang giữ,
  không phải chuỗi đã mất.
- **A2 — Chưa từng học lượt nào:** cả ba khối rỗng. Hệ thống hiện một mặt
  empty của cả màn với CTA thật dẫn sang branch Study, không phải một màn ba
  khối toàn số 0.
- **A3 — Có một lượt mới ghi trong lúc màn đang mở:** người dùng học ở tab khác
  rồi quay lại, hoặc một answer được ghi khi màn còn sống — các con số tự cập
  nhật, không cần Retry và không nháy toàn trang (BR-PROGRESS-018).
- **A4 — Local midnight trôi qua trong lúc màn đang mở:** cửa sổ bảy ngày trượt
  một ngày, Today về 0, và streak chuyển sang nhánh "hôm qua active" của
  BR-PROGRESS-016 — tất cả không cần thao tác nào (BR-PROGRESS-018).
- **A5 — Reset learning progress ở màn khác rồi quay lại:** mọi con số giữ
  nguyên, vì reset không đụng lịch sử (BR-PROGRESS-017).
- **A6 — Xoá một card hoặc một deck ở màn khác rồi quay lại:** hoạt động của
  các card đã xoá biến mất khỏi mọi ngày, kể cả ngày quá khứ (BR-PROGRESS-017).
- **A7 — Chỉ lướt `browse` rồi thoát:** không có gì đổi — `browse` không ghi
  answer nên không tạo hoạt động (BR-PROGRESS-012).

**Error flows:**
- **E1 — Đọc lịch sử thất bại:** hệ thống map exception thành `Failure`; màn
  hình hiện mặt lỗi kèm `Retry`. Thông báo MUST NOT lộ SQL, tên bảng hay nội
  dung card (BR-PRIVACY-002).
- **E2 — Retry vẫn lỗi:** màn hình ở lại mặt lỗi; MUST NOT tự thử lại vòng lặp
  và MUST NOT ghi gì (BR-PROGRESS-009).

## UI

**UI states:** loading · loaded-normal (có hoạt động trong cửa sổ) ·
loaded-today-zero-streak-retained (A1) · empty-lifetime + CTA sang Study (A2) ·
error + Retry (E1/E2). Live refresh (A3) và midnight rollover (A4) là **chuyển
tiếp giữa hai loaded**, không phải state thứ sáu; luật cấm hạ màn về loading khi
đã có dữ liệu nằm ở BR-PROGRESS-018.

## Local

**Postconditions:** Database không đổi ở mọi nhánh, kể cả nhánh lỗi và nhánh
Retry (BR-PROGRESS-009). Không session nào được mở, tiếp tục hay đóng.

## API

Không áp dụng — ứng dụng local-only, không network ([quyết định nền tảng](../../../product/product.md#platform-decisions)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
