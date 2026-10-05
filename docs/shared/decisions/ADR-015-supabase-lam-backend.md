---
id: ADR-015
title: Supabase làm backend, nghiệp vụ ở app
status: active
superseded_by:
---
## Bối cảnh

[ADR-013](ADR-013-dong-bo-voi-server-offline-first.md) chốt server là dữ liệu
chính thức và app offline-first.
[ADR-014](ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md) đi xa hơn: nó biến
`memox-api-services` (Spring Boot) thành backend nghiệp vụ, đẩy lệnh thay cho
hàng, và đặt SRS ở server bằng Java. Cái giá của hướng đó là phải host một JVM
cùng một Postgres, và phải cài mọi BR hai lần, bằng Dart và bằng Java.

Ngày 2026-09-28 chủ dự án chọn **Supabase toàn phần**, thay ADR-014. Gói Free
gồm Postgres 500 MB, 50.000 MAU, 5 GB egress và 2 project, và tự pause sau 1
tuần không hoạt động (đã kiểm với trang pricing ngày 2026-09-28). Supabase không
chạy Java, nên chủ dự án cũng chốt rằng nghiệp vụ và SRS trở về app. Thiết kế
chi tiết nằm ở
[`superpowers/specs/2026-09-28-supabase-backend-design.md`](../../superpowers/specs/2026-09-28-supabase-backend-design.md).

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Backend | Một project Supabase (Postgres và Auth). Logic sync là các hàm Postgres gọi qua RPC (`sync_push`, `sync_changes`). SQL nằm trong `supabase/migrations/` của repo |
| 2 | Nghiệp vụ | **App là nơi duy nhất cài BR và SRS**, như ADR-013 ban đầu. Server chỉ kiểm tính toàn vẹn: owner, bất biến của cây deck, CHECK và khoá ngoại, tombstone. Các dòng #1, #2, #4, #5 và #8 của ADR-013 có hiệu lực trở lại đúng như văn bản gốc; dòng #8 sau đó được [ADR-017](ADR-017-lich-srs-dong-bo-nhu-mot-dong.md) thay |
| 3 | Giao thức | Giữ nguyên wire format của spec sync (push theo hàng có idempotency theo `opId`, pull theo `server_version`). Chỉ phần hiện thực phía server đổi |
| 4 | Danh tính | Supabase Auth. App **đăng nhập ẩn danh** (`signInAnonymously`) khi có cấu hình Supabase mà chưa có session. Owner của mọi hàng là `auth.uid()`; server không bao giờ tin owner do client gửi. Login bằng email OTP và Google gắn vào cùng user ([auth spec 2026-09-30](../../superpowers/specs/2026-09-30-auth-design.md)); role nằm trong `public.profiles`, mọi hàng dữ liệu tham chiếu `auth.users` (migration `20261010000000`) |
| 5 | Ranh giới bảo mật | Mọi bảng bật RLS, không có policy, và `anon`, `authenticated` không có quyền nào trên bảng, nên client không đọc hay ghi bảng trực tiếp. Hàm RPC chạy `SECURITY DEFINER` với `search_path` cố định, lọc theo `auth.uid()`, và chỉ `authenticated` được `EXECUTE` |
| 6 | Test | pgTAP chạy bằng Supabase CLI (`supabase test db`) trên stack local. CI có job `supabase` |
| 7 | Flutter | `supabase_flutter`. `SupabaseSyncApi` triển khai `SyncApi`. Dio và Retrofit **giữ lại** cho một API REST về sau ([ADR-012](ADR-012-goi-api-bang-retrofit.md)). Coordinator, outbox, trigger và adapter không đổi |
| 8 | Spring Boot | `memox-api-services/` **đóng băng**: giữ trong repo làm tham chiếu, bỏ khỏi CI, không phát triển tiếp |
| 9 | Vận hành | Workflow GitHub chạy theo lịch hằng ngày gọi RPC `ping()`, để project Free không bị pause |

## Hệ quả

- ADR-014 chuyển sang `deprecated`. Spec
  [API authority](../../superpowers/specs/2026-09-27-api-authority-command-sync-design.md),
  spec và plan của command protocol, và `wbs_API.md` là lịch sử, không còn
  hiệu lực.
- Trong ADR-013, phần "PostgreSQL của `memox-api-services`" đọc là "Postgres của
  Supabase", và `CurrentUserProvider` với user dev đọc là `auth.uid()`.
- Dòng #4 thay dòng *Roles & permissions* của [ADR-001](ADR-001-quyet-dinh-nen-tang.md)
  (chủ dự án chốt 2026-10-05): có hai role `user` và `admin`; chỉ admin gọi được các
  RPC log và role ([`supabase/README.md`](../../../supabase/README.md#rules)).
- Nếu sau này làm web: web đọc và ghi qua cùng các RPC. Vì BR và SRS ở app,
  web phải tự cài chúng (TS), hoặc lúc đó một ADR mới đưa phần cần dùng chung
  lên Edge Function hay một service riêng.
- `memox-api-services/`, skill `spring-boot-mybatis-review` và các ECC skill
  Java/Spring được giữ để dùng khi có logic server thật: chia sẻ hoặc
  marketplace deck, tích hợp cần giữ secret, xử lý batch nặng, AI sinh thẻ.
- Chủ dự án tự tạo project Supabase, bật Anonymous sign-ins, chạy
  `supabase db push` và thêm secret cho workflow keep-alive.
- Phương án bị loại:
  - **Firebase:** offline cache của Firestore chồng chéo với Drift, NoSQL khó
    xử lý dữ liệu quan hệ, và cách tính tiền theo lượt đọc document bất lợi
    cho việc pull;
  - **tiếp tục Spring Boot (ADR-014):** phải host JVM và cài BR hai lần;
  - **port lệnh và SRS sang PL/pgSQL:** vẫn cài SRS hai lần, lần này bằng SQL,
    và phải viết lại toàn bộ lát cắt lệnh.
