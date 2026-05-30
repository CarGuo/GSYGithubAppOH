# Release-gate Checklist

> 任何发版（debug 真机回归 / 上架）前必须从头跑一遍。
> 蓝本：[https://github.com/CarGuo/GSYGithubApp/blob/master/harness/regression/checklist.md](https://github.com/CarGuo/GSYGithubApp/blob/master/harness/regression/checklist.md)。

## 0. 准备
- [ ] 主干同步最新代码、`ohpm install` 通过。
- [ ] [https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/](https://github.com/CarGuo/GSYGithubAppOH/blob/main/signature/) 4 个签名材料齐备（不入库）。
- [ ] DevEco gradle / hvigor sync 成功。

## 1. 静态检查
- [ ] DevEco "Code Inspect" 全绿，无新增 Error。
- [ ] 无新增 TODO/FIXME；如有，已写入 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/regression/known-issues.md)。

## 2. 单元 / 组件测试（hypium）
- [ ] `hvigorw test` 全部通过。
- [ ] 新增功能至少 1 单测 + 1 组件测（参见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md)）。

## 3. E2E（hypium Driver）
- [ ] [auth domain](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/e2e/README.md) `flows/login-if-needed` + `login.spec` 通过。
- [ ] `flows/skip-welcome` 通过。
- [ ] `repository.spec` 通过。

## 4. 手工回归（按 7 域）
- [ ] [auth.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/auth.md)
- [ ] [dynamic.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/dynamic.md)
- [ ] [trending.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/trending.md)
- [ ] [repository.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/repository.md)
- [ ] [search.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/search.md)
- [ ] [profile.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/profile.md)
- [ ] [infra.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/infra.md)

## 5. 性能 / 内存
- [ ] WelcomePage → MainTabs 冷启动 < 2.5s（鸿蒙中端机）。
- [ ] List 滑动稳定 60fps，无明显丢帧。
- [ ] 内存峰值 < 350MB。

## 6. 兼容性
- [ ] 至少 2 个 HarmonyOS 版本 / 2 种屏幕（手机 / 折叠屏）。
- [ ] 横竖屏切换无白屏 / 错位。

## 7. 包大小 / 隐私
- [ ] hap 包大小未异常增长（>10% 需说明）。
- [ ] [https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5](https://github.com/CarGuo/GSYGithubAppOH/blob/main/entry/src/main/module.json5) 权限声明与实际使用一致。

## 8. 真机闭环
- [ ] `hdc install -r entry-default-signed.hap` Success。
- [ ] `hdc shell aa start -a EntryAbility -b cn.gsy.githubapp` 启动后 5s 内进程仍存活。
- [ ] hilog 关键词 `gsygithub` 无 ERROR / FATAL。
- [ ] PAT 登录 → 首页 → Trending → 仓库详情 → README 渲染 → 退出登录闭环成功。
