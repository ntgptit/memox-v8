---
feature: study
code: [lib/features/study/domain, lib/features/study/data, lib/features/study/di, lib/features/study/presentation]
depends_on: [card, deck, srs, study-mode]
---
## Phạm vi

Vòng đời phiên học, hàng đợi, round, Study Home (V8.0): mở, giữ và đóng phiên `learning`/`reviewing`, hành vi từng mode chấm điểm, và tab Study.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Tập StudyMode, chuỗi stage, chiều hỏi | Feature `study-mode` |
| Scheduler và reset | Feature `srs` |
