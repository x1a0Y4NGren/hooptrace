# Security policy / 安全政策

## Supported versions / 支持版本

Security fixes are provided for the latest published HoopTrace release. The
current 1.0 work remains a release candidate until its signed tag is published.

HoopTrace 仅为最新正式版本提供安全修复；1.0 在签名标签发布前均视为候选版本。

## Report privately / 私密报告

Do not open a public issue for vulnerabilities that could expose or destroy
local match data, bypass backup safeguards, escape the selected SAF directory,
or enable code execution. Use GitHub **Private vulnerability reporting** in the
repository Security tab. Include affected versions, reproduction steps, impact,
and a minimal proof of concept. Never include real player data or signing keys.

如问题可能泄露或破坏本地比赛数据、绕过备份保护、越出用户选择的 SAF
目录或造成代码执行，请不要创建公开 Issue；应使用仓库 Security 页面中的
**Private vulnerability reporting**。请提供受影响版本、复现步骤、影响范围和
最小化验证材料，且不要上传真实球员数据或签名密钥。

Maintainers will acknowledge a complete report within 7 days, aim to provide a
triage decision within 14 days, and coordinate disclosure after a fix is
available. These are best-effort targets for a volunteer project.

维护者会尽量在 7 天内确认完整报告、14 天内给出分级结论，并在修复可用后
协调披露；这些是志愿维护项目的尽力目标，并非服务等级承诺。

## Security boundaries / 安全边界

- HoopTrace has no account system, cloud backend, telemetry, ads, or payment SDK.
- Match data is local SQLite data unless the user explicitly exports, shares, or
  enables an approved SAF backup directory.
- Android system backup is disabled; official releases request no broad storage
  permission.
- Third-party forks and repackaged APKs are outside the upstream trust boundary.
- Official APKs must trace to a signed Git tag, published checksums, and the
  maintainer certificate documented in the release record.
