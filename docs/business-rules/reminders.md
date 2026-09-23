# Business rules — Nhắc học hằng ngày

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng REMINDER, dưới ID vĩnh viễn `BR-REMINDER-nnn` |
| **Scope** | Luật nhắc học hằng ngày (notification). |
| **Source of truth for** | BR-REMINDER-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2).

## Nhắc học hằng ngày

**Phạm vi:** sub-project sau — nhắc học hằng ngày (spec §2).

Một notification tóm tắt mỗi ngày, dựng từ workload đến hạn thật. Các
rule dưới đây **không** phát biểu lại định nghĩa "đến hạn" (BR-STUDY-001), cách tra root
(BR-DECK-002, BR-DECK-003), hay luật riêng tư chung (BR-PRIVACY-001…BR-PRIVACY-004) — chúng chỉ nói phần mà
chiều nhắc học thêm vào.

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-REMINDER-001 | active | Nhắc học MUST mặc định **tắt**. Ứng dụng MUST NOT xin quyền notification, MUST NOT đăng ký lịch nền và MUST NOT hiện notification nào cho tới khi người dùng chủ động bật. Bật là một hành động tường minh của người dùng, MUST NOT suy ra từ việc mở app, học xong một phiên hay cài lại app. | rule + UI | UC-REMINDER-001, BR-PRIVACY-004 |
| BR-REMINDER-002 | active | Giờ nhắc MUST lưu dưới dạng **phút trong ngày theo giờ địa phương**, miền hợp lệ `0…1439`, mặc định gợi ý `1200` (20:00). Giá trị ngoài miền MUST bị từ chối ở tầng nghiệp vụ bằng lý do có kiểu trước khi chạm database. Giờ nhắc MUST được diễn giải theo offset địa phương **tại thời điểm tính lịch**, MUST NOT quy đổi sang UTC rồi lưu — quy đổi lúc lưu làm giờ nhắc trôi đúng bằng lượng offset đổi khi người dùng qua múi giờ khác. | rule + db | UC-REMINDER-001, BR-STUDY-074 |
| BR-REMINDER-003 | active | Notification MUST chỉ được hiện khi tổng `overdue + due-today` > 0 **đo lại tại thời điểm fire**, không phải tại thời điểm đặt lịch. Thẻ chưa học xong chuỗi learning (`learned_at IS NULL`) MUST NOT được tính và MUST NOT tự mình làm phát notification. Đến giờ mà tổng bằng 0 thì MUST bỏ hẳn lượt nhắc đó và MUST NOT hiện notification rỗng hay notification "không có gì để học". | rule | UC-REMINDER-001, BR-STUDY-001, BR-STUDY-051 |
| BR-REMINDER-004 | active | MUST có nhiều nhất **một** notification tóm tắt cho mỗi ngày địa phương, và nó MUST thay thế notification của ngày trước nếu vẫn còn trên shade — dùng một notification id cố định. MUST NOT có notification riêng cho mỗi deck. | store | UC-REMINDER-001 |
| BR-REMINDER-005 | active | Nội dung notification MAY nêu **tên root deck cấp bách nhất**, **tổng số thẻ đến hạn** và **số deck còn lại**. Nội dung MUST NOT chứa mặt trước/sau của thẻ, ví dụ, gợi ý, phiên âm, tag, lịch sử ôn hay bất kỳ dữ liệu học nào của từng thẻ, kể cả trên lock screen. Log ở mọi level MUST NOT chứa nội dung thẻ, tên deck hay bản thân chuỗi copy; diagnostic chỉ MAY ghi lý do có kiểu và số đếm. | store + UI | UC-REMINDER-001, BR-STARTER-002, BR-PRIVACY-001, BR-PRIVACY-002 |
| BR-REMINDER-006 | active | "Cấp bách nhất" MUST là một thứ tự **toàn phần và tất định**: số thẻ overdue giảm dần, rồi tuổi overdue lớn nhất (số ranh giới ngày địa phương đã qua, BR-STUDY-067) giảm dần, rồi số thẻ due-today giảm dần, rồi tên deck tăng dần, rồi `deck.id` tăng dần. Không được có tie chưa phân giải: hai deck cùng mọi số liệu MUST xếp theo tên rồi id, không theo thứ tự database trả về. | rule | UC-REMINDER-001, BR-STUDY-067 |
| BR-REMINDER-007 | active | Tổng số thẻ đến hạn MUST gộp theo **root deck** qua `deck.root_id` (BR-DECK-003) và MUST đếm mỗi thẻ **đúng một lần**: một thẻ MUST NOT bị cộng thêm vì tổ tiên và hậu duệ của deck chứa nó cùng có mặt trong danh sách. `COALESCE(parent_id, id)` MUST NOT được dùng để tra root. | db + rule | UC-REMINDER-001, BR-DECK-002, BR-DECK-003, BR-REMINDER-003 |
| BR-REMINDER-008 | active | Chạm notification MUST mở Study Home theo đúng route contract của app và MUST NOT tự mở phiên học, tự chọn deck hay tự ghi gì. Vuốt bỏ notification MUST NOT thay đổi study state, không đánh dấu đã học, không dời lịch thẻ và không ghi history. | UI + rule | UC-REMINDER-001, BR-STUDY-004 |
| BR-REMINDER-009 | active | Đặt lịch MUST dùng cơ chế **không chính xác** (inexact) của hệ điều hành; ứng dụng MUST NOT khai báo hay xin quyền exact alarm. Lịch MUST được đặt lại khi: bật nhắc, đổi giờ nhắc, offset địa phương đổi, và — nếu nền tảng yêu cầu — sau reboot hoặc app update. Tắt nhắc MUST huỷ lịch đang có. | store | UC-REMINDER-001 |
| BR-REMINDER-010 | active | Đặt lịch MUST **idempotent**: chạy lại việc hoà giải lịch với cùng settings và cùng giờ địa phương MUST cho đúng một lịch đang chờ, MUST NOT xếp chồng thêm lượt và MUST NOT nhân đôi notification. | store | UC-REMINDER-001 |
| BR-REMINDER-011 | active | Trên nền tảng cần quyền notification (Android 13+), quyền MUST chỉ được xin **sau** khi người dùng chạm bật. Bị từ chối MUST là một trạng thái **có kiểu và khôi phục được**: settings MUST giữ nguyên **tắt**, lịch MUST NOT được đặt, UI MUST nói cách bật lại ở cài đặt hệ thống và MUST cho thử lại. Ứng dụng MUST NOT tự động xin lại quyền, MUST NOT lưu trạng thái "đã bật" khi bước bật chưa hoàn tất. | rule + UI | UC-REMINDER-001 |
| BR-REMINDER-012 | active | Nền tảng không hỗ trợ nhắc học MUST báo capability bằng một giá trị có kiểu và MUST NOT crash, MUST NOT im lặng coi như đã bật. UI MUST hiện trạng thái không khả dụng thay vì một toggle bật được nhưng không có tác dụng. Nghiệp vụ và UI MUST NOT import kiểu của plugin notification, MUST NOT kiểm tra nền tảng và MUST NOT chạm platform IO. | rule + store + UI | UC-REMINDER-001 |

BR-REMINDER-003 nói "đo lại tại thời điểm fire" chứ không phải "đo lúc đặt lịch": một
notification đã nạp sẵn nội dung từ hôm qua vẫn hiện đúng giờ ngay cả khi người
dùng đã học hết, và nó hiện **số của hôm qua**.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Đến giờ nhắc nhưng người dùng vừa học hết | Bỏ lượt nhắc, không hiện notification nào (BR-REMINDER-003) |
| Chỉ còn thẻ chưa học, không có thẻ đến hạn | Không nhắc — thẻ mới không làm phát notification (BR-REMINDER-003) |
| Bật nhắc rồi từ chối quyền Android 13+ | Settings vẫn tắt, không đặt lịch, UI chỉ đường bật lại và cho thử lại (BR-REMINDER-011) |
| Đổi múi giờ sau khi đã bật nhắc | Đặt lại lịch theo giờ địa phương mới; giờ nhắc hiển thị không đổi (BR-REMINDER-002, BR-REMINDER-009) |
| Mở app nhiều lần trong ngày khi đang bật nhắc | Hoà giải lịch idempotent — vẫn đúng một lượt chờ (BR-REMINDER-010) |
| Hai deck có số overdue và tuổi overdue bằng nhau | Xếp theo tên rồi `id`, không theo thứ tự database (BR-REMINDER-006) |
| Chạm notification | Mở Study Home, không tự mở phiên (BR-REMINDER-008) |
| Vuốt bỏ notification | Không đụng study state, không ghi history (BR-REMINDER-008) |
| Chạy trên Web | Capability báo không hỗ trợ; không có toggle bật được mà vô tác dụng (BR-REMINDER-012) |
