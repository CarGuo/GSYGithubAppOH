# scenario-tour 20260526-094812

- target: `127.0.0.1:5555`  pid: `2095`  bundle: `cn.gsy.githubapp`
- 产物目录: `/tmp/scenario-tour-r8-l3-issueDetail-v3`
- 结果: ok=`1` fail=`0` skip=`13`
- md5 重复 (≥3 张同图): `NO`

## 场景产物

| # | key | screenshot | layout | md5 | assert |
|---|-----|------------|--------|-----|--------|
| 14 | issueDetail | [14_issueDetail.png](14_issueDetail.png) | [14_issueDetail.json](14_issueDetail.json) | `14f2cf6c` | ok:3 fail:0
0 |

## hilog 切片协议

在 `hilog_business.log` 中按 marker 切片：

```bash
awk '/=== BEGIN scenario=launch /,/=== END   scenario=launch /' /tmp/scenario-tour-r8-l3-issueDetail-v3/hilog_business.log
```

## 断言全文

```
[OK]   14_issueDetail.json  id=issue_detail_appbar
[OK]   14_issueDetail.json  id=issue_detail_pull_list
[OK]   14_issueDetail.json  id=issue_detail_bottom_bar
```
