# X. Legacy · XI. Banned raw widgets · XIV. Static guard · XV. Admission rule

## 53. `ToggleButtonsThemeData`

Policy:

- [ ] Không dùng mới.
- [ ] Dùng `SegmentedButton`.
- [ ] Guard raw `ToggleButtons`.
- [ ] Không tạo Mx wrapper.

## 54. `ButtonThemeData`

Legacy theme used by old Material widgets.

Policy:

- [ ] Không dùng để style modern buttons.
- [ ] Không coi nó là action design system.
- [ ] Chỉ set fallback nếu legacy Flutter widget còn đọc nó.
- [ ] Không tạo shared wrapper dựa trên `ButtonThemeData`.

## XI. Raw widgets không nên có visual freedom ở feature layer

Guard trực tiếp trong `lib/features/**`. **Trạng thái hiện tại:** ba rule
phủ phần đánh dấu `[x]` — `no_raw_button`, `no_raw_widget` và
`no_raw_style_escape`. Mỗi mục thêm phải kèm lượt chạy chứng minh
**hai chiều**: rule bắn đúng site hiện có (hoặc một probe file cố ý vi phạm)
rồi về 0 — và đếm site phải dùng `[<(]` chứ không chỉ `\(`, vì
`RadioListTile<T>(` và `showModalBottomSheet<void>(` lọt lưới `\(` trần.

**Nhóm hoãn:** `TextField` và chips chưa vào danh sách cấm. Wrapper chỉ đáng
dựng khi nó chốt thêm một quyết định mà `InputDecorationTheme` hay `ChipTheme`
chưa chốt; khi chỉ chuyển code sang chỗ khác thì nó chưa đáng dựng.

**Regex theo dòng có lối thoát:** một lời gọi xuống dòng trước tham số
(`Icon(` rồi `color:` ở dòng sau) lọt qua pattern một dòng. Rule cần thấy
*cấu trúc* thì thành test Dart (quét ngoặc cân bằng), không cố nhồi vào regex.
`showModalBottomSheet` **không** vào danh sách cấm: hàm `showX` trong bucket
`overlays/` gọi nó trực tiếp, và đó là pattern hợp lệ (ADR-011 D8).

- [x] `FilledButton`
- [x] `OutlinedButton`
- [x] `TextButton`
- [x] `ElevatedButton`
- [x] `IconButton`
- [x] `FloatingActionButton`
- [x] `Card`
- [x] `ListTile`
- [x] `Checkbox`
- [x] `CheckboxListTile`
- [x] `Radio`
- [x] `RadioListTile`
- [x] `Switch`
- [x] `SwitchListTile`
- [ ] `ChoiceChip`
- [ ] `FilterChip`
- [ ] `ActionChip`
- [ ] `InputChip`
- [x] `SegmentedButton`
- [ ] `TextField`
- [x] `TextFormField`
- [x] `NavigationBar`
- [x] `NavigationDrawer`
- [x] `NavigationRail`
- [x] `BottomNavigationBar`
- [x] `BottomAppBar`
- [x] `Dialog`
- [x] `AlertDialog`
- [x] Direct `showDialog`
- [ ] Direct `showModalBottomSheet`
- [x] `PopupMenuButton`
- [x] `DropdownMenu`
- [x] `DropdownButton`
- [x] `SnackBar`
- [x] `MaterialBanner`
- [x] `SearchBar`
- [x] `SearchAnchor`
- [x] `Slider`
- [x] `RangeSlider`
- [x] `TabBar`
- [x] `ExpansionTile`
- [x] `Badge`
- [x] Direct interactive `InkWell`
- [x] Direct interactive `InkResponse`

Cho phép raw layout primitives: `Row`, `Column`, `Stack`, `Wrap`, `Flex`,
`Expanded`, `Flexible`, `Align`, `Center`, `Positioned`, `Padding`, `SizedBox`,
`Spacer`, `LayoutBuilder`, scrolling/layout primitives khi không tự mang
visual language.

## XIV. Feature layer static guard

Trong `lib/features/**`, fail CI nếu xuất hiện visual escapes như:

- [x] `Color(` — `no_raw_color` (design-token)
- [x] `Colors.` — `no_raw_color`
- [x] `TextStyle(` — `no_raw_text_style`
- [x] `BorderRadius.circular(` số trần — `no_raw_border_radius`
- [x] `BorderSide(` — `no_raw_style_escape`
- [x] `BoxShadow(` — `no_raw_style_escape`
- [x] `ButtonStyle(` — `no_raw_style_escape`
- [x] `.styleFrom(` — `no_raw_style_escape` (features), và
      `no_flat_style_from` scope `widget_ui_files` phủ cả `lib/shared/widgets`
- [x] `ShapeDecoration(` — `no_raw_style_escape`
- [x] `RoundedRectangleBorder(` — `no_raw_style_escape`
- [x] `Icon(size:` số trần — `no_raw_style_escape`
- [x] `WidgetStateProperty`/`MaterialStateProperty` — `no_raw_style_escape`
- [x] `fontWeight: FontWeight.` — `no_bare_font_weight`, scope rộng hơn
      (cả `lib/shared` và `lib/core/theme`), vì bug này không chỉ sống trong
      features
- [x] Raw interactive Material widgets — `no_raw_button` + `no_raw_widget`
- [x] `texts.*.copyWith` và `withWeight(...).copyWith` — `no_text_restyle`:
      feature đọc vai chữ, không pha style
- [x] `Icon(color:)` mở — `no_raw_icon_color`; `.resolve(` là cách
      viết hợp lệ duy nhất cho size ngoài bậc

Allowlist chỉ dành cho:

```
lib/core/theme/**
lib/shared/widgets/**
```

và exception phải có comment/rule ID.

**Chỗ đặt rule trong repo này:**
`code-verification-guard-v2/registries/projects/memox-v8/rules/memox-design-system-rules.yaml`,
scope `presentation_files` (không phải `ui_surfaces` — `lib/shared/` là nơi
primitives dựng raw widget hợp lệ). Ruleset `memox` cũ có rule tương tự nhưng
scope layer-first: load lại sẽ **xanh mà không match gì** — viết rule mới, đừng
trỏ manifest sang file cũ.

## XV. Admission rule cho raw Material widget mới

Trước khi feature được dùng một Material widget chưa support:

- [ ] Tìm ThemeData slot tương ứng.
- [ ] Xác định raw widget đọc những default nào — **đọc SDK thật**, đừng đoán:
      default có thể hardcode theo cặp màu cũ (`_FABDefaultsM3`) hoặc tự tổng
      hợp overlay (`IconButton.styleFrom`).
- [ ] Liệt kê các default không thể theme.
- [ ] Map color roles.
- [ ] Map typography.
- [ ] Map radius/shape.
- [ ] Map elevation.
- [ ] Map internal geometry.
- [ ] Map states.
- [ ] Map accessibility.
- [ ] Build shared wrapper nếu ThemeData không đủ.
- [ ] Add golden/state tests.
- [ ] Add raw-widget guard.
- [ ] Sau đó feature mới được sử dụng Mx component.

Không được:

> feature dùng raw trước → thấy xấu → override cục bộ → vài tháng sau mới nghĩ
> đến shared widget.

Luồng đúng:

> Design decision → token → ThemeData → shared widget → tests → feature.

**Ngoại lệ có kiểm soát — planned themes:** một theme cho component chưa render
được phép vào `ThemeData` khi và chỉ khi qua admission test ba điều kiện: chỉ
restate token đã quyết và đã đo; component có tên trong roadmap thật; M3
default sai theo cách đã xác lập.
