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

### A. Vận hành và bảo mật

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-O1 | Thay secret key và mật khẩu database đã lộ trong phiên chat ngày 2026-09-28; cập nhật secret `SUPABASE_DB_PASSWORD` của repo và biến User env trên máy | chưa bắt đầu | chủ dự án | — | S | Làm trước mọi hạng mục khác. Xác nhận: workflow `supabase migrations` chạy tay (`workflow_dispatch`) vẫn xanh với mật khẩu mới |
| SB-O2 | Xoá dữ liệu test: user ẩn danh `208b8bc6-…` (deck "AB isolation check") và `dd6d7a13-…`. Nếu deck không tự mất khi xoá user thì xoá tay các dòng của hai user trong `deck`, `user_sync_version`, `sync_applied_op` | chưa bắt đầu | chủ dự án | — | S | `deck.user_id` không có FK tới `auth.users` (spec backend Supabase §3), nên xoá user **không** kéo theo dữ liệu |
| SB-O3 | Chống tạo user ẩn danh hàng loạt: bật CAPTCHA cho anonymous sign-ins, hoặc chốt giữ giới hạn tần suất mặc định | chưa bắt đầu | chủ dự án | — | S | README `supabase/` bước 2. Nếu bật CAPTCHA thì app phải gửi token CAPTCHA khi `signInAnonymously`, tức là thêm việc ở phía app |
| SB-O4 | Keep-alive chạy xanh lần đầu: chạy tay `supabase keep-alive`, xem `ping` trả `"ok"` | xong | | — | S | [Run 36369154145](https://github.com/ntgptit/memox-v8/actions/runs/36369154145) (2026-09-28) in `"ok"`; từ đó chạy theo lịch hằng ngày |
| SB-O5 | Gate trước khi đẩy schema: workflow `supabase migrations` chạy `supabase db start` và `supabase test db` (pgTAP) trước `db push`, để một migration hỏng không lên project | chưa bắt đầu | | — | S | Hiện CI (có job `supabase`) chỉ chạy tay nên không chặn được merge |
| SB-O6 | Phát hiện lệch schema: một bước CI so project với `supabase/migrations/` (`supabase db diff --linked` hoặc `migration list`) và báo lỗi khi có thay đổi làm tay trên dashboard | chưa bắt đầu | | SB-O5 | S | Quy tắc: không sửa schema bằng SQL Editor; migration là đường duy nhất |
| SB-O7 | Sao lưu: chốt cách giữ bản sao dữ liệu trên gói Free, ví dụ workflow hằng tuần `supabase db dump --data-only` lưu thành artifact có hạn | bị chặn | chủ dự án | SB-O1 | M | Giả định: gói Free không có bản sao lưu tải được. Cần chủ dự án chọn nơi lưu và thời hạn; dump chứa dữ liệu người dùng nên không để ở chỗ công khai |
| SB-O8 | Theo dõi hạn mức Free (500 MB database, 50.000 MAU, pause sau một tuần không hoạt động): một truy vấn hoặc bước CI báo cỡ database và số user | chưa bắt đầu | | — | S | Số liệu hạn mức từ ADR-015 (kiểm ngày 2026-09-28) |

### B. Mở rộng sync (spec sync §9 bước 4)

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-S1 | Spec và plan sync card, tags, card–tag, review log, lịch SRS và setting theo tài khoản trên Supabase, theo mô hình hàng. Chốt các câu hỏi mở ở mục "Quyết định còn mở" | chưa bắt đầu | | BE-E8 | M | Thay BE-E2, BE-E4, BE-E5 của `wbs_BE.md` |
| SB-S2 | Sync `card`: bảng server (CHECK và FK như Drift, `deck_id` → `deck`, tombstone, `delete_batch_id`), `sync_push`/`sync_changes` nhận loại `card`, pgTAP; Drift migration thêm `server_version` và trigger outbox cho `card`, adapter card, đặt lại cursor pull khi thêm loại mới (coordinator hiện bỏ qua loại lạ mà vẫn nhích `since`) | chưa bắt đầu | | SB-S1 | L | Luật xung đột: upsert cả hàng, thao tác server áp sau thắng (spec sync §5) |
| SB-S3 | Sync `tags` và liên kết card–tag: bảng server với tên tag duy nhất theo user; khi hai máy tạo cùng tên thì gộp bằng luồng gộp sẵn có (BR-TAG-003…BR-TAG-011) và sửa id tag trong outbox | chưa bắt đầu | | SB-S2 | L | `card_tags` có PK ghép `(card_id, tag_id)` trong khi giao thức cần `entityId` là UUID: xem "Quyết định còn mở" |
| SB-S4 | Sync `review_log` (chỉ thêm, insert-if-absent theo `id`) và `card_schedule` (dẫn xuất): sau pull có review mới, app phát lại review của từng thẻ theo `(reviewed_at, id)` qua scheduler của thẻ đó rồi đẩy lịch như một upsert dẫn xuất; review của generation cũ xử lý theo spec sync §6 | chưa bắt đầu | | SB-S2 | XL | Phát lại phải tất định: UTC, `Clock` tiêm vào, thứ tự toàn phần. Cần bộ test "hai máy cùng log ra cùng lịch" |
| SB-S5 | Setting theo tài khoản: tuỳ chọn học và trình bày (`card_limit`, `new_card_order`, `theme_mode`, `language`) đồng bộ; nhắc học (`reminder_*`) giữ trên máy | chưa bắt đầu | | SB-S1 | M | `app_settings` local có `id = 1` cố định, nên cần khoá server theo user: xem "Quyết định còn mở" |
| SB-S6 | Trash xuyên loại: xoá, Undo, khôi phục và purge deck kéo theo card đồng bộ đúng; dọn Trash hết hạn chỉ ở local | chưa bắt đầu | | SB-S2 | M | Thay BE-E3 của `wbs_BE.md`. `delete_batch` đã đồng bộ cho deck |
| SB-S7 | Ghi hàng loạt: import card và starter deck sinh nhiều dòng outbox; push chia lô (tối đa 100 thao tác mỗi lần gọi) và pull phân trang (tối đa 500 dòng) chạy hết mà không nghẽn UI; đo trên một bộ lớn | chưa bắt đầu | | SB-S2, SB-S3 | M | Giới hạn 100/500 ở spec backend Supabase §4 |
| SB-S8 | Máy mới hoặc cài lại kéo toàn bộ dữ liệu từ `since = 0` và dựng lại Drift đúng thứ tự phụ thuộc (deck → card → tag → liên kết → review log → lịch) | chưa bắt đầu | | SB-S4, SB-S5 | M | Chỉ có ý nghĩa khi có login (nhóm C); với ẩn danh, cài lại là user mới |

### C. Danh tính và tài khoản (spec sync §9 bước 5)

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-A1 | Spec auth: cách đăng nhập (email OTP, magic link, mật khẩu hay Google), gắn danh tính vào **cùng** user ẩn danh để không phải chuyển dữ liệu, đăng xuất, và cách xử lý `owner_id` local đang `NULL` | bị chặn | chủ dự án | — | M | Thay BE-E6 của `wbs_BE.md`. Cần chủ dự án chọn cách đăng nhập |
| SB-A2 | Login phía app: màn đăng nhập, gắn danh tính, giữ session; không đổi `user_id` của dữ liệu đã đồng bộ | chưa bắt đầu | | SB-A1 | L | Màn này không có trong kit: dùng Impeccable `shape` trước khi plan (`CLAUDE.md`); ghi thêm hạng mục ở `wbs_FE.md` |
| SB-A3 | Nhiều máy cùng tài khoản: máy thứ hai đăng nhập thì kéo dữ liệu về; dữ liệu ẩn danh đã có trên máy đó được gộp hay bỏ theo spec auth | chưa bắt đầu | | SB-A2, SB-S8 | L | Đây là lúc sync giữa các máy của cùng một người bắt đầu có tác dụng |
| SB-A4 | Cấu hình Auth cho Android: redirect URL và deep link cho email, mẫu email, SMTP riêng nếu cần | chưa bắt đầu | chủ dự án | SB-A1 | S | Giả định: email dựng sẵn của Supabase có giới hạn gửi rất thấp, không đủ cho người dùng thật |
| SB-A5 | Xoá tài khoản trong app (Google Play đòi hỏi khi app có tạo tài khoản): RPC xoá toàn bộ dữ liệu của `auth.uid()` rồi xoá user | chưa bắt đầu | | SB-A2 | M | Hàm `SECURITY DEFINER` mới, pgTAP chứng minh không xoá được dữ liệu người khác |
| SB-A6 | Dọn user ẩn danh mồ côi: user ẩn danh không hoạt động quá N ngày thì xoá cùng dữ liệu, chạy theo lịch | chưa bắt đầu | | SB-A5 | S | Mỗi lần cài lại app tạo một user ẩn danh mới, nên dữ liệu cũ nằm lại mãi. Chủ dự án chốt N |

### D. Trải nghiệm sync trong app

| ID | Kết quả | Trạng thái | Người làm | Phụ thuộc | Cỡ | Bằng chứng / ghi chú |
|---|---|---|---|---|---|---|
| SB-U1 | Lỗi sync không còn im lặng: ghi lại lần sync gần nhất và lỗi gần nhất (mạng, đăng nhập, RPC bị từ chối), và hiện trạng thái đó ở một chỗ người dùng xem được | chưa bắt đầu | | — | M | Bài học 2026-09-28: bản release thiếu `INTERNET` làm `signInAnonymously` thất bại mà app không báo gì. Phần màn hình ghi thêm ở `wbs_FE.md` |
| SB-U2 | Báo cho người dùng rằng dữ liệu đang gắn với lần cài này (ẩn danh) và mời gắn email | chưa bắt đầu | | SB-A2 | S | — |

## Quyết định còn mở

| Hạng mục | Câu hỏi | Ảnh hưởng | Cần gì, từ ai |
|---|---|---|---|
| SB-S3 | Liên kết card–tag đi trên dây thế nào khi giao thức cần `entityId` là UUID mà `card_tags` có PK ghép: thêm cột `id` UUID, suy UUID tất định từ `(card_id, tag_id)`, hay gửi danh sách tag như một trường của card | Schema server, trigger outbox và adapter | Chốt trong SB-S1 |
| SB-S5 | Khoá của setting theo tài khoản trên server (một dòng mỗi `user_id`) và cách giữ `app_settings.id = 1` ở local | Schema server và adapter | Chốt trong SB-S1 |
| SB-S4 | Khi hai máy đổi scheduler của một deck gốc (tăng `generation`) rồi cùng đẩy review, review của generation cũ bị bỏ hay giữ làm lịch sử | Phát lại lịch SRS | Chốt trong SB-S1, đối chiếu spec sync §6 |
| SB-A1 | Cách đăng nhập và chính sách gộp dữ liệu ẩn danh khi đăng nhập trên máy thứ hai | Toàn bộ nhóm C | Chủ dự án |
| SB-O7 | Nơi lưu và thời hạn giữ bản sao lưu | Khôi phục khi mất dữ liệu | Chủ dự án |

## Bước tiếp theo

1. SB-O1, SB-O2, SB-O3 (chủ dự án, trên dashboard).
2. SB-O5 và SB-O6: gate pgTAP và kiểm lệch schema trước khi có migration thứ hai.
3. SB-U1: để lỗi sync lộ ra trước khi mở rộng thêm loại dữ liệu.
4. SB-S1 (spec) rồi SB-S2 → SB-S3 → SB-S4 → SB-S5, SB-S6, SB-S7.
5. SB-A1 có thể làm song song với nhóm B khi chủ dự án chọn cách đăng nhập; SB-A2
   trở đi sau SB-A1.

## Ngữ cảnh cập nhật

- **Tạo ngày 2026-09-28** theo yêu cầu của chủ dự án, sau khi sync deck chạy trên
  project thật. Nhận nhóm "Đồng bộ với server" từ `wbs_BE.md`: BE-E1 và BE-E8 chép
  sang mục "Đã xong"; BE-E2…BE-E6 (mô hình lệnh) được lập lại theo mô hình hàng thành
  SB-S1…SB-S6 và SB-A1…SB-A3; BE-E7 giữ trạng thái `hoãn` ở `wbs_BE.md`.
