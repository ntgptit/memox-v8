---
id: UC-PROGRESS-001
title: Xem tiến độ học
status: ready
rules: [BR-CORE-005, BR-MODE-005, BR-PROGRESS-007, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGRESS-012, BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016, BR-PROGRESS-017, BR-PROGRESS-018, BR-STUDY-074]
code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/presentation/screens/progress_screen.dart, lib/features/progress/presentation/providers/progress_provider.dart]
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
  dung card (BR-CORE-005).
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

Không áp dụng — UC chạy trên Drift và không gọi mạng; đồng bộ với server chạy ngoài UC ([ADR-013](../../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md), [ADR-015](../../../shared/decisions/ADR-015-supabase-lam-backend.md)).

## Acceptance criteria

- [ ] **Given** người dùng mở tab Progress, **when** hệ thống đọc xong, **then** Current streak, Today (kèm phân rã Learning/Reviewing) và Last 7 days hiện ra từ đúng một snapshot của đồng hồ và offset (BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016).
- [ ] **Given** màn Progress đang mở, **when** người dùng chỉ đọc rồi rời tab hoặc bấm Retry, **then** không có hàng nào trong `card_schedule`, `review_log`, `app_settings` hay `study_session` bị ghi, và không session nào được mở, tiếp tục hay đóng (BR-PROGRESS-007, BR-PROGRESS-009).
- [ ] **Given** hôm nay chưa học nhưng hôm qua có, **when** mở Progress, **then** Today hiện 0 và streak vẫn giữ nguyên số ngày tính tới hôm qua, với nhãn nói rõ đây là chuỗi đang giữ (BR-PROGRESS-016, A1).
- [ ] **Given** đã có deck nhưng chưa từng học lượt nào, **when** mở Progress, **then** Current streak và Today hiện dưới dạng mặt rỗng (không phải số 0 trần) kèm nút "Start studying" mở sang tab Study (BR-PROGRESS-010, A2).
- [ ] **Given** màn Progress đang mở, **when** một answer mới được ghi ở nơi khác, **then** các con số tự cập nhật mà không hạ màn về skeleton (BR-PROGRESS-018, A3).
- [ ] **Given** màn Progress đang mở lúc gần nửa đêm, **when** local midnight trôi qua, **then** cửa sổ bảy ngày trượt một ngày, Today về 0, streak chuyển sang nhánh "hôm qua active" khi phù hợp, và không có write nào trong database (BR-PROGRESS-013, BR-PROGRESS-018, A4).
- [ ] **Given** đã học rồi reset learning progress ở màn khác, **when** quay lại Progress, **then** mọi con số của Progress giữ nguyên như trước reset (BR-PROGRESS-017, A5).
- [ ] **Given** một card đã được trả lời rồi bị xoá cứng (trực tiếp hoặc theo cascade từ deck), **when** quay lại Progress, **then** hoạt động của card đó biến mất khỏi mọi ngày, kể cả ngày quá khứ (BR-PROGRESS-017, A6).
- [ ] **Given** một phiên chỉ lướt `browse`, một card hoặc deck trong Trash, hoặc một answer có thời điểm sau ranh giới hôm nay, **when** đọc Progress, **then** các trường hợp đó không tạo card-day, không làm ngày thành active và không giữ streak (BR-PROGRESS-012, A7).
- [ ] **Given** lần đọc lịch sử thất bại, **when** màn Progress nhận lỗi, **then** hệ thống hiện mặt lỗi chung kèm nút Retry, và Retry đọc lại (E1).
- [ ] **Given** Retry vẫn lỗi, **when** người dùng ở lại màn lỗi, **then** hệ thống không tự thử lại theo vòng lặp và không ghi gì (BR-PROGRESS-009, E2).
