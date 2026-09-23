# Document conventions — hợp đồng tài liệu

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Quy định format bắt buộc cho mọi tài liệu trong `docs/`, để AI agent và người đọc cùng một cách hiểu về "cái gì là quyết định chính thức" |
| **Scope** | Toàn bộ `docs/*.md` và các reference trong `.claude/skills/` |
| **Source of truth for** | Format tài liệu, thứ tự đọc, từ khoá MUST/SHOULD/MAY, quy tắc canonical location, quy tắc superseded |
| **Depends on** | — (đây là tài liệu gốc của hệ thống tài liệu) |
| **Updated by** | `docs/superpowers/plans/2026-09-23-docs-v8-reset.md` — V8 reset: gỡ mẫu AD, template WBS task và tham chiếu tài liệu đã xoá khỏi hợp đồng tài liệu |
| **Last updated** | 2026-09-23 |

---

## 1. Vấn đề mà tài liệu này giải quyết

Một agent đọc `docs/` cần trả lời được ba câu:

1. **Đọc theo thứ tự nào?** Không có thứ tự thì agent đọc file nào gặp trước, và
   một quyết định trong `docs/superpowers/specs/` có thể bị bỏ qua vì nó đọc
   `use-cases.md` trước.
2. **Câu nào là quyết định chính thức, câu nào là giải thích?** Prose giải thích
   *tại sao* một rule tồn tại rất dễ bị đọc thành một rule mới. Ví dụ minh hoạ
   càng dễ bị đọc thành đặc tả.
3. **Thông tin này ở đâu là bản gốc?** Cùng một rule viết ở hai file thì sớm muộn
   hai bản sẽ lệch nhau, và không ai biết bản nào đúng.

---

## 2. Thứ tự đọc

MUST đọc theo đúng thứ tự này khi cần hiểu hệ thống. Mỗi tài liệu giả định các
tài liệu trước nó đã được đọc.

| # | Tài liệu | Trả lời câu hỏi |
|---|---|---|
| 1 | `CLAUDE.md` | Ràng buộc nào áp dụng ở mọi phase? |
| 2 | `docs/document-conventions.md` | Tài liệu được viết và đọc thế nào? *(file này)* |
| 3 | `docs/product.md` | Sản phẩm là gì, phạm vi MVP đến đâu? |
| 4 | `docs/superpowers/specs/` | Quyết định kiến trúc nào đã chốt, và vì sao? |
| 5 | `docs/business-rules.md` (+ `business-rules/study-mode.md`) | Luật nghiệp vụ nào phải đúng? |
| 6 | `docs/data-model.md` | Dữ liệu được mô hình hoá thế nào? |
| 7 | `docs/use-cases.md` | Người dùng đi qua những luồng nào? |
| 8 | `docs/master-flow.md` | Các UC nối vào nhau thành hành trình nào? |
| 9 | `docs/superpowers/plans/` | Kế hoạch triển khai nào đang chạy, và các bước của nó? |

Đọc **1–2 trước mọi thứ khác**. Với một task cụ thể, agent SHOULD đọc thêm chỉ
những tài liệu mà task chạm tới, không đọc hết.

`docs/it-scenarios/` là bộ kịch bản kiểm thử tích hợp; đọc khi task chạm tới
kiểm thử, không nằm trong thứ tự bắt buộc ở trên.

`.claude/skills/` là hướng dẫn *cách làm*, không phải quyết định sản phẩm. Khi
skill và `docs/` mâu thuẫn, `docs/` thắng, và mâu thuẫn đó là một defect phải sửa.

---

## 3. Từ khoá mức độ ràng buộc

Mọi câu mang tính ràng buộc MUST dùng một trong ba từ khoá sau, viết hoa:

| Từ khoá | Nghĩa | Vi phạm thì sao |
|---|---|---|
| **MUST** | Bắt buộc. Không có ngoại lệ trong phạm vi MVP. | Là defect. Không merge. |
| **SHOULD** | Khuyến nghị mạnh. Làm khác được, nhưng phải ghi lý do. | Cần biện minh. |
| **MAY** | Tuỳ chọn. Cả hai lựa chọn đều chấp nhận được. | Không sao. |

Câu **không** chứa từ khoá nào là **giải thích, không phải ràng buộc**. Agent
MUST NOT suy ra một rule mới từ prose giải thích.

Tiếng Việt tương đương được dùng trong thân rule (`phải`, `không được`, `nên`,
`có thể`), nhưng khi cần rõ mức độ thì MUST dùng từ khoá viết hoa.

---

## 4. Header bắt buộc cho mọi tài liệu

Mọi file trong `docs/` MUST mở đầu bằng tiêu đề `#` rồi ngay sau đó là bảng
header với **đủ bảy dòng**, đúng thứ tự này:

```markdown
# <Tên tài liệu>

| | |
|---|---|
| **Status** | draft \| frozen for MVP \| active \| superseded |
| **Purpose** | Một câu: tài liệu này tồn tại để làm gì |
| **Scope** | Cái gì nằm trong, và cái gì cố ý nằm ngoài |
| **Source of truth for** | Danh sách thông tin mà file này là bản gốc |
| **Depends on** | Các tài liệu phải đọc trước |
| **Updated by** | `<đường dẫn plan>` — mô tả ngắn thay đổi |
| **Last updated** | YYYY-MM-DD |
```

**Updated by** là đường dẫn plan trong `docs/superpowers/plans/` đã tạo ra thay
đổi này, kèm mô tả ngắn — **không** phải task ID: V8 không có WBS ledger nên
không có ID nào để trỏ tới.

**Source of truth for** là dòng quan trọng nhất. Nó là cách quy tắc canonical
location (mục 5) được diễn đạt thành thứ kiểm tra được: nếu hai file cùng khai
báo là nguồn gốc của một thông tin, đó là defect.

Giá trị `Status`:

| Giá trị | Nghĩa |
|---|---|
| `draft` | Đang viết, chưa được dựa vào |
| `frozen for MVP` | Đã chốt. Code viết theo nó. Sửa là quyết định có chủ đích |
| `active` | Sống theo tiến độ dự án, cập nhật thường xuyên |
| `superseded` | Đã bị thay thế; giữ lại để tra cứu |

---

## 5. Canonical location — một thông tin, một chỗ

**MUST:** mỗi thông tin có đúng **một** vị trí gốc. Các file khác MUST tham chiếu
bằng ID (`BR-xx`, `UC-xx`), MUST NOT chép lại nội dung.

| Loại thông tin | Vị trí gốc |
|---|---|
| Quyết định kiến trúc và lý do | `docs/superpowers/specs/` |
| Luật nghiệp vụ, validation, state machine | `business-rules.md` (BR-xx) |
| Luồng người dùng | `use-cases.md` (UC-xx) |
| Bảng, cột, index, query bất biến | `data-model.md` |
| Phạm vi sản phẩm, MVP, quyết định nền tảng | `product.md` |
| Kế hoạch triển khai, tiến độ theo từng plan | `docs/superpowers/plans/` |
| Kịch bản kiểm thử tích hợp theo hành trình | `it-scenarios/` |
| Format tài liệu | file này |

Lý do quy tắc này chặt: hai bản sao của cùng một rule **luôn** lệch nhau sau vài
lần sửa, và lúc đó không có cách nào biết bản nào đúng ngoài việc hỏi người viết
— người đã quên. Tham chiếu bằng ID không có vấn đề đó.

**Được phép nhắc lại** một kết luận ngắn kèm ID để đoạn văn đọc được (`scheduler
thuộc root deck (BR-05)`). **Không được phép** chép lại chi tiết đủ để hai chỗ có
thể mâu thuẫn.

---

## 6. Template cho từng loại nội dung

Field đánh dấu **MUST** thì luôn có. Field đánh dấu **MAY** chỉ viết khi nó thật
sự bổ sung thông tin — một mục `Examples: —` không phải là sự đầy đủ, nó là nhiễu
và làm loãng phần có tín hiệu.

### 6.2. BR — Business Rule

BR nhiều (hiện 87), nên MUST dùng **dạng bảng** làm mặc định:

```markdown
| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-xx | active | <Luật, một câu, dùng MUST/SHOULD/MAY> | domain \| db \| UI \| script | UC-xx |
```

| Field | Mức | Ghi chú |
|---|---|---|
| ID | MUST | Vĩnh viễn (mục 7) |
| Status | MUST | `active` \| `superseded by BR-yy` |
| Rule | MUST | Một câu. Nhiều câu nghĩa là nhiều rule |
| Enforced by | MUST | Chỗ rule được cưỡng chế: `domain`, `db`, `UI`, `scheduler`, `script`, hoặc `—` nếu chưa cưỡng chế được |
| Related | MUST | UC liên quan, hoặc `—` |
| Rationale | MAY | Đoạn prose **dưới bảng**, mở đầu bằng `BR-xx` |
| Examples | MAY | Chỉ khi ví dụ làm rõ được ranh giới |
| Edge cases | MAY | Gom ở mục `## Edge cases` cuối tài liệu |

`Enforced by` là field có giá trị thực tế cao nhất khi code: nó nói cho người
triển khai biết rule này sống ở đâu trong hệ thống, và nó phơi bày những rule
hiện chưa có gì cưỡng chế.

Rule cần nhiều hơn một câu (ví dụ có bảng tra) MUST dùng dạng section
`### BR-xx · <tiêu đề>` và vẫn phải xuất hiện Status/Enforced by/Related ngay
dưới tiêu đề.

### 6.3. UC — Use Case

MUST dùng dạng section, đủ chín mục:

```markdown
## UC-xx · <Tên>

| | |
|---|---|
| **Status** | active \| superseded by UC-yy |

**Actor:**
**Trigger:**
**Preconditions:**
**Main flow:** <các bước đánh số>
**Alternative flows:** <A1, A2, …>
**Error flows:** <E1, E2, …>
**Postconditions:**
**Business rules:** <BR-xx, …>
**UI states:** <initial · loading · loaded · empty · error · submitting>
```

`Error flows` và `UI states` là hai mục hay bị bỏ và là nguồn của phần lớn màn
hình thiếu trạng thái. MUST liệt kê đủ; trạng thái không xảy ra thì MUST nói rõ
vì sao thay vì im lặng bỏ.

### 6.4. Data model

Mỗi bảng MUST có: một section `## <tên bảng>`, một bảng cột với
`Cột | Kiểu | Ghi chú`, danh sách index, và tham chiếu BR cho mọi ràng buộc.

Mọi bất biến MUST được diễn đạt thành một câu SQL **trả về 0 dòng khi dữ liệu
đúng**, đặt trong mục `## Bất biến`, đánh số `-- N. <mô tả> (BR-xx)`.

Định dạng đó không tuỳ tiện: `tools/check_docs_refs.py` dựa vào đúng khuôn
`-- N.` để đối chiếu invariant với nơi trích dẫn nó. Viết sai khuôn thì tham
chiếu `invariant Q<n>` không đối chiếu được.

---

## 7. ID là vĩnh viễn

**MUST NOT** đánh số lại BR, UC hay invariant. Mục mới append vào số tiếp theo,
kể cả khi nó thuộc một phần nằm đầu tài liệu. ID vì thế **không** tăng dần theo
thứ tự đọc, và đó là cố ý.

Lý do cụ thể: lần renumber trước đã làm `BR-13` trỏ sang một rule về template
trong khi nó định trỏ tới rule reset. Không test nào bắt được; nó chỉ lộ ra khi
ai đó đọc và làm theo.

Rule bị thay thế MUST đánh dấu `superseded by BR-yy` ở cột Status, giữ nguyên ID
và nguyên văn. **MUST NOT xoá.** Một ID biến mất khiến mọi tham chiếu cũ — trong
commit message, code comment, PR — trỏ vào hư không.

---

## 8. Tài liệu frozen và phạm vi sửa

**MUST:** agent MUST NOT sửa tài liệu có `Status: frozen for MVP` trừ khi task
hiện tại nêu **tường minh** file đó là được phép sửa.

**MUST:** mọi task sửa tài liệu MUST liệt kê chính xác các file được phép sửa.

Lý do: tài liệu frozen là hợp đồng mà code được viết theo. Một sửa đổi tiện tay
trong lúc làm việc khác sẽ làm code và spec lệch nhau mà không ai để ý — và spec
là thứ phiên sau tin tưởng.

Khi một task **cần** sửa tài liệu frozen ngoài phạm vi đã nêu, agent MUST dừng và
nói rõ file nào cần sửa và vì sao, thay vì tự mở rộng phạm vi.

---

## 9. Ví dụ không phải là rule

**MUST NOT** coi đoạn code, ví dụ minh hoạ, hay bảng "ví dụ" là đặc tả.

Ví dụ tồn tại để làm rõ ranh giới của một rule đã được phát biểu ở chỗ khác. Khi
ví dụ và rule mâu thuẫn, **rule thắng**, và ví dụ sai là một defect phải sửa.

Đoạn code trong `docs/` và trong `.claude/skills/` là **minh hoạ hình dạng**, không
phải code phải chép nguyên. Tên biến, tên hàm và chi tiết triển khai trong đó
MAY khác với code thật.

---

## 10. Validation

`tools/check_docs_refs.py` kiểm phần cơ học của hợp đồng này:

| Kiểm | Bắt được gì |
|---|---|
| Mọi `BR-xx` / `UC-xx` / `invariant Q<n>` được trích dẫn đều resolve được | Tham chiếu chết sau khi sửa |

Những gì `tools/check_docs_refs.py` **không** kiểm được, và MUST do người xem:
tài liệu có đủ bảy dòng header không, `Source of truth for` có trùng giữa các
file không (vi phạm mục 5), BR/UC có trùng ID không (vi phạm mục 7), bảng BR có
đủ cột bắt buộc không (mục 6.2), UC có đủ chín mục không (mục 6.3), query bất
biến có parse và phân biệt được đúng khuôn không (mục 6.4), một tài liệu có
trích dẫn một tài liệu hoặc đường dẫn không còn tồn tại không, tài liệu còn
marker chưa chốt hay không, một rule có phải rule tốt không, một tham chiếu có
trỏ đúng rule về mặt ngữ nghĩa không, và một `Rationale` có thật sự giải thích
được gì không.
