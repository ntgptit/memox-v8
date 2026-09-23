# Tags — UI

Màn hình, điều hướng và validation dùng chung nhiều UC của feature. Hành vi riêng của từng UC nằm trong file UC.

## Validation

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| Tag.name | không rỗng sau trim (BR-TAG-001) | "Tên tag không được để trống" | rule |
| Tag.name | ≤ 50 ký tự (BR-TAG-001) | "Tên tag tối đa 50 ký tự" | rule |
| Tag.name | không trùng, không phân biệt hoa thường (BR-TAG-001) | "Tag này đã tồn tại" | rule + db |
| Card.tags | ≤ 10 tag mỗi thẻ (BR-TAG-002) | "Mỗi thẻ tối đa 10 tag" | rule |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.
