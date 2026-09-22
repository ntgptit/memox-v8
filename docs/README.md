# Documentation

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chỉ mục tài liệu — cái gì tồn tại trong `docs/` và ai sở hữu cái gì |
| **Scope** | Toàn bộ `docs/`. Ngoài phạm vi: nội dung của từng tài liệu |
| **Source of truth for** | Danh mục tài liệu · trạng thái từng tài liệu |
| **Depends on** | `document-conventions.md` |
| **Updated by** | `docs/superpowers/plans/2026-09-23-docs-v8-reset.md` — V8 reset: viết lại chỉ mục cho bộ tài liệu V8; gỡ tài liệu, thư mục và skill đã xoá khỏi chỉ mục, và bỏ mục tài liệu chưa viết theo quy trình cũ |
| **Last updated** | 2026-09-23 |

Format và thứ tự đọc: [`document-conventions.md`](document-conventions.md).

## What exists

| Document | Purpose | Status |
|---|---|---|
| [`document-conventions.md`](document-conventions.md) | Hợp đồng tài liệu: thứ tự đọc, header bắt buộc, template BR/UC/data model, và từ khoá MUST/SHOULD/MAY | frozen for MVP |
| [`product.md`](product.md) | Vấn đề, người dùng, quyết định nền tảng, và phạm vi MVP | frozen for MVP |
| [`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](superpowers/specs/2026-09-21-memox-v8-foundation-design.md) | Kiến trúc nền tảng V8: Flutter viết lại từ đầu, giữ nghiệp vụ học của V7, không giữ kiến trúc hay cách triển khai của nó | draft for review |
| [`business-rules.md`](business-rules.md) (+ [`business-rules/study-mode.md`](business-rules/study-mode.md)) | BR-01…270: cây deck, hai scheduler, kind, session lifecycle, reset/generation, starter template, trạng thái thẻ, cờ và tag, import/export, tiến độ, Study Home, Settings, nhắc học, tìm kiếm, Trash | frozen for MVP |
| [`data-model.md`](data-model.md) | Schema, cột, index, quan hệ, và các câu query bất biến giữ dữ liệu đúng | frozen for MVP |
| [`use-cases.md`](use-cases.md) | UC-01…22 cho phạm vi MVP | frozen for MVP |
| [`master-flow.md`](master-flow.md) | Đồ thị nối UC-01…20 thành hành trình, tách theo đối tượng deck / card / study | active |
| [`superpowers/plans/2026-09-21-memox-v8-foundation.md`](superpowers/plans/2026-09-21-memox-v8-foundation.md) | Kế hoạch triển khai nền tảng V8: Flutter skeleton, data model lõi, scheduler SRS thuần Dart, luật cây deck | not started |
| [`superpowers/plans/2026-09-23-docs-v8-reset.md`](superpowers/plans/2026-09-23-docs-v8-reset.md) | Kế hoạch dọn `docs/`: xoá tài liệu V7, dựng gate tham chiếu, scrub tài liệu còn lại, nâng `data-model.md` lên V8 | in progress |
| [`it-scenarios/`](it-scenarios/) | Bộ kịch bản kiểm thử tích hợp theo hành trình người dùng: điều hướng, bộ thẻ, thẻ ghi nhớ, học và ôn tập | active |
| [`../tools/check_docs_refs.py`](../tools/check_docs_refs.py) | Gate: không tài liệu nào được trích dẫn thứ đã bị xoá; BR/UC/invariant được trích dẫn phải phân giải được | active |

**ID là vĩnh viễn.** BR, UC và invariant không bao giờ được đánh số lại; luật
mới append vào số tiếp theo, kể cả khi nó thuộc phần đầu tài liệu — chi tiết và
lý do ở [`document-conventions.md`](document-conventions.md) §7.

## The rule that keeps this useful

Tài liệu và code được cập nhật trong cùng một commit. Một tài liệu chậm hơn
code là có hại thật sự — phiên làm việc sau đọc nó, tin nó, và xây tiếp trên
một điều không còn đúng. Nếu một thay đổi làm tài liệu sai, phải sửa tài liệu
đó trước khi merge.
