---
id: BR-STUDY-024
title: card_limit chốt lúc mở phiên
status: active
summary: Số thẻ của phiên chốt một lần lúc mở vào `card_limit`; đổi tùy chọn sau đó không ảnh hưởng.
superseded_by:
---
## Rule

Số thẻ của một phiên MUST được chốt **một lần lúc mở phiên** từ tùy chọn hiệu lực (BR-STUDY-056) và lưu vào `study_session.card_limit`. Đổi tùy chọn sau đó MUST NOT ảnh hưởng phiên đang chạy.

**Enforced by:** db
**Liên quan:** BR-STUDY-003, BR-STUDY-056

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
