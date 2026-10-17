---
id: ADR-019
title: App là chuẩn UI; retire kit v3 và design handoff
status: active
superseded_by:
---
## Bối cảnh

Đến 2026-09-30, chuẩn hình ảnh của V8 là artifact "MemoX — Mobile UI Kit v3" và bản
design handoff tách từ nó (`docs/shared/ui/design-handoff/`). Mọi chỗ app khác kit phải
ghi thành deviation trong file chi tiết của màn. Đợt critique Impeccable toàn bộ 28 màn
ngày 2026-09-30 thấy nhiều điểm yếu do chính kit vẽ (khối tiến độ ba lớp ở màn 07, số
liệu lặp ba lần ở màn 21, hai nút Save ở màn 08/09). Sửa chúng nghĩa là ghi thêm
deviation.

## Quyết định

- Kit v3 và design handoff không còn là chuẩn. Artifact vẫn nằm trên claude.ai như lịch
  sử, không được đọc làm nguồn.
- Thứ tự ưu tiên: BR/UC > [`DESIGN.md`](../../../DESIGN.md) cùng golden đã được chủ dự án
  duyệt > file chi tiết của màn trong
  [`docs/shared/ui/screen-handoff/`](../ui/screen-handoff/00-index.md).
- `DESIGN.md` được sinh từ code (`lib/core/theme/`, `lib/shared/widgets/`) và cập nhật
  cùng PR với mọi thay đổi hệ thống hình ảnh. File chi tiết của màn cập nhật cùng PR với
  thay đổi của màn đó. Không còn khái niệm deviation so với kit.
- Impeccable đánh giá UI so với `DESIGN.md` và quality floor.
- **Cập nhật 2026-10-13 ([ADR-022](ADR-022-mot-nguon-token-va-theme-flutter.md)):** thứ tự
  ưu tiên thành BR/UC > `design/tokens.json` > golden đã duyệt > file chi tiết của màn.
  `DESIGN.md` (frontmatter) và `.impeccable/design.json` được sinh từ `design/tokens.json`
  bằng `tools/design/generate.py`; phần văn xuôi chỉ gọi tên token.
- **Cập nhật 2026-10-17 ([ADR-026](ADR-026-forui-la-he-component-giao-dien.md)):** ADR-022
  bị thay. Thứ tự ưu tiên thành BR/UC > theme ForUI production (`lib/core/theme/`)
  > golden đã duyệt > file chi tiết của màn. Frontmatter của `DESIGN.md` và
  `.impeccable/design.json` được render từ theme production
  (`test/tools/design_doc_test.dart`); phần văn xuôi chỉ gọi tên role.

## Hệ quả

- Xoá `docs/shared/ui/screen-handoff/img/`, `docs/shared/ui/design-handoff/`,
  `docs/shared/ui/design-handoff.json`, `tools/docs/split_handoff.py`, `tools/design/`
  (thư mục cũ; `tools/design/` hiện nay là bộ sinh token của ADR-022) và checklist state theo kit; các mục Deviations của file chi tiết thành mục Rulings.
- `tools/docs/check.py` không kiểm link trong `docs/superpowers/`: spec và plan cũ là hồ
  sơ lịch sử, giữ nguyên link tới các file đã xoá.
- Sổ nợ UI-base (spec 2026-09-23 §9) vẫn là danh sách nợ UI đã biết, không còn ghi lệch
  với kit.
