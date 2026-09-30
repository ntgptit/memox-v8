<!-- Hand-written screen record. -->

# 29 · Welcome

The first launch invites an account: the name, one promise, three benefits, and three
ways on in the thumb zone. Shaped by Impeccable before the plan (2026-09-30). SB-A2;
spec [2026-09-30-account-ui-design.md](../../../superpowers/specs/2026-09-30-account-ui-design.md)
§5.1, §6.

## Entry points

- The launch, once per device, on a build that can sign in: `main` reads
  `app_settings.welcome_seen` before the first frame and the router sends any location
  to `/welcome?from=<location>` until Welcome is answered (U1, P3a plan ruling 3).
- No back arrow: Android Back leaves the app, as on any root.

## Layout

| Region | Widget | Design |
|---|---|---|
| Head | `MxIconTile` (large, tinted, deck glyph) | Stands in for the app icon, which is still Flutter's default (U5; UI-base row 149). |
| Name and promise | `screenTitle` + `emptyBody` | "MemoX"; "Sign in to keep your decks safe and the same on every phone." |
| Benefits | `MxSection` + `MxSettingsRow` × 3 | Shield "Keep your decks when you reinstall"; devices "Study on several phones"; cloud-off "Still works offline". Not tappable. |
| Offline note | `MxNote` | "Signing in needs a connection. You can do it later in Settings." Only while the account is not ready to link (P3a plan ruling 6). |
| Actions | `MxFooterBar` + `MxButton` × 3, 12 apart | "Continue with Google" (primary, the G mark: the one fill); "Continue with email" (outline); "Continue without an account" (text). |

Every exit answers Welcome first, then goes on: Google and "without" to `from`, email
to Sign-in with Settings under it (P3a plan ruling 4). A Google account that belongs
to another account opens the merge sheet (30); its choice also leaves Welcome.

## States

The images are the goldens.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| ready | ![](../../../../test/features/account/presentation/goldens/welcome_ready_light.png) | ![](../../../../test/features/account/presentation/goldens/welcome_ready_dark.png) | Golden `welcome_ready_*`. |
| offline | ![](../../../../test/features/account/presentation/goldens/welcome_offline_light.png) | ![](../../../../test/features/account/presentation/goldens/welcome_offline_dark.png) | Golden `welcome_offline_*`. |

## Rulings

- **U1:** shown once on every device, including one that used the app before the update.
- **U5:** the tile until MemoX has its own icon (UI-base row 149).
- **U6:** Google's G mark on the Google button.
- **P3a plan rulings 3, 4, 6:** only on a build that can sign in; the email exit lands on Sign-in over Settings; sign-in waits, with a note, while the account cannot link yet.

## Copy

- "MemoX" · "Sign in to keep your decks safe and the same on every phone."
- "Keep your decks when you reinstall" · "Study on several phones" · "Still works offline".
- "Continue with Google" · "Continue with email" · "Continue without an account".
- "Signing in needs a connection. You can do it later in Settings."
- Toast: "Signed in as {email}" (or "Signed in").
