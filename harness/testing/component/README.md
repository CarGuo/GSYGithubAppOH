# 组件测试（hypium UI Test）

## 目录
```
entry/src/ohosTest/ets/test/component/
├── EventItem.test.ets
├── RepositoryItem.test.ets
├── IssueItem.test.ets
├── UserItem.test.ets
└── SearchDrawerFilter.test.ets
```

## 关键 Page / 组件测试范围

| 组件 | 验证点 | RN 蓝本 |
|---|---|---|
| EventItem | 头像 / 文案（PushEvent/WatchEvent/ForkEvent…） / 时间 / 点击跳转参数 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/EventItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/EventItem.js) |
| RepositoryItem | 仓库名 / 描述 / Star/Fork/语言色块 / 长按收藏 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/RepositoryItem.js) |
| IssueItem | 标题 / 状态图标 / 时间 / 评论数 / 点击跳转 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/IssueItem.js) |
| UserItem | 头像 / login / 关注/取关交互 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/UserItem.js) |
| SearchDrawerFilter | Drawer 切换 / 选项联动 / 重置 / 触发回调 | [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchDrawerFilter.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/SearchDrawerFilter.js) |

## 通用模板
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

export default function EventItemTest() {
  describe('EventItem', () => {
    it('renders push event with branch', 0, async () => {
      const driver = Driver.create();
      // 加载组件容器页面 → 注入 fixture → 断言
      const text = await driver.findComponent(ON.id('event-item-action-text'));
      expect(await text.getText()).assertContain('Push to');
    });
  });
}
```

## 注意点
- 组件测试需在 `ohosTest` 模块下注册一个 Test Container Page（如 `TestHostPage.ets`），用 query 参数动态决定渲染哪个组件 + 哪份 fixture。
- 所有 mock 数据集中放 `entry/src/ohosTest/ets/fixtures/` 下，命名 `<domain>.fixture.json`。
- 所有可交互节点必须打 `id="<domain>-<element>"`，与 testID 约定一致（见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/strategy.md)）。
