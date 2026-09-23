---
id: ADR-007
title: Khoá chính UUID sinh phía client
status: active
superseded_by:
---
## Quyết định

Toàn bộ khoá chính là TEXT chứa UUID sinh phía client (spec V8 §3). Tạo dữ liệu
offline cần ID trước khi có server, và đổi kiểu khoá chính về sau là migration
đắt nhất có thể.
