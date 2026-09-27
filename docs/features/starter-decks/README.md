---
feature: starter-decks
code: [lib/features/starter_decks/domain, lib/features/starter_decks/data, lib/features/starter_decks/di]
depends_on: [card, deck]
---
## Phạm vi

**Phạm vi:** Starter library, phần store (BE-B4,
[spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md)). Màn 03 thuộc FE-B4.

Starter deck / template: thư viện starter và sao chép một template vào dữ liệu cá nhân.
Template là asset JSON đi kèm bản build (xem [`data.md`](data.md)); bản sao được ghi bởi
chính các feature sở hữu bảng (deck, card, srs) trong một transaction.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Thư viện starter (child flow trong tab Thư viện; empty state khi chưa có deck) | UC-STARTER-001 |

Nguồn: trigger của UC-STARTER-001 ("Mở app lần đầu sau khi cài"); [`shared/ui/navigation.md`](../../shared/ui/navigation.md) mục "Điều hướng top-level" ("Thư viện starter (M6) là child flow bên trong tab Thư viện").

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nội dung từ vựng production | Dự án chưa có nguồn nội dung có bản quyền rõ ràng (BR-STARTER-010) |
