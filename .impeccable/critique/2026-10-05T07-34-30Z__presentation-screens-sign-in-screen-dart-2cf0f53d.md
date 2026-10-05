---
target: sign-in flow 29/30/31
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/user/memox-v8/lib/features/account/presentation/screens/sign_in_screen.dart"
target_fingerprint: "sha256:db3a3809569d6cc0490f08b13b10c87ab09d49391bf389424904b81cd0983155"
target_path: /home/user/memox-v8/lib/features/account/presentation/screens/sign_in_screen.dart
timestamp: 2026-10-05T07-34-30Z
slug: presentation-screens-sign-in-screen-dart-2cf0f53d
---
Method: dual-agent (A design review · B detector + golden measurements)

# Critique: sign-in flow (29 Welcome · 30 Sign-in · 31 Code)

Score 28/40. H4 consistency 2, H10 help 2, others 3.

Specificity: tokens are MemoX's; composition is the generic auth template. Detector [] (not meaningful on Dart; positive control on Dart also []). Token guard clean (real).
Golden measurements (360x800dp): sign_in_link uses 44% height, primary button top at 301dp, empty tail 451dp; layer_target 43%/295dp; code_waiting 31%, no fill, tail 556dp; welcome_ready 96%, primary at 616dp. Disabled resend text 1.83:1; code field edge 1.24:1.

Priority issues
- [P1] Wrong-code recovery contradicts locked resend; countdown at 1.83:1 (code_form_widget.dart:119-126). Fix: wait as on-surface-variant caption; drop "or send a new code" while locked.
- [P1] Sign-in flat, top-heavy, inconsistent with Welcome (sign_in_form_widget.dart:143-172). Fix: title + footer CTA; email-only mode from Welcome's email exit; Google same rank everywhere.
- [P1] Welcome sells an account to a user with no decks (welcome_screen.dart:101-117). Fix: honest offline-first lead, tighter benefits, offline note by the footer.
- [P2] Re-auth: five actions, destructive exit styled as harmless skip (sign_in_screen.dart:86-96). Fix: eyebrow naming the account, 32dp separation, consequence wording.
- [P2] Empty code field has no affordance (edge 1.24:1). Fix: slots or 000000 hint, spam hint.

Personas: first-timer (nothing to protect), refused session (no reason, prefilled unlabeled, thumb-slip risk), patchy connection (offline Welcome looks broken, 60s wait).
Minor: "Use another email" duplicates Back; verifying spinner shifts layout; layer_target top-aligned vs F1 "centred".
