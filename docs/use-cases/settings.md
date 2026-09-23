# Use cases — Tuỳ chọn ứng dụng

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Đặc tả luồng người dùng của đối tượng SETTINGS, dưới ID vĩnh viễn `UC-SETTINGS-nnn` |
| **Scope** | Luồng đặt tuỳ chọn ứng dụng. |
| **Source of truth for** | UC-SETTINGS-nnn · main/alternative/error flow · UI state matrix |
| **Depends on** | `../document-conventions.md`, `../product/product.md`, `../business-rules/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## UC-SETTINGS-001 · Đặt tuỳ chọn ứng dụng

| | |
|---|---|
| **Status** | active |

**Actor:** Người dùng
**Trigger:** Mở tab `Settings` của navigation shell, hoặc deep link `/settings`
**Preconditions:** Không có. Một local profile, dòng `app_settings` luôn tồn tại
(BR-SETTINGS-001)

**Main flow:**
1. Người dùng mở tab Settings. Hệ thống đọc dòng `app_settings` qua stream và
   hiển thị ba nhóm: `Study defaults`, `Appearance`, `Language` — mỗi control
   hiển thị **giá trị đang có hiệu lực**, không phải placeholder (BR-SETTINGS-001).
2. Người dùng đổi trần thẻ mỗi phiên và/hoặc thứ tự thẻ mới, rồi bấm lưu nhóm
   `Study defaults`. Hệ thống validate trần thẻ bằng đúng ràng buộc của tùy chọn
   deck (BR-SETTINGS-002), ghi một transaction, và stream đẩy giá trị mới ra mọi surface.
3. Hệ thống nói rõ tại chỗ rằng mặc định mới áp cho **phiên tạo sau đó**; phiên
   đang chạy giữ nguyên trần đã chốt (BR-SETTINGS-004).
4. Người dùng chọn theme trong `System` / `Light` / `Dark`. Lựa chọn là một
   submit riêng, ghi ngay khi chạm, và giao diện đổi trong cùng phiên chạy —
   không restart, không mất navigation stack (BR-SETTINGS-005).
5. Người dùng chọn ngôn ngữ trong `System` / `English` / `Tiếng Việt`. Cùng cơ
   chế và cùng ràng buộc như theme (BR-SETTINGS-006).
6. Rời tab và quay lại, hoặc khởi động lại app: mọi lựa chọn tường minh vẫn còn
   (BR-SETTINGS-005, BR-SETTINGS-006).

**Alternative flows:**
- **A1 — Root deck có override:** deck đó không đổi gì khi mặc định toàn app
  đổi. Muốn nó theo mặc định, người dùng mở tuỳ chọn học của deck và bấm
  `Use app defaults`; hệ thống xoá `study_config` của root trong một transaction
  và deck bắt đầu đọc mặc định toàn app. Tiến độ học, scheduler và lịch sử không
  đụng (BR-SETTINGS-003). Deck không có override thì action này không hiện.
- **A2 — `System` khi platform đổi:** người dùng đổi dark mode hoặc ngôn ngữ của
  hệ điều hành trong lúc app đang chạy. Đang để `System` thì app đổi theo ngay;
  đang để một giá trị tường minh thì app không đổi (BR-SETTINGS-005, BR-SETTINGS-006).
- **A3 — Reset về mặc định:** người dùng chọn `Reset to defaults`, hệ thống hỏi
  xác nhận và nói rõ hành động này **không** đụng tiến độ học. Xác nhận đưa cả
  bốn giá trị về mặc định trong một transaction (BR-SETTINGS-008).
- **A4 — Bấm lưu lần thứ hai khi lần đầu chưa xong:** hệ thống bỏ qua lần bấm
  sau; không có hai transaction nào chạy cho một lần đổi (BR-SETTINGS-007).

**Error flows:**
- **E1 — Trần thẻ không hợp lệ:** không phải số, nhỏ hơn tối thiểu hoặc lớn hơn
  tối đa → lý do có kiểu hiện ngay dưới trường, không ghi gì, draft giữ nguyên
  (BR-SETTINGS-002, BR-SETTINGS-007).
- **E2 — Ghi thất bại:** thao tác ghi lỗi → thông báo có kiểu và `Retry`. Draft
  giữ nguyên, các control còn lại vẫn hiển thị giá trị **đã persisted**; thông
  báo MUST NOT lộ SQL hay stack trace (BR-SETTINGS-007).
- **E3 — Đọc thất bại:** stream lỗi → trạng thái lỗi của cả màn với `Retry`;
  không control nào hiển thị giá trị bịa (BR-SETTINGS-001).
- **E4 — Xoá override của deck thất bại:** override giữ nguyên, lý do có kiểu,
  không có thay đổi một phần nào (BR-SETTINGS-003).

**Postconditions:** `app_settings` giữ đúng một dòng với giá trị người dùng đã
chọn (BR-SETTINGS-001). `deck.study_config` chỉ đổi khi người dùng chủ động dùng
`Use app defaults` hoặc chỉnh tuỳ chọn của chính deck đó (BR-SETTINGS-003). Không thẻ,
study state, session hay history nào bị đụng bởi bất kỳ luồng nào ở trên
(BR-SETTINGS-004, BR-SETTINGS-008).

**Business rules:** BR-STUDY-003, BR-SRS-022, BR-STUDY-035, BR-STUDY-024, BR-STUDY-056, BR-STUDY-057, BR-SETTINGS-001,
BR-SETTINGS-002, BR-SETTINGS-003, BR-SETTINGS-004, BR-SETTINGS-005, BR-SETTINGS-006, BR-SETTINGS-007, BR-SETTINGS-008

**UI states:** loading (đọc lần đầu) · loaded ở mặc định · loaded ở giá trị
không mặc định · saving (control của nhóm đang ghi bị khoá, các nhóm khác vẫn
dùng được) · validation error trên trần thẻ · persistence error + retry · reset
confirm · System resolution theo platform (light/dark, en/vi). Không có state
`empty`: một màn tuỳ chọn luôn có đủ ba nhóm.
