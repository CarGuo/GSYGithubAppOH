# device-smoke 装机回归脚本使用说明

本文档说明如何使用 `scripts/device-smoke.sh` 在 hdc 已连接的真机/模拟器上完成"半自动冒烟"。脚本只做装机回归（设备探活 → 安装 HAP → 启动 Ability → 抓图/抓 layout/抓日志），不依赖也不会写入任何 token，token 由 App 内 LoginPage 由用户手动输入。

## 前置条件

1. **hdc 在 PATH 中可用**，且已连接到目标设备：
   ```bash
   hdc list targets
   # 期望看到：127.0.0.1:5555 （或你自定义的 target）
   ```
   如未连接：
   ```bash
   hdc tconn 127.0.0.1:5555
   ```
2. **已经在 DevEco Studio 中完成 Build > Build Hap(s)/APP(s) > Build Hap(s)**，
   产物默认位于：
   ```
   entry/build/default/outputs/default/entry-default-signed.hap
   ```
   若使用未签名 HAP 或自定义路径，请通过 `HAP_PATH` 环境变量覆盖（见下文）。
3. 仓库根目录运行脚本（脚本中的相对路径以仓库根为基准）。

## 标准用法

```bash
cd /path/to/GSYGithubAppOH
bash scripts/device-smoke.sh
```

执行完成后，所有产物落在：
```
harness/regression/reports/M6/device-smoke-YYYYMMDD-HHMMSS/
```
目录中包含：
- `device.txt`：设备型号、系统版本、RenderService 屏幕信息
- `install.log`：HAP 安装日志
- `start.log`：`aa start` 拉起 Ability 的日志
- `01_welcome.png` / `01_welcome_layout.json`：启动 3s 的欢迎页截图与控件树
- `hilog_business.log`：30s 业务域（domain `0x0666`）日志
- `02_after.png` / `02_after_layout.json`：30s 后（通常已落到 LoginPage）截图与控件树
- `README.md`：本次回归的元信息（target / bundle / hap / artifacts 列表）

## 环境变量覆盖

脚本通过环境变量提供可配置项，常见三种场景：

### 1. 切换 hdc target

默认 `127.0.0.1:5555`（DevEco 模拟器）。切换到 USB 真机或其他 target：
```bash
hdc list targets
# 假设输出：1234567890ABCDEF
HDC_TARGET=1234567890ABCDEF bash scripts/device-smoke.sh
```
真机/模拟器场景：
```bash
HDC_TARGET=127.0.0.1:5556 bash scripts/device-smoke.sh
```

### 2. 覆盖 HAP_PATH

当 HAP 不在默认输出路径（例如使用了 `release` profile 或自定义 module）：
```bash
HAP_PATH=entry/build/release/outputs/default/entry-release-signed.hap \
  bash scripts/device-smoke.sh
```
> 若 `HAP_PATH` 不存在，脚本会以 exit code `3` 退出，并提示先在 DevEco 中 Build > Build Hap。

### 3. 覆盖输出目录

```bash
OUT_DIR=/tmp/my-smoke-run bash scripts/device-smoke.sh
```

## hilog domain `0x0666` 含义

- `0x0666` 是本仓在 ArkTS 侧 `Logger`（`entry/src/main/ets/ai-debug/Logger.ets`）统一使用的**业务 domain**。所有业务模块（auth / dao / net / pages / service / store 等）通过 `Logger.x()` 落日志时都打到这一 domain。
- `hdc -t $TARGET hilog -T 0x0666` 即"按业务 tag 过滤 hilog"，能在 30s 抓取窗口里只保留与本 App 相关的业务日志，去掉系统噪音。
- 若需联合排查系统侧（如 RenderService、ArkUI、Ability），可单独再开一个终端：
  ```bash
  hdc -t 127.0.0.1:5555 hilog | grep -E "ArkUI|Ability|RenderService"
  ```
  本脚本不会自动抓系统全量 hilog，避免日志量爆炸。

## 退出码

- `0`：全部步骤成功（含被忽略的非关键失败）
- `2`：设备探活失败（hdc 不通 / target 离线）
- `3`：未找到 HAP，请先在 DevEco 中 Build Hap

## 安全约束

- 脚本**不读取、不写入、不传输任何 token**。
- LoginPage 出现后，请在设备上手动完成 OAuth 流程（或粘贴 PAT），脚本本身不参与认证。
- 截图与 layout dump 会带上当前页面内容，请在归档前自查 `02_after.png` 是否包含敏感信息。

## 典型一次冒烟流程

1. DevEco：Build > Build Hap(s)/APP(s) > Build Hap(s)
2. 终端：
   ```bash
   hdc list targets                        # 确认 127.0.0.1:5555 存在
   bash scripts/device-smoke.sh            # 跑回归
   open harness/regression/reports/M6/     # macOS 下查看产物
   ```
3. 把生成的 `device-smoke-*` 目录连同 `README.md` 一并归档到对应里程碑（M6）。
