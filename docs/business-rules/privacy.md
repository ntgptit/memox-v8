# Business rules — Dữ liệu riêng tư

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng PRIVACY, dưới ID vĩnh viễn `BR-PRIVACY-nnn` |
| **Scope** | Luật riêng tư chung: dữ liệu nào là riêng tư, log, media, export/backup. |
| **Source of truth for** | BR-PRIVACY-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Dữ liệu riêng tư

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-PRIVACY-001 | active | Nội dung deck/card, ghi chú, lịch sử học, file import, hình ảnh, audio và dữ liệu backup MUST được coi là dữ liệu riêng tư. | — | — |
| BR-PRIVACY-002 | active | MUST NOT log nội dung flashcard hoặc ghi chú ở bất kỳ log level nào. Log ID thì MAY. | logging | — |
| BR-PRIVACY-003 | active | Media MUST lưu trong thư mục riêng của ứng dụng. | store | — |
| BR-PRIVACY-004 | active | Export và backup MUST chỉ chạy khi người dùng chủ động yêu cầu. | rule | — |
