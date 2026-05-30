# 单元测试（hypium）

## 目录结构
```
entry/src/ohosTest/ets/test/unit/
├── TimeUtil.test.ets
├── HtmlUtils.test.ets
├── TrendingUtil.test.ets
├── FilterUtils.test.ets
├── EventUtils.test.ets
├── IssueUtils.test.ets
├── EventDao.test.ets
├── RepositoryDao.test.ets
├── UserDao.test.ets
└── ...
```

## 哪些单测必须有（与 RN 端 [https://github.com/CarGuo/GSYGithubApp/blob/master/__tests__/unit/](https://github.com/CarGuo/GSYGithubApp/blob/master/__tests__/unit/) 对齐）

| 模块 | 测什么 | RN 蓝本 |
|---|---|---|
| TimeUtil | `resolveTime` 的 falsy / justNow / 多分钟 / 多小时 / 多天 / 多月 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/timeUtil.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/timeUtil.js) |
| HtmlUtils | `getFullName / launchUrl / parseDiffSource / generateMd2Html` 边界 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/htmlUtils.js) |
| TrendingUtil | fixture HTML（today / weekly / monthly + 不同语言） → 解析正确 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/TrendingUtil.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/trending/TrendingUtil.js) |
| FilterUtils | 关键字 + 排序 + 时间过滤参数拼接、URL encode、空值忽略 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/filterUtils.js) |
| EventUtils | type → 文案 / 跳转目标矩阵（PushEvent / WatchEvent / ForkEvent…） | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js) |
| IssueUtils | open/closed/all 过滤、reaction 解析、状态 emoji | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/issueUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/issueUtils.js) |

## 通用 Mock
- HttpClient：用 hypium 提供的 mock，或自实现 `MockHttpClient` 替换 `@ohos.net.http`。
- relationalStore：测试时使用内存 in-memory 模式 / mock。
- preferences：mock 为简单 Map。
- I18n：替换为 `(key) => key` 直传。

## 运行
```bash
hvigorw test                                     # 全量
hvigorw test --filter HtmlUtils                  # 仅跑 HtmlUtils 相关
```

## 编写示例（最小骨架）
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { resolveTime } from '../../../main/ets/utils/TimeUtil';

export default function TimeUtilTest() {
  describe('TimeUtil.resolveTime', () => {
    it('returns empty for falsy', 0, () => {
      expect(resolveTime(undefined)).assertEqual('');
    });
    it('returns justNow for very recent times', 0, () => {
      expect(resolveTime(Date.now())).assertEqual('justNow');
    });
  });
}
```

## 与 harness/requirements 的对应
- `requirements/auth.md` US-AUTH-1 → `UserDao.test.ets`
- `requirements/repository.md` US-REPO-2 → `HtmlUtils.test.ets`
- `requirements/trending.md` US-TRD-1 → `TrendingUtil.test.ets`
- `requirements/dynamic.md` US-DYN-2 → `EventUtils.test.ets`
- `requirements/search.md` US-SCH-1 → `FilterUtils.test.ets`
- `requirements/infra.md` 时间 / Markdown → `TimeUtil.test.ets` / `HtmlUtils.test.ets`
