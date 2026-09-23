---
feature: starter-decks
code: []
depends_on: [card, deck]
---
## Phạm vi

**Phạm vi:** sub-project sau — Starter decks (spec §2).

Starter deck / template: thư viện starter và sao chép một template vào dữ liệu cá nhân.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Thư viện starter (child flow trong tab Thư viện; empty state khi chưa có deck) | UC-STARTER-001 |

Nguồn: trigger của UC-STARTER-001 ("Mở app lần đầu sau khi cài"); [`shared/ui/navigation.md`](../../shared/ui/navigation.md) mục "Điều hướng top-level" ("Thư viện starter (M6) là child flow bên trong tab Thư viện").

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Nội dung từ vựng production | Dự án chưa có nguồn nội dung có bản quyền rõ ràng (BR-STARTER-010) |
