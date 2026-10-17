---
id: BR-TOPIK-008
title: Đề không hợp lệ bị loại khi nạp
status: active
summary: Một bộ kiểm tra nội dung duy nhất chạy ở app và ở gate; đề vi phạm bị loại khỏi mọi danh sách, ghi log, và không chặn đề khác.
superseded_by:
---
## Rule

Mọi đề MUST qua cùng một bộ luật kiểm tra, mà bản tham chiếu là `checkTopikTest` trong `lib/features/topik/domain/models/topik_content_check_model.dart` (thuần Dart), trước khi xuất hiện ở đâu. Từ [ADR-024](../../../shared/decisions/ADR-024-master-data-topik-tren-supabase-va-admin-web.md) có ba cổng kiểm cùng một bộ luật, chứng minh bằng cùng bộ fixture: Dart ở app (cổng cuối), SQL khi publish, TypeScript ở Admin Web:

- **App:** đề vi phạm bất kỳ rule nào của BR-TOPIK-001…BR-TOPIK-007 hoặc thiếu file audio, ảnh MUST bị bỏ qua, ghi log cảnh báo kèm id đề và rule vi phạm đầu tiên, và không hiện trong danh sách nào. Các đề còn lại vẫn nạp. Nội dung lỗi MUST NOT làm app crash hay hiện màn lỗi.
- **Gate:** `test/tools/topik_content_assets_test.dart` duyệt mọi gói dưới `assets/topik/` bằng cùng bộ kiểm tra qua `tools/topik/topik_lint.dart`; gói vi phạm không merge được. `testId` trùng giữa hai file: file thứ hai bị loại. (Cho tới khi plan 2 của ADR-024 bỏ `assets/topik/`; sau đó gate kiểm fixture và validator.)
- **Publish (ADR-024):** `topik_admin_publish` từ chối đề vi phạm các luật hình dạng (BR-TOPIK-001…004, 006, 007) bằng `VALIDATION_FAILED`; app vẫn kiểm lại mọi đề tải về trước khi vào cache.

**Enforced by:** rule
**Liên quan:** BR-TOPIK-001, BR-TOPIK-002, BR-TOPIK-003, BR-TOPIK-004, BR-TOPIK-005, BR-TOPIK-006, BR-TOPIK-007

## Lý do

Hai bộ kiểm tra sẽ lệch nhau theo thời gian; một bộ dùng chung bảo đảm cái gate chặn đúng là cái app từ chối. Điểm sai trên một đề còn tệ hơn không có đề đó.

## Ví dụ

Gói có `topik1-96-listening` hợp lệ và `topik2-96-listening` tổng điểm 98: danh sách TOPIK I hiện đề kỳ 96, danh sách TOPIK II không có đề nào và hiện trạng thái rỗng.

## Edge case

File audio của đề nghe không có trong bundle: đề bị loại, không có nút bắt đầu dẫn tới lỗi phát.
