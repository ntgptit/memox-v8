---
id: BR-STUDY-038
title: Nguồn distractor
status: active
summary: Distractor lấy từ thẻ đã học xong hoặc đang trong phiên, cùng cây deck, khác thẻ đang hỏi.
superseded_by:
---
## Rule

Distractor MUST lấy từ thẻ **đã học xong** (`learned_at IS NOT NULL`) **hoặc đang trong phiên hiện tại**, trong cùng cây deck. Mỗi distractor MUST tham chiếu một thẻ khác thẻ đang hỏi.

**Enforced by:** rule
**Liên quan:** BR-STUDY-059, BR-STUDY-037, BR-STUDY-051

## Lý do

**BR-STUDY-038 đã đổi nguồn, và lý do nằm ở phiên ôn tập.** Một phiên ôn có thể chỉ có
ba thẻ đến hạn — lấy distractor từ phạm vi đó thì không bao giờ đủ năm nghĩa và
`guess` gần như luôn bị vô hiệu hoá, dù deck có hai trăm thẻ đã học. Nguồn đúng là
**thẻ đã học xong trong cây**: người học đã gặp chúng nên chúng là nhiễu thật, và
thẻ chưa học không bị lộ nội dung trước khi đến lượt nó.

**BR-STUDY-038 tách hai khái niệm dễ bị gộp.** *Hàng đợi* là những thẻ đang được hỏi ở
round này; *tập thẻ của phiên* là nguồn lấy distractor. Chúng khác nhau, và gộp
lại thì retry round còn một thẻ sẽ không đủ năm lựa chọn — đúng ca mà BR-STUDY-059 tạo ra
thường xuyên nhất. Thẻ đã đạt rời hàng đợi nhưng **không** rời tập nguồn.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
