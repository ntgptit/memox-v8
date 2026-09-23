---
id: BR-PROGRESS-013
title: Định nghĩa "hôm nay" của Progress
status: active
summary: "Hôm nay" là `[startOfToday, startOfTomorrow)` theo ranh giới ngày học, dựng từ một snapshot.
superseded_by:
---
## Rule

"Hôm nay" của Progress là nửa khoảng `[startOfToday, startOfTomorrow)` theo đúng ranh giới ngày học cục bộ của BR-STUDY-074, dựng từ **một** snapshot của `clockProvider` và `utcOffsetProvider`. Mọi con số của một lần hiển thị — Today, Last 7 days, streak — MUST đến từ cùng snapshot đó; MUST NOT có hai lần đọc đồng hồ trong một emission, và SQL MUST NOT tự dẫn xuất local midnight.

**Enforced by:** store
**Liên quan:** BR-STUDY-074

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Mở màn hình tiến độ lúc 23:59 rồi để yên | Nửa đêm địa phương, cửa sổ trượt một ngày và màn hình tự đọc lại (BR-PROGRESS-013, BR-PROGRESS-018) |
