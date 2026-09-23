# MemoX V8 Folder Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record the approved V8 folder architecture as ADR-011, and make the
tooling, the skills and the root `README.md` enforce and describe it, so that the
foundation plan (already revised to this layout) runs from its Task 2 under a gate
that passes.

**Architecture:** Documentation, skills, tests and tooling only; `lib/` keeps only
`main.dart`. ADR-011 records decisions D1–D12. Three nets enforce the layout: the
Dart rules in `test/architecture/boundary_rules.dart`, which `boundaries_test.dart`
applies to the real `lib/`; `check_architecture.py`, where only an empty `lib/`
stays a fatal zero scope; and the vendored guard, which gains a
`targets_pending: <layer>` rule option so the `memox-v8` ruleset can name each rule
that waits for an unbuilt layer, while any other rule that checks nothing still
fails the gate. The skills that describe folders point to ADR-011.

**Tech Stack:** Flutter 3.47.5 / Dart 3.13.4 (`flutter_test`); Python 3.11 as
`python3` (architecture checker, CI tooling tests, docs tools); Python 3.13 as
`python3.13` (vendored guard and its pytest suite); YAML guard configuration.

**Spec:** [`docs/superpowers/specs/2026-09-23-v8-folder-architecture-design.md`](../specs/2026-09-23-v8-folder-architecture-design.md).
The foundation plan, revised to the spec in the same commit as this plan:
[`2026-09-23-memox-v8-foundation.md`](2026-09-23-memox-v8-foundation.md). Its Task 1
already ran; its Task 2 starts after this plan's Task 9.

## Global Constraints

- Work on branch `claude/project-folder-architecture-gbsw4r`. End every commit
  message with the attribution trailer lines your session is configured to add;
  the commit commands below show the subject line only.
- Language (CLAUDE.md): ADRs and `docs/` prose in Vietnamese, like their
  neighbours; code, identifiers, comments, skills and commit messages in English.
- No product code. `lib/main.dart` stays the only file under `lib/`. A step that
  creates files under `lib/` to prove a check deletes them in the same step, and
  `git status --short lib` prints nothing afterwards.
- No speculative structure: no empty folders, no `.gitkeep`, no barrel files.
- V7 is a reference, not a template (CLAUDE.md): skill text that describes V7 is
  marked as V7, not rewritten into V8 facts that no V8 document states.
- The guard needs Python 3.12 or newer:
  `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8`.
  Its console wraps long lines, so prefix `COLUMNS=400` when you grep its output.
- `python3 -m unittest <file path>` fails on the `.claude` path ("Empty module
  name"). Always run `python3 -m unittest discover -s <dir> -p '<pattern>'`.
- After any change under `docs/`, run `python3 tools/docs/generate.py`, then
  `python3 tools/docs/check.py`, which must end with `0 error(s)` (its warnings
  are pre-existing).
- Links in `docs/` are checked outside code fences and inline code. Never link to
  a file before the task that creates it; write its path in backticks instead.

## Review Focus

1. An entry left in the waiting list after its layer landed must fail the gate,
   not linger (Task 2 test `test_pending_rule_that_gained_targets_reports_a_stale_declaration`;
   Task 3 Step 6).
2. A rule with no target and no `targets_pending` must still fail, also when it
   sits next to pending rules (Task 2 test
   `test_undeclared_rule_next_to_a_pending_one_still_warns`; Task 3 Step 5).
3. A relative import is judged like the package path it names:
   `../../../deck/data/...` from `card/data/` is a cross-feature violation (Task 5
   test `a relative import is judged like its package path`).
4. A barrel, or an `export` of another feature's internals, is rejected like an
   `import` (Task 5 tests `a barrel at the feature root is rejected`,
   `an export of another feature internals fails like an import`, and the barrel
   URI in `data/, presentation/, usecases/ and barrels of another feature fail`).
5. Generated `*.g.dart` files are never read as sources, so a `part of` file cannot
   trip the shape rules (Task 5 test
   `readSources skips generated files and keeps paths repo-relative`).

## File Structure

| File | Task | Change |
|---|---|---|
| `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md` | 1 | create: D1–D12, folder tree, dependency rules, use-case and rejection policy, gate |
| `docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md` | 1 | one bullet under `## Hệ quả` pointing to ADR-011 |
| `docs/README.md` | 1 | one sentence after the `depends_on` definition |
| `docs/_generated/index.md` | 1 | regenerated: ADR-011 row |
| `code-verification-guard-v2/code_verification_guard/constants/config_keys.py` | 2 | `ConfigKeys.TARGETS_PENDING` |
| `code-verification-guard-v2/code_verification_guard/config/config_manager.py` | 2 | validate `targets_pending` |
| `code-verification-guard-v2/code_verification_guard/runner/rule_runner.py` | 2 | info and stale diagnostics |
| `code-verification-guard-v2/tests/test_config_manager.py` | 2 | 5 tests |
| `code-verification-guard-v2/tests/test_rule_runner_config_diagnostics.py` | 2 | 4 tests, `_register` gains `targets_pending` |
| `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml` | 3 | the 40-rule waiting list |
| `.claude/skills/flutter-architecture/scripts/check_architecture.py` | 4 | only the `all` zero scope is fatal |
| `.claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py` | 4 | 3 fixtures |
| `test/architecture/boundary_rules.dart` | 5 | create: the ADR-011 rules as pure functions |
| `test/architecture/boundary_rules_test.dart` | 5 | create: each rule proven on a planted violation |
| `test/architecture/boundaries_test.dart` | 5 | rewrite: the rules applied to the real `lib/` |
| `README.md` | 6 | the phased gate |
| `.claude/skills/flutter-architecture/SKILL.md` | 7 | tree, buckets, dependency rules, AD-12, naming, guard command |
| `.claude/skills/flutter-feature-slice/SKILL.md` | 8 | layout authority is ADR-011; lazy `data/models/`; `test/support/`; guard command |
| `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md` | 8 | V7 banner |
| `.claude/skills/flutter-feature-slice/assets/feature_checklist.md` | 8 | the two lines that restate what Task 8 changes in `SKILL.md` |
| `.claude/skills/flutter-drift/references/project-baseline.md` | 8 | V7 banner |
| `.claude/skills/flutter-testing/SKILL.md` | 8 | V8 `test/` tree; `test/support/` |
| `.claude/skills/flutter-project-setup/SKILL.md` | 8 | §6.2: flavors not in V8 yet |

Out of scope (spec §9), for later work:

- V7 references in skills that are not about folders: `docs/architecture.md`,
  `docs/wbs.md` and `docs/checklist.md` mentions, AD numbers in `flutter-data-layer`
  and `flutter-state-riverpod`, the MX-VIS-001 and Widgetbook steps.
- `--ruleset memox-v7` in `flutter-state-riverpod/SKILL.md`, `flutter-ship/SKILL.md`
  and `flutter-ship/references/ci.md`.
- The 13 `memox_v7.design_system.*` rule ids in the `memox-v8` ruleset.

---

### Task 1: ADR-011 and the documentation pointers

**Files:**
- Create: `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`
- Modify: `docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md` (end of
  `## Hệ quả`, which is the end of the file)
- Modify: `docs/README.md` (after the line that ends the `depends_on` paragraph)
- Regenerate: `docs/_generated/index.md`

**Interfaces:**
- Produces: the decision record `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`
  (id `ADR-011`). Tasks 5–8 cite it by this path and by its decision numbers
  D1–D12.

- [ ] **Step 1: Write ADR-011**

Create `docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md` with exactly this
content:

````markdown
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
````

- [ ] **Step 2: Run the docs check to see the stale index**

Run: `python3 tools/docs/check.py`
Expected: FAIL, with an `ERROR docs/_generated/index.md` line saying the index is
stale (`lỗi thời`): the ADR index does not list ADR-011 yet.

- [ ] **Step 3: Point ADR-010 to ADR-011**

`docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md` ends with the
`## Hệ quả` bullet whose last line is `` `ImpactMapMatchesTheDocsTest` giữ nó khớp với `docs/features/`. ``
Append after it:

```markdown
- Quyết định 2 được cụ thể hoá bởi [ADR-011](ADR-011-cau-truc-thu-muc-v8.md): bucket trong
  từng layer, luật import giữa các feature và gate kiểm chứng theo giai đoạn.
```

- [ ] **Step 4: Add the import-direction sentence to `docs/README.md`**

The `depends_on` paragraph of `docs/README.md` ends with the line
`` chu trình; `verification_impact_map.json` suy ra từ trường này. ``
Insert these lines directly below it, before the blank line:

```markdown
Chiều import Dart giữa các feature trong `lib/features/` do
[ADR-011](shared/decisions/ADR-011-cau-truc-thu-muc-v8.md) quy định riêng và có thể khác
đồ thị này.
```

- [ ] **Step 5: Regenerate and check**

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
git diff --stat docs/_generated
```

Expected: `check.py` ends with `0 error(s)`; the only generated change is one new
row in `docs/_generated/index.md`, for ADR-011 (`Cấu trúc thư mục V8`, `active`).

- [ ] **Step 6: Commit**

```bash
git add docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md docs/README.md docs/_generated
git commit -m "docs(adr): add ADR-011 V8 folder structure"
```

---

### Task 2: Guard `targets_pending` rule option

**Files:**
- Modify: `code-verification-guard-v2/code_verification_guard/constants/config_keys.py`
  (after `COUNT_MODE = "count_mode"`)
- Modify: `code-verification-guard-v2/code_verification_guard/config/config_manager.py`
  (`_validate_optional_rule_fields`; new `_validate_targets_pending`)
- Modify: `code-verification-guard-v2/code_verification_guard/runner/rule_runner.py`
  (module constants; `RuleRunner.run`; new `_target_diagnostics`,
  `_rule_targets_pending_notice`, `_stale_targets_pending_violation`;
  `_missing_literal_path_violations`)
- Test: `code-verification-guard-v2/tests/test_config_manager.py`,
  `code-verification-guard-v2/tests/test_rule_runner_config_diagnostics.py`

**Interfaces:**
- Consumes: `overrides.rule_options.<rule_id>` in a ruleset's
  `config/overrides.yaml`. `ConfigManager.load_rule_definitions` already merges
  those keys into the final rule dict, unknown keys included; the first new test
  pins that.
- Produces:
  - `ConfigKeys.TARGETS_PENDING == "targets_pending"`: an optional rule field whose
    value is a non-empty string naming the awaited layer. Any other value raises
    `ValueError` with `targets_pending` in the message.
  - In `code_verification_guard.runner.rule_runner`:
    `RULE_TARGETS_PENDING_ID = "guard.config.rule_targets_pending"`, reported at
    `info` while the rule has no target file, and
    `STALE_TARGETS_PENDING_ID = "guard.config.stale_targets_pending"`, reported at
    `warning` once it has one. A rule with neither targets nor the field still gets
    `guard.config.rule_without_targets` (`warning`). A pending rule's literal
    include/exclude paths are not reported as `guard.config.missing_target_path`.
  - Task 3 uses the field in `registries/projects/memox-v8/config/overrides.yaml`.

- [ ] **Step 1: Write the failing config tests**

Append to `code-verification-guard-v2/tests/test_config_manager.py`. It already
imports `pytest`, `Path`, `ConfigKeys` and `ConfigManager`, and defines
`write_yaml`, `registry_yaml`, `project_config` and `profile_config`.

```python
def test_targets_pending_from_rule_options_reaches_the_final_rule(tmp_path: Path):
    write_yaml(tmp_path / "registries" / "rules.yaml", registry_yaml("sample.waiting"))
    config = project_config(registries=["registries/rules.yaml"])
    config[ConfigKeys.OVERRIDES][ConfigKeys.RULE_OPTIONS] = {
        "sample.waiting": {ConfigKeys.TARGETS_PENDING: "presentation"},
    }

    rules = ConfigManager().load_rule_definitions(tmp_path, config, profile_config())

    assert rules[0][ConfigKeys.TARGETS_PENDING] == "presentation"


@pytest.mark.parametrize("bad_value", ["", "   ", 3, ["presentation"]])
def test_targets_pending_must_name_a_layer(tmp_path: Path, bad_value: object):
    write_yaml(tmp_path / "registries" / "rules.yaml", registry_yaml("sample.waiting"))
    config = project_config(registries=["registries/rules.yaml"])
    config[ConfigKeys.OVERRIDES][ConfigKeys.RULE_OPTIONS] = {
        "sample.waiting": {ConfigKeys.TARGETS_PENDING: bad_value},
    }

    with pytest.raises(ValueError, match="targets_pending"):
        ConfigManager().load_rule_definitions(tmp_path, config, profile_config())
```

- [ ] **Step 2: Run to verify they fail**

Run: `(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_config_manager.py)`
Expected: `5 failed, 17 passed`, each failure
`AttributeError: type object 'ConfigKeys' has no attribute 'TARGETS_PENDING'`.

- [ ] **Step 3: Add the key and its validation**

In `config_keys.py`, add below `COUNT_MODE = "count_mode"`:

```python
    TARGETS_PENDING = "targets_pending"
```

In `config_manager.py`, the method `_validate_optional_rule_fields` ends with:

```python
        if ConfigKeys.MAX_LINES in rule and not isinstance(rule[ConfigKeys.MAX_LINES], int):
            raise ValueError(f"Rule field '{ConfigKeys.MAX_LINES}' must be a number in {path}")

        self._validate_fix(rule, path)
```

Replace those lines with the following, which calls the new validator before
`_validate_fix` and adds the validator as the next method:

```python
        if ConfigKeys.MAX_LINES in rule and not isinstance(rule[ConfigKeys.MAX_LINES], int):
            raise ValueError(f"Rule field '{ConfigKeys.MAX_LINES}' must be a number in {path}")

        self._validate_targets_pending(rule, path)
        self._validate_fix(rule, path)

    def _validate_targets_pending(self, rule: dict, path: Path) -> None:
        """Validate the optional name of the layer a rule is waiting for."""
        # Rules without the declaration are expected to have targets now.
        if ConfigKeys.TARGETS_PENDING not in rule:
            return

        pending_layer = rule[ConfigKeys.TARGETS_PENDING]

        # The value names the awaited layer, so it must be a non-empty string.
        if isinstance(pending_layer, str) and pending_layer.strip():
            return

        raise ValueError(
            f"Rule field '{ConfigKeys.TARGETS_PENDING}' must be a non-empty string in {path}"
        )
```

- [ ] **Step 4: Run to verify they pass**

Run: `(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_config_manager.py)`
Expected: `22 passed`.

- [ ] **Step 5: Write the failing runner tests**

In `code-verification-guard-v2/tests/test_rule_runner_config_diagnostics.py`,
replace the import from `code_verification_guard.runner.rule_runner` with:

```python
from code_verification_guard.runner.rule_runner import (
    MISSING_TARGET_PATH_ID,
    RULE_TARGETS_PENDING_ID,
    RULE_WITHOUT_TARGETS_ID,
    STALE_TARGETS_PENDING_ID,
    RuleRunner,
)
```

Replace the helper `_register` with this version. The new argument is optional, so
every existing call stays as it is:

```python
def _register(
    registry: RuleRegistry,
    rule_id: str,
    include: list[str],
    targets_pending: str | None = None,
) -> None:
    rule = {
        ConfigKeys.ID: rule_id,
        ConfigKeys.TYPE: "regex",
        ConfigKeys.MODE: "line",
        ConfigKeys.SEVERITY: "error",
        ConfigKeys.ENABLED: True,
        ConfigKeys.MESSAGE: "No print.",
        ConfigKeys.INCLUDE: include,
        ConfigKeys.PATTERNS: ["\\bprint\\s*\\("],
    }
    if targets_pending is not None:
        rule[ConfigKeys.TARGETS_PENDING] = targets_pending
    registry.register(rule)
```

Append at the end of the file:

```python
def test_pending_rule_without_targets_reports_info_only(tmp_path: Path) -> None:
    registry = RuleRegistry()
    registry.clear()
    _register(
        registry,
        "sample.waits_for_ui",
        ["lib/features/*/presentation/**/*.dart"],
        targets_pending="presentation",
    )

    violations = RuleRunner(rule_registry=registry).run(tmp_path)

    assert [(v.rule_id, v.severity) for v in violations] == [
        (RULE_TARGETS_PENDING_ID, "info")
    ]
    assert "sample.waits_for_ui" in violations[0].message
    assert "presentation" in violations[0].message
    registry.clear()


def test_pending_rule_that_gained_targets_reports_a_stale_declaration(tmp_path: Path) -> None:
    screen = tmp_path / "lib" / "features" / "deck" / "presentation" / "screens" / "deck_screen.dart"
    screen.parent.mkdir(parents=True)
    screen.write_text("class DeckScreen {}\n", encoding="utf-8")
    registry = RuleRegistry()
    registry.clear()
    _register(
        registry,
        "sample.waits_for_ui",
        ["lib/features/*/presentation/**/*.dart"],
        targets_pending="presentation",
    )

    violations = RuleRunner(rule_registry=registry).run(tmp_path)

    assert [(v.rule_id, v.severity) for v in violations] == [
        (STALE_TARGETS_PENDING_ID, "warning")
    ]
    assert "sample.waits_for_ui" in violations[0].message
    registry.clear()


def test_pending_rule_does_not_report_its_missing_literal_path(tmp_path: Path) -> None:
    registry = RuleRegistry()
    registry.clear()
    _register(
        registry,
        "sample.waits_for_arb",
        ["lib/l10n/app_en.arb"],
        targets_pending="l10n",
    )

    violations = RuleRunner(rule_registry=registry).run(tmp_path)

    assert [v.rule_id for v in violations] == [RULE_TARGETS_PENDING_ID]
    registry.clear()


def test_undeclared_rule_next_to_a_pending_one_still_warns(tmp_path: Path) -> None:
    registry = RuleRegistry()
    registry.clear()
    _register(
        registry,
        "sample.waits_for_ui",
        ["lib/features/*/presentation/**/*.dart"],
        targets_pending="presentation",
    )
    _register(registry, "sample.dead_rule", ["lib/data/sync/**/*.dart"])

    violations = RuleRunner(rule_registry=registry).run(tmp_path)

    assert sorted((v.rule_id, v.severity) for v in violations) == [
        (RULE_TARGETS_PENDING_ID, "info"),
        (RULE_WITHOUT_TARGETS_ID, "warning"),
    ]
    registry.clear()
```

- [ ] **Step 6: Run to verify they fail**

Run: `(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_rule_runner_config_diagnostics.py)`
Expected: FAIL at collection:
`ImportError: cannot import name 'RULE_TARGETS_PENDING_ID' from 'code_verification_guard.runner.rule_runner'`.

- [ ] **Step 7: Implement the runner diagnostics**

In `rule_runner.py`, add below `MISSING_TARGET_PATH_ID = "guard.config.missing_target_path"`:

```python
# A rule may declare `targets_pending: <layer>` when its targets arrive with a
# layer the project has not built yet. It is then reported at info level while
# it has no targets, and as a warning once it has some, so the declaration
# cannot outlive its reason.
RULE_TARGETS_PENDING_ID = "guard.config.rule_targets_pending"
STALE_TARGETS_PENDING_ID = "guard.config.stale_targets_pending"
```

In `RuleRunner.run`, replace

```python
            violations.extend(rule.check(project_root))

            # A rule with an empty target set silently checks nothing.
            if not rule.target_files(project_root):
                config_diagnostics.append(
                    self._rule_without_targets_violation(rule, project_root)
                )
```

with

```python
            violations.extend(rule.check(project_root))
            config_diagnostics.extend(
                self._target_diagnostics(rule, rule_config, project_root)
            )
```

Add these three methods to `RuleRunner`, directly above
`_rule_without_targets_violation`:

```python
    def _target_diagnostics(
        self,
        rule: BaseRule,
        rule_config: dict,
        project_root: Path,
    ) -> list[Violation]:
        """Report a rule that checks nothing, unless it declares what it waits for."""
        pending_layer = rule_config.get(ConfigKeys.TARGETS_PENDING)
        has_targets = bool(rule.target_files(project_root))

        # The awaited layer has landed; the declaration must go.
        if has_targets and pending_layer:
            return [self._stale_targets_pending_violation(rule, pending_layer, project_root)]

        # A rule with targets and no declaration is the healthy case.
        if has_targets:
            return []

        # An empty target set is expected while the declared layer is missing.
        if pending_layer:
            return [self._rule_targets_pending_notice(rule, pending_layer, project_root)]

        # A rule with an empty target set silently checks nothing.
        return [self._rule_without_targets_violation(rule, project_root)]

    def _rule_targets_pending_notice(
        self,
        rule: BaseRule,
        pending_layer: str,
        project_root: Path,
    ) -> Violation:
        """Report a rule that has no targets yet because its layer is not built."""
        return Violation(
            rule_id=RULE_TARGETS_PENDING_ID,
            severity=Severity.INFO,
            message=(
                f"Rule `{rule.rule_id}` has no target files yet; it waits for the "
                f"`{pending_layer}` layer (targets_pending)."
            ),
            file_path=project_root,
            fix_hint=(
                "Nothing to do until that layer lands. The declaration then turns "
                "into a stale_targets_pending warning."
            ),
        )

    def _stale_targets_pending_violation(
        self,
        rule: BaseRule,
        pending_layer: str,
        project_root: Path,
    ) -> Violation:
        """Report a targets_pending declaration whose rule now has targets."""
        return Violation(
            rule_id=STALE_TARGETS_PENDING_ID,
            severity=Severity.WARNING,
            message=(
                f"Rule `{rule.rule_id}` declares targets_pending `{pending_layer}` "
                "but now has target files, so the declaration is stale."
            ),
            file_path=project_root,
            fix_hint=(
                "Remove the rule's targets_pending entry from the ruleset's "
                "config/overrides.yaml."
            ),
        )
```

In `_missing_literal_path_violations`, replace

```python
            rule_id = rule_config.get(ConfigKeys.ID, "<unknown>")

            for config_key in (ConfigKeys.INCLUDE, ConfigKeys.EXCLUDE):
```

with

```python
            rule_id = rule_config.get(ConfigKeys.ID, "<unknown>")

            # A rule waiting for a layer expects its literal paths to be absent.
            if rule_config.get(ConfigKeys.TARGETS_PENDING):
                continue

            for config_key in (ConfigKeys.INCLUDE, ConfigKeys.EXCLUDE):
```

- [ ] **Step 8: Run the two files, then the whole guard suite**

```bash
(cd code-verification-guard-v2 && python3.13 -m pytest -q tests/test_config_manager.py tests/test_rule_runner_config_diagnostics.py)
(cd code-verification-guard-v2 && python3.13 -m pytest -q)
```

Expected: `31 passed`, then `204 passed` (195 before this task).

- [ ] **Step 9: Commit**

```bash
git add code-verification-guard-v2/code_verification_guard code-verification-guard-v2/tests
git commit -m "feat(guard): targets_pending rule option for rules awaiting a layer"
```

---

### Task 3: `memox-v8` waiting list

**Files:**
- Modify: `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
  (insert directly below the line `  rule_options:`)

**Interfaces:**
- Consumes: the `targets_pending` field (Task 2).
- Produces: 40 entries in seven groups, each group headed by a comment line that
  starts with `# --` and names its layer: `domain` (6), `providers` (3), `data` (1),
  `app` (2), `presentation` (25), `l10n` (1), `visual-audit` (2). Foundation plan
  Tasks 3, 5, 7 and 10 delete the `domain`, `providers`, `data` and `app` groups as
  those layers land (12 entries); the other 28 wait for the UI sub-project.

- [ ] **Step 1: See the gate fail today**

Run: `COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 | grep 'Total:'; echo "exit ${PIPESTATUS[0]}"`
Expected: `Total: 41 | Errors: 0 | Warnings: 41 | Info: 0` and `exit 1`: 40
`guard.config.rule_without_targets` plus one `guard.config.missing_target_path`
(`lib/l10n/app_en.arb`).

- [ ] **Step 2: Insert the waiting list**

In `overrides.yaml`, directly below `  rule_options:` and above the existing comment
`    # Generated code is not hand-written; length limits on it are noise.`, insert:

```yaml
    # Phased gate (ADR-011, spec 2026-09-23-v8-folder-architecture-design.md
    # section 8). Each rule below has no target files yet because the layer
    # it checks has not been built. `targets_pending` names that layer: the
    # guard reports the rule at info level while it waits, and as a
    # stale_targets_pending WARNING once it has targets. When that warning
    # appears, delete the rule's entry here in the same commit that added the
    # layer. The list must be empty before the full dod_check.sh gate applies.
    # -- `domain`: waits for the first lib/features/*/domain/ file (foundation plan Task 3)
    memox.architecture.domain_no_infrastructure_import:
      targets_pending: domain
    memox.architecture.no_drift_type_in_domain:
      targets_pending: domain
    memox.architecture.no_transaction_outside_data_layer:
      targets_pending: domain
    memox.architecture.single_study_mode_dispatch:
      targets_pending: domain
    memox.data_model.scheduler_no_ambient_now:
      targets_pending: domain
    memox.naming.domain_file_role_suffix:
      targets_pending: domain
    # -- `providers`: waits for the first *_provider.dart file (foundation plan Task 5)
    memox.state_management.controller_no_build_context:
      targets_pending: providers
    memox.state_management.notifier_no_public_mutable_field:
      targets_pending: providers
    memox.state_management.state_write_after_await_requires_mounted:
      targets_pending: providers
    # -- `data`: waits for the first lib/features/*/data/ file (foundation plan Task 7)
    memox.naming.data_file_role_suffix:
      targets_pending: data
    # -- `app`: waits for the first lib/app/ file (foundation plan Task 10)
    memox.design_token.no_raw_text_style:
      targets_pending: app
    memox_v7.design_system.no_bare_font_weight:
      targets_pending: app
    # -- `presentation`: waits for the first presentation/ or shared/ UI file (UI sub-project)
    memox.architecture.presentation_no_data_import:
      targets_pending: presentation
    memox.architecture.widget_no_database_access:
      targets_pending: presentation
    memox.architecture.widget_no_repository_access:
      targets_pending: presentation
    memox.architecture.widgets_grouped_into_buckets:
      targets_pending: presentation
    memox.data_model.review_actions_from_supported_actions:
      targets_pending: presentation
    memox.design_token.no_raw_border_radius:
      targets_pending: presentation
    memox.design_token.no_raw_color:
      targets_pending: presentation
    memox.design_token.no_raw_duration:
      targets_pending: presentation
    memox.design_token.no_raw_spacing_literal:
      targets_pending: presentation
    memox.design_token.no_raw_stroke_width:
      targets_pending: presentation
    memox.error_handling.no_technical_detail_in_user_message:
      targets_pending: presentation
    memox.error_handling.ui_never_sees_infrastructure_exception:
      targets_pending: presentation
    memox.i18n.no_literal_user_string:
      targets_pending: presentation
    memox.naming.presentation_file_role_suffix:
      targets_pending: presentation
    memox.state_management.no_shared_is_loading_flag:
      targets_pending: presentation
    memox_v7.design_system.no_flat_style_from:
      targets_pending: presentation
    memox_v7.design_system.no_raw_button:
      targets_pending: presentation
    memox_v7.design_system.no_raw_choice_chip:
      targets_pending: presentation
    memox_v7.design_system.no_raw_icon_color:
      targets_pending: presentation
    memox_v7.design_system.no_raw_loading_indicator:
      targets_pending: presentation
    memox_v7.design_system.no_raw_screen_chrome:
      targets_pending: presentation
    memox_v7.design_system.no_raw_sheet_route:
      targets_pending: presentation
    memox_v7.design_system.no_raw_style_escape:
      targets_pending: presentation
    memox_v7.design_system.no_raw_widget:
      targets_pending: presentation
    memox_v7.design_system.no_text_restyle:
      targets_pending: presentation
    # -- `l10n`: waits for lib/l10n/app_en.arb (the first user-visible string)
    memox.i18n.arb_entry_needs_description:
      targets_pending: l10n
    # -- `visual-audit`: waits for the first test/visual_audit/ companion (UI sub-project)
    memox.visual.production_screen_audit_not_exploratory:
      targets_pending: visual-audit
    memox.visual.production_screen_audit_not_skipped:
      targets_pending: visual-audit
```

- [ ] **Step 3: Run the guard**

Run the Step 1 command.
Expected: `Total: 40 | Errors: 0 | Warnings: 0 | Info: 40` and `exit 0`: one
`guard.config.rule_targets_pending` notice per entry.

- [ ] **Step 4: Commit**

```bash
git add code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml
git commit -m "chore(guard): list the memox-v8 rules that wait for an unbuilt layer"
```

- [ ] **Step 5: Prove an undeclared rule still fails**

Delete these two lines from `overrides.yaml`:

```yaml
    memox.i18n.arb_entry_needs_description:
      targets_pending: l10n
```

Run the Step 1 command.
Expected: `Total: 41 | Errors: 0 | Warnings: 2 | Info: 39` and `exit 1`: one
`guard.config.rule_without_targets` and one `guard.config.missing_target_path`.
Restore the file:
`git checkout -- code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.

- [ ] **Step 6: Prove a stale declaration fails**

```bash
mkdir -p lib/features/deck/domain/entities
printf 'class DeckEntity {}\n' > lib/features/deck/domain/entities/deck_entity.dart
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 | grep 'Total:'; echo "exit ${PIPESTATUS[0]}"
rm -r lib/features
git status --short
```

Expected: `Total: 40 | Errors: 0 | Warnings: 6 | Info: 34` and `exit 1`: one
`guard.config.stale_targets_pending` per `domain` entry. Then `git status --short`
prints nothing.

---

### Task 4: `check_architecture.py`: only an empty `lib/` is a zero scope

**Files:**
- Modify: `.claude/skills/flutter-architecture/scripts/check_architecture.py` (`_check_scope`)
- Test: `.claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py`

**Interfaces:**
- Produces: `check_architecture.py` exits 0 on a tree with only `lib/main.dart`, and
  on a feature with any subset of layers; it exits 1 with `zero scope: all` when
  `lib/` holds no Dart file. It still prints the per-layer counts. A renamed layer
  is caught by name: by the CI tooling test
  `test_every_feature_source_uses_a_known_top_level_layer` (unchanged) and by the
  shape rules of Task 5.

- [ ] **Step 1: See the checker fail today**

Run: `python3 .claude/skills/flutter-architecture/scripts/check_architecture.py; echo "exit $?"`
Expected: `✗ 5 boundary violation(s)` (`zero scope: features`, `domain`, `data`,
`presentation`, `di`) and `exit 1`, because `lib/` holds only `main.dart`.

- [ ] **Step 2: Write the failing fixtures**

In `.claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py`:

1. Add `import shutil` to the imports, directly above `import subprocess`.
2. In `_project`, replace the comment

```python
        # `presentation/` and `di/` exist because the checker refuses a layer
        # that matches nothing — "every rule scoped to it passed without
        # inspecting anything" is its own wording. A fixture missing a layer
        # fails for that reason instead of the planted one, which is exactly
        # the unattributable failure the clean case below rules out.
```

with

```python
        # All four layers are present so that every rule has a file to
        # inspect. A missing layer is legitimate under ADR-011 (a layer
        # appears with its first real file) and has its own test below.
```

3. Insert these three tests directly above
   `def test_a_project_with_no_lib_but_a_pubspec_fails`:

```python
    def test_a_tree_without_presentation_or_di_passes(self) -> None:
        # ADR-011: a layer appears with its first real file, so the foundation
        # has domain/ and data/ long before any screen or provider. Missing
        # optional layers must not fail the check.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._project(root)
            deck = root / "lib" / "features" / "deck"
            shutil.rmtree(deck / "presentation")
            shutil.rmtree(deck / "di")

            result = self._run(root)

            self.assertEqual(
                result.returncode,
                0,
                msg=f"a lazily-built layer was treated as missing.\n{result.stdout}",
            )

    def test_a_fresh_tree_with_only_main_passes(self) -> None:
        # The state right after `flutter create`: no feature yet, nothing
        # wrong with that, and nothing for the feature rules to inspect.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "pubspec.yaml").write_text("name: fixture\n", encoding="utf-8")
            (root / "lib").mkdir()
            (root / "lib" / "main.dart").write_text("void main() {}\n", encoding="utf-8")

            result = self._run(root)

            self.assertEqual(result.returncode, 0, msg=result.stdout)

    def test_a_lib_without_dart_files_fails(self) -> None:
        # The zero scope that stays fatal: a checker that read no file at all
        # is reporting success for having looked at nothing.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "pubspec.yaml").write_text("name: fixture\n", encoding="utf-8")
            (root / "lib").mkdir()

            result = self._run(root)

            self.assertEqual(result.returncode, 1, msg=result.stdout)
            self.assertIn("zero scope: all", result.stdout)
```

- [ ] **Step 3: Run to verify they fail**

Run: `python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_architecture_checker.py'`
Expected: `FAILED (failures=2)`: `test_a_fresh_tree_with_only_main_passes` and
`test_a_tree_without_presentation_or_di_passes`. The third new test already passes,
because the current rule also fails an empty `lib/`.

- [ ] **Step 4: Make only the `all` scope fatal**

Replace the whole `_check_scope` function with:

```python
def _check_scope(files: list[tuple[str, list[str]]], lib: str) -> None:
    # 9. Scope. Every rule above selects files by path fragment, so a checker
    #    that matched no file at all passed by looking at nothing: zero files
    #    under lib/ is a hard failure. The per-layer counts are reported, not
    #    required. ADR-011 creates a layer with its first real file, so a tree
    #    with domain/ and no data/ yet is legitimate. A renamed layer or
    #    top-level folder is caught by name instead: the known-layer CI test
    #    and the shape rules in test/architecture/boundaries_test.dart fail on
    #    any folder outside the ADR-011 list.
    paths = [p for p, _ in files]
    scopes = {
        "all": len(paths),
        "features": sum("/features/" in p for p in paths),
        "domain": sum("/domain/" in p for p in paths),
        "data": sum("/data/" in p for p in paths),
        "presentation": sum("/presentation/" in p for p in paths),
        "di": sum("/di/" in p for p in paths),
    }
    print("-" * 60)
    print(
        f"scanned {scopes['all']} files under {lib} — features "
        f"{scopes['features']} (domain {scopes['domain']}, data {scopes['data']}"
        f", presentation {scopes['presentation']}, di {scopes['di']})"
    )
    if scopes["all"] > 0:
        return
    _error(
        "zero scope: all",
        lib,
        "No Dart file under lib/, so every rule passed without inspecting "
        "anything. Either the sources moved or the path changed.",
    )
```

- [ ] **Step 5: Run to verify they pass**

```bash
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_architecture_checker.py'
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py; echo "exit $?"
```

Expected: `Ran 8 tests` and `OK`; then `Ran 82 tests` and `OK (skipped=11)`; then
`scanned 1 files under lib — features 0 (domain 0, data 0, presentation 0, di 0)`,
`✓ architecture boundaries clean` and `exit 0`.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/flutter-architecture/scripts/check_architecture.py .claude/skills/flutter-workflow/scripts/tests/test_architecture_checker.py
git commit -m "fix(tooling): only an empty lib/ is a fatal zero scope"
```

---

### Task 5: ADR-011 boundary rules

**Files:**
- Create: `test/architecture/boundary_rules.dart`, `test/architecture/boundary_rules_test.dart`
- Modify (rewrite): `test/architecture/boundaries_test.dart`

**Interfaces:**
- Consumes: ADR-011 (Task 1), cited by decision number in comments.
- Produces, all in `test/architecture/boundary_rules.dart` and imported relatively
  (`import 'boundary_rules.dart';`) by the two tests:
  - `class SourceFile` with `SourceFile(String path, List<String> imports)`:
    `path` is repo-relative (`lib/...`); `imports` holds every `import` and
    `export` URI, a relative one resolved to its `package:memox/...` form.
  - `const Map<String, Set<String>> allowedFeatureImports`, equal to
    `{'srs': {}, 'deck': {'srs'}, 'card': {'deck', 'srs'}}`: the Dart import map
    (ADR-011 D2). A new feature adds its entry in the commit that creates its
    folder. The foundation plan's Global Constraints name this file as its home.
  - `List<SourceFile> readSources(Directory projectRoot)`: every `lib/**.dart`
    except `*.g.dart`.
  - `SourceFile parseSource(String path, String content)` and
    `String resolveImport(String fromPath, String uri)`.
  - `List<String> shapeViolations(List<SourceFile> sources)`,
    `List<String> domainPurityViolations(List<SourceFile> sources)`,
    `List<String> crossFeatureViolations(List<SourceFile> sources, {Map<String, Set<String>> allowed = allowedFeatureImports})`,
    `List<String> coreViolations(List<SourceFile> sources)` and
    `List<String> cyclesIn(Map<String, Set<String>> map)`: one readable line per
    violation, empty when clean.

- [ ] **Step 1: Write the failing rule tests**

Create `test/architecture/boundary_rules_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'boundary_rules.dart';

/// A source file whose imports are written the way a developer would, then
/// resolved the way the rules see them.
SourceFile _file(String path, [List<String> imports = const []]) =>
    SourceFile(path, [for (final uri in imports) resolveImport(path, uri)]);

void main() {
  group('shape', () {
    test('the ADR-011 layout passes', () {
      final sources = [
        _file('lib/main.dart'),
        _file('lib/app/app.dart'),
        _file('lib/app/router/app_router.dart'),
        _file('lib/core/error/outcome.dart'),
        _file('lib/features/deck/domain/entities/deck_entity.dart'),
        _file('lib/features/deck/data/repositories/deck_repository_impl.dart'),
        _file('lib/features/deck/di/deck_repository_provider.dart'),
        _file('lib/features/deck/presentation/screens/deck_list_screen.dart'),
        _file(
          'lib/features/deck/presentation/widgets/items/deck_tile_widget.dart',
        ),
      ];

      expect(shapeViolations(sources), isEmpty);
    });

    test('a barrel at the feature root is rejected', () {
      final sources = [_file('lib/features/deck/deck.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });

    test('a file directly in a layer folder is rejected', () {
      final sources = [_file('lib/features/deck/domain/deck.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });

    test('an unknown layer, bucket or top-level folder is rejected', () {
      final sources = [
        _file('lib/features/deck/logic/deck_rules.dart'),
        _file('lib/features/deck/domain/rules/deck_rule.dart'),
        _file('lib/utils/strings.dart'),
      ];

      expect(shapeViolations(sources), hasLength(3));
    });

    test('a widget sits one level deep in an AD-15 bucket', () {
      const widgets = 'lib/features/deck/presentation/widgets';
      final sources = [
        _file('$widgets/deck_tile_widget.dart'),
        _file('$widgets/rows/deck_tile_widget.dart'),
        _file('$widgets/items/tile/deck_tile_widget.dart'),
      ];

      expect(shapeViolations(sources), hasLength(3));
    });

    test('core/ holds concern folders, not loose files', () {
      final sources = [_file('lib/core/outcome.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });

    test('di/ is flat', () {
      final sources = [_file('lib/features/deck/di/sub/deck_provider.dart')];

      expect(shapeViolations(sources), hasLength(1));
    });
  });

  group('domain purity', () {
    test('domain may import plain Dart, meta, core and other domain code', () {
      final sources = [
        _file('lib/features/deck/domain/entities/deck_entity.dart', [
          'package:meta/meta.dart',
          'package:memox/core/error/outcome.dart',
          'package:memox/features/srs/domain/models/scheduler_type_model.dart',
          '../models/deck_content_type_model.dart',
        ]),
      ];

      expect(domainPurityViolations(sources), isEmpty);
    });

    test(
      'domain importing Flutter, Riverpod, Drift or core/database fails',
      () {
        final sources = [
          _file('lib/features/study/domain/models/study_mode.dart', [
            'package:flutter/foundation.dart',
            'package:riverpod_annotation/riverpod_annotation.dart',
            'package:drift/drift.dart',
            'package:memox/core/database/app_database.dart',
          ]),
        ];

        expect(domainPurityViolations(sources), hasLength(4));
      },
    );

    test('domain reaching data/ or di/ fails, relative paths included', () {
      final sources = [
        _file('lib/features/deck/domain/repositories/deck_repository.dart', [
          '../../data/repositories/deck_repository_impl.dart',
          'package:memox/features/deck/di/deck_repository_provider.dart',
        ]),
      ];

      expect(domainPurityViolations(sources), hasLength(2));
    });
  });

  group('cross-feature imports', () {
    const cardRepository =
        'lib/features/card/data/repositories/card_repository_impl.dart';

    test('public domain buckets along an allowed edge pass', () {
      final sources = [
        _file(cardRepository, [
          'package:memox/features/deck/domain/repositories/deck_repository.dart',
          'package:memox/features/srs/domain/models/scheduler_type_model.dart',
        ]),
      ];

      expect(crossFeatureViolations(sources), isEmpty);
    });

    test('an edge outside the import map fails', () {
      final sources = [
        _file('lib/features/srs/domain/models/srs_scheduler.dart', [
          'package:memox/features/deck/domain/entities/deck_entity.dart',
        ]),
      ];

      expect(crossFeatureViolations(sources), hasLength(1));
    });

    test(
      'data/, presentation/, usecases/ and barrels of another feature fail',
      () {
        final sources = [
          _file(cardRepository, [
            'package:memox/features/deck/data/repositories/deck_repository_impl.dart',
            'package:memox/features/deck/presentation/screens/deck_list_screen.dart',
            'package:memox/features/deck/domain/usecases/create_deck_use_case.dart',
            'package:memox/features/deck/deck.dart',
          ]),
        ];

        expect(crossFeatureViolations(sources), hasLength(4));
      },
    );

    test('another feature di/ is reachable from presentation/ and di/ only', () {
      const deckProvider =
          'package:memox/features/deck/di/deck_repository_provider.dart';
      final allowedFrom = [
        _file(
          'lib/features/card/presentation/providers/create_card_provider.dart',
          [deckProvider],
        ),
        _file('lib/features/card/di/card_repository_provider.dart', [
          deckProvider,
        ]),
      ];
      final rejectedFrom = [
        _file(cardRepository, [deckProvider]),
      ];

      expect(crossFeatureViolations(allowedFrom), isEmpty);
      expect(crossFeatureViolations(rejectedFrom), hasLength(1));
    });

    test('a relative import is judged like its package path', () {
      final sources = [
        _file(cardRepository, [
          '../../../deck/data/repositories/deck_repository_impl.dart',
        ]),
      ];

      expect(crossFeatureViolations(sources), hasLength(1));
    });

    test('an export of another feature internals fails like an import', () {
      final source = parseSource(
        'lib/features/card/domain/entities/card_entity.dart',
        "export 'package:memox/features/deck/data/datasources/deck_dao.dart';\n",
      );

      expect(crossFeatureViolations([source]), hasLength(1));
    });
  });

  group('core', () {
    test('core importing a feature, app/ or shared/ fails', () {
      final sources = [
        _file('lib/core/database/app_database.dart', [
          'package:memox/features/deck/domain/entities/deck_entity.dart',
          'package:memox/app/app.dart',
          'package:memox/shared/widgets/mx_button.dart',
        ]),
      ];

      expect(coreViolations(sources), hasLength(3));
    });
  });

  group('import map', () {
    test('the declared map is acyclic', () {
      expect(cyclesIn(allowedFeatureImports), isEmpty);
    });

    test('a cycle is reported with its path', () {
      const cyclic = {
        'srs': {'deck'},
        'deck': {'srs'},
      };

      expect(cyclesIn(cyclic), ['srs -> deck -> srs']);
    });
  });

  test('readSources skips generated files and keeps paths repo-relative', () {
    final root = Directory.systemTemp.createTempSync('boundary_rules');
    addTearDown(() => root.deleteSync(recursive: true));
    const provider = 'lib/features/deck/di/deck_repository_provider';
    File('${root.path}/$provider.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("part 'deck_repository_provider.g.dart';\n");
    File('${root.path}/$provider.g.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync("part of 'deck_repository_provider.dart';\n");

    final sources = readSources(root);

    expect(sources.map((source) => source.path), ['$provider.dart']);
    expect(sources.single.imports, isEmpty);
  });

  test('resolveImport maps a relative path under lib/ to package form', () {
    expect(
      resolveImport(
        'lib/features/card/data/repositories/card_repository_impl.dart',
        '../../../deck/domain/entities/deck_entity.dart',
      ),
      'package:memox/features/deck/domain/entities/deck_entity.dart',
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/architecture/boundary_rules_test.dart`
Expected: FAIL, a compilation error: `boundary_rules.dart` does not exist.

- [ ] **Step 3: Implement the rules**

Create `test/architecture/boundary_rules.dart`:

```dart
/// The folder and import rules of ADR-011, as pure functions over source
/// files. `boundary_rules_test.dart` proves each rule fires on a planted
/// violation; `boundaries_test.dart` applies them to the real `lib/`.
library;

import 'dart:io';

/// One Dart file under `lib/`: its repo-relative path and every URI it
/// imports or exports, resolved to `package:` form.
class SourceFile {
  const SourceFile(this.path, this.imports);

  final String path;
  final List<String> imports;
}

/// ADR-011 D2: the features each feature may import. Acyclic, with `srs`
/// at the base. A new feature adds its entry in the commit that creates it.
const allowedFeatureImports = <String, Set<String>>{
  'srs': {},
  'deck': {'srs'},
  'card': {'deck', 'srs'},
};

const _package = 'package:memox/';
const _featuresPackage = 'package:memox/features/';

/// ADR-011 folder tree: the only folders directly under `lib/`.
const _topLevelFolders = {'app', 'core', 'features', 'l10n', 'shared'};

/// ADR-011 D1: the buckets of each layer. `di/` has none; it is flat.
const _layerBuckets = <String, Set<String>>{
  'domain': {'entities', 'models', 'repositories', 'failures', 'usecases'},
  'data': {'datasources', 'mappers', 'repositories', 'models'},
  'presentation': {'screens', 'controllers', 'states', 'providers', 'widgets'},
};

/// ADR-011 D8 (AD-15): the widget buckets, one level deep.
const _widgetBuckets = {'sections', 'items', 'overlays', 'support'};

/// ADR-011 D3: the domain buckets another feature may import.
const _publicDomainBuckets = {'entities', 'models', 'repositories', 'failures'};

/// ADR-011 dependency rules: what `domain/` never imports.
const _forbiddenInDomain = [
  'dart:ui',
  'package:flutter/',
  'package:flutter_riverpod/',
  'package:riverpod/',
  'package:riverpod_annotation/',
  'package:drift/',
  'package:drift_flutter/',
  'package:sqlite3/',
  'package:memox/app/',
  'package:memox/core/database/',
  'package:memox/shared/',
];

/// ADR-011 dependency rules: what `core/` never imports.
const _forbiddenInCore = [
  'package:memox/app/',
  'package:memox/features/',
  'package:memox/shared/',
];

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Reads every hand-written Dart file under `lib/` of [projectRoot], with
/// paths relative to it (`lib/...`). Generated `.g.dart` files are skipped.
List<SourceFile> readSources(Directory projectRoot) {
  final root = projectRoot.path.replaceAll(r'\', '/');
  final lib = Directory('$root/lib');
  if (!lib.existsSync()) return const [];
  final files = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) => file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
      );
  return [
    for (final file in files)
      parseSource(
        file.path.replaceAll(r'\', '/').substring(root.length + 1),
        file.readAsStringSync(),
      ),
  ];
}

/// Collects the import and export URIs of [content], resolved against [path].
SourceFile parseSource(String path, String content) => SourceFile(path, [
  for (final match in _directive.allMatches(content))
    resolveImport(path, match.group(1)!),
]);

/// Resolves a relative [uri] written in [fromPath] (`lib/...`) to its
/// `package:memox/...` form, so a relative import is judged like the package
/// path it names. `dart:` and `package:` URIs are returned unchanged.
String resolveImport(String fromPath, String uri) {
  if (uri.startsWith('dart:') || uri.startsWith('package:')) return uri;
  final segments = fromPath.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '.') continue;
    if (part != '..') {
      segments.add(part);
      continue;
    }
    if (segments.isNotEmpty) segments.removeLast();
  }
  if (segments.isEmpty || segments.first != 'lib') return segments.join('/');
  return '$_package${segments.skip(1).join('/')}';
}

/// ADR-011 D1, D11: every file sits where the layout allows it.
List<String> shapeViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (_shapeProblem(source.path) case final problem?)
      '${source.path}: $problem',
];

/// ADR-011 dependency rules: `domain/` is plain Dart and reaches no
/// other layer.
List<String> domainPurityViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (_layerOf(source.path) == 'domain')
      for (final uri in source.imports)
        if (_isForbiddenInDomain(uri)) '${source.path} imports $uri',
];

/// ADR-011 D2–D3: another feature is reached only through its public
/// domain buckets (or its `di/`, from `presentation/` and `di/`), and only
/// along an edge of [allowed].
List<String> crossFeatureViolations(
  List<SourceFile> sources, {
  Map<String, Set<String>> allowed = allowedFeatureImports,
}) {
  final violations = <String>[];
  for (final source in sources) {
    final own = _featureOf(source.path);
    if (own == null) continue;
    for (final uri in source.imports) {
      final problem = _crossFeatureProblem(source.path, own, uri, allowed);
      if (problem == null) continue;
      violations.add('${source.path} imports $uri: $problem');
    }
  }
  return violations;
}

/// ADR-011 dependency rules: `core/` knows no feature, no `app/` and no
/// `shared/`.
List<String> coreViolations(List<SourceFile> sources) => [
  for (final source in sources)
    if (source.path.startsWith('lib/core/'))
      for (final uri in source.imports)
        if (_forbiddenInCore.any(uri.startsWith)) '${source.path} imports $uri',
];

/// ADR-011 D2: every cycle in [map], each written as `a -> b -> a`.
List<String> cyclesIn(Map<String, Set<String>> map) {
  final cycles = <String>[];
  final done = <String>{};

  void visit(String node, List<String> stack) {
    final start = stack.indexOf(node);
    if (start >= 0) {
      cycles.add([...stack.sublist(start), node].join(' -> '));
      return;
    }
    if (done.contains(node)) return;
    for (final next in map[node] ?? const <String>{}) {
      visit(next, [...stack, node]);
    }
    done.add(node);
  }

  for (final node in map.keys) {
    visit(node, const []);
  }
  return cycles;
}

/// `lib/features/<f>/...` -> `<f>`, otherwise null.
String? _featureOf(String path) {
  const prefix = 'lib/features/';
  if (!path.startsWith(prefix)) return null;
  return path.substring(prefix.length).split('/').first;
}

/// `lib/features/<f>/<layer>/...` -> `<layer>`, otherwise null.
String? _layerOf(String path) {
  final feature = _featureOf(path);
  if (feature == null) return null;
  final below = path.substring('lib/features/$feature/'.length).split('/');
  return below.length > 1 ? below.first : null;
}

String? _shapeProblem(String path) {
  final parts = path.split('/');
  if (parts.length == 2) {
    return parts[1] == 'main.dart' ? null : 'only main.dart sits in lib/';
  }
  final top = parts[1];
  if (!_topLevelFolders.contains(top)) return 'lib/$top/ is not in ADR-011';
  if (top == 'core' && parts.length == 3) return 'core/ holds concern folders';
  if (top != 'features') return null;
  return _featureShapeProblem(parts.sublist(2));
}

/// [parts] is the path below `lib/features/`: `<f>/<layer>/...`.
String? _featureShapeProblem(List<String> parts) {
  if (parts.length < 3) return 'a feature root holds no file';
  final layer = parts[1];
  if (layer == 'di') return parts.length == 3 ? null : 'di/ is flat';
  final buckets = _layerBuckets[layer];
  if (buckets == null) return '$layer/ is not a layer';
  if (parts.length == 3) return 'a file sits directly in $layer/';
  final bucket = parts[2];
  if (!buckets.contains(bucket)) return '$layer/$bucket/ is not a bucket';
  if (bucket == 'widgets') return _widgetShapeProblem(parts.sublist(3));
  return parts.length == 4 ? null : '$layer/$bucket/ is one level deep';
}

/// [parts] is the path below `presentation/widgets/`.
String? _widgetShapeProblem(List<String> parts) {
  if (parts.length < 2) return 'a file sits directly in widgets/';
  if (!_widgetBuckets.contains(parts.first)) {
    return 'widgets/${parts.first}/ is not an AD-15 bucket';
  }
  return parts.length == 2 ? null : 'widget buckets are one level deep';
}

bool _isForbiddenInDomain(String uri) {
  if (_forbiddenInDomain.any(uri.startsWith)) return true;
  final target = _featureTarget(uri);
  return target != null && target.layer != 'domain';
}

String? _crossFeatureProblem(
  String path,
  String own,
  String uri,
  Map<String, Set<String>> allowed,
) {
  final target = _featureTarget(uri);
  if (target == null || target.feature == own) return null;
  if (!(allowed[own] ?? const <String>{}).contains(target.feature)) {
    return '$own may not depend on ${target.feature}';
  }
  final isPublicDomain =
      target.layer == 'domain' && _publicDomainBuckets.contains(target.bucket);
  if (isPublicDomain) return null;
  final ownLayer = _layerOf(path);
  final mayUseDi = ownLayer == 'presentation' || ownLayer == 'di';
  if (target.layer == 'di' && mayUseDi) return null;
  return 'import only its domain/{entities,models,repositories,failures}/, '
      'or its di/ from presentation/ and di/';
}

/// `package:memox/features/<f>/<layer>/<bucket>/...` split into its parts.
({String feature, String layer, String? bucket})? _featureTarget(String uri) {
  if (!uri.startsWith(_featuresPackage)) return null;
  final parts = uri.substring(_featuresPackage.length).split('/');
  if (parts.length < 3) return (feature: parts.first, layer: '', bucket: null);
  final bucket = parts.length > 3 ? parts[2] : null;
  return (feature: parts[0], layer: parts[1], bucket: bucket);
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/architecture/boundary_rules_test.dart`
Expected: `All tests passed!` (21 tests).

- [ ] **Step 5: Apply the rules to the real tree**

Replace the whole content of `test/architecture/boundaries_test.dart`. Its barrel
rule and its fixed list of three domain folders are what ADR-011 replaces:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'boundary_rules.dart';

/// Applies the ADR-011 folder and import rules to the real `lib/`. Each rule
/// is proven to fire on a planted violation in `boundary_rules_test.dart`.
void main() {
  final sources = readSources(Directory.current);

  test('the tree has the ADR-011 shape', () {
    expect(shapeViolations(sources), isEmpty);
  });

  test('domain layers stay plain Dart', () {
    expect(domainPurityViolations(sources), isEmpty);
  });

  test('features reach each other through public buckets, along the map', () {
    expect(crossFeatureViolations(sources), isEmpty);
  });

  test('core imports no feature, app/ or shared/', () {
    expect(coreViolations(sources), isEmpty);
  });

  test('the feature import map is acyclic', () {
    expect(cyclesIn(allowedFeatureImports), isEmpty);
  });
}
```

- [ ] **Step 6: Run the architecture tests**

Run: `flutter test test/architecture`
Expected: `All tests passed!` (26 tests).

- [ ] **Step 7: Prove the real-tree test can fail**

```bash
mkdir -p lib/features/deck
printf "export 'package:memox/features/deck/data/datasources/deck_dao.dart';\n" > lib/features/deck/deck.dart
flutter test test/architecture/boundaries_test.dart
rm -r lib/features
git status --short lib
```

Expected: FAIL in `the tree has the ADR-011 shape`, with
`lib/features/deck/deck.dart: a feature root holds no file`; the other four tests
pass. Then `git status --short lib` prints nothing.

- [ ] **Step 8: Format, analyze, commit**

```bash
dart format --output=none --set-exit-if-changed test/architecture
flutter analyze
git add test/architecture
git commit -m "test(architecture): enforce the ADR-011 folder and import rules"
```

Expected: `Formatted 3 files (0 changed)` with exit 0, and `No issues found!`.

---

### Task 6: Root `README.md` states the phased gate

**Files:**
- Modify: `README.md` (header paragraph, `## Toolchain`, `## Commands`)

**Interfaces:**
- Consumes: the gate commands that Tasks 2–5 made pass.
- Produces: the gate that the foundation plan's Global Constraints call "the phased
  gate in `README.md`".

- [ ] **Step 1: Rewrite `README.md`**

Replace the whole file with:

````markdown
# MemoX V8

Flutter flashcard / spaced-repetition app. Rules: see `CLAUDE.md`. Layering
and tooling: `docs/shared/decisions/ADR-010-kien-truc-lop-v8-va-tooling.md`.
Folder structure and the verification gate:
`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`. Design:
`docs/superpowers/specs/`. Plans: `docs/superpowers/plans/`. Data model:
`docs/shared/data/schema.md`.

## Toolchain

Flutter version is pinned in `.fvmrc`. Check with:

```bash
.claude/skills/flutter-workflow/scripts/check_flutter_version.sh
```

The vendored guard (`code-verification-guard-v2/`) needs Python 3.12 or newer
with `code-verification-guard-v2/requirements-dev.txt` installed. In Claude
Code on the web, `.claude/hooks/install-guard-deps.sh` installs it when a
session starts. The commands below call it as `python3.13`; use `python3.12`
if that is the newest you have.

## Commands

Generated code is not committed. A fresh clone does not analyze or test
until:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Verification gate, until the first `presentation/` file exists (ADR-011):

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Every command must exit 0. A guard rule whose layer does not exist yet is
listed with `targets_pending: <layer>` in
`code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`.
Once the rule has a target file, the guard reports
`guard.config.stale_targets_pending` and the gate fails: delete the rule's entry
in the commit that added the file.

From the first screen on, the gate is
`.claude/skills/flutter-workflow/scripts/dod_check.sh`, and the
`targets_pending` list must be empty.
````

- [ ] **Step 2: Run the gate it states**

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

Expected: every command exits 0.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): state the phased verification gate of ADR-011"
```

---

### Task 7: `flutter-architecture` skill describes ADR-011

**Files:**
- Modify: `.claude/skills/flutter-architecture/SKILL.md`: `## Folder structure`,
  `## Dependency rules`, two bullets and the closing paragraph of
  `## Pragmatic, not ceremonial`, the first two paragraphs of `## Naming`, the
  guard command in `## Lint`. Match by the quoted text, not by line number.

**Interfaces:**
- Consumes: ADR-011 (Task 1), `boundary_rules.dart` and `allowedFeatureImports`
  (Task 5).

- [ ] **Step 1: List the V7 statements this task removes**

Run: `grep -nE 'docs/architecture\.md|memox-v7|architecture_boundary_test|carve-out|older rule' .claude/skills/flutter-architecture/SKILL.md`
Expected: 7 lines: the two `docs/architecture.md` citations, the
`architecture_boundary_test.dart` owner, the AD-12 carve-out, the two mentions of
"the older rule", and the `--ruleset memox-v7` command.

- [ ] **Step 2: Replace `## Folder structure`**

Replace everything from the line `## Folder structure` up to, but not including,
the line `## Dependency rules` with the following, and keep one blank line before
`## Dependency rules`:

````markdown
## Folder structure

The V8 layout is ADR-011 (`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`),
which refines ADR-010 decision 2. The tree says where a file goes, not what to
create: a folder appears with its first real file.

```
lib/
├── main.dart                 # ProviderScope + runApp, nothing else
├── app/                      # composition root: MemoxApp, retry policy
│   └── router/               # app_router.dart; paths and shell come with the UI
├── core/                     # infrastructure that knows no feature, one folder per concern
│   ├── database/             # connection.dart, app_database.dart, di/, tables/, queries/
│   ├── error/                # failure.dart, outcome.dart
│   └── id/                   # new_id.dart
├── l10n/                     # app_en.arb, app_vi.arb, from the first UI string
├── shared/
│   └── widgets/              # Mx* components, from the design-system sub-project
└── features/<feature>/       # names from ADR-010 decision 1
    ├── domain/               # plain Dart: entities/ models/ repositories/ failures/ usecases/
    ├── data/                 # datasources/ mappers/ repositories/ models/
    ├── di/                   # flat: repository providers, typed as the contract
    └── presentation/         # screens/ controllers/ states/ providers/
        └── widgets/          # exactly four buckets, one level deep (AD-15):
                              #   sections/ items/ overlays/ support/
```

| Folder | Suffix | Holds |
|---|---|---|
| `domain/entities/` | `_entity` | immutable domain objects; pure rules as members |
| `domain/models/` | `_model`, `_scheduler`, `_mode` | value objects, stored-code enums, read models; `srs` schedulers, `study_mode` modes |
| `domain/repositories/` | `_repository` | contracts, one implementation each |
| `domain/failures/` | `_failure` | the feature's rejection-reason enum |
| `domain/usecases/` | `_use_case` | one per UI interaction (AD-12) |
| `data/datasources/` | `_dao`, `_data_source` | a DAO per bounded context |
| `data/mappers/` | `_mapper` | row to entity, when the mapping is not trivial |
| `data/repositories/` | `_repository_impl` | contract implementations; every write in one transaction |
| `data/models/` | `_model` | DTOs; none while the app is local-only (ADR-001) |
| `di/` | `_provider` | repository providers; each constructs its implementation |
| `presentation/screens/`, `controllers/`, `states/` | `_screen`, `_controller`, `_state` | a screen, its controllers, its state classes |
| `presentation/providers/` | `_provider` | use-case providers |
| `presentation/widgets/<bucket>/` | `_widget` | placed by the four questions below |

Every feature file sits in a bucket of its layer; only `di/` is flat. No file
sits directly in `domain/`, `data/`, `presentation/` or `widgets/`, or at the
feature root, and there are no barrels: another feature imports the bucket file
it needs. The folder never replaces the suffix: `entities/deck_entity.dart`, not
`entities/deck.dart`. These wait for an ADR that opens the need:
`core/network/`, `core/storage/`, `core/utils/`, `app/config/` and flavors,
`app/di/`, `shared/models/`, `shared/extensions/`.

**Placing a widget** is four questions asked in order, stopping at the first
yes (AD-15, ratified for V8 by ADR-011 D8):

1. Does it open *over* the screen (`showModalBottomSheet`/`showDialog`)? → `overlays/`
2. Is it the repeated row of a list, or a part only that row uses? → `items/`
3. Does the screen compose it directly into its body or chrome? → `sections/`
4. Does it serve more than one bucket above (ARB mapping, render-only extension)? → `support/`

Buckets never nest, a bucket is created only when it has real content, and the
bucket list is app-wide: a fifth name is an ADR change, not a new folder.
`test/architecture/boundaries_test.dart` owns the full shape, with the rules in
`test/architecture/boundary_rules.dart`; the guard rule
`memox.architecture.widgets_grouped_into_buckets` is the second net.

`core/` is infrastructure with no knowledge of any feature. The moment
`core/database/` imports a feature entity, the boundary has broken — that code
belongs in the feature.
````

- [ ] **Step 3: Replace `## Dependency rules`**

Replace everything from the line `## Dependency rules` up to, but not including,
the line `## Pragmatic, not ceremonial` with the following, and keep one blank line
before `## Pragmatic, not ceremonial`:

````markdown
## Dependency rules

```
presentation ──► domain ◄── data
      │                      ▲
      └────────► di ─────────┘      di wires data to the domain contract
```

- **domain** is plain Dart: no Flutter, Riverpod or Drift, nothing from
  `core/database/`, `app/` or `shared/`, and no other layer. `meta` is allowed.
  The test is simple: a domain file must compile in a plain Dart package. If it
  needs `package:flutter` for `@immutable` or `Color`, restructure — `@immutable`
  can come from `meta`, and a `Color` in a domain entity means a UI concept
  leaked into the model.
- **data** implements the repository contracts of its own domain, and may import
  its own `domain/` and `core/`. Never the reverse.
- **di** may import its own `data/` and `domain/`, and `core/`. It is where a
  repository implementation is constructed.
- **presentation** may import its own `domain/` and `di/`, never `data/`. Every
  interaction it triggers, read or write, goes through exactly one use case
  (AD-12, ADR-011 D4–D5): never to a DAO, never to Drift.
- **Between features**, a file may import another feature's
  `domain/{entities,models,repositories,failures}/`, file by file. A file in
  `presentation/` or `di/` may also import another feature's `di/`. Nothing
  imports another feature's `data/`, `presentation/` or `domain/usecases/`. If
  two features need the same thing, it moves to `core/`, or one feature exposes
  a domain contract the other depends on.
- **The import map is acyclic.** `allowedFeatureImports` in
  `test/architecture/boundary_rules.dart` lists the features each feature may
  import: `srs → ∅`, `deck → {srs}`, `card → {deck, srs}`. A new feature adds
  its entry in the commit that creates its folder. The map is the contract
  direction; `depends_on` in `docs/features/*/README.md` is the data direction
  and may differ (ADR-011 D2).
- `core/` imports no feature, `app/` or `shared/`. `shared/` imports only
  `core/`. `app/` composes features, and no feature imports `app/`.

Verify mechanically rather than by eye:

```bash
flutter test test/architecture
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
```
````

- [ ] **Step 4: Ratify AD-12 without the carve-out**

In `## Pragmatic, not ceremonial`, replace these two bullets and the blank line
after them:

```markdown
- **Not every feature needs every layer.** A settings screen that toggles a
  local preference does not need an entity, a contract, an implementation and a
  use case to wrap one boolean. It needs a controller and a storage call.
- **A feature that has a `usecases/` folder gets one use case per interaction**
  (AD-12). This is a deliberate change from the older rule below, made by the
  project owner before the second feature was cloned: uniformity is what turns a
  new feature into a clone rather than a judgement call at every operation. Six of
  Deck's ten hold the input validation that used to run twice — once in a
  controller and once again in the repository. Four are thin, and that is the
  accepted cost.

  The older rule still applies to a feature small enough not to have the folder at
  all: a settings toggle needs a controller and a storage call, not five layers.
  What changed is that *within* a Clean Architecture feature, the layer is uniform.
```

with:

```markdown
- **A layer appears with its first real file, and a feature with a screen has
  one use case per interaction** (AD-12, ratified by ADR-011 D4). A feature with
  no screen has no `presentation/` and no `domain/usecases/`; nothing is
  scaffolded for later. Once a feature has a screen, every interaction goes
  through its own use case, reads and thin ones included, and no feature is
  exempt, settings included (D5). Uniformity is what turns a new feature into a
  clone of a known shape rather than a judgement call at every operation, and it
  gives each input-validation rule one owner — the use case — instead of a
  controller and a repository that both check it.
```

Then replace the section's closing paragraph

```markdown
When you deviate from the standard shape, write one line in
`docs/architecture.md` saying what and why. The next person then reads a
decision instead of an inconsistency.
```

with:

```markdown
The standard shape is ADR-011. A deviation from it is an ADR change approved
by the project owner, not a local exception, so the next person reads a
decision instead of an inconsistency.
```

- [ ] **Step 5: Tell the two `_model` meanings apart**

In `## Naming`, replace the first two paragraphs

```markdown
Files are `snake_case` ending in the suffix that states the role:
`*_screen.dart`, `*_widget.dart`, `*_controller.dart`, `*_state.dart`,
`*_repository.dart` (contract), `*_repository_impl.dart` (implementation),
`*_use_case.dart`, `*_model.dart` (DTO), `*_entity.dart` (domain).

The `_model` / `_entity` split is load-bearing: `_model` is the wire or database
shape and may change when the API changes; `_entity` is the domain shape and
should not. Naming them apart keeps people from passing a DTO into the UI.
```

with:

```markdown
Files are `snake_case` ending in the suffix that states the role; the table
under "Folder structure" pairs each folder with its suffixes, and the folder
never replaces the suffix.

`_model` means two things, told apart by its folder. In `domain/models/` it is
a value object, a stored-code enum or a read model: domain language, stable. In
`data/models/` it is a DTO, the wire shape, which changes when the API changes.
`_entity` is the domain object and changes with neither. The Drift row class is
none of these: only `data/` and `core/database/` use it, and the repository maps
it to the entity, so no row or DTO reaches the UI.
```

- [ ] **Step 6: Point the guard command at `memox-v8`**

In `## Lint`, replace the line

```bash
python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7
```

with:

```bash
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
```

- [ ] **Step 7: Verify and commit**

```bash
grep -nE 'docs/architecture\.md|memox-v7|architecture_boundary_test|carve-out|older rule' .claude/skills/flutter-architecture/SKILL.md
grep -c 'ADR-011' .claude/skills/flutter-architecture/SKILL.md
git add .claude/skills/flutter-architecture/SKILL.md
git commit -m "docs(skills): flutter-architecture describes the ADR-011 layout"
```

Expected: the first `grep` prints nothing; the count is `6`.

---

### Task 8: The other skills point to ADR-011

**Files:**
- Modify: `.claude/skills/flutter-feature-slice/SKILL.md`
- Modify: `.claude/skills/flutter-feature-slice/assets/feature_blueprint.md` (banner
  under the title)
- Modify: `.claude/skills/flutter-feature-slice/assets/feature_checklist.md`: the
  `di/` item and the guard item. They restate the `SKILL.md` statements this task
  changes, so leaving them would contradict ADR-011 inside the same skill.
- Modify: `.claude/skills/flutter-drift/references/project-baseline.md` (banner
  under the title)
- Modify: `.claude/skills/flutter-testing/SKILL.md` (the `## Layout` block and two
  paths)
- Modify: `.claude/skills/flutter-project-setup/SKILL.md` (note under
  `## 6.2 Environments and flavors`)

**Interfaces:**
- Consumes: ADR-011 (Task 1), the `test/support/` decision (ADR-011 D12), the
  guard command (Task 6).

- [ ] **Step 1: List the V7 statements this task removes**

Run:

```bash
grep -nE 'only when warranted|only when feature-specific|it is the authority on|present and empty on purpose|none exist yet|test/database/support|test/helpers|memox-v7|app/di/repository_bindings' .claude/skills/flutter-feature-slice/SKILL.md .claude/skills/flutter-feature-slice/assets/feature_checklist.md .claude/skills/flutter-testing/SKILL.md
```

Expected: 11 lines: 7 in `flutter-feature-slice/SKILL.md`, 2 in
`feature_checklist.md`, 2 in `flutter-testing/SKILL.md`.

- [ ] **Step 2: `flutter-feature-slice/SKILL.md`**

Make these seven replacements.

(a) In the Step 1 domain tree, replace

```
├── usecases/       <verb>_<noun>_use_case.dart     # only when warranted
└── failures/       <name>_failure.dart             # only when feature-specific
```

with

```
├── usecases/       <verb>_<noun>_use_case.dart     # one per UI interaction (AD-12)
└── failures/       <name>_failure.dart             # the feature's rejection enum
```

(b) Replace

```markdown
select on. `check_architecture.sh` additionally pairs each folder with its
required suffix. See `assets/feature_blueprint.md` — it is the authority on
layout, and this block is a summary of it.
```

with

```markdown
select on. `check_architecture.py` additionally pairs each folder with its
required suffix. The authority on layout is ADR-011
(`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`), and this block is a
summary of it. `assets/feature_blueprint.md` is V7's worked example: read it
for the reasoning, never for a path.
```

(c) In the Step 2 data tree, replace

```
└── models/         <name>_model.dart               # DTOs — none exist yet
```

with

```
└── models/         <name>_model.dart               # DTOs, with the first wire format
```

(d) Replace

```markdown
`models/` is present and empty on purpose: **there is no DTO layer**. `dio` is
deliberately not a dependency (AD-05), Drift is the source of truth (AD-01), and a
DTO would be a second shape for data that already has two. It gets files with the
first real request, not in anticipation of one.
```

with

```markdown
`models/` does not exist yet: **there is no DTO layer**, and a folder appears
with its first real file (ADR-011 D1). The app is local-only (ADR-001), Drift is
the source of truth, and a DTO would be a second shape for data that already has
two. The folder comes with the first real wire format, not in anticipation of
one.
```

(e) In Step 4, replace

```markdown
      Use `test/database/support/test_database.dart` and a per-feature harness.
```

with

```markdown
      Use `test/support/test_database.dart` and a per-feature harness.
```

(f) In Step 5, replace

```markdown
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` clean
```

with

```markdown
- [ ] `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean
```

(g) In the closing paragraphs, replace

```markdown
`assets/feature_blueprint.md` is the same ground covered from the other
direction: what the *existing* `features/deck` slice settled, measured against
the code rather than described in the abstract. Read it before starting the
```

with

```markdown
`assets/feature_blueprint.md` is the same ground covered from the other
direction: what V7's `features/deck` slice settled, measured against V7's code
rather than described in the abstract. Its paths are V7's; the V8 layout is
ADR-011. Read it before starting the
```

- [ ] **Step 3: Banner on `feature_blueprint.md`**

Insert this banner directly below the title (the first line), with one blank line
above and below it:

```markdown
> **V7 reference.** This file describes memox-v7's `features/deck` and
> `features/card` as V7 built them. Its paths, including the
> `app/di/repository_bindings.dart` binding, do not exist in V8. The V8 layout is
> ADR-011 (`docs/shared/decisions/ADR-011-cau-truc-thu-muc-v8.md`): read this
> file for the reasoning, never for a path.
```

- [ ] **Step 4: `feature_checklist.md`**

Replace

```markdown
- [ ] `di/` — one provider per contract the feature needs, declared as the
      **domain type**, bound in `app/di/repository_bindings.dart`
```

with

```markdown
- [ ] `di/` — one provider per contract the feature needs, typed as the
      **domain type**, constructing the implementation itself (ADR-011: no
      `app/di/`)
```

and replace

```markdown
- [ ] `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` clean
```

with

```markdown
- [ ] `python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8` clean
```

- [ ] **Step 5: Banner on `project-baseline.md`**

Insert this banner directly below the title (the first line), with one blank line
above and below it:

```markdown
> **V7 baseline.** This file records what memox-v7 settled. V8 keeps its layout
> decisions where ADR-010 and ADR-011 do — tables and named queries in
> `lib/core/database/{tables,queries}/`, DAOs in each feature's
> `data/datasources/` — but V8's table and column names come from
> `docs/shared/data/schema.md`: `parent_id`, `root_id`, singular table names, and
> `delete_batch_id` in a later sub-project. Where this file and `schema.md`
> differ, `schema.md` wins.
```

- [ ] **Step 6: `flutter-testing/SKILL.md`**

Replace the `## Layout` code block and add the paragraph after it. Replace

````markdown
```
test/
├── features/<feature>/
│   ├── domain/       use case, validation
│   ├── data/         repository, mapper, data source
│   └── presentation/ controller, widget
├── app/              architecture/convention guards parsing the AST
├── core/             error mapping and other core units
├── database/         migration_test.dart · invariants_test.dart · support/test_database.dart
├── drift/            generated schema verifiers (schema_vN.dart)
├── shared/           shared widget tests
├── visual_audit/     MX-VIS-001 per-screen audits
└── helpers/          fakes, builders, pump helpers
integration_test/     the 60-scenario E2E suite (it_*_test.dart + support/)
```
````

with

````markdown
```
test/
├── architecture/       boundaries_test.dart, boundary_rules.dart (ADR-011)
├── app/                once app/ has behaviour: router, bootstrap
├── core/<concern>/     mirrors lib/core/<concern>/
├── database/           schema-wide: schema, migration, invariants
├── integration/        cross-feature flows on real SQLite
├── features/<feature>/
│   ├── domain/         entity rules, value objects, use cases
│   ├── data/           repository, mapper, DAO
│   └── presentation/   controller, widget; support/ for feature-local fakes
└── support/            shared: test_database.dart, fake clock, builders, pump helpers
```

Folders appear with their first test (ADR-011 D1, D12). The suites that come
with the UI (visual audits under `test/visual_audit/`, which the guard's
`memox.visual.*` rules already target, goldens and `integration_test/`) are
placed when the UI sub-project starts.
````

Then replace

```markdown
(`test/database/support/test_database.dart`), not a mocked executor — the thing
```

with

```markdown
(`test/support/test_database.dart`), not a mocked executor — the thing
```

and

```markdown
Put the wrapper in `test/helpers/` once. Every test writing its own is how they
```

with

```markdown
Put the wrapper in `test/support/` once. Every test writing its own is how they
```

- [ ] **Step 7: Note in `flutter-project-setup/SKILL.md`**

Insert this note directly below the heading `## 6.2 Environments and flavors`,
with one blank line above and below it:

```markdown
> **Not in V8 yet.** MemoX V8 is local-only (ADR-001): no API base URL, no
> staging backend, no analytics. So it has no flavors, no `EnvConfig` and no
> `app/config/` (ADR-011). The rest of this section applies once an ADR opens
> networking.
```

- [ ] **Step 8: Verify and commit**

```bash
grep -nE 'only when warranted|only when feature-specific|it is the authority on|present and empty on purpose|none exist yet|test/database/support|test/helpers|memox-v7|app/di/repository_bindings' .claude/skills/flutter-feature-slice/SKILL.md .claude/skills/flutter-feature-slice/assets/feature_checklist.md .claude/skills/flutter-testing/SKILL.md
head -8 .claude/skills/flutter-feature-slice/assets/feature_blueprint.md | grep -c 'V7 reference'
head -8 .claude/skills/flutter-drift/references/project-baseline.md | grep -c 'V7 baseline'
grep -c 'Not in V8 yet' .claude/skills/flutter-project-setup/SKILL.md
git add .claude/skills
git commit -m "docs(skills): point feature-slice, drift, testing and setup skills to ADR-011"
```

Expected: the first `grep` prints nothing; each count is `1`.

---

### Task 9: Final verification

**Files:** none changed. Stub files created in Step 2 are deleted in the same step.

**Interfaces:**
- Consumes: everything above, and the File Structure block of
  `docs/superpowers/plans/2026-09-23-memox-v8-foundation.md`.

- [ ] **Step 1: The phased gate and the docs check**

```bash
flutter analyze
flutter test
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
dart format --output=none --set-exit-if-changed test/architecture
python3 tools/docs/check.py
```

Expected: every command exits 0; `check.py` ends with `0 error(s)`.

- [ ] **Step 2: Dry-run the foundation layout**

This proves that the tree the foundation plan will build passes the new rules, and
that its Tasks 3, 5, 7 and 10 retire exactly the 12 entries they name. It creates
one comment-only stub per `lib/` Dart path in the foundation plan's File Structure,
runs the checks and deletes the stubs.

```bash
git status --short lib
python3 - <<'EOF'
import re
from pathlib import Path

plan = Path("docs/superpowers/plans/2026-09-23-memox-v8-foundation.md").read_text(encoding="utf-8")
block = plan[plan.index("## File Structure"):].split("```", 2)[1]
paths = [line.split()[0] for line in block.splitlines() if re.match(r"lib/\S+\.dart\b", line)]
for path in paths:
    file = Path(path)
    file.parent.mkdir(parents=True, exist_ok=True)
    if not file.exists():
        file.write_text("// ADR-011 layout stub, deleted by the same step.\n", encoding="utf-8")
print(len(paths), "paths")
EOF
out=$(mktemp)
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8 > "$out"; echo "guard exit $?"
grep 'Total:' "$out"
grep -oE 'Rule `[a-z0-9_.]+` declares targets_pending `[a-z-]+`' "$out" | LC_ALL=C sort
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py | tail -3
flutter test test/architecture
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_ci_tooling.py'
rm -rf lib/app lib/core lib/features "$out"
git status --short
```

Expected:
- The first `git status --short lib` prints nothing; the script prints `37 paths`.
- `guard exit 1` with `Total: 40 | Errors: 0 | Warnings: 12 | Info: 28`. No
  naming or architecture rule reports an error on the foundation's file names.
- Exactly these 12 stale declarations. The foundation plan deletes the `domain`
  entries in its Task 3, `providers` in Task 5, `data` in Task 7 and `app` in
  Task 10:

```
Rule `memox.architecture.domain_no_infrastructure_import` declares targets_pending `domain`
Rule `memox.architecture.no_drift_type_in_domain` declares targets_pending `domain`
Rule `memox.architecture.no_transaction_outside_data_layer` declares targets_pending `domain`
Rule `memox.architecture.single_study_mode_dispatch` declares targets_pending `domain`
Rule `memox.data_model.scheduler_no_ambient_now` declares targets_pending `domain`
Rule `memox.design_token.no_raw_text_style` declares targets_pending `app`
Rule `memox.naming.data_file_role_suffix` declares targets_pending `data`
Rule `memox.naming.domain_file_role_suffix` declares targets_pending `domain`
Rule `memox.state_management.controller_no_build_context` declares targets_pending `providers`
Rule `memox.state_management.notifier_no_public_mutable_field` declares targets_pending `providers`
Rule `memox.state_management.state_write_after_await_requires_mounted` declares targets_pending `providers`
Rule `memox_v7.design_system.no_bare_font_weight` declares targets_pending `app`
```

- The checker prints `features 28 (domain 19, data 6, presentation 0, di 4)` and
  `✓ architecture boundaries clean`.
- `flutter test test/architecture` passes (26 tests); the CI tooling tests end
  with `OK`.
- The last `git status --short` prints nothing.

- [ ] **Step 3: The foundation plan uses no pre-ADR-011 path**

Run:

```bash
grep -nE 'core/(outcome|id|failure)\.dart|features/(srs|deck|card)/(srs|deck|card)\.dart|_providers\.dart|lib/app/router\.dart|test/helpers/|test/database/support/|\bRejection\.' docs/superpowers/plans/2026-09-23-memox-v8-foundation.md
```

Expected: no output. Each pattern is a path or name that ADR-011 or spec §10
retired: the flat `core/` files, the feature barrels, `deck_providers.dart`, the flat
router file, the old test-helper folders, and the single `Rejection` enum.

- [ ] **Step 4: Push**

```bash
git status --short
git log --oneline -9
git push -u origin claude/project-folder-architecture-gbsw4r
```

Expected: a clean tree; eight commits from Tasks 1–8 on top of the plan commit;
the push succeeds. If it fails on a network error, retry up to four times, waiting
2 s, 4 s, 8 s and 16 s.
