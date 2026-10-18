<!-- Hand-written screen record. -->

# 40 · Route not found

The page for a location the router does not know: a mistyped path, a deep link that leads
nowhere, a TOPIK level that does not exist. It says so in the person's language, shows no
exception text and no path, and offers one way back, to the Library. IT-NAV-005, FE-D3 spec
D5; UI-base register row 144 (`2026-09-23-flutter-ui-base-design.md` §9).
`RouteNotFoundScreen`, `lib/app/router/route_not_found_screen.dart`.

## Entry points

- **Any location that matches no route:** the root router's `errorBuilder`
  (`lib/app/router/app_router.dart:72`) builds it in place of go_router's own page, which
  prints the exception. Reached by a deep link such as `memox://app/nowhere` and by a
  path pushed with `go`.
- **A TOPIK level that does not exist:** `/study/topik/:level` with a code that is neither
  TOPIK I nor TOPIK II builds it directly (`lib/app/router/topik_routes.dart:87`). An unknown
  TOPIK *test* is not this page: it is screen 36's `testMissing`. An unknown deck is not
  this page either: it is screen 01's `deckNotFound`.
- From `errorBuilder` it lies on the root navigator, so it covers the tab shell: no bottom
  bar, no rail. From an unknown TOPIK level it is built inside the Study branch's route
  (no `parentNavigatorKey`), so the tab shell stays under it (`topik_routes.dart:87`;
  `topik_routes_test.dart::deep links: an unknown level is not found; an unknown test is missing, and Back to tests opens TOPIK`).

## Layout

| Region | Widget | Design |
|---|---|---|
| Shell | `MxAppShell` | No app bar, no footer, no FAB. A bare column on the page ground. |
| Safe area | `SafeArea` | The body keeps clear of the system bars and the cutout. |
| Body | `MxScreenScroll` | Scrolls, so a short window (a phone held sideways, split screen) never cuts it. |
| Empty state | `MxEmptyState` (primary tone) | The `searchOff` glyph (search with a cross) on the primary tint, the title "Page not found", one line of body, and one block `MxButton`, "Back to Library". |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| notFound | — | — | The one frame: glyph, title, body and "Back to Library". The location is never shown and no exception text appears. No golden. `route_not_found_test.dart::an unknown route shows not found, no exception text, and Back to Library opens the Library (IT-NAV-005)`; the audit companion `test/visual_audit/screens/app/router/route_not_found_screen_visual_audit_test.dart::not found (IT-NAV-005)` runs it in both themes at the default text scale against the 48 dp tap-target and label guidelines. |
| shortWindow | — | — | A window 360 dp high (a phone held sideways, 800 × 360): the empty state scrolls instead of overflowing and the button stays reachable. No golden. `route_not_found_screen_test.dart::in a phone held sideways it scrolls instead of overflowing, and the way back stays reachable`. |

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (entry) | a location matches no route | notFound | IT-NAV-005. VERIFIED `route_not_found_test.dart::an unknown route shows not found, no exception text, and Back to Library opens the Library (IT-NAV-005)` (title and body shown; `GoException` and the path absent). The deep link `memox://app/nowhere` is scripted on a device (`tools/device/run_device_e2e.sh`, `scenario_IT-PLAT-004`, expects "Page not found"); that run is not part of the host gate |
| (entry) | `/study/topik/:level` with an unknown level code | notFound | VERIFIED `topik_routes_test.dart::deep links: an unknown level is not found; an unknown test is missing, and Back to tests opens TOPIK` |
| notFound | tap Back to Library | the Library root, `/decks`; `context.go` replaces the stack | VERIFIED `route_not_found_test.dart::an unknown route shows not found, no exception text, and Back to Library opens the Library (IT-NAV-005)` (it lands on the empty Library) |
| notFound | the window is short | shortWindow: the body scrolls, the button stays reachable | VERIFIED `route_not_found_screen_test.dart::in a phone held sideways it scrolls instead of overflowing, and the way back stays reachable` |
| notFound | system Back | the router pops what lies beneath the page, else the app is left; the page has no Back control of its own | `UNVERIFIED (code read)`: `route_not_found_screen.dart` has no `PopScope` or app bar; no test presses system Back here (IT-PLAT-005 covers the study session only) |
| notFound | the theme or the language changes | the page redraws in the new theme or language | `UNVERIFIED (code read)`: it reads `context.l10n` and the theme; only the default light and dark frames are audited |

## Rulings

- **FE-D3 spec D5, IT-NAV-005:** an unknown route never shows go_router's default error page. No exception text, no path, in the person's language.
- **Register row 144:** the page is not in the kit; it is `MxEmptyState` on the shell, with the primary tone, because the one action leads somewhere.
- **One way out:** "Back to Library" is the only action; Library is the app's home, and the page has no Retry, since an unknown location does not become known.
- **No golden:** the frame is a stock `MxEmptyState`; the audit companion and the two widget tests are its evidence. A golden would be added with a change to its layout.

## Copy

"Page not found" · "This link doesn't lead anywhere in MemoX." · "Back to Library".
Vietnamese: "Không tìm thấy trang" · "Liên kết này không dẫn tới đâu trong MemoX." · "Về Thư viện".
