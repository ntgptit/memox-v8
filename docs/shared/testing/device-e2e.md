# Kịch bản `DEVICE-E2E` trên thiết bị

Tám kịch bản mang profile `DEVICE-E2E` trong
[host-coverage-map.md](host-coverage-map.md) chạy trên một emulator hoặc điện
thoại Android bằng một lệnh. Thiết kế nằm trong
[spec FE-D3](../../superpowers/specs/2026-09-28-device-e2e-design.md). Lệnh
chạy tay, không nằm trong CI.

## Chạy

Cần có:

- `flutter` trên PATH;
- `adb` trên PATH hoặc trong `ANDROID_HOME`;
- đúng một thiết bị đang gắn, hoặc chỉ định bằng `-d`.

Script xoá dữ liệu của MemoX trên thiết bị ở đầu mỗi kịch bản.

```bash
tools/device/run_device_e2e.sh all
```

Có thể chạy một vài kịch bản:
`tools/device/run_device_e2e.sh IT-PLAT-002 IT-PLAT-004`.

- Script in `PASS <ID>` hoặc `FAIL <ID> (<bước>)` cho từng kịch bản, và thoát
  khác 0 khi có kịch bản hỏng.
- Khi một bước chờ hết giờ, phase chụp màn hình vào `build/device_e2e/<phase>.png`.
  Thông báo lỗi kèm các chữ đang hiện trên màn.

Chạy cả tám kịch bản mất khoảng 20 phút, vì mỗi phase build lại APK.

## Cách hoạt động

Một phase là một file trong `integration_test/`. Script làm các việc sau:

- **Chạy phase:**
  - Chạy từng phase bằng `flutter test <file> --no-uninstall`, nên app và dữ liệu
    còn nguyên sang phase sau.
  - Mỗi lần chạy, flutter tool kết thúc bằng `am force-stop`. Đó chính là lần
    process chết mà một kịch bản "đóng hẳn rồi mở lại" cần.
  - Trước mỗi phase, script xoá logcat và các `adb forward`. Nếu không, flutter tool
    có thể nối vào VM service đã chết của phase trước.
- **Đọc tín hiệu từ phase.** Phase in các dòng `MEMOX-E2E:` và script phản ứng:
  - `MEMOX-E2E: back`: script gửi `KEYCODE_BACK` thật của hệ điều hành.
  - `MEMOX-E2E: value KEY=VALUE`: script lưu giá trị và truyền cho các phase sau
    bằng `--dart-define=MEMOX_E2E_KEY=VALUE` (ví dụ id deck, mốc của phiên học).
  - `MEMOX-E2E: snap`: script chụp màn hình khi phase sắp báo lỗi.
- **Chế độ máy bay.** Script bật bằng `cmd connectivity airplane-mode`, và `trap`
  luôn tắt lại khi thoát.
- **Deep link và bản release.** Script mở deep link `memox://app/<route>` bằng
  `am start`, cài APK release, và kiểm màn hình bằng `uiautomator` (sau khi đặt
  ngôn ngữ của app là `en-US`).

Phase tìm chữ qua `AppLocalizations` của cây widget đang chạy, nên chạy được
với mọi ngôn ngữ thiết bị. Fixture được dựng qua UI như
[agent-execution-guide.md](agent-execution-guide.md) mô tả.

## Từng kịch bản

| ID | Phase | Việc do script làm |
|---|---|---|
| IT-PLAT-001 | `it_plat_001_cold_start`: khởi động nguội, Library trống với Create deck | Xoá dữ liệu |
| IT-PLAT-002 | `a_build_tree`: D-EB › D-BRANCH › D-LEAF, C-001 đổi nghĩa thành "rời bỏ" · `b_after_restart`: mọi thứ còn nguyên | Kill process giữa hai phase |
| IT-PLAT-003 | `a_start_session`: `SETUP-STUDY-EB-5-FULL`, Learn, hai lượt, gửi mốc · `b_resume`: Tiếp tục về đúng chế độ, thẻ và bộ đếm | Kill như hệ điều hành thu hồi |
| IT-PLAT-004 | `a_seed_deck`: D-EB, gửi id | Cài bản app đè bản test, rồi mở ba link: deck (Back về Library), deck không còn, đường dẫn lạ |
| IT-PLAT-005 | `system_back`: Back hệ thống → hỏi → Keep giữ nguyên → Back → Stop → "You left early"; màn vào học không còn Tiếp tục | Gửi `KEYCODE_BACK` |
| IT-PLAT-006 | — | Build APK release, cài lên máy sạch, mở từ launcher, thấy Library trống, logcat không có crash |
| IT-CONT-008 | `a_offline_session`: trọn một phiên Learn (5 chế độ) · `b_after_restart`: phiên đã xong, không còn thẻ mới | Chế độ máy bay suốt kịch bản |
| IT-NAV-007 | `a_offline_content`: tạo sub-deck, tạo, sửa, gắn cờ card · `b_after_restart`: còn nguyên, xoá card | Chế độ máy bay suốt kịch bản |

## Lần chạy gần nhất

Ngày 2026-09-28, emulator Android 16 (API 36, `google_apis_playstore`, x86_64),
nhánh `claude/fe-d3-device-e2e`: `tools/device/run_device_e2e.sh all`, 17 phút.

| ID | Kết quả |
|---|---|
| IT-PLAT-001 | PASS |
| IT-PLAT-002 | PASS |
| IT-PLAT-003 | PASS (mốc: Browse, thẻ 바다/sea, 3 / 5) |
| IT-PLAT-004 | PASS |
| IT-PLAT-005 | PASS |
| IT-CONT-008 | PASS (phiên Learn 21 lượt qua cả năm chế độ) |
| IT-NAV-007 | PASS |
| IT-PLAT-006 | PASS |

Chế độ máy bay tắt sau lần chạy (`airplane_mode_on` = 0).
