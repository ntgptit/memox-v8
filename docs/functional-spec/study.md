# Study — functional specification

Các chức năng của feature study. Feature study-mode không có use case class riêng: các mode
(`browse`, `match`, `guess`, `recall`, `fill`, `self_assess`) là logic mà các FN dưới đây chạy, nên
các BR-MODE được trích ở đây. Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen
spec". Lỗi là các giá trị của `StudyRejection`
(`lib/features/study/domain/failures/study_failure.dart`); lỗi ghi hay đọc database đi theo mô hình
lỗi của ADR-016.

## FN-STUDY-001 — Xem lối vào học của một deck
Status: active · Code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart]

### Precondition

Không có.

### Input

- Deck (root hoặc deck con).

### Kết quả

Một luồng dữ liệu, phát lại mỗi khi dữ liệu đổi và mỗi nửa đêm theo giờ local. Mỗi lần phát cho
biết:

- hai tập **không trộn**: học mới = thẻ `learned_at IS NULL`; ôn tập = thẻ
  `learned_at IS NOT NULL AND due_at <= now`, mỗi tập kèm số lượng; không thẻ nào thuộc cả hai;
- tuỳ chọn học đang hiệu lực của root (số thẻ mỗi phiên, thứ tự thẻ mới);
- các mode ôn tập mà thuật toán của root cung cấp — `eight_box`: `match`, `guess`, `recall`, `fill`;
  `sm2`: `self_assess`; không bao giờ `browse` — mỗi mode kèm **số thẻ của riêng nó** (`fill` chỉ
  tính thẻ có `example`), và mode không đủ dữ liệu là không khả dụng kèm lý do, lý do đó không gợi
  ý Reset;
- mode ôn tập có nhận chiều hỏi hay không;
- khi tập ôn tập rỗng: thời điểm thẻ gần nhất đến hạn, neo theo đầu ngày học địa phương — một
  trạng thái bình thường, không phải lỗi;
- phiên đang mở của deck này, nếu còn tiếp tục được (cùng ngày học, cùng generation), cùng những
  gì người dùng cần biết về nó để tiếp tục;
- số thẻ khác nhau mà một phiên sẽ lấy, theo giới hạn của phiên.

Không ghi gì.

### Lỗi

- `notFound` — deck không còn hoặc đang ở Trash.

### Business rules

- BR-MODE-009
- BR-MODE-010
- BR-MODE-013
- BR-STUDY-008
- BR-STUDY-025
- BR-STUDY-044
- BR-STUDY-045
- BR-STUDY-051
- BR-STUDY-054
- BR-STUDY-055
- BR-STUDY-056
- BR-STUDY-067
- BR-STUDY-072
- BR-STUDY-074

## FN-STUDY-002 — Mở phiên học mới
Status: active · Code: [lib/features/study/domain/usecases/open_learning_session_use_case.dart]

### Precondition

Deck tồn tại, đang active, và cây của nó còn thẻ chưa học. Chỉ một hành động học tường minh của
người dùng tạo phiên; badge, danh sách và thông báo không tạo phiên.

### Input

- Deck.

### Kết quả

Trong một transaction:

- phiên `in_progress` đang mở của app, nếu có, được đóng: `abandoned` với `end_reason = user_exit`
  nếu nó bắt đầu trong ngày học hiện tại, `interrupted` nếu ở một ngày học trước;
- lấy tối đa `card_limit` thẻ chưa học, theo `new_card_order` của tuỳ chọn hiệu lực (`created`
  lấy thẻ cũ nhất, `random` lấy một tập con);
- tạo `study_session` với `session_kind = 'learning'`, mang `root_id` và generation hiện tại của
  root, ghi `card_limit` đã dùng (không đổi theo cấu hình về sau), và ghi tường minh mode đang
  chạy;
- dựng và lưu hàng đợi của stage đầu: chuỗi stage do thuật toán khai báo (`eight_box`:
  `browse → match → guess → recall → fill`; `sm2`: `browse → self_assess`); người dùng không chọn
  stage.

Kết quả trả về id của phiên.

### Lỗi

- `notFound` — deck không còn hoặc đang ở Trash.
- `nothingToLearn` — cây không còn thẻ nào chưa học; không ghi gì.

### Business rules

- BR-MODE-003
- BR-MODE-004
- BR-MODE-007
- BR-MODE-008
- BR-SRS-025
- BR-STUDY-010
- BR-STUDY-012
- BR-STUDY-014
- BR-STUDY-020
- BR-STUDY-021
- BR-STUDY-022
- BR-STUDY-024
- BR-STUDY-051
- BR-STUDY-056
- BR-STUDY-057
- BR-STUDY-072

## FN-STUDY-003 — Mở phiên ôn tập
Status: active · Code: [lib/features/study/domain/usecases/open_review_session_use_case.dart, lib/features/study/domain/models/queue_plan_model.dart]

### Precondition

Deck tồn tại, đang active, và cây của nó có ít nhất một thẻ đến hạn. Chỉ một hành động học tường
minh của người dùng tạo phiên.

### Input

- Deck.
- Mode ôn tập, một trong các mode thuật toán của root cung cấp.
- Chiều hỏi — `term first`, `meaning first` hoặc `mixed` — khi và chỉ khi mode nhận chiều
  (`self_assess` của `sm2`).

### Kết quả

Hệ thống đọc lại điều kiện **trong** transaction, rồi:

- đóng phiên `in_progress` đang mở của app, nếu có, như khi mở phiên học mới;
- lấy **toàn bộ** thẻ đến hạn theo `due_at` tăng dần, tối đa `card_limit`;
- tạo `study_session` với `session_kind = 'reviewing'`, mang `root_id` và generation hiện tại,
  ghi `card_limit` đã dùng, mode, và chiều đã chọn;
- dựng và lưu hàng đợi trong cùng transaction; với chiều, mỗi dòng nhận một chiều: cùng một chiều
  cho hai lựa chọn cố định, hoặc chia gần đều một lần lúc mở cho `mixed`; chiều của mỗi dòng không
  đổi suốt phiên, kể cả khi thẻ quay lại.

Chiều hỏi không đổi lịch hay nội dung thẻ. Kết quả trả về id của phiên.

### Lỗi

- `notFound` — deck không còn hoặc đang ở Trash.
- `nothingDue` — không còn thẻ nào đến hạn; không ghi gì.
- `modeNotOffered` — thuật toán của root không cung cấp mode đó (ví dụ scheduler vừa đổi); không
  ghi gì.
- `modeUnavailable` — mode không chạy được trên các thẻ sẽ lấy; không ghi gì.
- `directionRequired` — mode nhận chiều nhưng không có chiều: lỗi validation; không ghi gì.
- `directionNotAllowed` — có chiều cho một mode không nhận chiều: xung đột; không ghi gì.

### Business rules

- BR-MODE-009
- BR-MODE-013
- BR-MODE-015
- BR-MODE-016
- BR-MODE-017
- BR-MODE-018
- BR-MODE-019
- BR-SRS-025
- BR-STUDY-002
- BR-STUDY-003
- BR-STUDY-020
- BR-STUDY-021
- BR-STUDY-024
- BR-STUDY-044
- BR-STUDY-045
- BR-STUDY-054
- BR-STUDY-055
- BR-STUDY-072

## FN-STUDY-004 — Xem một phiên học
Status: active · Code: [lib/features/study/domain/usecases/watch_study_session_use_case.dart]

### Precondition

Không có.

### Input

- Phiên.

### Kết quả

Một luồng của phiên, phát lại sau mỗi lượt: loại phiên, mode và stage đang chạy, tiến độ, và lượt
đang phục vụ, đúng như mode của nó dựng:

- `browse`: hai mặt của thẻ, không sinh action; xem lại được các thẻ đã qua;
- `self_assess`: đề theo chiều của dòng (nửa trên), đáp án sau khi lật (nửa dưới); các action là
  `supportedActions` của thuật toán — 2 với `eight_box`, 4 với `sm2`;
- `match`: một bàn tối đa 5 cặp, ít nhất 2 cặp, hai hoán vị độc lập của term và nghĩa;
- `guess`: đúng 5 lựa chọn, distractor lấy từ nguồn quy định, khác nghĩa đo bằng mặt sau đã gập;
  câu thiếu lựa chọn thì bị chặn hoặc stage bị bỏ qua theo quy định;
- `recall`: 20 giây tương tác, thời gian còn lại và trạng thái lật đã lưu;
- `fill`: đề là mặt sau, người dùng gõ mặt trước; gợi ý khi thẻ có.

Kết quả của một lượt chỉ hiện sau khi lượt đã được ghi, và đơn vị học ở lại giữa hai lượt. Khi
deck vào Trash hoặc phiên không còn, luồng báo `notFound`. Không ghi gì.

### Lỗi

- `notFound` — phiên không còn, hoặc deck của nó đang ở Trash.
- Đọc database thất bại — lý do có kiểu (ADR-016), đọc lại được.

### Business rules

- BR-MODE-002
- BR-MODE-005
- BR-MODE-006
- BR-MODE-014
- BR-STUDY-009
- BR-STUDY-026
- BR-STUDY-031
- BR-STUDY-036
- BR-STUDY-037
- BR-STUDY-038
- BR-STUDY-039
- BR-STUDY-040
- BR-STUDY-043
- BR-STUDY-045
- BR-STUDY-048
- BR-STUDY-049
- BR-STUDY-063
- BR-STUDY-064
- BR-STUDY-066
- BR-TRASH-002

## FN-STUDY-005 — Trả lời một lượt học
Status: active · Code: [lib/features/study/domain/usecases/answer_study_turn_use_case.dart]

### Precondition

Phiên đang `in_progress` và đang phục vụ đúng thẻ được trả lời.

### Input

- Phiên.
- Thẻ.
- Câu trả lời đúng loại của mode đang chạy: một action của `supportedActions` (`self_assess`),
  một lựa chọn theo định danh (`guess`), một cặp của bàn hiện tại (`match`), tự đánh giá sau khi
  lật hoặc hết giờ (`recall`), một chuỗi gõ (`fill`), hoặc đi tiếp (`browse`).

### Kết quả

Trong một transaction, ghi ngay, không chờ hết phiên:

1. So `session.generation` với generation hiện tại của root; lệch thì từ chối như ở mục Lỗi.
2. Chấm lượt: `self_assess` lấy action trực tiếp từ người dùng; bốn mode chấm điểm chấm ra kết quả
   **nhị phân** rồi ánh xạ sang action theo thuật toán (`eight_box`). Mức phản hồi không đúng là
   sai. `guess` đánh giá lựa chọn bằng định danh và chỉ nhận lựa chọn đầu tiên; một lượt `match`
   thuộc thẻ sở hữu term; `fill` so khớp theo phiên bản chính sách so khớp đã lưu và không lưu nội
   dung đã gõ; câu trả lời rỗng sau khi gập không sinh lượt; `recall` nhận tối đa một đáp án mỗi
   lượt, và hết giờ khoá kết cục sai cùng lý do hết giờ. Không lưu nhãn màn hình.
3. Xác định `kind` và ghi tường minh: phiên `learning` ⇒ `learning`, hoặc `relearning` ở lượt lặp
   trong round, **không đổi lịch**; phiên `reviewing` ⇒ `scheduled` ở lượt đầu của thẻ,
   `relearning` ở các lượt lặp.
4. Lượt `scheduled` tính trạng thái mới bằng thuật toán (`eight_box`: chuyển box và bảng
   interval; `sm2`: thang chất lượng, interval, repetitions, ease factor) và cập nhật study state,
   `answer_count`, `lapse_count`. Lượt `learning` và `relearning` chỉ cập nhật `last_answered_at`.
   Chiều hỏi không đổi lịch.
5. Ghi một dòng `review_log` mang `kind`, mode, chiều (chép từ dòng hàng đợi), `scheduler_type` và
   `generation` tại thời điểm đó.
6. **Chỉ ở phiên `learning`:** thẻ đi hết stage cuối mà chính nó tham gia (stage bỏ qua nó không
   tính) ⇒ đặt `learned_at` và khởi tạo lịch ở mức thấp nhất (`eight_box` box 1, `sm2` interval 1),
   `due_at` là đầu ngày học kế tiếp — một sự kiện, không phải một lượt đánh giá. Nếu đó là thẻ
   đầu tiên của root hoàn tất chuỗi học mới ở generation này, đặt `first_answered_at`: chế độ ôn
   tập khoá từ đây.
7. Hàng đợi: action khác `forgotten`/`again` ⇒ thẻ rời hàng đợi. Với `self_assess`, thẻ
   `forgotten`/`again` quay lại cùng hàng đợi sau ít nhất 3 thẻ khác (hoặc cuối hàng đợi), trần 3
   lượt `relearning`; chạm trần thì thẻ rời hàng đợi và cờ của thẻ được bật, không bao giờ tự tắt.
   Với bốn mode chấm điểm, thẻ sai ở lại tập không đạt của round — kể cả khi sau đó làm đúng — và
   round mới chỉ dựng từ tập đó, với thứ tự xáo riêng, không trần; tập rỗng thì stage hoàn tất.
8. Phiên `learning` hết hàng đợi của một stage ⇒ chuyển `current_mode` sang stage kế, trên cùng tập
   thẻ, với thứ tự xáo riêng; thẻ thiếu dữ liệu cho stage được bỏ qua có ghi nhận, vẫn có ở stage
   khác. Hết stage cuối, hoặc hết hàng đợi của phiên `reviewing` ⇒ phiên `completed`,
   `end_reason = NULL`, `ended_at` được đặt.

Kết quả trả về kết quả của lượt để hiển thị sau khi đã ghi.

### Lỗi

- `staleGeneration` — root bị đặt lại sau khi phiên mở: không ghi phần nào của lượt; phiên thành
  `invalidated`, `end_reason = stale_generation`.
- `sessionClosed` — phiên đã kết thúc.
- `notFound` — phiên, deck hoặc thẻ không còn.
- `notCurrentCard` — câu trả lời gọi tên một thẻ phiên không phục vụ.
- `answerDoesNotFitMode` — câu trả lời thuộc loại của mode khác.
- `unsupportedAction` — action không có trong `supportedActions`.
- `emptyAnswer` — `fill`: không còn gì sau khi gập.
- `notRevealed` — `recall`: tự đánh giá trước khi mở đáp án.
- `alreadyRevealed` — `recall`: hết giờ sau khi đã mở đáp án.
- `questionBlocked` — `guess`: câu thiếu lựa chọn; stage dừng ở đây tới khi người dùng rời.
- `notAnOption` — `guess`: thẻ được chọn không phải một lựa chọn.
- `notOnBoard` — `match`: nghĩa không phải một cặp chưa nối của bàn hiện tại.
- Database bận — không ghi gì, phiên vẫn `in_progress`; thử lại đúng câu trả lời đó thì lượt được
  ghi đúng một lần, và thẻ không chuyển khi chưa ghi được.
- Lỗi ghi khác — lượt rollback; phiên thành `failed`, `end_reason = persistence_error`, trong một
  lần ghi riêng; các lượt đã ghi trước vẫn giữ.

### Business rules

- BR-CARD-009
- BR-MODE-002
- BR-MODE-003
- BR-MODE-004
- BR-MODE-007
- BR-MODE-008
- BR-MODE-009
- BR-MODE-011
- BR-MODE-012
- BR-MODE-016
- BR-MODE-019
- BR-SRS-003
- BR-SRS-008
- BR-SRS-009
- BR-SRS-010
- BR-SRS-011
- BR-SRS-012
- BR-SRS-014
- BR-SRS-015
- BR-SRS-016
- BR-SRS-017
- BR-SRS-018
- BR-SRS-019
- BR-SRS-026
- BR-STUDY-004
- BR-STUDY-005
- BR-STUDY-006
- BR-STUDY-007
- BR-STUDY-009
- BR-STUDY-010
- BR-STUDY-012
- BR-STUDY-013
- BR-STUDY-017
- BR-STUDY-018
- BR-STUDY-019
- BR-STUDY-022
- BR-STUDY-023
- BR-STUDY-027
- BR-STUDY-029
- BR-STUDY-030
- BR-STUDY-032
- BR-STUDY-033
- BR-STUDY-034
- BR-STUDY-035
- BR-STUDY-040
- BR-STUDY-041
- BR-STUDY-042
- BR-STUDY-052
- BR-STUDY-053
- BR-STUDY-058
- BR-STUDY-059
- BR-STUDY-060
- BR-STUDY-061
- BR-STUDY-062
- BR-STUDY-063
- BR-STUDY-069
- BR-STUDY-070
- BR-STUDY-071
- BR-STUDY-073
- BR-STUDY-074

## FN-STUDY-006 — Mở đáp án của lượt recall
Status: active · Code: [lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart]

### Precondition

Phiên `in_progress` ở mode `recall`, đang phục vụ thẻ này, thời gian chưa hết.

### Input

- Phiên.
- Thẻ.
- Thời gian còn lại, trong khoảng 0 tới 20 giây.

### Kết quả

Thời gian dừng, đáp án mở, và lượt chờ người dùng tự đánh giá. Mở đáp án không phải kết cục của
lượt: không ghi `review_log` nào.

### Lỗi

- `notFound`, `sessionClosed`, `staleGeneration`, `notCurrentCard` — như khi trả lời một lượt.
- `answerDoesNotFitMode` — mode đang chạy không phải `recall`.

### Business rules

- BR-STUDY-031
- BR-STUDY-036
- BR-STUDY-065

## FN-STUDY-007 — Lưu thời gian còn lại của lượt recall
Status: active · Code: [lib/features/study/domain/usecases/save_recall_time_use_case.dart]

### Precondition

Phiên `in_progress` ở mode `recall`, đang phục vụ thẻ này.

### Input

- Phiên.
- Thẻ.
- Thời gian còn lại, trong khoảng 0 tới 20 giây.

### Kết quả

Thời gian còn lại của lượt được lưu, để tiếp tục phiên lấy lại đúng chỗ dừng. Được ghi khi app vào
nền và khi màn phiên đóng, không ghi mỗi nhịp đồng hồ.

### Lỗi

- `notFound`, `sessionClosed`, `staleGeneration`, `notCurrentCard`, `answerDoesNotFitMode` — như
  khi mở đáp án.

### Business rules

- BR-STUDY-031
- BR-STUDY-036

## FN-STUDY-008 — Hiện gợi ý của lượt fill
Status: active · Code: [lib/features/study/domain/usecases/show_fill_hint_use_case.dart]

### Precondition

Phiên `in_progress` ở mode `fill`, đang phục vụ thẻ này, và thẻ có gợi ý.

### Input

- Phiên.
- Thẻ.

### Kết quả

Lượt ghi nhận rằng gợi ý đã được hiện; kết quả của lượt không vì thế mà đổi.

### Lỗi

- `noHint` — thẻ không có gợi ý.
- `notFound`, `sessionClosed`, `staleGeneration`, `notCurrentCard`, `answerDoesNotFitMode` — như
  khi trả lời một lượt.

### Business rules

- BR-STUDY-028

## FN-STUDY-009 — Rời phiên học
Status: active · Code: [lib/features/study/domain/usecases/abandon_study_session_use_case.dart]

### Precondition

Phiên đang `in_progress`.

### Input

- Phiên.

### Kết quả

Phiên thành `abandoned`, `end_reason = user_exit`, `ended_at` được đặt. Mọi lượt đã ghi vẫn giữ.

### Lỗi

- `notFound` — phiên không còn.
- `sessionClosed` — phiên đã kết thúc.

### Business rules

- BR-STUDY-004
- BR-STUDY-012
- BR-STUDY-014
- BR-STUDY-019

## FN-STUDY-010 — Tiếp tục một phiên đang dở
Status: active · Code: [lib/features/study/domain/usecases/resume_study_session_use_case.dart]

### Precondition

Phiên đang `in_progress`.

### Input

- Phiên.

### Kết quả

Phiên của **cùng ngày học** tiếp tục đúng hàng đợi đã lưu: đúng thẻ đang dở, đúng thứ tự, đúng số
lượt đã dùng, cùng chiều hỏi, thời gian còn lại và trạng thái lật đã lưu; không hỏi lại chiều.

### Lỗi

- `sessionExpired` — phiên mở ở một ngày học trước: nó được đóng `abandoned`,
  `end_reason = interrupted`, và người dùng dựng phiên mới.
- `staleGeneration` — root bị đặt lại sau khi phiên mở: phiên thành `invalidated`.
- `notFound` — phiên hoặc deck không còn (ví dụ deck vào Trash: phiên đã kết thúc với
  `content_deleted`).
- `sessionClosed` — phiên đã kết thúc.

### Business rules

- BR-MODE-017
- BR-STUDY-017
- BR-STUDY-021
- BR-STUDY-036
- BR-STUDY-072

## FN-STUDY-011 — Đóng các phiên của ngày học trước khi app mở
Status: active · Code: [lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart]

### Precondition

App vừa khởi động.

### Input

Không có.

### Kết quả

Mọi phiên còn `in_progress` mở ở một ngày học trước thành `abandoned`, `end_reason = interrupted`.
App bị hệ điều hành thu hồi rơi vào đúng trường hợp này, và nó khác `user_exit`: người dùng không
hề bỏ cuộc.

### Lỗi

Không áp dụng — không có phiên nào như vậy thì không ghi gì.

### Business rules

- BR-STUDY-012
- BR-STUDY-072

## FN-STUDY-012 — Xem tab Study
Status: active · Code: [lib/features/study/domain/usecases/watch_study_home_use_case.dart]

### Precondition

Không có.

### Input

Không có.

### Kết quả

Một luồng, phát lại sau mỗi lần ghi nó thấy và mỗi nửa đêm theo giờ local, đọc **một snapshot**
trong một transaction:

- phiên có thể tiếp tục: đúng một phiên hợp lệ đang mở, với deck, `kind` và mode lấy từ chính hàng
  session (kể cả khi phiên mở trên deck con); không có phiên nào khi phiên đã kết thúc, thuộc ngày
  học cũ, hết hàng đợi, thuộc generation cũ, hay deck hoặc thẻ đã bị xoá;
- mọi root deck với tên, chế độ ôn tập khi biết, và ba con số Overdue, Due today, New; thứ tự giảm
  dần theo Overdue, rồi Due today, rồi New (không theo tổng), hoà thì theo tên đã gập rồi `id`;
- trạng thái của thư viện: chưa có deck; có deck nhưng chưa có card (không có con số nào); hoặc có
  card — kể cả khi mọi deck đều không còn gì đến hạn.

Việc đọc không ghi gì, kể cả khi còn phiên của ngày trước đang mở: đóng phiên cũ chỉ xảy ra khi
người dùng thực sự vào học.

### Lỗi

- Đọc database thất bại — lý do có kiểu (ADR-016), đọc lại được; không có gì bị thay đổi.

### Business rules

- BR-MODE-008
- BR-PROGRESS-011
- BR-SRS-015
- BR-STUDY-008
- BR-STUDY-017
- BR-STUDY-051
- BR-STUDY-068
- BR-STUDY-072
- BR-STUDY-074
- BR-STUDY-075
- BR-STUDY-076
- BR-STUDY-077

## FN-STUDY-013 — Xem trước khoảng ôn của từng mức tự đánh giá
Status: active · Code: [lib/features/study/domain/usecases/preview_self_assess_intervals_use_case.dart]

### Precondition

Phiên `self_assess`.

### Input

- Loại phiên, thẻ, round, và số lượt đã trả lời trong phiên.

### Kết quả

Ở một lượt `scheduled`: khoảng ôn mà mỗi mức tự đánh giá sẽ cho thẻ. Ở một lượt `learning` hay
`relearning`, hay khi thẻ không còn: không có gì, vì câu trả lời đó không đổi lịch. Không ghi gì.

### Lỗi

Không áp dụng — trường hợp không có khoảng ôn cho kết quả rỗng.

### Business rules

- BR-SRS-009
- BR-SRS-011
- BR-SRS-016
- BR-SRS-017
