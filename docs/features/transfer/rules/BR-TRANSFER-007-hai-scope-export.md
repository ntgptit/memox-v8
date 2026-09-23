---
id: BR-TRANSFER-007
title: Hai scope export
status: active
summary: Export có đúng hai scope `all` và `selected`.
superseded_by:
---
## Rule

Export MUST hỗ trợ đúng hai scope và MUST NOT có scope thứ ba ở v1. `all`: toàn bộ card **trực tiếp** của deck đang mở, độc lập với filter, search term, sort và pagination đang bật, MUST NOT gồm card của deck descendant. `selected`: đúng tập id đã materialize từ chế độ chọn (BR-CARD-012), id trùng MUST được normalize về một lần và MUST NOT nhân bản hàng trong file. Một id không còn tồn tại, hoặc không còn thuộc chính deck đó tại thời điểm đọc snapshot, MUST làm **cả request** thất bại bằng lý do có kiểu — MUST NOT export một phần im lặng. Scope rỗng (deck không còn card, hoặc tập chọn rỗng) MUST bị từ chối ở tầng nghiệp vụ kể cả khi UI đã ẩn action.

**Enforced by:** rule + store
**Liên quan:** BR-CARD-012

## Lý do

Nửa còn lại của Card Transfer. Các rule dưới đây **không** phát biểu lại
validation nội dung (BR-CARD-001, BR-CARD-002, BR-CARD-003), luật tag (BR-TAG-001, BR-TAG-002) hay luật
riêng tư chung (BR-PRIVACY-001…BR-PRIVACY-004) — chúng chỉ nói phần mà chiều export thêm vào.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Export scope `all` khi danh sách đang bật filter/search | File vẫn chứa toàn bộ card trực tiếp của deck, không phải tập đã lọc (BR-TRANSFER-007) |
| Export scope `selected` có id lặp lại | Normalize còn một hàng; số card trong file khớp số id phân biệt (BR-TRANSFER-007) |
| Một card trong tập chọn bị xoá hoặc chuyển deck trước lúc đọc | Cả request thất bại có kiểu; không sinh file một phần (BR-TRANSFER-007) |
