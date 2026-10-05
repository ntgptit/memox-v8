# Tags — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Màn hình và điều hướng

| Màn | Route | Mở từ | Handoff |
|---|---|---|---|
| 05 · Tags | `/decks/tags`, toàn màn hình trên root navigator, không có bottom bar | Hành động Tags trên app bar của Thư viện | [05-tags.md](../../shared/ui/screen-handoff/05-tags.md) |
| 07 · Overlay lọc theo tag | Bottom sheet trên card list | Chip Tags trên thanh filter của card list | [07-card-list.md](../../shared/ui/screen-handoff/07-card-list.md) |

"Find cards with this tag" mở tìm kiếm thư viện với tên tag; tìm kiếm nằm trong nhánh
Thư viện nên Back về Thư viện. Đổi tên chạy `PlanTagRenameUseCase` sau khi tên dừng 250
ms, xác nhận gộp bằng `mergeIntoTagId`; gặp `mergeNotConfirmed` thì mở lại hộp thoại với
tên đã gõ. Nguồn: [spec FE-B2 + FE-B4](../../superpowers/specs/2026-09-27-tags-starter-ui-design.md)
§3 (D3, D5, D8, D11, D12, D14), §5.2, §5.3.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Tag.name | không rỗng sau trim (BR-TAG-001) | "Tên tag không được để trống" | rule |
| Tag.name | ≤ 50 ký tự (BR-TAG-001) | "Tên tag tối đa 50 ký tự" | rule |
| Tag.name | không trùng, không phân biệt hoa thường (BR-TAG-001) | "Tag này đã tồn tại" | rule + db |
| Card.tags | ≤ 10 tag mỗi thẻ (BR-TAG-002) | "Mỗi thẻ tối đa 10 tag" | rule |

Toàn bộ enforce ở tầng nghiệp vụ của app. Server chỉ kiểm lại tính toàn vẹn (CHECK, khoá ngoại, bất biến cây, [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md) #2) — client validation là trải nghiệm, không phải bảo mật.
