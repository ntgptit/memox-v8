---
id: BR-STUDY-031
title: recall: 20 giây tương tác
status: active
summary: `recall` cho tối đa 20 giây mỗi lượt, đo thời gian tương tác thực.
superseded_by:
---
## Rule

`recall` MUST cho tối đa **20 giây** mỗi lượt, đo bằng thời gian tương tác thực: MUST tạm dừng khi app vào nền hoặc bị ngắt, và MUST NOT tính thời gian tải nội dung.

**Enforced by:** rule + UI

## Lý do

**Đếm giờ là input, không phải thứ nghiệp vụ tự đọc.** Nghiệp vụ MUST NOT tự đọc
đồng hồ hệ thống. Handler của `recall` nhận `didTimeout` và `elapsedMs` như input
và vẫn là một hàm thuần.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
