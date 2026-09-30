<!-- Hand-written screen record. -->

# 27 · Sync

What sync did and what waits: the last success, the changes not yet on the server, the
last failed run, and the rows the server refused. Shaped by Impeccable before the plan
(2026-09-28). SB-U1; spec
[2026-09-28-sync-status-design.md](../../../superpowers/specs/2026-09-28-sync-status-design.md)
§5.2.

## Entry points

- Screen 23, Sync section, row "Sync". Route `/settings/sync`, on the root navigator like
  Theme and Language; Back returns to 23.
- Screen 13's sync banner, "Details" (`context.go`, as Study home opens the Library);
  Back lands on Settings.
- Neither exists when the build has no Supabase.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) + back `MxIconButton` | "Sync". |
| Problem | `MxInlineBanner` (warning) | Under the status card, above Sync now (critique 2026-09-30; it was a floating notice). Refused rows win: the title "{n} changes weren't accepted" (critique 2026-09-30 part 3a, R3) over the message "The server didn't accept them. They're safe here. Try again, or keep them on this device only; they won't sync to your other devices.", then Keep on this device (outline) · Try again (primary, the screen's one primary) under it. Keep opens the Keep dialog first (critique 2026-09-30 part 1, R4). Otherwise the last failed run's sentence (spec §5.4), local-first, with no code, id or message. None when all is well. |
| Status | `MxSection` + two `MxSettingsRow`s + note | "Last synced" · "{Today, 14:32}" or "Not yet"; "Waiting to sync" · "{n} changes" or "Nothing waiting", or "No other changes waiting" when only refused rows remain (critique 2026-09-30 part 1); the note "MemoX syncs on its own when you're online. Your study never waits for it." |
| Sync now | `MxButton` (block, cloud-sync glyph): primary while changes wait or a run failed and no row was refused; outline otherwise, since sync is automatic (critique 2026-09-30) and, with refused rows, the banner's Try again is the one primary (critique 2026-09-30 part 1) | Spins and is disabled while a run it started is going. |
| Keep dialog | `MxDialog` + `MxSheetActions` | "Keep {n} changes on this device only?" · "They won't sync to your other devices. You can't undo this." · Cancel · Keep on this device. Only the confirm keeps; Cancel, Back or the scrim write nothing (critique 2026-09-30 part 1, R4). |
| Toasts | `MxSnackbar` | "Synced"; "Couldn't sync. Nothing was lost."; "Kept on this device"; "Couldn't change that. Nothing was lost." · Retry. |

Only one of Sync now, Try again and Keep on this device runs at a time; the other two
are disabled meanwhile.

## States

The images are the goldens.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| synced | ![](../../../../test/features/settings/presentation/goldens/sync_synced_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_synced_dark.png) | Golden `sync_synced_*`. |
| neverSynced | ![](../../../../test/features/settings/presentation/goldens/sync_never_synced_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_never_synced_dark.png) | Golden `sync_never_synced_*`. |
| pending | ![](../../../../test/features/settings/presentation/goldens/sync_pending_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_pending_dark.png) | Golden `sync_pending_*`. |
| failedNetwork | ![](../../../../test/features/settings/presentation/goldens/sync_failed_network_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_failed_network_dark.png) | Golden `sync_failed_network_*`. |
| failedServer | ![](../../../../test/features/settings/presentation/goldens/sync_failed_server_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_failed_server_dark.png) | Golden `sync_failed_server_*`. |
| rejected | ![](../../../../test/features/settings/presentation/goldens/sync_rejected_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_rejected_dark.png) | Golden `sync_rejected_*`. |
| keepDialog | ![](../../../../test/features/settings/presentation/goldens/sync_keep_dialog_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_keep_dialog_dark.png) | Golden `sync_keep_dialog_*` (critique 2026-09-30 part 1). |
| syncing | ![](../../../../test/features/settings/presentation/goldens/sync_syncing_light.png) | ![](../../../../test/features/settings/presentation/goldens/sync_syncing_dark.png) | Golden `sync_syncing_*`. |
| loading | — | — | `MxSkeletonList`, two rows. |
| read error | — | — | `MxErrorState` "Couldn't open Sync" with the local-first body and Retry (spec §6). |

## Rulings

- **ADR-015, SB-U1 owner rulings R1, R3, R5–R7:** sync has its own screen, and its problems reach other screens as a floating notice (register row 143); on this screen they sit inline under the status, by Sync now (critique 2026-09-30).
- **Critique 2026-09-30 part 1 (spec `2026-09-30-critique-fixes-part1-design.md`), R4:** with refused rows Try again is the one primary, the waiting row never says "Nothing waiting", the banner says why and what Keep costs, and Keep asks first.
- **Spec R6, FE-B5 D9:** times are 24-hour `HH:mm` in every language; dates read "Sep 26" style in English.

## Copy

- App bar: "Sync".
- Refused rows: "{n} changes weren't accepted" · "1 change wasn't accepted" · "The server didn't accept them. They're safe here. Try again, or keep them on this device only; they won't sync to your other devices." · "Keep on this device" · "Try again".
- Keep dialog: "Keep {n} changes on this device only?" · "They won't sync to your other devices. You can't undo this." · "Cancel" · "Keep on this device".
- Failures: "No connection. Your changes are safe on this device and will sync when you're back online." · "Couldn't sign in to sync. Your changes are safe on this device. MemoX will try again." · "The server couldn't take the changes. They're safe on this device. MemoX will try again." · "Sync stopped with an error. Your changes are safe on this device. MemoX will try again."
- Status: "Status" · "Last synced" · "Not yet" · "Waiting to sync" · "{n} changes" · "Nothing waiting" · "No other changes waiting" · "MemoX syncs on its own when you're online. Your study never waits for it." · "Sync now".
- Toasts: "Synced" · "Couldn't sync. Nothing was lost." · "Kept on this device" · "Couldn't change that. Nothing was lost." · "Retry".
- Error: "Couldn't open Sync" · "Nothing was lost. Try again in a moment." · "Retry".
