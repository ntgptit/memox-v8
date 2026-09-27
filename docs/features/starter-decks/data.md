# Starter decks — dữ liệu

Bảng riêng của feature. Bảng dùng chung và mọi invariant nằm ở [`shared/data/schema.md`](../../shared/data/schema.md).

## `deck_templates`

**Phạm vi:** Starter library, phần store (BE-B4, [spec](../../superpowers/specs/2026-09-26-starter-decks-backend-design.md) §5).

**Đây không phải bảng runtime** — template là asset JSON đi kèm bản build:

```
assets/templates/
├── manifest.json            {"templates": ["en/everyday_en_vi.json", …]}
└── en/
    ├── everyday_en_vi.json
    └── hangul_basics.json
```

`manifest.json` liệt kê các file template theo thứ tự thư viện hiện chúng. Mỗi file là
một template:

| Trường JSON | Ghi chú |
|---|---|
| `templateId` | ổn định giữa các phiên bản app (BR-STARTER-002) |
| `version` | số nguyên từ 1, tăng khi nội dung đổi; bản sao ghi version tại thời điểm sao chép (BR-STARTER-004) |
| `locale` | ngôn ngữ của chữ trong template (tên và tên deck): `en`, `vi`, … |
| `title` | tên hiển thị, cũng là tên root deck của bản sao |
| `contentSource` | nguồn gốc nội dung, cho ghi công và kiểm tra bản quyền |
| `frontLanguage`, `backLanguage` | thẻ BCP 47 của hai mặt card (`en`, `vi`, `ko`, `ko-Latn`) |
| `defaultScheduler` | `eight_box` hoặc `sm2`: scheduler gợi ý; người dùng chọn khi thêm (BR-STARTER-004), đổi được trước lượt học đầu |
| `decks` | các deck con của root, theo thứ tự |

Template mô tả **cả cây deck**, không chỉ một danh sách card, vì bản sao phải
dựng lại đúng cấu trúc `content_type` và `root_id`. Mỗi deck có `name` và **hoặc**
`decks` **hoặc** `cards`, không cả hai và không danh sách rỗng; cây sâu tối đa 10 cấp kể
cả root (BR-DECK-001). Mỗi card có `front`, `back` và có thể có `example`, `hint`,
`pronunciation`, theo đúng luật card (BR-CARD-001…BR-CARD-003).

Manifest thiếu hoặc hỏng thì thư viện rỗng (UC-STARTER-001 E2). Một file thiếu, hỏng,
sai một luật trên, hoặc trùng `templateId` với file trước, thì bị bỏ qua và các template
khác vẫn hiện (E3).

## Fixture hiện có

| Template | `templateId` | Deck con | Card | Gợi ý |
|---|---|---|---|---|
| English → Vietnamese · Everyday | `fixture.everyday-en-vi` | Greetings, Food & drink, Travel, Home (mỗi deck 10) | 40 | Eight boxes |
| Korean → Romanisation · Hangul basics | `fixture.hangul-basics` | Consonants (14, tên chữ ở `hint`), Vowels (10) | 24 | SM-2 |

Nội dung starter hiện tại là **fixture do dự án tự tạo, chỉ phục vụ development
và test** (BR-STARTER-010); `contentSource` của cả hai là "Development fixture". Không mô
tả nó như nội dung production ở bất kỳ đâu — UI, store listing, hay tài liệu.
