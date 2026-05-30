# E2E（hypium Driver + hdc）

## 选型
- 默认使用 hypium 自带的 `Driver` API（基于 UiTest），跑在真机或鸿蒙模拟器上。
- 与 RN 端 Maestro 等价：保证主流程在 release 包不崩。

## 准备
- 设备：鸿蒙真机或 DevEco 模拟器，已通过 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/README.md) 完成签名。
- 工具：`hdc list targets` 确认设备在线；`hvigorw test --filter e2e` 跑全部 E2E。

## 目录
```
entry/src/ohosTest/ets/test/e2e/
├── flows/
│   ├── login-if-needed.spec.ets    # 已登录则直接进 MainTabs
│   └── skip-welcome.spec.ets       # 跳过启动页等待
├── login.spec.ets                  # PAT 登录闭环
├── repository.spec.ets             # 仓库详情核心链路
├── search.spec.ets                 # 搜索 + Drawer 过滤
└── README.md（本文件）
```

## flows/ 用例框架说明

### flows/login-if-needed.spec.ets
- 启动 App → 检测当前页面：
  - 若已是 MainTabs（id="main-tabs"）→ 直接 return（用于其他 spec 复用）。
  - 若是 LoginPage → 执行 PAT 输入 + 提交流程。
- 用法：被 `repository.spec` / `search.spec` 等其他 spec 通过 helper 引用。

### flows/skip-welcome.spec.ets
- 等待 WelcomePage 自动跳转（最长 3s）。
- 期望落到 LoginPage 或 MainTabs。

### repository.spec.ets（关键链路示例）
1. 引用 `flows/login-if-needed.spec` 保证登录态。
2. 进入 SearchPage → 输入 `CarGuo/GSYGithubAppOH` → 选第一项 → 进入 RepositoryDetailPage。
3. 断言 README Web 组件加载完成（id="repo-detail-readme-web" 高度 > 100）。
4. 切到 Activity / Issue Tab → 断言列表至少 1 项。
5. 返回 → 断言回到 SearchPage。

## hdc 配合命令
```bash
hdc list targets                                  # 设备列表
hdc install -r entry/build/.../entry-default-signed.hap
hdc shell aa start -a EntryAbility -b cn.gsy.githubapp
hdc shell hilog -P gsygithub                      # 实时日志
hdc file recv /data/.../files/ai-debug/<ts>.json /tmp/   # AI debug dump
```

## 失败处理
- 任意 E2E 失败时自动 `Driver.takeScreenShot(...)` 落到 `/tmp/gsy_e2e_<ts>.png` 并复制到 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) 登记。

## 与 harness/regression 的关系
- 每条 E2E 用例在发布前必须通过；失败用例必须在 [known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) 登记并指派负责人。
