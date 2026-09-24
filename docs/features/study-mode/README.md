---
feature: study-mode
code: [lib/features/study_mode/domain]
depends_on: [srs]
---
## Phạm vi

Tập StudyMode, chuỗi stage và chiều hỏi của `self_assess` (V8.0; đủ sáu mode (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md))). Feature không có UC riêng: mode chạy bên trong các UC của feature `study`.

App có **hai trục độc lập**, và việc tách chúng là quyết định sản phẩm chứ không
phải chi tiết kỹ thuật:

| Trục | Là gì | Ai chọn |
|---|---|---|
| **Thuật toán SRS** | `eight_box` · `sm2` — quyết định **khi nào** thẻ quay lại | chọn một lần lúc tạo root deck, khoá khi thẻ đầu tiên học xong chuỗi học mới (BR-SRS-003) |
| **StudyMode** | `browse` · `self_assess` · `match` · `guess` · `recall` · `fill` — quyết định **cách** thẻ được hỏi | không ai chọn: một phiên chạy chuỗi stage cố định của thuật toán (BR-MODE-003, BR-MODE-004) |

**Hai loại phiên, tách hẳn** (BR-STUDY-051):

| | Học mới | Ôn tập |
|---|---|---|
| Thẻ | chưa học xong lần đầu | đã học xong **và** đến hạn |
| Cách hỏi | chuỗi stage cố định | một mode người dùng chọn |
| Đổi lịch | không, cho tới khi xong chuỗi | có, mỗi thẻ một lượt |

**Chỉ lần học đầu tiên mới đi qua cả chuỗi.** Từ lần thứ hai, thẻ vào ôn tập và
người học chọn cách ôn. Đó là quyết định về **áp lực**: bắt đi lại năm cách hỏi cho
một thẻ đã quen là bắt làm bài tập, không phải ôn tập.

**Chuỗi của phiên học mới** (BR-MODE-003, BR-MODE-004):

| Thuật toán | Chuỗi stage |
|---|---|
| `eight_box` | `browse` → `match` → `guess` → `recall` → `fill` |
| `sm2` | `browse` → `self_assess` |

Bốn stage chấm điểm sinh tín hiệu **nhị phân** — đúng hoặc sai — khớp tự nhiên
với hai action của `eight_box`, nhưng chỉ nuôi được hai trong bốn mức của `sm2`.
Nên `sm2` dùng `self_assess`: người học lật thẻ và tự chấm, đúng luồng M3 mô tả.

**`browse` và `self_assess` tách nhau vì chúng là hai việc khác nhau.** `browse`
hiện cả hai mặt cùng lúc để làm quen, không chấm và không đổi lịch (BR-MODE-005);
`self_assess` che mặt sau cho tới khi người học lật, rồi nhận đánh giá của chính
họ. Một cái tên ôm cả hai là thứ sẽ phải giải thích lại ở mọi test và mọi màn hình.

**Phạm vi:** `browse` và `self_assess` thuộc MVP (M3). Bốn stage chấm điểm
`match` · `guess` · `recall` · `fill` có ngưỡng dữ liệu riêng của chúng
(BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) và câu trả lời cho việc một chuỗi học mới ghi vào lịch
thế nào (BR-STUDY-023, BR-STUDY-053). Màn chọn mode ôn tập chỉ xuất hiện khi thuật toán có
từ hai mode ôn tập: `eight_box` có bốn, `sm2` chỉ có `self_assess` nên vào
thẳng (BR-STUDY-055).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Không có màn hình riêng — mode chạy trong phiên học | UC-STUDY-001, UC-STUDY-003 (feature `study`) |

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Đảo chiều ở các mode khác `self_assess` | Should-have S3 mới đặc tả một nửa: UC-STUDY-003 và BR-MODE-013…BR-MODE-019 chỉ cho phiên `self_assess` của deck `sm2` |
