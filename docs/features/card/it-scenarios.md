# card — kịch bản IT

Kịch bản kiểm thử tích hợp truy vết về feature này (theo cột "Truy vết" của [danh mục](../../shared/testing/scenario-catalog.md)). Hướng dẫn thực thi, mã chuẩn bị `SETUP-*` và hồ sơ thực thi nằm ở [`shared/testing/`](../../shared/testing/README.md).

## Nhóm: IT scenarios — Cây deck, loại nội dung và di chuyển

## IT-TREE-014 — Xoá card cuối mở khoá lại loại nội dung của deck

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một deck con loại card chỉ còn đúng một card.
- **Liên kết:** UC-CARD-001 A2, BR-DECK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá card cuối và xác nhận | Người dùng về màn hình deck, không mắc kẹt ở card list rỗng |
| 2 | Quan sát deck | Deck ở trạng thái chưa định loại; không cần thao tác quản trị nào |
| 3 | Chạm Tạo | Có cả Tạo card và Tạo deck |

## Nhóm: IT scenarios — Vòng đời card

## IT-CARD-001 — Empty card deck có hành động thêm card đầu tiên

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có deck loại card nhưng chưa có card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở deck | Hiện đúng tên deck, breadcrumb và empty state cho card |
| 2 | Chạm hành động thêm card trong empty state | Mở editor tạo card; focus ở mặt trước |

## IT-CARD-002 — Tạo card với hai mặt bắt buộc

> **Tách thành** — `IT-CARD-002` (`HOST-WIDGET`) · `IT-CARD-002F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở editor tạo card trong `D-LEAF`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập front `abandon`, back `từ bỏ` | Hai giá trị hiển thị đúng |
| 2 | Chạm Lưu | Quay về danh sách; card mới xuất hiện ở đầu |
| 3 | Quan sát card | Hiện đúng front/back và state New; card chưa có due badge vì chưa hoàn tất chuỗi học mới (BR-CARD-007, BR-STUDY-053) |
| 4 | Restart app và mở lại deck | Card vẫn tồn tại |

## IT-CARD-003 — Validation mặt trước và mặt sau

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Để cả hai mặt trống và chạm Lưu | Mỗi ô bắt buộc hiển thị lỗi inline; editor không đóng |
| 2 | Nhập chỉ khoảng trắng ở front, back hợp lệ | Front vẫn bị coi là rỗng; không tạo card |
| 3 | Nhập front hợp lệ, back chỉ khoảng trắng | Back báo lỗi; dữ liệu front còn nguyên |
| 4 | Sửa cả hai hợp lệ và lưu | Tạo đúng một card |

## IT-CARD-004 — Giới hạn độ dài nội dung card

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập front đúng 60 ký tự và back đúng 240 ký tự | Có thể lưu |
| 2 | Mở editor mới và thử vượt 60 ký tự ở front | Giá trị được lưu không vượt 60 ký tự: ký tự dư bị chặn, hoặc form giữ nguyên và báo lỗi inline tại front |
| 3 | Thử vượt 240 ký tự ở back | Giá trị được lưu không vượt 240 ký tự: ký tự dư bị chặn, hoặc form giữ nguyên và báo lỗi inline tại back |

## IT-CARD-005 — Tạo card có thông tin bổ sung

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở phần Thông tin thêm | Hiện các ô ví dụ, gợi ý, phiên âm |
| 2 | Nhập đầy đủ dữ liệu `C-001` và lưu | Card được tạo |
| 3 | Mở card để sửa | Phần thông tin thêm tự mở và hiện đúng dữ liệu đã lưu |
| 4 | Xoá nội dung một trường tùy chọn rồi lưu | Lần mở tiếp theo trường đó rỗng; các trường khác giữ nguyên |

## IT-CARD-006 — Giới hạn 240 ký tự cho từng trường bổ sung

- **Ưu tiên:** P1
- **Tiền điều kiện:** Đang ở editor và đã mở phần Thông tin thêm.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập đúng 240 ký tự vào ví dụ, gợi ý và phiên âm | Form chấp nhận |
| 2 | Thử nhập ký tự thứ 241 vào từng ô | Không trường nào lưu quá 240 ký tự: ký tự dư bị chặn, hoặc form giữ nguyên và báo lỗi inline đúng ô |
| 3 | Sửa về hợp lệ và lưu | Card được lưu, không mất front/back |

## IT-CARD-007 — Lưu và thêm card khác

- **Ưu tiên:** P0
- **Tiền điều kiện:** Đang ở editor tạo card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập `C-001`, chạm Lưu và thêm | Card được lưu nhưng editor vẫn mở |
| 2 | Quan sát form | Tất cả ô được xoá và focus trở về front |
| 3 | Nhập `C-002`, chạm Lưu | Quay về danh sách |
| 4 | Quan sát danh sách | Có đúng hai card mới, card tạo sau ở trên; không có dòng trùng |

## IT-CARD-008 — Sửa card và giữ vị trí quản lý ổn định

> **Tách thành** — `IT-CARD-008` (`HOST-WIDGET`) · `IT-CARD-008F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có ít nhất ba card; `C-001` không phải card mới nhất.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm `C-001` | Editor sửa được prefill đúng front/back và dữ liệu tùy chọn |
| 2 | Đổi back thành `rời bỏ`, lưu | Quay về danh sách và thấy nội dung mới |
| 3 | Quan sát thứ tự | Card không nhảy lên đầu chỉ vì vừa sửa |
| 4 | Restart app | Nội dung sửa vẫn còn |

## IT-CARD-009 — Sửa nội dung không làm mất tiến độ hoặc cờ

- **Ưu tiên:** P0
- **Tiền điều kiện:** Dùng seed có một card đã học, có trạng thái/đến hạn quan sát được và đang flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi nhận state label, due badge và trạng thái cờ của card | Có baseline |
| 2 | Mở editor, chỉ sửa front/back rồi lưu | Nội dung thay đổi |
| 3 | Quan sát lại card | State label, due badge và cờ giữ nguyên |

## IT-CARD-010 — Huỷ và xác nhận xoá card

> **Tách thành** — `IT-CARD-010` (`HOST-WIDGET`) · `IT-CARD-010F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `C-001`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-001`, chọn Xoá | Hiện hộp xác nhận destructive |
| 2 | Chọn Huỷ | Quay lại editor; card vẫn còn sau khi đóng editor |
| 3 | Mở lại và chọn Xoá, sau đó xác nhận | Quay về danh sách; card biến mất |
| 4 | Restart app | Card không xuất hiện lại |

## IT-CARD-011 — Xoá card cuối đưa deck về chưa định loại

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một deck loại card chỉ còn đúng một card.
- **Liên kết:** UC-CARD-001 A2, BR-DECK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Xoá card cuối và xác nhận | Điều hướng về màn hình deck; card, study state và history của nó biến mất cùng nhau |
| 2 | Chạm hành động tạo | Có cả Tạo card và Tạo deck |
| 3 | Xoá một card khi deck vẫn còn card khác | Ở lại card list; loại vẫn là card |

## IT-CARD-012 — Chuyển card sang deck khác cùng cây giữ nguyên tiến độ

- **Ưu tiên:** P0
- **Tiền điều kiện:** Hai deck cùng root: nguồn loại `card` có đúng một card đã học và có tag, đích `unset`.
- **Liên kết:** UC-CARD-001 A5, BR-CARD-010, BR-DECK-015.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi nhận state label, due badge, cờ và tag của card | Có baseline |
| 2 | Nhấn giữ card, chọn Move, chọn deck đích | Card biến mất khỏi danh sách nguồn |
| 3 | Mở deck đích | Card ở đó, mọi thứ ở bước 1 giữ nguyên |
| 4 | Quan sát hai deck | Nguồn về `unset` (hiện cả hai lựa chọn tạo), đích thành loại `card` |
| 5 | Restart app | Cả bốn thay đổi vẫn còn |

## IT-CARD-013 — Đích không hợp lệ bị từ chối trước khi ghi

- **Ưu tiên:** P0
- **Tiền điều kiện:** Một root khác đã tồn tại, cùng scheduler và cùng generation với root hiện tại.
- **Liên kết:** UC-CARD-001 E5, BR-CARD-010.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở picker Move từ một selection | Danh sách chỉ có deck cùng root, không có root, không có deck đang chứa deck con, không có chính deck nguồn |
| 2 | Gọi move tới một deck ở root khác | Bị từ chối kèm lý do; **không** tự đổi scheduler dù hai root trùng chế độ |
| 3 | Quan sát dữ liệu sau lần từ chối | `deck_id`, `content_type` hai đầu và `updated_at` đều không đổi |

## Nhóm: IT scenarios — Tìm kiếm, tổ chức và tiến độ card

## IT-ORG-001 — Tìm card theo mặt trước và mặt sau

> **Tách thành** — `IT-ORG-001` (`HOST-WIDGET`) · `IT-ORG-001F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `D-LEAF` có `C-001`, `C-002`, `C-003`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập `abandon` vào ô tìm kiếm | Chỉ hiện `C-001` |
| 2 | Đổi query thành `nhân từ` | Chỉ hiện `C-002`, chứng minh tìm được theo mặt sau |
| 3 | Xoá query | Tất cả card quay lại |

## IT-ORG-002 — Search không có kết quả và phục hồi

- **Ưu tiên:** P1
- **Tiền điều kiện:** Deck có card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhập `không-tồn-tại` | Hiện empty state nêu từ khoá không khớp; không hiện hành động “thêm card đầu tiên” |
| 2 | Xoá query | Danh sách, filter và progress panel hoạt động lại với dữ liệu gốc |

## IT-ORG-003 — Sắp xếp card mới nhất và đến hạn trước

- **Ưu tiên:** P1
- **Tiền điều kiện:** Dùng `S-DUE`, các card có thời điểm tạo khác nhau.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn sắp xếp Mới nhất | Thứ tự khớp `created_at` giảm dần của fixture; mỗi card xuất hiện đúng một lần |
| 2 | Chọn Đến hạn trước | Hai card đã học và đang Due (`C-P-BEGIN`, `C-P-REVIEW`) đứng trước card future; `C-P-NEW` không bị gọi là Due |
| 3 | Chọn một filter rồi đổi sort | Filter và sort kết hợp; không làm xuất hiện card ngoài filter |

## IT-ORG-004 — Gắn cờ và bỏ cờ một card

> **Tách thành** — `IT-ORG-004` (`HOST-WIDGET`) · `IT-ORG-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `C-003` chưa flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `C-003`, chạm biểu tượng cờ | Biểu tượng chuyển sang trạng thái đã đánh dấu |
| 2 | Quay về card list | Row `C-003` có dấu cờ |
| 3 | Restart app, mở lại card | Cờ vẫn còn |
| 4 | Chạm cờ lần nữa | Cờ được bỏ ở editor và card list |

## IT-ORG-005 — Lọc All, Due, New và Flagged với số lượng đúng

- **Ưu tiên:** P0
- **Tiền điều kiện:** Dùng `S-DUE`, trong đó có ít nhất một card flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát bốn filter pill | Hiện chính xác All 4, Due 2, New 1 và Flagged 1 |
| 2 | Chọn Due | Chỉ hiện `C-P-BEGIN` và `C-P-REVIEW`; `C-P-NEW` không xuất hiện |
| 3 | Chọn New | Chỉ hiện card chưa học |
| 4 | Chọn Flagged | Chỉ hiện card đã gắn cờ |
| 5 | Chọn All | Tất cả card trở lại |

## IT-ORG-006 — Filter không có kết quả không bị hiểu là deck rỗng

- **Ưu tiên:** P1
- **Tiền điều kiện:** Deck có card nhưng không card nào flagged.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Flagged | Hiện trạng thái “không có card phù hợp”, không hiện CTA thêm card đầu tiên |
| 2 | Chọn All | Danh sách card trở lại |

## IT-ORG-010 — Trạng thái, due badge và progress panel nhất quán

> **Tách thành** — `IT-ORG-010` (`HOST-WIDGET`) · `IT-ORG-010F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`testing-pyramid-audit.md`](../../shared/testing/testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** Dùng `S-PROGRESS` v2; nó dùng chung contract dữ liệu với alias S-DUE.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở card list | Mỗi row hiện đúng một state: New, Beginning, Reviewing hoặc Mastered |
| 2 | Quan sát due badge | `C-P-NEW` không có due badge; hai card Due hiện quá hạn/đến hạn; card future hiện số ngày còn lại đúng fixture |
| 3 | Quan sát progress panel | Tổng 4; mỗi state có 1 card; Mastered là 1/4 và 25% |
| 4 | Gắn/bỏ cờ hoặc sửa text một card | Progress không thay đổi vì các thao tác này không phải review |

## IT-ORG-011 — Breadcrumb và tên deck trên card list cập nhật sau rename

- **Ưu tiên:** P1
- **Tiền điều kiện:** `D-EB > D-BRANCH > D-LEAF` có card.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở `D-LEAF` | App bar hiện `D-LEAF`; breadcrumb hiện đủ ancestors |
| 2 | Quay lại, đổi tên `D-BRANCH`, rồi mở lại `D-LEAF` | Breadcrumb dùng tên ancestor mới |
| 3 | Đổi tên chính `D-LEAF` và mở lại | App bar và breadcrumb dùng tên leaf mới |

## IT-ORG-013 — Chọn nhiều card và Select all trên tập đã lọc

- **Ưu tiên:** P0
- **Tiền điều kiện:** Deck có nhiều card hơn một cửa sổ tải, và một filter khớp một tập con quan sát được.
- **Liên kết:** UC-CARD-001 A6, BR-CARD-012.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Nhấn giữ một card | Vào selection mode với đúng card đó; thanh hành động hiện số lượng |
| 2 | Chạm card khác | Số lượng tăng; chạm lại thì giảm |
| 3 | Bỏ chọn card cuối cùng | Rời selection mode |
| 4 | Vào lại mode rồi chọn Select all | Số lượng bằng **toàn bộ tập đã lọc**, không phải số dòng đang hiển thị |
| 5 | Đổi filter | Selection bị xoá, không mang theo sang tập khác |
| 6 | Bấm Back khi đang chọn | Rời selection trước, vẫn ở lại card list |

## IT-ORG-014 — Bulk action là tất-cả-hoặc-không

- **Ưu tiên:** P0
- **Tiền điều kiện:** Có `IT-ORG-013`; một selection từ hai card trở lên.
- **Liên kết:** UC-CARD-001 A6, UC-CARD-001 E6, BR-CARD-011.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn Delete từ thanh hành động | Hộp xác nhận nêu **số lượng** và hậu quả mất lịch sử học; Huỷ là mặc định |
| 2 | Chọn Huỷ | Không card nào bị xoá; selection còn nguyên |
| 3 | Xác nhận xoá | Cả lô biến mất cùng lúc; selection được xoá; thông báo nêu số lượng |
| 4 | Chạy một bulk action mà một phần tử bị từ chối | **Không** phần tử nào được ghi; selection giữ nguyên để thử lại |
| 5 | Restart app | Kết quả bước 3 vẫn còn, kết quả bước 4 vẫn chưa từng xảy ra |
