---
id: BR-MODE-015
title: Chiều của phiên và mixed
status: active
summary: Chiều của phiên là một trong ba; `mixed` gán chiều từng thẻ một lần lúc tạo hàng đợi, lệch không quá một.
superseded_by:
---
## Rule

Lựa chọn ở mức **phiên** MUST là một trong ba: `korean_to_meaning`, `meaning_to_korean`, `mixed`. Với `mixed`, chiều thật của từng thẻ MUST được gán **đúng một lần**, tại thời điểm materialize hàng đợi, bằng nguồn ngẫu nhiên **được tiêm**, và MUST lưu trên từng dòng `study_queue_items`. Số thẻ hai chiều MUST lệch nhau **không quá một**. Chiều đã gán MUST giữ nguyên qua comeback (BR-STUDY-005), retry, Resume (BR-STUDY-072) và restart tiến trình; MUST NOT gieo lại từ seed hay tính lại lúc render. Giá trị `mixed` MUST NOT xuất hiện trên một dòng hàng đợi hay một dòng lịch sử.

**Enforced by:** db + rule
**Liên quan:** BR-STUDY-005, BR-STUDY-021, BR-STUDY-072, BR-STUDY-043, BR-MODE-013

## Lý do

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

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Phiên `mixed` có số thẻ lẻ | Lệch tối đa một thẻ; bên nhận thẻ lẻ rút ngẫu nhiên (BR-MODE-015) |
