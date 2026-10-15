---
id: BR-TOPIK-020
title: Tổng quan tiến độ của một đề
status: active
summary: Overall Progress của một đề tính Sessions, Completed, Completion, Accuracy, Best, Average, Last activity và Total time theo công thức cố định; điểm chỉ lấy từ lượt đã nộp.
superseded_by:
---
## Rule

Phạm vi là một đề. Lượt đã nộp gồm cả lượt đồng bộ từ máy khác.

| Số | Công thức | Khi chưa có dữ liệu |
|---|---|---|
| Sessions | số lượt, mọi trạng thái | thẻ thành trạng thái rỗng có nút bắt đầu |
| Completed | số lượt `completed` | 0 |
| Completion | Completed / Sessions, phần trăm nguyên | — |
| Accuracy | Σ `correct_count` / Σ `question_count` trên lượt đã nộp, phần trăm nguyên | — |
| Best | `score` lớn nhất trên lượt đã nộp | — |
| Average | trung bình `score` trên lượt đã nộp, làm tròn nửa lên về số nguyên | — |
| Last activity | `updated_at` mới nhất, dạng thời gian tương đối | — |
| Total time | Σ `total_time_ms` trên mọi lượt | 0 giây |

Thẻ MUST ghi rằng điểm chỉ tính từ lượt đã nộp.

**Enforced by:** rule + UI
**Liên quan:** BR-TOPIK-013, BR-TOPIK-021, BR-TOPIK-025

## Lý do

Mỗi số cần một định nghĩa chốt trước; trộn lượt dở vào điểm làm Best và Average vô nghĩa.

## Ví dụ

Ba lượt đã nộp 80, 90, 85 và một lượt dở: Sessions 4, Completed 3, Completion 75%, Best 90, Average 85.

## Edge case

Trung bình 84.5 hiện 85.
