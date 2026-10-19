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
| App bar | `MxAppBar` + Back | "Admin". |
| Logs | `MxSection` + rows | "Logs". "Monitoring" / "Logs of the app and the server" (monitor tile, opens 28); "Log SQL statements" / "Logs each statement the app runs, for performance checks." with a trailing `MxToggle` on the debug-level tile (the account's value, synced; disabled while its save runs, and off and disabled while the value is not read yet or its read failed, so no ON is ever claimed (audit 2026-10-17); a refused save shows "Couldn't change that. The switch is unchanged." with the row unchanged). |
| People | `MxSection` + row | "People". "Users" / "Who can manage the app" (people tile, opens 33). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `admin_light.png` | `admin_dark.png` | The three rows for an admin. |
| gate | — | — | (ADR-018 §7) the gate's wait or refusal, as Monitoring and Users show it. |

Goldens: `test/features/settings/presentation/goldens/admin_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (deep link or Admin tools row) | the account is still being confirmed | gate: a skeleton list titled "Admin" | ADR-018 §7. VERIFIED `monitoring_admin_gate_test.dart::while the account is still being confirmed, the gate waits instead of refusing (plan ruling 13)` |
| gate (wait) | the account is confirmed an admin | loaded | `UNVERIFIED (code read)`: `MonitoringAdminGateWidget` rebuilds on `isAdminProvider` |
| gate (wait) | the account is confirmed not an admin | gate: "Only an admin can see this" | ADR-018 §7. VERIFIED `monitoring_admin_gate_test.dart::a settled non-admin is refused` |
| gate (refusal) | Back | the hub (23), or the previous screen | `UNVERIFIED (code read)`: the gate's back button is `maybePop` |
| loaded | tap Monitoring | 28; Back returns here | monitoring spec §3.1. VERIFIED `test/app/monitoring_routes_test.dart::Settings opens Monitoring above the shell, a row opens its detail, and Back climbs one page at a time` (Back climbs to 23b, then to the hub); the row's presence and order `admin_screen_test.dart::Logs holds Monitoring and the SQL switch, People holds Users, in that order` |
| loaded | tap Users | 33; Back returns here | users spec U2. VERIFIED `test/app/account_routes_test.dart::an admin opens Users from Settings, and Back returns (users spec U5)` (Back to 23b, then to the hub) |
| loaded | flip Log SQL statements | the toggle disabled while the save runs, then the new value | SQL log switch spec §5. VERIFIED `sql_log_row_widget_test.dart::shows the row's value and saves the flipped one`; `sql_log_controller_test.dart::set saves once and ignores a second tap while saving` |
| loaded | the save fails | the toggle keeps its value, toast "Couldn't change that. The switch is unchanged." | VERIFIED `sql_log_row_widget_test.dart::a failed save shows the snackbar and keeps the value`; `sql_log_controller_test.dart::a failed save is reported, then dismissed` |
| loaded | the save meets a bug (not a `Failure`) | as a failed save: the toggle is enabled again and keeps its value, with the same toast; the bug is reported | VERIFIED the controller state, `settings_held_bug_test.dart::a SQL log save that dies on a bug is no longer saving and reports the failure once (set)`; the toast from that state is VERIFIED for a `Failure` in `sql_log_row_widget_test.dart` |
| loaded | the settings read has not landed, or it failed | the toggle is off and disabled; it claims no value it has not read (audit 2026-10-17 SET-12) | VERIFIED `sql_log_row_widget_test.dart::while the settings load the toggle is off and disabled`, `::after a failed read the toggle is off and disabled` |
| loaded | the account stops being an admin (sign-out, role change) | gate: "Only an admin can see this", the rows gone | `UNVERIFIED (code read)`: the gate watches `isAdminProvider`; the same switch is VERIFIED for the hub's row, `settings_screen_test.dart::an account confirmed as admin shows the row without a restart, and a lost confirmation hides it` |
| (deep link) | `/settings/monitoring` or `/settings/users` opened directly | that screen; Back returns to the hub | settings hub spec D5. VERIFIED for Monitoring `test/app/account_routes_test.dart::an admin's deep link to Monitoring returns to the hub, not to 23b (settings hub spec D5)`; a non-admin's deep link to Admin or Users meets the gate: `::a non-admin's deep link to Admin meets the gate, titled Admin`, `::a non-admin's deep link to Users meets the gate, titled Users` |

## Rulings

- **Settings hub spec D4, D5:** one page for the admin rows, behind the gate; leaf paths do not move, so a deep link to a leaf returns to the hub.
- **ADR-018 §7, §8; users spec U2:** the features supply the rows, Settings draws the groups; only an admin sees them.
- **SQL log switch spec 2026-10-07:** the switch is the account's value, synced; the same row as screen 28's.

## Copy

- "Admin" · "Logs" · "Monitoring" · "Logs of the app and the server" · "Log SQL statements" · "Logs each statement the app runs, for performance checks." · "Couldn't change that. The switch is unchanged." · "People" · "Users" · "Who can manage the app" · "Only an admin can see this".
