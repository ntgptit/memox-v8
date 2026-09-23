# Documentation — MemoX V8

Bản đồ tài liệu cho người và AI agent: cái gì nằm ở đâu, ID đặt thế nào, và
kiểm chứng bằng lệnh nào. Danh mục chi tiết từng rule/use case **không** viết ở
đây — nó được sinh ở [`_generated/index.md`](_generated/index.md).

> Đang migrate sang cấu trúc này theo [`_migration/plan.md`](_migration/plan.md).
> Trong lúc đó, nội dung chưa chuyển vẫn nằm ở vị trí cũ — xem mục
> [Trong lúc migration](#trong-lúc-migration).

## Bản đồ

```
docs/
├── README.md                    # file này
├── glossary.md                  # thuật ngữ, trỏ về định nghĩa gốc
├── shared/
│   ├── rules/                   # BR-CORE-NNN-<slug>.md — rule không feature nào sở hữu
│   ├── decisions/               # ADR-NNN-<slug>.md
│   ├── data/                    # schema.md — bảng, cột, index, invariant `-- N.`
│   ├── ui/                      # navigation.md — điều hướng toàn app
│   └── testing/                 # hạ tầng kịch bản IT dùng chung
├── features/<feature>/
│   ├── README.md                # phạm vi + màn hình → use case
│   ├── rules/                   # BR-<DOMAIN>-NNN-<slug>.md
│   ├── usecases/                # UC-<DOMAIN>-NNN-<slug>.md
│   ├── ui.md                    # TÙY CHỌN
│   ├── data.md                  # TÙY CHỌN
│   ├── api.md                   # TÙY CHỌN
│   └── it-scenarios.md          # TÙY CHỌN — kịch bản IT truy vết về feature này
├── superpowers/                 # spec + plan của quy trình Superpowers (giữ ID lịch sử)
└── _generated/                  # KHÔNG SỬA TAY — index, traceability, open questions
```

File/folder trong `shared/` và file tùy chọn của feature chỉ tồn tại khi có nội
dung thật. Không tạo file rỗng.

## Thứ tự đọc

1. `CLAUDE.md` ở root repo — ràng buộc áp dụng ở mọi phase.
2. File này.
3. `features/<feature>/README.md` của feature đang làm, rồi đúng các BR/UC mà nó
   trỏ tới. Không đọc hết `docs/`.
4. `shared/` khi feature tham chiếu tới; `shared/decisions/` khi cần biết **vì sao**.
5. [`_generated/open-questions.md`](_generated/open-questions.md) trước khi coi
   một hành vi là đã chốt.

`.claude/skills/` là hướng dẫn *cách làm*, không phải quyết định sản phẩm. Khi
skill và `docs/` mâu thuẫn, `docs/` thắng, và mâu thuẫn đó là defect phải sửa.

## X viết ở đâu

| Nội dung | Vị trí |
|---|---|
| Ràng buộc nghiệp vụ, dùng 1 feature | `features/<f>/rules/` |
| Ràng buộc nghiệp vụ, dùng ≥ 2 feature | `shared/rules/` (BR-CORE) |
| Hành vi chỉ xảy ra trong 1 use case (kể cả UI/local/API của UC đó) | Section tương ứng trong file UC |
| Màn hình, điều hướng, state dùng chung nhiều UC của feature | `features/<f>/ui.md` |
| Bảng/field feature dùng, dữ liệu sync, conflict rule riêng | `features/<f>/data.md` |
| Endpoint feature dùng, lỗi đặc thù | `features/<f>/api.md` |
| Request/response, error code | `shared/api/` |
| Cơ chế chung: cache, sync, state pattern, token | `shared/data/`, `shared/ui/` |
| Quyết định kỹ thuật có lý do và phương án bị loại | `shared/decisions/` (ADR) |
| Định nghĩa thuật ngữ | `glossary.md` |

Nguyên tắc: nghiệp vụ → rule; hành vi → use case; cơ chế → shared.
Không chép nội dung sang chỗ khác — chỉ reference ID hoặc link.

Áp dụng cho repo này (quyết định migration, `_migration/plan.md` §6):

- **"Dùng ≥ 2 feature" nghĩa là không feature nào sở hữu.** Rule ràng buộc một
  đối tượng ở lại feature của đối tượng đó dù feature khác trích nó; feature khác
  tham chiếu bằng ID. `shared/rules/` chỉ giữ rule không có chủ — các rule riêng
  tư, sẽ nhận DOMAIN `CORE` khi chuyển sang.
- Kịch bản kiểm thử tích hợp: `features/<f>/it-scenarios.md` theo UC/BR mà kịch
  bản truy vết; hướng dẫn thực thi, danh mục và kịch bản không thuộc feature nào
  ở `shared/testing/`.
- Điều hướng toàn app: `shared/ui/navigation.md`.

## Convention

### ID

| Loại | Format | Ví dụ |
|---|---|---|
| Business rule | `BR-<DOMAIN>-NNN` | `BR-DECK-015` |
| Use case | `UC-<DOMAIN>-NNN` | `UC-STUDY-001` |
| Rule dùng chung | `BR-CORE-NNN` | — (chưa có) |
| Quyết định | `ADR-NNN` | `ADR-001` |

- DOMAIN viết hoa, NNN đúng 3 chữ số. Tên file: `<ID>-<slug-kebab-case>.md`; ID
  trong tên file MUST khớp `id` trong frontmatter.
- DOMAIN của một feature là tên thư mục viết hoa, trừ các ngoại lệ dưới đây (giữ
  mã đối tượng có từ trước):

  | Thư mục | DOMAIN |
  |---|---|
  | `study-mode` | `MODE` |
  | `tags` | `TAG` |
  | `starter-decks` | `STARTER` |
  | `reminders` | `REMINDER` |
  | `shared/rules` | `CORE` |

- **ID là vĩnh viễn.** MUST NOT đánh số lại, MUST NOT tái sử dụng số đã bỏ trống.
  ID mới lấy số tiếp theo của DOMAIN đó, nên ID không nhất thiết tăng theo thứ tự
  đọc. Lý do: một lần đánh số lại trước V8 đã làm một ID trỏ sang rule khác mà
  không test nào bắt được. Ngoại lệ duy nhất, thuộc đợt migrate này:
  `BR-PRIVACY-00n` → `BR-CORE-00n`.
- Rule bị thay thế: `status: deprecated` + `superseded_by: <ID>`, giữ nguyên ID
  và nguyên văn. **MUST NOT xoá** — ID biến mất làm mọi tham chiếu cũ trong
  commit, comment, PR trỏ vào hư không.
- `docs/superpowers/` giữ ID lịch sử; `check.py` không kiểm ID ở đó.

### Frontmatter

Business rule — `features/<f>/rules/` hoặc `shared/rules/`:

```yaml
---
id: BR-STUDY-001
title: <tên ngắn>
status: active            # draft | active | deprecated
summary: <một câu, đủ để agent quyết định có cần mở file không>
superseded_by:            # chỉ khi deprecated
---
## Rule
## Lý do
## Ví dụ
## Edge case
```

Body BR **không** có mục "Được dùng bởi" — `generate.py` sinh nó ở index.

Use case — `features/<f>/usecases/`:

```yaml
---
id: UC-STUDY-001
title: <tên>
status: ready             # draft | ready | deprecated — trạng thái SPEC, không phải tiến độ code
rules: [BR-STUDY-001, BR-STUDY-002]
code: []                  # path thật trong repo; không chắc → [] và ghi OPEN QUESTION
---
## Mục tiêu / Actor / Precondition
## Main flow
## Alternative / Error flow
## UI
## Local
## API
## Acceptance criteria
```

Feature README — `features/<f>/README.md`:

```yaml
---
feature: study
code: []
depends_on: []
---
## Phạm vi
## Màn hình → Use case
## Không thuộc phạm vi
```

ADR — `shared/decisions/`: frontmatter `id`, `title`, `status`
(`draft | active | deprecated`), `superseded_by` khi deprecated.

Section không áp dụng: ghi "Không áp dụng", không xoá heading. Quan hệ chỉ khai
báo một chiều: UC khai báo `rules`; không viết reverse link hay index bằng tay.

### Ngôn ngữ ràng buộc

| Từ khoá | Nghĩa | Vi phạm |
|---|---|---|
| **MUST** / **MUST NOT** | Bắt buộc, không ngoại lệ trong phạm vi MVP | Defect, không merge |
| **SHOULD** | Khuyến nghị mạnh; làm khác phải ghi lý do | Cần biện minh |
| **MAY** | Tuỳ chọn | Không sao |

Câu không có từ khoá là **giải thích, không phải ràng buộc** — MUST NOT suy ra
rule mới từ prose. Ví dụ, đoạn code và bảng ví dụ minh hoạ ranh giới của một rule
đã phát biểu; khi ví dụ và rule mâu thuẫn, **rule thắng**.

### Hợp đồng và phạm vi sửa

BR `active` và UC `ready` là hợp đồng mà code viết theo. Sửa chúng là quyết định có
chủ đích: task sửa tài liệu MUST nêu chính xác file được phép sửa; khi cần sửa
ngoài phạm vi đó, dừng và nói rõ file nào, vì sao.

Mâu thuẫn, mơ hồ hoặc thiếu thông tin: không tự chọn. Ghi tại file đích
`> ⚠️ OPEN QUESTION: <mô tả, trích nguồn các bên>`; chúng được gom ở
[`_generated/open-questions.md`](_generated/open-questions.md).

Tài liệu và code cập nhật trong cùng một commit. Tài liệu chậm hơn code là có hại
thật: phiên sau đọc nó, tin nó, và xây tiếp trên một điều không còn đúng.

## Kiểm chứng

Chạy từ root repo, Python 3, không cần thư viện ngoài:

```sh
python tools/docs/generate.py                                  # sinh docs/_generated/
python tools/docs/check.py                                     # ERROR → exit 1
python tools/docs/check.py --plan docs/_migration/plan.md      # thêm: đích của bảng ánh xạ phải tồn tại
```

`check.py` kiểm frontmatter, ID (format, trùng, khớp tên file và DOMAIN của thư
mục), `rules`/`superseded_by`, path trong `code`, link tương đối, ID và
`invariant Qn` được trích, section bắt buộc, và `_generated/` có lỗi thời không.
WARNING (không fail): BR active không UC nào dùng, UC ready có `code: []` hoặc
chưa có test chứa ID. Chi tiết ở docstring của hai script.

## Trong lúc migration

Nội dung chưa chuyển vẫn ở vị trí cũ. Tra cứu theo đối tượng:

| Đang làm việc trên | Business rules | Use cases |
|---|---|---|
| Cây deck, tên/xoá deck | [`business-rules/deck.md`](business-rules/deck.md) | [`use-cases/deck.md`](use-cases/deck.md) |
| Nội dung card, cờ, di chuyển, chi tiết card | [`business-rules/card.md`](business-rules/card.md) | [`use-cases/card.md`](use-cases/card.md) |
| Scheduler `eight_box`/`sm2`, khoá/đổi scheduler, reset | [`business-rules/srs.md`](business-rules/srs.md) | [`use-cases/srs.md`](use-cases/srs.md) |
| Phiên ôn tập, hàng đợi, round, Study Home | [`business-rules/study.md`](business-rules/study.md) | [`use-cases/study.md`](use-cases/study.md) |
| StudyMode, chuỗi stage, chiều hỏi `self_assess` | [`business-rules/study-mode.md`](business-rules/study-mode.md) | [`use-cases/study.md`](use-cases/study.md) |
| Tiến độ theo deck, Progress overview | [`business-rules/progress.md`](business-rules/progress.md) | [`use-cases/progress.md`](use-cases/progress.md) |
| Tuỳ chọn ứng dụng | [`business-rules/settings.md`](business-rules/settings.md) | [`use-cases/settings.md`](use-cases/settings.md) |
| Tìm kiếm toàn thư viện | [`business-rules/search.md`](business-rules/search.md) | [`use-cases/search.md`](use-cases/search.md) |
| Luật riêng tư chung | [`business-rules/privacy.md`](business-rules/privacy.md) | — |
| Trash và restore (sub-project sau) | [`business-rules/trash.md`](business-rules/trash.md) | [`use-cases/trash.md`](use-cases/trash.md) |
| Tag (sub-project sau) | [`business-rules/tags.md`](business-rules/tags.md) | [`use-cases/tags.md`](use-cases/tags.md) |
| Import/export card (sub-project sau) | [`business-rules/transfer.md`](business-rules/transfer.md) | [`use-cases/transfer.md`](use-cases/transfer.md) |
| Starter deck (sub-project sau) | [`business-rules/starter-decks.md`](business-rules/starter-decks.md) | [`use-cases/starter-decks.md`](use-cases/starter-decks.md) |
| Nhắc học hằng ngày (sub-project sau) | [`business-rules/reminders.md`](business-rules/reminders.md) | [`use-cases/reminders.md`](use-cases/reminders.md) |

Tài liệu khác chưa chuyển: [`product/product.md`](product/product.md),
[`product/master-flow.md`](product/master-flow.md), [`data-model.md`](data-model.md),
[`it-scenarios/`](it-scenarios/README.md),
[`document-conventions.md`](document-conventions.md) (quy ước cũ, được thay bằng
file này; xoá ở bước dọn dẹp). Mục này bị xoá khi migration xong.
