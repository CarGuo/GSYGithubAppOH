# Debug 签名（HarmonyOS）

本目录用于存放 DevEco Studio 自动生成的 **调试签名材料**，**禁止提交私钥**到公共仓库。

## 第一次配置步骤
1. 用 DevEco Studio 打开本工程根目录 `./`。
2. 顶部菜单：**File → Project Structure → Project → Signing Configs**。
3. 选择 `default`，勾选 **Automatically generate signature**（自动生成调试签名）。
4. 登录已注册的华为开发者账号，DevEco 会自动产生：
   - `gsygithubapp.p12`（私钥库）
   - `gsygithubapp.csr`（证书请求）
   - `gsygithubapp.cer`（调试证书）
   - `gsygithubapp.p7b`（HarmonyOS Profile，含 bundleName=cn.gsy.githubapp）
5. 把上述 4 个文件落到本目录，DevEco 会自动改写工程根的 [build-profile.json5](../build-profile.json5) 中的 `signingConfigs.default.material`。
6. 工程根的 [build-profile.json5](../build-profile.json5) 已经预留好相对路径，正常情况下无需手动改。
7. **必须**：bundleName 与 [AppScope/app.json5](../AppScope/app.json5) 中保持一致 (`cn.gsy.githubapp`)。

## 切换电脑 / 团队协作
- 不要把 `*.p12` / `*.cer` / `*.p7b` 提交到 git；本目录请保留 `.gitkeep`，并在 `.gitignore` 中忽略实际产物。
- 新成员需要本地重复上面的"自动生成签名"流程，使用各自华为账号的调试证书。

## 故障排查
- **构建报 'profile not match'**：检查 bundleName 是否被改动；重新自动生成。
- **报 'cer file not found'**：DevEco 未把文件写到本目录，按上述步骤 4 重新生成。
- **真机部署失败**：在 [decisions/0005-debug-signing-config.md](../harness/decisions/0005-debug-signing-config.md) 记录失败现场，便于 AI 复盘。
