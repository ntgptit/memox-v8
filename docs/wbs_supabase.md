# WBS Supabase — MemoX V8

- **Trạng thái:** hiện hành, sửa mỗi khi một hạng mục đổi trạng thái.
- **Mục đích:** cho người và agent biết phần đồng bộ với server trên Supabase nào đã
  xong, phần nào còn lại và làm theo thứ tự nào.
- **Phạm vi:** mọi thứ của sync và danh tính theo
  [ADR-015](shared/decisions/ADR-015-supabase-lam-backend.md): schema và RPC trong
  `supabase/`, pgTAP, workflow vận hành, phía app của sync (`lib/core/sync/`, cột và
  trigger sync trong Drift, adapter) và login. Màn hình mới của sync và login có
  hạng mục ở đây nhưng tiến độ phần giao diện ghi thêm ở [`wbs_FE.md`](wbs_FE.md).
- **Nguồn sự thật cho:** tiến độ và thứ tự của các hạng mục sync trên Supabase. File
  này không phát biểu lại rule:
  - vai trò của Supabase, danh tính và ranh giới bảo mật thuộc ADR-015;
  - giao thức, luật xung đột theo loại dữ liệu và SRS thuộc
    [spec sync](superpowers/specs/2026-09-27-server-sync-design.md) §4–§6;
  - schema và RPC đã chạy thuộc
    [spec backend Supabase](superpowers/specs/2026-09-28-supabase-backend-design.md)
    và `supabase/migrations/`;
  - hành vi thuộc BR/UC trong `features/`, dữ liệu local thuộc
    [`schema.md`](shared/data/schema.md).
- **Thay cho:** nhóm "Đồng bộ với server" của [`wbs_BE.md`](wbs_BE.md) (BE-E2…BE-E6
  viết theo mô hình lệnh của ADR-014) và [`wbs_API.md`](wbs_API.md) (đóng băng).
- **Ngữ cảnh bằng chứng:** tạo từ `master` tại `561a58cf` (PR #125) ngày 2026-09-28,
  sau khi sync deck chạy thật trên project `hgacyucfagsvolymlqto`.

## Trạng thái hiện tại

Sync deck và thùng rác chạy đầu cuối trên project thật (2026-09-28):

- migration `20260928000000_deck_sync` lên project qua workflow `supabase migrations`
  ([run 36367806645](https://github.com/ntgptit/memox-v8/actions/runs/36367806645));
- vai trò `anon` bị từ chối (`42501`) ở cả bốn bảng và ở `sync_push`, `sync_changes`;
  schema `private` không lộ ra Data API; `ping` trả `"ok"`;
- hai user ẩn danh tách biệt: user B không thấy deck của user A, và upsert trùng id
  bị `SYNC_ENTITY_CONFLICT` mà không lộ `current`;
- APK build 8 (`561a58cf`, sau PR #125 thêm quyền `INTERNET`) cài trên thiết bị của
  chủ dự án đã đăng nhập ẩn danh và đẩy deck lên `public.deck`;
- workflow keep-alive gọi `ping` hằng ngày.

Chưa đồng bộ: card, tags, liên kết card–tag, review log, lịch SRS, setting theo tài
khoản. Chưa có login: mỗi lần cài app là một user ẩn danh mới.

## Hạng mục

Quy ước giống [`wbs_BE.md`](wbs_BE.md):

- **Trạng thái:** `xong` (đạt Definition of Done và đã merge vào `master`) ·
  `đang làm` · `chưa bắt đầu` · `bị chặn` (cần một quyết định trước khi làm) ·
  `cắt` (chủ dự án quyết không làm; lý do ở cột Bằng chứng).
- **Cỡ:** S < M < L < XL, ước lượng chứ không phải cam kết.
- **Người làm:** `chủ dự án` khi hạng mục cần quyền tài khoản (dashboard, secret,
  mật khẩu), mà agent không được dùng; để trống khi agent làm được.
- Mỗi nhóm có code đi qua brainstorm → spec → plan → thực thi → review của
  Superpowers (`CLAUDE.md`). Một hạng mục là đơn vị lập kế hoạch, không phải một task
  của plan.
- Câu ghi "giả định" là điều chưa kiểm trên project hay trên trang của Supabase; người
  làm hạng mục kiểm lại trước khi dựa vào nó.

### Đã xong

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng |
|---|---|---|---|---|---|
| BE-E1 | Sync deck phía app theo mô hình hàng: `sync_outbox`, `sync_state`, `server_version`, trigger, `SyncCoordinator`, adapter `deck` và `delete_batches` | xong | — | XL | [PR #114](https://github.com/ntgptit/memox-v8/pull/114) |
| BE-E8 | Backend Supabase cho sync deck: bảng và RPC `sync_push`/`sync_changes`/`ping`, RLS không policy, pgTAP; `SupabaseSyncApi` và đăng nhập ẩn danh; job CI `supabase`, workflow keep-alive | xong | BE-E1 | L | [PR #123](https://github.com/ntgptit/memox-v8/pull/123); kiểm trên project thật ở mục "Trạng thái hiện tại" |
| SB-O0 | Đưa schema lên project qua CI: workflow `supabase migrations` (link, list, `db push`, list) chạy khi merge vào `master` có đổi `supabase/migrations/**`; Build APK truyền `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY` qua `--dart-define-from-file`; manifest release có quyền `INTERNET` | xong | BE-E8 | M | [PR #123](https://github.com/ntgptit/memox-v8/pull/123), [#124](https://github.com/ntgptit/memox-v8/pull/124), [#125](https://github.com/ntgptit/memox-v8/pull/125); `test/app/android_manifest_test.dart` |
| SB-O4 | Keep-alive chạy xanh lần đầu: chạy tay `supabase keep-alive`, xem `ping` trả `"ok"` | xong | — | S | [Run 36369154145](https://github.com/ntgptit/memox-v8/actions/runs/36369154145) (2026-09-28) in `"ok"`; từ đó chạy theo lịch hằng ngày |

### A. Vận hành và bảo mật

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-O1 | Dọn và khoá project trên dashboard, một lượt: (1) thay secret key và mật khẩu database đã lộ trong phiên chat ngày 2026-09-28, cập nhật secret `SUPABASE_DB_PASSWORD` của repo và biến User env trên máy; (2) xoá dữ liệu test: user ẩn danh `208b8bc6-…` (deck "AB isolation check") và `dd6d7a13-…`, rồi xoá tay các dòng của hai user trong `deck`, `user_sync_version`, `sync_applied_op`; (3) chống tạo user ẩn danh hàng loạt: giữ giới hạn tần suất mặc định cho anonymous sign-ins, hoặc bật CAPTCHA | chưa bắt đầu | chủ dự án | — | M | Làm trước mọi hạng mục khác. Gộp SB-O2 (2) và SB-O3 (3) vào đây ngày 2026-09-28. Xác nhận (1): workflow `supabase migrations` chạy tay (`workflow_dispatch`) vẫn xanh với mật khẩu mới. (2): `deck.user_id` không có FK tới `auth.users` (spec backend Supabase §3), nên xoá user **không** kéo theo dữ liệu. (3): README `supabase/` bước 2; bật CAPTCHA thì app phải gửi token CAPTCHA khi `signInAnonymously`, là việc phía app chưa có hạng mục, nên đề xuất giữ giới hạn mặc định |
| SB-O5 | Gate và phát hiện lệch schema trong workflow `supabase migrations`: (1) chạy `supabase db start` và `supabase test db` (pgTAP) trước `db push`, để một migration hỏng không lên project; (2) một bước `supabase db diff --linked` báo lỗi khi project có thay đổi schema làm tay trên dashboard | xong | | — | M | Gộp SB-O6 (2) vào đây ngày 2026-09-28: cùng một file workflow, và `db diff` cần Docker mà bước (1) đã khởi động. `migration list` không thay được `db diff`: nó chỉ so lịch sử migration, không thấy DDL chạy trong SQL Editor. Hiện CI (có job `supabase`) chỉ chạy tay nên không chặn được merge. Quy tắc: không sửa schema bằng SQL Editor; migration là đường duy nhất. Code: `.github/workflows/supabase-migrations.yml` (bước `pgTAP` trước `link`, bước `schema matches migrations` sau `db push`). Lần chạy đầu ([run 36388782572](https://github.com/ntgptit/memox-v8/actions/runs/36388782572)) bắt được `public.rls_auto_enable()`, hàm event trigger Supabase tạo cùng project để tự bật RLS; chủ dự án quyết miễn trừ nó (README `supabase/`). Xanh ở [run 36389329856](https://github.com/ntgptit/memox-v8/actions/runs/36389329856) (2026-09-28) |
| SB-O7 | Sao lưu: chốt cách giữ bản sao dữ liệu trên gói Free, ví dụ workflow hằng tuần `supabase db dump --data-only` lưu thành artifact có hạn | tạm dừng | chủ dự án | SB-O1 | M | Ngày 2026-09-28 chủ dự án quyết chưa sao lưu, làm khi có người dùng thật; repo đang public nên bản dump phải mã hoá (đề xuất: workflow hằng tuần, gpg với secret `BACKUP_PASSPHRASE`, artifact giữ 30 ngày). Giả định: gói Free không có bản sao lưu tải được. Cần chủ dự án chọn nơi lưu và thời hạn; dump chứa dữ liệu người dùng nên không để ở chỗ công khai |
| SB-O8 | Theo dõi hạn mức Free (500 MB database, 50.000 MAU, pause sau một tuần không hoạt động): một truy vấn hoặc bước CI báo cỡ database và số user | đang làm | | — | S | Số liệu hạn mức từ ADR-015 (kiểm ngày 2026-09-28). Code: `.github/workflows/supabase-usage.yml` (thứ Hai hằng tuần và chạy tay; `db query --linked` chỉ cần `SUPABASE_ACCESS_TOKEN`; đỏ ở 80% hạn mức). Số user hoạt động 30 ngày là xấp xỉ MAU. Chờ lần chạy tay đầu tiên sau merge |

### B. Mở rộng sync (spec sync §9 bước 4)

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-S1 | Spec và plan sync card, tags, card–tag, review log, lịch SRS và setting theo tài khoản trên Supabase, theo mô hình hàng. Chốt các câu hỏi mở ở mục "Quyết định còn mở" | xong | | BE-E8 | M | [PR #140](https://github.com/ntgptit/memox-v8/pull/140); [Spec](superpowers/specs/2026-09-28-sync-library-and-study-design.md); [ADR-017](shared/decisions/ADR-017-lich-srs-dong-bo-nhu-mot-dong.md). Chủ dự án chốt ngày 2026-09-28: liên kết card–tag là trường `tagIds` của card; setting tài khoản một dòng mỗi user, `entityId` là nil UUID; review của generation cũ giữ làm lịch sử; cả lượt pull trong một transaction (giả định SB-S8 đã kiểm là đúng); lịch SRS đồng bộ như một dòng, lịch tiến xa hơn thắng, bỏ phát lại của spec sync §6 (ADR-017). Plan viết riêng cho từng slice khi bắt đầu slice đó. Thay BE-E2, BE-E4, BE-E5 của `wbs_BE.md` |
| SB-S2 | Sync `card` và Trash xuyên loại: (1) bảng server (CHECK và FK như Drift, `deck_id` → `deck`, tombstone, `delete_batch_id`), `sync_push`/`sync_changes` nhận loại `card`, pgTAP; Drift migration thêm `server_version` và trigger outbox cho `card`, adapter card; cơ chế đặt lại cursor pull khi app có loại mới, làm chung một lần cho mọi loại về sau (coordinator hiện bỏ qua loại lạ mà vẫn nhích `since`); cả lượt pull trong một transaction; xoá deck kéo theo tombstone card trên server; (2) xoá, Undo, khôi phục và purge deck kéo theo card đồng bộ đúng; dọn Trash hết hạn chỉ ở local; (3) ghi hàng loạt: import card và starter deck sinh nhiều dòng outbox, push và pull chạy hết mà không nghẽn UI, đo trên một bộ lớn | xong | | SB-S1 | XL | [PR #141](https://github.com/ntgptit/memox-v8/pull/141); [Plan](superpowers/plans/2026-09-28-card-sync.md). Server: `supabase/migrations/20260929000000_card_sync.sql` (bảng `card`, `CARD_DECK_MISSING`, xoá deck tombstone card), pgTAP `05_card_sync.sql`; Drift schema 7 (`card.server_version`, trigger outbox, xếp card có sẵn vào outbox); `CardSyncAdapter` (lịch ban đầu cho card kéo về); coordinator áp cả lượt pull trong một transaction và kéo lại từ `since = 0` khi có loại mới (`pull_entity_types`). Test: `test/core/sync/card_sync_*`, `sync_bulk_test.dart`, `test/drift/`. Bài đo 5.000 card (Drift in-memory, server giả, container cloud): push khoảng 3 s (51 lượt), pull khoảng 0,4 s (11 trang, một transaction). Chạy pgTAP không cần Docker: `tools/supabase/local_pgtap.sh`. Gộp SB-S6 (2) và SB-S7 (3) vào đây ngày 2026-09-28. (1): luật xung đột là upsert cả hàng, thao tác server áp sau thắng (spec sync §5). (2): thay BE-E3 của `wbs_BE.md`; card có FK `deck_id`, nên đưa card lên mà xoá và purge deck chưa kéo theo card thì dữ liệu lệch hoặc bị FK chặn; `delete_batch` đã đồng bộ cho deck. (3): push chia lô 100 và pull phân trang 500 đã có trong `SyncCoordinator` (`pushBatchSize`, `pullPageSize`; spec backend Supabase §4), phần còn lại là bài đo Lỗi thứ tự đẩy (card chờ đẩy chuyển sang deck mới tạo bị từ chối `CARD_DECK_MISSING`) sửa ở SB-S3 (R6). |
| SB-S3 | Sync `tags` và liên kết card–tag: bảng server với tên tag duy nhất theo user; khi hai máy tạo cùng tên thì gộp tag local vào tag từ server bằng `TagDao.merge` và xếp lại card bị ảnh hưởng vào outbox; liên kết đi trong trường `tagIds` của card; bài đo ghi hàng loạt của SB-S2 chạy lại với tag và liên kết | xong | | SB-S2 | L | [PR #143](https://github.com/ntgptit/memox-v8/pull/143); [Plan](superpowers/plans/2026-09-28-tag-sync.md). Server: `supabase/migrations/20260930000000_tag_sync.sql` (`tags` với tên duy nhất trong tag sống, `card_tags` suy từ `tagIds` của card, `TAG_NAME_TAKEN`; card không có `tagIds` giữ nguyên liên kết), pgTAP `06_tag_sync.sql`; Drift schema 8 (`tags.server_version`, trigger outbox cho tag và cho `card_tags`, xếp tag và card có tag vào outbox); `TagSyncAdapter` gộp tag local trùng tên vào tag kéo về; outbox đẩy theo loại rồi `created_at` (R6); pull kiểm pending từng thay đổi (R7). Test: `test/core/sync/tag_*`, `sync_triggers_test.dart`, `sync_bulk_test.dart`, `test/drift/`. Bài đo 5.000 card gắn tag (Drift in-memory, server giả): push khoảng 4,5 đến 5,2 s, pull khoảng 1,2 đến 1,4 s. Chấp nhận (R9): đổi tên tag local trùng tên máy khác đã tạo trước bị từ chối và quay về tên cũ. Spec SB-S1 §3.2 |
| SB-S4 | Sync `review_log` (chỉ thêm, insert-if-absent theo `id`, giữ review mọi generation làm lịch sử) và `card_schedule` như một dòng: khi pull, lịch local tiến xa hơn thì giữ và đẩy lại, không thì nhận bản server | xong | | SB-S2 | L | [PR #145](https://github.com/ntgptit/memox-v8/pull/145); [Plan](superpowers/plans/2026-09-28-study-history-sync.md). Server: `supabase/migrations/20261002000000_study_history_sync.sql` (`review_log` chỉ thêm, `card_schedule` upsert cả dòng; `CARD_MISSING` cho card server chưa thấy, card đã xoá thì nhận rồi bỏ; lệnh xoá hai loại này là no-op; xoá card và deck xoá cứng review và lịch), pgTAP `08_study_history_sync.sql`; Drift schema 10 (trigger thêm review, thêm hoặc sửa lịch; xếp dữ liệu sẵn có); `compareScheduleProgress` (5 luật của spec §3.4); `ReviewLogSyncAdapter`, `CardScheduleSyncAdapter` (lịch local tiến xa hơn thì giữ và đẩy lại). Test: `test/core/sync/schedule_progress_test.dart`, `study_history_*`, `sync_triggers_test.dart`, `test/drift/sync_seed_migration_test.dart`. Spec SB-S1 §3.3–3.4, ADR-017 (không phát lại log). Cần test thứ tự so sánh từng luật và "hai máy cùng ôn offline hội tụ" |
| SB-S5 | Setting theo tài khoản: tuỳ chọn học và trình bày (`card_limit`, `new_card_order`, `theme_mode`, `language`) đồng bộ; nhắc học (`reminder_*`) giữ trên máy | xong | | SB-S1 | M | [PR #144](https://github.com/ntgptit/memox-v8/pull/144); [Plan](superpowers/plans/2026-09-28-account-settings-sync.md). Server: `supabase/migrations/20261001000000_account_settings_sync.sql` (bảng `account_settings` một dòng mỗi user, id trên dây là nil UUID, không có xoá), pgTAP `07_account_settings_sync.sql`; Drift schema 9 (trigger `app_settings_sync_update` chỉ khi đổi 1 trong 4 cột; nâng cấp chỉ xếp dòng khi khác mặc định, R11); `AccountSettingsSyncAdapter` (dòng `id = 1`, nhắc học giữ trên máy). Test: `test/core/sync/account_settings_sync_test.dart`, `sync_triggers_test.dart`, `test/drift/`. Spec SB-S1 §3.5: bảng server khoá theo `user_id`, `entityId` là nil UUID, trigger chỉ khi một trong bốn cột đồng bộ đổi |
| SB-S8 | Máy mới hoặc cài lại kéo toàn bộ dữ liệu từ `since = 0` và dựng lại Drift đúng thứ tự phụ thuộc (deck → card → tag → liên kết → review log → lịch) | chưa bắt đầu | | SB-S3, SB-S4, SB-S5 | S | Chỉ có ý nghĩa khi có login (nhóm C); với ẩn danh, cài lại là user mới. Thứ tự qua nhiều trang đã giải ở SB-S2 (cả lượt pull một transaction, spec SB-S1 §4.2); phần còn lại là kiểm trên hai máy thật. Từ SB-S4 mọi loại dữ liệu đều đồng bộ; phần còn lại cần login (nhóm C). |

### C. Danh tính và tài khoản (spec sync §9 bước 5)

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-A1 | Spec auth: cách đăng nhập (email OTP, magic link, mật khẩu hay Google), gắn danh tính vào **cùng** user ẩn danh để không phải chuyển dữ liệu, đăng xuất, và cách xử lý `owner_id` local đang `NULL` | xong | chủ dự án | — | M | [Spec](superpowers/specs/2026-09-30-auth-design.md), chủ dự án duyệt 2026-09-30: email OTP và Google, gộp máy thứ hai bằng claim token, đăng xuất xoá dữ liệu trên máy, role trong `public.profiles`. Thay BE-E6 của `wbs_BE.md`. Ngày 2026-09-28 chủ dự án tạm dừng việc đăng nhập để cân nhắc lại chuyện tài khoản người dùng; sẽ bàn lại trước khi viết spec. Ý kiến ban đầu, **chưa chốt**: đăng nhập bằng email OTP và Google; máy thứ hai có dữ liệu ẩn danh thì hỏi người dùng, mặc định gộp. Chưa bàn: đăng xuất, `owner_id` local |
| SB-A2 | Login phía app: màn đăng nhập, gắn danh tính, giữ session; không đổi `user_id` của dữ liệu đã đồng bộ; báo cho người dùng rằng dữ liệu đang gắn với lần cài này (ẩn danh) và mời gắn email, làm lối vào màn đăng nhập | đang làm | | SB-A1 | L | P2 (core auth, logic, plan `superpowers/plans/2026-09-30-accounts-core-auth.md`) xong; UI ở P3. Gộp SB-U2 (lời báo và lời mời) vào đây ngày 2026-09-28: nó là lối vào của màn này nên cùng một lượt `shape` và plan. Màn này không có trong kit: dùng Impeccable `shape` trước khi plan (`CLAUDE.md`); ghi thêm hạng mục ở `wbs_FE.md` |
| SB-A3 | Nhiều máy cùng tài khoản: máy thứ hai đăng nhập thì kéo dữ liệu về; dữ liệu ẩn danh đã có trên máy đó được gộp hay bỏ theo spec auth | đang làm | | SB-A2, SB-S8 | L | P2 (core auth, logic, plan `superpowers/plans/2026-09-30-accounts-core-auth.md`) xong; UI ở P3. Đây là lúc sync giữa các máy của cùng một người bắt đầu có tác dụng |
| SB-A4 | Cấu hình Auth cho Android: redirect URL và deep link cho email, mẫu email, SMTP riêng nếu cần | chưa bắt đầu | chủ dự án | SB-A1 | S | Giả định: email dựng sẵn của Supabase có giới hạn gửi rất thấp, không đủ cho người dùng thật |
| SB-A5 | Xoá dữ liệu theo user: (1) xoá tài khoản trong app (Google Play đòi hỏi khi app có tạo tài khoản): RPC xoá toàn bộ dữ liệu của `auth.uid()` rồi xoá user; (2) dọn user ẩn danh mồ côi: user ẩn danh không hoạt động quá N ngày thì xoá cùng dữ liệu, chạy theo lịch, dùng lại hàm xoá của (1) | đang làm | | SB-A2 | M | Server (P1, [plan](superpowers/plans/2026-09-30-accounts-server.md)): `account_delete`, `private.cleanup_accounts` (cron `account-cleanup`, ẩn danh 90 ngày), migration `20261010000000_accounts.sql`, pgTAP `12_account.sql`. Phía app (P3b, FE-B10, [plan](superpowers/plans/2026-09-30-account-ui-manage.md)): "Delete account" ở màn 32, chỉ khi online; còn lại kiểm tra trên máy sau SB-A4. Gộp SB-A6 (2) vào đây ngày 2026-09-28: chung một hàm `SECURITY DEFINER` và một bộ pgTAP chứng minh không xoá được dữ liệu người khác. (2): mỗi lần cài lại app tạo một user ẩn danh mới, nên dữ liệu cũ nằm lại mãi; chủ dự án chốt N |

### D. Trải nghiệm sync trong app

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-U1 | Lỗi sync không còn im lặng: ghi lại lần sync gần nhất và lỗi gần nhất (mạng, đăng nhập, RPC bị từ chối), và hiện trạng thái đó ở một chỗ người dùng xem được | xong | | — | M | [PR #138](https://github.com/ntgptit/memox-v8/pull/138); [Spec](superpowers/specs/2026-09-28-sync-status-design.md) và [plan](superpowers/plans/2026-09-28-sync-status.md). Drift schema 6: bảng `sync_rejection` và các key `last_success_at`, `last_failure_at`, `last_failure_kind`; scheduler ghi từng lượt, coordinator ghi dòng bị từ chối; màn 27 [27-sync.md](shared/ui/screen-handoff/27-sync.md), dòng Sync ở màn 23, banner ở màn 13 (hiện khi có thay đổi chờ quá 24 giờ hoặc dòng bị từ chối); test trong `test/core/sync/`, `test/drift/`, `test/features/settings/presentation/`, `test/features/study/presentation/`. Bài học 2026-09-28: bản release thiếu `INTERNET` làm `signInAnonymously` thất bại mà app không báo gì |

## Quyết định còn mở

| Hạng mục | Câu hỏi | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| SB-O7 | Nơi lưu và thời hạn giữ bản sao lưu | Khôi phục khi mất dữ liệu | Chủ dự án (tạm dừng 2026-09-28: chưa sao lưu tới khi có người dùng thật) |

## Bước tiếp theo

1. SB-O1 (chủ dự án, một lượt trên dashboard).
2. SB-O8: chủ dự án chạy tay workflow `supabase usage` lần đầu trên `master`.
3. SB-S2 → SB-S3 → SB-S4; SB-S5 làm được bất cứ lúc nào (spec SB-S1 đã xong).
4. SB-A1 có thể làm song song với nhóm B khi chủ dự án chọn cách đăng nhập; SB-A2
   trở đi sau SB-A1.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-28** theo yêu cầu của chủ dự án, sau khi sync deck chạy trên
  project thật. Nhận nhóm "Đồng bộ với server" từ `wbs_BE.md`: BE-E1 và BE-E8 chép
  sang mục "Đã xong"; BE-E2…BE-E6 (mô hình lệnh) được lập lại theo mô hình hàng thành
  SB-S1…SB-S6 và SB-A1…SB-A3; BE-E7 giữ trạng thái `hoãn` ở `wbs_BE.md`.
- **Cập nhật ngày 2026-09-28** theo rà soát của chủ dự án, gộp những hạng mục làm
  chung một chỗ hoặc không tách được. SB-O2 và SB-O3 gộp vào SB-O1 (một lượt trên
  dashboard). SB-O6 gộp vào SB-O5 (cùng workflow). SB-S6 và SB-S7 gộp vào SB-S2: card
  có FK tới deck nên Trash không tách được, còn chia lô và phân trang đã có trong
  coordinator. SB-U2 gộp vào SB-A2 (lối vào màn đăng nhập). SB-A6 gộp vào SB-A5 (cùng
  hàm xoá). ID đã gộp không dùng lại. Sửa kèm: SB-S8 phụ thuộc thêm SB-S3; SB-O5 chỉ
  dùng `db diff --linked` để bắt lệch schema; cơ chế đặt lại cursor pull ghi là việc
  chung của SB-S2; SB-O4 chuyển lên "Đã xong"; thêm câu hỏi mở về thứ tự dựng lại qua
  nhiều trang pull.
- **Cập nhật ngày 2026-09-28:** SB-O5 xong (gate pgTAP và kiểm lệch schema chạy xanh
  trên project thật, miễn trừ `public.rls_auto_enable()` theo quyết định của chủ dự
  án). SB-O8 có workflow `supabase usage`, chờ lần chạy đầu sau merge vì GitHub chỉ
  cho chạy tay workflow đã có trên nhánh mặc định.
- **Cập nhật ngày 2026-09-28:** SB-U1 xong: lỗi sync được ghi lại và hiện ở Settings
  (dòng Sync), màn 27 Sync và banner ở Study home; màn và banner ghi thêm ở
  `wbs_FE.md` (FE-B7).
- **Cập nhật ngày 2026-09-28:** SB-S1 xong: spec sync card, tag, review log, lịch SRS
  và setting tài khoản; bốn câu hỏi mở của nhóm B đã chốt và chuyển vào spec. Lịch SRS
  đổi từ phát lại log sang đồng bộ như một dòng (ADR-017). SB-S4 giảm từ XL xuống L,
  SB-S8 từ M xuống S.
- **Cập nhật ngày 2026-09-28:** SB-S2 xong: card đồng bộ hai chiều; xoá deck, Trash và
  purge kéo theo card; pull một transaction; loại mới kéo lại từ đầu.
- **Cập nhật ngày 2026-09-28:** SB-S3 xong: tag và liên kết card–tag đồng bộ, trùng tên thì
  gộp; sửa kèm thứ tự đẩy của SB-S2 (hàng cha trước hàng con theo loại).
- **Cập nhật ngày 2026-09-28:** SB-S5 xong: tuỳ chọn học và trình bày đồng bộ theo tài khoản;
  nhắc học ở lại trên máy; cài đặt mặc định không đẩy lên.
- **Cập nhật ngày 2026-09-28:** SB-S4 xong: review log và lịch SRS đồng bộ, lịch tiến xa hơn
  thắng (ADR-017). Nhóm B chỉ còn SB-S8, chờ login.
- **Cập nhật ngày 2026-09-28:** chủ dự án tạm dừng SB-A1 (đăng nhập, tài khoản) để cân nhắc
  lại; nhóm C chờ buổi bàn tiếp. SB-O7 tạm dừng tới khi có người dùng thật. Còn lại cần chủ
  dự án: SB-O1 (dashboard) và SB-O8 (chạy tay `supabase usage` lần đầu).

- **Cập nhật ngày 2026-09-30:** SB-A1 xong (spec auth); P1 phía server làm theo plan 2026-09-30-accounts-server: profiles và role, khoá ngoại về `auth.users`, `me`, role, gộp máy thứ hai, xoá tài khoản, dọn ẩn danh 90 ngày. Bỏ SB-A1 khỏi "Quyết định còn mở".
- **Cập nhật ngày 2026-09-30 (P2):** P2 core auth: `AccountCoordinator` (45 hàng của spec §3.3), sync chỉ chạy khi `Ready`, `isAdmin` từ `me()`; chưa có màn hình (P3). SB-A2 và SB-A3 sang đang làm.
