# ADR-0005：DevEco 自动签名流程

- **状态**：Accepted
- **日期**：2026-05-24

## 背景
- HarmonyOS 真机部署 / Profile 调试需要合法签名（不像 Android Debug 默认 self-sign）。
- 团队多人协作时，私钥不能入库；新成员 onboarding 时需明确步骤。
- 已存在落库提示文档 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md)，本 ADR 把"决策与故障排查"沉淀进 harness。

## 决策
1. **使用 DevEco Studio 自动生成调试签名**：File → Project Structure → Project → Signing Configs → 勾选 `Automatically generate signature`。
2. **签名材料统一落到 `signature/` 目录**（仓库根的 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/)），文件名固定：
   - `gsygithubapp.p12`（私钥库）
   - `gsygithubapp.csr`（证书请求）
   - `gsygithubapp.cer`（调试证书）
   - `gsygithubapp.p7b`（HarmonyOS Profile，含 bundleName=cn.gsy.githubapp）
3. **bundleName 固定 `cn.gsy.githubapp`**，与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5) 严格一致；改动 bundleName 必须重新生成签名 + 写新 ADR。
4. **签名材料绝不入库**：`.gitignore` 必须忽略 `signature/*.p12 / *.cer / *.csr / *.p7b`，仓库仅保留 `README.md` + `.gitkeep`。
5. **新成员上手** = 各自登录华为开发者账号在 DevEco 重复"自动生成"流程，使用各自调试证书。

## 备选方案
- 共享一份团队调试签名：违背华为开发者账号的"一人一证"约束；CI 远端构建时无法刷新；否决。
- 用命令行 `hap-sign-tool` 手工签名：步骤多、易错，新成员上手成本高；保留为故障兜底。

## 影响
- [https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5) `signingConfigs.default.material` 由 DevEco 自动改写，正常情况下无需手动维护。
- 团队协作时 onboarding 路径清晰：clone → DevEco 打开 → 勾选自动签名 → Build。

## 故障排查（同步 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md)）
| 现象 | 排查 | 处理 |
|---|---|---|
| `profile not match` | bundleName 是否被改 | 同步 [AppScope/app.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5)，重新自动生成 |
| `cer file not found` | 未写到本目录 | 重新执行 Project Structure → Signing 自动生成 |
| 真机部署失败 | 设备未注册到当前账号 | 在 AppGallery Connect 注册设备 UDID |
| `Invalid signature` | p12 与 cer 不匹配 | 删除 signature/ 全部产物，重新自动生成 |
| `bundleName 与 profile 不一致` | profile 缓存了旧 bundleName | 改 `cn.gsy.githubapp` 后重新自动生成 |

## 后续动作
- 一旦切到上架签名（Release Profile），需开新 ADR 0006 记录正式签名流程与密钥托管方案。
- 详见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/debug-signing.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/playbooks/debug-signing.md)。

## 现实补丁（2026-05-24）：先填 Bundle name 再勾自动签名
- **背景**：DevEco 在 Project Structure → Signing Configs 勾选 `Automatically generate signature` 时若 `Bundle name` 字段为空，会报 `Unable to create the profile due to a lack of a device. Connect a device via IP or USB first. Skip this step if you are installing a HAP on the emulator.`。**根因不是缺真机**，而是 DevEco 在 Bundle name 缺失时默认尝试走"真机 Profile"流程才需要 UDID。
- **正确流程**：
  1. 在弹窗里 **`Bundle name` 必须先填 `cn.gsy.githubapp`**（与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5#L3-L3) 一致）；
  2. 勾选 `Automatically generate signature`；
  3. 点 OK，DevEco 在 1-2 秒内为该 bundleName 生成 4 个本地签名材料；
  4. 将本地签名材料放到工程 `signature/` 目录，或按 DevEco 生成结果更新本地 `build-profile.json5`。
- **当前工程状态**：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5) 只保留相对路径和占位密码；真实证书、私钥和密码不入库。模拟器 / 真机都按此流程，**无需真机参与**。
- **不做的事**：
  - 不跨 bundleName 复用 `.p7b`（HarmonyOS Profile 与 bundleName 强绑定）。
  - 不让 AI 触碰用户级目录里的 `.p12` 私钥。
