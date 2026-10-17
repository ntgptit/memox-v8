---
id: ADR-025
title: Ghim lượt đang làm vào phiên bản nội dung TOPIK và gói nội dung offline
status: active
superseded_by:
---
## Bối cảnh

[ADR-024](ADR-024-master-data-topik-tren-supabase-va-admin-web.md) đưa Master Data
TOPIK lên Supabase và cho app cache nội dung đã publish. Plan 1 (kho Master Data
trong `supabase/`) đã merge và đã push lên project (workflow `supabase migrations`
run 31, 2026-10-17). Phần app (plan 2) và Admin Web (plan 3) chưa xây.

Gói quyết định kiến trúc
[`2026-10-17-topik-master-data-decision-package.md`](../../superpowers/specs/2026-10-17-topik-master-data-decision-package.md)
rà lại thiết kế trước khi xây phần app và tìm thấy những điểm cần quyết định khác
với văn bản đã duyệt. Chủ dự án duyệt gói ngày 2026-10-17. ADR này ghi năm quyết định
sửa ADR-024; mục 5 là phán quyết của chủ dự án về DR-14, chặt hơn các phương án gói
đưa ra. Các bổ sung
chỉ thêm (giới hạn bucket, RPC kiểm thử trước publish, khoá lạc quan khi lưu draft,
CLI quản trị trước Admin UI) nằm trong hướng ADR-024 đã duyệt và không cần ADR; chúng
nằm trong decision register của gói (DR-09, DR-10, DR-18, DR-22).

## Quyết định

| # | Chủ đề | Quyết định | Sửa dòng nào |
|---|---|---|---|
| 1 | Lượt đang làm và phiên bản nội dung | Một lượt `in_progress` **ghim** vào phiên bản (`content_version`) nó bắt đầu: tiếp tục, hiển thị và chấm trên đúng phiên bản đó; `content_version` của lượt không bị ghi đè lúc nộp; máy giữ phiên bản đã ghim cho tới khi lượt được nộp hoặc xoá. Khi phiên bản đã ghim không còn trên máy (đề retired, hoặc mất dữ liệu cục bộ) hay không còn khớp bộ câu của lượt, app từ chối tiếp tục và đề nghị xoá, như BR-TOPIK-019 đang quy định cho đề "không còn". Lượt đã nộp không đổi gì: bản chốt, Summary, Review theo nội dung hiện tại kèm banner | BR-TOPIK-013 đoạn 3 ("bản sửa nội dung có trước lúc nộp là bản dùng để chấm"), BR-TOPIK-019 gạch đầu dòng 3, spec 2026-10-15 §5.3 câu cuối, spec 2026-10-16 §8.4 và §12 dòng "A publication while a learner is mid-attempt" |
| 2 | Cache nội dung trên máy | `topik_content_cache` khoá theo `(test_id, content_version)` với `state` ∈ {`pending`, `current`, `retained`, `failed`}: mỗi đề có nhiều nhất một dòng `current` (unique index); dòng `retained` là phiên bản bị thay nhưng còn một lượt đang làm ghim vào; dòng `failed` là lần cài thất bại, được thử lại ở lần làm mới sau và không chặn cursor. Cài đặt theo thứ tự tải về thư mục tạm → kiểm từng file (`size`/`eTag`) và tài liệu (`md5`, `checkTopikTest`) → đổi tên thư mục → ghi dòng trong một transaction; gói `current` cũ chỉ bị hạ xuống trong chính transaction đó | spec 2026-10-16 §8.2 (`test_id text pk`), §8.3 bước 2 (cursor đứng lại khi có lỗi) |
| 3 | Bộ kiểm tra ở Admin Web | Admin Web dùng chính `checkTopikTest` của Dart biên dịch bằng `dart compile js` (artifact có phiên bản, xuất từ `tools/topik/`), không viết lại bằng TypeScript. Hợp đồng fixture giữ nguyên và chạy trong CI của Admin Web | ADR-024 #5 ("TypeScript ở Admin Web"), spec 2026-10-16 §7 mục 3, BR-TOPIK-008 cụm "TypeScript ở Admin Web" |
| 4 | Toàn vẹn nội dung bằng hash mật mã | Server tính SHA-256 (`pg_catalog.sha256`, đã dùng ở `20261010000000_accounts.sql`) trên đúng văn bản tài liệu nó trả về; `topik_catalog` và `topik_test_content` trả `sha256` (cùng `schemaVersion`, `bytes`), app kiểm trước khi kích hoạt. Media đặt tên theo SHA-256 của nội dung trong hợp đồng đường dẫn đã ship: `{test_id}/{content_version}/{sha256}.{ext}`; publish từ chối tên khác; app kiểm `sha256(bytes)` bằng tên và `size`. `checksum` md5 giữ cho màn admin; `eTag` chỉ để tham khảo | ADR-024 #4 ("kiểm size/eTag từng file"), spec 2026-10-16 §6.2, §6.4, §8.3 |
| 5 | Ai đọc được nội dung đã publish | **Tạm thời chỉ admin** (chủ dự án, 2026-10-17, DR-14): quyền phân phối lại đề NIIED cho người khác chưa được xác lập. Một hàm cổng duy nhất `private.topik_can_read_content()` trả `private.is_admin()`; `topik_catalog` trả trang rỗng (`entries = []`, `next = since`, `more = false`) cho người không qua cổng, nên máy của họ không lưu gì, không ghi lỗi và giữ cursor ở 0; `topik_test_content` trả `NOT_FOUND`; policy đọc Storage qua `topik_media_can_read` đòi qua cổng. Mở cổng (cho mọi tài khoản không ẩn danh, hay cho tất cả) là một migration thay thân hàm, và là một quyết định riêng của chủ dự án; khi mở, các máy kéo toàn bộ từ cursor 0 ở lần làm mới kế tiếp | ADR-024 #7 ("`authenticated` … chỉ đọc object của mọi phiên bản đã tồn tại của một đề đang published"), spec 2026-10-16 §6.2 ("Both are `authenticated`-only"), §6.4 Read |

## Hệ quả

- ADR-024 #4, #5 và #7 ghi "sửa bởi ADR-025": mục 1, 2, 4 sửa #4; mục 3 sửa #5; mục 5 sửa #7.
- Các câu của BR-TOPIK-013, BR-TOPIK-019, BR-TOPIK-008, UC-TOPIK-002 E1, UC-TOPIK-003, spec 2026-10-15 §5.3 và spec 2026-10-16 §6.2, §6.4, §7, §8.2–§8.4, §10 được sửa **trong chính PR đổi code của chúng** (gói quyết định §11: PR-02 cho server, PR-04 cho cache, PR-05 cho ghim lượt và màn 36), để tài liệu và code không bao giờ nói khác nhau. Cho tới PR đó, văn bản hiện tại mô tả đúng code đang chạy. `contentMismatch` (nộp bị từ chối khi bộ câu khác) được ghi vào BR-TOPIK-019 và UC-TOPIK-003 ở PR-05.
- Dữ liệu người dùng, sync và lượt đã nộp không đổi. Màn 34–39 không đổi, trừ hai chỗ: gợi ý offline ở trạng thái `noTests` của màn 34, và History vẫn hiện ở màn 36 khi đề không còn (DR-11, đã duyệt).
- Chi phí của mục 1: mỗi lượt đang làm giữ thêm nhiều nhất một gói trên máy (BR-TOPIK-011 giới hạn một lượt dở mỗi đề); thêm `revision(testId, contentVersion)` trên `TopikContentRepository`; các use case làm bài, nộp và ôn lại lượt dở đọc phiên bản đã ghim. Test "a content correction made before submit is the one that scores" được viết lại theo nghĩa mới, không bỏ.
- Chi phí của mục 5: người học không phải admin thấy "No tests yet" cho tới khi cổng mở; chủ dự án luyện đề và chạy kiểm tra kỳ 96 bằng tài khoản admin (không thể là tài khoản ẩn danh). Máy đã tải nội dung không thu hồi được nếu sau đó tài khoản bị hạ quyền; đây là giới hạn của app offline-first.
- Phương án bị loại (gói quyết định §5.6, §6.5): chấm theo nội dung mới nhất; ghim kèm fallback sang phiên bản hiện tại; chốt đáp án lúc bắt đầu; port TypeScript cho validator; `md5` và `eTag` làm kiểm toàn vẹn; phân phối cho mọi người dùng `authenticated` khi chưa rõ quyền phân phối lại.
