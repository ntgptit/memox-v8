# Business rules — SRS scheduler

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng SRS, dưới ID vĩnh viễn `BR-SRS-nnn` |
| **Scope** | Luật hai scheduler (`eight_box`, `sm2`), khoá/đổi scheduler, reset và generation (V8.0). Ngoài phạm vi: luồng phiên học (`study.md`) |
| **Source of truth for** | BR-SRS-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Chọn và khoá scheduler

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-SRS-001 | active | Root deck MUST chọn một scheduler khi tạo: `eight_box` hoặc `sm2`. MUST NOT có mặc định ngầm bỏ qua bước chọn. | rule + invariant Q11 | UC-DECK-001 |
| BR-SRS-002 | active | Scheduler, version và config MAY đổi trực tiếp chừng nào root deck chưa có lượt học nào ở generation hiện tại (`first_answered_at IS NULL`). Đây là thao tác **riêng**, MUST NOT đi qua Reset: `generation` MUST giữ nguyên (UC-DECK-002). Điều kiện mở khoá MUST được đọc lại bên trong transaction ghi, không tin trạng thái màn hình. Chọn đúng scheduler deck đang chạy MUST là no-op: MUST NOT seed lại cây (BR-SRS-004) và MUST NOT đóng session đang mở (BR-STUDY-016). | store | UC-DECK-002, BR-SRS-004, BR-STUDY-016 |
| BR-SRS-003 | active | Sau khi thẻ đầu tiên **hoàn tất chuỗi học mới** (BR-STUDY-053), scheduler, version và config MUST bị khoá. Việc khoá — đặt `first_answered_at` trên root — MUST xảy ra trong **cùng transaction** với chính lần hoàn tất đó, và MUST NOT ghi đè dấu của thẻ hoàn tất đầu tiên. Đổi MUST đi qua Reset learning progress (BR-SRS-024). | store + invariant Q30 | UC-DECK-002, UC-STUDY-001, BR-STUDY-053 |
| BR-SRS-004 | active | Đổi scheduler khi chưa khoá MUST khởi tạo lại study state của toàn bộ card trong cây theo scheduler mới, trong một transaction. | store | UC-DECK-002 |
| BR-SRS-005 | active | MUST NOT tự động chuyển đổi study state giữa hai scheduler. | rule | UC-DECK-005 |
| BR-SRS-006 | active | Di chuyển subtree sang root có scheduler hoặc generation không tương thích MUST bị chặn, hoặc MUST yêu cầu người dùng reset tường minh. | rule | UC-DECK-005 |
| BR-SRS-007 | active | Thứ tự thủ công của deck MUST chỉ được xác định trong một nhóm sibling có cùng `parent_id`, bằng `(sibling_position, id)` để luôn deterministic. Reorder MUST đọc lại source và target active trong cùng transaction, và MUST từ chối nếu chúng không còn là sibling. Reorder MUST chỉ đổi `sibling_position` (và `updated_at` của các sibling đổi vị trí); MUST NOT đổi `parent_id`, `root_id`, scheduler/generation, card, study state hay descendant. Transaction thất bại MUST rollback toàn bộ thứ tự. | store + db | UC-DECK-006 |

BR-SRS-004 dễ bị bỏ sót vì "chưa có lượt học nên không có gì để mất". Nhưng study state
đã tồn tại từ lúc tạo card (BR-CARD-004), và state của 8-box không dùng được cho SM-2.
Bỏ bước này để lại card `sm2` với `current_box` và không có `ease_factor`.

BR-SRS-006 là hệ quả trực tiếp của BR-SRS-005 khi cây có nhiều root. Một subtree kéo từ root
dùng `eight_box` sang root dùng `sm2` sẽ mang theo card có `current_box` mà
scheduler mới không hiểu.

---

## Scheduler `eight_box`

Hai action: `forgotten` và `remembered`.

### BR-SRS-008 · Chuyển box

**Status:** active · **Enforced by:** rule · **Related:** —

| Action | Box đích |
|---|---|
| `forgotten` | `1` |
| `remembered` | `min(8, current_box + 1)` |

### BR-SRS-009 · Bảng interval

**Status:** active · **Enforced by:** rule · **Related:** —

| Box | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Ngày | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128 |

`next_due_at` = đầu ngày học thứ `interval(box đích)` — 00:00 giờ địa phương,
lưu bằng UTC, không phải `now + N*24h` (lý do: BR-STUDY-074).

Box 8 là box cuối. Card ở box 8 trả lời `remembered` vẫn ở box 8 và xếp lịch lại
sau 128 ngày — không có trạng thái "tốt nghiệp" khiến card biến mất, vì trí nhớ
vẫn phai. "Đã thuộc" (`current_box == 8`) là giá trị suy ra để hiển thị, không
phải cột trong DB.

---

## Scheduler `sm2`

Bốn action: `again`, `hard`, `good`, `easy`.

### BR-SRS-010 · Ánh xạ action sang thang chất lượng

**Status:** active · **Enforced by:** rule · **Related:** —

| Action | q |
|---|---|
| `again` | 0 |
| `hard` | 3 |
| `good` | 4 |
| `easy` | 5 |

### BR-SRS-011 · Cập nhật interval và repetitions

**Status:** active · **Enforced by:** rule · **Related:** —

```
ease_factor = <giá trị mới theo BR-SRS-012>      ← chạy TRƯỚC

nếu q < 3:
    repetitions = 0
    interval_days = 1
ngược lại:
    nếu repetitions == 0: interval_days = 1
    nếu repetitions == 1: interval_days = 6
    ngược lại:            interval_days = round(interval_days * ease_factor)
    repetitions = repetitions + 1
```

`next_due_at` = đầu ngày học thứ `interval_days`, theo đúng BR-STUDY-074 như `eight_box`.

**Thứ tự là một phần của luật, không phải chi tiết triển khai.** `ease_factor`
trong phép nhân MUST là giá trị **sau** khi BR-SRS-012 đã chạy cho chính lượt này —
không phải giá trị thẻ mang vào lượt. Hai cách đọc chỉ khác nhau ở những action
làm đổi hệ số: với `good` (q=4) hệ số không đổi nên không phân biệt được, còn
`hard` (q=3) hạ 2.5 xuống 2.36, và một thẻ đang ở interval 10 ngày nhận 24 ngày
theo luật này thay vì 25.

Bản đầu của tài liệu không nói thứ tự, nên từng có một lần triển khai theo cách
đọc sát chữ — nhân với hệ số cũ — và chủ dự án chốt lại hướng ngược lại. Ghi thẳng vào đây
thay vì để trong commit message, vì đây đúng là loại mơ hồ mà người đọc kế tiếp
sẽ tự suy lại và suy khác.

### BR-SRS-012 · Cập nhật ease factor

**Status:** active · **Enforced by:** rule · **Related:** —

```
ease_factor = max(1.3, ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))
```

Cập nhật ở mọi lượt `scheduled`, kể cả khi `q < 3`. Sàn 1.3 là bắt buộc: không có
nó, một card liên tục bị quên sẽ có ease factor tiến về 0 và interval kẹt ở 1
ngày vĩnh viễn.

---

## Card "đã thuộc" — giá trị suy ra, hai scheduler

### BR-SRS-013 · Định nghĩa "đã thuộc"

**Status:** active · **Enforced by:** db (query tổng hợp) · **Related:** BR-SRS-009, BR-SRS-011, UC-DECK-003

Một card MUST được tính là "đã thuộc" khi:

| Scheduler | Điều kiện |
|---|---|
| `eight_box` | `current_box = 8` |
| `sm2` | `interval_days >= 128` |

Giá trị này MUST được suy ra khi đọc và MUST NOT là cột trong DB.

**Nửa `eight_box` không phải luật mới.** BR-SRS-009 đã phát biểu nó bằng văn xuôi từ
trước: *"Đã thuộc" (`current_box == 8`) là giá trị suy ra để hiển thị, không phải
cột trong DB*. BR-SRS-013 chỉ nâng nó thành một rule có ID và mở rộng sang scheduler
thứ hai, vì màn deck cần một con số dùng được cho cả hai.

**Vì sao `sm2` là 128 ngày và không phải 21.** 21 là ngưỡng "mature card" quen
thuộc của SM-2/Anki, và nó tới sớm hơn nhiều — khoảng bốn lần trả lời tốt
(1 → 6 → 15 → 37). Chọn 128 vì nó **khớp đúng interval của box 8** (BR-SRS-009), nên
"đã thuộc" nghĩa là cùng một khoảng cách thời gian ở cả hai scheduler thay vì
cùng một quy ước ở một cái và một quy ước khác ở cái kia.

Cái giá đã nhận, nói thẳng vì nó nhìn thấy được: một deck `sm2` cần khoảng bảy
lần trả lời tốt mới có card đầu tiên "đã thuộc", nên thanh tiến độ của nó nhúc
nhích chậm hơn hẳn một deck `eight_box` cùng số lần ôn. Đó là hệ quả của việc
khớp theo thời gian chứ không phải theo công sức, và là lựa chọn có ý thức.

**Suy ra khi đọc, không lưu.** Một cột `is_learned` sẽ phải cập nhật ở mọi
đường ghi chạm vào `current_box` hoặc `interval_days`, và sẽ sai ngay lần đầu
một đường nào đó quên — trong khi ngưỡng thì đứng yên và cả hai cột đã có index
cần thiết. Reset learning progress vì thế cũng tự động đúng: nó đặt lại state,
và con số suy ra đi theo.

---

## Loại lượt ôn — `scheduled` và `relearning`

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-SRS-014 | active | `review_log` MUST có cột `kind` với đúng ba giá trị: `learning`, `scheduled` và `relearning`. | db | BR-STUDY-052 |
| BR-SRS-015 | active | `kind` MUST được lưu tường minh tại thời điểm ghi. MUST NOT suy luận bằng cách so sánh trạng thái trước và sau. | store | — |
| BR-SRS-016 | active | **Chỉ áp cho phiên `reviewing`.** Lượt đầu tiên của một thẻ trong phiên đó MUST là `scheduled`. Chỉ lượt `scheduled` MAY cập nhật `current_box`, `ease_factor`, `interval_days` và `due_at`. Phiên `learning` MUST NOT sinh lượt `scheduled` nào (BR-STUDY-053). | store | UC-STUDY-001, BR-STUDY-053 |
| BR-SRS-017 | active | Card quay lại sau `forgotten`/`again` MUST là `relearning`. Lượt `relearning` MUST ghi study answers và cập nhật `last_answered_at`, nhưng MUST NOT thay đổi `current_box`, `ease_factor`, `interval_days` hay `due_at`. | store + invariant Q14 | UC-STUDY-001 |

BR-SRS-015 đáng nói vì cách suy luận nghe rất hợp lý: "trước và sau giống nhau thì là
relearning". Nó sai ở đúng một trường hợp và trường hợp đó không hiếm — một lượt
`scheduled` trên card ở box 8 trả lời `remembered` cũng có `previous_box == 8` và
`next_box == 8`. Suy luận sẽ gắn nhãn nó là `relearning` và mọi thống kê về sau
đều lệch.

BR-SRS-016 là rule quan trọng nhất của mục này. Không có nó, một card trả lời
`forgotten` rồi `remembered` ngay trong phiên sẽ nhảy lên box 2 và biến mất khỏi
lịch ngày mai — người dùng vừa quên nó xong đã được cho nghỉ hai ngày.

### BR-SRS-018 · Bộ đếm

**Status:** active · **Enforced by:** store · **Related:** UC-STUDY-001

| Cột | Quy tắc |
|---|---|
| `answer_count` | +1 mỗi lượt `scheduled` (không tính `learning` hay `relearning`) |
| `lapse_count` | +1 khi lượt `scheduled` có action `forgotten` hoặc `again` |
| `last_answered_at` | = thời điểm đánh giá, cập nhật ở **cả ba** loại lượt |

**`answer_count` bằng 0 sau khi học xong lần đầu là đúng, không phải lỗi.** Chuỗi
học mới không sinh lượt `scheduled` nào (BR-STUDY-053), nên bộ đếm này chỉ bắt đầu chạy
từ phiên ôn tập đầu tiên. Nó đếm "đã được xếp lịch bao nhiêu lần", không đếm "đã
gặp bao nhiêu lần" — số thứ hai đọc từ `review_log`. Vì thế BR-CARD-007 xác định thẻ
mới bằng `learned_at`, không bằng bộ đếm này.

### BR-SRS-019 · Ghi study answers

**Status:** active · **Enforced by:** store · **Related:** UC-STUDY-001

Mỗi lượt đánh giá — cả `scheduled` lẫn `relearning` — MUST ghi một dòng vào
`review_log` gồm `card_id`, `session_id`, `scheduler_type`,
`generation`, `kind`, `action`, `answered_at`, `next_due_at`, và
cặp trạng thái trước/sau của scheduler tương ứng.

Ghi cả lượt `relearning` là có chủ đích: nó là dữ liệu thật về việc người dùng
phải lặp mấy lần mới nhớ — thứ cần để đánh giá chất lượng thuật toán sau này.

---

## Reset learning progress và generation

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-SRS-020 | active | Mỗi root deck MUST có `generation`, bắt đầu từ 1, +1 sau mỗi lần reset. | db | UC-SRS-001 |
| BR-SRS-021 | active | Reset MUST giữ nguyên: deck, toàn bộ cây deck con, flashcard, media, tag và mọi nội dung. | store | UC-SRS-001 |
| BR-SRS-022 | active | Reset MUST xoá/đặt lại: active scheduler state của mọi card trong cây — **bao gồm `learned_at`** — và mọi session đang dở. Thẻ trở lại tập học mới và đi lại chuỗi (BR-STUDY-051, BR-STUDY-053). | store | UC-SRS-001, BR-STUDY-050 |
| BR-SRS-023 | active | Study answers cũ MUST được giữ lại, mang generation cũ, và MUST NOT được dùng cho chu kỳ mới. | store | UC-SRS-001 |
| BR-SRS-024 | active | Sau reset, `first_answered_at` MUST về NULL → scheduler mở khoá. Đây là cơ chế duy nhất để đổi scheduler sau lượt học đầu. | store | UC-SRS-001 |
| BR-SRS-025 | active | Card study state, study session và study answers MUST đều mang `generation`. | db | — |
| BR-SRS-026 | active | MUST NOT chấp nhận kết quả từ session thuộc generation cũ; mọi thao tác ghi MUST so generation và từ chối nếu lệch. | store | UC-STUDY-001 |
| BR-SRS-027 | active | Reset và đổi scheduler MUST chạy trong một Drift transaction duy nhất. | store | UC-SRS-001 |
| BR-SRS-028 | active | Bất biến 1: một cây deck MUST có đúng một active scheduler tại một thời điểm. | invariant Q9 | — |
| BR-SRS-029 | active | Bất biến 2: toàn bộ card state trong một cây MUST thuộc cùng một generation. | invariant Q9 | — |
| BR-SRS-030 | active | Reset MUST cần xác nhận, nêu rõ những gì mất và những gì giữ. | UI | UC-SRS-001 |

BR-SRS-027 quan trọng vì nửa vời ở đây nghĩa là một cây deck có card thuộc hai
generation, hoặc scheduler mới với card state theo luật cũ. Cả hai là dữ liệu
hỏng không tự phục hồi, tệ hơn nhiều so với reset thất bại sạch sẽ.

---

## Entity state machines

### Card study state

Trạng thái suy ra từ `learned_at` và `due_at`, không lưu cột riêng. Đây là trục
**lịch**; bốn nhãn hiển thị `new` · `beginning` · `reviewing` · `mastered` là một
phép đọc khác của cùng dữ liệu (BR-CARD-006…BR-CARD-008).

| Trạng thái | Điều kiện |
|---|---|
| `new` | `learned_at IS NULL` — khi đó `due_at` cũng NULL (BR-CARD-007, BR-STUDY-058) |
| `due` | `learned_at IS NOT NULL AND due_at <= now` |
| `scheduled` | `learned_at IS NOT NULL AND due_at > now` |

| From | To | Trigger |
|---|---|---|
| new | scheduled | thẻ hoàn tất chuỗi học mới — một sự kiện, không phải một lượt `scheduled` (BR-STUDY-053) |
| scheduled | due | thời gian trôi qua `due_at` |
| due | scheduled | lượt `scheduled`, chỉ có trong phiên `reviewing` (BR-SRS-016) |
| bất kỳ | new | reset learning progress (BR-SRS-022, BR-STUDY-050) |

Reset là chuyển đổi duy nhất quay ngược về `new` — và nó đi kèm generation mới,
nên card sau reset không bị nhầm với card chưa từng ôn ở chu kỳ trước.

**Chuyển đổi không hợp lệ:** sửa nội dung card không đưa nó về `new` (BR-CARD-005);
lượt `learning` (BR-STUDY-052) và lượt `relearning` (BR-SRS-017) không gây chuyển trạng thái
nào.

### Deck — trạng thái khoá scheduler

| Trạng thái | Điều kiện |
|---|---|
| `unlocked` | `first_answered_at IS NULL` |
| `locked` | `first_answered_at IS NOT NULL` |

| From | To | Trigger |
|---|---|---|
| unlocked | locked | thẻ đầu tiên của generation hiện tại hoàn tất chuỗi học mới (BR-SRS-003, BR-STUDY-053) |
| locked | unlocked | reset learning progress (BR-SRS-024) |

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Deck.schedulerType | bắt buộc chọn khi tạo root deck | "Hãy chọn chế độ ôn tập cho deck" | rule |
| Deck.move | đích cùng root scheduler và generation | "Deck đích dùng chế độ ôn tập khác. Hãy đặt lại tiến độ học trước khi di chuyển" | rule |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Di chuyển subtree sang root khác scheduler | Chặn, đề nghị reset (BR-SRS-006) |
| Tạo root deck không chọn scheduler | Chặn, lỗi inline (BR-SRS-001) |
| Đổi scheduler khi chưa có lượt học | Cho phép, khởi tạo lại study state toàn cây (BR-SRS-004) |
| Đổi scheduler khi đã có lượt học | Chặn; đề nghị Reset learning progress (BR-SRS-003) |
| App bị kill giữa lúc reset | Transaction rollback; giữ nguyên generation và state cũ (BR-SRS-027) |
| Card ở box 8 trả lời `remembered` trong lượt `scheduled` | Vẫn box 8, xếp lịch lại 128 ngày (BR-SRS-009). `kind` vẫn là `scheduled` dù box không đổi (BR-SRS-015) |
| SM-2, card bị quên liên tục | `ease_factor` chạm sàn 1.3 và dừng ở đó (BR-SRS-012) |
| Đổi giờ hệ thống / lệch múi giờ | Lưu và so sánh `due_at` bằng UTC |
| Reset learning progress rồi học tiếp | Cả hai generation đều được đếm — reset không làm việc đã học biến mất (BR-SRS-023, BR-PROGRESS-017) |
