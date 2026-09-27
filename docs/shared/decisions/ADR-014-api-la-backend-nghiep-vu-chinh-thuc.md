---
id: ADR-014
title: API là backend nghiệp vụ chính thức, sync đẩy lệnh và kéo trạng thái
status: active
superseded_by:
---
## Bối cảnh

[ADR-013](ADR-013-dong-bo-voi-server-offline-first.md) chốt server là dữ liệu
chính thức. Nhưng trong ADR đó, logic nghiệp vụ chỉ nằm ở app: server lưu hàng,
kiểm tính toàn vẹn và không cài đặt SRS. Ngày 2026-09-27, chủ dự án chốt mục tiêu
dài hạn: sau này có thể có web, iOS hay desktop, và các client đó phải dùng được
mọi nghiệp vụ mà Android có. Nếu API chỉ là "sync server cho Android" thì web
không thể ngang tính năng với Android. Thiết kế chi tiết ở
[`superpowers/specs/2026-09-27-api-authority-command-sync-design.md`](../../superpowers/specs/2026-09-27-api-authority-command-sync-design.md).

## Quyết định

| # | Chủ đề | Quyết định |
|---|---|---|
| 1 | Vai trò của API | `memox-api-services` là **backend nghiệp vụ chính thức** của sản phẩm. Mỗi nghiệp vụ có đúng một service ở server. REST (cho client khác) và lệnh sync (của Android) là hai lối vào của cùng service đó. Thay dòng #1 của ADR-013 ở phần "nguồn chính thức": server là chuẩn **cả về dữ liệu lẫn nghiệp vụ**. Drift vẫn là kho vận hành bền vững của Android, và là bản cài đặt offline của cùng các BR đó |
| 2 | Phạm vi của API | Nếu một client khác Android cần thực hiện một nghiệp vụ, và kết quả của nó phải tồn tại hoặc dùng chung giữa các thiết bị, thì API hỗ trợ nghiệp vụ đó. Trạng thái UI, hiển thị, điều hướng và phiên học đang dở ở lại client. API là hợp đồng nghiệp vụ, không phải bộ điều khiển UI từ xa, và không sao chép cấu trúc của Drift |
| 3 | Push | Thay dòng #2 và phần push của dòng #4 của ADR-013. Outbox là một hàng FIFO. Thao tác có luật nghiệp vụ được đẩy lên dưới dạng **lệnh** (ví dụ `MOVE_DECK`, `RECORD_REVIEW`), không gộp, và server chạy lại qua service. Dữ liệu thuần (nội dung card, setting) được đẩy dưới dạng **patch theo nhóm trường**, có gộp. Lệnh bị từ chối trả bản của server cho mọi entity mà nó đã đổi ở local, và không chặn các lệnh sau |
| 4 | Pull | Giữ nguyên phần pull của dòng #4 của ADR-013: một dòng thay đổi trạng thái theo `server_version`. Client ghi cả lượt pull trong một transaction, và kiểm khoá ngoại lúc commit |
| 5 | Conflict | Thay dòng #5 của ADR-013. Luật "thao tác server nhận sau thắng" chỉ áp dụng cho patch. Phần do lệnh sở hữu (vị trí trong cây, xoá, Trash, danh tính tag, liên kết card–tag) do service kiểm theo trạng thái hiện tại của server. Tên tag là duy nhất trong mỗi user; bên tới sau bị từ chối và tự gộp ở client |
| 6 | SRS | Thay dòng #8 của ADR-013. **Server là chuẩn của SRS**: Java cài `eight_box` và `sm2` theo `scheduler_type` và `scheduler_version`. Android giữ bản Dart để chạy offline, và khi hai kết quả khác nhau thì server thắng. `card_schedule` là trạng thái phái sinh, không bao giờ là đầu vào của sync. Server lưu mọi review và dựng lại lịch ôn từ lịch sử của generation hiện tại, xếp theo `(answered_at, id)`. Review của generation cũ bị từ chối (BR-SRS-026). Một bộ dữ liệu test dùng chung được cả test Dart lẫn test Java chạy, và CI fail khi hai bên lệch nhau |

Các dòng #3, #6, #7, #9, #10 của ADR-013 giữ nguyên.

## Hệ quả

- Logic nghiệp vụ nằm ở hai nơi, Dart và Java. Để chúng không lệch nhau:
  - BR vẫn là nguồn luật duy nhất, và mọi service ở server dẫn BR của nó;
  - riêng SRS có bộ dữ liệu test dùng chung.
- Hạ tầng của lát cắt deck ở server ([PR #110](https://github.com/ntgptit/memox-v8/pull/110))
  và ở app ([PR #114](https://github.com/ntgptit/memox-v8/pull/114)) được giữ: idempotency theo `opId`, gom lô, `server_version`, cursor, tuần tự theo
  user, `CurrentUserProvider`, `rejected` kèm `current`. `SyncEntityHandler` phát
  triển thành handler theo lệnh. Upsert hàng của deck được thay bằng các lệnh deck.
- `wbs_API.md` xếp hạng mục theo nghiệp vụ; phía app của sync ở `wbs_BE.md`.
- ADR này không đổi các dòng nền tảng của
  [ADR-001](ADR-001-quyet-dinh-nen-tang.md). Nó chỉ bảo đảm rằng một client khác
  làm được nếu sau này sản phẩm quyết định làm.
- Phương án bị loại:
  - **giữ server chỉ kiểm toàn vẹn (ADR-013):** web phải tự mang toàn bộ logic
    nghiệp vụ, kể cả SRS, bằng JS/TS;
  - **đẩy mọi thứ thành lệnh:** dữ liệu thuần không có ý định nào để kiểm, mà
    phải thêm nhiều loại lệnh;
  - **online-first (gọi API trước, local khi mất mạng):** vẫn phải có đủ cơ chế
    sync cho phần offline, cộng thêm hai đường ghi cho mỗi thao tác.
