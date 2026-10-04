---
feature: study
code: [lib/features/study/domain, lib/features/study/data, lib/features/study/di, lib/features/study/presentation]
depends_on: [card, deck, srs, study-mode]
---
## Phạm vi

Vòng đời phiên học, hàng đợi, round, Study Home (V8.0): mở, giữ và đóng phiên `learning`/`reviewing`, hành vi từng mode chấm điểm, và tab Study.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tab Study (Study Home) | UC-STUDY-002 |
| Study Entry của một deck | UC-STUDY-001, UC-STUDY-003 |
| Phiên học / phiên ôn tập | UC-STUDY-001 |

Nguồn: trigger của UC-STUDY-001 ("bấm Study trên một deck"), UC-STUDY-002 ("Chạm tab Study, deep link `/study`"), UC-STUDY-003 ("Bấm `Review` ở Study Entry của một deck chạy `sm2`"); sơ đồ ở [`ui.md`](ui.md).

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Tập StudyMode, chuỗi stage, chiều hỏi | Feature `study-mode` |
| Scheduler và reset | Feature `srs` |
