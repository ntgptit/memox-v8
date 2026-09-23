---
id: ADR-010
title: Kiến trúc lớp V8, tên thư mục feature và phiên bản Flutter
status: active
superseded_by:
---
## Bối cảnh

[`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](../../superpowers/specs/2026-09-21-memox-v8-foundation-design.md)
§4 chọn cấu trúc `features/{decks,cards,srs,study,progress}` gồm `data/` và `logic/`,
không có repository layer, và mỗi feature tự khai báo bảng `.drift` của mình.
Tooling và skill có sẵn trong repo (`.claude/skills/flutter-*`,
`build_verification_plan.py`, `test_architecture_checker.py`) lại giả định cấu trúc
lớp `domain/ data/ presentation/ di/` có repository contract. Hai bên không tương
thích: init Flutter theo spec thì verification plan xếp mọi file feature vào "unknown
layer" và kéo cả suite. Tên thư mục trong spec (`decks`, `cards`) cũng lệch với tên
feature trong `docs/features/`. Chủ dự án chốt ba điểm này ngày 2026-09-23.

## Quyết định

| # | Câu hỏi | Quyết định |
|---|---|---|
| 1 | Tên thư mục feature | `lib/features/<f>/` với `<f>` là tên thư mục trong `docs/features/` viết snake_case: `deck`, `card`, `srs`, `study`, `study_mode`, `progress`, `tags`, `search`, `settings`, `reminders`, `transfer`, `trash`, `starter_decks` |
| 2 | Kiến trúc lớp | Theo cấu trúc lớp mà tooling đang giả định, mô tả trong skill [`flutter-architecture`](../../../.claude/skills/flutter-architecture/SKILL.md): mỗi feature có `domain/` (entities, repositories, usecases…), `data/` (repository implementation, datasource, mapper), `presentation/`, và `di/` khi cần. Bảng và query Drift đặt tập trung ở `lib/core/database/` theo [`flutter-drift/references/project-baseline.md`](../../../.claude/skills/flutter-drift/references/project-baseline.md) |
| 3 | Phiên bản Flutter | 3.47.5 (stable, ra 2026-09-18), pin trong `.fvmrc` |

**Lý do cụ thể cho repository contract** (điều kiện "concrete architectural reason"
trong `CLAUDE.md`): contract ở `domain/` giữ domain không phụ thuộc Drift/Flutter —
luật SRS và cây deck test được như Dart thuần — và là ranh giới mà
`test_architecture_checker.py`, `build_verification_plan.py` cùng các skill
`flutter-*` đã dựa vào. Contract chỉ có một implementation ở `data/` là chấp nhận
được vì lý do này, không phải để "dành cho sau".

## Hệ quả

- Foundation spec §4 được thay bằng ADR này; spec giữ nguyên như tài liệu lịch sử
  của Superpowers. Phần còn lại của spec (§3 state/DB/routing/models, §5–§9) vẫn
  áp dụng, trừ các điểm đã thay bởi ADR-009.
- `CLAUDE.md` ghi ngoại lệ: kiến trúc lớp theo ADR này. State management, routing,
  UI và các abstraction khác của V7 vẫn không được chép.
- Plan [`superpowers/plans/2026-09-21-memox-v8-foundation.md`](../../superpowers/plans/2026-09-21-memox-v8-foundation.md)
  phải sửa trước khi chạy: tên thư mục (`decks/cards` → `deck/card`), lớp (`logic/`
  + store → `domain/` + `data/` repository), vị trí `.drift`, thêm `.fvmrc`, kiểm lại
  version package cho Flutter 3.47.5, và schema theo
  [`shared/data/schema.md`](../data/schema.md).
- Tên feature là khoá của `verification_impact_map.json`; test
  `ImpactMapMatchesTheDocsTest` giữ nó khớp với `docs/features/`.
- Quyết định 2 được cụ thể hoá bởi [ADR-011](ADR-011-cau-truc-thu-muc-v8.md): bucket trong
  từng layer, luật import giữa các feature và gate kiểm chứng theo giai đoạn.
