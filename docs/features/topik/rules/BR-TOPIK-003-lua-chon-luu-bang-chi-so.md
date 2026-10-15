---
id: BR-TOPIK-003
title: Lựa chọn lưu bằng chỉ số 1–4
status: active
summary: Mỗi câu có đúng bốn lựa chọn chỉ số 1–4; đáp án đúng và đáp án người dùng chọn đều lưu bằng chỉ số, khớp ①–④ của 정답표.
superseded_by:
---
## Rule

Mỗi câu MUST có đúng bốn lựa chọn, `idx` 1–4 mỗi số một lần, mỗi lựa chọn có văn bản hoặc ảnh. `answerIdx` MUST thuộc 1–4. Lựa chọn của người dùng lưu bằng chỉ số (`selected_idx`), không bao giờ bằng văn bản.

Đề MUST ghi `form` (ví dụ `B-홀수형`): các bản 홀수형/짝수형 cùng câu hỏi có thể khác thứ tự lựa chọn, nên đáp án chỉ đúng với đúng bản đề.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-013, BR-TOPIK-023

## Lý do

Chỉ số là thứ 정답표 chính thức dùng, nên đối chiếu được trực tiếp; văn bản đáp án đổi theo bản dịch và không so được.

## Ví dụ

Người dùng chọn ③ ở câu 21: `selected_idx = 3`; cột Your trong Summary hiện ③.

## Edge case

Câu có ba lựa chọn, hai lựa chọn cùng `idx 2`, hoặc `answerIdx = 5` làm đề bị loại khi nạp.
