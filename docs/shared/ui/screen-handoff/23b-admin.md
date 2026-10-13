<!-- Hand-written screen record. -->

# 23b · Settings · Admin (admin only)

The admin rows, moved from the Settings tab to a page of their own behind the admin
gate (settings hub spec 2026-10-07, D4): Monitoring, the SQL log switch and Users. The
rows are the ones their features supply (monitoring spec §3.1, users spec U2, SQL log
switch spec 2026-10-07); `app/` composes them, as it composed them into the tab.
Spec [2026-10-07-settings-hub-design.md](../../../superpowers/specs/2026-10-07-settings-hub-design.md)
§5.3.

## Entry points

- **Screen 23's Admin tools row**, `/settings/admin`, on the root navigator with no
  bottom bar; the row shows only to an admin. A deep link from anyone else meets the
  gate (ADR-018 §7): the wait while the account is confirmed, else "Only an admin can
  see this", titled "Admin".
- Monitoring and Users open from here and Back returns here; a deep link straight to
  `/settings/monitoring` or `/settings/users` returns to the hub (D5).

## Layout

| Region | Widget | Design |
|---|---|---|
| Gate | `MonitoringAdminGateWidget` (title "Admin") | A non-admin sees the gate's refusal; while the account is being confirmed, a skeleton list. |
| App bar | `MxAppBar` (content density) + Back | "Admin". |
| Logs | `MxSection` + rows | "Logs". "Monitoring" / "Logs of the app and the server" (monitor tile, opens 28); "Log SQL statements" / "Each statement the app runs is logged, for performance checks. Turn off to keep the log small." with a trailing `MxToggle` on the debug-level tile (the account's value, synced; disabled while its save runs; a refused save shows "Couldn't change that. The switch is unchanged." with the row unchanged). |
| People | `MxSection` + row | "People". "Users" / "Who can manage the app" (people tile, opens 33). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `admin_light.png` | `admin_dark.png` | The three rows for an admin. |
| gate | — | — | (ADR-018 §7) the gate's wait or refusal, as Monitoring and Users show it. |

Goldens: `test/features/settings/presentation/goldens/admin_{light,dark}.png`.

## Rulings

- **Settings hub spec D4, D5:** one page for the admin rows, behind the gate; leaf paths do not move, so a deep link to a leaf returns to the hub.
- **ADR-018 §7, §8; users spec U2:** the features supply the rows, Settings draws the groups; only an admin sees them.
- **SQL log switch spec 2026-10-07:** the switch is the account's value, synced; the same row as screen 28's.

## Copy

- "Admin" · "Logs" · "Monitoring" · "Logs of the app and the server" · "Log SQL statements" · "Each statement the app runs is logged, for performance checks. Turn off to keep the log small." · "Couldn't change that. The switch is unchanged." · "People" · "Users" · "Who can manage the app" · "Only an admin can see this".
