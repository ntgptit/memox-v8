---
id: BR-MODE-013
title: Điều kiện chọn chiều hỏi
status: active
summary: Chọn chiều hỏi chỉ khả dụng khi phiên `reviewing`, scheduler `sm2` và mode `self_assess`.
superseded_by:
---
## Rule

Việc chọn **chiều hỏi** MUST chỉ khả dụng khi cả ba điều kiện cùng đúng: phiên `reviewing` (BR-STUDY-051), scheduler của root deck là `sm2` (BR-DECK-025), và mode là `self_assess` (BR-STUDY-055). Mọi tổ hợp khác — `eight_box` ở bất kỳ mode nào, chuỗi học mới (BR-MODE-003), `match`/`guess`/`recall`/`fill` — MUST NOT nhận chiều hỏi: MUST NOT hiện UI chọn chiều, MUST NOT nhận giá trị chiều khi mở phiên, và MUST NOT ghi chiều xuống bất kỳ bảng nào. Điều kiện này MUST là **một predicate duy nhất trong tầng nghiệp vụ**, MUST NOT viết lại ở UI.

**Enforced by:** rule + UI
**Liên quan:** BR-MODE-011, BR-MODE-003, BR-MODE-004, BR-STUDY-051, BR-STUDY-055

## Lý do

**Vì sao chỉ `sm2` × `reviewing` × `self_assess`.** `self_assess` là mode duy
nhất mà đổi chiều chỉ đổi **mặt nào là đề** và không đổi thứ được chấm. Bốn mode
còn lại dựng nội dung từ một mặt cố định: `fill` chấm bằng `front_folded`
(BR-STUDY-026), `guess` phân biệt nghĩa bằng `back_folded` (BR-STUDY-039), `match` ghép hai
mặt với nhau. Đảo chúng là đổi **cái được chấm**, không phải đổi cách hỏi.
`eight_box` không chạy `self_assess` trong phiên ôn (BR-MODE-004, BR-STUDY-055) nên không có
bề mặt nào để đảo. Phiên học mới đi theo chuỗi stage cố định người dùng không
chọn (BR-MODE-003), và bắt người học tạo ra một từ họ chưa từng thấy không phải là câu
hỏi khó hơn — nó là câu hỏi không trả lời được.

## Ví dụ

Không áp dụng

## Edge case

| Case | Expected behaviour |
|---|---|
| Deck `eight_box` nhận yêu cầu kèm chiều hỏi | Từ chối là conflict; không có UI nào tạo được yêu cầu đó (BR-MODE-013, BR-MODE-018) |
