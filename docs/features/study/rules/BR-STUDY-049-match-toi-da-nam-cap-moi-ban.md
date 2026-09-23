---
id: BR-STUDY-049
title: match: tối đa năm cặp mỗi bàn
status: active
summary: `match` bày tối đa năm cặp một lúc, chia round thành các bàn liên tiếp theo `position`.
superseded_by:
---
## Rule

`match` MUST bày **tối đa năm cặp** một lúc. Một round MUST được chia thành các bàn liên tiếp theo thứ tự `position` của round đó (BR-STUDY-061); bàn cuối lấy phần dư và **MAY chỉ có một cặp**. Một thẻ MUST ở nguyên bàn được chia cho nó trong suốt round. Bộ đếm và thanh tiến trình trên thanh header MUST đo **cả round**, không phải bàn. Sàn hai cặp của BR-STUDY-045 MUST được áp cho **stage**, không cho từng bàn.

**Enforced by:** rule + UI
**Liên quan:** BR-STUDY-059, BR-STUDY-061, BR-STUDY-045

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
