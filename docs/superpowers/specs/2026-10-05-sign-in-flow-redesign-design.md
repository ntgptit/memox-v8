# Sign-in flow redesign: screens 29 Welcome, 30 Sign-in, 31 Code — design

Status: approved by the owner 2026-10-05 (sections 1–3 in chat; this file awaits review) ·
Path: architectural (three screens, the transition layer's form, one shared widget, `DESIGN.md`) ·
Critique snapshot `.impeccable/critique/2026-10-05T07-34-30Z__presentation-screens-sign-in-screen-dart-2cf0f53d.md`

## 1. Intent

The owner asked to redesign the login screens. An Impeccable critique of 29 · 30 · 31
(dual-agent, 28/40) found the tokens right and the composition generic:

- **30 and 31 are top-heavy.** Sign-in uses 44 % of the height and its one fill sits at 301 dp,
  out of the thumb zone, over a 451 dp empty tail; Code uses 31 % and has a 556 dp tail.
- **29 and 30 disagree.** Google is the fill on Welcome and an outline on Sign-in, with no stated
  reason; Sign-in has no title in the body and no focal point.
- **Wrong-code recovery contradicts itself.** The error says "send a new code" while "Resend
  code in 1:00" is a disabled button at 1.83:1; the empty code field's edge is 1.24:1.
- **Welcome sells an account to a user with no decks**, and offline it shows two disabled buttons
  with the note 400 px above them.
- **Re-auth** shows five actions, says nothing about why, and its data-removing exit reads like
  Welcome's harmless skip.

The visual system stays (owner: "Bố cục mới, giữ hệ"). Every token, radius, spacing step and
`Mx*` component is DESIGN.md's; one shared widget gains a drawn form (§4.1).

Success means:

- every item in §3–§5 is built as written and pinned by a widget test or a golden;
- the flows, routes, controllers and commands do not change; only layout, copy and the code
  field's drawing do;
- goldens regenerated in the Linux container and reviewed on a golden review page; the gate passes.

Authority (ADR-019): a BR or UC beats DESIGN.md, which beats a detail file. No BR or UC fixes
these layouts; the account UI spec (`2026-09-30-account-ui-design.md`) §5.1–§5.2 and §6 are
amended by this spec where they disagree.

## 2. Owner rulings (2026-10-05)

- **S1. Scope:** the whole flow, 29 · 30 · 31, and the transition layer's form (it reuses 30's
  and 31's widgets).
- **S2. Direction:** new layout, same system. DESIGN.md gains rules; it is not replaced.
- **S3. Fix set:** the three P1s and the two P2s of the critique; minors ride along where they
  sit in a file this work changes.
- **S4. Screen 30 keeps both ways** (Google and email) from every entry, Welcome's email exit
  included.
- **S5. The code field draws six slots.**
- **S6. Frame A:** head (title and lead) in the body, one task in the body, actions in an
  `MxFooterBar` that rides above the keyboard.
- **S7. Rank follows the screen's purpose.** Welcome asks *which way*, so Google is its fill;
  Sign-in is the email screen, so "Send code" is its fill and Google is the outline beside it.
- **S8.** Sign-in drops the "or" divider: two stacked block buttons with one fill say "two ways",
  as Welcome's footer does.
- **S9.** Re-auth's way out stays in the body, 32 dp under the form, out of the footer's thumb
  path, and names the account it leaves.
- **S10.** Welcome offline shows one usable action, "Continue without an account", as the
  primary, with the offline note as the footer caption; Google and email return when the
  account can link.

## 3. Screen 30 · Sign-in

### 3.1 Link (`mode=link`)

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back only, no title. |
| Title | `screenTitle`, header semantics | "Sign in". |
| Lead | `emptyBody` | "Your decks stay on this phone and join the account." (unchanged), `control` (8) under the title. |
| Email | `MxTextField` (form) | `section` (24) under the lead. Label "Email address"; hint "name@example.com" (was the label again). Error under it as today. |
| Footer | `MxFooterBar` | "Send code" (primary, block, spins while sending), then `grouped` (12), "Continue with Google" (outline, block, G mark, spins while picking). Caption "Signing in needs a connection. You can do it later in Settings." only while the account cannot link; it replaces the `MxNote` at the top. |

The divider (`_OrDivider`) and `accountOr` go. Enabling, spinners, the field check on send, the
Google toast, the loss dialog and every outcome stay as they are.

### 3.2 Re-auth (`mode=reauth`)

| Region | Design |
|---|---|
| Eyebrow | The refused account's email, as typed (user data is never upper-cased), above the title. Absent when the email is unknown. |
| Title | "Sign in again". |
| Lead | "This phone was signed out, so syncing paused. Your decks are still here." |
| Email | Pre-filled with the account's email, as today. |
| Way out | `major` (32) under the field: "Continue without this account" (text, block). Its dialog title becomes "Continue without this account?"; body, banner and confirm flow unchanged except the confirm label, which takes the same new string. |
| Footer | As §3.1. |

Welcome keeps "Continue without an account": that skip removes nothing.

### 3.3 Transition layer, target sign-in

The same frame inside the layer: "Cancel" (text) stays at the top in place of the back arrow;
title "Sign in"; lead "Sign in to the account this phone moves to." (unchanged); the address
pre-filled; the footer of §3.1 at the layer's bottom, above the keyboard. Ruling F1 ("the
layer's content is centred") keeps applying to the running, error and stuck states only; the
detail file says so.

## 4. Screen 31 · Code

### 4.1 `MxTextField` code variant: six slots

One hidden `TextField` keeps everything that works today: `AutofillHints.oneTimeCode`, the
number keyboard, the digits-only formatter (a pasted "123 456" loses its space), the 6-digit
limit, the semantics label ("Code, 6 digits") and the error through `MxFieldMessage`. Over it the
widget paints six slots; a tap on any slot focuses the field.

| Part | Design |
|---|---|
| Slot | 48 wide in a 328 dp column (six slots, five `control` gaps, centred when wider), 56 high minimum, radius `md` (12), fill `surface-container-low`. |
| Edge | 1 dp `outline` at rest, which holds 3:1 on the page in both themes (added to the contrast test). The slot that takes the next digit: 2 dp primary ink while focused. Error: every slot 1 dp `error`. |
| Digit | `fieldCode` style, centred. |
| Disabled | The existing `AppOpacity.disabled` over the row. |

DESIGN.md's Inputs line for the code variant is rewritten to this.

### 4.2 Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back only, no title. |
| Title | `screenTitle`, header | "Enter the code" (unchanged string). |
| Lead | `emptyBody` | "We sent a 6-digit code to", then the email on its own line in the same style at `on-surface` ink, weight 600, so a typo shows. |
| Code | `MxTextField` (code) | `section` (24) under the lead; autofocused when the screen opens. |
| Status line | 48 dp minimum, `grouped` (12) under the field | While waiting: "New code in 0:42" as a caption in `on-surface-variant` (no button). When the wait ends: "Resend code" (text button), as today. While verifying: `MxSpinner` in this line, so nothing below moves. While resending: the button spins, as today. |
| Hint | `MxNote.hint` | "Check your spam folder if it hasn't arrived in a minute." |
| Another email | `MxButton` (text) | "Use another email" (unchanged). |

No footer: the code verifies on its sixth digit, so there is no commit action.
The wrong-code error becomes "That code is wrong or has expired. Check the latest email."; the
status line says when a new code can be sent. The resend loss dialog (P3b M7) is unchanged.

## 5. Screen 29 · Welcome

| Region | Design |
|---|---|
| Head | Tile, "MemoX", unchanged. |
| Lead | "MemoX works on this phone without an account, offline too. Signing in adds:" |
| Benefits | `MxSection` with two rows: "Keep your decks when you reinstall", "Study on several phones". The "Still works offline" row goes; the lead says it. |
| Body note | The mid-page `MxNote` goes. |
| Footer, can link | Unchanged: Google (primary, G), "Continue with email" (outline), "Continue without an account" (text). |
| Footer, cannot link | "Continue without an account" (primary, block) alone, caption "Signing in needs a connection. You can do it later in Settings." When linking becomes possible the footer returns to three buttons. |

## 6. Copy

| Key | English | Tiếng Việt |
|---|---|---|
| `welcomeLead` (changed) | MemoX works on this phone without an account, offline too. Signing in adds: | MemoX dùng được trên điện thoại này mà không cần tài khoản, cả khi không có mạng. Đăng nhập thêm cho bạn: |
| `welcomeBenefitOffline` | removed | removed |
| `accountOr` | removed | removed |
| `accountEmailHint` (new) | name@example.com | ten@example.com |
| `accountReauthTitle` (new) | Sign in again | Đăng nhập lại |
| `accountReauthLine` (changed) | This phone was signed out, so syncing paused. Your decks are still here. | Điện thoại này đã bị đăng xuất nên việc đồng bộ tạm dừng. Bộ thẻ vẫn còn ở đây. |
| `accountContinueWithoutThis` (new) | Continue without this account | Tiếp tục không dùng tài khoản này |
| `accountWithoutTitle` (changed) | Continue without this account? | Tiếp tục không dùng tài khoản này? |
| `accountCodeSentTo` (changed, no placeholder) | We sent a 6-digit code to | Mã 6 chữ số đã được gửi tới |
| `accountResendIn` (changed) | New code in {time} | Có thể gửi mã mới sau {time} |
| `accountCodeWrong` (changed) | That code is wrong or has expired. Check the latest email. | Mã sai hoặc đã hết hạn. Hãy xem email mới nhất. |
| `accountCodeSpamHint` (new) | Check your spam folder if it hasn't arrived in a minute. | Nếu sau một phút chưa thấy, hãy xem thư mục spam. |

Every other string stays.

## 7. Documents

- Detail files 29, 30, 31: layout tables, states, rulings (S1–S10 cited as "sign-in redesign
  2026-10-05"), copy; the screen index rows for 29–31.
- DESIGN.md: the code variant (§4.1); under the One Indigo Rule, one sentence for S7 (a screen
  that asks *which way* fills its first way; a screen for one way fills that way's commit).
- The account UI spec gets a pointer to this spec at §5.1, §5.2 and §6.

## 8. Testing

- Widget tests:
  - 30's footer holds the two actions and the caption only when the account cannot link;
  - re-auth shows the eyebrow and the way out under the field;
  - 31's status line is a caption while waiting, a button when the wait ends, and a spinner
    while verifying; a tap on a slot focuses the field;
  - 29 offline shows one primary action and the caption.
- Unit: the code variant keeps the digits-only formatter (a pasted "123 456" becomes "123456").
- Contrast test: the slot edge on page, low and sheet grounds, both themes.
- Goldens regenerated (Linux container) and reviewed on a golden review page:
  - `welcome_ready_*`, `welcome_offline_*`;
  - `sign_in_link_*`, `sign_in_invalid_*`, `sign_in_reauth_*`, `sign_in_unsent_loss_*`,
    `sign_in_continue_without_*`;
  - `layer_target_*`, `code_waiting_*`, `code_wrong_*`, `mx_text_field_code_*`.
- The gate (`dod_check.sh`). The auth integration run (`tools/supabase/run_auth_it.sh`) is due
  because `lib/features/account/` changes. If Docker is missing in the container, say so; never
  skip it silently.

## 9. Out of scope

- Welcome as a first-launch gate (critique question 1); an email field on Welcome itself (S4).
- A MemoX-only hero or illustration; the app icon (UI-base row 149).
- The merge sheet, the layer's running states, screen 32.
