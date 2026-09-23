---
id: BR-STUDY-051
title: Hai loại phiên learning và reviewing
status: active
summary: Có đúng hai loại phiên: `learning` lấy thẻ chưa học xong, `reviewing` lấy thẻ đã học và đến hạn.
superseded_by:
---
## Rule

MUST có đúng hai loại phiên, lưu trên `study_session.session_kind`: **`learning`** lấy thẻ `learned_at IS NULL`, và **`reviewing`** lấy thẻ `learned_at IS NOT NULL AND due_at <= now`. Một phiên MUST NOT trộn hai tập.

**Enforced by:** db
**Liên quan:** BR-STUDY-002, BR-STUDY-053

## Lý do

**BR-STUDY-001 bị thay, và điều đó chạm tới code đang chạy.** Định nghĩa cũ — `due_at IS
NULL OR due_at <= now` — đang được badge trên deck list, pill Due/New trên card
list và query `cardsDueForStudy` implement. Trong mô hình mới, `due_at IS NULL`
không còn nghĩa "đến hạn ngay" mà nghĩa "chưa học xong", nên một con số gom cả
hai đang trộn hai việc có chi phí khác hẳn nhau: 20 thẻ mới tốn gấp năm lần 20
thẻ ôn. BR-STUDY-046 và BR-STUDY-047 đưa hai con số đó về đúng ngôn ngữ mà popup Study dùng.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
