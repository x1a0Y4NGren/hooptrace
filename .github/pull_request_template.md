## Outcome / 结果

Describe the user-visible problem and the finished behavior.
说明用户问题及完成后的行为。

## Design and data decisions / 设计与数据决策

- Recording modes, rules, and critical flow impact:
- Schema, backup, migration, or audit impact:
- Privacy, permissions, network, and F-Droid impact:
- Accessibility, locale, theme, and adaptive-layout impact:

## Verification / 验证

- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze`
- [ ] Relevant unit/widget/database tests
- [ ] `flutter test --reporter expanded`
- [ ] Android debug build
- [ ] Main-flow integration test when a critical flow changed
- [ ] Real/emulated screenshots for visual changes (zh/en, light/dark, 200% text where relevant)

List exact commands and results:

## Release risk / 发布风险

- Rollback or recovery path:
- Known limitations and follow-up work:
- No real player data, signing key, `key.properties`, or generated device database is included.
