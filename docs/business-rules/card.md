# Business rules — Card

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng CARD, dưới ID vĩnh viễn `BR-CARD-nnn` |
| **Scope** | Luật nội dung card, cờ, di chuyển, thao tác hàng loạt và chi tiết card (V8.0). Ngoài phạm vi: lịch học (`srs.md`), tag (`tags.md`) |
| **Source of truth for** | BR-CARD-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Card

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-CARD-001 | active | Card MUST có mặt trước và mặt sau, đều không rỗng sau khi trim. | rule | UC-CARD-001 |
| BR-CARD-002 | active | Mặt trước MUST tối đa **60** ký tự và mặt sau MUST tối đa **240** ký tự, đo sau khi trim. | rule | UC-CARD-001 |
| BR-CARD-003 | active | Thẻ MAY có ba trường phụ, đều tuỳ chọn: ví dụ, gợi ý và phiên âm. Mỗi trường MUST tối đa 240 ký tự sau khi trim. | rule | UC-CARD-001, BR-CARD-002 |
| BR-CARD-004 | active | Tạo card MUST đồng thời tạo study state theo scheduler của root deck, với `generation` hiện tại của root và `due_at = NULL`. | store | UC-CARD-001, UC-DECK-004 |
| BR-CARD-005 | active | Sửa nội dung card MUST NOT đụng đến study state hay study answers. | store | UC-CARD-001 |

Card chỉ tồn tại trong deck có `content_type = card` (BR-DECK-009), và không bao giờ
trong root deck (BR-DECK-004).

**BR-CARD-002 đổi số: 2000 cho cả hai → 60 và 240.** Rule giữ nguyên ID chứ
không đánh `superseded`, vì cơ chế supersede của §7 dành cho lúc *danh tính* một
rule đổi khiến tham chiếu cũ trỏ sai chỗ. Ở đây ý nghĩa không đổi — "hai mặt có
giới hạn độ dài" — nên 21 chỗ đang trích BR-CARD-002 vẫn trích đúng thứ chúng định
trích. Cái đổi là con số, và nó được ghi ở đây thay vì im lặng.

2000 là **hàng rào chống dán**, không phải một quyết định về thẻ: nó chặn ai đó
thả nguyên một trang vào ô và không nói gì về thẻ nên dài bao nhiêu. 60 là bề
rộng mà hàng danh sách và mặt trước thẻ ôn được vẽ cho; quá đó thì prompt xuống
ba dòng trên điện thoại và câu trả lời rơi khỏi tầm nhìn. 240 gấp bốn vì một
nghĩa chứa nhiều hơn một từ — hai ngôn ngữ, ngăn bằng dấu phẩy.

**Hai mặt nay có hai số, nên giới hạn thuộc về từng mặt thẻ** chứ không phải một
hằng số dùng chung. Một hằng chung là đúng khi số giống nhau và trở thành cách
âm thầm cho mặt trước mượn hạn mức của mặt sau ngay khi chúng khác nhau; test
cho từng mặt ghim đúng điều đó.

BR-CARD-003 để cả ba trường phụ ở 240 thay vì ba con số riêng. Chúng là văn bản hỗ
trợ cùng bậc với mặt sau, và ba ngưỡng khác nhau cho ba ô trông giống nhau là
thứ phải giải thích mà không mua được gì.

Giá trị khởi tạo của study state theo scheduler:

| Scheduler | Khởi tạo |
|---|---|
| `eight_box` | `current_box = 1`; cột SM-2 để NULL |
| `sm2` | `ease_factor = 2.5`, `interval_days = 0`, `repetitions = 0`; `current_box` NULL |

---

## Trạng thái hiển thị của thẻ

BR-SRS-013 đã định nghĩa nửa trên của thang này — "đã thuộc" — cho cả hai scheduler.
Ba rule dưới đây chia phần còn lại, và **không** phát biểu lại BR-SRS-013.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-CARD-006 | active | Trạng thái hiển thị của một thẻ MUST là một trong bốn: `new`, `beginning`, `reviewing`, `mastered`. Nó MUST được suy ra khi đọc và MUST NOT là cột trong DB. | rule | BR-SRS-013, UC-CARD-001 |
| BR-CARD-007 | active | Thẻ **chưa học xong lần đầu** (`learned_at IS NULL`) MUST là `new`, ở cả hai thuật toán. MUST NOT suy từ `answer_count`, vì chuỗi học mới không sinh lượt `scheduled` nào (BR-STUDY-053). | rule | BR-CARD-006, BR-SRS-018, BR-STUDY-053 |
| BR-CARD-008 | active | Với thẻ đã học và chưa "đã thuộc": interval hiện tại dưới 8 ngày MUST là `beginning`, từ 8 ngày trở lên MUST là `reviewing`. Với `eight_box` đó là box 1–3 và box 4–7; với `sm2` là `interval_days` < 8 và 8…127. | rule | BR-CARD-006, BR-SRS-009, BR-SRS-013 |

**Mốc 8 ngày không phải số mới.** Nó là interval của box 4 trong BR-SRS-009, và thang
đó là luỹ thừa của hai — 1, 2, 4, **8**, 16, 32, 64, 128 — nên box 1–3 là toàn bộ
phần dưới một tuần và box 4 là bước đầu tiên ra khỏi nhịp ôn ngắn. Dùng lại đúng
mốc đó cho `sm2` khiến `beginning` nghĩa là **cùng một khoảng cách thời gian** ở
cả hai scheduler, là chính lập luận BR-SRS-013 dùng khi chọn 128 thay vì 21.

Chọn một ngưỡng riêng cho `sm2` — 7 ngày, hay 30 — sẽ khiến hai deck cùng nhịp
ôn hiện hai nhãn khác nhau, và không có gì trong dữ liệu giải thích được vì sao.

**Bốn trạng thái là nhãn hiển thị, không phải state machine.** Không có chuyển
tiếp nào được định nghĩa giữa chúng và không có gì lưu chúng lại; chúng là một
phép đọc `card_schedule` tại thời điểm vẽ. Thẻ đi lùi từ `reviewing` về
`beginning` sau một lần quên là chuyện bình thường, không phải vi phạm.

---

## Cờ, di chuyển và thao tác hàng loạt trên thẻ

Tách từ mục "Cờ và tag" của `business-rules.md` cũ theo đối tượng mà từng rule ràng buộc: cờ và các thao tác trên card ở đây, luật tag ở `tags.md`, luật import ở `transfer.md`.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-CARD-009 | active | Cờ đánh dấu thẻ MUST là nội dung: sửa thẻ và reset learning progress MUST NOT đụng tới nó; xoá thẻ MUST xoá nó theo cascade. Hệ thống MAY **bật** cờ (BR-STUDY-073) nhưng MUST NOT tự tắt — bỏ dấu là hành động của người dùng. | db + store | BR-CARD-005, BR-SRS-021, BR-STUDY-073 |
| BR-CARD-010 | active | Di chuyển thẻ MUST chỉ xảy ra giữa hai sub-deck **cùng một root**. Deck đích MUST NOT là root (BR-DECK-004), MUST có `content_type` là `unset` hoặc `card`, và MUST NOT là `deck` (BR-DECK-010). Deck đích MUST khác deck nguồn. Di chuyển **cross-root** MUST bị từ chối bằng một lý do có kiểu riêng, **kể cả khi hai root tình cờ cùng scheduler và cùng generation** — BR-SRS-005/BR-SRS-006 cấm chuyển đổi study state, và "tình cờ giống nhau" không phải một phép ánh xạ. Di chuyển MUST giữ nguyên: id thẻ, nội dung hai mặt và ba trường phụ, study state, toàn bộ review history, cờ, quan hệ tag và `created_at`. MUST chỉ ghi `deck_id` và `updated_at` của thẻ; MUST NOT đụng `scheduler_type`, `generation` hay bất kỳ cột lịch nào. Nếu deck nguồn mất thẻ cuối, `content_type` của nó MUST về `unset`; nếu deck đích đang `unset`, nó MUST thành `card` — cả hai trong **cùng transaction** với việc dời thẻ (BR-DECK-015). | store | UC-CARD-001, BR-DECK-004, BR-DECK-010, BR-SRS-005, BR-SRS-006, BR-DECK-015 |
| BR-CARD-011 | active | Mọi mutation hàng loạt trên thẻ — di chuyển, xoá, đặt/bỏ cờ, gắn tag — MUST là **all-or-nothing trong đúng một transaction**: một thẻ vi phạm làm cả lô rollback, và MUST NOT có partial success không được đặc tả. Gắn tag hàng loạt MUST giữ nguyên quy tắc đơn lẻ: dùng lại tag theo tên đã fold (BR-TAG-001), trần 10 tag mỗi thẻ (BR-TAG-002), và **idempotent** khi thẻ đã có tag đó. Chỉ cần một thẻ chạm trần là cả lô bị từ chối. Đặt cờ hàng loạt MUST là lệnh tường minh `Set flagged` / `Remove flag`, MUST NOT là toggle suy ra từ thẻ đầu tiên. Xoá hàng loạt MUST cascade study state và history như xoá đơn lẻ, và MUST đưa deck về `unset` nếu đó là những thẻ cuối (BR-DECK-015). | store | UC-CARD-001, BR-CARD-009, BR-TAG-001, BR-TAG-002, BR-DECK-015 |
| BR-CARD-012 | active | Chọn nhiều thẻ MUST áp dụng lên **toàn bộ tập kết quả** của deck hiện tại theo đúng filter và search term đang bật, MUST NOT chỉ giới hạn trong cửa sổ phân trang đã tải. "Select all" MUST đọc danh sách id qua cùng vị từ mà danh sách và các pill đếm dùng, MUST NOT tải nội dung thẻ chỉ để lấy id. Khi filter, search term, sort hoặc deck đổi, selection MUST bị xoá — một selection không nhìn thấy được là một mutation người dùng không đồng ý. Sau mutation thành công MUST xoá selection; khi thất bại MUST giữ selection và nêu lỗi, MUST NOT báo thành công. | UI + store | UC-CARD-001, BR-CARD-011 |

BR-CARD-009 và BR-TAG-001 nói cùng một điều mà BR-SRS-021 đã nói cho reset, nhưng ở chiều khác:
BR-SRS-021 nói reset giữ chúng lại, hai rule này nói *vì sao* — chúng thuộc nội dung,
cùng phía với `front`/`back`, chứ không thuộc lịch. Đó cũng là lý do cờ nằm trên
`card` chứ không trên `card_schedule`.

---

## Chi tiết card và lịch sử học

Mặt đọc của thẻ. Các rule dưới đây **không** phát biểu lại nội dung
(BR-CARD-001, BR-CARD-002, BR-CARD-003), cờ và tag (BR-CARD-009, BR-TAG-001, BR-TAG-002), trạng thái hiển thị
(BR-CARD-006…BR-CARD-008) hay tính bất biến của `review_log` (BR-SRS-023, BR-SRS-015) — chúng chỉ
nói phần mà một màn **chỉ đọc** thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-CARD-013 | active | Mở chi tiết card, cuộn nó và tải thêm trang lịch sử MUST là thao tác chỉ-đọc: MUST NOT ghi hay chạm tới nội dung card, `updated_at`, `content_type` của deck (BR-DECK-015), study state, review history, session, cờ hay quan hệ tag; MUST NOT đánh dấu thẻ đã học (`learned_at`) và MUST NOT tính là một lượt ôn. Xem một thẻ **không** phải là học nó. | store + UI | UC-CARD-002, BR-DECK-015, BR-TRANSFER-011 |
| BR-CARD-014 | active | Màn chi tiết MUST hiển thị **đầy đủ** `front` và `back` cùng ba field tuỳ chọn `example`, `hint`, `pronunciation` khi chúng có giá trị (BR-CARD-003), tag (BR-TAG-001) và cờ (BR-CARD-009), cộng **trạng thái lịch hiện tại** của thẻ đọc từ `card_schedule`: trạng thái hiển thị (BR-CARD-006…BR-CARD-008), `due_at`, `learned_at`, `last_answered_at`, `answer_count`, `lapse_count` và các field riêng của scheduler đang gắn — `current_box` cho `eight_box`, `ease_factor`/`interval_days`/`repetitions` cho `sm2`. Nội dung dài MUST xuống dòng hoặc cuộn được và MUST NOT bị cắt bằng ellipsis tuỳ tiện; field tuỳ chọn không có giá trị MUST vắng mặt, MUST NOT hiện nhãn rỗng hay placeholder. Field của scheduler **không** gắn với thẻ MUST NOT hiện. | rule + UI | UC-CARD-002, BR-CARD-006, BR-CARD-007, BR-CARD-008, BR-CARD-009, BR-TAG-001, BR-CARD-003 |
| BR-CARD-015 | active | Lịch sử học của một thẻ MUST đọc từ `review_log` của **đúng** `card_id` đó, sắp mới nhất trước theo `answered_at DESC` với tie-break `id DESC`, và MUST phân trang bằng **keyset** trên đúng cặp khoá đó với kích thước trang 50. MUST NOT dùng `OFFSET`, MUST NOT đọc toàn bộ lịch sử rồi cắt trong Dart, và MUST NOT đọc thêm một statement cho mỗi hàng (N+1). Một hàng mới được ghi trong lúc người dùng đang phân trang MUST NOT làm một hàng đã hiện xuất hiện lần thứ hai và MUST NOT làm mất một hàng chưa hiện — đó là hệ quả trực tiếp của việc cursor là giá trị của hàng cuối chứ không phải số thứ tự. | store | UC-CARD-002, BR-SRS-023 |
| BR-CARD-016 | active | Mỗi event trong lịch sử MUST hiển thị các giá trị **đã lưu** của chính hàng đó: thời điểm `answered_at`, `mode` (BR-MODE-008), `kind` (BR-SRS-014, BR-SRS-015), `action` (BR-STUDY-035), `outcome_reason` khi có (BR-STUDY-034) và `used_hint` khi có (BR-STUDY-028), cộng thay đổi lịch trước→sau đúng theo `scheduler_type` của hàng — `previous_box`→`next_box` cho `eight_box`; `previous_ease_factor`→`next_ease_factor` và `previous_interval_days`→`next_interval_days` cho `sm2` — và `next_due_at` khi có. MUST NOT suy ra `kind` hay `action` từ chênh lệch giữa trạng thái trước và sau, và MUST NOT hiển thị field trước→sau của scheduler khác với `scheduler_type` của hàng. Một lượt không dời lịch (`learning`, BR-STUDY-053) MUST hiện là không đổi lịch, MUST NOT hiện là lỗi hay thiếu dữ liệu. | rule + UI | UC-CARD-002, BR-SRS-014, BR-SRS-015, BR-MODE-008, BR-STUDY-034, BR-STUDY-035, BR-STUDY-028, BR-STUDY-053 |
| BR-CARD-017 | active | Hàng lịch sử MUST được nhóm theo `generation` đã lưu trên chính hàng đó, và nhóm MUST đọc được mà không cần màu — mỗi nhóm có tiêu đề dạng chữ. Reset (BR-SRS-021…BR-SRS-023) MUST NOT xoá hàng nào, nên generation cũ MUST vẫn xem được sau reset, kể cả khi scheduler của root đã đổi. Màn này MUST NOT tính accuracy, điểm số, streak hay bất kỳ giá trị tổng hợp nào từ lịch sử: đây là bản ghi thô, và một con số tổng hợp ở đây sẽ là định nghĩa thứ hai cạnh phần thống kê thật. | rule + UI | UC-CARD-002, BR-SRS-021, BR-SRS-022, BR-SRS-023 |
| BR-CARD-018 | active | Lịch sử rỗng MUST là trạng thái hợp lệ, MUST NOT là lỗi: một thẻ mới tạo chưa có hàng nào, và một thẻ đã đi hết chuỗi learning cũng có thể chưa có hàng `scheduled` nào (BR-STUDY-053). Nội dung và lịch sử có vòng đời riêng: sửa nội dung (BR-CARD-005) MUST NOT làm đổi trạng thái lịch hay thêm/bớt hàng lịch sử, và MUST NOT làm màn chi tiết hiện lịch sử khác đi ngoài phần nội dung. | rule + UI | UC-CARD-002, BR-CARD-005, BR-STUDY-053 |
| BR-CARD-019 | active | Thẻ không tồn tại — chưa bao giờ có, hoặc bị xoá từ màn khác trong lúc màn chi tiết đang mở — MUST surface bằng một lý do **có kiểu** — cùng lý do mà editor đã dùng khi thẻ biến mất, không phải một lý do thứ hai — MUST NOT là màn trắng, MUST NOT là thông báo kỹ thuật và MUST NOT lộ id, đường dẫn hay SQL (BR-PRIVACY-003). Route chi tiết của thẻ **đang hoạt động** MUST NOT hiển thị thẻ đã nằm trong Trash nếu tính năng đó tồn tại; Trash MAY dùng lại cùng read model qua một capability tường minh và MUST NOT nhân bản màn hình. | store + UI | UC-CARD-002, BR-PRIVACY-003, BR-CARD-011 |
| BR-CARD-020 | active | Chạm vào một hàng card trong danh sách đang ở chế độ thường MUST mở chi tiết chỉ-đọc của thẻ đó. Trong chế độ chọn nhiều (UC-CARD-001 A6), chạm MUST giữ nguyên nghĩa chọn/bỏ chọn và MUST NOT điều hướng. Sửa MUST là một action riêng, tường minh, dẫn tới editor sẵn có; nó MUST NOT là hành động mặc định của một lần chạm và MUST NOT nổi bật hơn phần nội dung đang đọc. Quay lại từ chi tiết MUST giữ nguyên ngữ cảnh của danh sách — filter, search term, sort, cửa sổ đã tải và selection. | UI | UC-CARD-002, UC-CARD-001, BR-CARD-012 |

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Card.front | không rỗng sau trim | "Mặt trước không được để trống" | rule |
| Card.back | không rỗng sau trim | "Mặt sau không được để trống" | rule |
| Card.front | ≤ 60 ký tự (BR-CARD-002) | "Mặt trước tối đa 60 ký tự" | rule |
| Card.back | ≤ 240 ký tự (BR-CARD-002) | "Mặt sau tối đa 240 ký tự" | rule |
| Card.example / hint / pronunciation | ≤ 240 ký tự (BR-CARD-003) | "Tối đa 240 ký tự" | rule |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Chuyển card cuối cùng sang deck khác cùng root | Nguồn về `unset`, đích thành `card` — một transaction (BR-CARD-010) |
| Chạm hàng card khi đang ở chế độ chọn nhiều | Toggle chọn; không mở chi tiết (BR-CARD-020) |
| Mở chi tiết một thẻ chưa từng được ôn | Lịch sử rỗng là trạng thái hợp lệ, không phải lỗi (BR-CARD-018) |
| Ghi thêm một lượt ôn giữa hai lần tải trang lịch sử | Không hàng nào hiện hai lần, không hàng nào bị bỏ qua (BR-CARD-015) |
| Thẻ bị xoá từ màn khác khi chi tiết đang mở | Not-found có kiểu, không màn trắng, không lộ id (BR-CARD-019) |
| Reset tiến độ rồi mở lại chi tiết | Hàng của generation cũ vẫn xem được, có tiêu đề nhóm riêng (BR-CARD-017) |
| Thẻ `sm2` có hàng lịch sử ghi dưới `eight_box` | Hàng đó hiện box trước→sau; hàng mới hiện ease/interval (BR-CARD-016) |
| Nội dung card rất dài (2000 ký tự) | Cuộn được trong vùng card, không tràn, không cắt mất |
