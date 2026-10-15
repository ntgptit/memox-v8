---
id: BR-TOPIK-004
title: Nhóm câu và đoạn audio của nhóm
status: active
summary: Mỗi câu thuộc đúng một nhóm; nhóm mang chỉ thị, đoạn văn và đoạn audio dùng chung; đề nghe có đoạn audio cho mọi nhóm và số lần phát theo bảng.
superseded_by:
---
## Rule

Một nhóm (`QuestionGroup`, ví dụ `[21～22]`) MUST liệt kê đúng các câu thuộc nó; mỗi câu MUST thuộc đúng một nhóm; `groupId` không trùng.

Đề nghe MUST có file audio của phần thi, và mỗi nhóm MUST có đoạn `[startMs, endMs)` với `0 ≤ startMs < endMs` trong file đó, cùng `playCount`:

| Cấp | Câu | Số lần phát khi thi thật |
|---|---|---|
| TOPIK I | 1–30 | 2 |
| TOPIK II | 1–20 | 1 |
| TOPIK II | 21–50 | 2 |

Bảng số lần phát **chờ đối chiếu** với file 듣기 của kỳ 96; lệch thì lint thất bại và báo chủ dự án. `playCount` chỉ dùng ở Exam mode (BR-TOPIK-032); Practice mode phát tự do (BR-TOPIK-017).

**Enforced by:** rule
**Liên quan:** BR-TOPIK-008, BR-TOPIK-017, BR-TOPIK-032

## Lý do

Đề thật đặt nhiều câu trên một đoạn hội thoại hoặc đoạn văn; tách nhóm khỏi câu cho phép hiện tài liệu dùng chung một lần và phát đúng một đoạn audio.

## Ví dụ

Nhóm `g21-22` có `questionNos [21, 22]`, audio 812000–905000 ms, `playCount 2`.

## Edge case

Câu 23 không thuộc nhóm nào, hoặc nhóm nghe thiếu `audio`, làm đề bị loại khi nạp.
