# Documentation — MemoX V8

Bản đồ tài liệu cho người và AI agent: cái gì nằm ở đâu, ID đặt thế nào, và
kiểm chứng bằng lệnh nào. Danh mục chi tiết từng rule/use case **không** viết ở
đây — nó được sinh ở [`_generated/index.md`](_generated/index.md).

## Sản phẩm

Định nghĩa sản phẩm: [`/PRODUCT.md`](../PRODUCT.md).

## Bản đồ

```
PRODUCT.md                       # root repo — định nghĩa sản phẩm, bản duy nhất
DESIGN.md                        # root repo — hệ thống hình ảnh (ADR-021)
docs/
├── README.md                    # file này: bản đồ và convention
├── USE_CASES.md                 # mọi UC, nhóm theo feature
├── NAVIGATION.md                # điều hướng cấp app và router
├── functional-spec/
│   ├── README.md                # feature → file
│   └── <feature>.md             # FN-<DOMAIN>-NNN
├── screens/
│   ├── SCREEN_CATALOG.md        # mọi màn + invariant chung INV-UI
│   └── spec/                    # SCR-<DOMAIN>-NNN-<slug>.md, một file một màn
├── glossary.md
├── wbs_BE.md, wbs_FE.md, wbs_API.md, wbs_supabase.md
├── shared/
│   ├── rules/                   # BR-CORE-NNN-<slug>.md
│   ├── decisions/               # ADR-NNN-<slug>.md
│   ├── data/                    # schema.md
│   └── testing/
├── features/<feature>/
│   ├── README.md                # phạm vi, thuật ngữ, depends_on
│   ├── rules/                   # BR-<DOMAIN>-NNN-<slug>.md
│   ├── data.md                  # TÙY CHỌN
│   └── it-scenarios.md          # TÙY CHỌN
├── superpowers/                 # spec + plan (giữ ID lịch sử)
└── _generated/                  # KHÔNG SỬA TAY — index, traceability, screens, navigation-graph, open questions
```

File/folder trong `shared/` và file tùy chọn của feature chỉ tồn tại khi có nội
dung thật. Không tạo file rỗng.

Mỗi màn có một spec trong `screens/spec/` và một hàng trong `screens/SCREEN_CATALOG.md`.
Hệ thống hình ảnh ở [`DESIGN.md`](../DESIGN.md); thứ tự ưu tiên theo
[ADR-021](shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md). Định nghĩa sản phẩm
thuộc `/PRODUCT.md`; không chép phạm vi sản phẩm vào cây `docs/`.

## Thứ tự đọc

1. `CLAUDE.md` ở root repo — ràng buộc áp dụng ở mọi phase.
2. File này.
3. `/PRODUCT.md` khi cần phạm vi sản phẩm.
4. Việc trên một feature: `features/<feature>/README.md`, `functional-spec/<feature>.md`, các UC
   của nó trong `USE_CASES.md`, rồi đúng các BR mà FN trỏ tới. Không đọc hết `docs/`.
5. Việc trên một màn: `screens/SCREEN_CATALOG.md`, spec của màn, các FN nó gọi, `/DESIGN.md`.
6. `shared/decisions/` khi cần biết **vì sao**.
7. [`_generated/open-questions.md`](_generated/open-questions.md) trước khi coi một hành vi là
   đã chốt.

`.claude/skills/` là hướng dẫn *cách làm*, không phải quyết định sản phẩm. Khi
skill và `docs/` mâu thuẫn, `docs/` thắng, và mâu thuẫn đó là defect phải sửa.

## X viết ở đâu

| Nội dung | Vị trí |
|---|---|
| Định nghĩa sản phẩm, phạm vi MVP | `/PRODUCT.md` |
| Mục tiêu và luồng của người dùng | `USE_CASES.md` (UC) |
| Hệ thống làm gì: precondition, input, kết quả, lỗi, BR áp dụng | `functional-spec/<feature>.md` (FN) |
| Ràng buộc nghiệp vụ, một feature sở hữu | `features/<f>/rules/` |
| Ràng buộc nghiệp vụ không feature nào sở hữu | `shared/rules/` (BR-CORE) |
| Một màn: vùng, state, control → FN, điều hướng cục bộ, copy, ruling | `screens/spec/` |
| Danh mục màn; invariant hành vi mọi màn phải giữ | `screens/SCREEN_CATALOG.md` |
| Điều hướng cấp app: shell, tab, deep link, back, guard, boot | `NAVIGATION.md` |
| Hệ thống hình ảnh | `/DESIGN.md` |
| Bảng/field feature dùng, dữ liệu sync, conflict rule riêng | `features/<f>/data.md` |
| Endpoint feature dùng, lỗi đặc thù | `features/<f>/api.md` |
| Request/response, error code | `shared/api/` |
| Cơ chế chung: cache, sync, token | `shared/data/` |
| Kịch bản IT | `features/<f>/it-scenarios.md`, `shared/testing/` |
| Quyết định kỹ thuật có lý do và phương án bị loại | `shared/decisions/` (ADR) |
| Định nghĩa thuật ngữ | `glossary.md` |

Nguyên tắc: mục tiêu → UC; hành vi hệ thống → FN; ràng buộc → BR; giao diện → screen spec.
Không chép nội dung sang chỗ khác — chỉ reference ID hoặc link.


Lý do quy tắc này chặt: hai bản sao của cùng một rule **luôn** lệch nhau sau vài
lần sửa, và lúc đó không có cách nào biết bản nào đúng ngoài việc hỏi người viết
— người đã quên. Tham chiếu bằng ID không có vấn đề đó.

**Được phép nhắc lại** một kết luận ngắn kèm ID để đoạn văn đọc được (`scheduler
thuộc root deck (BR-DECK-005)`). **Không được phép** chép lại chi tiết đủ để hai
chỗ có thể mâu thuẫn.

Áp dụng cho repo này (quyết định khi tái cấu trúc docs):

- **"Dùng ≥ 2 feature" nghĩa là không feature nào sở hữu.** Rule ràng buộc một
  đối tượng ở lại feature của đối tượng đó dù feature khác trích nó; feature khác
  tham chiếu bằng ID. `shared/rules/` chỉ giữ rule không có chủ — các rule riêng
  tư, sẽ nhận DOMAIN `CORE` khi chuyển sang.
- Kịch bản kiểm thử tích hợp: `features/<f>/it-scenarios.md` theo UC/BR mà kịch
  bản truy vết; hướng dẫn thực thi, danh mục và kịch bản không thuộc feature nào
  ở `shared/testing/`.
- Điều hướng toàn app: `NAVIGATION.md`.

## Convention

### Vì sao có các quy ước này

Một agent đọc `docs/` cần trả lời được ba câu:

1. **Đọc theo thứ tự nào?** Không có thứ tự thì agent đọc file nào gặp trước, và
   một quyết định trong `shared/decisions/` có thể bị bỏ qua vì nó đọc
   `features/` trước.
2. **Câu nào là quyết định chính thức, câu nào là giải thích?** Prose giải thích
   *tại sao* một rule tồn tại rất dễ bị đọc thành một rule mới. Ví dụ minh hoạ
   càng dễ bị đọc thành đặc tả.
3. **Thông tin này ở đâu là bản gốc?** Cùng một rule viết ở hai file thì sớm muộn
   hai bản sẽ lệch nhau, và không ai biết bản nào đúng.


### ID

| Loại | Format | Ví dụ |
|---|---|---|
| Business rule | `BR-<DOMAIN>-NNN` | `BR-DECK-015` |
| Use case | `UC-<DOMAIN>-NNN` | `UC-STUDY-001` |
| Rule dùng chung | `BR-CORE-NNN` | — (chưa có) |
| Chức năng | `FN-<DOMAIN>-NNN` | `FN-DECK-001` |
| Màn hình | `SCR-<DOMAIN>-NNN` | `SCR-DECK-001` |
| Invariant UI chung | `INV-UI-NNN` | `INV-UI-001` |
| State của một màn | `snake_case`, duy nhất trong màn | `root_loaded` |
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
  `BR-PRIVACY-00n` → `BR-CORE-00n`. Áp dụng cho cả FN, SCR, INV-UI
  và state key của màn; state bị bỏ giữ heading với `Status: removed`.
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

Dòng `**Enforced by:**` trong `## Rule` của BR giữ cột "Enforced by" của bảng BR cũ:
chỗ rule được cưỡng chế — `domain`, `db`, `UI`, `scheduler`, `script`, … — hoặc `—`
nếu chưa cưỡng chế được. `Enforced by` là field có giá trị thực tế cao nhất khi code: nó nói cho người
triển khai biết rule này sống ở đâu trong hệ thống, và nó phơi bày những rule
hiện chưa có gì cưỡng chế.

Rule cần nhiều hơn một câu (ví dụ có bảng tra) MUST dùng dạng section
`### BR-<CODE>-nnn · <tiêu đề>` và vẫn phải xuất hiện Status/Enforced by/Related
ngay dưới tiêu đề.

Feature README — `features/<f>/README.md`:

```yaml
---
feature: study
code: []
depends_on: []
---
## Phạm vi
## Không thuộc phạm vi
```

`depends_on` — X khai báo Y khi X **đọc dữ liệu hoặc contract mà Y sở hữu**
(chủ dự án chốt ngày 2026-09-23). Đồ thị phải **không có chu trình**: feature nền
tảng không khai báo feature tiêu thụ nó, kể cả khi tài liệu của nó nhắc tới feature
đó. Chỉ ghi phụ thuộc trực tiếp — bỏ cạnh đã suy ra được qua feature khác. Nhắc
tới một BR/UC của feature khác không tự tạo phụ thuộc. `check.py` báo lỗi khi có
chu trình; `verification_impact_map.json` suy ra từ trường này.
Chiều import Dart giữa các feature trong `lib/features/` do
[ADR-011](shared/decisions/ADR-011-cau-truc-thu-muc-v8.md) quy định riêng và có thể khác
đồ thị này.

ADR — `shared/decisions/`: frontmatter `id`, `title`, `status`
(`draft | accepted | superseded | deprecated`), `superseded_by` khi superseded hoặc
deprecated, `supersedes: [ADR-…]` ở ADR thay thế. Link trong ADR superseded hoặc deprecated
không được kiểm (bản ghi, không sửa).

Section không áp dụng: ghi "Không áp dụng", không xoá heading. Quan hệ chỉ khai
báo một chiều (UC → FN, FN → BR, màn → FN/UC/màn); không viết reverse link hay index bằng tay.

### UC, FN và screen spec

Mỗi UC là một section của `USE_CASES.md`, dưới nhóm `## <Feature>`. Dòng ngay dưới heading là
dòng meta, các phần cách nhau bởi ` · `:

```markdown
### UC-DECK-001 — <tiêu đề>
Status: ready · Code: [<path>, …] · Invokes: [FN-DECK-001, …]

#### Mục tiêu / Actor / Precondition
#### Main flow                — bước của hệ thống trỏ FN-ID: "Hệ thống thực hiện FN-DECK-001."
#### Alternative / Error flow
#### Acceptance criteria
```

Mỗi FN là một section của `functional-spec/<feature>.md`; tên file là tên thư mục feature:

```markdown
## FN-DECK-001 — <tiêu đề>
Status: active · Code: [lib/features/deck/domain/usecases/<x>_use_case.dart]

### Precondition
### Input
### Kết quả
### Lỗi                — failure type có thật trong lớp domain; không đặt mã lỗi mới
### Business rules     — BR-…, một dòng một BR (quan hệ gốc FN → BR)
```

Mỗi màn là một file `screens/spec/SCR-<DOMAIN>-NNN-<slug>.md`, viết tiếng Anh:

```markdown
---
id: SCR-DECK-001
name: <Screen name>
domain: <feature folder>
status: draft | ready | built
route: [/path, …]
---
# <Screen name>
## Purpose
## Related Use Cases          — UC-ID (quan hệ gốc màn → UC)
## Layout                     — vùng theo vai trò, trên → dưới; không tên class widget
## States                     — mỗi state: ### `<state_key>` · <Title>, rồi "Golden: light, dark" hoặc "Golden: none — <lý do>"
## Controls                   — mỗi control: Type, Purpose, Enabled when, "Invokes: FN-…",
                                #### On success ("Navigate to: SCR-…" hoặc phản hồi UI),
                                #### On failure (<failure type> → cách hiển thị)
## Responsive Behavior        — "Follows the shared floor" khi không có gì riêng
## Accessibility              — như trên
## UI Invariants              — | Invariant | Enforced by |, chỉ invariant riêng của màn
## Copy
## Rulings
```

UC chỉ giữ ý định của người dùng, luồng ở mức ngữ nghĩa và FN-ID. Control, layout, dialog, FAB,
nút, lỗi hiện inline hay snackbar và cách trình bày state nằm ở screen spec của màn đó.

Một màn chưa có spec là một hàng `pending` trong `screens/SCREEN_CATALOG.md` (Route và Spec ghi
`—`). ID của nó trích được ở mọi nơi; `Navigate to:` tới nó là WARNING cho tới khi spec được
viết, lúc đó hàng `pending` được thay bằng hàng thật.

Golden của state tên `<scr_id>__<state_key>__<variant>.png`, ví dụ
`scr_deck_001__root_loaded__light.png`, nằm dưới `test/**/goldens/`.

Quan hệ gốc chỉ khai báo một chiều; chiều ngược do `generate.py` sinh vào `_generated/`, và một
section viết tay kiểu `Used by`, `Invoked by`, `Related Screens`, `Related BR`, `Entry points`
là ERROR.

| Quan hệ gốc | Viết ở |
|---|---|
| UC → FN | dòng `Invokes:` của UC |
| FN → BR | `### Business rules` của FN |
| Màn → FN | dòng `Invokes:` ở control |
| Màn → UC | `## Related Use Cases` |
| Màn → màn | dòng `Navigate to:` ở control |
| App → màn | `NAVIGATION.md` (deep link, guard, tab, back, boot) |

Loại ID mỗi tài liệu được trích (dòng `OPEN QUESTION` được miễn; trong các tài liệu này, ID
trong `inline code` vẫn tính):

| Tài liệu | Được trích |
|---|---|
| `USE_CASES.md` | FN |
| `functional-spec/` | BR; FN khi là tiền điều kiện hay năng lực của domain khác ở mức contract — không mô tả call graph |
| `screens/spec/` | FN, UC, SCR, INV-UI |
| `screens/SCREEN_CATALOG.md` | SCR, INV-UI |
| `NAVIGATION.md` | SCR, UC |

UC và màn không bao giờ trích BR; BR tới UC hay màn chỉ qua FN.

### Viết use case

UC được viết khi feature được chọn để đặc tả; phạm vi ship của feature (V8.0 hay
sub-project sau) ghi ở README của feature đó. Không đặc tả trước những thứ chưa
được chọn — đặc tả trước những thứ có thể bị cắt là lãng phí. (Chủ dự án chốt khi
xử lý OQ-11 (2026-09-23).)

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

`Error flows` và `UI states` là hai mục hay bị bỏ và là nguồn của phần lớn màn
hình thiếu trạng thái. MUST liệt kê đủ; trạng thái không xảy ra thì MUST nói rõ
vì sao thay vì im lặng bỏ. Trong cấu trúc mới, error flow nằm ở `#### Alternative / Error flow` của UC,
còn trạng thái giao diện ở `## States` của screen spec.

Mỗi UC mô tả mình và im lặng về những UC bên cạnh. Các UC nối vào nhau thế nào
thì xem [`NAVIGATION.md`](NAVIGATION.md) và các dòng `Navigate to:` của screen spec (đồ thị sinh ở
[`_generated/navigation-graph.md`](_generated/navigation-graph.md)); chúng tham chiếu ngược về UC
bằng ID và không phát biểu lại luồng nào.

### Data model

Mỗi bảng MUST có: một section `## <tên bảng>`, một bảng cột với
`Cột | Kiểu | Ghi chú`, danh sách index, và tham chiếu BR cho mọi ràng buộc.

Mọi bất biến MUST được diễn đạt thành một câu SQL **trả về 0 dòng khi dữ liệu
đúng**, đặt trong mục `## Bất biến`, đánh số `-- N. <mô tả> (BR-xx)`.

Định dạng đó không tuỳ tiện: `tools/docs/check.py` dựa vào đúng khuôn `-- N.` trong
[`shared/data/schema.md`](shared/data/schema.md) để đối chiếu `invariant Qn` với nơi
trích dẫn nó.

### Ngôn ngữ ràng buộc

| Từ khoá | Nghĩa | Vi phạm |
|---|---|---|
| **MUST** / **MUST NOT** | Bắt buộc, không ngoại lệ trong phạm vi MVP | Defect, không merge |
| **SHOULD** | Khuyến nghị mạnh; làm khác phải ghi lý do | Cần biện minh |
| **MAY** | Tuỳ chọn | Không sao |

Câu không có từ khoá là **giải thích, không phải ràng buộc** — MUST NOT suy ra
rule mới từ prose. Ví dụ, đoạn code và bảng ví dụ minh hoạ ranh giới của một rule
đã phát biểu; khi ví dụ và rule mâu thuẫn, **rule thắng**. Mục `## Edge case` của
BR là **hệ quả** của rule, không phải rule mới.

### Hợp đồng và phạm vi sửa

BR `active` và UC `ready` là hợp đồng mà code viết theo. Sửa chúng là quyết định có
chủ đích: task sửa tài liệu MUST nêu chính xác file được phép sửa; khi cần sửa
ngoài phạm vi đó, dừng và nói rõ file nào, vì sao.

Lý do: tài liệu frozen là hợp đồng mà code được viết theo. Một sửa đổi tiện tay
trong lúc làm việc khác sẽ làm code và spec lệch nhau mà không ai để ý — và spec
là thứ phiên sau tin tưởng.

Trong các `OPEN QUESTION` ghi lúc migrate, phần "Nguồn:" nêu đường dẫn **trước
migrate** (`business-rules/`, `use-cases/`, `product/`, `data-model.md`,
`it-scenarios/`); nội dung gốc tra bằng git history trước commit xoá các thư mục đó. Nhãn "(Plan Qn)" / "(Plan OQ-n)" trỏ tới
bảng quyết định và danh sách mâu thuẫn của kế hoạch migration `docs/_migration/plan.md`,
cũng chỉ còn trong git history.

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
python tools/docs/ledger.py seed docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md
python tools/docs/check.py --ledger docs/superpowers/plans/2026-10-04-ui-docs-restructure-ledger.md
python -m unittest discover -s tools/docs -p 'test_*.py'
```

`check.py` kiểm frontmatter, ID (format, trùng, khớp tên file và DOMAIN của thư
mục), `rules`/`superseded_by`, path trong `code`, link tương đối, ID và
`invariant Qn` được trích, section bắt buộc, `_generated/` có lỗi thời không. Link trong
`docs/superpowers/` không được kiểm (tài liệu lịch sử, [ADR-019](shared/decisions/ADR-019-app-la-chuan-ui.md),
[ADR-021](shared/decisions/ADR-021-tai-lieu-dan-dat-ui-khi-xay-lai.md)). WARNING (không fail):
BR active không FN nào trích, FN active không UC hay màn nào gọi, UC ready chưa có code hay test,
INV-UI chưa có gì enforce. Chi tiết ở docstring của hai script.
