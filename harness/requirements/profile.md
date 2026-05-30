# 需求 — 个人主页 / 设置

## 用户故事
- **US-PRF-1**：作为登录用户，我可以查看自己的仓库 / Star / 关注 / 粉丝 / 组织（多 Tab）。
- **US-PRF-2**：我可以查看其他用户的资料（PersonPage），并 Follow / Unfollow（状态写入 UserFollower / UserFollowed）。
- **US-PRF-3**：我可以在设置页修改语言、清除缓存、查看版本、跳到 GitHub Releases 检查更新。

## 关键路径与文件
- MyPage / PersonPage / PersonInfoPage：蓝本
  - [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/MyPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/MyPage.js)
  - [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonPage.js)
  - [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonInfoPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/PersonInfoPage.js)
- SettingPage / AboutPage / ReleasePage：蓝本
  - [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/SettingPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/SettingPage.js)
  - [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/AboutPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/AboutPage.js)
  - [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ReleasePage.js)
- ListPage（通用列表页）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/ListPage.js)
- BasePersonPage（共享头部）：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/BasePersonPage.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/components/widget/BasePersonPage.js)
- UserDao：蓝本 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/userDao.js)

## 验收标准
1. MyPage 必须显示当前登录用户的统计数（Star/Follow/Followers）并支持下拉刷新；首屏命中 UserInfo 缓存表。
2. PersonPage 支持多 Tab（仓库 / Star / Followers / Following / Repos / Orgs），各 Tab 维护独立分页。
3. 设置页"清除缓存"必须连同 relationalStore 24 张表一并清空，并 Toast 提示成功；token 默认保留，除非用户点击"退出登录"。
4. AboutPage "检查更新" 按钮调起 `@ohos.web.webview` 或浏览器跳到 `https://github.com/CarGuo/GSYGithubAppOH/releases`，失败兜底走剪贴板复制 + Toast 提示。

## 测试矩阵
- 单测：`UserDao.test.ets`（关注 / 取关解析、UserInfo 解析）。
- 组件：`UserItem.test.ets`、`UserHeadItem.test.ets`。
- 手工：[https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/profile.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/testing/manual/profile.md)。
