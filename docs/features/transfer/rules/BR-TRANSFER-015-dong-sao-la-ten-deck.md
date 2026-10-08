---
id: BR-TRANSFER-015
title: Dòng sao là tên deck
status: active
summary: Dòng dữ liệu có ô `front` bắt đầu bằng `*` đặt tên một deck con; các dòng dưới nó là card của deck đó.
superseded_by:
---
## Rule

Một **dòng dữ liệu** (dòng header không bao giờ tính) MUST được coi là **dòng sao** khi ô của cột map vào `front`, sau trim, bắt đầu bằng `*`; các ô khác của dòng sao MUST bị bỏ qua và dòng sao MUST NOT thành card, MUST NOT tính là dòng trống. Tên deck là phần sau `*` đã trim và MUST thoả BR-DECK-020; tên không hợp lệ thì mọi dòng card dưới nó MUST invalid với lý do tên deck. Hai dòng sao có tên trùng nhau sau fold (trim, NFC, chữ thường) MUST là một nhóm: các dòng dưới dòng sao sau nối tiếp nhóm đầu, giữ chính tả của dòng sao đầu. Nhóm không còn card nào để ghi MUST NOT tạo deck. Dòng card nằm trước dòng sao đầu tiên thuộc **deck mặc định** (EN "Uncategorized", VI "Chưa phân loại"), tên sửa được trên Preview và cũng theo BR-DECK-020. Nguồn không có dòng sao nào là nguồn **phẳng** và import như trước. Quy tắc áp dụng cho XLSX, CSV, TSV và văn bản dán. Không có cấp lồng: `**x` là deck tên `*x`. Một card có `front` bắt đầu bằng `*` không import được.

**Enforced by:** rule
**Liên quan:** BR-DECK-020, BR-DECK-021, BR-TRANSFER-001, BR-TRANSFER-003, BR-TRANSFER-004

## Lý do

Chủ dự án soạn từ vựng theo nhóm trong một sheet, mỗi nhóm mở đầu bằng một dòng `*Tên nhóm` (spec 2026-10-08).

## Ví dụ

| front | back |
|---|---|
| \*Part 1 | \*Part 1 |
| 가난하다 | Be poor |
| \*관용어 | \*관용어 |
| 눈이 높다 | Standards are high |

→ hai deck con `Part 1` (1 card) và `관용어` (1 card).

## Edge case

| Case | Expected behaviour |
|---|---|
| `  *Part 1` có khoảng trắng đầu | Dòng sao tên `Part 1` (BR-TRANSFER-015) |
| `*` đứng một mình | Dòng sao tên rỗng; mọi card dưới nó invalid (BR-TRANSFER-015, BR-DECK-020) |
| `*A`, …, `*B`, …, `*a` | Một deck `A` chứa cả hai đoạn, đúng thứ tự nguồn (BR-TRANSFER-015) |
| Dòng sao không có card nào dưới nó | Không tạo deck (BR-TRANSFER-015) |
