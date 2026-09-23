---
id: UC-TAG-001
title: Quản lý tag và lọc thẻ theo tag
status: ready
rules: [BR-CARD-012, BR-DECK-015, BR-TAG-001, BR-TAG-002, BR-TAG-003, BR-TAG-004, BR-TAG-005, BR-TAG-006, BR-TAG-007, BR-TAG-008, BR-TAG-009, BR-TAG-010, BR-TAG-011, BR-TRANSFER-009]
code: []
---
## Mục tiêu / Actor / Precondition

**Phạm vi:** sub-project sau — Tags (spec §2).

**Actor:** Người dùng
**Trigger:** Chạm hành động `Tags` trên app bar của Library, hoặc `Manage tags`
trong overflow menu của card list; lọc theo tag thì chạm pill `Tags` trên thanh
filter của card list
**Preconditions:** Không có. Catalog mở được cả khi chưa có tag nào — trạng thái
rỗng là câu trả lời hợp lệ, không phải lỗi

## Main flow

**Main flow:**
1. Người dùng mở tag catalog. Hệ thống đọc mọi tag của owner hiện tại kèm số thẻ
   đang mang mỗi tag, sắp theo tên đã fold rồi `id` (BR-TAG-003).
2. Hệ thống hiển thị mỗi tag thành một hàng: tên canonical, số thẻ, và một menu
   hành động có `Rename` và `Delete`.
3. Người dùng gõ vào ô tìm kiếm để thu hẹp catalog. Hệ thống lọc theo cùng phép
   fold mà BR-TAG-001 dùng, nên `Dong tu` và `động từ` tìm thấy nhau đúng như lúc tạo
   tag (BR-TAG-003).
4. Người dùng chọn `Rename` trên một hàng. Hệ thống mở form với tên hiện tại đã
   điền sẵn.
5. Người dùng sửa tên rồi xác nhận. Hệ thống validate theo BR-TAG-001 và, vì tên đã
   fold chưa thuộc về tag nào khác, ghi `name` và `name_folded` mới lên **chính
   hàng tag đó** — `id` và mọi liên kết thẻ giữ nguyên (BR-TAG-006).
6. Người dùng quay lại card list và chạm pill `Tags`. Hệ thống mở overlay lọc
   với mọi tag và số thẻ của chúng, cùng tập tag đang chọn.
7. Người dùng chọn nhiều tag rồi bấm `Apply`. Hệ thống áp vị từ **OR giữa các
   tag đã chọn**, **AND** với filter trạng thái và search term đang bật, reset
   cửa sổ phân trang và xoá selection (BR-TAG-004, BR-TAG-005).
8. Card list hiển thị đúng tập thẻ khớp, mỗi thẻ đúng một lần, với count khớp
   danh sách (BR-TAG-004).

## Alternative / Error flow

**Alternative flows:**
- **A1 — Đổi tên gây trùng (gộp):** tên mới fold trùng một tag khác đang tồn
  tại. Form nói rõ **trước khi xác nhận** rằng hành động sẽ gộp vào tag đích,
  và nêu tên đích. Xác nhận thì hệ thống nối mọi thẻ của tag nguồn sang tag
  đích, dedupe liên kết trùng, gỡ liên kết còn lại của nguồn và xoá hàng tag
  nguồn — tất cả trong một transaction (BR-TAG-007). Không thẻ nào vượt trần 10 tag,
  vì mỗi thẻ đổi nguồn lấy đích chứ không cộng thêm (BR-TAG-002).
- **A2 — Đổi tên chỉ đổi cách viết hoa:** `noun` → `Noun`. Tên đã fold không
  đổi, nên đây là đổi cách viết chứ không phải gộp: `id` và liên kết giữ nguyên
  (BR-TAG-006).
- **A3 — Xoá tag:** người dùng chọn `Delete`. Hệ thống hỏi xác nhận, nêu rõ số
  thẻ sẽ bị gỡ tag và nói thẳng rằng thẻ **không** bị xoá. Xác nhận thì hệ thống
  gỡ mọi hàng `card_tags` rồi xoá hàng `tags` trong một transaction (BR-TAG-008).
- **A4 — Bỏ chọn hết tag trong overlay lọc:** `Clear` đưa tập chọn về rỗng. Tập
  rỗng là phần tử đơn vị — không có vị từ tag nào được áp và danh sách trở lại
  đúng như trước khi lọc (BR-TAG-004).
- **A5 — Huỷ overlay lọc:** đóng overlay mà không `Apply` giữ nguyên tập tag
  đang áp; bản nháp bị bỏ.
- **A6 — Tìm kiếm trong catalog không khớp gì:** catalog hiển thị trạng thái
  "không có tag nào khớp" kèm chuỗi đã gõ, khác với trạng thái "chưa có tag
  nào" (BR-TAG-003).
- **A7 — Lọc theo tag không còn thẻ nào khớp:** card list hiển thị trạng thái
  không có kết quả cho bộ lọc, kèm lối `Clear` để bỏ vị từ tag.

**Error flows:**
- **E1 — Đọc catalog thất bại:** hệ thống hiện trạng thái lỗi có Retry; chưa
  có mutation nào xảy ra.
- **E2 — Đổi tên với tên không hợp lệ:** rỗng sau trim, quá 50 ký tự, hoặc chứa
  ký tự điều khiển → lỗi có kiểu gắn dưới ô nhập, form giữ nguyên chữ đã gõ
  (BR-TAG-001, BR-TAG-006).
- **E3 — Tag đã biến mất:** tag bị xoá ở nơi khác giữa lúc mở form và lúc ghi →
  lý do có kiểu `không còn tồn tại`, catalog tự cập nhật, không có mutation.
- **E4 — Ghi thất bại giữa lúc gộp:** transaction rollback toàn bộ; cả hai tag
  và mọi liên kết trở lại đúng như trước, và UI nêu lỗi thay vì báo thành công
  (BR-TAG-007).
- **E5 — Xoá thất bại:** transaction rollback; tag và mọi liên kết còn nguyên,
  không thẻ nào bị đụng tới (BR-TAG-008, BR-TAG-009).

## UI

**UI states:** catalog loading · catalog populated · catalog empty (chưa có tag
nào) · catalog search empty · rename normal · rename collision (có tiết lộ gộp)
· submitting · rename failure · delete confirm · delete failure · filter overlay
không chọn gì · filter overlay chọn một · filter overlay chọn nhiều · card list
đang lọc theo tag · card list lọc theo tag không có kết quả.

## Local

**Postconditions:** Chỉ hàng `tags` và hàng `card_tags` thay đổi. Nội dung thẻ,
`updated_at` của thẻ, cờ, `content_type` của deck, study state, review history và
session đều nguyên vẹn (BR-TAG-009). Số thẻ trong catalog và kết quả lọc phản ánh
cùng một tập liên kết (BR-TAG-003, BR-TAG-004).

## API

Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../../shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).

## Acceptance criteria

- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
