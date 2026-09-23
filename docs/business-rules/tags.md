# Business rules — Tags

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng TAG, dưới ID vĩnh viễn `BR-TAG-nnn` |
| **Scope** | Mô hình dữ liệu tag và quản lý tag: catalog, filter, rename/merge, delete. |
| **Source of truth for** | BR-TAG-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

**Phạm vi:** sub-project sau — Tags (spec §2).

## Tag — mô hình dữ liệu

Tách từ mục "Cờ và tag" của `business-rules.md` cũ. Các rule dưới đây là mô hình dữ liệu cốt lõi của tag; mục "Quản lý tag" bên dưới **không** phát biểu lại chúng.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-TAG-001 | active | Tag MUST là nội dung, quan hệ nhiều-nhiều với thẻ. Tên tag MUST không rỗng sau trim, MUST tối đa 50 ký tự, và MUST là duy nhất không phân biệt hoa thường. | rule + db | BR-SRS-021, UC-CARD-001 |
| BR-TAG-002 | active | Một thẻ MUST mang tối đa 10 tag. | rule | BR-TAG-001 |

BR-TAG-002 là một giới hạn của **giao diện** được nâng thành rule, và nó thừa nhận
điều đó: hàng thẻ vẽ tag thành một dãy chip, và một dãy không giới hạn sẽ tràn ở
320 với `textScaler` 2.0. Mười là con số đủ rộng để không ai gặp phải trong thực
tế và đủ hẹp để hàng thẻ có chiều cao đoán được.

---

## Quản lý tag — catalog, filter, rename/merge, delete

**Phạm vi:** sub-project sau — Tags (spec §2).

Tag Management v1 không đổi mô hình dữ liệu của BR-TAG-001/BR-TAG-002: nó chỉ thêm mặt
**quản lý** cho cùng những hàng đó — nhìn toàn bộ tag, lọc thẻ theo tag, đổi tên
(có thể dẫn tới gộp) và xoá tag. Các rule dưới đây **không** phát biểu lại
BR-TAG-001 (chuẩn hoá tên, duy nhất không phân biệt hoa thường) hay BR-TAG-002 (trần 10
tag mỗi thẻ); chúng chỉ nói phần mà mặt quản lý thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-TAG-003 | active | Tag catalog MUST ở phạm vi **library** — mọi tag của owner hiện tại, không giới hạn theo deck đang mở (BR-TAG-001). Mỗi hàng MUST hiển thị tên canonical đúng như đã lưu và số thẻ **đang hoạt động** mang tag đó. Catalog MUST sắp theo `name_folded` tăng dần với tie-break `id` tăng dần — MUST NOT sắp theo tên chưa fold, vì hai cách fold khác nhau cho hai thứ tự khác nhau ở cùng một dữ liệu. Tìm kiếm trong catalog MUST dùng đúng phép fold của BR-TAG-001 cho cả chuỗi tìm lẫn cột được tìm; MUST NOT thêm bộ chuẩn hoá thứ hai. Tag không còn thẻ nào MUST vẫn xuất hiện với số đếm 0 — nó vẫn là một tag người dùng tạo ra và vẫn phải xoá được. | rule + store | BR-TAG-001, UC-TAG-001 |
| BR-TAG-004 | active | Lọc thẻ theo nhiều tag MUST là **OR giữa các tag đã chọn** — thẻ mang ít nhất một tag trong tập chọn là thẻ khớp. Vị từ tag MUST được **AND** với filter trạng thái đang bật (All/Due/New/Flagged) và với search term. **Tập chọn rỗng MUST là phần tử đơn vị**: không có vị từ tag nào được áp, và kết quả MUST bằng đúng kết quả khi tính năng chưa tồn tại. Vị từ tag MUST hiện thực bằng một phép kiểm tồn tại trên `card_tags` (`EXISTS` hoặc tương đương trả về nhiều nhất một hàng cho mỗi thẻ), MUST NOT bằng một join nhân bản: một thẻ mang ba tag đã chọn MUST xuất hiện đúng **một** lần trong danh sách, đếm đúng **một** lần trong count và chiếm đúng **một** chỗ trong cửa sổ phân trang. Danh sách, count và "select all" (BR-CARD-012) MUST dùng chung một vị từ. | store | BR-CARD-012, UC-CARD-001, UC-TAG-001 |
| BR-TAG-005 | active | Đổi tập tag đang lọc MUST reset cửa sổ phân trang về trang đầu, cùng lý do với đổi filter/search/sort (BR-CARD-012): một cửa sổ mở trên tập kết quả cũ không mô tả tập kết quả mới. Selection đang mở MUST bị xoá khi tập tag đổi. Kết quả của một truy vấn đã cũ MUST bị bỏ qua, MUST NOT ghi đè kết quả của tập tag hiện tại. | UI + store | BR-CARD-012, UC-TAG-001 |
| BR-TAG-006 | active | Đổi tên tag MUST đi qua đúng validation của BR-TAG-001 — trim, tối đa 50 ký tự, không ký tự điều khiển, và fold bằng chính hàm mà việc tạo tag dùng. Nếu tên đã fold **chưa** thuộc về tag nào khác, đổi tên MUST giữ nguyên `id` của tag và toàn bộ quan hệ `card_tags` của nó; chỉ `name` và `name_folded` được ghi. Đổi tên chỉ khác cách viết hoa của chính nó (`noun` → `Noun`) MUST được chấp nhận và MUST NOT bị coi là trùng với chính mình. | rule + store | BR-TAG-001, UC-TAG-001 |
| BR-TAG-007 | active | Nếu tên đã fold trùng với một tag **khác** đang tồn tại, đổi tên MUST gộp tag nguồn vào tag đích **nguyên tử trong đúng một transaction**: mọi thẻ mang tag nguồn mà chưa mang tag đích MUST được nối tới tag đích, liên kết trùng MUST được dedupe (cặp `(card_id, tag_id)` là khoá), mọi liên kết còn lại của tag nguồn MUST bị gỡ, và **hàng tag nguồn MUST bị xoá**. Tag đích MUST giữ nguyên `id`, `name` và `name_folded` — gộp không đổi cách viết của đích. Gộp MUST NOT làm bất kỳ thẻ nào vượt trần BR-TAG-002: số tag của một thẻ sau khi gộp MUST bằng hoặc nhỏ hơn trước khi gộp, vì mỗi thẻ đổi nguồn lấy đích chứ không cộng thêm. Một write thất bại MUST rollback toàn bộ, để lại đúng đồ thị tag ban đầu — MUST NOT có trạng thái nửa gộp trong đó cả hai tag cùng tồn tại với liên kết đã dời một phần. | store | BR-TAG-001, BR-TAG-002, UC-TAG-001 |
| BR-TAG-008 | active | Xoá tag MUST **chỉ** gỡ mọi hàng `card_tags` của tag đó rồi xoá hàng `tags`, trong một transaction. MUST NOT xoá, ẩn hay đụng tới bất kỳ thẻ nào, kể cả thẻ chỉ mang duy nhất tag đó. Xác nhận MUST nêu rõ số thẻ sẽ bị gỡ tag và MUST NOT dùng lời lẽ ngụ ý mất thẻ; hành động MUST được mô tả là gỡ tag khỏi thẻ. Xoá tag không còn thẻ nào MUST thành công không cần xác nhận khác biệt về nghĩa. | store + UI | BR-TAG-001, UC-TAG-001 |
| BR-TAG-009 | active | Mọi thao tác catalog — đổi tên, gộp, xoá — MUST là read-only đối với nội dung thẻ và dữ liệu học: MUST NOT ghi `front`, `back`, ba trường phụ, `is_flagged`, `card.updated_at`, `content_type` của deck (BR-DECK-015), study state, review history hay session. Thứ duy nhất được ghi là hàng `tags` và hàng `card_tags`. | store | BR-CARD-005, BR-SRS-021, BR-CARD-009, BR-DECK-015, BR-TRANSFER-011, UC-TAG-001 |
| BR-TAG-010 | active | Khi Trash tồn tại, thẻ đang ẩn trong Trash MUST NOT được tính vào số đếm "thẻ đang hoạt động" của catalog (BR-TAG-003) và MUST NOT xuất hiện trong kết quả lọc theo tag. Đổi tên và gộp MUST vẫn giữ liên kết tag của thẻ đang ẩn để khôi phục không mất metadata; purge vĩnh viễn MUST cascade dọn `card_tags` như xoá thẻ thường. Chừng nào Trash chưa tồn tại, mọi thẻ đã lưu đều là thẻ đang hoạt động và rule này MUST NOT được hiện thực bằng một cột hay một trạng thái ẩn được phát minh trước. | store | BR-TAG-003, BR-TAG-008 |
| BR-TAG-011 | active | Catalog MUST NOT thêm bản thứ hai của codec tag hay của hàm fold: import, export và catalog MUST dùng chung một codec (BR-TRANSFER-009) và một phép chuẩn hoá tên tag (BR-TAG-001). Tag do import tạo ra MUST xuất hiện trong catalog như mọi tag khác, và round-trip export → import MUST không đổi sau khi đổi tên, gộp hay xoá — điều thay đổi là tập tag của thẻ, không phải cách chúng được mã hoá. | rule | BR-TAG-001, BR-TRANSFER-002, BR-TRANSFER-009, UC-TAG-001 |

BR-TAG-004 là rule dễ hiện thực sai nhất trong nhóm này, và cả hai cách sai đều
trông đúng ở dữ liệu nhỏ. Một `INNER JOIN card_tags` với `tag_id IN (…)` cho
đúng tập thẻ nhưng **nhân bản hàng** theo số tag khớp, nên `LIMIT 50` trả về ít
hơn 50 thẻ và `COUNT(*)` đếm to hơn sự thật; `DISTINCT` chữa được count nhưng
vẫn buộc SQLite vật chất hoá rồi khử trùng, làm mất chính điểm dừng sớm mà
`LIMIT` và index `(deck_id, created_at, id)` mua được. `EXISTS` không có cả hai
vấn đề: nó là một phép kiểm boolean cho mỗi thẻ.

BR-TAG-007 gộp bằng đổi tên chứ không có một hành động `Merge` riêng, và đó là quyết
định về giao diện được nâng thành rule. Người dùng gõ `Noun` lên tag `nouns` là
đang nói "hai cái này là một"; bắt họ tìm một menu khác để nói đúng điều vừa gõ
là thêm một bước cho cùng một ý định.

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Tag.name | không rỗng sau trim (BR-TAG-001) | "Tên tag không được để trống" | rule |
| Tag.name | ≤ 50 ký tự (BR-TAG-001) | "Tên tag tối đa 50 ký tự" | rule |
| Tag.name | không trùng, không phân biệt hoa thường (BR-TAG-001) | "Tag này đã tồn tại" | rule + db |
| Card.tags | ≤ 10 tag mỗi thẻ (BR-TAG-002) | "Mỗi thẻ tối đa 10 tag" | rule |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.
