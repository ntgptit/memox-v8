# Business rules — StudyMode

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng MODE, dưới ID vĩnh viễn `BR-MODE-nnn` |
| **Scope** | Luật StudyMode: tập mode, chuỗi stage, và chiều hỏi của `self_assess`. |
| **Source of truth for** | BR-MODE-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |


| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-MODE-001 | superseded by BR-MODE-002 | StudyMode MUST là một trong năm: `review`, `match`, `guess`, `recall`, `fill`. | rule | UC-STUDY-001, BR-STUDY-009 |
| BR-MODE-002 | active | StudyMode MUST là một trong sáu: `browse`, `self_assess`, `match`, `guess`, `recall`, `fill`. | rule | UC-STUDY-001, BR-STUDY-009 |
| BR-MODE-003 | active | Phiên **học mới** MUST chạy một **chuỗi stage** theo thứ tự cố định do thuật toán khai báo; người dùng MUST NOT chọn stage. Phiên **ôn tập** MUST chạy đúng **một** mode do người dùng chọn (BR-STUDY-055). | rule | BR-MODE-004, BR-STUDY-051, UC-STUDY-001 |
| BR-MODE-004 | active | Chuỗi stage của phiên học mới MUST là: `eight_box` → `browse`, `match`, `guess`, `recall`, `fill`; `sm2` → `browse`, `self_assess`. | rule | BR-MODE-007, BR-MODE-003 |
| BR-MODE-005 | active | `browse` MUST NOT sinh `action`, MUST NOT ghi `review_log` và MUST NOT đổi lịch. Nó chỉ ghi tiến độ stage để Resume quay đúng chỗ. | rule | BR-MODE-011, BR-MODE-006 |
| BR-MODE-006 | active | `browse` MUST hiển thị mặt trước và mặt sau **cùng lúc**, không có bước lật. `self_assess` MUST hiện mặt trước trước, và chỉ hiện mặt sau cùng tập action sau khi người dùng lật. | UI | BR-MODE-002, UC-STUDY-001 |
| BR-MODE-007 | active | Chuỗi stage MUST do **thuật toán SRS của root deck** khai báo qua `stageSequence` (BR-MODE-004). MUST NOT hardcode ở UI. | rule | BR-STUDY-009, BR-MODE-004 |
| BR-MODE-008 | active | Stage đang chạy MUST được lưu tường minh trên `study_session.current_mode`, và mode của từng lượt trên `review_log.mode`. MUST NOT suy luận từ hình dạng dữ liệu. | db | BR-SRS-015, BR-MODE-003 |
| BR-MODE-009 | active | Trong phiên `learning`, một stage MUST chạy chỉ khi nằm trong `stageSequence` **và** có ít nhất một thẻ đủ dữ liệu; stage không còn thẻ nào MUST bị bỏ qua thay vì hiện rỗng. Trong phiên `reviewing`, không có stage nào để bỏ qua vì người dùng đã chọn: mode không đủ dữ liệu MUST bị **vô hiệu hoá ngay trên màn chọn**, kèm lý do. | rule + UI | BR-MODE-007, BR-STUDY-071, BR-STUDY-055, UC-STUDY-001 |
| BR-MODE-010 | active | Mode bị chặn vì thuật toán MUST được trình bày là không khả dụng cho deck này, và MUST NOT gợi ý Reset learning progress như cách mở khoá. | UI | BR-SRS-003, BR-SRS-021 |
| BR-MODE-011 | active | Mọi mode **trừ `browse`** MUST sinh một `action` thuộc `supportedActions` của thuật toán. `self_assess` MUST lấy action **trực tiếp từ người dùng**; `match`/`guess`/`recall`/`fill` MUST chấm ra kết quả nhị phân rồi ánh xạ theo BR-MODE-012. | rule | BR-SRS-008, BR-STUDY-009, BR-MODE-005 |
| BR-MODE-012 | active | Với `eight_box`, kết quả nhị phân MUST ánh xạ: sai → `forgotten`, đúng → `remembered`. Hết giờ ở `recall` MUST tính là sai. | rule | BR-SRS-008, BR-MODE-002 |

**Vì sao tập mode thuộc thuật toán chứ không thuộc deck.** Bốn mode chấm điểm
sinh tín hiệu **nhị phân** — đúng hoặc sai. `eight_box` nhận đúng hai
action (`forgotten`/`remembered`) nên ánh xạ là một-một. `sm2` cần bốn mức, và
một nguồn nhị phân chỉ nuôi được hai trong bốn; ease factor sẽ trôi hẹp dần theo
BR-SRS-012 mà không có gì báo. Nên `sm2` giữ đúng `self_assess`, và điều đó là **thuộc tính
của thuật toán**, không phải một hạn chế tạm thời của UI.

Hệ quả trực tiếp: `stageSequence` đứng cạnh `supportedActions` trên cùng
abstraction, vì cả hai trả lời cùng một câu hỏi — "thuật toán này cho phép người
dùng làm gì". BR-STUDY-009 đã cấm hardcode tập action; BR-MODE-007 là đúng câu đó cho tập mode.

BR-MODE-010 tồn tại vì lối thoát duy nhất là có thật nhưng không được phép đề nghị:
thuật toán khoá khi thẻ đầu tiên học xong chuỗi học mới (BR-SRS-003) và chỉ Reset mới mở, mà
Reset xoá toàn bộ tiến độ học. Một dòng copy gợi ý điều đó đang đề nghị người
dùng đánh đổi thứ họ không định đánh đổi.

**BR-MODE-011 gỡ một mâu thuẫn nghe rất hợp lý.** `self_assess` thường được mô tả là "không
có đúng/sai" — đúng, theo nghĩa **không có máy chấm**: người học tự đánh giá. Nhưng
nó vẫn sinh ra `forgotten`/`remembered`, và nếu đọc thành "không sinh action" thì
**không mode nào cập nhật lịch** và toàn bộ SRS biến mất cùng M3 của `product.md`.

Khác biệt thật giữa các mode vì thế nằm gọn ở **nguồn** của action, không phải ở
việc có hay không có action — và đó cũng chính là toàn bộ phần mỗi handler phải
tự viết. `self_assess` không còn là ngoại lệ của luồng chung; nó là mode mà
`evaluate` trả về đúng cái người dùng vừa bấm.

**Không còn mục nào để trống.** Câu cuối cùng — lượt nào trong chuỗi stage đổi
lịch — được BR-STUDY-023 trả lời, và câu trả lời đã nằm sẵn trong cơ chế round.

**Vì sao BR-SRS-016 vẫn đúng dù nó được viết cho một phiên một cách hỏi.** BR-STUDY-069 bắt
mỗi stage lặp cho tới khi một round không còn thẻ sai, nên **lượt cuối của mọi
stage luôn là một lần đúng** — nó không mang tín hiệu nào về trí nhớ, chỉ nói rằng
vòng lặp đã kết thúc. Thứ duy nhất cho biết người học có thực sự nhớ hay không là
**lần thử đầu tiên**, khi chưa có stage nào nhắc bài. Lấy kết quả cuối chuỗi sẽ
cho mọi thẻ đều "nhớ được", và SRS mất sạch tín hiệu.

Ngưỡng riêng theo stage đã đóng ở BR-STUDY-024: không có. Năm stage chạy trên **một**
tập thẻ của phiên, và BR-STUDY-025 tách bạch điều đó với điều kiện dựng được nội dung —
`guess` cần năm nghĩa khác nhau, `fill` cần thẻ có `example`. Hai thứ đó quyết
định stage **có chạy hay bị bỏ qua**, không quyết định lấy bao nhiêu thẻ.
Không đoán ở đây — mỗi câu trả lời khác nhau cho ra một thiết kế khác nhau.

Hai mục từng nằm trong danh sách này đã đóng: `guess` so "khác nghĩa" bằng
`back_folded` (BR-STUDY-039), và ngưỡng của chính `guess` là **năm nghĩa khác nhau
trong tập thẻ của phiên** (BR-STUDY-037, BR-STUDY-040). Ngưỡng đó khác `match` và `recall` ở
một điểm đáng chú ý: nó là điều kiện của **cả stage**, không phải của từng thẻ,
vì một question mượn bốn thẻ khác để dựng.

---

## Chiều hỏi của `self_assess` — reverse recall

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-MODE-013 | active | Việc chọn **chiều hỏi** MUST chỉ khả dụng khi cả ba điều kiện cùng đúng: phiên `reviewing` (BR-STUDY-051), scheduler của root deck là `sm2` (BR-DECK-025), và mode là `self_assess` (BR-STUDY-055). Mọi tổ hợp khác — `eight_box` ở bất kỳ mode nào, chuỗi học mới (BR-MODE-003), `match`/`guess`/`recall`/`fill` — MUST NOT nhận chiều hỏi: MUST NOT hiện UI chọn chiều, MUST NOT nhận giá trị chiều khi mở phiên, và MUST NOT ghi chiều xuống bất kỳ bảng nào. Điều kiện này MUST là **một predicate duy nhất trong tầng nghiệp vụ**, MUST NOT viết lại ở UI. | rule + UI | BR-MODE-011, BR-MODE-003, BR-MODE-004, BR-STUDY-051, BR-STUDY-055, UC-STUDY-003 |
| BR-MODE-014 | active | Chiều của **một lượt** MUST là một trong hai: `korean_to_meaning` hiển thị `front` làm đề và `back` làm đáp án; `meaning_to_korean` hiển thị `back` làm đề và `front` làm đáp án. Đề MUST luôn nằm ở nửa trên của thẻ và đáp án ở nửa dưới (BR-MODE-006) — chiều đổi **nội dung** của hai nửa, MUST NOT đổi vị trí, thứ tự đọc, hay hình học của thẻ. Nhãn của mỗi nửa MUST đi theo nội dung nửa đó. Chiều MUST NOT là dấu hiệu chỉ bằng màu. | rule + UI | BR-CARD-002, BR-MODE-006, BR-MODE-013 |
| BR-MODE-015 | active | Lựa chọn ở mức **phiên** MUST là một trong ba: `korean_to_meaning`, `meaning_to_korean`, `mixed`. Với `mixed`, chiều thật của từng thẻ MUST được gán **đúng một lần**, tại thời điểm materialize hàng đợi, bằng nguồn ngẫu nhiên **được tiêm**, và MUST lưu trên từng dòng `study_queue_items`. Số thẻ hai chiều MUST lệch nhau **không quá một**. Chiều đã gán MUST giữ nguyên qua comeback (BR-STUDY-005), retry, Resume (BR-STUDY-072) và restart tiến trình; MUST NOT gieo lại từ seed hay tính lại lúc render. Giá trị `mixed` MUST NOT xuất hiện trên một dòng hàng đợi hay một dòng lịch sử. | db + rule | BR-STUDY-005, BR-STUDY-021, BR-STUDY-072, BR-STUDY-043, BR-MODE-013 |
| BR-MODE-016 | active | Chiều của phiên, chiều thật của từng dòng hàng đợi và chiều của từng lượt trong `review_log` MUST được lưu **tường minh**. MUST NOT suy luận từ nội dung thẻ, từ thứ tự widget, hay từ lựa chọn của phiên. Chiều ghi vào lịch sử MUST **chép từ dòng hàng đợi** trong cùng transaction ghi lượt, MUST NOT nhận từ tham số do UI truyền xuống. | db | BR-SRS-015, BR-MODE-008, BR-STUDY-034, BR-MODE-015 |
| BR-MODE-017 | active | Chiều MUST được chốt trước lượt đầu tiên và **khoá** trong suốt phiên: MUST NOT đổi sau khi phiên đã mở. Resume MUST đọc chiều đã lưu và MUST NOT hỏi lại. Thoát trước khi hàng đợi được tạo MUST NOT ghi session (BR-STUDY-020), nên MUST NOT để lại chiều nào. | rule + UI | BR-SRS-025, BR-STUDY-020, BR-STUDY-072, BR-STUDY-024 |
| BR-MODE-018 | active | Yêu cầu mở phiên **đủ điều kiện** mà thiếu chiều MUST bị từ chối là lỗi validation, và MUST NOT ghi session. Yêu cầu **không đủ điều kiện** mà kèm chiều MUST bị từ chối là conflict, và MUST NOT ghi session. Cả hai kiểm tra MUST chạy trước mọi ghi. | rule | BR-STUDY-020, BR-STUDY-054, BR-MODE-013 |
| BR-MODE-019 | active | Chiều hỏi MUST NOT đổi tập action của scheduler (BR-STUDY-009), ánh xạ chất lượng (BR-SRS-010), `ease_factor`, `interval_days`, `repetitions`, `due_at`, hay `current_box`. Cùng một thẻ với cùng một action MUST cho ra cùng một lịch bất kể chiều. Chiều MUST NOT ghi hay sửa nội dung thẻ (`front`, `back`, cột folded) và MUST NOT chạm `card.updated_at`. | rule + store | BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-STUDY-009, BR-SRS-021 |

**Vì sao chỉ `sm2` × `reviewing` × `self_assess`.** `self_assess` là mode duy
nhất mà đổi chiều chỉ đổi **mặt nào là đề** và không đổi thứ được chấm. Bốn mode
còn lại dựng nội dung từ một mặt cố định: `fill` chấm bằng `front_folded`
(BR-STUDY-026), `guess` phân biệt nghĩa bằng `back_folded` (BR-STUDY-039), `match` ghép hai
mặt với nhau. Đảo chúng là đổi **cái được chấm**, không phải đổi cách hỏi.
`eight_box` không chạy `self_assess` trong phiên ôn (BR-MODE-004, BR-STUDY-055) nên không có
bề mặt nào để đảo. Phiên học mới đi theo chuỗi stage cố định người dùng không
chọn (BR-MODE-003), và bắt người học tạo ra một từ họ chưa từng thấy không phải là câu
hỏi khó hơn — nó là câu hỏi không trả lời được.

**Vì sao `mixed` lưu chứ không gieo.** Một chiều quyết định lúc render là một câu
hỏi khác ở mỗi lần rebuild — khoá nút trong lúc ghi cũng đủ để rebuild — nên thẻ
sẽ đổi từ "tạo ra" sang "nhận ra" ngay dưới mắt người học. BR-STUDY-043 đã chốt đúng
hình dạng này cho thứ tự option của `guess` và bàn của `match`: **thế bài quyết
định khi hàng đợi được ghi, không phải khi nó được vẽ.** Chỉ khác một điểm, và
điểm đó là lý do phải là *cột* chứ không phải *seed*: `self_assess` đưa thẻ quên
quay lại trong **chính dòng cũ** sau ba thẻ khác (BR-STUDY-005), và BR-STUDY-072 mang cả phiên
trở lại sau khi hệ điều hành thu hồi app. Một seed sống sót qua rebuild nhưng
không sống sót qua một lần đổi công thức seed; một cột sống sót cả hai.

**Vì sao chia đều chứ không tung đồng xu từng thẻ.** Hai mươi lần tung độc lập
cho ra 14–6 hoặc tệ hơn khoảng một lần trong mười sáu. Người học chọn "trộn" mà
nhận mười bốn thẻ cùng một chiều đã nhận một thứ khác. Hợp đồng `|a − b| ≤ 1` là
thứ test khẳng định được mà không cần ghim seed; một phân phối thì không.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Mở phiên `self_assess` trên deck `sm2` nhưng chưa chọn chiều | Từ chối là validation, không ghi session (BR-MODE-018) |
| Deck `eight_box` nhận yêu cầu kèm chiều hỏi | Từ chối là conflict; không có UI nào tạo được yêu cầu đó (BR-MODE-013, BR-MODE-018) |
| Phiên `mixed` có số thẻ lẻ | Lệch tối đa một thẻ; bên nhận thẻ lẻ rút ngẫu nhiên (BR-MODE-015) |
| DB cũ có lượt `self_assess` của deck `sm2` | Backfill `korean_to_meaning` — đó là chiều mà mọi bản trước đã chạy (BR-MODE-016) |
| Đọc dòng có chiều do bản mới hơn ghi | Đọc được, vẽ như `korean_to_meaning`, MUST NOT ghi lại giá trị đó (BR-MODE-014) |
