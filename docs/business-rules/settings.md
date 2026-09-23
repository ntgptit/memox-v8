# Business rules — Tuỳ chọn ứng dụng

| | |
|---|---|
| **Status** | frozen for MVP |
| **Purpose** | Phát biểu luật nghiệp vụ của đối tượng SETTINGS, dưới ID vĩnh viễn `BR-SETTINGS-nnn` |
| **Scope** | Luật tuỳ chọn ứng dụng (`app_settings`): mặc định học, theme, ngôn ngữ. |
| **Source of truth for** | BR-SETTINGS-nnn của đối tượng này |
| **Depends on** | `../document-conventions.md`, `../product/product.md` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

## Tuỳ chọn ứng dụng

Mặc định học toàn app, theme và ngôn ngữ, trong một dòng duy nhất (UC-SETTINGS-001). Các rule dưới đây **không** phát biểu lại luật override theo root deck (BR-DECK-025) hay luật riêng tư chung (BR-PRIVACY-001…BR-PRIVACY-004).

| ID | Status | Rule | Enforced by | Related |
|---|---|---|---|---|
| BR-SETTINGS-001 | active | `app_settings` MUST là nơi duy nhất giữ mặc định toàn app, MUST ở đúng một dòng (`id = 1`) và MUST là **cột có kiểu** — MUST NOT là key-value, JSON blob hay chuỗi phải ép kiểu lúc đọc. Mọi surface MUST đọc qua cùng một stream của dòng đó, nên một lần ghi MUST làm mọi surface đang mở cập nhật mà không cần điều hướng lại. MUST NOT có bản thứ hai của các giá trị này sống trong bộ nhớ của provider, và trạng thái hiển thị MUST NOT là nguồn sự thật. Đọc mà không có dòng nào là defect, MUST NOT được xử lý như một trạng thái hợp lệ bằng cách bịa giá trị mặc định tại chỗ. | db + store | BR-STUDY-056 |
| BR-SETTINGS-002 | active | Mặc định học toàn app MUST gồm đúng hai giá trị: `card_limit` và `new_card_order`. Chúng MUST dùng lại đúng validation và enum production của BR-STUDY-003 và BR-STUDY-057 — MUST NOT có bản sao thứ hai của bound, của giá trị mặc định hay của tên enum. Ghi mặc định toàn app MUST NOT ghi vào `deck.study_config` của bất kỳ deck nào. | rule | BR-STUDY-003, BR-STUDY-056, BR-STUDY-057 |
| BR-SETTINGS-003 | active | Root deck đang có `study_config` MUST tiếp tục dùng override đó sau khi mặc định toàn app đổi; root không override MUST đọc mặc định mới ngay ở lần giải kế tiếp. Hành động `Use app defaults` MUST xoá override của **root** trong một transaction và MUST NOT đụng `card_schedule`, `review_log`, `study_session`, `scheduler_*` hay `first_answered_at`. Hành động này MUST sống ở surface tuỳ chọn của deck, MUST NOT nằm trên màn hình Settings toàn app, và deck con MUST NOT sở hữu override để mà xoá. | store + UI | BR-STUDY-056, BR-DECK-025 |
| BR-SETTINGS-004 | active | Đổi bất kỳ mặc định học nào MUST chỉ có hiệu lực với phiên **được tạo sau đó**. Phiên đang chạy MUST giữ nguyên `study_session.card_limit` đã chốt lúc mở (BR-STUDY-024), MUST NOT dựng lại hàng đợi, MUST NOT đổi thứ tự đã sinh và MUST NOT đổi round đang chạy. UI MUST nói rõ điều đó tại chỗ đổi. | store + UI | BR-STUDY-024, BR-STUDY-022, BR-STUDY-057 |
| BR-SETTINGS-005 | active | Theme MUST là một trong ba giá trị lưu được: `system`, `light`, `dark`; mặc định `system`. `system` MUST giải theo brightness của platform tại thời điểm hiện tại và MUST đổi theo khi platform đổi mà người dùng không thao tác gì. Lựa chọn tường minh MUST bền qua restart và MUST thắng brightness của platform. Đổi theme MUST áp ngay trong cùng phiên chạy: MUST NOT cần restart, MUST NOT dựng lại router và MUST NOT làm mất navigation stack hay vị trí cuộn. | db + UI | BR-SETTINGS-001 |
| BR-SETTINGS-006 | active | Ngôn ngữ MUST là một trong ba giá trị lưu được: `system`, `en`, `vi`; mặc định `system`. `system` MUST đi qua resolution của platform trên `supportedLocales` và MUST fallback về `en` khi không khớp. Lựa chọn tường minh MUST bền qua restart. Đổi ngôn ngữ MUST áp ngay trong cùng phiên chạy với đúng các ràng buộc của BR-SETTINGS-005, và MUST NOT đổi bất kỳ giá trị canonical nào được lưu — nhãn hiển thị MUST NOT trở thành dữ liệu (BR-STUDY-035). | db + UI | BR-STUDY-035, BR-SETTINGS-001, BR-SETTINGS-005 |
| BR-SETTINGS-007 | active | Mỗi lần lưu một tuỳ chọn MUST là **một** transaction và MUST là một submit độc lập: hỏng khi lưu theme MUST NOT ghi ngôn ngữ hay mặc định học. Lỗi MUST đi ra ngoài dưới dạng `Failure` có kiểu, MUST NOT là exception của tầng dữ liệu và MUST NOT lộ SQL, đường dẫn hay stack trace. Lần gửi thứ hai khi lần đầu chưa xong MUST bị bỏ qua. Lưu thất bại MUST giữ nguyên draft người dùng đang nhập và MUST tiếp tục hiển thị **giá trị đã persisted** cho các control còn lại; MUST NOT vẽ một giá trị chưa lưu như thể đã lưu. | store + UI | BR-SETTINGS-001 |
| BR-SETTINGS-008 | active | `Reset to defaults` MUST là hành động tường minh có xác nhận, MUST đưa toàn bộ giá trị của `app_settings` về mặc định trong một transaction, và MUST NOT đụng `deck.study_config`, tiến độ học, `card_schedule`, `review_log`, session, scheduler hay nội dung card. Copy MUST nói rõ phạm vi đó trước khi thực hiện — MUST NOT dùng từ ngữ khiến hành động này bị hiểu là Reset learning progress (BR-SRS-022). | store + UI | BR-SRS-022, BR-SETTINGS-001, BR-SETTINGS-003 |

---

## Validation rules

| Trường | Rule | Message hiển thị | Enforced by |
|---|---|---|---|
| app_settings.cardLimit | cùng bound với tùy chọn của deck (BR-STUDY-003, BR-SETTINGS-002) | như tùy chọn của deck — không có message riêng | rule |
| app_settings.themeMode | thuộc `system` \| `light` \| `dark` (BR-SETTINGS-005) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |
| app_settings.language | thuộc `system` \| `en` \| `vi` (BR-SETTINGS-006) | không có — control chỉ đưa ra ba lựa chọn hợp lệ | rule + db |

Toàn bộ enforce ở tầng nghiệp vụ vì chưa có server. Khi có backend, server validate lại — client validation là trải nghiệm, không phải bảo mật.
