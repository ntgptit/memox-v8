# Documentation — MemoX V8

Bản đồ tài liệu cho người và AI agent: cái gì nằm ở đâu, ID đặt thế nào, và
kiểm chứng bằng lệnh nào. Danh mục chi tiết từng rule/use case **không** viết ở
đây — nó được sinh ở [`_generated/index.md`](_generated/index.md).

## Sản phẩm

### Problem

Người học từ vựng quên phần lớn những gì vừa học nếu ôn tập không đúng thời
điểm. Ôn thủ công bằng sổ tay hoặc file không cho biết *khi nào* cần ôn lại từ
nào, nên người học hoặc ôn quá sớm (lãng phí) hoặc quá muộn (đã quên).

### Target users

| Group | Context | What they need | Not the target |
|---|---|---|---|
| Người tự học từ vựng | Học lẻ trên điện thoại, thời gian rời rạc, kết nối không ổn định | Ôn đúng thời điểm, dùng được mọi lúc kể cả offline | Lớp học có giáo viên quản lý |
| Người ôn thi | Khối lượng từ lớn, có deadline | Theo dõi tiến độ, ưu tiên từ sắp quên | Người cần nội dung biên soạn sẵn |

**Đã chốt:** người dùng tự tạo nội dung, **và** app cung cấp starter deck dưới
dạng template để người dùng sao chép về. Nội dung starter hiện tại là
fixture của dự án, chỉ phục vụ development và test — không phải nội dung
production (BR-STARTER-010). Import/export vẫn ở nice-to-have.

### Core value

Ôn đúng từ vào đúng thời điểm, hoạt động đầy đủ khi không có mạng.

Quyết định nền tảng: [ADR-001](shared/decisions/ADR-001-quyet-dinh-nen-tang.md). Dữ liệu nhạy cảm: [ADR-002](shared/decisions/ADR-002-du-lieu-nhay-cam-va-chua-ma-hoa-database.md).

### Phạm vi MVP

Nguyên tắc: MVP là **một vertical slice chạy được từ Drift đến màn hình**, đủ để
chứng minh kiến trúc local-only (không network) và cơ chế Drift migration hoạt
động. Không phải bản đầy đủ tính năng.

#### Must-have

| # | Feature | Done when |
|---|---|---|
| M1 | Tạo/sửa/xoá deck | Deck tồn tại sau khi restart app; xoá deck cần xác nhận và cascade xoá vĩnh viễn toàn bộ card ngay, không qua Trash (BR-DECK-022, BR-DECK-023) |
| M2 | Tạo/sửa/xoá card trong deck | Card có mặt trước/sau; sửa không làm mất lịch sử ôn tập |
| M3 | Phiên học theo lịch SRS | Chỉ hiện card đến hạn; đánh giá kết quả cập nhật lịch ôn lần sau |
| M4 | Danh sách deck với tiến độ | Mỗi deck hiện số card đến hạn hôm nay |
| M5 | Hoạt động đầy đủ offline | Bật chế độ máy bay, mọi chức năng trên vẫn chạy bình thường |

Hai trục độc lập (thuật toán SRS và StudyMode) và hai loại phiên: xem [`features/study-mode/README.md`](features/study-mode/README.md).

#### Should-have

| # | Feature | Done when |
|---|---|---|
| S1 | Tìm kiếm card trong deck | Trong phạm vi: tìm theo nội dung mặt trước/sau trong deck đang mở, không phân biệt hoa thường và giữ dấu. Tìm toàn thư viện là UC-SEARCH-001 |
| S2 | Thống kê ôn tập cơ bản | Trong phạm vi (UC-PROGRESS-001, BR-PROGRESS-009…BR-PROGRESS-018): số card đã học hôm nay tách Learning/Reviewing, streak theo ngày, và hoạt động bảy ngày gần nhất. Ngoài phạm vi: accuracy, longest streak, goal, XP, heatmap và lọc theo deck (BR-PROGRESS-010) |
| S3 | Đảo chiều card (nghĩa → từ) | Trong phạm vi (UC-STUDY-003, BR-MODE-013…BR-MODE-019): chọn chiều hỏi trước lượt đầu, chỉ cho phiên ôn tập `self_assess` của deck `sm2` |

#### Nice-to-have

| # | Feature | Notes |
|---|---|---|
| N1 | Import/export | Trong V8.0 theo [spec card transfer](superpowers/specs/2026-09-26-card-transfer-design.md) (UC-TRANSFER-001, UC-TRANSFER-002, BR-TRANSFER-001…BR-TRANSFER-014): import CSV/TSV/XLSX hoặc văn bản dán (màn 11), export nội dung (sheet 12) — không phải backup. Backend BE-B3 xong; UI là FE-B3 |
| N2 | Nhắc nhở ôn tập hằng ngày | Sub-project sau (UC-REMINDER-001, BR-REMINDER-001…BR-REMINDER-012): opt-in, mặc định tắt, một tóm tắt mỗi ngày dựng từ workload đến hạn tại thời điểm hiện tại. Quyền notification chỉ được xin **sau** khi người dùng bật (BR-REMINDER-011) |
| N3 | Tag/phân loại card | Sub-project sau (UC-TAG-001, BR-TAG-003…BR-TAG-011): catalog phạm vi library, lọc nhiều tag theo OR, đổi tên có gộp, và xoá. Ngoài phạm vi: tag phân cấp, màu tag, taxonomy chia sẻ |

#### Explicitly out of MVP

| Feature | Why deferred | Revisit when |
|---|---|---|
| Đăng nhập / tài khoản | Không có backend; thêm auth lúc này là xây UI cho thứ chưa dùng được | Khi Spring Boot backend sẵn sàng |
| Đồng bộ đa thiết bị | Cần backend và conflict resolution | Cùng lúc với auth |
| iOS | Ổn định Android trước để tránh sửa lỗi trên hai nền tảng cùng lúc | Sau khi Android ổn định về UX + migration + test |
| Phân quyền theo role | Chỉ có một loại user, kể cả sau khi có auth | Chưa có kế hoạch |
| Chia sẻ deck giữa người dùng | Cần backend | Sau đồng bộ |
| Audio / hình ảnh trong card | Kéo theo lưu trữ file, đồng bộ file, nén ảnh — một khối lượng riêng | Sau MVP |

## Bản đồ

```
docs/
├── README.md                    # file này
├── glossary.md                  # thuật ngữ, trỏ về định nghĩa gốc
├── wbs_BE.md                    # tiến độ backend: đã xong, còn lại, thứ tự làm
├── wbs_FE.md                    # tiến độ frontend: đã xong, còn lại, thứ tự làm
├── shared/
│   ├── rules/                   # BR-CORE-NNN-<slug>.md — rule không feature nào sở hữu
│   ├── decisions/               # ADR-NNN-<slug>.md
│   ├── data/                    # schema.md — bảng, cột, index, invariant `-- N.`
│   ├── ui/
│   │   ├── navigation.md        # điều hướng toàn app
│   │   ├── design-handoff.json  # nguồn: handoff thiết kế V3 (foundations, theme, 46 widget)
│   │   └── design-handoff/      # KHÔNG SỬA TAY — sinh từ design-handoff.json
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

`shared/ui/design-handoff/` là bản tách nguyên văn của handoff thiết kế V3 (design
kit `ui_kits/mobile/v3`) trong [`design-handoff.json`](shared/ui/design-handoff.json):
foundations, theme binding và spec của 46 widget; đọc từ
[`00-index.md`](shared/ui/design-handoff/00-index.md). Nội dung chỉ đổi khi JSON đổi:
thay JSON rồi chạy `python tools/docs/split_handoff.py`; tool dừng và không ghi gì nếu
gặp file bị sửa tay. Đây là bản gốc chưa sửa. Vấn đề đã biết (contrast của token,
a11y, mâu thuẫn giữa các file, typography tiếng Việt/tiếng Hàn, study loop chưa thiết
kế) ghi ở
[`.impeccable/critique/2026-09-21T06-26-58Z__handoff-out.md`](../.impeccable/critique/2026-09-21T06-26-58Z__handoff-out.md);
bản đã sửa tay trước đợt reset docs V8 chỉ còn trong git
(`git show d0b9250:docs/design/memox-v3/CHANGES.md`).
Thư mục cạnh đó, `shared/ui/screen-handoff/`, là screen handoff viết tay từ artifact "MemoX — Mobile UI Kit v3" và không do tool sinh ra ([index](shared/ui/screen-handoff/00-index.md)).

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
- Điều hướng toàn app: `shared/ui/navigation.md`.

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

Dòng `**Enforced by:**` trong `## Rule` của BR giữ cột "Enforced by" của bảng BR cũ:
chỗ rule được cưỡng chế — `domain`, `db`, `UI`, `scheduler`, `script`, … — hoặc `—`
nếu chưa cưỡng chế được. `Enforced by` là field có giá trị thực tế cao nhất khi code: nó nói cho người
triển khai biết rule này sống ở đâu trong hệ thống, và nó phơi bày những rule
hiện chưa có gì cưỡng chế.

Rule cần nhiều hơn một câu (ví dụ có bảng tra) MUST dùng dạng section
`### BR-<CODE>-nnn · <tiêu đề>` và vẫn phải xuất hiện Status/Enforced by/Related
ngay dưới tiêu đề.

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
(`draft | active | deprecated`), `superseded_by` khi deprecated.

Section không áp dụng: ghi "Không áp dụng", không xoá heading. Quan hệ chỉ khai
báo một chiều: UC khai báo `rules`; không viết reverse link hay index bằng tay.

### Viết use case

UC được viết khi feature được chọn để đặc tả; phạm vi ship của feature (V8.0 hay
sub-project sau) ghi ở README của feature đó. Không đặc tả trước những thứ chưa
được chọn — đặc tả trước những thứ có thể bị cắt là lãng phí. (Chủ dự án chốt khi
xử lý OQ-11 (2026-09-23).)

Luồng viết bằng ngôn ngữ người dùng, không nói theo màn hình hay widget. Màn
hình sẽ đổi; luồng thì không.

`Error flows` và `UI states` là hai mục hay bị bỏ và là nguồn của phần lớn màn
hình thiếu trạng thái. MUST liệt kê đủ; trạng thái không xảy ra thì MUST nói rõ
vì sao thay vì im lặng bỏ. Trong cấu trúc mới, hai mục đó nằm ở `## Alternative / Error flow` và `## UI`.

Mỗi UC mô tả mình và im lặng về những UC bên cạnh. Các UC nối vào nhau thế nào
thì xem [`shared/ui/navigation.md`](shared/ui/navigation.md) và `ui.md` của từng
feature; các sơ đồ đó tham chiếu ngược về UC bằng ID và không phát biểu lại luồng nào.

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
python tools/docs/split_handoff.py                             # khi JSON đổi: sinh lại docs/shared/ui/design-handoff/
python tools/docs/generate.py                                  # sinh docs/_generated/
python tools/docs/check.py                                     # ERROR → exit 1
```

`check.py` kiểm frontmatter, ID (format, trùng, khớp tên file và DOMAIN của thư
mục), `rules`/`superseded_by`, path trong `code`, link tương đối, ID và
`invariant Qn` được trích, section bắt buộc, `_generated/` có lỗi thời không, và
`shared/ui/design-handoff/` có khớp từng byte với bản sinh lại từ JSON không (thiếu,
bị sửa tay hay thừa file đều là ERROR). WARNING (không fail): BR active không UC nào
dùng, UC ready có `code: []` hoặc chưa có test chứa ID. Chi tiết ở docstring của ba
script.
