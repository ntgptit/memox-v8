# Master flow — memox (MVP)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Cho thấy các use case nối vào nhau thành hành trình nào, thứ mà đọc từng UC riêng lẻ không thấy được |
| **Scope** | Đồ thị chuyển tiếp giữa các UC có sơ đồ ở mục 2–5, và phân loại toàn bộ 22 UC theo đối tượng nghiệp vụ (mục 6). Ngoài phạm vi: nội dung của từng UC, mọi luật nghiệp vụ, và mọi chi tiết màn hình |
| **Source of truth for** | Đồ thị chuyển tiếp giữa các UC · điểm vào của từng luồng · đối tượng nghiệp vụ của từng UC |
| **Depends on** | `../document-conventions.md`, `product.md`, `../business-rules/`, `../use-cases/` |
| **Updated by** | `docs/superpowers/specs/2026-09-23-docs-restructure-design.md` — tách theo đối tượng, đánh số lại BR/UC |
| **Last updated** | 2026-09-23 |

---

## 1. Tài liệu này là gì, và không là gì

`../use-cases/` đặc tả **từng** UC đầy đủ chín mục. Nó cố ý không vẽ đồ thị nối
chúng lại, nên câu "sau khi tạo deck xong thì người dùng đi đâu" không có chỗ nào
trả lời — mỗi UC tự mô tả mình và im lặng về những UC bên cạnh.

Tài liệu này chỉ giữ **các cạnh của đồ thị đó**. Mọi đỉnh đều trỏ về một UC hoặc
một BR bằng ID.

**MUST NOT** đọc sơ đồ ở đây như một đặc tả. Theo `../document-conventions.md` §5,
luật nghiệp vụ sống ở `../business-rules/` và luồng sống ở `../use-cases/`; nhãn
trong sơ đồ là **rút gọn để đọc được**, không phải bản gốc. Khi sơ đồ và UC/BR
mâu thuẫn, **UC/BR thắng**, và sơ đồ sai là một defect phải sửa.

**Tách theo đối tượng, không theo hành động.** Mục 3–5 chia theo *deck*, *card*,
*review* — không có mục riêng cho "tạo deck" hay "xoá deck". Một tài liệu cho mỗi
hành động sẽ nhân số file theo số nút bấm, và phần lớn chúng sẽ chỉ có một sơ đồ
ba đỉnh.

---

## 2. Master flow — toàn app

Hành trình từ lúc mở app tới lúc vào được một phiên ôn tập. Nhánh nào đi sâu vào
một đối tượng thì dừng ở đó và tiếp tục ở mục tương ứng.

```mermaid
flowchart TD
    A["Mở app"] --> B["Khởi tạo database"]
    B -->|"Thất bại"| B1["Màn hình lỗi có nút thử lại · UC-STARTER-001 E1"]
    B --> C{"Đã có deck nào chưa?"}

    C -->|"Chưa"| D["Empty state, hai lối đi · UC-DECK-003 A1"]
    D -->|"Thư viện starter"| E["Chọn starter deck và chế độ ôn tập · UC-STARTER-001"]
    D -->|"Tạo deck mới"| F["Tạo root deck · UC-DECK-001"]

    C -->|"Rồi"| G["Danh sách deck kèm tiến độ · UC-DECK-003"]
    E --> G
    F --> G

    G --> H["Mở một deck"]
    H --> I{"content_type của deck"}
    I -->|"deck"| J["Danh sách deck con · UC-DECK-003 A3"]
    I -->|"card"| K["Danh sách card · UC-CARD-001"]
    I -->|"unset"| L["Deck rỗng, tạo được cả hai loại · UC-DECK-004"]

    J --> H
    L -->|"Tạo deck con"| J
    L -->|"Tạo card"| K

    H --> M["Quản lý deck: đổi tên, xoá, di chuyển · mục 3"]
    G --> N["Bắt đầu phiên ôn tập · mục 5"]
    K --> N
    N --> G
```

**`J --> H` là vòng lặp cố ý.** Deck lồng tới 10 cấp (BR-DECK-001) và một cấp bất kỳ
lại là "mở một deck" của cấp trên nó; màn hình là **một** màn đệ quy chứ không
phải hai màn khác nhau cho root và cho deck con.

---

## 3. Deck

Mọi thao tác trên cây deck. Điểm vào là một deck bất kỳ đang mở.

```mermaid
flowchart TD
    A["Một deck đang mở"] --> B{"Người dùng chọn gì"}

    B -->|"Bấm Create"| C{"Deck này là gì"}
    C -->|"root"| C1["Chỉ Create deck · BR-DECK-005"]
    C -->|"con · unset"| C2["Create card và Create deck · BR-DECK-007"]
    C -->|"con · card"| C3["Chỉ Create card · BR-DECK-012"]
    C -->|"con · deck"| C4["Chỉ Create deck · BR-DECK-012"]
    C1 --> D["Tạo phần tử con và xác lập content_type trong một transaction · UC-DECK-004"]
    C2 --> D
    C3 --> D
    C4 --> D
    D -->|"Cha đã ở cấp 10"| D1["Chặn trước khi ghi · UC-DECK-004 E4, BR-DECK-001"]
    D -->|"Huỷ giữa chừng"| D2["Không tạo gì và content_type không đổi · UC-DECK-004 A4"]
    D -->|"Thành công"| D3["Cây được vẽ lại"]

    B -->|"Đổi tên"| E["Validate rồi lưu · UC-DECK-002, BR-DECK-020"]

    B -->|"Xoá"| F["Xác nhận, nêu rõ số deck con và số card sẽ bị xoá vĩnh viễn · UC-DECK-002, BR-DECK-023"]
    F -->|"Đồng ý"| F1["Xoá cứng cả cây theo cascade, trong một transaction · BR-DECK-022 · Trash là sub-project sau, xem UC-TRASH-001"]
    F -->|"Huỷ"| F2["Không xảy ra gì · UC-DECK-002 A4"]

    B -->|"Di chuyển"| G{"Bốn phép kiểm, theo thứ tự · UC-DECK-005"}
    G -->|"Đích là chính nó hoặc descendant"| G1["Chặn · E1, BR-DECK-017"]
    G -->|"Đích có content_type card"| G2["Chặn · E2, BR-DECK-010"]
    G -->|"Root đích khác scheduler hoặc generation"| G3["Chặn, đề nghị reset tường minh · E3, BR-SRS-006"]
    G -->|"Vượt cấp 10"| G4["Chặn · E5, BR-DECK-001"]
    G -->|"Hợp lệ"| G5["Đổi parent và root_id toàn subtree trong một transaction · BR-DECK-018"]

    B -->|"Đưa content_type về unset"| H{"Deck có rỗng không"}
    H -->|"Không"| H1["Không có nhánh này: content_type do hệ thống tự duy trì · BR-DECK-015"]
    H -->|"Rỗng"| H2["Xác nhận rồi đặt unset · UC-DECK-002 A3"]

    B -->|"Đổi chế độ ôn tập · chỉ root"| I{"first_answered_at"}
    I -->|"NULL"| I1["Mở khoá: cảnh báo rồi khởi tạo lại study state toàn cây, generation giữ nguyên, session đang mở → invalidated · UC-DECK-002, BR-SRS-002, BR-SRS-004, BR-STUDY-016"]
    I -->|"Đã có"| I2["Khoá, hiện kèm lối đi sang Reset learning progress · UC-DECK-002 A1, BR-SRS-003"]
    I2 --> I3["UC-SRS-001 · mục 5"]
```

**Nhánh `I` là chỗ hai đối tượng gặp nhau.** Chế độ ôn tập là thuộc tính của deck
nhưng bị khoá bởi một sự kiện của review, nên đường thoát duy nhất khi đã khoá
nằm ở mục 5. Ẩn nó đi thay vì hiện trạng thái khoá là điều BR-SRS-003 cấm.

**`I1` và `I3` là hai thao tác, không phải một thao tác với hai cách gọi.** Cả hai
ghi scheduler và khởi tạo lại toàn cây; chỉ `I3` tiêu một generation, vì chỉ nó
vứt đi một chu kỳ học. Cho `I1` chạy qua Reset sẽ đánh số lịch sử rỗng thành "đã
bị thay thế" và bắt người dùng xác nhận một cảnh báo phá huỷ về thứ không tồn tại
(BR-SRS-002, UC-DECK-002).

**Ai đặt khoá ở `I`:** chính lần một thẻ hoàn tất chuỗi học mới, trong cùng
transaction với lần hoàn tất đó (mục 5, bước 10–11 của UC-STUDY-001; BR-SRS-003, BR-STUDY-053).
Không thao tác nào của deck ghi cột này.

---

## 4. Card

Điểm vào là một deck đã có `content_type = 'card'` (BR-DECK-009). Card **đầu tiên** của
một deck `unset` không đi qua đây — nó được tạo ở UC-DECK-004 và chính nó xác lập
`content_type`.

```mermaid
flowchart TD
    A["Deck có content_type = card"] --> B["Danh sách card · UC-CARD-001"]
    B -->|"Chưa có card nào"| B1["Empty state kèm hành động Thêm card · UC-CARD-001 A3"]

    B --> C{"Người dùng chọn gì"}

    C -->|"Thêm"| D["Nhập mặt trước và mặt sau"]
    D --> E{"Validate · BR-CARD-001, BR-CARD-002"}
    E -->|"Rỗng hoặc quá dài"| E1["Lỗi inline ở đúng ô · UC-CARD-001 E1, E2"]
    E -->|"Hợp lệ"| F["Tạo card và study state trong cùng transaction, theo scheduler của root · BR-CARD-004"]
    F -->|"Ghi thất bại"| F1["Hiện lỗi, giữ nội dung, không tạo card thiếu study state · UC-CARD-001 E3"]
    F -->|"Thành công"| G["Giữ form mở và xoá trống các ô · UC-CARD-001 A4"]
    G --> B

    C -->|"Chạm một hàng"| J["Chi tiết card, chỉ đọc · UC-CARD-002"]
    J --> J1["Lịch sử học phân trang keyset, nhóm theo generation · UC-CARD-002, BR-CARD-015, BR-CARD-017"]
    J -->|"Edit — action riêng, không phải cử chỉ chạm"| H
    J -->|"Back"| B

    C -->|"Sửa"| H["Đổi nội dung; study state và history không đổi · UC-CARD-001 A1, BR-CARD-005"]
    C -->|"Xoá"| I["Xác nhận, xoá kèm study state và history của card đó · UC-CARD-001 A2"]
    I --> I1["Card cuối cùng bị xoá → deck tự về unset trong cùng transaction · BR-DECK-015"]
```

**`J` đổi nghĩa của một lần chạm, và đó là cạnh dễ nhớ sai thứ hai ở đây.** Chạm
một hàng ở chế độ thường mở **chi tiết chỉ đọc**, không mở editor; đường tới
`H` đi qua một action `Edit` tường minh. Trong chế độ chọn nhiều thì chạm vẫn
chỉ là chọn/bỏ chọn và **không** có đường nào tới `J` (BR-CARD-020).

**`I1` là cạnh dễ vẽ sai nhất trong tài liệu này.** Xoá hết card **không** đưa
deck về `unset`; muốn đổi loại phải qua nhánh `H` ở mục 3, và đó là một hành động
do hệ thống tự duy trì cùng mutation direct children (BR-DECK-015).

**Card cũng mang cờ, tag và ba trường phụ (BR-CARD-009, BR-TAG-001, BR-TAG-002, BR-CARD-003), theo cùng luồng
Thêm/Sửa ở trên.**

---

## 5. Review

Hai UC dùng chung một đối tượng: phiên ôn tập (UC-STUDY-001) và việc đặt lại tiến độ học
(UC-SRS-001). Chúng nằm chung mục vì generation là thứ nối chúng — và là thứ khiến một
phiên đang mở có thể bị vô hiệu hoá từ màn khác.

```mermaid
flowchart TD
    A["Bấm ôn tập trên một deck"] --> B{"Còn thẻ đến hạn không · BR-STUDY-051, BR-STUDY-054"}
    B -->|"Không"| B1["Empty state tích cực kèm thời điểm đến hạn gần nhất; KHÔNG tạo session · UC-STUDY-001 E1, BR-STUDY-008"]
    B -->|"Còn"| C["Tạo study_session in_progress mang root_id và generation hiện tại · BR-SRS-025, BR-STUDY-010"]
    C --> D["Chọn Học mới hoặc Ôn tập · tối đa `card_limit` thẻ · BR-STUDY-051, BR-STUDY-003"]
    D --> E["Render nút đánh giá từ supportedActions: 2 với eight_box, 4 với sm2 · BR-STUDY-009"]
    E --> F["Hiện mặt trước và tiến độ phiên"]
    F --> G["Người dùng lật rồi chọn một action"]

    G --> H{"session.generation còn khớp root không · BR-SRS-026"}
    H -->|"Lệch"| H1["Từ chối ghi; session invalidated, end_reason stale_generation · UC-STUDY-001 E4, BR-STUDY-017"]
    H -->|"Khớp"| I{"Lượt đầu tiên của card này trong phiên"}
    I -->|"Đúng"| J["kind = scheduled: tính lịch mới rồi ghi history · BR-SRS-016"]
    I -->|"Không"| K["kind = relearning: chỉ cập nhật last_answered_at · BR-SRS-017"]

    J --> L{"Action có phải forgotten hoặc again"}
    K --> L
    L -->|"Đúng"| M["Card quay lại trong phiên sau ít nhất 3 card khác · UC-STUDY-001 A1, BR-STUDY-005"]
    L -->|"Không"| N["Card rời hàng đợi · BR-STUDY-007"]
    M --> F
    N --> O{"Hàng đợi còn card không"}
    O -->|"Còn"| F
    O -->|"Hết"| P["session completed, end_reason NULL; hiện tổng kết · BR-STUDY-013"]

    G -->|"Thoát giữa phiên"| Q["session abandoned, end_reason user_exit; mọi đánh giá đã ghi vẫn giữ · UC-STUDY-001 A3, BR-STUDY-014, BR-STUDY-019"]

    R["Đặt lại tiến độ học trên root · UC-SRS-001"] --> S["Xác nhận, nêu rõ giữ gì và mất gì; chọn chế độ mới ngay tại đây"]
    S --> T["Một transaction: generation +1, first_answered_at NULL, khởi tạo lại study state toàn cây, mọi session in_progress → invalidated · BR-SRS-020, BR-SRS-022, BR-SRS-024, BR-SRS-027, BR-STUDY-015"]
    T --> U["review_log giữ nguyên, mang generation cũ · BR-SRS-023"]
    T -.->|"Phiên đang mở ở màn khác"| H1
```

**Cạnh nét đứt `T -.-> H1` là lý do hai UC này ở chung một mục.** Reset chạy ở màn
hình A làm mọi phiên đang mở ở màn hình B hết hiệu lực; người dùng ở B chỉ biết
điều đó khi bấm đánh giá lần tiếp theo. Đọc riêng UC-STUDY-001 hoặc riêng UC-SRS-001 đều không
thấy được cạnh này.

---

## 6. UC theo đối tượng nghiệp vụ

Phân loại 22 UC theo đối tượng nghiệp vụ. Mục 2–5 chỉ vẽ sơ đồ cho các UC quanh deck, card, review và Trash (mục 2–5); bảng dưới đây phủ toàn bộ 22 UC, kể cả những UC
vốn không có sơ đồ riêng trong tài liệu này.

| UC | Đối tượng |
|---|---|
| UC-STARTER-001 | deck |
| UC-DECK-001 | deck |
| UC-DECK-002 | deck |
| UC-CARD-001 | card |
| UC-STUDY-001 | review |
| UC-DECK-003 | deck |
| UC-SRS-001 | review |
| UC-DECK-004 | deck |
| UC-DECK-005 | deck |
| UC-TRANSFER-001 | card |
| UC-TRANSFER-002 | card |
| UC-PROGRESS-001 | progress |
| UC-PROGRESS-002 | progress |
| UC-STUDY-002 | review |
| UC-STUDY-003 | review |
| UC-SETTINGS-001 | settings |
| UC-REMINDER-001 | settings |
| UC-TAG-001 | card |
| UC-CARD-002 | card |
| UC-SEARCH-001 | search |
| UC-TRASH-001 | trash |
| UC-DECK-006 | deck |
