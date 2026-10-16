# Vendored ECC skills

`.claude/skills/` holds 9 skills copied, unchanged, from
[affaan-m/ECC](https://github.com/affaan-m/ECC) (MIT) at commit
`bf70150eb2df8070024e5bdf08e4aa08959e2735`:

| Area | Skills |
|---|---|
| Flutter/Dart | `dart-flutter-patterns`, `flutter-dart-code-review` |
| Java/Spring | `java-coding-standards`, `jpa-patterns`, `springboot-patterns`, `springboot-security`, `springboot-tdd`, `springboot-verification` |
| Security | `security-review` |

- **Reference material, not process.** When one conflicts with `CLAUDE.md`,
  `CLAUDE.md` wins: Superpowers and Impeccable own the workflows. The same
  holds for the repo's own `flutter-*` skills, the active ADRs in
  `docs/shared/decisions/` and the guard. For example, V8 uses Riverpod and
  Drift, not BLoC or Freezed; sync goes through the Supabase RPCs in `SupabaseSyncApi`
  (ADR-015), and a future REST API goes through Retrofit on the one shared Dio
  client (ADR-012), never hand-written Dio calls.
- **Java/Spring skills apply to the frozen `memox-api-services/` only**, never
  to the Flutter app. The repo's own `spring-boot-mybatis-review` wins over the
  ECC `springboot-*` and `jpa-patterns` skills.
- **Skills only.** ECC's agents, rules, hooks, commands and memory are not
  used here. A plan task never delegates to an ECC agent; its implementer
  reads the relevant skill instead.
- **Not vendored:** `ios-icon-gen` ships executable scripts, and
  `security-scan` runs the npm package `ecc-agentshield`. Both run third-party
  code.
- **Removed 2026-10-16:** the native and other-framework mobile skills
  (`android-clean-architecture`, `compose-multiplatform-patterns`,
  `kotlin-coroutines-flows`, `swiftui-patterns`, `swift-concurrency-6-2`,
  `swift-actor-persistence`, `swift-protocol-di-testing`,
  `react-native-patterns`, `foundation-models-on-device`,
  `liquid-glass-design`). MemoX is Flutter only, and each listed skill sat in
  every session's skill list, where it cost context and could be picked by
  mistake. Re-vendor one from the commit above if the app ever grows native
  code that needs it.
- **To update:** copy the new versions from a pinned ECC commit, review the
  diff, and update the commit above.
