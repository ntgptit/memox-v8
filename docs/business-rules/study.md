# Business rules — Study session

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng STUDY, dưới ID vĩnh viễn `BR-STUDY-nnn` |
| **Scope** | Luật phiên ôn tập: vòng đời session, hàng đợi, round, các mode chấm điểm (V8.0). Ngoài phạm vi: luật riêng của từng scheduler (`srs.md`), StudyMode (`study-mode.md`) |
| **Source of truth for** | BR-STUDY-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Phiên ôn tập

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-STUDY-001 | superseded by BR-STUDY-051 | Một phiên MUST chỉ lấy card có `due_at IS NULL OR due_at <= now`. | db | UC-STUDY-001, UC-DECK-003 |
| BR-STUDY-002 | active | Trong một phiên **ôn tập**, thứ tự MUST theo `due_at` tăng dần. Trong phiên **học mới**, thứ tự MUST theo tùy chọn `new_card_order` (BR-STUDY-057). Hai loại phiên MUST NOT trộn thẻ của nhau. | db | UC-STUDY-001, BR-STUDY-051 |
| BR-STUDY-003 | active | Một phiên MUST giới hạn số **thẻ riêng biệt** theo `study_session.card_limit`, mặc định **20**, áp cho **cả hai loại phiên**. Đây là trần **mỗi lần lấy**, MUST NOT được hiểu là hạn mức ngày: số phiên trong một ngày không giới hạn. | store | UC-STUDY-001, BR-STUDY-024 |
| BR-STUDY-004 | active | Đánh giá MUST được ghi ngay khi người dùng bấm, không chờ hết phiên. | store | UC-STUDY-001 |
| BR-STUDY-005 | active | **Chỉ áp cho mode `self_assess`, ở mọi loại phiên.** Card đánh giá `forgotten`/`again` MUST quay lại trong cùng hàng đợi, sau ít nhất 3 card khác, hoặc cuối hàng đợi nếu không đủ 3. `self_assess` MUST NOT dùng round. | store | UC-STUDY-001, BR-STUDY-073, BR-STUDY-059 |
| BR-STUDY-006 | active | Chỉ lượt `scheduled` MAY thay đổi lịch dài hạn, và nó chỉ tồn tại trong phiên `reviewing`. Trong phiên `learning`, mọi lượt là `learning` hoặc `relearning` và không đổi lịch. Chi tiết ở BR-SRS-014…BR-SRS-017, BR-STUDY-023, BR-STUDY-051, BR-STUDY-052, BR-STUDY-053. | rule | UC-STUDY-001 |
| BR-STUDY-007 | active | Ở stage có chấm điểm, card MUST rời hàng đợi khi được đánh giá bằng action khác `forgotten`/`again`. `browse` không sinh action (BR-MODE-005), nên thẻ rời hàng đợi của nó ngay khi đã được hiển thị và người dùng chuyển tiếp. | rule | UC-STUDY-001, BR-MODE-005 |
| BR-STUDY-008 | active | Không có thẻ nào đến hạn MUST được trình bày là trạng thái bình thường, không phải lỗi — và MUST NOT có đường nào mở phiên ôn tập khi tập đến hạn rỗng (BR-STUDY-054). | UI | UC-STUDY-001, UC-DECK-003, BR-STUDY-054 |
| BR-STUDY-009 | active | UI MUST render nút đánh giá từ `supportedActions`, và chuỗi stage từ `stageSequence`, của scheduler thuộc root deck; MUST NOT hardcode tập nào trong hai. | UI | UC-STUDY-001, BR-MODE-007 |

---

## Vòng đời study session

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-STUDY-010 | active | `study_session.status` MUST có đúng năm giá trị: `in_progress`, `completed`, `abandoned`, `invalidated`, `failed`. | db + invariant Q12 | UC-STUDY-001 |
| BR-STUDY-011 | superseded by BR-STUDY-012 | `study_session.end_reason` MUST có năm giá trị: `user_exit`, `scheduler_reset`, `stale_generation`, `persistence_error`, `interrupted`; NULL khi kết thúc bình thường hoặc chưa kết thúc. | db + invariant Q12 | UC-STUDY-001 |
| BR-STUDY-012 | active | `study_session.end_reason` MUST có đúng bảy giá trị: `user_exit`, `interrupted`, `scheduler_reset`, `scheduler_changed`, `stale_generation`, `persistence_error`, `content_deleted`; NULL khi chưa kết thúc hoặc kết thúc bình thường. | db + invariant Q12 | UC-STUDY-001, BR-STUDY-072, BR-STUDY-016, BR-TRASH-004 |
| BR-STUDY-013 | active | Hoàn thành toàn bộ queue MUST cho `completed`, `end_reason` NULL. | store | UC-STUDY-001 |
| BR-STUDY-014 | active | Người dùng chủ động thoát MUST cho `abandoned`, `end_reason = user_exit`. | store | UC-STUDY-001 |
| BR-STUDY-015 | active | Reset xảy ra khi session đang mở MUST cho `invalidated`, `end_reason = scheduler_reset`. | store | UC-SRS-001 |
| BR-STUDY-016 | active | Đổi scheduler khi chưa khoá (BR-SRS-002) xảy ra lúc session đang mở MUST cho session đó `invalidated`, trong **cùng** transaction đổi scheduler. MUST NOT dùng `user_exit` — người dùng không thoát phiên — và MUST NOT để phiên cũ chạy tiếp: hàng đợi của nó được chia theo thuật toán cũ, còn generation không đổi nên chốt chặn BR-STUDY-017 sẽ cho mọi lượt của nó đi qua. MUST NOT bắt người dùng chạy thêm một Reset thủ công để dọn. | store | BR-SRS-002, BR-SRS-004, BR-STUDY-015, UC-DECK-002 |
| BR-STUDY-017 | active | Session thuộc generation cũ cố ghi lượt học MUST bị từ chối ghi, và MUST chuyển `invalidated`, `end_reason = stale_generation`. | store | UC-STUDY-001 |
| BR-STUDY-018 | active | Lỗi không thể tiếp tục MUST cho `failed`, `end_reason = persistence_error`. | store | UC-STUDY-001 |
| BR-STUDY-019 | active | Các lượt học đã ghi thành công trước khi session kết thúc bất thường MUST được giữ, ở mọi trạng thái kết thúc. | store | UC-STUDY-001 |

BR-STUDY-012 thay BR-STUDY-011 chỉ để đếm lại tập giá trị. BR-STUDY-011 được viết khi `end_reason`
có năm giá trị; `content_deleted` vào sau, cùng Trash (BR-TRASH-004), và
`scheduler_changed` vào sau, khi đổi scheduler tách khỏi reset (BR-STUDY-016).
CHECK trong schema và kiểu dữ liệu lý do kết thúc phiên (`end_reason`) đã nhận
cả bảy từ lúc đó, còn BR-STUDY-011 thì không được đếm lại — tài liệu nói năm trong khi
database nhận bảy.

BR-STUDY-019 là điều phân biệt "session hỏng" với "mất tiến độ". Session chuyển sang
`failed` hay `invalidated` không được kéo theo việc xoá các lượt đã ghi xong —
người dùng đã bỏ công ôn 20 card thì 20 lượt đó là thật.

BR-STUDY-017 chống một tình huống thật và dễ bỏ sót: người dùng mở phiên ôn, để đó, vào
Settings reset deck, rồi quay lại phiên cũ và bấm đánh giá. Không kiểm tra
generation thì kết quả đó ghi đè trạng thái vừa được làm mới.

---

## Phiên học — cách mở, cách giữ, cách đóng

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-STUDY-020 | active | Một `study_session` MUST chỉ được tạo bởi hành động Study tường minh của người dùng. Hiển thị số đến hạn — badge, danh sách, thông báo — MUST NOT tạo session. | rule | UC-STUDY-001, BR-STUDY-008 |
| BR-STUDY-021 | active | Hàng đợi MUST được lưu trong database và MUST bất biến trong suốt phiên: thay đổi deck sau khi phiên mở MUST NOT đổi hàng đợi đang chạy. | db | UC-STUDY-001, BR-STUDY-003, BR-STUDY-022 |
| BR-STUDY-022 | active | Mỗi stage MUST có hàng đợi riêng trên **cùng tập thẻ** của phiên, với thứ tự xoáo độc lập. Phiên `reviewing` chỉ có một mode nên chỉ có một hàng đợi. Hai stage MUST NOT dùng chung một sequence khi phiên có từ hai thẻ trở lên. | db | BR-STUDY-021, BR-MODE-003 |
| BR-STUDY-023 | active | Trong phiên **học mới**, mọi lượt MUST là `learning` hoặc `relearning` và MUST NOT đổi lịch (BR-STUDY-053). Trong phiên **ôn tập**, lượt đầu tiên của mỗi thẻ là `scheduled` và đổi lịch; mọi lượt lặp sau đó là `relearning`. | store | BR-SRS-016, BR-STUDY-059, BR-STUDY-053 |
| BR-STUDY-024 | active | Số thẻ của một phiên MUST được chốt **một lần lúc mở phiên** từ tùy chọn hiệu lực (BR-STUDY-056) và lưu vào `study_session.card_limit`. Đổi tùy chọn sau đó MUST NOT ảnh hưởng phiên đang chạy. | db | BR-STUDY-003, BR-STUDY-056 |
| BR-STUDY-025 | active | Điều kiện **dựng được nội dung** của một stage (BR-STUDY-071, BR-STUDY-037, BR-STUDY-040) MUST NOT được hiểu là ngưỡng thẻ của stage đó. Chúng quyết định stage có chạy được hay bị bỏ qua, không quyết định lấy bao nhiêu thẻ. | rule | BR-MODE-009, BR-STUDY-024 |
| BR-STUDY-026 | active | `fill` MUST hiển thị **mặt sau** của thẻ làm đề bài và MUST yêu cầu người học gõ **mặt trước**: theo BR-CARD-002, `front` giữ term (tiếng Hàn) và `back` giữ nghĩa. Việc chấm MUST so dạng **đã fold** của câu trả lời với `front_folded` của thẻ — trim hai đầu và hạ hoa Unicode-aware — và khi sai, đáp án hiển thị MUST là `front`. Chính sách này **giữ nguyên dấu** — `cong` MUST NOT khớp `công`. | rule | BR-CARD-002, BR-STUDY-039, BR-STUDY-027 |
| BR-STUDY-027 | active | Mỗi lượt `fill` MUST lưu phiên bản chính sách so khớp đã dùng. Đổi chính sách MUST tăng phiên bản, MUST NOT sửa lại các lượt cũ. | db | BR-STUDY-026 |
| BR-STUDY-028 | active | Việc dùng gợi ý MUST được ghi trên lượt, và MUST NOT tự đổi `action` hay lịch. | db | BR-MODE-011, BR-CARD-003 |
| BR-STUDY-029 | active | Câu trả lời rỗng sau khi trim MUST NOT sinh lượt và MUST NOT tiến checkpoint. | rule | BR-STUDY-004, BR-STUDY-026 |
| BR-STUDY-030 | active | Nội dung người dùng gõ ở `fill` MUST NOT được lưu. Chỉ kết cục, phiên bản chính sách và cờ dùng gợi ý được ghi. | db | BR-PRIVACY-001, BR-PRIVACY-002, BR-PRIVACY-004 |
| BR-STUDY-031 | active | `recall` MUST cho tối đa **20 giây** mỗi lượt, đo bằng thời gian tương tác thực: MUST tạm dừng khi app vào nền hoặc bị ngắt, và MUST NOT tính thời gian tải nội dung. | rule + UI | — |
| BR-STUDY-032 | active | Một lượt `recall` MUST ghi **tối đa một** đáp án. Tại mốc hết giờ MUST chỉ một nhánh thắng: thao tác có thời điểm **trước** mốc là reveal thủ công (không ghi gì — BR-STUDY-065); tại hoặc sau mốc là hết giờ (ghi sai — BR-STUDY-066). MUST NOT vừa vào tự đánh giá vừa ghi hết giờ. | rule + UI | BR-STUDY-004, BR-STUDY-031, BR-STUDY-065, BR-STUDY-066 |
| BR-STUDY-033 | active | Hết giờ MUST khoá kết cục thành sai và MUST tự lật đáp án **sau khi** ghi đã commit (BR-STUDY-063). Trong cùng lượt đó MUST NOT đổi được sang đúng, kể cả khi ghi thất bại — retry MUST gửi lại đúng kết quả sai đó và MUST NOT mở lại lựa chọn của người học. | rule + UI | BR-MODE-012, BR-STUDY-032, BR-STUDY-063 |
| BR-STUDY-034 | active | Lý do "hết giờ" MUST được lưu tường minh trên `review_log.outcome_reason`. MUST NOT suy luận từ `action`, vì tự nhận quên và hết giờ cho cùng một `action`. | db | BR-SRS-015, BR-STUDY-033 |
| BR-STUDY-035 | active | Nhãn trên màn hình (ví dụ Remembered / Forgot) MUST NOT được lưu. Chỉ `action` canonical vào `review_log`. | db + UI | BR-MODE-011, BR-STUDY-070 |
| BR-STUDY-036 | active | Thời gian còn lại và trạng thái đã lật MUST được lưu để Resume tiếp tục đúng chỗ, MUST NOT đặt lại 20 giây. Lượt Resume với `is_revealed = true` và còn thời gian MUST quay lại **tự đánh giá** với đáp án đang hiện và đồng hồ đã dừng, MUST NOT chạy lại đồng hồ. Một lượt mới của thẻ ở round sau là lượt khác và MUST bắt đầu lại đủ 20 giây với đáp án ẩn. | db + UI | BR-STUDY-072, BR-STUDY-059, BR-STUDY-031, BR-STUDY-065 |
| BR-STUDY-037 | active | Mỗi question của `guess` MUST có **đúng năm** lựa chọn: một đáp án đúng xuất hiện đúng một lần, và bốn distractor. MUST NOT render số lượng khác. | rule + UI | BR-MODE-009, BR-STUDY-038 |
| BR-STUDY-038 | active | Distractor MUST lấy từ thẻ **đã học xong** (`learned_at IS NOT NULL`) **hoặc đang trong phiên hiện tại**, trong cùng cây deck. Mỗi distractor MUST tham chiếu một thẻ khác thẻ đang hỏi. | rule | BR-STUDY-059, BR-STUDY-037, BR-STUDY-051 |
| BR-STUDY-039 | active | "Hai nghĩa khác nhau" MUST đo bằng `back_folded`, không bằng chuỗi hiển thị. Hai thẻ cùng `back_folded` MUST NOT cùng xuất hiện trong một option set. | rule | BR-STUDY-037, BR-STUDY-038 |
| BR-STUDY-040 | active | Phân biệt hai ca: tập thẻ của phiên **không đủ năm nghĩa khác nhau** thì stage `guess` MUST bị bỏ qua theo BR-MODE-009, không phải lỗi. Đủ năm nhưng một question vẫn không dựng được thì MUST chặn: không render, không ghi lượt, không bỏ qua thẻ, không tiến checkpoint. | rule | BR-MODE-009, BR-STUDY-071, BR-STUDY-037 |
| BR-STUDY-041 | active | Đánh giá lựa chọn MUST so bằng định danh, MUST NOT so bằng chuỗi hiển thị. | rule | BR-STUDY-037 |
| BR-STUDY-042 | active | Mỗi question MUST chỉ nhận **lựa chọn đầu tiên** và sinh tối đa một lượt. Chạm lặp MUST NOT sinh lượt thứ hai. | rule | BR-STUDY-004, BR-STUDY-037 |
| BR-STUDY-043 | active | Thứ tự thẻ trong round và thứ tự năm lựa chọn MUST là hai hoán vị độc lập: đổi cái này MUST NOT đổi cái kia. Cả hai MUST ổn định khi Resume. | db + rule | BR-STUDY-061 |
| BR-STUDY-044 | active | Màn chọn mode ôn tập MUST hiện số thẻ **của từng mode**, không dùng chung một số: `fill` chỉ nhận thẻ có `example`, nên một phiên 20 thẻ có thể chỉ ôn được 3 bằng mode đó. | UI | BR-STUDY-071, BR-STUDY-055, BR-MODE-009 |
| BR-STUDY-045 | active | `match` MUST có ít nhất **hai** cặp trên bàn. Một cặp duy nhất làm đáp án hiển nhiên, nên stage MUST bị bỏ qua (phiên `learning`) hoặc vô hiệu hoá trên màn chọn (phiên `reviewing`) theo BR-MODE-009. | rule + UI | BR-MODE-009, BR-STUDY-059 |
| BR-STUDY-046 | active | Badge trên danh sách deck MUST hiện **hai số** theo đúng hai tập của BR-STUDY-051: số thẻ chưa học và số thẻ đến hạn ôn. MUST NOT gộp thành một số — hai tập có chi phí rất khác nhau. | UI | BR-STUDY-051, BR-CARD-007 |
| BR-STUDY-047 | active | Pill lọc trên danh sách thẻ MUST dùng cùng định nghĩa: **New** = `learned_at IS NULL` (BR-CARD-007); **Due** = `learned_at IS NOT NULL AND due_at <= now`. Hai tập MUST rời nhau. | UI + db | BR-CARD-007, BR-STUDY-051 |
| BR-STUDY-048 | active | Chỉ stage `browse` MUST cho xem lại thẻ đã qua trong cùng round, bằng vuốt hoặc bằng một control tương đương. Đây là **xem, không phải trả lời**: thẻ MUST giữ nguyên `completed`, `study_session.cursor` MUST NOT lùi, và tiến lại qua thẻ đó MUST NOT ghi lượt thứ hai hay tăng `cursor` lần hai. Các stage khác MUST NOT có thao tác này. | UI + rule | BR-MODE-005, BR-STUDY-004, BR-STUDY-042 |
| BR-STUDY-049 | active | `match` MUST bày **tối đa năm cặp** một lúc. Một round MUST được chia thành các bàn liên tiếp theo thứ tự `position` của round đó (BR-STUDY-061); bàn cuối lấy phần dư và **MAY chỉ có một cặp**. Một thẻ MUST ở nguyên bàn được chia cho nó trong suốt round. Bộ đếm và thanh tiến trình trên thanh header MUST đo **cả round**, không phải bàn. Sàn hai cặp của BR-STUDY-045 MUST được áp cho **stage**, không cho từng bàn. | rule + UI | BR-STUDY-059, BR-STUDY-061, BR-STUDY-045 |
| BR-STUDY-050 | active | Reset MUST đặt `learned_at` và `due_at` cùng về NULL. MUST NOT để thẻ có `learned_at` mà không có lịch (BR-STUDY-058). | store | BR-SRS-022, BR-STUDY-058 |
| BR-STUDY-051 | active | MUST có đúng hai loại phiên, lưu trên `study_session.session_kind`: **`learning`** lấy thẻ `learned_at IS NULL`, và **`reviewing`** lấy thẻ `learned_at IS NOT NULL AND due_at <= now`. Một phiên MUST NOT trộn hai tập. | db | BR-STUDY-002, BR-STUDY-053 |
| BR-STUDY-052 | active | `kind = 'learning'` MUST dành cho lượt trong chuỗi học mới: ghi lịch sử, không đổi lịch. MUST NOT xuất hiện trong phiên `reviewing`. | db | BR-SRS-014, BR-STUDY-023 |
| BR-STUDY-053 | active | Chuỗi học mới MUST NOT đổi `card_schedule` cho tới khi thẻ đi hết **stage cuối mà chính nó tham gia** — stage bỏ qua thẻ theo BR-STUDY-071 không được tính là stage nó phải đợi. **Hoàn tất là một sự kiện, không phải một lượt đánh giá**: nó đặt `learned_at`, khởi tạo lịch ở mức thấp nhất — `eight_box` box 1, `sm2` interval 1 — với `due_at` là đầu ngày học kế tiếp (BR-STUDY-074), và MUST NOT ghi lượt `scheduled` nào. | store | BR-STUDY-023, BR-STUDY-074, BR-SRS-003, BR-STUDY-071 |
| BR-STUDY-054 | active | Phiên `reviewing` MUST NOT được mở khi không có thẻ nào đến hạn. MUST NOT có thao tác nào cho phép ôn sớm hơn hạn. | rule + UI | BR-STUDY-008, BR-STUDY-051 |
| BR-STUDY-055 | active | Mode khả dụng để ôn tập MUST là các stage **chấm điểm** của thuật toán: `eight_box` → `match`, `guess`, `recall`, `fill`; `sm2` → `self_assess`. `browse` MUST NOT là một lựa chọn ôn tập. Chỉ còn một mode khả dụng thì MUST vào thẳng, không hiện màn chọn. | rule + UI | BR-MODE-005, BR-MODE-009, BR-MODE-004 |
| BR-STUDY-056 | active | Tùy chọn học MUST có hai tầng: mặc định toàn app, và ghi đè trên **root deck**. Deck có giá trị riêng thì dùng giá trị đó; NULL thì theo mặc định. Deck con MUST NOT có tùy chọn riêng — tra qua `root_id` như BR-DECK-025. | db | BR-DECK-025, BR-STUDY-024, BR-STUDY-057 |
| BR-STUDY-057 | active | `new_card_order` MUST là một trong hai: `created` (theo `created_at` tăng dần) hoặc `random`. Mặc định `created`. | rule | BR-STUDY-002, BR-STUDY-056 |
| BR-STUDY-058 | active | Thẻ có `learned_at` MUST có lịch (`due_at` không NULL); thẻ `learned_at IS NULL` MUST NOT có lượt `scheduled` nào. | db + invariant | BR-STUDY-053 |
| BR-STUDY-059 | active | Bốn mode chấm điểm (`match`, `guess`, `recall`, `fill`) MUST chạy theo **round**, ở cả hai loại phiên: round 1 gồm toàn bộ thẻ đủ dữ liệu; mỗi round sau chỉ gồm thẻ không đạt ở round vừa xong. `self_assess` MUST NOT dùng round — nó lặp theo BR-STUDY-005. | store | BR-STUDY-005, BR-STUDY-060 |
| BR-STUDY-060 | active | Một thẻ từng có kết quả sai trong một round MUST thuộc tập không đạt của round đó, **kể cả khi sau đó nó được làm đúng** để rời bàn. Tập này MUST được khử trùng theo thẻ. | store | BR-SRS-018, BR-STUDY-059 |
| BR-STUDY-061 | active | Mỗi round MUST có thứ tự xoáo riêng. Hai round liền nhau, và round 1 với stage trước đó, MUST NOT dùng chung một sequence khi còn từ hai thẻ trở lên. | db | BR-STUDY-022 |
| BR-STUDY-062 | active | Một lượt MUST thuộc về thẻ sở hữu **term**, bất kể vế nào được chạm trước; chạm meaning trước MUST được chấp nhận. Chọn nhầm meaning MUST NOT đánh dấu thẻ sở hữu meaning đó là không đạt. Một cặp sai MUST giữ hàng queue của round hiện tại ở `pending` — thẻ ở lại bàn để ghép lại — và MUST enroll thẻ vào round kế tiếp đúng một lần. | rule | BR-STUDY-059, BR-STUDY-060 |
| BR-STUDY-063 | active | Giao diện MUST chỉ hiển thị kết quả của một lượt **sau khi** transaction ghi lượt đó đã commit; trạng thái đã chấm MUST NOT được vẽ dựa trên thao tác của người dùng trước khi có xác nhận ghi. Ghi thất bại MUST NOT bắt đầu feedback và MUST NOT chuyển lượt. | UI + store | BR-STUDY-004, BR-STUDY-018 |
| BR-STUDY-064 | active | Đơn vị học đang hiển thị MUST ở lại màn hình trong suốt thời gian đọc kết quả và trong suốt lúc tải lượt kế tiếp; MUST NOT thay thân màn bằng trạng thái tải giữa hai lượt. Trạng thái tải toàn thân MUST chỉ dùng khi phiên chưa có lượt nào. Mỗi mode MUST khai báo thời lượng hiển thị kết quả của mình. | UI | BR-STUDY-004, BR-STUDY-063 |
| BR-STUDY-065 | active | Ở `recall`, mở đáp án MUST NOT là một kết cục: nó MUST NOT ghi `review_log`, MUST NOT được chấm đúng hay sai, và MUST dừng đồng hồ rồi chuyển sang **tự đánh giá** với đúng hai lựa chọn — nhớ được (đúng) và đã quên (sai). Chỉ lựa chọn của người học MUST được ghi, đúng một lần cho một lượt. | rule + UI | BR-MODE-012, BR-STUDY-070, BR-STUDY-032, BR-STUDY-035 |
| BR-STUDY-066 | active | Hai kết thúc của `recall` MUST có nhịp khác nhau. Tự đánh giá: sau khi commit MUST tự chuyển lượt, MUST NOT giữ thêm một thời lượng cố định và MUST NOT hiện nút Tiếp theo. Hết giờ: sau khi commit MUST hiện trạng thái đã bị tính sai và một nút Tiếp theo, MUST NOT tự chuyển theo thời lượng; bấm Tiếp theo MUST chỉ chuyển lượt và MUST NOT ghi thêm đáp án nào. | UI | BR-STUDY-032, BR-STUDY-033, BR-STUDY-063, BR-STUDY-064 |
| BR-STUDY-067 | active | Danh sách deck MUST phân loại mỗi deck theo lịch, suy ra lúc đọc và MUST NOT lưu thành cột: `notDue` khi `dueCardCount = 0`; `dueToday` khi thẻ Due **cũ nhất** của subtree có `due_at` thuộc ngày học địa phương hiện tại; `overdue` khi ngày của nó đã qua. Badge MUST hiện số **ranh giới ngày địa phương đã hoàn tất** giữa `due_at` của thẻ Due cũ nhất và hôm nay (theo mốc BR-STUDY-074), MUST NOT là phép chia số giờ cho 24. Qua đầu ngày địa phương, trạng thái và badge MUST tự làm mới dù database không có write nào. Cả `dueToday` lẫn `overdue` vẫn thuộc đúng một tập Reviewing của BR-STUDY-051 — phân loại này là UI, MUST NOT tạo loại phiên thứ ba, MUST NOT đổi thứ tự thẻ hay hành vi scheduler, Trạng thái `overdue` MUST mang cặp `errorContainer`/`onErrorContainer` trên **chip đếm overdue của workload line** (quyết định chủ dự án 2026-08-20 — dời khỏi ô icon, đảo phần "ô icon" của quyết định 2026-08-11 vốn đã đảo phán quyết "không danger" cùng ngày): trễ hạn vẫn là tín hiệu đỏ, nhưng nó là **một con số**, không phải một ô vuông — ô icon đỏ cạnh chip đỏ nói cùng một điều hai lần, bằng một glyph đọc ra "đã huỷ" chứ không phải "trễ". Ô icon MUST là danh tính của deck (`folder`/`card`) trên cặp `primaryContainer`/`onPrimaryContainer` ở **mọi** trạng thái lịch. `dueToday` và `notDue` MUST NOT dùng màu đỏ. Level summary MUST tiếp tục phản ánh trạng thái của chính level đang xem — kể cả khi deck mang backlog không còn là một hàng trên màn hình: Due/New là tổng các child subtree (rời nhau), số ngày quá hạn là **max** trên các child có Due, và phân loại đi qua đúng một hàm chung với tile, MUST NOT chép lại điều kiện ở widget khác. Breakdown bốn tập của hero: BR-STUDY-068. | UI + store | BR-STUDY-074, BR-STUDY-051, BR-STUDY-046, BR-STUDY-008 |
| BR-STUDY-068 | active | Hero level summary MUST hiển thị bốn tập rời nhau của level đang xem: `Overdue` = `learned_at IS NOT NULL AND due_at < startOfToday` (ranh giới đầu ngày địa phương theo mốc BR-STUDY-074, tính ở một chỗ dùng chung, MUST NOT tự tính trong SQL); `Due today` = `learned_at IS NOT NULL AND due_at >= startOfToday AND due_at <= now`; `New` = `learned_at IS NULL`; `Scheduled` = `learned_at IS NOT NULL AND due_at > now` — hiển thị bằng `total − New − Due` từ cùng snapshot, MUST NOT mang headline hay màu cảnh báo (thẻ nghỉ là lịch đang chạy đúng, không phải việc cần làm). Bốn tập cộng đúng bằng tổng thẻ của level. MUST giữ `dueCardCount = overdueCardCount + dueTodayCardCount` — tổng Reviewing của BR-STUDY-051 không đổi nghĩa và phiên học vẫn chọn thẻ theo total, không theo hai nửa. Count là aggregate subtree của chính level đang xem, suy ra lúc đọc trong cùng một statement với các count khác — MUST NOT lưu thành cột, MUST NOT query thứ hai. Chú thích tuổi `+Nd` đã bỏ khỏi giao diện nhìn thấy (quyết định chủ dự án 2026-08-20): nó nói backlog *cũ* bao lâu chứ không nói *lớn* cỡ nào. Tuổi của thẻ Due cũ nhất (BR-STUDY-067) MUST vẫn tới được screen reader qua `deckOverdueSemanticLabel`/`deckHeroOverdueSemanticLabel` và MUST NOT là count. Qua đầu ngày địa phương, thẻ Due today của ngày cũ MUST tự chuyển sang Overdue ở lần đọc kế tiếp mà không có database write. Deck tile MUST hiển thị ba chip rời nhau `overdue · due · new` — mỗi chip một nền riêng — thay cho total Due + New và icon trạng thái (quyết định chủ dự án 2026-08-20). Chip chỉ hiện khi count > 0; deck có thẻ nhưng không còn việc MUST nêu cả hai số 0 trên nền trung tính. | UI + store | BR-STUDY-074, BR-STUDY-051, BR-STUDY-046, BR-STUDY-067 |
| BR-STUDY-069 | active | Mode dùng round MUST hoàn tất khi một round kết thúc mà tập không đạt rỗng. Không có trần số round. Trần 3 của BR-STUDY-073 là của `self_assess`, không áp ở đây. | store | BR-STUDY-059, BR-STUDY-073 |
| BR-STUDY-070 | active | Một stage MAY có nhiều mức phản hồi (ví dụ `almost` của `match`), nhưng mọi mức không phải "đúng" MUST vào tập không đạt và MUST ánh xạ như sai theo BR-MODE-012. Mức phản hồi MUST NOT xuất hiện trong `review_log.action`. | rule + UI | BR-MODE-011, BR-MODE-012 |
| BR-STUDY-071 | active | Thẻ không đủ dữ liệu cho một stage MUST bị bỏ qua **có ghi nhận** ở stage đó, MUST NOT bị xoá khỏi deck, và MUST vẫn xuất hiện ở các stage khác mà nó đủ dữ liệu. | store | BR-MODE-009, BR-STUDY-022 |
| BR-STUDY-072 | active | Khi mở app còn session `in_progress` của **cùng ngày học**, màn chọn MUST có ba đường: tiếp tục phiên đó, Học mới, hoặc Ôn tập. Chọn một trong hai đường sau MUST chuyển phiên dở sang `abandoned`/`user_exit`. Session `in_progress` của ngày học khác MUST chuyển `abandoned` với `end_reason = interrupted`. | store | BR-STUDY-011, BR-STUDY-074, BR-STUDY-051 |
| BR-STUDY-073 | active | **Chỉ áp cho mode `self_assess`, ở mọi loại phiên.** Chạm trần 3 lượt `relearning` (BR-STUDY-005) MUST cho thẻ rời hàng đợi, và MUST bật cờ đánh dấu của thẻ. MUST NOT tự tắt cờ. | store | BR-STUDY-005, BR-CARD-009 |
| BR-STUDY-074 | active | `next_due_at` MUST rơi vào **00:00 giờ địa phương** của ngày thứ N, với N là interval do thuật toán trả về. Giá trị lưu vẫn là UTC. | rule | BR-SRS-009, BR-SRS-011 |

BR-STUDY-021 thay câu cũ trong `data-model.md` rằng hàng đợi là trạng thái tạm của
controller. Lý do đổi: hàng đợi mang **luật**, không chỉ mang thứ tự — thứ tự
BR-STUDY-002, lượt quay lại BR-STUDY-005, trần BR-STUDY-073 — và một cấu trúc mang luật nằm trong
UI là chỗ luật đi ra khỏi tầm với của mọi phép kiểm. Đặt nó vào
database biến "snapshot bất biến" từ một lời hứa thành một ràng buộc, và cho phép
BR-STUDY-072 tồn tại: một phiên sống sót qua việc app bị hệ điều hành thu hồi.

BR-STUDY-074 sửa một chỗ trôi mà không ai thấy: `now + N*24h` đẩy mốc đến hạn muộn dần
theo giờ người dùng bấm. Học lúc 23:00 thì hôm sau 22:00 thẻ **chưa** tới hạn, và
mỗi phiên lại đẩy thêm — giờ học trôi dần về khuya cho tới khi người dùng hụt cả
một ngày. Neo vào đầu ngày lịch làm "đến hạn hôm nay" đúng nghĩa là hôm nay.

**BR-STUDY-026 dùng lại `back_folded`, và điều đáng kiểm là nó fold những gì.** Cột đó
trim và hạ hoa Unicode-aware nhưng **không bỏ dấu** — chỉ fold hoa/thường, nên
`công` vẫn không khớp `cong`. Nếu nó fold cả dấu thì `fill`
sẽ chấm "ma" bằng "mà" là đúng, và một app học từ vựng tiếng Việt hỏng ở đúng chỗ
quan trọng nhất. Kiểm trước khi dùng lại, không suy từ cái tên.

**BR-STUDY-027 là lý do `scheduler_version` tồn tại, áp cho một thứ khác.** Một lượt đã ghi
phải đọc lại được bằng chính luật đã tạo ra nó. Nới chính sách so khớp — ví dụ bỏ
qua dấu câu — sẽ biến những lượt sai của hôm qua thành đúng khi đọc lại, và không
có cách nào biết lượt nào đã được chấm theo luật nào.

**BR-STUDY-030 là quyết định có thể lật, và hiện tại nghiêng về không lưu.** Câu trả lời
sai của người học là dữ liệu phân tích tốt, nhưng nó cũng là dữ liệu riêng tư
(BR-PRIVACY-001) và chưa có tính năng nào đọc nó. Thêm cột khi có caller thật thì rẻ; gỡ một
cột đã đầy dữ liệu riêng tư thì không.

**BR-STUDY-053 làm một vấn đề biến mất thay vì phải xử lý nó.** Nếu chuỗi học mới đặt
lịch dọc đường thì một phiên bỏ dở ở stage 3 để lại thẻ có lịch nhưng chưa học
xong, và lần học mới sau sẽ đặt lại lịch lần hai. Gỡ chuyện đó cần hoàn tác
`card_schedule` từ `previous_*`, giảm `lapse_count`, và xoá lượt — tức sửa BR-STUDY-019,
thứ tồn tại để đảm bảo không lượt nào bị mất.

Không đặt lịch cho tới khi xong chuỗi thì **không có gì để hoàn tác**: thẻ bỏ dở
chưa có `learned_at`, chưa có `due_at`, nên nó đơn giản nằm lại trong tập học mới
và học lại từ `browse`. Các lượt đã ghi vẫn ở nguyên trong `review_log` dưới
`kind = 'learning'` — chúng là lịch sử thật về việc người học đã gặp thẻ đó.

**Hoàn tất học mới là sự kiện, không phải lượt đánh giá** — và đó là lý do nó
không cần một `action` tổng kết. Bốn stage chấm điểm đều lặp round tới khi sạch
(BR-STUDY-069), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng: một action suy từ đó
sẽ luôn là "nhớ được" và không phân biệt được thẻ nào. Thẻ vừa học lần đầu
vì thế bắt đầu ở mức thấp nhất và gặp lại ngay ngày học kế — một buổi học không
đủ dữ kiện để nói thẻ nào dễ.

**BR-STUDY-054 là luật về sản phẩm, không phải về dữ liệu.** Ôn sớm hơn hạn làm hỏng chính
thứ spaced repetition mua được: khoảng cách. App không chặn người dùng học nhiều —
họ có thể mở bao nhiêu phiên tùy ý (BR-STUDY-003) — nhưng thứ họ học thêm phải là **thẻ
mới**, không phải thẻ chưa tới hạn.

**BR-STUDY-056 tách hai tầng vì hai deck không giống nhau.** Một deck nhập từ giáo trình
cần học theo thứ tự bài; một deck từ vựng rời thì ngẫu nhiên tốt hơn. Bắt người
dùng chọn một kiểu cho cả hai là bắt họ chọn sai cho một trong hai. Deck để NULL
thì theo mặc định, nên không ai phải cấu hình gì để bắt đầu.

**Mốc 00:00 làm khoảng cách đầu tiên phụ thuộc giờ học, và đó là đánh đổi đã
nhận.** Thẻ học xong lúc 09:00 đến hạn sau 15 giờ; thẻ học xong lúc 23:00 đến hạn
sau **một giờ**. Từ lượt ôn thứ hai trở đi thì khoảng cách đo bằng ngày lịch nên
không còn lệch, nhưng lượt đầu tiên thì có.

Đây là giá của việc neo vào **ngày lịch** thay vì cộng giờ (BR-STUDY-074), và cái mua
được lớn hơn: giờ học không trôi dần về khuya, và "đến hạn hôm nay" đúng nghĩa là
hôm nay. Nếu sau này muốn gỡ, lối đi là mốc cắt khác 00:00 — sửa ở đúng một chỗ,
vì offset múi giờ chỉ do composition root cấp, không phải sửa công thức.

**BR-STUDY-065 sửa một lỗi chấm điểm, không phải một lỗi giao diện.** Mở đáp án từng
*là* kết cục "đúng": người học bấm Xem đáp án ở giây thứ tư và thẻ được thăng
hộp vì đã bỏ cuộc. 8-box cần đúng một bit bằng chứng cho mỗi lượt, và bằng chứng
ấy chỉ người học có — nhìn vào mặt sau không nói gì về việc có nhớ hay không.
Nên reveal là **trạng thái trình bày**, còn kết cục là thứ người học nói ra.

**BR-STUDY-066 là hệ quả của việc hai kết thúc do hai người bấm giờ.** Tự đánh giá xảy
ra *sau* khi người học đã đọc mặt sau, nên giữ màn hình thêm một nhịp là bắt họ
chờ trên thứ họ đọc xong rồi. Hết giờ thì ngược lại: mặt sau là chữ họ chưa từng
thấy, trên một thẻ vừa mất vì đồng hồ — không ai chọn hộ được thời lượng ấy, nên
nó kết thúc ở một nút họ bấm. Một con số cố định phục vụ cả hai thì sai cả hai
lần, và 1800/2200ms đang đo một việc không ai làm.

**BR-STUDY-034 là BR-SRS-015 lặp lại ở một chỗ khác.** Người học tự nhận quên và người học
hết giờ đều cho `action = forgotten`. Không có cột riêng thì hai điều đó không phân
biệt được từ dữ liệu đã lưu — và chúng nói hai chuyện rất khác nhau về chất
lượng thẻ. `review_log` là bảng chỉ thêm, nên một cột thiếu hôm nay không tính
ngược được ngày mai.

**BR-STUDY-036 là hệ quả của BR-STUDY-072, không phải một yêu cầu UI.** Phiên sống sót qua
việc hệ điều hành thu hồi app, nên "còn bao nhiêu giây" phải nằm trong database
chứ không trong bộ nhớ của một controller. Ngược lại, một lượt mới ở round sau
bắt đầu lại đủ 20 giây — nó là lượt khác, không phải phần còn lại của lượt cũ.

**Đếm giờ là input, không phải thứ nghiệp vụ tự đọc.** Nghiệp vụ MUST NOT tự đọc
đồng hồ hệ thống. Handler của `recall` nhận `didTimeout` và `elapsedMs` như input
và vẫn là một hàm thuần.

**Mỗi mode có một ngưỡng riêng, và chúng không giống nhau.** BR-STUDY-025 nói không mode
nào có ngưỡng **số thẻ lấy ra** riêng — mọi mode của một phiên dùng chung
một tập. Nhưng điều kiện
**dựng được nội dung** thì có, và khác nhau: `guess` cần năm nghĩa khác nhau trong cây
(BR-STUDY-037, BR-STUDY-038); `fill` cần thẻ có `example` (BR-STUDY-071); `match` cần hai cặp (BR-STUDY-045).
`recall`, `self_assess` và `browse` chạy được với một thẻ.

BR-STUDY-045 tồn tại vì một deck mới tạo với đúng một thẻ là ca thật, không phải ca biên:
người dùng thêm thẻ đầu tiên rồi bấm Học mới ngay. Không có luật này thì `match`
hiện một cặp và người học ghép nó với chính nó — một lượt đúng không chứng minh gì.

**BR-STUDY-001 bị thay, và điều đó chạm tới code đang chạy.** Định nghĩa cũ — `due_at IS
NULL OR due_at <= now` — đang được badge trên deck list, pill Due/New trên card
list và query `cardsDueForStudy` implement. Trong mô hình mới, `due_at IS NULL`
không còn nghĩa "đến hạn ngay" mà nghĩa "chưa học xong", nên một con số gom cả
hai đang trộn hai việc có chi phí khác hẳn nhau: 20 thẻ mới tốn gấp năm lần 20
thẻ ôn. BR-STUDY-046 và BR-STUDY-047 đưa hai con số đó về đúng ngôn ngữ mà popup Study dùng.

**BR-STUDY-048 tồn tại vì `browse` là stage duy nhất không có câu hỏi nào.** Năm stage
còn lại đều lấy một câu trả lời từ thẻ đang hiện; đặt một thẻ đã trả lời lên đó
là mời người dùng chấm lại thứ phiên đã chấm — BR-STUDY-042 nói mỗi câu hỏi sinh tối đa
một lượt, và một màn cho phép quay lại thẻ đã chấm là đường đi thẳng tới lượt thứ
hai. `browse` không chấm gì (BR-MODE-005), nên quay lại nó không mâu thuẫn với điều gì.

Chỗ dễ sai là **lùi rồi tiến**. Nếu lùi làm `cursor` giảm thì tiến lại sẽ đi qua
`markBrowsed` một lần nữa: thẻ được ghi hai lần và bộ đếm nhảy quá tay. Vì vậy
BR-STUDY-048 nói rõ lùi **không** đụng tới queue — nó chỉ đổi thẻ nào đang được vẽ. Bộ
đếm và thanh tiến trình vẫn mô tả lượt đang mở, nên màn hình MUST nói rõ đang xem
lại; nếu không, một thẻ đã qua trông như phiên vừa tự lùi.

Chỗ dễ sai thứ hai là **thứ tự của vết đã xem**. Danh sách thẻ đã xong của một
round trước đây được đọc không kèm `ORDER BY`; `match` dùng nó như một tập nên
không thấy gì, còn `browse` đi ngược nó nên thứ tự là bắt buộc. Câu truy vấn nay
sắp theo `position` — thứ tự queue phục vụ, cũng chính là thứ tự người dùng đã
thấy trong một round phục vụ mỗi thẻ đúng một lần.

**BR-STUDY-050 tồn tại vì invariant 24 đã bắt được một mâu thuẫn.** Reset xoá lịch;
nếu nó giữ `learned_at` thì mỗi lần reset sẽ để lại một thẻ "đã học xong nhưng
không có lịch" — đúng thiếu sót mà invariant 24 được viết để chặn, và một thẻ
không thuộc tập nào trong hai tập của BR-STUDY-051. Xoá cả hai cùng lúc đưa thẻ về
đúng trạng thái trước khi học — đúng nghĩa của "đặt lại tiến độ".

**BR-STUDY-038 đã đổi nguồn, và lý do nằm ở phiên ôn tập.** Một phiên ôn có thể chỉ có
ba thẻ đến hạn — lấy distractor từ phạm vi đó thì không bao giờ đủ năm nghĩa và
`guess` gần như luôn bị vô hiệu hoá, dù deck có hai trăm thẻ đã học. Nguồn đúng là
**thẻ đã học xong trong cây**: người học đã gặp chúng nên chúng là nhiễu thật, và
thẻ chưa học không bị lộ nội dung trước khi đến lượt nó.

**`self_assess` không bao giờ dùng round.** Nó lặp bằng BR-STUDY-005 ở **mọi loại phiên**:
thẻ quay lại sau ≥ 3 thẻ khác, trần 3 lượt rồi rời hàng đợi kèm cờ (BR-STUDY-073). Bốn
mode chấm điểm dùng round, không trần (BR-STUDY-069). Hai cơ chế, ranh giới là **mode**
chứ không phải loại phiên — vì `self_assess` không có "bàn" để hết, còn bốn mode
kia thì có.

**BR-STUDY-038 tách hai khái niệm dễ bị gộp.** *Hàng đợi* là những thẻ đang được hỏi ở
round này; *tập thẻ của phiên* là nguồn lấy distractor. Chúng khác nhau, và gộp
lại thì retry round còn một thẻ sẽ không đủ năm lựa chọn — đúng ca mà BR-STUDY-059 tạo ra
thường xuyên nhất. Thẻ đã đạt rời hàng đợi nhưng **không** rời tập nguồn.

**BR-STUDY-039 dùng lại `back_folded` thay vì định nghĩa một phép chuẩn hoá thứ hai.**
Cột đó đã tồn tại để search so trên nó: đã trim, hạ hoa và fold Unicode. Một
phép normalize riêng cho `guess` sẽ trôi khỏi phép kia ngay lần đầu
có ai sửa một trong hai, và không ai biết để sửa cả hai.

**BR-STUDY-040 là chỗ đặc tả gốc và BR-STUDY-071 nói ngược nhau, và cả hai đều đúng — cho hai
ca khác nhau.** Deck chỉ có ba thẻ thì `guess` **không bao giờ** dựng được question,
và hiện lỗi mỗi phiên là đổ cho người dùng một thứ họ không sửa được bằng thao
tác nào trong phiên; bỏ qua stage là đúng. Nhưng khi tập đủ năm mà một question
vẫn không dựng được thì đó là bất thường thật, và chặn lại mới đúng — render bốn
lựa chọn sẽ âm thầm đổi xác suất đoán đúng từ 20% lên 25%.

**Một thẻ đi qua nhiều mode trong một phiên, và câu "lượt nào đổi lịch" có hai
câu trả lời khác nhau tùy loại phiên.**

Trong phiên `reviewing`, mỗi thẻ được hỏi bằng **một** mode, nên lượt đầu của nó
là `scheduled` và đổi lịch; các lượt lặp sau đó — round hoặc BR-STUDY-005 — là
`relearning` (BR-SRS-016, BR-STUDY-023).

Trong phiên `learning`, thẻ đi qua cả chuỗi và **không lượt nào đổi lịch**
(BR-STUDY-053). Lý do không phải là tiết kiệm: bốn mode chấm điểm đều lặp tới khi sạch
(BR-STUDY-069), nên mọi thẻ đều kết thúc chuỗi bằng một lần đúng — một `action` suy từ
đó sẽ luôn đọc là "nhớ được" và không phân biệt được thẻ nào. Lịch vì thế được
khởi tạo bởi **sự kiện hoàn tất**, ở mức thấp nhất, giống nhau cho mọi thẻ.

**Mô hình này thay một cách tiếp cận cũ, cho lượt đầu ở stage chấm điểm đầu
tiên quyết định lịch** — một hệ quả được chấp nhận chứ chưa được cân nhắc đủ:
sai ở Match rồi đúng ba stage sau
vẫn cho lịch của một lần sai. Câu hỏi đó không còn tồn tại — trong phiên học mới
không có lịch nào để đặt sai, và trong phiên ôn tập chỉ có một mode nên không có
gì để chọn giữa.

**Không còn mục nào để trống trong nghiệp vụ Study.** Hai mục cuối đã đóng:
trần thẻ là `card_limit` áp cho cả hai loại phiên và là trần **mỗi lần
lấy** (BR-STUDY-003); và phiên không cho chọn scope hẹp hơn deck đang đứng — người dùng
chọn **loại phiên**, không chọn phạm vi.

---

## Tab Study — đọc thư viện thật

Study Home đọc đúng thư viện của người dùng thay vì một fixture (UC-STUDY-002). Các rule dưới đây **không** phát biểu lại luật mở phiên (BR-STUDY-004), luật đến hạn (BR-STUDY-051) hay luật ngày học (BR-STUDY-074).

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-STUDY-075 | active | Tab Study MUST đọc thư viện thật và MUST NOT phụ thuộc vào bất kỳ deck id cố định nào trong production. Vào tab, cuộn, đổi tab và stream tự refresh MUST NOT ghi database: MUST NOT tạo session, MUST NOT khoá scheduler (BR-SRS-003), MUST NOT materialize hàng đợi. Chỉ thao tác chạm tường minh của người dùng mới được dẫn tới write. Resume card MUST chỉ hiện khi tồn tại một session thoả **đồng thời** bốn điều kiện, tất cả kiểm bằng đọc: `status = in_progress`; `started_at` thuộc ngày học hiện tại theo mốc BR-STUDY-074; generation của root khớp generation của session (BR-STUDY-017); và hàng đợi của session còn ít nhất một hàng. Session không thoả MUST NOT được quảng cáo; việc **đóng** session của ngày cũ vẫn thuộc `abandonStaleSessions` (BR-STUDY-072) và MUST NOT chuyển vào màn hình này. Chạm Resume MUST mở đúng session và đúng lượt đã lưu (BR-STUDY-036), MUST NOT tạo session thứ hai. Nhiều session cùng mở thì MUST chọn session mới nhất theo `started_at`. Chạm hai lần liên tiếp MUST chỉ dẫn tới một lần mở. | store + UI | UC-STUDY-002, BR-STUDY-017, BR-STUDY-020, BR-STUDY-072, BR-STUDY-036 |
| BR-STUDY-076 | active | Danh sách Study Home MUST chỉ liệt kê root deck, mỗi root một hàng, workload tổng hợp **toàn subtree** qua `root_id` (BR-DECK-002, BR-DECK-003) và MUST NOT dùng shortcut coalesce parent. Thứ tự MUST giảm dần theo ba khoá xếp hạng, đúng thứ tự đó: số Overdue, rồi số Due today, rồi số New — MUST NOT xếp theo tổng. Bằng nhau cả ba thì tie-break theo tên deck đã fold chữ hoa/thường theo Unicode (cùng quy ước BR-TAG-001), rồi theo `id`; tie-break MUST NOT dựa vào `lower()` của SQL vì hàm đó chỉ fold ASCII. Deck không còn workload MUST vẫn nằm trong danh sách, đứng cuối theo chính thứ tự trên, và MUST giữ hành động mở nếu subtree còn ít nhất một card (BR-STUDY-008). Deck không còn card nào MUST NOT được trao hành động mở. Ba con số MUST luôn hiển thị kể cả khi bằng 0, mỗi con số MUST có icon và nhãn chữ riêng, và màu MUST NOT là tín hiệu duy nhất. | store + UI | UC-STUDY-002, BR-STUDY-008, BR-DECK-002, BR-DECK-003, BR-TAG-001, BR-STUDY-068 |
| BR-STUDY-077 | active | Study Home MUST phân biệt ba trạng thái đã tải, mỗi trạng thái có một bước tiếp theo riêng. Thư viện **không có root deck nào**: MUST hiển thị CTA tới Starter Library (UC-STARTER-001) và MUST NOT hiện danh sách rỗng. Có root deck nhưng **không root nào có card**: MUST hiển thị zero state có đường về Library, MUST NOT hiện CTA starter và MUST NOT bịa số Due cho deck rỗng. Có card: MUST hiện danh sách theo BR-STUDY-076, kể cả khi mọi workload bằng 0 — trường hợp đó là lịch đang chạy đúng (BR-STUDY-008), MUST NOT trình bày như lỗi hay như thành tích. Mọi hành động trên màn hình MUST trỏ tới route có thật; MUST NOT có control bật mà không dẫn đi đâu. Lỗi đọc MUST hiện trạng thái lỗi có retry, MUST NOT nêu tên bảng, câu truy vấn hay đường dẫn. | UI | UC-STUDY-002, UC-STARTER-001, BR-STUDY-008, BR-STUDY-076 |

---

## Entity state machines

### Study session

| From | To | Trigger |
|---|---|---|
| in_progress | completed | hết queue (BR-STUDY-013) |
| in_progress | abandoned | người dùng thoát hoặc chọn đường mới thay vì tiếp tục (`user_exit`, BR-STUDY-014, BR-STUDY-072), hoặc phiên của ngày học trước không được tiếp tục (`interrupted`, BR-STUDY-072) |
| in_progress | invalidated | reset khi đang mở (`scheduler_reset`, BR-STUDY-015), đổi scheduler khi chưa khoá (`scheduler_changed`, BR-STUDY-016), ghi từ generation cũ (`stale_generation`, BR-STUDY-017), hoặc nội dung của phiên vào Trash (`content_deleted`, BR-TRASH-004) |
| in_progress | failed | lỗi không thể tiếp tục (BR-STUDY-018) |

Trạng thái kết thúc là terminal — không có đường quay lại `in_progress`.

---

## Edge cases

Đây là **hệ quả** của các rule ở trên, không phải rule mới (§9).

| Case | Expected behaviour |
|---|---|
| Thẻ trả lời sai trong phiên `mixed`, quay lại sau ba thẻ | Vẫn hỏi đúng chiều cũ — chiều nằm trên chính dòng hàng đợi (BR-STUDY-005, BR-MODE-015) |
| App bị thu hồi giữa phiên `mixed`, mở lại | Resume đọc chiều đã lưu, không hỏi lại và không gieo lại (BR-STUDY-072, BR-MODE-017) |
| Mở phiên → reset ở màn khác → quay lại bấm đánh giá | Từ chối ghi; session → `invalidated`/`stale_generation` (BR-STUDY-017) |
| Reset khi đang có phiên dở | Session → `invalidated`/`scheduler_reset` trong cùng transaction (BR-STUDY-015, BR-SRS-027) |
| Session lỗi ghi không thể tiếp tục | Session → `failed`/`persistence_error`; các lượt đã ghi vẫn giữ (BR-STUDY-018, BR-STUDY-019) |
| Không card nào đến hạn | Ôn tập **không mở được** (BR-STUDY-054); hiện thời điểm card gần nhất đến hạn. Học mới vẫn mở được nếu còn thẻ chưa học |
| Bỏ 2 tuần, 400 card quá hạn | `card_limit` thẻ mỗi lần lấy, mặc định 20 (BR-STUDY-003); hiện số còn lại và cho mở phiên tiếp ngay — số phiên trong ngày không giới hạn |
| Thoát giữa phiên | Giữ toàn bộ lượt đã ghi (BR-STUDY-004, BR-STUDY-019); session → `abandoned`/`user_exit`. Phiên học mới bỏ dở **không để lại lịch nào** (BR-STUDY-053) |
