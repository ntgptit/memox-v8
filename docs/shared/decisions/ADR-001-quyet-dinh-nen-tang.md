---
id: ADR-001
title: Quyết định nền tảng
status: active
superseded_by:
---
## Quyết định

| Decision | Choice | Consequence |
|---|---|---|
| Android | **có** — target duy nhất của bản release đầu | min SDK 23+ (yêu cầu của `flutter_secure_storage` khi cần sau này) |
| iOS | **hoãn** — sau khi Android ổn định về UX, Drift migration, test | Không cần macOS runner trong CI giai đoạn đầu → tiết kiệm runner minutes |
| Web | **chỉ dùng cho development** | Review UI và chạy E2E/visual regression bằng Flutter Web + Playwright. **Không phải production target** — không tối ưu responsive cho desktop, không phát hành |
| Desktop | không | ngoài phạm vi hiện tại |
| Data posture | **local-only, không network** | Drift là source of truth |
| Authentication | **chưa có auth** | Một local profile trên thiết bị |
| Roles & permissions | không, kể cả sau khi có auth | Chỉ một loại user khi backend xuất hiện |

> Các dòng *Data posture* và *Authentication*, cùng việc Drift là source of truth,
> đã được thay bởi [ADR-013](ADR-013-dong-bo-voi-server-offline-first.md) (2026-09-27):
> server là dữ liệu chính thức, app offline-first và tự đồng bộ.
>
> Dòng *Roles & permissions* đã được thay bởi
> [ADR-015](ADR-015-supabase-lam-backend.md) (chủ dự án chốt 2026-10-05): có hai role
> `user` và `admin`, nằm trong `public.profiles`; admin xem log và gán role.

## Lý do và hệ quả

Hệ quả quan trọng của việc Web là dev-only: nó là **công cụ test**, không phải
target. Nghĩa là không đánh đổi thiết kế Android để Web đẹp hơn, nhưng cũng
không được dùng plugin chặn Web build — nếu Web không build được thì mất luôn
kênh E2E.

## Nguồn

Các quyết định nền tảng trên nằm ở [`superpowers/specs/2026-09-21-memox-v8-foundation-design.md`](../../superpowers/specs/2026-09-21-memox-v8-foundation-design.md) §3.
