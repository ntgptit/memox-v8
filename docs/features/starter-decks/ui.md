# Starter decks — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 03 · Starter decks | `/decks/starter`, toàn màn hình trên root navigator, không có bottom bar | Hành động Starter decks trên app bar của Thư viện; "Browse starter decks" khi Thư viện trống | [03-starter-decks.md](../../shared/ui/screen-handoff/03-starter-decks.md) |

Open trên toast "Added" đi tới deck gốc mới trong Thư viện; "Create a deck" (bản build
không có template) quay về Thư viện và mở hộp thoại tạo deck. Nguồn: [spec FE-B2 +
FE-B4](../../superpowers/specs/2026-09-27-tags-starter-ui-design.md) §3 (D5, D6, D7),
§5.1.

## Edge case chưa gắn BR

| Case | Expected behaviour |
|---|---|
| Mở app lần đầu | Hiện thư viện starter deck để chọn. Không tự chèn vào dữ liệu người dùng |

> ⚠️ OPEN QUESTION: 1 dòng edge case trên không trích BR nào trong nguồn. (Plan Q5)
