---
id: BR-SRS-011
title: sm2: cập nhật interval và repetitions
status: active
summary: `sm2`: cập nhật `interval_days` và `repetitions` bằng ease factor đã cập nhật của chính lượt đó.
superseded_by:
---
## Rule

```
ease_factor = <giá trị mới theo BR-SRS-012>      ← chạy TRƯỚC

nếu q < 3:
    repetitions = 0
    interval_days = 1
ngược lại:
    nếu repetitions == 0: interval_days = 1
    nếu repetitions == 1: interval_days = 6
    ngược lại:            interval_days = round(interval_days * ease_factor)
    repetitions = repetitions + 1
```

`next_due_at` = đầu ngày học thứ `interval_days`, theo đúng BR-STUDY-074 như `eight_box`.

**Thứ tự là một phần của luật, không phải chi tiết triển khai.** `ease_factor`
trong phép nhân MUST là giá trị **sau** khi BR-SRS-012 đã chạy cho chính lượt này —
không phải giá trị thẻ mang vào lượt. Hai cách đọc chỉ khác nhau ở những action
làm đổi hệ số: với `good` (q=4) hệ số không đổi nên không phân biệt được, còn
`hard` (q=3) hạ 2.5 xuống 2.36, và một thẻ đang ở interval 10 ngày nhận 24 ngày
theo luật này thay vì 25.

**Enforced by:** rule

## Lý do

Bản đầu của tài liệu không nói thứ tự, nên từng có một lần triển khai theo cách
đọc sát chữ — nhân với hệ số cũ — và chủ dự án chốt lại hướng ngược lại. Ghi thẳng vào đây
thay vì để trong commit message, vì đây đúng là loại mơ hồ mà người đọc kế tiếp
sẽ tự suy lại và suy khác.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
