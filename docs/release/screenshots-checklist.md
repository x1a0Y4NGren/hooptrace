# 1.0 screenshot checklist / 1.0 截图清单

Screenshots are release metadata, not test evidence. Use synthetic player names
and inspect every image at full resolution before committing it.

截图属于发行元数据而非测试证据。只能使用虚构球员名称，提交前必须逐张按原始
分辨率检查。

## Required matrix / 必需矩阵

- [ ] Simplified Chinese and English.
- [ ] Warm light and charcoal dark themes.
- [ ] Home/recovery state, pregame mode selection, simple and detailed scoring,
      finished replay/analytics, history filters, player growth, backup settings.
- [ ] Compact phone landscape scoring.
- [ ] Large/foldable portrait and landscape layouts.
- [ ] One critical flow at 200% text scale without clipping or overflow.
- [ ] Android 16 edge-to-edge with no content under system bars.

## Privacy and fidelity / 隐私与真实性

- [ ] No real names, notes, file paths, notifications, account identifiers,
      serial numbers, or other app content in the system recents/background.
- [ ] Status-bar time/battery/network are either intentionally retained or
      consistently cropped; do not paint over data.
- [ ] No mocked UI that differs from the shipped build.
- [ ] Scores, event timelines, analytics, and shot locations agree within each
      captured match.
- [ ] Locale-specific screenshots are stored under the matching Fastlane path.
- [ ] Icon and images use final release assets and correct aspect ratio.

## Capture record / 拍摄记录

For each final image record commit, build type, emulator/device, API, viewport,
locale, theme, text scale, route/state, and source test fixture. Re-capture after
any visible 1.0 RC change.
