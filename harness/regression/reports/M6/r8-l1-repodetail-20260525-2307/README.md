# scenario-tour 20260525-230709

- target: `127.0.0.1:5555`  pid: `2492`  bundle: `cn.gsy.githubapp`
- 产物目录: `/tmp/r8-l1-v2-230709`
- 结果: ok=`4` fail=`0` skip=`8`
- md5 重复 (≥3 张同图): `NO`

## 场景产物

| # | key | screenshot | layout | md5 | assert |
|---|-----|------------|--------|-----|--------|
| 06 | repoDetail-activity | [06_repoDetail-activity.png](06_repoDetail-activity.png) | [06_repoDetail-activity.json](06_repoDetail-activity.json) | `17616a21` | ok:0
0 fail:0
0 |
| 07 | repoDetail-readme | [07_repoDetail-readme.png](07_repoDetail-readme.png) | [07_repoDetail-readme.json](07_repoDetail-readme.json) | `332b7174` | ok:0
0 fail:0
0 |
| 08 | repoDetail-issues | [08_repoDetail-issues.png](08_repoDetail-issues.png) | [08_repoDetail-issues.json](08_repoDetail-issues.json) | `ccf0d228` | ok:0
0 fail:0
0 |
| 09 | repoDetail-files | [09_repoDetail-files.png](09_repoDetail-files.png) | [09_repoDetail-files.json](09_repoDetail-files.json) | `cbf59f78` | ok:0
0 fail:0
0 |

## hilog 切片协议

在 `hilog_business.log` 中按 marker 切片：

```bash
awk '/=== BEGIN scenario=launch /,/=== END   scenario=launch /' /tmp/r8-l1-v2-230709/hilog_business.log
```

## 断言全文

```
```
