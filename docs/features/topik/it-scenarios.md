# topik — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

Viết từ BR/UC và 12 edge case của [spec](../../superpowers/specs/2026-10-15-topik-practice-design.md) §9, không dựa vào code. Feature chưa xây, nên mọi kịch bản ở mức `KNOWN-GAP`: chạy chỉ để xác nhận khoảng trống, không bao giờ ghi là đạt. Plan của từng màn chuyển kịch bản của nó sang `READY` khi test tương ứng chạy được.

## Nhóm: Kịch bản IT — Luyện đề TOPIK

## IT-TOPIK-001 — Lối vào TOPIK, đếm đề hợp lệ, đề lỗi bị ẩn

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Gói nội dung gồm `topik1-96-reading` hợp lệ, `topik1-96-listening` hợp lệ một bản `topik2-96-reading` có tổng điểm 98 và một bản `topik2-96-listening` thiếu file audio.
- **Liên kết:** UC-TOPIK-001, BR-TOPIK-008.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở tab Học và cuộn tới cuối | Mục Practice có hàng "TOPIK past papers" với số đề hợp lệ (2) |
| 2 | Chạm hàng TOPIK | Màn 34 mở: TOPIK I "… · 2 tests", TOPIK II "No tests yet" không có chevron |
| 3 | Chạm TOPIK II | Không có gì xảy ra (không có vùng chạm) |
| 4 | Chạm TOPIK I | Màn 35 mở ở Reading, có đúng một hàng `#96` |
| 5 | Đọc log | Có `topik.content_rejected` cho `topik2-96-reading` (rule `points`) và `topik2-96-listening` (rule `assets`); app không hiện lỗi nào và không có nút bắt đầu nào dẫn tới lỗi phát |

## IT-TOPIK-002 — Đổi phần thi, thứ tự và trạng thái đề

- **Ưu tiên:** P2
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Như `SETUP-TOPIK-HISTORY`: kỳ 91 và 96; kỳ 96 đọc có một lượt dở và hai lượt đã nộp (88, 80).
- **Liên kết:** UC-TOPIK-001, BR-TOPIK-009, BR-TOPIK-022.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở màn 35 của TOPIK II | Reading; kỳ 96 đứng trước 91; hàng 96 ghi "In progress" và "Best 88 · 2 attempts"; hàng 91 ghi "Not started" |
| 2 | Chọn thứ tự "Oldest round" | 91 đứng trước 96 |
| 3 | Chạm Listening | Danh sách các đề nghe; nhãn thẻ nội dung suy ra từ dữ liệu (có "Script" khi đề có script) |

## IT-TOPIK-003 — Bắt đầu lượt TOPIK I đọc với số câu thật 31–70

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Đề `topik1-96-reading` chưa có lượt nào.
- **Liên kết:** UC-TOPIK-003, BR-TOPIK-001, BR-TOPIK-010.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở màn 36 của đề, chạm FAB | Màn 37 mở; bộ đếm "31 / 70"; lượt `in_progress` có 40 hàng đáp án trống trong database |
| 2 | Mở lưới câu | Ô đầu là 31, ô cuối là 70; không ô nào đã trả lời |

## IT-TOPIK-004 — Đổi đáp án và thời gian cộng dồn

- **Ưu tiên:** P0
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở mới của `topik2-96-reading`; đồng hồ inject.
- **Liên kết:** UC-TOPIK-003 A3, BR-TOPIK-012, BR-TOPIK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở câu 5 40 giây rồi chọn ② | Câu 5 lưu ②, 40 000 ms |
| 2 | Sang câu 6 20 giây | Câu 6 có 20 000 ms; `current_question_no` = 6 |
| 3 | Quay lại câu 5 thêm 10 giây và chọn ④ | Câu 5 lưu ④, 50 000 ms; `total_time_ms` = 70 000; không có thông tin đúng sai nào được lưu |

## IT-TOPIK-005 — Thoát giữa chừng và tiếp tục

- **Ưu tiên:** P0
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở đã trả lời 30 câu, đang ở câu 31.
- **Liên kết:** UC-TOPIK-003 A2, BR-TOPIK-010, BR-TOPIK-011.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đóng database rồi mở lại (giả lập chết tiến trình) | Lượt vẫn `in_progress` với đúng 30 đáp án và thời gian đã ghi |
| 2 | Tiếp tục lượt từ màn 36 | Mở ở câu 31 |
| 3 | Chạm FAB lần nữa | Hỏi Tiếp tục hay Bắt đầu mới; không có lượt dở thứ hai |

## IT-TOPIK-006 — Chuyển nền không cộng thời gian

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở, ở câu 5 được 10 giây; đồng hồ inject.
- **Liên kết:** BR-TOPIK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đưa app về `paused` 5 phút rồi `resumed` | Câu 5 vẫn 10 000 ms cộng phần trước khi chuyển nền |
| 2 | Ở thêm 5 giây rồi sang câu 6 | Câu 5 có 15 000 ms |

## IT-TOPIK-007 — Nộp khi còn câu trống

- **Ưu tiên:** P0
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở của `topik2-96-reading`, 47 câu đã trả lời.
- **Liên kết:** UC-TOPIK-003 A1, BR-TOPIK-013, BR-TOPIK-014.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Nộp | Hỏi "3 questions unanswered" |
| 2 | Chọn Keep answering | Vẫn ở màn 37; lượt vẫn `in_progress` |
| 3 | Chạm Nộp và xác nhận | Màn 38 mở; 3 câu `unanswered`, 0 điểm; lượt `completed` với `answered_count` = 47 |

## IT-TOPIK-008 — Chấm theo 배점 và chốt kết quả

- **Ưu tiên:** P0
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Đề `topik1-96-listening` (câu 1–10 được 4 điểm, còn lại 3).
- **Liên kết:** BR-TOPIK-002, BR-TOPIK-013, BR-TOPIK-019.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đúng câu 1 và 11, sai câu 2, bỏ trống còn lại, nộp | `score` = 7, `max_score` = 100, `correct_count` = 2, `answered_count` = 3; mỗi đáp án có `correct_idx`, `points`, `points_earned`, `question_type` |
| 2 | Lượt khác đúng hết, nộp | `score` = 100 |
| 3 | Lượt khác không trả lời câu nào, nộp | `score` = 0 |
| 4 | Đổi `answerIdx` câu 1 trong nội dung (`contentVersion` 2) rồi đọc lượt đầu | Điểm vẫn 7 (bản chốt không đổi) |
| 5 | Ghi đáp án vào lượt đã nộp | Bị database từ chối; không có gì đổi |

## IT-TOPIK-009 — Chạm Nộp hai lần và Back khi đang nộp

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở đã trả lời đủ; ghi nộp được làm chậm trong test.
- **Liên kết:** BR-TOPIK-014.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Nộp hai lần liên tiếp | Chỉ một lần nộp được ghi; outbox có đúng một thao tác |
| 2 | Nhấn Back trong lúc nộp | Không có tác dụng; sau khi xong mở màn 38 |

## IT-TOPIK-010 — Một lượt dở cho mỗi đề: Tiếp tục hoặc Bắt đầu mới

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Kỳ 96 đọc có một lượt dở ở câu 18.
- **Liên kết:** UC-TOPIK-002 A2, BR-TOPIK-011.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm FAB ở màn 36 | Hộp thoại Tiếp tục / Bắt đầu mới |
| 2 | Chọn Tiếp tục | Màn 37 ở câu 18 |
| 3 | Quay lại, chạm FAB, chọn Bắt đầu mới, huỷ xác nhận | Không đổi gì |
| 4 | Chạm FAB, Bắt đầu mới, xác nhận | Lượt cũ và đáp án của nó bị xoá, lượt mới tạo, trong một transaction; vẫn đúng một lượt dở |

## IT-TOPIK-011 — Xoá lượt dở và lượt đã nộp

- **Ưu tiên:** P0
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Ba lượt: #1 đã nộp, #2 đã nộp, #3 dở.
- **Liên kết:** UC-TOPIK-002, BR-TOPIK-018, BR-TOPIK-021, BR-TOPIK-026.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá #3 (dở) và xác nhận | Lượt và đáp án không còn; outbox không có thao tác nào cho nó |
| 2 | Xoá #1 (đã nộp) và xác nhận | Lượt và đáp án không còn; outbox có một `delete` `topik_attempt`; lượt #2 cũ thành #1; Best, Average tính lại |

## IT-TOPIK-012 — Tổng kết: số câu thật, số lựa chọn, bộ lọc, dạng câu, thời lượng

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Lượt `topik1-96-reading` đã nộp: sai câu 31 (2 điểm) và 45 (3 điểm), tổng thời gian 3 731 000 ms.
- **Liên kết:** UC-TOPIK-004, BR-TOPIK-023, BR-TOPIK-024, BR-TOPIK-025.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Summary | Điểm "95 / 100"; thời lượng "1h 02m 11s"; biểu đồ và bảng bắt đầu từ 31 |
| 2 | Đọc hàng câu 31 | Your và Correct là ①–④, không phải văn bản; trạng thái Wrong |
| 3 | Chọn bộ lọc Wrong | Chỉ còn câu 31 và 45 |
| 4 | Chạm biểu tượng mắt | Cột Correct ẩn; chạm lại thì hiện |
| 5 | Đọc mục By question type | Mỗi dạng có đúng/tổng; dạng yếu nhất được đánh dấu theo BR-TOPIK-024 |

## IT-TOPIK-013 — Ôn lại chỉ đọc, nội dung đã đổi và nội dung không còn

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Một lượt đã nộp chấm trên `contentVersion` 1.
- **Liên kết:** UC-TOPIK-005, BR-TOPIK-006, BR-TOPIK-010, BR-TOPIK-019.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Review ở giao diện tiếng Việt | Giải thích bằng tiếng Việt; lựa chọn đúng và sai được đánh dấu |
| 2 | Chạm một lựa chọn | Không có gì được ghi |
| 3 | Đổi gói sang `contentVersion` 2 và mở lại | Banner "This test was updated after this attempt" |
| 4 | Gỡ đề khỏi gói và mở lại | Review báo không khả dụng; Summary vẫn hiện đủ từ bản chốt |

## IT-TOPIK-014 — Audio của nhóm trong chế độ luyện tập

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở `topik2-96-listening`; trình phát giả (`FakeClipAudioPlayer`).
- **Liên kết:** BR-TOPIK-004, BR-TOPIK-017.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Vào câu 21 | Trình phát nạp đoạn `[startMs, endMs)` của nhóm [21～22]; không tự phát |
| 2 | Phát, tới giây 30, sang câu 22 | Audio vẫn phát tiếp từ giây 30, không nạp lại |
| 3 | Chọn tốc độ 1.5 | Trình phát nhận tốc độ 1.5 |
| 4 | Sang câu 23 | Audio nhóm trước dừng; nhóm mới chưa phát |
| 5 | Làm trình phát báo lỗi | Banner "Couldn't play this audio" với Try again; đáp án không đổi |

## IT-TOPIK-015 — Đồng bộ chỉ lượt đã nộp, một lần, kèm đáp án

- **Ưu tiên:** P0
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Hai máy A và B cùng tài khoản, `FakeSyncServer`.
- **Liên kết:** BR-TOPIK-026, BR-TOPIK-028.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Trên A: bắt đầu và trả lời một lượt, đồng bộ | Outbox không có gì; server không có lượt nào |
| 2 | Trên A: nộp, đồng bộ | Server nhận đúng một `topik_attempt` mang đủ đáp án |
| 3 | Trên B: đồng bộ | B có lượt đó, cùng điểm và đáp án; Overall Progress của B tính cả lượt đó |
| 4 | Trên A: đồng bộ lại | Không gửi gì thêm (idempotent) |
| 5 | Trên B: xoá lượt, đồng bộ; rồi A đồng bộ | Server có tombstone; lượt biến mất trên A |

## IT-TOPIK-016 — Đổi tài khoản xoá dữ liệu TOPIK cục bộ

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-HISTORY`. Máy có hai lượt đã nộp đã đồng bộ và một lượt dở.
- **Liên kết:** BR-TOPIK-027.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đăng xuất (chạy `LocalDataReset`) | Không còn lượt nào trên máy |
| 2 | Đăng nhập lại cùng tài khoản và đồng bộ | Hai lượt đã nộp quay về; lượt dở không quay về |

## IT-TOPIK-017 — Mọi thao tác TOPIK chạy khi không có mạng

- **Ưu tiên:** P1
- **Hồ sơ:** `HOST-FLOW`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Không có mạng (API đồng bộ luôn lỗi mạng).
- **Liên kết:** ADR-013, BR-TOPIK-026.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu, trả lời, nộp, xem Summary, xoá một lượt | Mọi bước thành công cục bộ; outbox giữ các thao tác chờ |
| 2 | Có mạng lại, đồng bộ | Các thao tác chờ đi lên server |

## IT-TOPIK-018 — Đổi ngôn ngữ giữa lượt làm bài

- **Ưu tiên:** P2
- **Hồ sơ:** `HOST-WIDGET`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Lượt dở ở câu 9 với hai đáp án đã chọn.
- **Liên kết:** UC-TOPIK-003 A4.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đổi ngôn ngữ app từ en sang vi | Nhãn đổi sang tiếng Việt; nội dung tiếng Hàn giữ nguyên; vẫn ở câu 9 với hai đáp án; thời gian không mất |

## IT-TOPIK-019 — Phát đoạn audio thật trên thiết bị

- **Ưu tiên:** P2
- **Hồ sơ:** `DEVICE-E2E`
- **Tiền điều kiện:** `SETUP-TOPIK-PACK`. Bản dựng phát triển có gói `topik2-96-listening` thật hoặc gói fixture có file audio.
- **Liên kết:** BR-TOPIK-017.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Vào câu 21, chạm Phát | Chỉ đoạn của nhóm [21～22] phát; dừng ở `endMs` |
| 2 | Đổi tốc độ 0.75 và 1.5 | Tốc độ nghe đổi tương ứng, không méo đoạn |
| 3 | Tua tới cuối đoạn | Dừng ở cuối đoạn, không phát sang nhóm sau |
