# Playbook — AI 自动 Debug

> 让 AI / 开发者无需 IDE 即可拿到崩溃现场上下文。

## 设计

### Logger（utils/Logger.ets）
- 底座：`@ohos.hilog`，domain `0x0666`，tag `gsygithub`。
- 接口：`Logger.d(tag, msg) / .i / .w / .e(tag, msg, err?)`。
- **环形缓冲**：内存中保留最近 500 条，结构 `{ ts, level, tag, msg }`。
- 每条 hilog 输出同时入环；超 500 时淘汰最旧。

### DebugDumper（ai-debug/DebugDumper.ets）
dump 出一份 JSON 文件，内容：
1. **路由栈快照**：当前 `NavPathStack.getAllPathName()` + 各页 params。
2. **store 快照**：从 `StoreProvider` 取所有 store 类的 `toJSON()`。
3. **最近 N 条 http**：HttpClient 内部环形保留最近 30 条 `{ url, method, status, ms, errorCode }`，不带 body / token。
4. **最近 200 条控制台**：取自 Logger 环形缓冲。
5. 元信息：bundleVersion / runtimeOS / deviceModel / language / 当前用户登录态（不含 token 明文）。

dump 文件路径：
```
internal://app/files/ai-debug/<yyyyMMdd-HHmmss>.json
```
落到应用 sandbox 的 `filesDir`，可被 `hdc file recv` 取出。

### 触发方式
| 方式 | 实现 |
|---|---|
| 长按 LOGO | LoginPage / WelcomePage / About 页面的 logo 加 `LongPressGesture(duration:2000)` → 调 `DebugDumper.dump()` |
| 摇一摇 | 通过 `@ohos.sensor` 监听加速度，5 秒内 3 次峰值 > 18m/s² 触发 |
| 关于页隐藏入口 | About 页连续点击版本号 7 次激活 |
| hilog 关键词 | `hdc shell hilog -P gsygithub -L D` 配合关键词监控（外部触发） |

## 取出 dump 文件

### 列出
```bash
hdc shell ls /data/app/el2/100/base/cn.gsy.githubapp/haps/entry/files/ai-debug/
```

### 拉到本机
```bash
hdc file recv \
  /data/app/el2/100/base/cn.gsy.githubapp/haps/entry/files/ai-debug/20260524-120000.json \
  /tmp/gsy_debug.json
```

### 清空
```bash
hdc shell rm /data/app/el2/100/base/cn.gsy.githubapp/haps/entry/files/ai-debug/*.json
```

> 实际 sandbox 路径以 DevEco 提示为准；本工程 `getContext().filesDir` 输出路径已经写在 Logger 启动日志，可直接搜索。

## 与 CHANGELOG-AI 协同
- 复盘故障时把 dump 摘要 / 关键 http 错误码贴进 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/iteration/CHANGELOG-AI.md) 对应行。
- dump 文件不入库，只在故障期间作为 AI 上下文。

## 与 known-issues 协同
- 反复出现的 dump 模式 → [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md) 立 KI 条目。
