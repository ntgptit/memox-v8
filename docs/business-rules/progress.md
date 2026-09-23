# Business rules — Progress

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng PROGRESS, dưới ID vĩnh viễn `BR-PROGRESS-nnn` |
| **Scope** | Luật đọc tiến độ theo deck và Progress overview (read-only). |
| **Source of truth for** | BR-PROGRESS-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Tiến độ theo deck

Drill-down hoạt động học theo cây deck (UC-PROGRESS-002). Các rule dưới đây **không** phát
biểu lại định nghĩa ngày địa phương (BR-STUDY-074), quan hệ cha–con và `root_id`
(BR-DECK-001…BR-DECK-003), tính append-only của `review_log` (BR-SRS-023) hay luật riêng tư
chung (BR-PRIVACY-001…BR-PRIVACY-004) — chúng chỉ nói phần mà chiều đọc tiến độ thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-PROGRESS-001 | active | Progress by Deck v1 MUST chỉ báo cáo đúng bốn số cho mỗi phạm vi: **unique active cards**, **active days**, **Learning card-days** và **Reviewing card-days** (BR-PROGRESS-002, BR-PROGRESS-005). v1 MUST NOT báo cáo accuracy, điểm số, streak dài nhất, dự báo due, so sánh giữa hai khoảng, hay bất kỳ số dẫn xuất nào khác — mỗi số đó cần một định nghĩa riêng phải chốt trước, và một màn hình chứa năm số nửa-đồng-thuận thì không số nào đáng tin. Màn hình MUST là read-only (BR-PROGRESS-007). | rule | UC-PROGRESS-002, BR-PROGRESS-002, BR-PROGRESS-005, BR-PROGRESS-007 |
| BR-PROGRESS-002 | active | Đơn vị đếm MUST là **card-day**: một cặp phân biệt `(card, ngày địa phương)` theo đúng định nghĩa ngày của BR-STUDY-074, MUST NOT là số lượt trả lời. Trả lời cùng một thẻ sáu lần trong một buổi tối MUST đếm là **một** card-day. `unique active cards` MUST là số card phân biệt có ít nhất một lượt trong khoảng; `active days` MUST là số ngày địa phương phân biệt có ít nhất một lượt trong khoảng. Hai số này đo hai thứ khác nhau và MUST NOT cộng vào nhau. `active days` MUST NOT được tính bằng cách cộng các deck con: cùng một ngày xuất hiện ở hai deck vẫn là một ngày học, nên mọi tổng MUST đọc trực tiếp từ cùng một câu lệnh chứ không fold từ các hàng. | rule + store | UC-PROGRESS-002, BR-STUDY-074 |
| BR-PROGRESS-003 | active | v1 MUST có đúng hai khoảng — **7 ngày** và **30 ngày** — và MUST NOT có khoảng thứ ba hay date picker tự do. Mỗi khoảng MUST gồm trọn các ngày địa phương **kết thúc bằng hôm nay**: 7 ngày là hôm nay cộng sáu ngày trước đó. Biên MUST dẫn xuất từ `clockProvider` và offset múi giờ do composition root cấp, MUST NOT đọc đồng hồ hay múi giờ trong SQL hay trong tầng nghiệp vụ. Hai khoảng MUST đến từ **một** lần đọc, nên đổi khoảng trên màn hình MUST NOT mở lại query và MUST NOT hiện trạng thái loading. Snapshot MUST mang theo thời điểm nó hết hạn — nửa đêm địa phương kế tiếp — vì mọi số của nó đổi tại đó mà không có write nào trong database. | rule + store | UC-PROGRESS-002, BR-STUDY-074 |
| BR-PROGRESS-004 | active | Lịch sử MUST được quy cho **vị trí hiện tại của thẻ**: đường đi `review_log → card → deck`. Chuyển một thẻ hoặc một subtree sang deck khác MUST làm **toàn bộ** lịch sử của thẻ xuất hiện dưới deck và root mới, không chỉ các lượt sau khi chuyển. `review_log` MUST NOT nhận thêm cột deck lịch sử và hệ thống MUST NOT thêm bảng analytics riêng để né rule này; hệ quả được chấp nhận là "tháng Ba deck này trông thế nào" không trả lời được và không thuộc v1. Tổng của một deck MUST gồm thẻ trực tiếp của nó và mọi descendant theo cây thật — root resolve qua `root_id`, cấp trung gian resolve bằng recursive walk, MUST NOT dùng `COALESCE(parent_id, id)` (BR-DECK-003). Deck đã xoá MUST biến mất khỏi mọi số, và điều đó MUST đến từ cascade của schema chứ không từ một predicate lọc; khi một cơ chế Trash tồn tại thì deck trong Trash và mọi descendant của nó MUST bị loại theo cùng cách, restore MUST làm activity xuất hiện lại theo vị trí hiện tại của thẻ, và purge vĩnh viễn MUST loại nó vĩnh viễn. | store | UC-PROGRESS-002, BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-018 |
| BR-PROGRESS-005 | active | Learning và Reviewing MUST là một phân hoạch **loại trừ và vét cạn** của card-days: mỗi card-day MUST thuộc đúng một nửa, nên `Learning + Reviewing` MUST bằng tổng card-days. Ưu tiên thuộc về Learning: một ngày có ít nhất một lượt `kind = 'learning'` MUST là Learning day dù ngày đó còn lượt nào khác; mọi ngày còn lại — `scheduled` và `relearning` — MUST là Reviewing day. Phân loại MUST đọc cột `kind` đã lưu (BR-SRS-015), MUST NOT suy ra bằng cách so sánh trạng thái trước/sau. | rule + store | UC-PROGRESS-002, BR-SRS-015, BR-STUDY-051 |
| BR-PROGRESS-006 | active | Danh sách deck MUST sắp theo `unique active cards` **giảm dần của khoảng đang chọn**, tie-break bằng tên đã fold rồi tới id, để thứ tự ổn định qua mọi lần đọc. Fold MUST làm trong Dart bằng `toLowerCase()` Unicode, MUST NOT dùng `lower()` của SQLite (chỉ fold ASCII, nên `Động` và `động` tách nhau trong khi `Verbs` và `verbs` gộp). Deck không có hoạt động MUST vẫn hiển thị và MUST đứng cuối — ẩn chúng đi là trả lời câu hỏi "mình đã bỏ bê deck nào" bằng cách xoá chính câu trả lời. | rule | UC-PROGRESS-002, BR-TAG-001 |
| BR-PROGRESS-007 | active | Đọc tiến độ MUST là thao tác chỉ-đọc: mở, rời hay đổi khoảng trên màn hình MUST NOT ghi hay chạm tới nội dung card, timestamp, `content_type`, study state, review history, session hay quan hệ tag; MUST NOT mở hay đóng session nào. Một lần đọc thất bại vì thế MUST NOT làm hỏng dữ liệu, và copy lỗi MUST NOT gợi ý ngược lại. | store + UI | UC-PROGRESS-002, BR-TRANSFER-011 |
| BR-PROGRESS-008 | active | Màn hình MUST cập nhật trực tiếp: ghi một lượt trả lời, chuyển thẻ hoặc subtree, xoá deck, và nửa đêm địa phương đi qua MUST đều làm số trên màn hình đổi mà người dùng không phải thao tác gì. Ba sự kiện đầu MUST đến từ stream invalidation của các bảng liên quan; sự kiện thứ tư không có write nào trong database nên MUST đến từ một lần hẹn giờ duy nhất, đặt theo thời điểm hết hạn mà chính snapshot mang theo (BR-PROGRESS-003). | store + UI | UC-PROGRESS-002, BR-PROGRESS-003 |

---

## Progress overview

Progress đọc `review_log` (BR-SRS-016) và **không** ghi gì. Các rule dưới đây chỉ
nói phần mà việc *đọc lại lịch sử* thêm vào; chúng không phát biểu lại luật ghi
lượt (BR-SRS-015, BR-SRS-016, BR-MODE-005), luật reset (BR-SRS-021…BR-SRS-027) hay luật ngày học
(BR-STUDY-074).

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-PROGRESS-009 | active | Progress MUST là read-only tuyệt đối: mở màn, đóng màn, Retry, đổi tab hay quay lại MUST NOT ghi hay sửa bất kỳ hàng nào — không `study_session`, không `card_schedule`, không `review_log`, không `app_settings` — và MUST NOT mở, tiếp tục hay đóng session nào. | store + UI | UC-PROGRESS-001, BR-TRANSFER-011 |
| BR-PROGRESS-010 | active | v1 của Progress MUST NOT hiển thị: accuracy hay correct rate, longest streak, mục tiêu/goal, XP hay điểm, heatmap, bộ lọc theo deck, chia sẻ, và hiệu ứng ăn mừng. Các chỉ số này cần định nghĩa nghiệp vụ riêng chưa được chốt; hiển thị một con số chưa có BR đứng sau là viết spec ở tầng sai. | UI | UC-PROGRESS-001 |
| BR-PROGRESS-011 | active | Đơn vị hoạt động của Progress là một cặp **distinct `(localDay, cardId)`**, gọi là một *card-day*. Nhiều answer, nhiều stage, nhiều round hay nhiều session của **cùng một card trong cùng một local day** MUST đếm đúng **một**. Progress MUST NOT đếm số hàng `review_log`, số session hay số lượt. Một card được trả lời trong hai local day khác nhau MUST đếm hai. `localDay` của **mọi** hàng — kể cả hàng ghi từ nhiều tháng trước — MUST được tính bằng UTC offset của **lần đọc hiện tại**, vì `review_log` không lưu offset theo hàng. Hệ quả đã biết và chấp nhận cho v1: đổi múi giờ hoặc qua một mốc DST làm các ngày quá khứ được phân bucket lại, nên một chuỗi có thể dài ra hoặc đứt hồi tố. | store (SQL) | UC-PROGRESS-001, BR-SRS-016, BR-STUDY-074 |
| BR-PROGRESS-012 | active | Stage `browse` không ghi hàng `review_log` nào (BR-MODE-005), nên nó MUST NOT tạo card-day, MUST NOT làm một ngày trở thành active và MUST NOT giữ streak. Mở một phiên rồi chỉ lướt `browse` và thoát MUST để Progress y nguyên. | store (SQL) | UC-PROGRESS-001, BR-MODE-005 |
| BR-PROGRESS-013 | active | "Hôm nay" của Progress là nửa khoảng `[startOfToday, startOfTomorrow)` theo đúng ranh giới ngày học cục bộ của BR-STUDY-074, dựng từ **một** snapshot của `clockProvider` và `utcOffsetProvider`. Mọi con số của một lần hiển thị — Today, Last 7 days, streak — MUST đến từ cùng snapshot đó; MUST NOT có hai lần đọc đồng hồ trong một emission, và SQL MUST NOT tự dẫn xuất local midnight. | store | UC-PROGRESS-001, BR-STUDY-074 |
| BR-PROGRESS-014 | active | Phân rã của một ngày là một **partition loại trừ nhau**: một card-day là **Learning** khi có ít nhất một answer `kind = 'learning'` trong ngày đó; nếu không, và chỉ khi đó, nó là **Reviewing** khi có answer `scheduled` hoặc `relearning`. `learning + reviewing = total` MUST luôn đúng cho mọi ngày. Một card vừa `learning` vừa `scheduled` trong cùng ngày MUST đếm là Learning và MUST NOT đếm hai lần. | store (SQL) | UC-PROGRESS-001, BR-SRS-015, BR-PROGRESS-011 |
| BR-PROGRESS-015 | active | "Last 7 days" gồm **hôm nay và sáu ngày trước đó**, đúng bảy phần tử, thứ tự **cũ → mới**. Ngày không có card-day nào MUST xuất hiện với giá trị 0 (zero-fill), MUST NOT bị bỏ khỏi dãy và MUST NOT làm dãy ngắn lại. Dãy MUST đúng khi cửa sổ bắc qua ranh giới tháng, ranh giới năm và ở mọi UTC offset. | store | UC-PROGRESS-001, BR-PROGRESS-011, BR-PROGRESS-013 |
| BR-PROGRESS-016 | active | Current streak là số local day liên tiếp có hoạt động, tính lùi từ **anchor**: nếu hôm nay active thì anchor là hôm nay; nếu hôm nay chưa active nhưng hôm qua active thì anchor là hôm qua và chuỗi MUST được giữ nguyên (không reset về 0 chỉ vì hôm nay chưa học); nếu cả hai đều không active thì streak là 0. Streak MUST NOT có trần và MUST NOT bị cắt bởi cửa sổ bảy ngày của BR-PROGRESS-015. | store | UC-PROGRESS-001, BR-PROGRESS-011, BR-PROGRESS-013 |
| BR-PROGRESS-017 | active | Reset learning progress giữ `review_history`/`review_log` (BR-SRS-023), nên nó MUST NOT làm thay đổi bất kỳ con số nào của Progress. Ngược lại, card đã bị xoá cứng — trực tiếp, hay theo cascade từ deck bị xoá — MUST NOT còn xuất hiện trong Progress, kể cả trong các ngày quá khứ, vì hàng `review_log` của nó bị cascade xoá theo. v1 MUST NOT tạo tombstone, bảng bóng hay bản sao analytics để giữ lại hoạt động của card đã xoá. | db (schema cascade) | UC-PROGRESS-001, BR-SRS-021, BR-SRS-023 |
| BR-PROGRESS-018 | active | Màn Progress MUST tự cập nhật khi lịch sử đổi (một answer mới ghi vào, một card hay deck bị xoá) và tại **local midnight**, không cần thao tác của người dùng. Bộ hẹn giờ midnight MUST là one-shot đặt theo `startOfTomorrow` của emission hiện tại, MUST bị huỷ khi controller dispose hoặc rebuild, MUST NOT lặp vô hạn khi ranh giới đã ở quá khứ tại lúc emission tới, và MUST resolve lại UTC offset ở **mỗi** lần đọc lại — resume, midnight hoặc Retry — chứ MUST NOT giữ offset mà màn hình mở lần đầu. Live refresh và midnight rollover MUST là chuyển tiếp giữa hai trạng thái loaded: khi đã có dữ liệu trên màn, cả hai MUST NOT hạ màn về loading. | UI | UC-PROGRESS-001, BR-PROGRESS-013 |

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Trả lời cùng một thẻ sáu lần trong một buổi tối | Một card-day, một active day (BR-PROGRESS-002) |
| Học hai deck khác nhau trong cùng một ngày | Mỗi deck một active day; tổng của cấp trên vẫn là một (BR-PROGRESS-002) |
| Chuyển thẻ sang root khác sau khi đã học | Toàn bộ lịch sử của thẻ chuyển theo; deck cũ về 0 (BR-PROGRESS-004) |
| Xoá deck đang có hoạt động | Cascade xoá card rồi answers; số về 0, không phải bị lọc (BR-PROGRESS-004) |
| Mở màn hình tiến độ lúc 23:59 rồi để yên | Nửa đêm địa phương, cửa sổ trượt một ngày và màn hình tự đọc lại (BR-PROGRESS-013, BR-PROGRESS-018) |
| Một ngày có cả lượt `learning` và lượt `scheduled` trên cùng thẻ | Là Learning day (BR-PROGRESS-005) |
| Năm mươi deck cùng 0 hoạt động | Vẫn hiện, đứng cuối, thứ tự không đổi giữa hai lần đọc (BR-PROGRESS-006) |
