# Playbook — Debug 签名

签名相关详细操作请直接看：
- 仓库根说明：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md)
- 决策与故障排查：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0005-debug-signing-config.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0005-debug-signing-config.md)

## 一句话流程
1. DevEco → File → Project Structure → Project → Signing Configs → 勾 `Automatically generate signature`。
2. 登录华为开发者账号 → DevEco 自动写 4 个文件到 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/)。
3. 确保 `bundleName=cn.gsy.githubapp` 与 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/AppScope/app.json5) 一致。
4. Build → 真机 / 模拟器部署。

## 反复出问题时
- 删除 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/) 下所有 `*.p12 / *.cer / *.csr / *.p7b`。
- 重新执行 step 1。
- 复盘内容写到 ADR-0005 故障排查表。
