---
feature: starter-decks
code: [lib/features/starter_decks/domain, lib/features/starter_decks/data, lib/features/starter_decks/di, lib/features/starter_decks/presentation]
depends_on: [card, deck]
---
## Phạm vi

**Phạm vi:** Starter library, phần store (BE-B4,
[spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn: SCR-STARTER-001 (FE-B4).

Starter deck / template: thư viện starter và sao chép một template vào dữ liệu cá nhân.
Template là asset JSON đi kèm bản build (xem [`data.md`](data.md)); bản sao được ghi bởi
chính các feature sở hữu bảng (deck, card, srs) trong một transaction.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nội dung từ vựng production | Dự án chưa có nguồn nội dung có bản quyền rõ ràng (BR-STARTER-010) |
