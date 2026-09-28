# XII. Shared Widget Construction Template · XIII. Parity Test

Mỗi `Mx*` widget mới phải đi qua checklist này.

## A. Purpose

- [ ] Có raw Material widget cụ thể bên dưới.
- [ ] Có ít nhất một real product use case.
- [ ] Component semantic purpose được mô tả trong một câu.
- [ ] Không phải wrapper chỉ để đổi tên raw widget.

## B. Public API

- [ ] Required parameters chỉ chứa content/business state.
- [ ] Variant names theo meaning.
- [ ] Không expose raw Flutter `style`.
- [ ] Không expose arbitrary colors.
- [ ] Không expose arbitrary radius.
- [ ] Không expose arbitrary shadow.
- [ ] Không expose arbitrary border.
- [ ] Không expose arbitrary internal padding.
- [ ] Không expose arbitrary font.
- [ ] Không expose arbitrary icon size.
- [ ] Không forward toàn bộ constructor của Flutter widget.

## C. Variants

Mỗi variant phải trả lời:

- [ ] Meaning là gì?
- [ ] Khi nào dùng?
- [ ] Khi nào không dùng?
- [ ] Fill role nào?
- [ ] Ink role nào?
- [ ] Border role nào?
- [ ] Elevation level nào?
- [ ] Radius nào?
- [ ] Typography nào?

Nếu không trả lời được khác biệt semantic, không tạo variant.

## D. States

Với state applicable: resting, hovered, focused, pressed, selected, disabled,
error, loading.

Mỗi state phải xác định: fill, ink, border, shadow/elevation, icon, semantics.

## E. Geometry

- [ ] Painted height.
- [ ] Touch target.
- [ ] Horizontal padding.
- [ ] Vertical padding.
- [ ] Icon size.
- [ ] Icon-label gap.
- [ ] Border width.
- [ ] Radius.
- [ ] Minimum width.
- [ ] Maximum width nếu relevant.
- [ ] Alignment.
- [ ] Multiline behavior.
- [ ] Overflow behavior.

Không để caller tự đoán.

## F. Typography

- [ ] TextTheme rung.
- [ ] Weight — qua `AppTypography.withWeight`, không `copyWith(fontWeight:)`
      trần: variable font đọc trục `wght`, không đọc `fontWeight`.
- [ ] Line height.
- [ ] Max lines.
- [ ] Overflow.
- [ ] TextScaler behavior.
- [ ] Không `.copyWith(fontSize:)` tùy ý.

## G. Color

- [ ] Resting pair contrast.
- [ ] Selected pair contrast.
- [ ] Focus indicator contrast.
- [ ] Error pair.
- [ ] Disabled appearance.
- [ ] Light.
- [ ] Dark.
- [ ] High contrast.
- [ ] No accidental raw hex.

## H. Interaction

- [ ] Tap.
- [ ] Keyboard.
- [ ] Hover.
- [ ] Focus-visible.
- [ ] Press.
- [ ] Disabled interaction blocked.
- [ ] Loading interaction blocked nếu applicable.
- [ ] Focus order.
- [ ] Mouse cursor nếu web/desktop.

## I. Accessibility

- [ ] ≥48×48 target.
- [ ] Semantic role.
- [ ] Accessible name.
- [ ] Selected/toggled state announced.
- [ ] Disabled state announced.
- [ ] Progress value announced.
- [ ] Destructive meaning không chỉ bằng màu.
- [ ] Text scale 2.0.
- [ ] RTL.
- [ ] TalkBack traversal.

## J. Composition

- [ ] Widget không biết domain entity.
- [ ] Feature-specific entity component build trên shared widget.
- [ ] Internal spacing owned by shared widget.
- [ ] External spacing owned by caller.
- [ ] Nested shared components không override nhau bằng style hacks.

## K. Tests

Mỗi shared widget:

- [ ] Unit/theme contract test.
- [ ] Light golden.
- [ ] Dark golden.
- [ ] Selected golden nếu applicable.
- [ ] Disabled golden.
- [ ] Focused golden.
- [ ] Pressed/hover screenshot nếu web important.
- [ ] TextScaler 2.0.
- [ ] 320px narrow width.
- [ ] RTL nếu có text/icon direction.
- [ ] Semantics test.
- [ ] 48×48 accessibility guideline.
- [ ] Contrast test cho critical pairs.
- [ ] No raw token/style override test nếu có thể static-analyze.

---

# XIII. Theme ↔ Shared Widget Parity Test

Cho mỗi component pair:

```
TextButtonTheme         ↔ MxButton (mọi tone: primary, secondary, outline,
                          destructive, dangerSoft, warning; TextButton +
                          appButtonStyle)
FilledButtonTheme       ↔ — (slot có trong app_theme.dart; V8 không có Mx riêng,
OutlinedButtonTheme     ↔    MxButton phủ cả hai)
IconButtonTheme         ↔ MxIconButton
InputDecorationTheme    ↔ MxTextField / MxSearchField
DialogTheme             ↔ MxDialog + showMxDialog
BottomSheetTheme        ↔ MxBottomSheet
SnackBarTheme           ↔ showMxSnackbar
CardTheme               ↔ MxCard            (chưa có slot trong app_theme.dart)
ListTileTheme           ↔ MxListRow         (chưa có slot)
ChipTheme               ↔ MxFilterChip / MxTagChip / MxChipTrigger (chưa có slot)
NavigationBarTheme      ↔ MxBottomNav       (không dùng NavigationBar; chưa có slot)
CheckboxTheme           ↔ MxSelectionCheckbox (chưa có slot)
RadioTheme              ↔ MxOptionRow       (chưa có slot)
SwitchTheme             ↔ MxToggle          (chưa có slot)
ProgressIndicatorTheme  ↔ MxSpinner / MxLinearProgress / MxSkeleton* (chưa có slot)
SegmentedButtonTheme    ↔ MxSegmentedTray   (chưa có slot)
PopupMenuTheme          ↔ — (chưa dựng)
SliderTheme             ↔ — (chưa dựng)
TabBarTheme             ↔ — (chưa dựng)
```

Test:

- [ ] Shared widget không vô tình override resting theme bằng một giá trị khác.
- [ ] Nếu override thì phải vì Theme API không thể biểu diễn requirement.
- [ ] Override phải lấy token/theme semantic, không raw constant.
- [ ] Bare raw widget và Mx wrapper phải cùng family.
- [ ] Wrapper chỉ làm contract chặt hơn, không tạo một design system thứ hai.

**Kỹ thuật đo trong test parity:** khi ownership màu nằm ở theme, probe phải
resolve theo đúng thứ tự Material dùng — widget style trước, theme sau
(`style?.x?.resolve(...) ?? theme.<slot>.style?.x?.resolve(...)`). Một test
chỉ đọc property trên widget sẽ gãy đúng lúc widget làm điều phải làm: thôi
mang màu riêng.
