# scenario-tour 20260526-113755

- target: `127.0.0.1:5555`  pid: `22804`  bundle: `cn.gsy.githubapp`
- 产物目录: `/tmp/scenario-tour-20260526-113755`
- 结果: ok=`1` fail=`0` skip=`14`
- md5 重复 (≥3 张同图): `NO`

## 场景产物

| # | key | screenshot | layout | md5 | assert |
|---|-----|------------|--------|-----|--------|
| 15 | codeDetail | [15_codeDetail.png](15_codeDetail.png) | [15_codeDetail.json](15_codeDetail.json) | `4b41eb5c` | ok:2 fail:0
0 |

## hilog 切片协议

在 `hilog_business.log` 中按 marker 切片：

```bash
awk '/=== BEGIN scenario=launch /,/=== END   scenario=launch /' /tmp/scenario-tour-20260526-113755/hilog_business.log
```

## 断言全文

```
[OK]   15_codeDetail.json  id=code_detail_appbar
[OK]   15_codeDetail.json  id=code_detail_web
```
