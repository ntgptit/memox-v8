# Starter decks — dữ liệu

Bảng riêng của feature. Bảng dùng chung và mọi invariant nằm ở [`shared/data/schema.md`](../../shared/data/schema.md).

## `deck_templates`

**Phạm vi:** sub-project sau — Starter decks. Bảng giữ ở đây để nghiệp vụ không
phải đào lại.

**Đây không phải bảng runtime** — template là asset JSON:

```
assets/templates/
├── manifest.json
└── vi/
    └── starter_fixture_a.json
```

| Trường | Ghi chú |
|---|---|
| `template_id` | ổn định giữa các phiên bản app (BR-STARTER-002) |
| `version` | tăng khi nội dung đổi |
| `locale` | `vi`, `en`, … |
| `title` | tên hiển thị |
| `content_source` | nguồn gốc nội dung, cho ghi công và kiểm tra bản quyền |
| `default_scheduler_type` | scheduler gợi ý; người dùng đổi được trước lượt học đầu |

Template mô tả **cả cây deck**, không chỉ một danh sách card, vì bản sao phải
dựng lại đúng cấu trúc `content_type` và `root_id`.

Nội dung starter hiện tại là **fixture do dự án tự tạo, chỉ phục vụ development
và test** (BR-STARTER-010). Không mô tả nó như nội dung production ở bất kỳ đâu — UI, store
listing, hay tài liệu.
