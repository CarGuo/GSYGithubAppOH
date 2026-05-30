# Playbook — 升级 DevEco / SDK

> 适用于 DevEco Studio 主版本升级 / compatibleSdkVersion 提升 / runtimeOS 切换。

## 总体阶段
1. **基线勘察**：固化当前 DevEco 版本、`compatibleSdkVersion`（当前 `6.1.0(23)`）、`runtimeOS HarmonyOS`、ohpm 关键依赖版本、构建是否绿。
2. **写 RFC / ADR**：在 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/) 新增 `NNNN-upgrade-deveco-X.Y.md`，列出动机、风险、回滚预案。
3. **在干净分支推进**：`upgrade/deveco-X.Y` 分支独立工作；主干保持可发布。
4. **DevEco 升级**：先升 IDE → 让 IDE 引导升级 SDK 与 hvigor；同步刷新 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/build-profile.json5)、[https://github.com/CarGuo/GSYGithubAppOH/blob/main/hvigor/hvigor-config.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/hvigor/hvigor-config.json5)、[https://github.com/CarGuo/GSYGithubAppOH/blob/main/oh-package.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/oh-package.json5)。
5. **SDK 提升**：`compatibleSdkVersion` 改动后必须复测全部 24 张 relationalStore CREATE、Web 组件资源加载、@ohos.events.emitter 行为。
6. **三方包矩阵**：ohpm 依赖逐个验证最低版本约束；不兼容时申请新版本或写 patch。
7. **回归**：先跑 hypium 全部单测 / 组件测 / E2E → 再跑 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/checklist.md)。
8. **文档**：更新 ADR、CHANGELOG-AI、known-issues。

## 关键风险
- ArkUI 装饰器 / V2 状态管理在 SDK 升级时可能引入断点（如 `@Track` 行为变更）。
- relationalStore SQL 兼容性：升级后可能需要 DB version+1 + onUpgrade 迁移。
- Web 组件 onLoadIntercept 签名变化会影响深链拦截。
- 签名 profile 与 SDK 版本绑定，升级后需重新生成（详见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0005-debug-signing-config.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/decisions/0005-debug-signing-config.md)）。

## Tips
- 每阶段都要能跑出"WelcomePage → LoginPage → 主 Tab 任一页面"三件套，否则不进入下一阶段。
- 升级前先备份 `signature/` 目录下证书；升级后重新自动生成。
- DevEco 升级失败时优先用 IDE 自带 "Migration Assistant"；不要手改 hvigor 文件。

## 通用命令
```bash
# 查询 ohpm 依赖
ohpm list

# 清理产物
hvigorw clean

# 仅打包 entry hap
hvigorw assembleHap

# 真机安装
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
```

## 回滚
- 通过 git 回滚到升级前提交；signature/ 同步还原。
- DevEco 不支持降级时，使用上一版本安装包重装即可；项目级配置在 git 中可回滚。
