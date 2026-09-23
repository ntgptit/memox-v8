---
id: BR-MODE-007
title: stageSequence do thuật toán khai báo
status: active
summary: Chuỗi stage do thuật toán SRS của root khai báo qua `stageSequence`, không hardcode ở UI.
superseded_by:
---
## Rule

Chuỗi stage MUST do **thuật toán SRS của root deck** khai báo qua `stageSequence` (BR-MODE-004). MUST NOT hardcode ở UI.

**Enforced by:** rule
**Liên quan:** BR-STUDY-009, BR-MODE-004

## Lý do

**Vì sao tập mode thuộc thuật toán chứ không thuộc deck.** Bốn mode chấm điểm
sinh tín hiệu **nhị phân** — đúng hoặc sai. `eight_box` nhận đúng hai
action (`forgotten`/`remembered`) nên ánh xạ là một-một. `sm2` cần bốn mức, và
một nguồn nhị phân chỉ nuôi được hai trong bốn; ease factor sẽ trôi hẹp dần theo
BR-SRS-012 mà không có gì báo. Nên `sm2` giữ đúng `self_assess`, và điều đó là **thuộc tính
của thuật toán**, không phải một hạn chế tạm thời của UI.

Hệ quả trực tiếp: `stageSequence` đứng cạnh `supportedActions` trên cùng
abstraction, vì cả hai trả lời cùng một câu hỏi — "thuật toán này cho phép người
dùng làm gì". BR-STUDY-009 đã cấm hardcode tập action; BR-MODE-007 là đúng câu đó cho tập mode.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
