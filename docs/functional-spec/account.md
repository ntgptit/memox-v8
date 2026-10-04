# Account — functional specification

Các chức năng của feature account: tài khoản, đăng nhập, quản lý quyền, và đồng bộ với server.
Định dạng: [docs/README.md](../README.md), mục "UC, FN và screen spec". Feature account chưa có UC
và BR: hành vi của nó theo [auth spec](../superpowers/specs/2026-09-30-auth-design.md),
[account UI spec](../superpowers/specs/2026-09-30-account-ui-design.md),
[users admin spec](../superpowers/specs/2026-09-30-users-admin-design.md),
[app deck sync spec](../superpowers/specs/2026-09-27-app-deck-sync-design.md) và
[sync status spec](../superpowers/specs/2026-09-28-sync-status-design.md). Đồng bộ (code ở
`lib/core/sync/`) và các lệnh tài khoản (code ở `lib/core/auth/`) không có use case class; mỗi FN
dưới đây trỏ tới nơi hành vi đang sống.

Lỗi là các `Failure` của `lib/core/error/failure.dart`: `OfflineFailure` khi lời gọi không tới
được server, `ServerFailure` khi server không trả lời được, và các `AuthFailure` có tên ở từng FN.

Đăng nhập là tuỳ chọn: app chạy trên một người dùng ẩn danh, và người dùng có thể gắn email hoặc
Google vào thiết bị. Trạng thái tài khoản là nguồn sự thật duy nhất cho đồng bộ, điều hướng và mọi
màn hình. Mỗi lúc chỉ một lệnh tài khoản chạy; lệnh sau chờ lệnh trước. Một lệnh đổi tài khoản
(chuyển, đăng xuất, xoá, bỏ tài khoản bị từ chối) là một **chuyển tiếp** được lưu lại, nên app bị
tắt giữa chừng vẫn đi tiếp được ở lần mở sau.

## FN-ACCOUNT-001 — Hiện Welcome một lần trên mỗi thiết bị
Status: active · Code: [lib/features/account/domain/usecases/is_welcome_seen_use_case.dart, lib/features/account/domain/usecases/mark_welcome_seen_use_case.dart, lib/app/startup_welcome.dart]

### Precondition

Bản build có thể đăng nhập.

### Input

- Khi đọc: không có.
- Khi đánh dấu: không có — mọi lối ra khỏi Welcome đều đánh dấu nó đã được trả lời.

### Kết quả

Trước khung hình đầu, cờ Welcome của thiết bị được đọc, chờ tối đa 2 giây: chưa trả lời thì Welcome
hiện, kể cả trên thiết bị đã dùng app trước bản cập nhật. Đọc lỗi hoặc quá hạn thì không hiện gì, và
lần mở sau hỏi lại. Đánh dấu ghi cờ một lần cho thiết bị; từ đó Welcome không hiện nữa.

### Lỗi

- Đọc hoặc ghi database thất bại (ADR-016).

### Business rules

Không áp dụng — feature account chưa có BR (account UI spec §5.1, U1).

## FN-ACCOUNT-002 — Theo dõi trạng thái tài khoản
Status: active · Code: [lib/core/auth/auth_state.dart, lib/core/auth/account_coordinator.dart]

### Precondition

Không có.

### Input

Không có.

### Kết quả

Một stream trạng thái tài khoản, là một trong: đang khởi động; **chỉ cục bộ** (không có phiên và
không có mạng: ghi cục bộ vẫn chạy, thay đổi chờ gửi); đang tạo người dùng ẩn danh; **đang xác nhận**
phiên (đồng bộ tạm dừng); **sẵn sàng** (đã xác nhận: email, cách đăng nhập — Google, email hay cả hai
— và vai trò; đồng bộ chạy khi có mạng); **cần đăng nhập lại** (phiên của một tài khoản bị từ chối:
dữ liệu trên máy giữ nguyên, đồng bộ dừng); **đang chuyển tiếp**, kèm việc nó đang chờ người dùng đăng
nhập vào tài khoản đích hay đã dừng vì sao; hoặc **đang khôi phục** một chuyển tiếp còn dở từ lần
chạy trước. Kèm các thông báo một lần: việc gộp không thành và thiết bị đã về dữ liệu của chính nó;
việc xoá tài khoản không thành.

### Lỗi

Không có: một lỗi là một trạng thái trong stream.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.2).

## FN-ACCOUNT-003 — Gửi mã đăng nhập qua email
Status: active · Code: [lib/core/auth/account_coordinator_switch.dart]

### Precondition

Một trong ba ngữ cảnh: thiết bị đang là người dùng ẩn danh (gắn email vào nó), một lần chuyển đang
chờ đăng nhập vào tài khoản đích, hoặc tài khoản cần đăng nhập lại.

### Input

- Địa chỉ email.
- Người dùng đã xác nhận mất các thay đổi chưa gửi hay chưa: chỉ dùng khi đăng nhập lại bằng một tài
  khoản **khác**.

### Kết quả

Một mã 6 chữ số được gửi tới địa chỉ đó. Không gì trên thiết bị đổi.

### Lỗi

- `IdentityTakenFailure` — khi gắn: email đã thuộc một tài khoản khác; người dùng chọn gộp hay bỏ
  dữ liệu của máy (FN-ACCOUNT-007).
- `UnsentChangesFailure` — khi đăng nhập lại bằng tài khoản khác mà còn thay đổi chưa gửi, chưa được
  xác nhận: kèm số thay đổi sẽ mất. Cùng tài khoản thì không hỏi gì.
- `RateLimitedFailure` — quá nhiều lần thử.
- `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #16, #17, #21, #36; account UI spec
§5.2).

## FN-ACCOUNT-004 — Xác nhận mã đăng nhập
Status: active · Code: [lib/core/auth/account_coordinator_switch.dart]

### Precondition

Một mã đã được gửi tới địa chỉ đó, trong cùng ngữ cảnh.

### Input

- Địa chỉ email.
- Mã 6 chữ số.

### Kết quả

Theo ngữ cảnh: email được gắn vào người dùng ẩn danh của thiết bị và tài khoản được xác nhận lại;
hoặc tài khoản đích của lần chuyển được đăng nhập và lần chuyển đi tiếp; hoặc tài khoản được đăng
nhập lại — cùng tài khoản thì xác nhận lại và đồng bộ chạy tiếp, tài khoản khác thì thiết bị chuyển
sang nó và bỏ dữ liệu cũ.

### Lỗi

- `InvalidCodeFailure` — mã sai hoặc hết hạn; hai trường hợp là một.
- `RateLimitedFailure`, `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #16, #21, #36, #37; account UI spec
§5.2).

## FN-ACCOUNT-005 — Đăng nhập bằng Google
Status: active · Code: [lib/core/auth/account_coordinator_switch.dart, lib/core/auth/google_credential_source.dart]

### Precondition

Một trong ba ngữ cảnh: thiết bị đang là người dùng ẩn danh (gắn Google vào nó), một lần chuyển đang
chờ đăng nhập vào tài khoản đích, hoặc tài khoản cần đăng nhập lại.

### Input

- Người dùng đã xác nhận mất các thay đổi chưa gửi hay chưa: chỉ dùng khi đăng nhập lại bằng một tài
  khoản **khác**.

### Kết quả

Người dùng chọn một tài khoản Google, rồi theo ngữ cảnh: tài khoản đó được gắn vào người dùng ẩn
danh, hoặc được đăng nhập làm tài khoản đích, hoặc được đăng nhập lại. Tài khoản Google đã chọn được
giữ lại khi phải hỏi người dùng thêm (gộp, hoặc mất thay đổi), để lần sau không phải chọn lại; người
dùng từ chối thì lần sau chọn lại từ đầu.

### Lỗi

- `GoogleCancelledFailure` — người dùng huỷ việc chọn; không phải lỗi cần báo.
- `IdentityTakenFailure` — khi gắn: tài khoản Google đã thuộc một tài khoản khác.
- `UnsentChangesFailure` — khi đăng nhập lại bằng tài khoản khác mà còn thay đổi chưa gửi, chưa được
  xác nhận: kèm số thay đổi sẽ mất. Cùng tài khoản thì không hỏi gì.
- `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #16, #17, #21, #36; account UI spec
§5.2, U6).

## FN-ACCOUNT-006 — Đếm thư viện trên thiết bị
Status: active · Code: [lib/features/account/domain/usecases/count_local_library_use_case.dart, lib/features/account/domain/models/local_library_model.dart]

### Precondition

Không có.

### Input

Không có.

### Kết quả

Số deck và số card đang active trên thiết bị, không tính Trash — điều một lần gộp sẽ mang theo.
Không có deck nào nghĩa là không có gì để gộp hay để mất: lần chuyển không cần hỏi. Không ghi gì.

### Lỗi

- Đọc database thất bại (ADR-016).

### Business rules

Không áp dụng — feature account chưa có BR (account UI spec §5.3, R6).

## FN-ACCOUNT-007 — Chuyển thiết bị sang tài khoản khác
Status: active · Code: [lib/core/auth/account_coordinator_switch.dart, lib/core/auth/account_transition.dart]

### Precondition

Tài khoản đang sẵn sàng, và không có chuyển tiếp nào khác đang chạy.

### Input

- Cách xử lý dữ liệu của thiết bị: **gộp** vào tài khoản đích — chỉ khi thiết bị đang là người dùng
  ẩn danh mà email hay Google đã thuộc một tài khoản — hoặc **bỏ** dữ liệu của thiết bị.
- Gợi ý tài khoản đích, khi có.

### Kết quả

Đồng bộ dừng, các thay đổi của tài khoản nguồn được gửi đi trước, và với gộp thì một quyền gộp được
giữ trên server. Rồi trạng thái chờ người dùng đăng nhập vào tài khoản đích (FN-ACCOUNT-003…005).
Sau khi đăng nhập: gộp thì dữ liệu của thiết bị nhập vào tài khoản đích; bỏ thì dữ liệu của thiết
bị bị xoá và dữ liệu của tài khoản đích được tải về. Trước khi đăng nhập vào đích, người dùng có thể
**huỷ**: thiết bị về lại tài khoản nguồn như cũ — hoặc, nếu phiên của nguồn đã mất, coi như mất nguồn.
Server từ chối gộp thì không gì được chuyển, và thiết bị về lại dữ liệu của chính nó (thông báo một
lần ở FN-ACCOUNT-002).

### Lỗi

- `ClaimInvalidFailure` — quyền gộp đã dùng, hết hạn hoặc không tồn tại.
- `OfflineFailure`, `ServerFailure` — chuyển tiếp dừng lại và đi tiếp khi thử lại (FN-ACCOUNT-011).

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #18–#35; account UI spec §5.3, §9 R1).

## FN-ACCOUNT-008 — Đăng xuất
Status: active · Code: [lib/core/auth/account_coordinator_leave.dart]

### Precondition

Tài khoản đang sẵn sàng.

### Input

- Có chấp nhận mất các thay đổi chưa gửi không: mặc định không.

### Kết quả

Các thay đổi chưa gửi được gửi đi trước; khi không có mạng, việc đăng xuất **chờ** ở đó, trừ khi
người dùng chấp nhận mất chúng. Rồi log được gửi, phiên bị bỏ, dữ liệu tài khoản trên thiết bị bị
xoá, và một người dùng ẩn danh mới bắt đầu. Khi còn đang chờ — chưa gì trên thiết bị bị xoá — người
dùng có thể **huỷ**: thiết bị về lại tài khoản như cũ và phiên được kiểm tra lại. Gọi lại lệnh đăng
xuất đang chờ, với việc chấp nhận mất, là đi tiếp nó.

### Lỗi

- `OfflineFailure`, `ServerFailure` — chuyển tiếp dừng lại và đi tiếp khi thử lại.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #39–#41; account UI spec §9 B4).

## FN-ACCOUNT-009 — Xoá tài khoản
Status: active · Code: [lib/core/auth/account_coordinator_leave.dart]

### Precondition

Tài khoản đang sẵn sàng, và người dùng đã xác nhận.

### Input

Không có.

### Kết quả

Tài khoản cùng mọi deck, card và tiến độ của nó bị xoá trên server, rồi thiết bị được dọn như khi
đăng xuất và một người dùng ẩn danh mới bắt đầu. Không thể hoàn tác.

### Lỗi

- `OfflineFailure` — không có mạng: từ chối trước khi bất cứ gì đổi.
- `LastAdminFailure` — tài khoản là admin cuối cùng: không gì bị xoá, và thông báo một lần ở
  FN-ACCOUNT-002 nói việc xoá không thành.
- `ServerFailure`.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #42–#44; account UI spec §9 B6, B7).

## FN-ACCOUNT-010 — Tiếp tục không cần tài khoản
Status: active · Code: [lib/core/auth/account_coordinator_leave.dart]

### Precondition

Tài khoản cần đăng nhập lại.

### Input

Không có.

### Kết quả

Tài khoản bị từ chối được bỏ: dữ liệu của nó trên thiết bị bị xoá — kể cả thay đổi chưa gửi — và
một người dùng ẩn danh mới bắt đầu. Đăng nhập lại vào tài khoản đó sau này thì lấy lại dữ liệu đã có
trên server.

### Lỗi

- `OfflineFailure`, `ServerFailure` — chuyển tiếp dừng lại và đi tiếp khi thử lại.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #38; account UI spec §5.2).

## FN-ACCOUNT-011 — Thử lại một chuyển tiếp đã dừng
Status: active · Code: [lib/core/auth/account_coordinator.dart]

### Precondition

Một chuyển tiếp đang dừng vì một lỗi, thường là mất mạng.

### Input

Không có.

### Kết quả

Chuyển tiếp đi tiếp từ đúng bước nó dừng, không làm lại các bước đã xong.

### Lỗi

- Như của chuyển tiếp đó.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec §3.3 #45, R1).

## FN-ACCOUNT-012 — Tìm người dùng (admin)
Status: active · Code: [lib/features/account/domain/usecases/search_users_use_case.dart, lib/features/account/domain/models/user_page_model.dart, lib/features/account/domain/models/managed_user_model.dart]

### Precondition

Người gọi là admin.

### Input

- Từ cần tìm theo email, bỏ khoảng trắng hai đầu.
- Email của dòng cuối trang trước, khi đọc trang sau.

### Kết quả

Một trang tới 50 tài khoản đã đăng nhập bằng email hoặc Google, theo email, mỗi tài khoản mang
email, vai trò (admin hoặc người dùng), ngày tham gia và lần đăng nhập gần nhất; kèm email để đọc
trang kế tiếp, hoặc không có ở trang cuối. Không có tổng số. Không ghi gì.

### Lỗi

- `NotAdminFailure` — người gọi không phải admin.
- `OfflineFailure`, `ServerFailure`.

### Business rules

Không áp dụng — feature account chưa có BR (users admin spec §2, §3).

## FN-ACCOUNT-013 — Đặt vai trò của một người dùng (admin)
Status: active · Code: [lib/features/account/domain/usecases/set_user_role_use_case.dart]

### Precondition

Người gọi là admin.

### Input

- Tài khoản.
- Vai trò mới: admin hoặc người dùng.

### Kết quả

Vai trò được đổi trên server, và vai trò đang giữ được trả về; không có gì khi tài khoản không còn.

### Lỗi

- `LastAdminFailure` — việc đổi sẽ không còn admin nào.
- `AnonymousUserFailure` — tài khoản chưa đăng nhập bằng email hay Google, nên không thể là admin.
- `NotAdminFailure` — người gọi không còn là admin.
- `OfflineFailure`, `ServerFailure`.

Mọi lỗi đều không đổi gì.

### Business rules

Không áp dụng — feature account chưa có BR (auth spec O9; users admin spec §2).

## FN-ACCOUNT-014 — Đồng bộ thư viện với server
Status: active · Code: [lib/core/sync/sync_scheduler.dart, lib/core/sync/sync_coordinator.dart]

### Precondition

Tài khoản đã được xác nhận; khi chưa, đồng bộ không bắt đầu.

### Input

Không có: đồng bộ tự chạy.

### Kết quả

Một lần đồng bộ gửi các thay đổi đang chờ trên thiết bị rồi tải về các thay đổi từ server. Nó chạy
lúc bắt đầu, sau một loạt thay đổi (gom lại trước khi chạy), ngay khi mạng trở lại, và lùi dần sau
một lần thất bại; mỗi lúc chỉ một lần chạy. Việc học không bao giờ chờ đồng bộ. Server đã có một
bản khác của dòng được gửi thì bản của server được áp lên thiết bị; một thay đổi mới hơn trên thiết
bị thì không bị đè. Một dòng server từ chối mà chưa từng có trên server không được gửi lại tự động:
nó nằm lại trên thiết bị — không bao giờ bị xoá — chờ người dùng quyết định. Mỗi lần chạy
ghi lại kết quả: lần thành công gần nhất, hoặc lần thất bại gần nhất cùng loại của nó. Đồng bộ tạm
dừng trong lúc một chuyển tiếp tài khoản chạy, và không gửi gì sau khi đã dừng.

### Lỗi

Không có lỗi đi ra: một lần thất bại được ghi theo loại — không có mạng (một trạng thái bình thường),
không đăng nhập được, server lỗi, hoặc lỗi khác — rồi đồng bộ lùi lại và thử sau.

### Business rules

Không áp dụng — feature account chưa có BR (app deck sync spec §5; sync status spec §4; auth spec
R2, R3).

## FN-ACCOUNT-015 — Theo dõi trạng thái đồng bộ
Status: active · Code: [lib/core/sync/sync_status.dart, lib/core/sync/sync_store.dart]

### Precondition

Không có.

### Input

Không có.

### Kết quả

Một stream: lần đồng bộ thành công gần nhất; lần thất bại gần nhất cùng loại của nó, chỉ khi chưa
có lần thành công nào sau nó; số thay đổi đang chờ gửi và lúc thay đổi chờ lâu nhất bắt đầu chờ; và
số dòng server đã từ chối. Đồng bộ **cần chú ý** khi có dòng bị từ chối, hoặc có thay đổi đã chờ quá
24 giờ. Không ghi gì.

### Lỗi

- Đọc database thất bại (ADR-016).

### Business rules

Không áp dụng — feature account chưa có BR (sync status spec §4, R2).

## FN-ACCOUNT-016 — Đồng bộ ngay
Status: active · Code: [lib/core/sync/sync_commands.dart, lib/core/sync/sync_scheduler.dart]

### Precondition

Bản build có server.

### Input

Không có.

### Kết quả

Bỏ qua thời gian lùi và chạy một lần đồng bộ ngay — hoặc ngay sau lần đang chạy. Kết quả cho biết
lần chạy đó có thành công không.

### Lỗi

Không có lỗi đi ra: một lần thất bại là kết quả "không thành công", và được ghi lại cùng loại của
nó như mọi lần đồng bộ.

### Business rules

Không áp dụng — feature account chưa có BR (sync status spec §5.2).

## FN-ACCOUNT-017 — Gửi lại các thay đổi bị từ chối
Status: active · Code: [lib/core/sync/sync_commands.dart, lib/core/sync/sync_coordinator.dart]

### Precondition

Có ít nhất một dòng server đã từ chối.

### Input

Không có.

### Kết quả

Các dòng bị từ chối trở lại hàng chờ gửi, rồi một lần đồng bộ chạy ngay. Kết quả cho biết lần chạy
đó có thành công không.

### Lỗi

- Ghi database thất bại: không gì đổi (ADR-016).

### Business rules

Không áp dụng — feature account chưa có BR (sync status spec §5.2, R7).

## FN-ACCOUNT-018 — Giữ các thay đổi bị từ chối chỉ trên thiết bị
Status: active · Code: [lib/core/sync/sync_commands.dart, lib/core/sync/sync_store.dart]

### Precondition

Có ít nhất một dòng server đã từ chối, và người dùng đã xác nhận.

### Input

Không có.

### Kết quả

Các dòng bị từ chối thôi chờ gửi: chúng ở lại trên thiết bị và không bao giờ đồng bộ sang thiết bị
khác. Dữ liệu trên thiết bị không đổi. Không thể hoàn tác.

### Lỗi

- Ghi database thất bại: không gì đổi (ADR-016).

### Business rules

Không áp dụng — feature account chưa có BR (sync status spec §5.2, R7).
