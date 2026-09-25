# Card Editor Fields From Common Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make screen 08/09's fields consistent and kit-true by fixing the shared field and type roles they are built from.

**Architecture:** The fixes land in common code:
- `MxTextField` gains a semantic `label` and a `variant` (form · detail · meaning · term) that owns each kit geometry and type role. `isMultiline` goes away.
- The caption role loses its 1.2 px tracking. The two roles the kit tracks (the study mode badge at 1.2, the field count at 0.2) set it explicitly.
- The card feature then adopts the variants and a kit-shaped "Add details" disclosure.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3, gen-l10n, flutter_test goldens.

**Spec:** the Impeccable audit of 2026-09-25 (conversation), scored 14/20, with findings P1-1..3 and P2-4..6. The kit sources it cites are:
- `FlashcardCreateScreen`, `FlashcardEditScreen`;
- `CardFieldBlock` (`FieldHeader`, `OptionalField`);
- `FieldMessage`, `BottomBar`, `Note`, `InlineBanner`, `OptionRow`, `StudyTopBar`.

These are the V3 kit modules (artifact UCesgHkzYHKsZwhwVshKRE). The widget contract is `docs/shared/ui/design-handoff/widgets/text-field.md`.

## Global Constraints

- **Guard `memox-v8` must stay 0/0:**
  - no `Icon(color:)` (use `IconTheme.merge`);
  - no per-site `textStyles.x.copyWith` (add a role to `MxTextStyles`);
  - no user literal strings;
  - no `BorderSide(` in feature code;
  - no `ref.read` in build;
  - `max_build_lines`.
- **Goldens:** only from the Linux container (`golden.Dockerfile`, `TZ=UTC`). On Windows run `flutter test --exclude-tags golden` and never `--update-goldens`.
- **Kit precedence:** a BR/UC beats the kit, and the kit beats a UI spec. Every deviation goes into the UI-base register §9, starting at row 99.
- **Accessibility:** WCAG 2.2 AA; 48 dp touch targets; layouts hold at text scale 2.
- **Copy:** in ARB files (en + vi). Components hold no copy.

## Kit values (binding for this plan)

| Field | Box | Padding | Min height | Radius | Fill | Value text | Placeholder |
|---|---|---|---|---|---|---|---|
| form (dialogs, tag entry) | TextField contract | 0 12 | 52 | 12 | resting `surfaceContainerLow`, focused `surfaceContainerLowest` | 14/400 | 14/400 |
| detail (example, hint, pronunciation) | `OptionalField` | 8 12 | 40 | 12 | `surfaceContainerLowest` | 14/400, lh 1.45 | 14/400 |
| meaning (back) | editor `.card` | 12 16 | 76 | 20 | `surfaceContainerLowest` | 16/500, lh 1.45 | 14/400 |
| term (front) | editor `.card` | 16 16 | 66 | 20 | `surfaceContainerLowest` | 24/700, lh 1.25, tracking −0.4; 18/700 over 30 chars | 16/500 |

All four fields share the same edges: a ghost border at rest, a primary border on focus, an error border in error, and an `MxFieldMessage` below.

**Kit tracking** (12 px text):
- no tracking: `FieldMessage`, `BottomBar` caption, `Note`, `InlineBanner` title and message, `OptionRow` sub, the "· optional" suffix, the `StudyTopBar` counter;
- `FieldHeader` count: 0.2;
- overline: 0.6 (already set);
- study mode badge: 1.2.

The 1.2 px in the foundations table only appears on the kit's documentation chrome (`phone-label`, `seg-label`, `theme-label`).

## Review Focus

1. **A 60-character term.** It wraps inside the term box, drops to 18/700, and nothing scrolls sideways out of view. Pinned in Task 2.
2. **TalkBack on a filled field.** It announces the field's label, not only its value. Pinned in Task 1.
3. **Text scale 2.** Term, meaning, detail and the disclosure all grow with the text, with no overflow. Pinned in Tasks 2 and 4.
4. **The Enter key in the term field.** It moves focus to the back field and inserts no newline, even though the box wraps. Pinned in Task 2.
5. **A field message under any variant.** It sits below the box, with no tracking, and pushes the following content down. Pinned in Tasks 2 and 3.

---

### Task 1: `MxTextField` semantic label

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_field_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_tag_editor_widget.dart`, `lib/features/card/presentation/widgets/overlays/card_tag_dialog_widget.dart`, `lib/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart`, `lib/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart` (pass the label they already show or hint)
- Test: `test/shared/widgets/mx_text_field_test.dart`, `test/features/card/presentation/card_editor_blocks_test.dart`

**Interfaces:**
- Produces: `MxTextField({String? label, ...})`. `label` is the field's accessible name, announced with the value. It is never painted.

- [ ] **Step 1: Write the failing test** (`mx_text_field_test.dart`):

```dart
testWidgets('a filled field keeps its name for TalkBack', (tester) async {
  final handle = tester.ensureSemantics();
  await pumpMx(
    tester,
    MxTextField(
      label: 'Front',
      hintText: 'The term',
      controller: TextEditingController(text: 'gamsa'),
    ),
  );
  final node = tester.getSemantics(find.byType(EditableText));
  expect(node.label, contains('Front'));
  expect(node.value, 'gamsa');
  handle.dispose();
});
```

- [ ] **Step 2: Run it.** Run `flutter test test/shared/widgets/mx_text_field_test.dart`. Expected: FAIL; `label` is not a parameter.

- [ ] **Step 3: Implement.** Add `final String? label;` and wrap the `TextField`:

```dart
final named = label == null
    ? field
    : Semantics(label: label, textField: true, child: field);
```

Use `named` in the column. If the test shows the label on a separate node instead of the `EditableText`'s, use `MergeSemantics(child: Semantics(label: label, child: field))`. The test decides which.
- `CardFieldWidget` passes `label: label` to its `MxTextField`.
- `CardFieldWidget` wraps its header's label `Text` in `ExcludeSemantics`, so TalkBack does not read the name twice. It keeps "Required" and the count.

- [ ] **Step 4: Add the card field test** (`card_editor_blocks_test.dart`): a `CardFieldWidget` with text "gamsa" has an `EditableText` whose semantics label contains `_en.cardFieldFront`. Only one node in the tree has that label.

- [ ] **Step 5: Pass labels at the other sites.**
- tag entry: `l10n.cardTagHint`;
- tag dialog, deck name dialogs: the dialog field's existing hint or title string.

  No new copy.

- [ ] **Step 6: Run** `flutter test test/shared test/features --exclude-tags golden`. Expected: PASS.

- [ ] **Step 7: Commit** `feat(ui): MxTextField names itself for TalkBack`.

---

### Task 2: `MxTextField` variants (form · detail · meaning · term)

**Files:**
- Modify: `lib/shared/widgets/mx_text_field.dart`, `lib/core/theme/mx_text_styles.dart`, `lib/app/gallery/gallery_inputs_section.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_field_widget.dart`, `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`
- Test: `test/shared/widgets/mx_text_field_test.dart`, `test/core/theme/mx_text_styles_test.dart`, `test/shared/widgets/input_widgets_golden_test.dart`, `test/features/card/presentation/card_editor_screen_test.dart`

**Interfaces:**
- Consumes: Task 1's `label`.
- Produces:
  - `enum MxTextFieldVariant { form, detail, meaning, term }`;
  - `MxTextField({MxTextFieldVariant variant = MxTextFieldVariant.form, ...})`, replacing `isMultiline`;
  - `CardFieldWidget({MxTextFieldVariant variant = MxTextFieldVariant.form, ...})`, replacing `isMultiline`;
  - `MxTextStyles` roles `fieldTerm`, `fieldTermLong`, `fieldTermHint`, `fieldMeaning`, `fieldDetail`.

- [ ] **Step 1: Write the failing tests** (`mx_text_field_test.dart`):

```dart
for (final (variant, floor) in [
  (MxTextFieldVariant.form, 52.0),
  (MxTextFieldVariant.detail, 40.0),
  (MxTextFieldVariant.meaning, 76.0),
  (MxTextFieldVariant.term, 66.0),
]) {
  testWidgets('${variant.name}: its kit floor', (tester) async {
    await pumpMx(tester, MxTextField(hintText: 'x', variant: variant));
    expect(tester.getSize(find.byType(TextField)).height, floor);
  });
}

testWidgets('term: wraps, and a long term steps down to 18', (tester) async {
  final controller = TextEditingController(text: 'a' * 60);
  await pumpMx(
    tester,
    MxTextField(controller: controller, variant: MxTextFieldVariant.term),
  );
  final text = tester.widget<EditableText>(find.byType(EditableText));
  expect(text.maxLines, isNull);
  expect(text.style.fontSize, 18);
  controller.text = 'gamsa';
  await tester.pump();
  expect(
    tester.widget<EditableText>(find.byType(EditableText)).style.fontSize,
    24,
  );
});

testWidgets('term: Enter moves on and adds no newline', (tester) async {
  final controller = TextEditingController(text: 'gamsa');
  await pumpMx(
    tester,
    MxTextField(
      controller: controller,
      variant: MxTextFieldVariant.term,
      textInputAction: TextInputAction.next,
    ),
  );
  await tester.showKeyboard(find.byType(EditableText));
  await tester.testTextInput.receiveAction(TextInputAction.next);
  expect(controller.text, 'gamsa');
  expect(
    tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
    TextInputType.text,
  );
});
```

Also add tests to `mx_text_styles_test.dart` for the new roles:
- `fieldTerm` 24/700, height 1.25, tracking −0.4;
- `fieldTermLong` 18/700;
- `fieldTermHint` 16/500 in `onSurfaceVariant`;
- `fieldMeaning` 16/500, height 1.45;
- `fieldDetail` 14/400, height 1.45.

- [ ] **Step 2: Run them.** Expected: FAIL; the variant and roles are undefined.

- [ ] **Step 3: Implement the roles** in `MxTextStyles`:

```dart
static const double _termTracking = -0.4;
static const double _termHeight = 1.25;
static const double _fieldBodyHeight = 1.45;

/// Card editor term (kit 08/09 Front): 24/700.
TextStyle get fieldTerm => _texts.headlineSmall!.copyWith(
  height: _termHeight,
  letterSpacing: _termTracking,
  color: _scheme.onSurface,
);

/// A term past 30 characters: 18/700 (kit).
TextStyle get fieldTermLong => AppTypography.withWeight(
  _texts.bodyLarge!.copyWith(fontSize: _termLongSize),
  FontWeight.w700,
).copyWith(height: _termHeight, letterSpacing: _termTracking, color: _scheme.onSurface);

/// The term's placeholder: 16/500, onSurfaceVariant.
TextStyle get fieldTermHint =>
    _texts.bodyLarge!.copyWith(color: _scheme.onSurfaceVariant);

/// Card editor meaning (kit Back): 16/500 at 1.45.
TextStyle get fieldMeaning => _texts.bodyLarge!.copyWith(
  height: _fieldBodyHeight,
  color: _scheme.onSurface,
);

/// Optional detail value (kit OptionalField): 14/400 at 1.45.
TextStyle get fieldDetail => _texts.bodyMedium!.copyWith(
  height: _fieldBodyHeight,
  color: _scheme.onSurface,
);
```

(`static const double _termLongSize = 18;`)

- [ ] **Step 4: Implement the variant** in `MxTextField`. Replace `isMultiline` with `variant`.
- **Per-variant geometry** comes from a private switch, one record per variant:

```dart
({double floor, EdgeInsets padding, double radius, bool isMultiline}) _geometry(
  MxTextFieldVariant variant,
) => switch (variant) {
  MxTextFieldVariant.form => (floor: AppSize.input, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.grouped), radius: AppRadius.md, isMultiline: false),
  MxTextFieldVariant.detail => (floor: 40, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.grouped, vertical: AppSpacing.control), radius: AppRadius.md, isMultiline: true),
  MxTextFieldVariant.meaning => (floor: 76, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.grouped), radius: AppRadius.xl, isMultiline: true),
  MxTextFieldVariant.term => (floor: 66, padding: const EdgeInsets.all(AppSpacing.gutter), radius: AppRadius.xl, isMultiline: true),
};
```

  Name the floors as `static const double` fields: `_detailFloor = 40`, `_meaningFloor = 76`, `_termFloor = 66`.
- **Floor:** `form` keeps today's centred-single-line padding math. The multiline variants use `InputDecoration.constraints: BoxConstraints(minHeight: floor)` with their padding. Check that the fill and the edge paint the whole floor, and fall back to today's padding math if they do not.
- **Fill:** `form` keeps resting `surfaceContainerLow` and focused `surfaceContainerLowest`. The other variants are `surfaceContainerLowest` in both states.
- **Text style:**
  - `form` uses `bodyMedium`;
  - `detail` uses `fieldDetail`;
  - `meaning` uses `fieldMeaning`;
  - `term` uses `fieldTerm`, or `fieldTermLong` once the text passes `_termLongAt = 30` characters (by `characters.length`). The field listens to `controller` through a `ListenableBuilder` when the variant is `term` and a controller is present.
- **Hint:** `term` uses `fieldTermHint`; the others use `inputHint`.
- **Multiline and keyboard:** `maxLines` is null for every multiline variant. `term` keeps `keyboardType: TextInputType.text`, so it wraps but Enter fires the action. `meaning` and `detail` use `TextInputType.multiline`.

- [ ] **Step 5: Adopt the variants.**
- `CardFieldWidget` replaces `isMultiline` with `variant`. `textInputAction` is `next` for `term` and `newline` otherwise.
- In `card_editor_form_widget.dart`:
  - Front uses `variant: MxTextFieldVariant.term`;
  - Back uses `MxTextFieldVariant.meaning`;
  - the three optional fields use `MxTextFieldVariant.detail`.
- In the gallery, the "Back of the card" sample becomes `variant: MxTextFieldVariant.detail`. Add a `term` and a `meaning` sample.
- Update `input_widgets_golden_test.dart` in the same way.

- [ ] **Step 6: Screen tests** (`card_editor_screen_test.dart`):
- **"a 60-character term wraps and stays in view":** enter 60 characters in the front. The front `EditableText`'s render box height is greater than 66, and `tester.takeException()` is null.
- **"the editor at 2x holds with every field open":** text scale 2; tap Add details; `takeException()` is null.

- [ ] **Step 7: Run** `dart run build_runner build --delete-conflicting-outputs`, then `flutter analyze`, then `flutter test test/shared test/features test/core --exclude-tags golden`. Expected: PASS.

- [ ] **Step 8: Commit** `feat(ui): MxTextField variants — form, detail, meaning, term (kit 08/09)`.

---

### Task 3: The caption role carries no tracking

**Files:**
- Modify: `lib/core/theme/app_typography.dart`, `lib/core/theme/mx_text_styles.dart`
- Test: `test/core/theme/app_typography_test.dart`, `test/core/theme/mx_text_styles_test.dart`

**Interfaces:**
- Produces: `labelSmall.letterSpacing == 0`. `studyBadge` has 1.2 and `fieldCount` has 0.2. The other caption-derived roles now inherit 0:
  - `counter`, `navLabel`, `footerCaption`, `fieldMessage`, `rowDescription`;
  - `noteText`, `bannerTitle`, `bannerMessage`, `trayLabel`.

- [ ] **Step 1: Write the failing tests.**
- In `app_typography_test.dart`, change the caption row's expected tracking from `1.2` to `0`.
- In `mx_text_styles_test.dart`, add:

```dart
test('sentences at caption size carry no tracking (kit components)', () {
  for (final style in [
    styles.fieldMessage(scheme.error),
    styles.footerCaption,
    styles.rowDescription,
    styles.noteText,
    styles.bannerMessage,
  ]) {
    expect(style.letterSpacing, 0);
  }
  expect(styles.studyBadge(scheme.primary).letterSpacing, 1.2);
  expect(styles.fieldCount(isOver: false).letterSpacing, 0.2);
});
```

  Match the actual signatures in `mx_text_styles.dart`: `studyBadge` and `footerCaption` may be getters or take an ink.

- [ ] **Step 2: Run them.** Expected: FAIL; they read 1.2.

- [ ] **Step 3: Implement.**
- In `AppTypography`, remove `_captionTracking` and the `tracking:` argument of `labelSmall`.
- Update its doc comment: "caption: metadata, counts, chips. 12 is a hard floor. Tracking belongs to the roles that want it (overline 0.6, count 0.2, the study mode badge 1.2)."
- In `MxTextStyles`:
  - add `static const double _badgeTracking = 1.2;` and `static const double _countTracking = 0.2;`;
  - `studyBadge` sets `letterSpacing: _badgeTracking`;
  - `fieldCount` sets `letterSpacing: _countTracking` on both branches.

- [ ] **Step 4: Run** `flutter test test/core test/shared test/features --exclude-tags golden`. Expected: PASS.
- Tests that pinned 1.2 through a derived role were wrong against the kit. Change them to the kit value, and ledger each change as a ruling.

- [ ] **Step 5: Commit** `fix(theme): the caption role carries no tracking; overline, count and study badge carry their own`.

---

### Task 4: Kit "Add details" disclosure

**Files:**
- Create: `lib/features/card/presentation/widgets/items/card_add_details_widget.dart`
- Modify: `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`, `lib/core/theme/mx_text_styles.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/card/presentation/card_editor_blocks_test.dart`, `test/features/card/presentation/card_editor_screen_test.dart`

**Interfaces:**
- Produces:
  - `CardAddDetailsWidget({required VoidCallback onPressed})`;
  - ARB: `cardAddDetails` "Add details" / "Thêm chi tiết", and `cardAddDetailsFields` "example · hint · pronunciation" / "ví dụ · gợi ý · phát âm";
  - `MxTextStyles.disclosureLabel`: 12/600 in primary.

- [ ] **Step 1: Write the failing tests** (`card_editor_blocks_test.dart`):
  - the disclosure shows `_en.cardAddDetails` and `_en.cardAddDetailsFields`;
  - it is one button for TalkBack, with a label containing both;
  - it is at least 48 tall;
  - it calls `onPressed` on tap;
  - at text scale 2, `takeException()` is null.

- [ ] **Step 2: Run them.** Expected: FAIL; the widget does not exist.

- [ ] **Step 3: Implement.** The widget tree:

```dart
MergeSemantics(
  child: Semantics(
    button: true,
    child: MxRowInk(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.outlineVariant, width: AppStroke.hairline),
        ),
        child: Row(spacing: AppSpacing.control, children: [
          IconTheme.merge(data: IconThemeData(color: context.colors.primary), child: const Icon(AppIcons.details, size: AppIconSize.inline)),
          Expanded(child: Text.rich(TextSpan(children: [
            TextSpan(text: l10n.cardAddDetails, style: styles.disclosureLabel),
            const TextSpan(text: '  '),
            TextSpan(text: l10n.cardAddDetailsFields, style: styles.rowDescription),
          ]))),
          IconTheme.merge(data: IconThemeData(color: context.colors.primary), child: const Icon(AppIcons.chevronDown, size: AppIconSize.inline)),
        ]),
      ),
    ),
  ),
)
```

- Take the token names (`AppSize.touchTarget`, `AppIconSize.inline`) from `lib/core/theme/foundations/`. If a name differs, use the existing one.
- The two-space `TextSpan` gap becomes a spacing token if the guard flags it as a literal. Otherwise, a `WidgetSpan(child: SizedBox(width: AppSpacing.control))`.
- `MxRowInk` clips its ink to the radius if it supports that. If not, wrap it in `ClipRRect(borderRadius: AppRadius.md)`.
- Replace the `MxButton` in `_optionalFields` with `CardAddDetailsWidget(onPressed: () => setState(() => _isDetailsOpen = true))`, keeping its bottom padding.

- [ ] **Step 4: Run** `flutter gen-l10n`, then `flutter test test/features/card --exclude-tags golden`. Expected: PASS. The existing `tap(find.text(_en.cardAddDetails))` still finds the label.

- [ ] **Step 5: Commit** `feat(card): the kit's Add details disclosure`.

---

### Task 5: Register, goldens, gate

**Files:**
- Modify: `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` (§9 rows 99+)
- Test: every golden (regenerated in the container)

- [ ] **Step 1: Register rows.**
  - **99:** The caption role carries no tracking; the foundations table's 1.2 px appears only on the kit's documentation chrome. The kit's components track only the overline (0.6), the field count (0.2) and the study mode badge (1.2). *(card editor fields, audit 2026-09-25)*
  - **100:** Field placeholders are full `onSurfaceVariant`, not the kit's 0.6 opacity, for text contrast (WCAG 1.4.3). An empty meaning's placeholder sits at the top, not centred.
  - **101:** "Add details" is 48 tall (the touch minimum), not the kit's 42, with a solid `outlineVariant` edge instead of dashed: there is no dashed-border token (row 81).
- [ ] **Step 2: Windows gate:**
  - `dart format --set-exit-if-changed lib test`;
  - `flutter analyze`;
  - guard `memox-v8` 0/0;
  - `python .claude/skills/flutter-architecture/scripts/check_architecture.py`;
  - `flutter test --exclude-tags golden`;
  - `python tools/docs/check.py`.

  Expected: all green.
- [ ] **Step 3: Goldens.** Regenerate every golden in the container and verify that run is green. Review the changed images once, with the card editor (create, errors, edit, 2x) and one list screen first. Fix what shows in one batch; do at most one confirming round.
- [ ] **Step 4: Commit** `docs(ui): card editor fields — register rows 99–101; goldens (Linux container)`.
- [ ] **Step 5: Final review and PR.** Run the whole-branch review (opus). Open the PR and squash-merge after the owner's popup.
