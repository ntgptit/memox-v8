---
id: BR-PROGRESS-016
title: Current streak
status: active
summary: Current streak đếm ngày liên tiếp có hoạt động tính lùi từ anchor hôm nay hoặc hôm qua.
superseded_by:
---
## Rule

Current streak là số local day liên tiếp có hoạt động, tính lùi từ **anchor**: nếu hôm nay active thì anchor là hôm nay; nếu hôm nay chưa active nhưng hôm qua active thì anchor là hôm qua và chuỗi MUST được giữ nguyên (không reset về 0 chỉ vì hôm nay chưa học); nếu cả hai đều không active thì streak là 0. Streak MUST NOT có trần và MUST NOT bị cắt bởi cửa sổ bảy ngày của BR-PROGRESS-015.

**Enforced by:** store
**Liên quan:** BR-PROGRESS-011, BR-PROGRESS-013

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
