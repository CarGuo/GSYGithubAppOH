# scenario-tour 20260526-090633

- target: `127.0.0.1:5555`  pid: `23813`  bundle: `cn.gsy.githubapp`
- 产物目录: `/tmp/r8-l2-pushdetail-v4-090633`
- 结果: ok=`1` fail=`0` skip=`12`
- md5 重复 (≥3 张同图): `NO`

## 场景产物

| # | key | screenshot | layout | md5 | assert |
|---|-----|------------|--------|-----|--------|
| 13 | pushDetail | [13_pushDetail.png](13_pushDetail.png) | [13_pushDetail.json](13_pushDetail.json) | `6661d80b` | ok:0
0 fail:0
0 |

## hilog 切片协议

在 `hilog_business.log` 中按 marker 切片：

```bash
awk '/=== BEGIN scenario=launch /,/=== END   scenario=launch /' /tmp/r8-l2-pushdetail-v4-090633/hilog_business.log
```

## 断言全文

```
```
