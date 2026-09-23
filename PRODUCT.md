# Product

<!-- impeccable:product-schema 1 -->

Bản tóm tắt bối cảnh sản phẩm cho Impeccable, chủ dự án xác nhận ngày
2026-09-23. Nguồn gốc là [`docs/README.md`](docs/README.md) (mục Sản phẩm) và
các ADR trong [`docs/shared/decisions/`](docs/shared/decisions/); khi hai bên
lệch nhau, `docs/` thắng và file này phải sửa theo.

## Platform

android

## Users

- Người tự học từ vựng trên điện thoại, học vào những quãng thời gian rời rạc,
  kết nối mạng không ổn định.
- Người ôn thi: khối lượng từ lớn, có deadline, cần theo dõi tiến độ và ưu tiên
  từ sắp quên.

Không nhắm tới lớp học có giáo viên quản lý hay người cần nội dung biên soạn sẵn.

## Product Purpose

Ôn đúng từ vào đúng thời điểm theo lịch SRS, và dùng được đầy đủ mọi lúc kể cả
khi không có mạng. Thành công là người dùng tạo deck và card, rồi ôn hằng ngày
theo lịch mà không cần mạng.

## Positioning

- Mỗi root deck chọn một trong hai scheduler, `eight_box` hoặc `sm2`
  ([ADR-003](docs/shared/decisions/ADR-003-hai-scheduler-chon-theo-deck.md)).
- Sáu study mode trong V8.0: `browse`, `self_assess`, `match`, `guess`,
  `recall`, `fill` ([ADR-009](docs/shared/decisions/ADR-009-chot-pham-vi-v8-0.md)).
- Cây deck lồng tối đa 10 cấp; nội dung do người dùng tự tạo.

## Operating Context

Phiên học ngắn trên điện thoại, thường ở chế độ máy bay hoặc mạng chập chờn.
Không tài khoản, không đồng bộ; dữ liệu chỉ nằm trên máy.

## Capabilities and Constraints

- Chỉ Android là target phát hành; Flutter Web chỉ dùng để dev/test
  ([ADR-001](docs/shared/decisions/ADR-001-quyet-dinh-nen-tang.md)).
- Offline hoàn toàn, không network, không auth.
- Ngôn ngữ giao diện: tiếng Việt và tiếng Anh; Settings chọn System / English /
  Tiếng Việt. Theme: System / Light / Dark.
- Phạm vi V8.0 và những gì để sub-project sau:
  [ADR-009](docs/shared/decisions/ADR-009-chot-pham-vi-v8-0.md) và
  [`docs/README.md`](docs/README.md).

## Brand Commitments

- Tên sản phẩm: **MemoX**.
- Giữ nguyên hai màu của light mode (chủ dự án chốt 2026-09-23):
  - primary `#5265F5`;
  - nền trang (page ground) `#F7F9FE`.
- Chưa có logo hay icon app bắt buộc. Phần còn lại của design kit V3
  ([`docs/shared/ui/design-handoff/`](docs/shared/ui/design-handoff/00-index.md))
  là tài liệu tham chiếu, chưa phải cam kết thương hiệu.

## Evidence on Hand

- Handoff thiết kế V3 (foundations, theme binding, 46 widget) ở
  `docs/shared/ui/design-handoff/`; vấn đề đã biết ở
  `.impeccable/critique/2026-09-21T06-26-58Z__handoff-out.md`.
- Starter deck hiện chỉ là fixture để dev/test, không phải nội dung production.
- Chưa có testimonial, số liệu người dùng hay case study; không được bịa.

## Product Principles

1. Offline là trạng thái bình thường, không phải chế độ phụ.
2. Người dùng luôn thấy hôm nay còn bao nhiêu card đến hạn (M4).
3. Nội dung người dùng là dữ liệu riêng tư: không log, không gửi đi
   ([BR-CORE-001](docs/shared/rules/BR-CORE-001-noi-dung-nguoi-dung-la-du-lieu-rieng-tu.md),
   [BR-CORE-002](docs/shared/rules/BR-CORE-002-khong-log-noi-dung.md)).
4. Một phiên học vừa với vài phút rảnh: vào học nhanh, thoát giữa chừng không
   mất những lượt đã trả lời.

## Accessibility & Inclusion

- Không khoá cỡ chữ hệ thống; bố cục phải chịu được cỡ chữ 200%.
- Hỗ trợ trình đọc màn hình (TalkBack).
- Vùng chạm tối thiểu 48dp.
