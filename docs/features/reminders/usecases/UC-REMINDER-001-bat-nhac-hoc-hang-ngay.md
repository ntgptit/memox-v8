---
id: UC-REMINDER-001
title: Bật nhắc học hằng ngày
status: ready
rules: [BR-DECK-003, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-REMINDER-001, BR-REMINDER-002, BR-REMINDER-003, BR-REMINDER-004, BR-REMINDER-005, BR-REMINDER-006, BR-REMINDER-007, BR-REMINDER-008, BR-REMINDER-009, BR-REMINDER-010, BR-REMINDER-011, BR-REMINDER-012, BR-STUDY-051, BR-STUDY-067, BR-STUDY-074]
code: [lib/features/reminders/domain/usecases/watch_reminder_use_case.dart, lib/features/reminders/domain/usecases/enable_reminder_use_case.dart, lib/features/reminders/domain/usecases/disable_reminder_use_case.dart, lib/features/reminders/domain/usecases/change_reminder_time_use_case.dart, lib/features/reminders/domain/usecases/reconcile_reminder_use_case.dart, lib/features/reminders/domain/usecases/deliver_reminder_use_case.dart]
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2). Phần logic xong ở BE-B5a
([spec](../../../superpowers/specs/2026-09-26-reminders-backend-design.md)); adapter Android (lịch nền, notification, quyền) là BE-B5b; màn
24 thuộc FE-B5.

**Actor:** Người dùng
**Trigger:** Mở `Settings → Daily reminder`
**Preconditions:** Không có. Nhắc học mặc định tắt và không phụ thuộc dữ liệu
nào (BR-REMINDER-001); màn hình mở được cả khi thư viện rỗng

## Main flow

**Main flow:**
1. Người dùng mở màn nhắc học từ Settings. Hệ thống hiển thị toggle **tắt**, giờ
   gợi ý 20:00 hiển thị ở trạng thái không hoạt động, và hai dòng nói rõ: nhắc
   chỉ hiện khi còn thẻ đến hạn, và notification có thể nêu tên deck cùng số thẻ
   trên màn khoá (BR-REMINDER-001, BR-REMINDER-002, BR-REMINDER-005).
2. Người dùng bật toggle. Hệ thống chuyển sang trạng thái `enabling` và **chỉ
   lúc này** mới xin quyền notification của hệ điều hành (BR-REMINDER-011).
3. Người dùng cấp quyền. Hệ thống lưu `enabled = true` cùng giờ đang chọn, đặt
   một lượt nhắc không chính xác cho lần 20:00 địa phương kế tiếp (BR-REMINDER-009), và
   hiển thị trạng thái bật kèm giờ.
4. Đến giờ, hệ thống đọc lại workload đến hạn. Còn `overdue + due-today > 0` thì
   hiện đúng một notification tóm tắt: tên root deck cấp bách nhất theo thứ tự
   BR-REMINDER-006, tổng số thẻ và số deck còn lại (BR-REMINDER-004, BR-REMINDER-005). Sau đó nó đặt lịch
   cho ngày kế tiếp.
5. Người dùng chạm notification. Hệ thống mở Study Home, không mở phiên nào
   (BR-REMINDER-008).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Đổi giờ nhắc:** chạm hàng giờ → dialog chọn giờ; xác nhận thì lưu giờ
  mới và đặt lại lịch trong cùng một thao tác (BR-REMINDER-009). Huỷ dialog thì không đổi
  gì.
- **A2 — Tắt nhắc:** tắt toggle → lịch bị huỷ và mọi notification đang chờ bị
  gỡ; không xin quyền, không hỏi xác nhận (BR-REMINDER-009).
- **A3 — Đến giờ nhưng không còn thẻ đến hạn:** bỏ lượt nhắc, không hiện gì, vẫn
  đặt lịch cho ngày kế tiếp (BR-REMINDER-003).
- **A4 — Chỉ còn thẻ chưa học:** như A3 — thẻ mới không làm phát notification
  (BR-REMINDER-003).
- **A5 — Đổi múi giờ hoặc mở lại app:** hệ thống hoà giải lịch lúc khởi động;
  chạy nhiều lần vẫn đúng một lượt chờ (BR-REMINDER-010).
- **A6 — Vuốt bỏ notification:** không có mutation nào; lượt nhắc hôm sau không
  đổi (BR-REMINDER-008).

**Error flows:**
- **E1 — Từ chối quyền (Android 13+):** settings giữ nguyên **tắt**, không đặt
  lịch, màn hiện lý do có kiểu cùng hướng dẫn bật lại ở cài đặt hệ thống và một
  hành động thử lại. Hệ thống không tự xin lại quyền (BR-REMINDER-011).
- **E2 — Nền tảng không hỗ trợ:** toggle bị vô hiệu và màn nói rõ nhắc học chưa
  có trên nền tảng này; không có trạng thái bật giả (BR-REMINDER-012).
- **E3 — Đặt lịch thất bại:** lỗi của nền tảng map thành lý do có kiểu; settings
  **không** ở trạng thái bật, màn cho thử lại, và thông báo MUST NOT lộ chi tiết
  kỹ thuật.
- **E4 — Lưu settings thất bại:** không đặt lịch, trạng thái UI quay về giá trị
  đang lưu trong database, kèm lý do có kiểu và hành động thử lại.
- **E5 — Đọc workload thất bại lúc fire:** bỏ lượt nhắc thay vì hiện notification
  đoán mò, vẫn đặt lịch cho ngày kế tiếp (BR-REMINDER-003).
- **E6 — Huỷ lịch thất bại khi tắt:** settings **đã** ở trạng thái tắt — ghi đã
  thành công, chỉ lượt đang chờ là không huỷ được. Copy MUST NOT dùng lại câu của
  E3 ("chưa bật được gì"), vì ở đây điều ngược lại vừa xảy ra; màn nói rõ có thể
  còn một lượt nhắc cũ và cho thử lại. Lượt cũ đó vô hại: khi fire, delivery đọc
  lại settings và bỏ qua (BR-REMINDER-003, BR-REMINDER-009).
- **E7 — Đọc settings thất bại khi mở màn:** không vẽ hàng nào — không toggle,
  không hàng giờ, không dải lỗi trong luồng — mà thay cả thân màn bằng trạng thái
  lỗi toàn màn kèm hành động thử lại. Copy MUST nói về **một lần đọc**, không
  dùng lại câu của E4: người dùng chưa đổi gì cả, nên "chưa lưu được thay đổi"
  mô tả một việc chưa xảy ra.

## UI

**UI states:** loading (đọc settings) · off · enabling (đang xin quyền/đặt lịch,
toggle khoá) · on (giờ hiển thị, hàng giờ chạm được) · time picker mở ·
permission denied (khôi phục được) · platform unavailable · schedule error
(thử lại được) · settings error (thử lại được) · cancel error (E6 — đã tắt, chỉ
lượt chờ còn sót) · read error (E7 — lỗi toàn màn, không vẽ hàng nào). Không có
state `empty`: màn này luôn có nội dung, kể cả khi thư viện rỗng.

## Local

**Postconditions:** `app_settings` mang đúng trạng thái bật/tắt và giờ nhắc mà
người dùng nhìn thấy; đúng một lượt nhắc đang chờ khi bật và không lượt nào khi
tắt (BR-REMINDER-010); không thao tác nào ở đây đụng tới study state hay history.

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] **Given** nhắc học đang tắt, **when** người dùng bật lúc 20:00 và cấp quyền, **then** quyền được xin đúng lúc này, đúng một lượt nhắc được đặt cho lần 20:00 địa phương kế tiếp, rồi settings mới lưu bật cùng giờ (BR-REMINDER-009, BR-REMINDER-011; main 2–3).
- [ ] **Given** người dùng từ chối quyền, **when** bật, **then** settings vẫn tắt, không có lượt nào chờ, và hệ thống không tự xin lại (E1).
- [ ] **Given** nền tảng không hỗ trợ nhắc học, **when** mở màn hoặc bật, **then** capability báo không hỗ trợ và không có gì được xin, lưu hay đặt lịch (E2).
- [ ] **Given** nền tảng từ chối đặt lịch, **when** bật hoặc đổi giờ, **then** settings giữ nguyên giá trị cũ và không có gì được ghi (E3).
- [ ] **Given** lưu settings thất bại, **when** bật, **then** lượt vừa đặt bị gỡ và lỗi đến tay người gọi dưới dạng `Failure` (E4).
- [ ] **Given** nhắc học đang bật và có thẻ đến hạn, **when** đến giờ, **then** workload được đọc lại, đúng một digest hiện tên root deck cấp bách nhất theo BR-REMINDER-006, số thẻ đến hạn của deck đó và số deck khác còn thẻ đến hạn, lần gửi được ghi, và lượt của ngày mai được đặt (main 4).
- [ ] **Given** không còn thẻ đến hạn, hoặc chỉ còn thẻ chưa học, **when** đến giờ, **then** không hiện gì và lượt kế tiếp vẫn được đặt (A3, A4).
- [ ] **Given** đọc workload thất bại lúc fire, **when** đến giờ, **then** không hiện gì và lượt kế tiếp vẫn được đặt (E5).
- [ ] **Given** một ngày địa phương đã có digest, **when** lượt nhắc fire lần nữa trong ngày đó, **then** không hiện thêm (BR-REMINDER-004).
- [ ] **Given** nhắc học đang bật, **when** người dùng đổi giờ, **then** giờ mới được đặt lịch rồi mới lưu, trong cùng một thao tác (A1).
- [ ] **Given** người dùng tắt nhắc học, **when** huỷ lịch thất bại, **then** settings đã tắt và lý do là `couldNotCancel`; thử lại chỉ huỷ, không ghi gì (A2, E6).
- [ ] **Given** app mở lại nhiều lần trong ngày khi đang bật, **when** hoà giải chạy, **then** vẫn đúng một lượt chờ; khi đang tắt, lượt còn sót bị huỷ (A5, BR-REMINDER-010).
- [ ] **Given** đọc settings thất bại khi mở màn, **then** stream báo `Failure`, không có giá trị bịa (E7).
- [ ] Main 5 và A6 (chạm và vuốt bỏ notification) được kiểm ở BE-B5b và FE-B5, trên thiết bị.
