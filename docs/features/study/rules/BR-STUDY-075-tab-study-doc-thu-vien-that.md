---
id: BR-STUDY-075
title: Tab Study đọc thư viện thật
status: active
summary: Tab Study đọc thư viện thật, không phụ thuộc deck id cố định, và không ghi database.
superseded_by:
---
## Rule

Tab Study MUST đọc thư viện thật và MUST NOT phụ thuộc vào bất kỳ deck id cố định nào trong production. Vào tab, cuộn, đổi tab và stream tự refresh MUST NOT ghi database: MUST NOT tạo session, MUST NOT khoá scheduler (BR-SRS-003), MUST NOT materialize hàng đợi. Chỉ thao tác chạm tường minh của người dùng mới được dẫn tới write. Resume card MUST chỉ hiện khi tồn tại một session thoả **đồng thời** bốn điều kiện, tất cả kiểm bằng đọc: `status = in_progress`; `started_at` thuộc ngày học hiện tại theo mốc BR-STUDY-074; generation của root khớp generation của session (BR-STUDY-017); và hàng đợi của session còn ít nhất một hàng. Session không thoả MUST NOT được quảng cáo; việc **đóng** session của ngày cũ vẫn thuộc `abandonStaleSessions` (BR-STUDY-072) và MUST NOT chuyển vào màn hình này. Chạm Resume MUST mở đúng session và đúng lượt đã lưu (BR-STUDY-036), MUST NOT tạo session thứ hai. Nhiều session cùng mở thì MUST chọn session mới nhất theo `started_at`. Chạm hai lần liên tiếp MUST chỉ dẫn tới một lần mở.

**Enforced by:** store + UI
**Liên quan:** BR-STUDY-017, BR-STUDY-020, BR-STUDY-072, BR-STUDY-036

## Lý do

Study Home đọc đúng thư viện của người dùng thay vì một fixture (UC-STUDY-002). Các rule dưới đây **không** phát biểu lại luật mở phiên (BR-STUDY-004), luật đến hạn (BR-STUDY-051) hay luật ngày học (BR-STUDY-074).

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
