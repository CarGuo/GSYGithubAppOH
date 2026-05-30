# ADR-0004：持久化方案选 relationalStore（24 张表 schema）

- **状态**：Accepted
- **日期**：2026-05-24

## 背景
- RN 端使用 Realm 缓存 GitHub 拉取数据，对应 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js)，共 24 张表。
- HarmonyOS 没有原生 Realm，对位的关系型数据库为 `@ohos.data.relationalStore`（SQLite 包装）。
- 选择 relationalStore 而不是 NoSQL（preferences 仅 KV / 文件序列化），原因：列表分页 / WHERE 过滤 / 事务 / 数据量增长后维护成本最优。

## 决策
1. 数据库名：`gsygithub_oh.db`，version：1（首次发布）。
2. 通用列约定：`fullName TEXT`（仓库 / 用户主键，可空）、`data TEXT`（JSON 序列化原始返回）、`updateAt INTEGER`（毫秒时间戳）。
3. 24 张表与 Realm schema 一一对应，列名保持小驼峰（与 GitHub API 字段一致），便于 `JSON.stringify` 直存。
4. 复杂关联（用户 ↔ 关注关系）扁平化为多张独立表，避免对象图。
5. 升级策略：DB version+1 + onUpgrade 中 `ALTER TABLE` 或 `DROP & CREATE`（缓存可重建，弱兼容）。

## 备选方案
- preferences + JSON：写大数据时 IO 风险高，分页查询无优势，否决。
- 自实现 IndexedDB-like：成本高，否决。
- 引入 ohpm 第三方 ORM：当前生态不稳定，等待官方完善。

## 影响
- dao 层代码与 Realm 略有差异：从 `realm.objects(...).filtered(...)` 改为 `store.querySql('SELECT ... WHERE ...', [...])`。
- JSON 大字段直接落 `data` 列，反序列化交给业务层；轻量索引列单独抽出来供 WHERE。
- 见 [https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/data-flow.md](https://github.com/CarGuo/GSYGithubAppOH/blob/main/harness/architecture/data-flow.md) 第 6 节通用读写范式。

## 24 张表 CREATE TABLE 草案

> 列名、用途与 RN 端 [https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/dao/db/index.js) 对齐。所有表默认带 `updateAt INTEGER`（写入时间戳）。

```sql
-- 1. 仓库 Pulse 缓存（详情页 Pulse 摘要）
CREATE TABLE IF NOT EXISTS RepositoryPulse (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 2. 已读历史（Code/Issue/Repository 跳转过的条目）
CREATE TABLE IF NOT EXISTS ReadHistory (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  type     TEXT NOT NULL,      -- repo | issue | code | user
  fullName TEXT NOT NULL,
  title    TEXT,
  data     TEXT NOT NULL,
  updateAt INTEGER
);
CREATE INDEX IF NOT EXISTS idx_read_history_full ON ReadHistory(fullName);

-- 3. 仓库分支
CREATE TABLE IF NOT EXISTS RepositoryBranch (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 4. 仓库 commits（按页缓存）
CREATE TABLE IF NOT EXISTS RepositoryCommits (
  fullName TEXT NOT NULL,
  branch   TEXT,
  page     INTEGER NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER,
  PRIMARY KEY (fullName, branch, page)
);

-- 5. Watcher 列表
CREATE TABLE IF NOT EXISTS RepositoryWatcher (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 6. Star 列表
CREATE TABLE IF NOT EXISTS RepositoryStar (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 7. Fork 列表
CREATE TABLE IF NOT EXISTS RepositoryFork (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 8. 仓库详情
CREATE TABLE IF NOT EXISTS RepositoryDetail (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 9. 仓库 README
CREATE TABLE IF NOT EXISTS RepositoryDetailReadme (
  fullName TEXT PRIMARY KEY NOT NULL,
  branch   TEXT,
  data     TEXT NOT NULL,    -- markdown 原文
  updateAt INTEGER
);

-- 10. 仓库 Event（活动）
CREATE TABLE IF NOT EXISTS RepositoryEvent (
  fullName TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 11. 仓库 Issue 列表
CREATE TABLE IF NOT EXISTS RepositoryIssue (
  fullName TEXT NOT NULL,
  state    TEXT NOT NULL,    -- open|closed|all
  page     INTEGER NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER,
  PRIMARY KEY (fullName, state, page)
);

-- 12. 仓库 commit 详情
CREATE TABLE IF NOT EXISTS RepositoryCommitInfoDetail (
  fullName TEXT NOT NULL,
  sha      TEXT NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER,
  PRIMARY KEY (fullName, sha)
);

-- 13. Trending v2（since + lang 维度）
CREATE TABLE IF NOT EXISTS TrendRepositoryV2 (
  since    TEXT NOT NULL,    -- daily|weekly|monthly
  lang     TEXT NOT NULL,    -- "" 表示全部
  data     TEXT NOT NULL,
  updateAt INTEGER,
  PRIMARY KEY (since, lang)
);

-- 14. 用户信息（自己 + 他人）
CREATE TABLE IF NOT EXISTS UserInfo (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 15. 用户 Follower 列表
CREATE TABLE IF NOT EXISTS UserFollower (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 16. 用户 Followed（关注的）列表
CREATE TABLE IF NOT EXISTS UserFollowed (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 17. 组织成员
CREATE TABLE IF NOT EXISTS OrgMember (
  org      TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 18. 用户所属组织
CREATE TABLE IF NOT EXISTS UserOrgs (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 19. 用户 Star 仓库
CREATE TABLE IF NOT EXISTS UserStared (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 20. 用户自有仓库
CREATE TABLE IF NOT EXISTS UserRepos (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 21. 全站 Received Events（动态首页）
CREATE TABLE IF NOT EXISTS ReceivedEvent (
  login    TEXT PRIMARY KEY NOT NULL,    -- 当前登录用户
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 22. 用户 Event（个人动态）
CREATE TABLE IF NOT EXISTS UserEvent (
  login    TEXT PRIMARY KEY NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER
);

-- 23. Issue 详情
CREATE TABLE IF NOT EXISTS IssueDetail (
  fullName TEXT NOT NULL,
  number   INTEGER NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER,
  PRIMARY KEY (fullName, number)
);

-- 24. Issue Comment 列表
CREATE TABLE IF NOT EXISTS IssueComment (
  fullName TEXT NOT NULL,
  number   INTEGER NOT NULL,
  page     INTEGER NOT NULL,
  data     TEXT NOT NULL,
  updateAt INTEGER,
  PRIMARY KEY (fullName, number, page)
);
```

## 表用途速查

| # | 表 | 用途 | 主要使用方 |
|---|---|---|---|
| 1 | RepositoryPulse | 仓库 Pulse 摘要缓存 | RepositoryDetailPage |
| 2 | ReadHistory | 已读条目（仓库/Issue/Code） | DynamicPage / 全局跳转兜底 |
| 3 | RepositoryBranch | 分支列表 | RepositoryDetailFilePage |
| 4 | RepositoryCommits | 提交列表分页 | RepositoryDetailActivityPage |
| 5 | RepositoryWatcher | Watch 用户列表 | RepositoryDetailPage |
| 6 | RepositoryStar | Star 用户列表 | RepositoryDetailPage |
| 7 | RepositoryFork | Fork 用户列表 | RepositoryDetailPage |
| 8 | RepositoryDetail | 仓库基础信息 | RepositoryDetailPage |
| 9 | RepositoryDetailReadme | README md | RepositoryDetailPage |
| 10 | RepositoryEvent | 仓库活动 | RepositoryDetailActivityPage |
| 11 | RepositoryIssue | 仓库 Issue 列表分页 | RepositoryIssueListPage |
| 12 | RepositoryCommitInfoDetail | 单 commit 详情 | PushDetailPage |
| 13 | TrendRepositoryV2 | Trending 缓存 | TrendPage |
| 14 | UserInfo | 用户信息 | MyPage / PersonPage |
| 15 | UserFollower | 粉丝 | PersonPage |
| 16 | UserFollowed | 关注 | PersonPage |
| 17 | OrgMember | 组织成员 | ListPage |
| 18 | UserOrgs | 用户组织 | PersonPage |
| 19 | UserStared | 用户 Star 仓库 | PersonPage |
| 20 | UserRepos | 用户仓库 | PersonPage / MyPage |
| 21 | ReceivedEvent | 全站动态 | DynamicPage |
| 22 | UserEvent | 个人动态 | PersonPage |
| 23 | IssueDetail | Issue 详情 | IssueDetailPage |
| 24 | IssueComment | Issue 评论分页 | IssueDetailPage |
