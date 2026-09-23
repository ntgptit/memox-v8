# deck — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: Kịch bản IT — Khởi động, điều hướng và tiếp tục

## IT-NAV-001 — Cold start mở đúng danh sách Deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** App đã cài; không có process MemoX đang chạy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở MemoX từ launcher | App khởi động thành công, không hiện màn đỏ hoặc chi tiết kỹ thuật |
| 2 | Quan sát bottom navigation | Tab Thư viện đang được chọn |
| 3 | Quan sát nội dung | Hiện danh sách Deck; nếu chưa có dữ liệu thì hiện empty state kèm hành động tạo deck |

## IT-NAV-003 — Back đi lên đúng một cấp trong cây

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có cây ba cấp `D-EB > D-BRANCH > D-LEAF`; đang mở `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bấm Back của hệ thống | Quay về `D-BRANCH`, không nhảy thẳng về root list |
| 2 | Bấm Back lần nữa | Quay về `D-EB` |
| 3 | Bấm Back lần nữa | Quay về danh sách root deck |

## IT-NAV-004 — Breadcrumb quay về ancestor đã chọn

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây ba cấp `D-EB > D-BRANCH > D-LEAF`; đang mở `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát breadcrumb | Hiện đủ đường đi từ Root tới `D-LEAF`, đúng thứ tự |
| 2 | Chạm `D-EB` trên breadcrumb | Mở nội dung của `D-EB` |
| 3 | Mở lại `D-LEAF`, chạm Root | Quay về danh sách root deck |

## IT-NAV-006 — Hành trình Deck/Card xuyên suốt và còn dữ liệu sau restart

> **Tách thành** — `IT-NAV-006` (`HOST-FLOW`) · `IT-PLAT-002` (`DEVICE-E2E`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** App ở trạng thái trống; có thể đóng hẳn và mở lại app.
- **Liên kết:** UC-DECK-001, UC-DECK-002, UC-CARD-001, UC-DECK-004.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tạo root `D-EB` và chọn Eight Box | Root deck xuất hiện trong danh sách |
| 2 | Mở `D-EB`, tạo `D-BRANCH`, rồi mở `D-BRANCH` | Cây hiển thị đúng quan hệ cha-con |
| 3 | Trong `D-BRANCH`, tạo `D-LEAF`; trong `D-LEAF`, chọn tạo card | Mở editor card và deck leaf được định hướng thành deck chứa card khi card được lưu thành công |
| 4 | Tạo `C-001`, sau đó mở card và đổi nghĩa thành `rời bỏ` | Danh sách hiện nội dung đã sửa |
| 5 | Quay về root list, đóng hẳn app rồi mở lại | `D-EB` vẫn tồn tại |
| 6 | Đi lại tới `D-LEAF` | `C-001` vẫn tồn tại với nghĩa `rời bỏ` |
| 7 | Xoá `C-001` và xác nhận | Card biến mất; deck card trở thành empty state |
| 8 | Xoá lần lượt nhánh vừa tạo và xác nhận | Các deck bị xoá không còn xuất hiện; app vẫn hoạt động bình thường |

## Nhóm: IT scenarios — Vòng đời root deck

## IT-DECK-001 — Tạo root deck dùng Eight Box

> **Tách thành** — `IT-DECK-001` (`HOST-WIDGET`) · `IT-DECK-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở root deck list.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm tạo deck | Form tạo root deck mở, có ô tên và lựa chọn chế độ học |
| 2 | Nhập `Giao tiếp hằng ngày`, chọn Eight Box | Lựa chọn được hiển thị rõ và có giải thích việc chế độ sẽ bị khoá sau khi bắt đầu học |
| 3 | Chạm Tạo/Lưu | Form đóng; deck mới xuất hiện với tên và chế độ Eight Box |
| 4 | Đóng hẳn rồi mở lại app | Deck vẫn còn |

## IT-DECK-002 — Tạo root deck dùng SM-2 và cho phép trùng tên

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đã có một root deck tên `IELTS 2026`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tạo root deck mới, cũng nhập `IELTS 2026` | Form chấp nhận tên trùng |
| 2 | Chọn SM-2 và xác nhận | Root deck thứ hai được tạo với chế độ SM-2 |
| 3 | Quan sát danh sách | Có hai deck cùng tên; app không ghi đè deck cũ |

## IT-DECK-003 — Không tạo deck khi thiếu dữ liệu bắt buộc

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang mở form tạo root deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Để trống tên, chọn Eight Box rồi gửi | Lỗi hiển thị ngay tại ô tên; form vẫn mở; không tạo deck |
| 2 | Nhập chỉ khoảng trắng rồi gửi | Vẫn báo tên không hợp lệ; không tạo deck |
| 3 | Nhập tên hợp lệ nhưng bỏ chọn chế độ học rồi gửi | Lỗi hiển thị tại khu vực chọn chế độ; không tạo deck |
| 4 | Chọn chế độ và gửi lại | Deck được tạo đúng một lần |

## IT-DECK-004 — Giới hạn tên và bảo toàn nội dung khi validation lỗi

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang mở form tạo root deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập tên dài đúng 200 ký tự và chọn scheduler | Có thể lưu deck |
| 2 | Mở form tạo deck khác, thử nhập ký tự thứ 201 | Giá trị được lưu MUST không vượt 200 ký tự: ký tự 201 bị chặn, hoặc form giữ nguyên và báo lỗi inline cho tới khi người dùng sửa |
| 3 | Gửi form không hợp lệ | Tên và scheduler người dùng đã nhập vẫn còn để sửa |

## IT-DECK-005 — Huỷ form có và không có thay đổi

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở root deck list.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở form tạo deck rồi đóng ngay khi chưa nhập gì | Form đóng, không hỏi bỏ thay đổi, không tạo deck |
| 2 | Mở lại, nhập tên rồi chạm Huỷ/đóng | Hiện xác nhận bỏ nội dung đã nhập |
| 3 | Chọn tiếp tục chỉnh sửa | Quay lại form và tên đã nhập còn nguyên |
| 4 | Đóng lần nữa và xác nhận bỏ | Form đóng; không có deck mới |

## IT-DECK-006 — Đổi tên root deck

> **Tách thành** — `IT-DECK-006` (`HOST-WIDGET`) · `IT-DECK-006F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `D-EB`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu của `D-EB`, chọn Đổi tên | Form hiện tên hiện tại |
| 2 | Đổi thành `Giao tiếp công việc` và lưu | Tên mới xuất hiện ngay trong danh sách |
| 3 | Mở deck | App bar và breadcrumb dùng tên mới |
| 4 | Restart app | Tên mới vẫn còn; cấu trúc con và card không bị thay đổi |

## IT-DECK-007 — Huỷ xoá root deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-EB` có ít nhất hai deck con và ba card trong toàn cây.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu `D-EB`, chọn Xoá | Hộp xác nhận nêu đúng tên deck, số deck con và số card sẽ mất |
| 2 | Chọn Huỷ | Hộp thoại đóng |
| 3 | Mở lại `D-EB` và đi tới các card | Deck, descendants và card vẫn còn nguyên |

## IT-DECK-008 — Xác nhận xoá root deck và toàn bộ cây

> **Tách thành** — `IT-DECK-008` (`HOST-WIDGET`) · `IT-DECK-008F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Như IT-DECK-007 và dữ liệu này không dùng chung với scenario khác.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Xoá trên `D-EB` | Hiện xác nhận impact |
| 2 | Xác nhận xoá | Quay về root deck list; `D-EB` biến mất |
| 3 | Restart app | `D-EB` không xuất hiện lại |
| 4 | Dùng search deck tìm tên các descendant cũ | Không tìm thấy descendant nào của cây đã xoá |

## Nhóm: IT scenarios — Cây deck, loại nội dung và di chuyển

## IT-TREE-001 — Root deck chỉ cho tạo deck con

> **Tách thành** — `IT-TREE-001` (`HOST-WIDGET`) · `IT-TREE-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có root `D-EB`, chưa có child.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `D-EB`, chạm hành động tạo | Chỉ có luồng tạo deck con; không có lựa chọn tạo card trực tiếp |
| 2 | Tạo deck `Vocabulary` | Deck con xuất hiện bên trong `D-EB`; form không yêu cầu chọn scheduler riêng |

## IT-TREE-002 — Deck con chưa định loại cho phép chọn card hoặc deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-LEAF` vừa được tạo và chưa có nội dung.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `D-LEAF`, chạm Tạo | Hiện hai lựa chọn: tạo card và tạo deck |
| 2 | Đóng sheet mà chưa chọn/lưu | Không tạo nội dung; khi mở lại vẫn còn đủ hai lựa chọn |

## IT-TREE-003 — Card đầu tiên cố định deck thành loại card

> **Tách thành** — `IT-TREE-003` (`HOST-WIDGET`) · `IT-TREE-003F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck con `D-LEAF` đang rỗng và chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Tạo, chọn Card | Mở editor card |
| 2 | Nhập `C-001` và lưu | Mở/hiện danh sách card của `D-LEAF`, có `C-001` |
| 3 | Quan sát các hành động tạo | Chỉ còn tạo card; không có đường tạo deck con trong `D-LEAF` |
| 4 | Rời màn hình rồi mở lại `D-LEAF` | Tự đi vào danh sách card, không hiện danh sách sub-deck rỗng |

## IT-TREE-004 — Deck con đầu tiên cố định deck thành loại deck

> **Tách thành** — `IT-TREE-004` (`HOST-WIDGET`) · `IT-TREE-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck con `Grammar` đang rỗng và chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Tạo, chọn Deck | Mở form tạo sub-deck |
| 2 | Tạo child `Tenses` | `Tenses` xuất hiện trong `Grammar` |
| 3 | Chạm Tạo lần nữa | Chỉ có luồng tạo deck; không còn lựa chọn tạo card |

## IT-TREE-005 — Validation thất bại không làm deck bị khoá loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck `Unclassified` chưa định loại.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn tạo Card, để trống mặt trước và gửi | Hiện lỗi inline; không tạo card |
| 2 | Đóng editor, mở lại hành động Tạo của `Unclassified` | Vẫn có cả Tạo card và Tạo deck |
| 3 | Chọn tạo Deck, để tên trống và gửi | Hiện lỗi inline; không tạo deck |
| 4 | Đóng form và mở lại hành động Tạo | Vẫn có đủ hai lựa chọn |

## IT-TREE-006 — Xoá child cuối đưa sub-deck về chưa định loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** Deck con `Grammar` loại deck chỉ có một child `Tenses`.
- **Liên kết:** UC-DECK-004 A3, BR-DECK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá `Tenses` và xác nhận | `Grammar` trở thành empty state và `content_type` về `unset` trong cùng transaction |
| 2 | Chạm Tạo | Có cả Tạo card và Tạo deck — deck đã mở khoá loại |
| 3 | Lặp lại với một root rỗng | Root vẫn chỉ cho tạo deck: root bất biến `deck` (BR-DECK-004) |

## IT-TREE-007 — Di chuyển child cuối đi cũng mở khoá loại của deck nguồn

> Di chuyển là cách thứ hai (ngoài xoá) làm deck mất phần tử con cuối; BR-DECK-015
> áp dụng như nhau: `content_type` quay về `unset` trong cùng transaction.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-BRANCH` chỉ có `D-LEAF`; tồn tại một deck đích khác đang chưa định loại.
- **Liên kết:** UC-DECK-005, BR-DECK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Di chuyển `D-LEAF` sang deck đích | `D-LEAF` xuất hiện ở đích cùng toàn bộ card |
| 2 | Mở deck đích | Đích đã thành loại deck: chỉ cho tạo deck con |
| 3 | Mở `D-BRANCH` | Đã trở về chưa định loại: có cả Tạo card và Tạo deck |
| 4 | Lặp lại khi `D-BRANCH` còn một child khác | `D-BRANCH` giữ nguyên loại deck |

## IT-TREE-008 — Deck còn nội dung giữ nguyên loại

> Ràng buộc "còn nội dung thì giữ loại" là hệ quả của BR-DECK-015, không phải của
> một hành động reset ẩn riêng.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-BRANCH` đang chứa `D-LEAF` và một deck con thứ hai.
- **Liên kết:** UC-DECK-004 A3, BR-DECK-015, invariant Q29.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá `D-LEAF`, xác nhận | `D-BRANCH` vẫn là loại deck; nút Tạo vẫn chỉ cho tạo deck con |
| 2 | Xoá nốt deck con còn lại | Lúc này `D-BRANCH` mới trở về chưa định loại |
| 3 | Chạm Tạo | Có cả Tạo card và Tạo deck |

## IT-TREE-009 — Di chuyển sub-deck tới đích hợp lệ trong cùng cây

> **Tách thành** — `IT-TREE-009` (`HOST-WIDGET`) · `IT-TREE-009F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-EB` có hai branch `Vocabulary` và `Grammar`; `D-LEAF` nằm trong `Vocabulary`; `Grammar` có thể chứa deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở menu `D-LEAF`, chọn Di chuyển | Sheet hiển thị các đích và trạng thái có thể/không thể chọn |
| 2 | Chọn `Grammar` | Sheet đóng; `D-LEAF` không còn trong `Vocabulary` |
| 3 | Mở `Grammar` | `D-LEAF` xuất hiện với toàn bộ card cũ còn nguyên |

## IT-TREE-010 — Không cho di chuyển vào chính nó hoặc descendant

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `Vocabulary > Academic words > Level 1`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Di chuyển trên `Vocabulary` | `Vocabulary` và `Academic words`/`Level 1` không xuất hiện như đích có thể chọn |
| 2 | Quan sát sheet | Sheet **ẩn** đích không hợp lệ thay vì liệt kê kèm lý do; khi mọi ứng viên đều bị loại nó nói thẳng `Nowhere to move this` — cycle bất khả thi và người dùng được giải thích |
| 3 | Đóng sheet | Cây giữ nguyên, không có cycle |

## IT-TREE-011 — Không cho di chuyển deck vào deck chứa card

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có source sub-deck và `D-LEAF` đã chứa card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Di chuyển trên source | `D-LEAF` vẫn hiện để người dùng hiểu phạm vi nhưng ở trạng thái không thể chọn, kèm lý do deck chỉ chứa card |
| 2 | Quan sát lý do | Người dùng hiểu đích chỉ chứa card |
| 3 | Đóng sheet | Source vẫn ở vị trí cũ; card trong `D-LEAF` không đổi |

## IT-TREE-012 — Không cho move giữa hai root khác scheduler

- **Ưu tiên:** P0
- **Tiền điều kiện:** Source nằm dưới `D-EB`; target nằm dưới `D-SM2` và có thể chứa deck.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Di chuyển trên source | Target thuộc `D-SM2` không thể chọn |
| 2 | Quan sát lý do | UI giải thích hai cây không tương thích về chế độ/tiến độ học; không âm thầm chuyển đổi |
| 3 | Đóng sheet và kiểm tra hai cây | Source và target đều giữ nguyên |

## IT-TREE-013 — Chặn tạo hoặc move vượt quá 10 cấp

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có cây hợp lệ đủ 10 cấp, root là cấp 1.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tại deck cấp 10, thử tạo deck con | Không tạo cấp 11; có user-facing copy nói đã đạt giới hạn độ sâu và không chứa SQL/exception/ID kỹ thuật |
| 2 | Tạo card trong deck cấp 10 đang chưa định loại | Card vẫn có thể được tạo vì không làm cây sâu thêm |
| 3 | Với một subtree có chiều cao làm đích vượt cấp 10, thử move subtree vào đích sâu | Đích bị từ chối; subtree vẫn ở vị trí cũ |

## Nhóm: IT scenarios — Khám phá deck và theo dõi tiến độ

## IT-DISC-001 — Deck tile trình bày đủ thông tin ra quyết định

> **Tách thành** — `IT-DISC-001` (`HOST-WIDGET`) · `IT-DISC-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp, clock được pin tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở root deck list | Tile `Due library` hiện Eight Box, 5 card toàn cây, **số New và số Due là hai con số tách biệt** (BR-STUDY-046) — 2 card đến hạn — và 2 sub-deck trực tiếp |
| 2 | Quan sát deck có card đến hạn | Trạng thái đến hạn được truyền đạt bằng chữ và biểu tượng, không chỉ bằng màu |
| 3 | Mở một child level | Tile child dùng cùng cách trình bày, số liệu đúng với subtree đó |

## IT-DISC-002 — Không có card đến hạn là trạng thái bình thường

- **Ưu tiên:** P0
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp; mở level `No due group` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát tile `Future only` | Tile cho biết 0 card đến hạn bằng thông điệp trung tính |
| 2 | Quan sát màn hình | Không hiện error state và không yêu cầu retry |

## IT-DISC-003 — Lọc chỉ các deck đang có card đến hạn

> **Tách thành** — `IT-DISC-003` (`HOST-WIDGET`) · `IT-DISC-003F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp; đang ở level `Due library` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn bộ lọc Đến hạn | Chỉ còn `Mixed due`; `No due group` bị loại khỏi kết quả |
| 2 | Mở một deck trong kết quả rồi Back | Quay lại level; bộ lọc vẫn phản ánh đúng dữ liệu hiện tại |
| 3 | Chọn Hiện tất cả | Tất cả deck quay lại |

## IT-DISC-004 — Bộ lọc không có kết quả có lối quay lại

- **Ưu tiên:** P1
- **Tiền điều kiện:** Fixture `S-DUE` đã được nạp; đang ở level `No due group` tại `T0`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn bộ lọc Đến hạn | Hiện empty state “không có gì đến hạn”, không phải lỗi |
| 2 | Chạm hành động Hiện tất cả | Danh sách deck được khôi phục |

## IT-DISC-005 — Sắp xếp theo tên và gần đây

> **Tách thành** — `IT-DISC-005` (`HOST-WIDGET`) · `IT-DISC-005F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P1
- **Tiền điều kiện:** Có ba deck cùng cấp: `beta`, `Alpha`, `gamma`, với thời điểm tạo/cập nhật khác nhau.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn sắp xếp theo tên | Thứ tự là `Alpha`, `beta`, `gamma`, không phân biệt hoa thường |
| 2 | Chọn sắp xếp gần đây | Thứ tự là `gamma`, `Alpha`, `beta`, khớp thứ tự tạo mới nhất trước |
| 3 | Đổi bộ lọc rồi quay về tất cả | Kiểu sắp xếp đang chọn vẫn được áp dụng |

## IT-DISC-006 — Tìm deck trong đúng phạm vi subtree

> **Tách thành** — `IT-DISC-006` (`HOST-WIDGET`) · `IT-DISC-006F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-EB > Vocabulary > Academic words`; `D-SM2` có deck khác cũng chứa chữ `Academic`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở trong `D-EB`, nhập `Academic` vào ô tìm kiếm | Kết quả có `Academic words` trong subtree `D-EB`, kèm đường đi đủ để phân biệt vị trí |
| 2 | Quan sát kết quả | Không lẫn deck cùng tên/từ khoá nằm dưới `D-SM2` |
| 3 | Chạm kết quả | Điều hướng tới đúng deck được chọn |
| 4 | Xoá nội dung tìm kiếm | Quay về danh sách level bình thường |

## IT-DISC-007 — Tìm kiếm không khớp có thông tin phạm vi và lối xoá

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở một level có dữ liệu.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập một chuỗi không khớp deck nào | Hiện trạng thái không có kết quả, nêu phạm vi đang tìm |
| 2 | Chạm xoá tìm kiếm | Danh sách và summary của level trở lại |

## IT-DISC-008 — Summary và danh sách tự cập nhật sau thay đổi nội dung

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `D-LEAF` và có thể quan sát tile/summary của ancestor.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi lại tổng card, New và Due trên ancestor | Có baseline ba số rõ ràng |
| 2 | Tạo một card mới trong `D-LEAF`, rồi Back về ancestor | Tổng và New tăng đúng 1; Due không đổi vì card chưa học; không cần pull-to-refresh/restart |
| 3 | Xoá card vừa tạo, quay lại ancestor | Tổng và New giảm đúng 1 về baseline; Due vẫn không đổi |
| 4 | Khi summary panel đang hiện, chạm ẩn rồi gọi hiện lại | Panel ẩn/hiện theo hành động người dùng; số liệu không đổi sai |

## Nhóm: Kịch bản IT — Điểm vào chức năng học và tùy chọn

## IT-STUDY-009 — Ghi đè ở bộ thẻ gốc thắng mặc định và bộ thẻ con không có cấu hình riêng

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-21`; mặc định toàn ứng dụng là giới hạn 20/`Created`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đặt giá trị ghi đè của bộ thẻ gốc `Limit library` thành giới hạn 8/`Random` | Bộ thẻ gốc hiển thị giá trị riêng đã lưu |
| 2 | Mở tùy chọn từ bộ thẻ con `Twenty one` | Hiện giá trị hiệu lực của bộ thẻ gốc; không cho tạo giá trị ghi đè riêng cho bộ thẻ con |
| 3 | Bắt đầu Học mới từ bộ thẻ con | Phiên chốt giới hạn 8/`Random` |
| 4 | Xóa giá trị ghi đè ở bộ thẻ gốc | Lần mở phiên kế tiếp quay về 20/`Created`; phiên đang chạy không đổi |

## Nhóm: Kịch bản ranh giới nền tảng

## IT-PLAT-001 — Khởi động nguội bản đã cài đặt vào đúng danh sách bộ thẻ

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản `development` đã cài, dữ liệu ứng dụng đã xoá, không có tiến trình MemoX nào đang chạy.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở MemoX từ launcher của hệ điều hành | App khởi động, không màn đỏ, không chi tiết kỹ thuật |
| 2 | Quan sát màn hình đầu tiên | Danh sách bộ thẻ, tab Bộ thẻ đang chọn |
| 3 | Quan sát khi chưa có dữ liệu | Empty state kèm hành động tạo bộ thẻ |

Dẫn xuất từ `IT-NAV-001`. Ranh giới: bootstrap thật của engine, đường dẫn
database do nền tảng cấp, và asset bundle của bản đã cài — không thứ nào
trong ba tồn tại khi `flutter test` dựng cây widget trong tiến trình host.

## IT-PLAT-002 — Dữ liệu đã ghi sống sót qua một lần chết tiến trình thật

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản `development` đã cài, dữ liệu ứng dụng đã xoá.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Tạo một bộ thẻ gốc và một thẻ trong đó | Cả hai hiện trong danh sách |
| 2 | Bật cờ cho thẻ và đổi một tùy chọn toàn ứng dụng | Cờ và tùy chọn nhận thay đổi |
| 3 | Đóng hẳn tiến trình từ trình quản lý tác vụ | App thoát hoàn toàn |
| 4 | Mở lại app | Bộ thẻ, thẻ, cờ và tùy chọn đều còn nguyên |

Dẫn xuất từ `IT-NAV-006`, `IT-DECK-001`, `IT-CARD-002`, `IT-CARD-008`,
`IT-CARD-010`, `IT-ORG-004`, `IT-STUDY-008`. Ranh giới: file database thật
trên bộ nhớ thiết bị, ghi bởi một tiến trình và đọc bởi một tiến trình khác.
**Nội dung của từng luật không kiểm ở đây** — chúng đã có ở `HOST-FLOW`; ở
đây chỉ kiểm rằng byte đã chạm đĩa.

## IT-PLAT-004 — Deep link đi từ hệ điều hành vào đúng màn hình

- **Ưu tiên:** P1
- **Tiền điều kiện:** Một bộ thẻ đang tồn tại; app đã đóng hẳn.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Từ hệ điều hành mở deep link tới bộ thẻ đó | App mở đúng màn bộ thẻ ấy |
| 2 | Bấm back | Có lối ra hợp lệ, không kẹt màn trắng |
| 3 | Lặp lại với một link không hợp lệ | Màn 404 kèm lối phục hồi |

Dẫn xuất từ `IT-NAV-005`. Ranh giới: intent filter của Android và việc hệ
điều hành bàn giao URL. Bảng route và màn 404 đã kiểm ở `HOST-WIDGET`.

## IT-PLAT-006 — Smoke trước phát hành: cài, mở, tạo, học

- **Ưu tiên:** P0
- **Tiền điều kiện:** Bản release đã cài lên thiết bị sạch.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở app | Khởi động thành công |
| 2 | Tạo một bộ thẻ gốc và một thẻ | Cả hai hiện ra |
| 3 | Bắt đầu học và hoàn tất một thẻ | Phiên chạy hết và có tổng kết |
| 4 | Đóng và mở lại | Tiến độ còn nguyên |

Kịch bản duy nhất trong danh mục cố tình đi qua nhiều lớp. Nó không tồn tại
để bắt lỗi nghiệp vụ — nó tồn tại để bắt một bản dựng **không chạy được**:
thiếu asset, sai flavor, hỏng chữ ký, R8 cắt nhầm, migration không chạy trên
máy thật.
