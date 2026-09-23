# Business rules — Deck

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng DECK, dưới ID vĩnh viễn `BR-DECK-nnn` |
| **Scope** | Luật cây deck, tên và xoá deck (V8.0). Ngoài phạm vi: nội dung card (`card.md`), scheduler (`srs.md`) |
| **Source of truth for** | BR-DECK-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Cây deck

Nền tảng của mô hình dữ liệu, nên đặt đầu tiên dù ID cao hơn.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-DECK-001 | active | Deck MUST được phép lồng nhiều cấp, tối đa **10 cấp** với root là cấp 1; tạo hoặc di chuyển deck vượt cấp 10 MUST bị chặn trước khi ghi. Thiết kế MUST NOT giả định cây chỉ có một cấp. | store + invariant Q15 | UC-DECK-004, UC-DECK-005 |
| BR-DECK-002 | active | Mỗi deck MUST mang `root_id`. Root deck có `root_id = id`; mọi descendant mang đúng `root_id` của root. | db + invariant Q6, Q7 | UC-DECK-004, UC-DECK-005 |
| BR-DECK-003 | active | Xác định root MUST qua `root_id`. MUST NOT dùng `COALESCE(parent_id, id)`. | script | — |
| BR-DECK-004 | active | Root deck MUST chỉ chứa deck con; MUST NOT chứa card trực tiếp. | db + invariant Q1 | UC-DECK-001, UC-DECK-004 |
| BR-DECK-005 | active | Nút Create tại root deck MUST chỉ có một lựa chọn: Create deck. | UI | UC-DECK-004 |
| BR-DECK-006 | active | Sub-deck mới tạo MUST có `content_type = unset`. Người dùng MUST NOT chọn `content_type` khi tạo. | rule | UC-DECK-004 |
| BR-DECK-007 | active | Bấm Create trong sub-deck `unset` MUST hiển thị hai lựa chọn: Create card và Create deck. | UI | UC-DECK-004 |
| BR-DECK-008 | active | Lần tạo phần tử con đầu tiên MUST xác lập `content_type`, trong cùng transaction với việc tạo phần tử đó. | store | UC-DECK-004 |
| BR-DECK-009 | active | `content_type = card`: deck MUST chỉ chứa card; MUST NOT chứa deck con. | db + invariant Q3 | UC-CARD-001, UC-DECK-004 |
| BR-DECK-010 | active | `content_type = deck`: deck MUST chỉ chứa deck con; MUST NOT chứa card trực tiếp. | db + invariant Q4 | UC-DECK-004, UC-DECK-005 |
| BR-DECK-011 | active | Một deck MUST NOT đồng thời chứa card và deck con. | db + invariant Q3, Q4 | UC-DECK-003 |
| BR-DECK-012 | active | Sau khi `content_type` được xác lập, nút Create MUST chỉ hiển thị hành động tương ứng. | UI | UC-DECK-004 |
| BR-DECK-013 | superseded by BR-DECK-015 | Xoá hết nội dung MUST NOT tự động đưa `content_type` về `unset`. | rule | UC-CARD-001 |
| BR-DECK-014 | superseded by BR-DECK-015 | Đưa `content_type` về `unset` MUST là thao tác riêng, có xác nhận, và chỉ thực hiện được khi deck rỗng. | rule + UI | UC-DECK-002 |
| BR-DECK-015 | active | Với mọi sub-deck, `content_type` MUST được hệ thống cập nhật **atomically trong cùng transaction với mutation direct children**: `unset` khi không còn direct child nào, `card` khi chứa direct card, `deck` khi chứa direct child deck. Root deck vẫn bất biến `deck` theo BR-DECK-004. Người dùng MUST NOT có thao tác reset `content_type` thủ công. Transaction thất bại MUST rollback cả mutation lẫn thay đổi `content_type`. | store + invariant Q29 | UC-DECK-002, UC-CARD-001, UC-DECK-004, UC-DECK-005 |
| BR-DECK-016 | active | Cây deck MUST NOT có cycle. | invariant Q8 | UC-DECK-005 |
| BR-DECK-017 | active | MUST NOT di chuyển một deck vào chính nó hoặc vào descendant của nó. | rule | UC-DECK-005 |
| BR-DECK-018 | active | Di chuyển subtree MUST cập nhật `root_id` cho toàn bộ subtree trong một transaction. | store | UC-DECK-005 |
| BR-DECK-019 | active | MUST NOT có descendant trỏ sai root. | invariant Q6 | UC-DECK-005 |

**BR-DECK-013 và BR-DECK-014 bị BR-DECK-015 thay thế.** Lập luận cũ — "quay về `unset`
tự động khiến cấu trúc đổi âm thầm" — giả định `content_type` là một lựa chọn của
người dùng. Nó không phải: BR-DECK-006 cấm chọn lúc tạo và BR-DECK-008 xác lập nó tự động từ
phần tử con đầu tiên. Nó là **metadata hệ thống tự duy trì** để cưỡng chế "một deck
chỉ chứa một loại" (BR-DECK-011), nên hướng ngược lại cũng phải tự động: create đã
đổi type atomically, còn delete/move thì không — bất đối xứng đó để lại deck rỗng
nhưng vẫn `card`/`deck`, một trạng thái người dùng không thoát ra được nếu không
biết tới một nút reset chôn trong action sheet. Reset thủ công vì thế là thao tác
quản trị không mua được giá trị nghiệp vụ nào, và BR-DECK-015 xóa nó.

BR-DECK-003 cấm đúng một biểu thức đã từng xuất hiện trong tài liệu.
`COALESCE(parent_id, id)` cho ra "cha, hoặc chính nó nếu không có cha", nên
với deck ở cấp 3 nó trả về deck cấp 2 chứ không phải root.

---

## Deck — tên và xoá

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-DECK-020 | active | Deck MUST có tên không rỗng sau khi trim, tối đa 200 ký tự. | rule | UC-DECK-001, UC-DECK-002 |
| BR-DECK-021 | active | Tên deck MAY trùng nhau. | rule | UC-DECK-001 |
| BR-DECK-022 | active | Xoá deck MUST xoá toàn bộ descendant, card, study state, study answers và study session của nó (cascade). | db | UC-DECK-002 |
| BR-DECK-023 | active | Xoá deck MUST cần xác nhận, kèm số deck con và số card sẽ mất. | UI | UC-DECK-002 |
| BR-DECK-024 | active | Scheduler thuộc về root deck. Mọi descendant ở mọi cấp MUST kế thừa `scheduler_type`, `scheduler_version` và `generation` từ root, và MUST NOT chọn riêng. | db + invariant Q9, Q10 | UC-STUDY-001 |
| BR-DECK-025 | active | Cột scheduler MUST chỉ có giá trị trên root deck; deck không phải root MUST để NULL và tra qua `root_id`. | invariant Q10 | UC-DECK-002 |

BR-DECK-021 đã chốt: người dùng có thể muốn hai deck "Unit 5" cho hai giáo trình, nên
ép duy nhất là hạn chế tuỳ tiện.

---

## Entity state machines

### Deck — `content_type`

| Trạng thái | Ý nghĩa |
|---|---|
| `unset` | chưa có card và chưa có deck con (BR-DECK-006) |
| `card` | chỉ chứa card (BR-DECK-009) |
| `deck` | chỉ chứa deck con (BR-DECK-010) |

| From | To | Trigger |
|---|---|---|
| unset | card | tạo card đầu tiên (BR-DECK-008) |
| unset | deck | tạo deck con đầu tiên (BR-DECK-008) |
| card | unset | xoá card cuối cùng, hoặc chuyển card cuối cùng đi nơi khác — tự động, trong cùng transaction (BR-DECK-015, BR-CARD-010) |
| deck | unset | xoá deck con cuối cùng, hoặc chuyển deck con cuối cùng đi nơi khác — tự động, trong cùng transaction (BR-DECK-015) |

**Chuyển đổi không hợp lệ:** `card` → `deck` và `deck` → `card` trực tiếp — một
deck đang có nội dung không đổi loại. Đường duy nhất giữa hai loại là đi qua
`unset`, và `unset` chỉ đạt được bằng cách deck thật sự rỗng (BR-DECK-015).

Root deck được tạo thẳng với `content_type = 'deck'` và giá trị đó bất biến — đó
là cách BR-DECK-004 trở thành ràng buộc kiểm tra được bằng cùng một câu query như mọi
deck khác.

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Deck.name | không rỗng sau trim | "Tên deck không được để trống" | rule |
| Deck.name | ≤ 200 ký tự | "Tên deck tối đa 200 ký tự" | rule |
| Deck.move | đích không phải chính nó hoặc descendant | "Không thể di chuyển deck vào chính nó" | rule |
| Deck.create (sub-deck) | cấp của deck mới ≤ 10 (BR-DECK-001) | "Deck đã ở độ sâu tối đa (10 cấp)" | store |
| Deck.move | cấp đích + chiều cao subtree nguồn ≤ 10 (BR-DECK-001) | "Di chuyển vào đây sẽ vượt độ sâu tối đa (10 cấp)" | store |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Bấm Create ở root deck | Chỉ có lựa chọn Create deck (BR-DECK-005) |
| Bấm Create ở sub-deck `unset` | Hiện hai lựa chọn (BR-DECK-007) |
| Bấm Create ở sub-deck `content_type = card` | Chỉ có Create card (BR-DECK-012) |
| Xoá card cuối cùng của deck `content_type = card` | `content_type` về `unset` trong cùng transaction (BR-DECK-015) |
| Muốn đổi deck rỗng từ `card` sang chứa deck con | Rỗng là đã `unset`; tạo deck con luôn được (BR-DECK-015) |
| Kéo deck vào descendant của chính nó | Chặn, lỗi rõ ràng (BR-DECK-017) |
| Cây sâu 4–5 cấp | Hoạt động bình thường; root tra qua `root_id` (BR-DECK-002, BR-DECK-003) |
| Tạo deck con dưới deck đang ở cấp 10 | Chặn trước khi ghi; parent giữ nguyên `content_type` (BR-DECK-001, BR-DECK-008) |
| Move khiến cấp sâu nhất sau move vượt 10 | Chặn; không đổi parent, root pointer hay `content_type` của đích (BR-DECK-001, BR-DECK-018) |
| Ôn phiên trải trên nhiều deck con | Một tập action duy nhất, của root deck (BR-DECK-024, BR-STUDY-009) |
| Deck rỗng (0 card) | Empty state với hành động phù hợp `content_type`; không vào được phiên nào |
