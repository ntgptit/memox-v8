---
id: ADR-024
title: Master Data TOPIK trên Supabase và Admin Web
status: active
superseded_by:
---
## Bối cảnh

[ADR-023](ADR-023-luyen-de-topik.md) #3 chốt nội dung đề TOPIK là dữ liệu đóng gói
trong `assets/topik/`, không nạp vào Drift, và để gói tải về cho Phase B với spec
riêng. Mỗi kỳ mới khi đó là một bản phát hành app. Ngày 2026-10-16, trong đợt kiểm
toán DEV-394, chủ dự án chốt hướng khác: Master Data TOPIK nằm trong Supabase
PostgreSQL (cùng project app đang đồng bộ, [ADR-015](ADR-015-supabase-lam-backend.md)),
được quản lý bởi một Admin Web riêng (Next.js, host trên Vercel); app Flutter chỉ
dùng dữ liệu đã publish, cache offline bằng Drift/SQLite, và giữ dữ liệu học của
người dùng riêng như hiện nay. Thiết kế ở
[`superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md`](../../superpowers/specs/2026-10-16-topik-master-data-admin-web-design.md).

Chủ dự án duyệt spec ngày 2026-10-16 (các câu hỏi O1–O9 của spec §11 chốt theo đề
xuất); ADR này `active` và thay các dòng ADR-023 #3, #5.

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Nơi lưu | Master Data TOPIK (đề, nhóm câu, câu, đáp án, điểm, giải thích) là các bảng `topik_*` trong Postgres của Supabase; audio và ảnh trong bucket Storage `topik-media`. Không còn gói nào trong APK |
| 2 | Admin Web | Một ứng dụng riêng, Next.js trên Vercel, repo và vòng đời triển khai riêng (`memox-topik-admin`); dùng cùng Supabase Auth và model role `profiles.role = 'admin'` của app; mọi ghi qua RPC `topik_admin_*` kiểm `private.is_admin()`; browser chỉ cầm publishable key, không bao giờ cầm service role |
| 3 | Vòng đời nội dung | Draft (sửa tự do) → Published (một phiên bản bất biến `topik_test_version`, `content_version` tăng dần do server cấp) → Retired (client bỏ đề, phiên bản giữ lại). Rollback là publish lại phiên bản cũ thành phiên bản mới; publish/rollback trên đề đã retired bị từ chối `INVALID_STATE` (phải unretire trước); mọi thay đổi ghi `topik_master_audit` trong cùng transaction |
| 4 | Client | App đọc qua hai RPC `topik_catalog(since)` (phân trang theo `catalog_version` toàn cục, đề retired là tombstone) và `topik_test_content(test_id, version)`; tải media từ Storage bằng session của chính nó; mỗi đề đã publish là một dòng document trong Drift `topik_content_cache` (không nạp quan hệ); `TopikContentRepository.catalog()` giữ hợp đồng; làm mới khi app mở và khi có mạng, offline dùng cache |
| 5 | Bộ kiểm tra | Một bộ luật (BR-TOPIK-001…007), ba cổng kiểm: Dart `checkTopikTest` là bản tham chiếu và là cổng cuối ở app; SQL kiểm hình dạng khi publish; TypeScript ở Admin Web cho tác giả. Fixture dùng chung (xuất từ `test/`) là hợp đồng: ba bản phải cho cùng kết quả trên từng fixture |
| 6 | Dữ liệu người dùng | Không đổi: `topik_attempt`, `topik_attempt_answer`, outbox, `sync_push`, `sync_changes`. Master Data không đi qua sync người dùng, không có `user_id`, không bị xoá khi đổi tài khoản |
| 7 | Bảo mật | Bảng Master Data: RLS bật, không policy, không quyền cho `anon`/`authenticated`, chỉ RPC `SECURITY DEFINER` (ADR-015 #5). Ngoại lệ duy nhất: `storage.objects` dùng policy (cơ chế duy nhất của Storage), giới hạn trong bucket `topik-media`: admin ghi, `authenticated` (người dùng phải có dòng `profiles`) chỉ đọc object của mọi phiên bản đã tồn tại của một đề đang published |

## Hệ quả

- ADR-023 #3 và #5 bị thay: nội dung không còn đóng gói trong repo; repo giữ schema nội dung, validator Dart, lint cho fixture và SQL của kho Master Data; pipeline PDF/MP3 → JSON vẫn ở `memox-topik-content`, kết quả nhập qua Admin Web.
- Spec 2026-10-15: D2, D3, D5, D13, §3.1, §4.3, §13.4 được chú thích "thay bởi ADR-024"; §5, §6, §8, §13.1–13.3, §13.5–13.8 giữ nguyên.
- BR-TOPIK-007 ghi thêm "phiên bản đã publish bất biến, server cấp số phiên bản kế tiếp"; BR-TOPIK-008 đổi "một bộ kiểm tra duy nhất ở app và ở gate" thành "một bộ luật, ba cổng kiểm với cùng fixture" (chủ dự án duyệt, spec §11 O7).
- Schema Drift lên v18 với `topik_content_cache` và `topik_content_state`; `assets/topik/` và `TopikContentAssetDataSource` bị bỏ; `PRODUCT.md`, README `topik`, `supabase/README.md` (rules, giới hạn Storage), `schema.md` cập nhật.
- Supabase: một migration thêm bốn bảng, trigger bất biến, các RPC admin và client, bucket và policy Storage, pgTAP; chủ dự án thêm domain Vercel vào Auth URL configuration và chạy `supabase db push` sau khi plan 1 merge.
- Plan 1 (kho Master Data trong `supabase/`) đã xây trên branch `ccr-b0d5b7c9-mlvno2` (DEV-394), chưa push migration. Spec được sửa cho khớp bản xây: `media` là mảng đường dẫn (không checksum), `checksum` là `md5(json::text)`, server ghi đè `contentVersion` trong JSON đã lưu khi publish; publish/rollback đề retired và rollback về phiên bản đang hiện hành là `INVALID_STATE`; `catalog_version` cấp dưới một advisory lock toàn cục nên thứ tự cấp là thứ tự commit; đường dẫn media phải là `{test_id}/{số nguyên dương}/{file}`; quyền đọc Storage theo mọi phiên bản đã tồn tại; hợp đồng fixture chỉ khẳng định SQL ⊆ Dart trên fixture Dart chấp nhận.
- Phương án bị loại (spec §3.3): giữ đóng gói; Master Data là file JSON trong Storage không có bảng; nạp quan hệ vào Drift; service role trên server Next.js; Edge Function cho publish; Admin Web trong repo này.
