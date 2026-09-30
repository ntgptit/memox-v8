---
id: BR-STUDY-068
title: Hero summary nêu tổng Due và hai nửa rời nhau
status: active
summary: Hero summary nêu tổng Due của level đang xem và hai nửa rời nhau Overdue, Due today; New và Scheduled không ở hero.
superseded_by:
---
## Rule

Hero level summary MUST nêu tổng Due của level đang xem cùng hai nửa rời nhau Overdue và Due today; New và Scheduled MUST NOT xuất hiện ở hero (quyết định chủ dự án 2026-09-30: hero chỉ nói việc cần làm, New vẫn hiện ở từng dòng deck). Bốn tập của level vẫn được định nghĩa như sau cho store và các dòng deck: `Overdue` = `learned_at IS NOT NULL AND due_at < startOfToday` (ranh giới đầu ngày địa phương theo mốc BR-STUDY-074, tính ở một chỗ dùng chung, MUST NOT tự tính trong SQL); `Due today` = `learned_at IS NOT NULL AND due_at >= startOfToday AND due_at <= now`; `New` = `learned_at IS NULL`; `Scheduled` = `learned_at IS NOT NULL AND due_at > now` — tính bằng `total − New − Due` từ cùng snapshot, MUST NOT mang headline hay màu cảnh báo (thẻ nghỉ là lịch đang chạy đúng, không phải việc cần làm). Bốn tập cộng đúng bằng tổng thẻ của level. MUST giữ `dueCardCount = overdueCardCount + dueTodayCardCount` — tổng Reviewing của BR-STUDY-051 không đổi nghĩa và phiên học vẫn chọn thẻ theo total, không theo hai nửa. Count là aggregate subtree của chính level đang xem, suy ra lúc đọc trong cùng một statement với các count khác — MUST NOT lưu thành cột, MUST NOT query thứ hai. Chú thích tuổi `+Nd` đã bỏ khỏi giao diện nhìn thấy (quyết định chủ dự án 2026-08-20): nó nói backlog *cũ* bao lâu chứ không nói *lớn* cỡ nào. Tuổi của thẻ Due cũ nhất (BR-STUDY-067) MUST vẫn tới được screen reader qua `deckOverdueSemanticLabel`/`deckHeroOverdueSemanticLabel` và MUST NOT là count. Qua đầu ngày địa phương, thẻ Due today của ngày cũ MUST tự chuyển sang Overdue ở lần đọc kế tiếp mà không có database write. Deck tile MUST hiển thị ba chip rời nhau `overdue · due · new` — mỗi chip một nền riêng — thay cho total Due + New và icon trạng thái (quyết định chủ dự án 2026-08-20). Chip chỉ hiện khi count > 0; deck có thẻ nhưng không còn việc MUST nêu cả hai số 0 trên nền trung tính.

**Enforced by:** UI + store
**Liên quan:** BR-STUDY-074, BR-STUDY-051, BR-STUDY-046, BR-STUDY-067

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
