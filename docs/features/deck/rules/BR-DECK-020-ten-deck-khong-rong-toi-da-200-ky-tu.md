---
id: BR-DECK-020
title: Tên deck không rỗng, tối đa 32 ký tự
status: active
summary: Tên deck không rỗng sau trim, tối đa 32 ký tự hiển thị và 128 code point; khuyến nghị 15–25 ký tự.
superseded_by:
---
## Rule

Deck MUST có tên không rỗng sau khi trim, tối đa **32 ký tự hiển thị** (grapheme cluster) và tối đa **128 code point** ở dạng lưu (trim, NFC). Khuyến nghị 15–25 ký tự; hộp tạo và đổi tên hiện bộ đếm "{n} / 32" từ ký tự thứ 26, báo lỗi ngay khi gõ quá giới hạn và khoá nút xác nhận, không chặn gõ và không cắt khi dán. Luật áp dụng cho mọi đường ghi tên: tạo root deck, tạo deck con, đổi tên, section import tạo deck mới, bản copy starter (root lấy tiêu đề template). Tên kéo về từ server MUST NOT bị kiểm, để sync không bao giờ kẹt. Server giữ trần `char_length(name) <= 128` (`20261021000000_deck_name_length.sql`).

**Enforced by:** rule + DB (server)
**Liên quan:** BR-DECK-021, BR-TRANSFER-015

## Lý do

Giảm mật độ thông tin trên danh sách, tiêu đề và sheet (chủ dự án 2026-10-21). Postgres không đếm được grapheme nên server chỉ giữ trần code point; app đếm cả hai nên không bao giờ ghi một tên mà server từ chối.

## Ví dụ

- "Từ vựng tiếng Hàn sơ cấp bài mườ" (32 ký tự): hợp lệ.
- 33 chữ "a": quá dài.
- 26 emoji gia đình "👨‍👩‍👧" (26 ký tự, 130 code point): quá dài vì vượt 128 code point.

## Edge case

Tên dài hơn trước thay đổi này được migration v17 → v18 cắt về đoạn đầu dài nhất gồm các ký tự nguyên vẹn trong cả hai giới hạn, bỏ khoảng trắng ở cuối, kể cả deck trong Trash; mỗi lần cắt được ghi log tên cũ → mới và đưa vào hàng đợi sync (spec `2026-10-21-deck-name-32-design.md` §5). Không còn ngoại lệ cho tên cũ.
