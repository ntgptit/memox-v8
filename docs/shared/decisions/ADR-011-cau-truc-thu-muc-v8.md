---
id: ADR-011
title: Cấu trúc thư mục V8
status: active
superseded_by:
---
## Bối cảnh

[ADR-010](ADR-010-kien-truc-lop-v8-va-tooling.md) quyết định 2 chọn "cấu trúc lớp mà
tooling đang giả định, mô tả trong skill `flutter-architecture`". Nhưng skill đó và các
skill quanh nó mô tả memox-v7 như đã build. Chúng trỏ tới tài liệu V7 không có trong
repo này (`docs/architecture.md` cho AD-12/AD-15, `docs/wbs.md`), nên V8 chưa có tài
liệu nào của riêng mình ghi cây thư mục. Foundation plan ngày 2026-09-23 vì vậy đã chọn
`domain/` phẳng và một barrel cho mỗi feature. Cả ba công cụ đều từ chối cách làm đó:
guard `memox-v8` báo 11 ERROR `domain_file_role_suffix`, test CI
`test_every_feature_source_uses_a_known_top_level_layer` fail, và verification planner
không còn nhận ra public contract để chọn test.

Chủ dự án chốt 12 quyết định dưới đây ngày 2026-09-23. Thiết kế đầy đủ và bằng chứng nằm
ở [spec](../../superpowers/specs/2026-09-23-v8-folder-architecture-design.md).

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| D1 | Bên trong feature | Dùng các bucket và suffix tên file mà tooling đang kiểm (xem mục "Cây thư mục"). Thư mục chỉ xuất hiện cùng file thật đầu tiên |
| D2 | Phụ thuộc giữa feature | Hai đồ thị. `depends_on` trong docs là chiều dữ liệu, dùng để chọn test. Map import Dart là chiều contract, không có chu trình, `srs` là nền |
| D3 | Public API của feature | Import thẳng `domain/{entities,models,repositories,failures}`; không dùng barrel |
| D4 | Use case | Phê chuẩn AD-12: trong feature có UI, mọi tương tác đi qua đúng một use case, kể cả use case mỏng |
| D5 | Ngoại lệ của AD-12 | Không có, kể cả settings |
| D6 | Lý do từ chối | Mỗi feature có một enum lý do trong `domain/failures/`. `Outcome<T, R extends Enum>` trong `core/error/` là kiểu generic |
| D7 | Luật nghiệp vụ thuần | Là member của entity, hoặc của value object trong `domain/models/`. Lý do từ chối nằm ở `domain/failures/` |
| D8 | Widget | Phê chuẩn AD-15: `widgets/{sections,items,overlays,support}/`, sâu đúng một cấp |
| D9 | Nơi ghi quyết định | ADR này cụ thể hoá quyết định 2 của ADR-010; ADR-010 giữ nguyên |
| D10 | Gate kiểm chứng | Theo giai đoạn (xem mục "Gate") |
| D11 | `lib/core/` | Mỗi concern một thư mục |
| D12 | Hạ tầng test dùng chung | `test/support/` |

### Cây thư mục

```
lib/
├── main.dart
├── app/             composition root; router/ khi đã có route
├── core/            hạ tầng không biết feature nào: database/, error/, id/…
├── l10n/            ARB en/vi, từ chuỗi UI đầu tiên
├── shared/widgets/  component Mx*, từ sub-project design system
└── features/<f>/    <f> theo ADR-010 quyết định 1
    ├── domain/{entities,models,repositories,failures,usecases}/
    ├── data/{datasources,mappers,repositories,models}/
    ├── di/
    └── presentation/{screens,controllers,states,providers}/
        └── widgets/{sections,items,overlays,support}/
test/
├── architecture/  core/<concern>/  database/  integration/  support/
└── features/<f>/{domain,data,presentation}/
```

Cây này cho biết file đặt ở đâu, không phải danh sách thư mục phải tạo trước.

- Mọi file của feature nằm trong một bucket của layer; riêng `di/` là phẳng.
- Không file nào nằm thẳng trong `domain/`, `data/`, `presentation/`, `widgets/`, hay ở
  gốc thư mục feature.
- Suffix tên file theo bucket: `_entity`, `_model` (với `_scheduler`, `_mode` cho
  strategy của `srs`, `study_mode`), `_repository`, `_failure`, `_use_case`,
  `_dao`/`_data_source`, `_mapper`, `_repository_impl`, `_provider`, `_screen`,
  `_controller`, `_state`, `_widget`.
- Không tạo các thư mục sau cho tới khi có ADR mở nhu cầu: `core/network/`,
  `core/storage/`, `core/utils/`, `app/config/`, flavor, `app/di/`, `shared/models/`,
  `shared/extensions/`.

### Luật phụ thuộc

- `domain/` là Dart thuần: không import Flutter, Riverpod, Drift, `core/database/`,
  `app/`, `shared/`, cũng không import layer khác.
- `data/` import `domain/` của chính feature và `core/`. `di/` import `data/`, `domain/`
  của chính feature và `core/`. `presentation/` không bao giờ import `data/`.
- Giữa các feature:
  - Được import `domain/{entities,models,repositories,failures}/` của feature khác.
  - `di/` của feature khác chỉ được import từ `presentation/` và `di/`.
  - Không bao giờ import `data/`, `presentation/`, `domain/usecases/` của feature khác.
- Map import Dart khai báo trong `test/architecture/boundary_rules.dart`, không có chu
  trình:
  - Hiện gồm `srs → ∅`, `deck → {srs}`, `card → {deck, srs}`.
  - Feature mới thêm entry của nó trong chính commit tạo thư mục feature.
  - Map này có thể khác `depends_on` trong docs. `deck` và `card` cần contract của `srs`
    (BR-SRS-001, BR-CARD-004, UC-CARD-002), còn `srs` đọc dữ liệu của `deck`/`card` qua
    `core/database/` khi reset và khi khoá scheduler.
  - Việc chọn test vẫn an toàn vì planner quét ngược theo import.
- `core/` không import feature, `app/` hay `shared/`. `shared/` chỉ import `core/`.
  Không feature nào import `app/`.

### Use case, luật, lý do từ chối

- **AD-12 không ngoại lệ (D4, D5).**
  - Feature có `presentation/` thì cũng có `domain/usecases/`.
  - Mỗi tương tác, đọc hay ghi, đi qua đúng một use case; use case chạy phần validate
    đầu vào.
  - CLAUDE.md đòi một lý do cụ thể để giữ use case mỏng. Lý do: mọi feature có cùng một
    hình dạng, nên feature mới chỉ cần nhân bản một khuôn đã biết, và mỗi luật validate
    chỉ có một nơi sở hữu.
- Luật cần dữ liệu đúng tại thời điểm ghi vẫn chạy trong transaction của repository.
- Repository provider nằm ở `di/` và dựng implementation trực tiếp. Provider của use case
  nằm ở `presentation/providers/`.

### Gate

Cho tới khi có file `presentation/` đầu tiên, gate gồm năm bước:

1. `flutter analyze`.
2. `flutter test`.
3. `check_architecture.py`: chỉ zero-scope `all` là lỗi.
4. CI tooling unit tests.
5. Guard `memox-v8`:
   - Rule chưa có target khai báo `targets_pending: <layer>` trong `config/overrides.yaml`.
   - Khi layer đó đã có file mà khai báo vẫn còn, guard báo `stale_targets_pending` và
     gate fail, buộc xoá entry.

Từ màn hình đầu tiên, gate là `dod_check.sh` đầy đủ và allowlist phải rỗng. Lệnh cụ thể
ghi ở `README.md` ở thư mục gốc repo.

## Hệ quả

- Skill `flutter-architecture` và các skill liên quan trỏ về ADR này, thay cho
  `docs/architecture.md` của V7. `feature_blueprint.md` và `project-baseline.md` trở
  thành tài liệu tham khảo V7.
- Foundation plan ngày 2026-09-23 đã được sửa theo ADR này trước khi chạy Task 2.
- Định nghĩa `depends_on` trong `docs/README.md` ghi rõ: chiều import Dart do ADR này quy
  định.
- Việc để lại cho sau, ngoài phạm vi ADR này:
  - Các tham chiếu V7 trong skill không liên quan tới thư mục (`docs/checklist.md`,
    `docs/wbs.md`, các số AD khác).
  - 13 rule `memox_v7.design_system.*` trong ruleset `memox-v8`.
