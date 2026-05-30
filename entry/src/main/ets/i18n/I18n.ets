import i18n from '@ohos.i18n';

export type LocaleKey = 'en' | 'zh-CN';

export interface TranslationMap {
  appName: string;
  netError: string;
  netTimeout: string;
  ok: string;
  cancel: string;
  tabRecommended: string;
  tabDynamic: string;
  tabMy: string;
  setting: string;
  daysAgo: string;
  monthsAgo: string;
  yearsAgo: string;
  hoursAgo: string;
  minutesAgo: string;
  justNow: string;
  UserName: string;
  Password: string;
  Login: string;
  LoginOut: string;
  LoginNameTip: string;
  LoginPWTip: string;
  LoginFailTip: string;
  LoginTitle: string;
  LoginSubtitle: string;
  LoginTokenLabel: string;
  LoginTokenHint: string;
  LoginTokenHelper: string;
  LoginButton: string;
  OAuthLogin: string;
  GithubAuthorization: string;
  OAuthConfigMissingTip: string;
  TokenLogin: string;
  TokenInputTip: string;
  TokenLoginFailTip: string;
  TokenLoginExpiredTip: string;
  refreshing: string;
  loading: string;
  loadMoreing: string;
  loadMoreEnd: string;
  doublePressExit: string;
  userInfoNoting: string;
  staredText: string;
  beStaredText: string;
  FollowersText: string;
  FollowedText: string;
  repositoryText: string;
  listRepositories: string;
  listFollowers: string;
  listFollowing: string;
  listRepos: string;
  listStargazers: string;
  listStar: string;
  listWatchers: string;
  listForks: string;
  listTopics: string;
  listOrgs: string;
  personDynamic: string;
  Member: string;
  trendDay: string;
  trendWeek: string;
  trendMonth: string;
  trendAll: string;
  search: string;
  best_match: string;
  stars: string;
  forks: string;
  updated: string;
  filerType: string;
  filterSort: string;
  filterLanguage: string;
  desc: string;
  asc: string;
  Java: string;
  Kotlin: string;
  Objective_C: string;
  Swift: string;
  JavaScript: string;
  PHP: string;
  Go: string;
  C__: string;
  C: string;
  HTML: string;
  CSS: string;
  unknown: string;
  created_at: string;
  forked_at: string;
  latest_update: string;
  latest_commit: string;
  reposActivity: string;
  reposEvents: string;
  reposCommits: string;
  reposPush: string;
  reposReadme: string;
  reposFile: string;
  reposIssue: string;
  issueInfo: string;
  issueComment: string;
  issueCommentDelete: string;
  issueCommentEdit: string;
  issueEdit: string;
  createIssue: string;
  issueClose: string;
  issueOpen: string;
  issueLocked: string;
  issueUnlock: string;
  issueInputTitleTip: string;
  issueInputTip: string;
  issueInputTipTitle: string;
  closeIssue: string;
  openIssue: string;
  closeIssueTip: string;
  openIssueTip: string;
  lockIssueTip: string;
  unLockIssueTip: string;
  commentsIssue: string;
  editIssue: string;
  copyComment: string;
  reposStar: string;
  reposUnStar: string;
  reposWatcher: string;
  reposUnWatcher: string;
  reposRelease: string;
  reposFork: string;
  reposForked: string;
  reposForkedTip: string;
  reposBranch: string;
  reposTag: string;
  notifyUnread: string;
  notifyParticipating: string;
  notifyAll: string;
  notifyType: string;
  notifyStatus: string;
  notifyStatusUnread: string;
  notifyStatusRead: string;
  unread: string;
  readed: string;
  notify: string;
  notifyTitle: string;
  notifyMarkAllRead: string;
  notifyEmpty: string;
  fileNotSupport: string;
  searchRepos: string;
  searchUser: string;
  searchHint: string;
  searchIssue: string;
  searchHistory: string;
  issueAllText: string;
  issueOpenText: string;
  issueCloseText: string;
  issueYoursText: string;
  issueOpenedBy: string;
  hadCopy: string;
  copyClone: string;
  filterCreated: string;
  filterUpdated: string;
  filterPushed: string;
  filterFullName: string;
  forkSuccess: string;
  forkFail: string;
  listEmpty: string;
  browserOpen: string;
  webRelativeLinkNeedRepoContext: string;
  copy: string;
  download: string;
  iosNotSupportDown: string;
  downloadDescription: string;
  userCreate: string;
  profileJoined: string;
  history: string;
  about: string;
  version: string;
  appVersionPrefix: string;
  author: string;
  projectUrl: string;
  feedback: string;
  feedbackHint: string;
  issueSubmitSuccess: string;
  issueSubmitFail: string;
  person: string;
  infoName: string;
  infoEmail: string;
  infoBlog: string;
  infoCompany: string;
  infoLocation: string;
  infoBio: string;
  editField: string;
  userInfoUpdateSuccess: string;
  userInfoUpdateFail: string;
  unFollowed: string;
  doFollowed: string;
  register: string;
  notFound: string;
  errorUnKnow: string;
  noPower: string;
  share: string;
  newestVersion: string;
  updateDialogTitle: string;
  updateDialogVersionLabel: string;
  openLinkFailed: string;
  beStared100Title: string;
  update: string;
  weekClosed: string;
  weekOpened: string;
  thisWeek: string;
  userOrg: string;
  reloadClick: string;
  language: string;
  systemLanguage: string;
  zhLanguage: string;
  enLanguage: string;
  gone410: string;
  clearCache: string;
  loginExpired: string;
  networkOffline: string;
  networkOnline: string;
  contributionTitle: string;
  contributionEmpty: string;
  drawerProfile: string;
  drawerNotify: string;
  drawerHistory: string;
  drawerSearch: string;
  drawerSetting: string;
  drawerFeedback: string;
  drawerPersonalInfo: string;
  drawerLanguage: string;
  drawerCheckUpdate: string;
  drawerAbout: string;
  drawerLogout: string;
  custom: string;
  customHeaderTitle: string;
  customComingSoon: string;
  customScriptItem1: string;
  customScriptHint1: string;
  customScriptItem2: string;
  customScriptHint2: string;
  customScriptItem3: string;
  customScriptHint3: string;
}

const enTranslations: TranslationMap = {
  appName: 'GSY GitHub App',
  netError: 'network error',
  netTimeout: 'network timeout',
  ok: 'ok',
  cancel: 'cancel',
  tabRecommended: 'Trending',
  tabDynamic: 'Feed',
  tabMy: 'My',
  setting: 'setting',
  daysAgo: '%d days ago',
  monthsAgo: '%d months ago',
  yearsAgo: '%d years ago',
  hoursAgo: '%d hours ago',
  minutesAgo: '%d minutes ago',
  justNow: 'just now',
  UserName: 'Click OAuth',
  Password: 'Click OAuth',
  Login: 'OAuth',
  LoginOut: 'Logout',
  LoginNameTip: 'username can\'t not be empty',
  LoginPWTip: 'password can\'t not be empty',
  LoginFailTip: 'login fail',
  LoginTitle: 'GSY GitHub',
  LoginSubtitle: 'HarmonyOS Edition',
  LoginTokenLabel: 'Access Token',
  LoginTokenHint: 'Enter your GitHub token',
  LoginTokenHelper: 'Get your token at github.com/settings/tokens, or click OAuth',
  LoginButton: 'Login',
  OAuthLogin: 'OAuth',
  GithubAuthorization: 'GitHub Authorization',
  OAuthConfigMissingTip: 'Please copy oauth.local.example.json to oauth.local.json and fill GitHub OAuth client_id/client_secret',
  TokenLogin: 'Login with Token',
  TokenInputTip: 'Paste your GitHub Personal Access Token (e.g. ghp_xxx)',
  TokenLoginFailTip: 'Token login failed, please check the token',
  TokenLoginExpiredTip: 'Token expired or revoked. Please generate a new one at github.com/settings/tokens',
  refreshing: 'refreshing...',
  loading: 'loading...',
  loadMoreing: 'loading...',
  loadMoreEnd: 'No more data',
  doublePressExit: 'Press again to Exit',
  userInfoNoting: 'nothing',
  staredText: 'Stars',
  beStaredText: 'honour',
  FollowersText: 'Followers',
  FollowedText: 'Following',
  repositoryText: 'Repositories',
  listRepositories: '%s repositories',
  listFollowers: '%s followers',
  listFollowing: '%s following',
  listRepos: '%s repos',
  listStargazers: '%s stargazers',
  listStar: '%s star',
  listWatchers: '%s watchers',
  listForks: '%s forks',
  listTopics: '%s topics',
  listOrgs: '%s orgs',
  personDynamic: 'Activity Feed',
  Member: 'Member',
  trendDay: 'Day',
  trendWeek: 'Week',
  trendMonth: 'Month',
  trendAll: 'All',
  search: 'search',
  best_match: 'Best match',
  stars: 'stars',
  forks: 'forks',
  updated: 'updated',
  filerType: 'Type',
  filterSort: 'Sort',
  filterLanguage: 'Language',
  desc: 'Desc',
  asc: 'Asc',
  Java: 'Java',
  Kotlin: 'Kotlin',
  Objective_C: 'Objective-C',
  Swift: 'Swift',
  JavaScript: 'JavaScript',
  PHP: 'PHP',
  Go: 'Go',
  C__: 'C++',
  C: 'C',
  HTML: 'HTML',
  CSS: 'CSS',
  unknown: 'unknown',
  created_at: 'Created at',
  forked_at: 'Forked from',
  latest_update: 'Latest update',
  latest_commit: 'Latest commit',
  reposActivity: 'Info',
  reposEvents: 'Events',
  reposCommits: 'Commits',
  reposPush: 'Push',
  reposReadme: 'Readme',
  reposFile: 'File',
  reposIssue: 'Issue',
  issueInfo: 'Info',
  issueComment: 'Reply',
  issueCommentDelete: 'Delete',
  issueCommentEdit: 'Edit',
  issueEdit: 'Edit',
  createIssue: 'Create',
  issueClose: 'Close',
  issueOpen: 'Open',
  issueLocked: 'Locked',
  issueUnlock: 'Unlock',
  issueInputTitleTip: 'enjoy yourself',
  issueInputTip: 'enjoy yourself',
  issueInputTipTitle: 'enjoy yourself',
  closeIssue: 'Close？',
  openIssue: 'Open？',
  closeIssueTip: 'Close？',
  openIssueTip: 'Open？',
  lockIssueTip: 'Locked？',
  unLockIssueTip: 'UnLock？',
  commentsIssue: 'Comment',
  editIssue: 'Edit Issue',
  copyComment: 'Copy',
  reposStar: 'Star',
  reposUnStar: 'UnStar',
  reposWatcher: 'Watcher',
  reposUnWatcher: 'UnWatcher',
  reposRelease: 'Release',
  reposFork: 'Fork',
  reposForked: 'you had Forked',
  reposForkedTip: 'Fxxx Sure?',
  reposBranch: 'Branch',
  reposTag: 'Tag',
  notifyUnread: 'Unread',
  notifyParticipating: 'Participating',
  notifyAll: 'All',
  notifyType: 'Type',
  notifyStatus: 'Status',
  notifyStatusUnread: 'Unread',
  notifyStatusRead: 'Read',
  unread: 'unread',
  readed: 'readed',
  notify: 'Notification',
  notifyTitle: 'Notification',
  notifyMarkAllRead: 'Mark all as read',
  notifyEmpty: 'No notifications',
  fileNotSupport: 'Not Support',
  searchRepos: 'Search Repository',
  searchUser: 'Search User',
  searchHint: 'Search GitHub',
  searchIssue: 'Search Issue',
  searchHistory: 'Search History',
  issueAllText: 'All',
  issueOpenText: 'Open',
  issueCloseText: 'Close',
  issueYoursText: 'Yours',
  issueOpenedBy: 'Opened by %{user}',
  hadCopy: 'Copy Link',
  copyClone: 'Copy Clone Link',
  filterCreated: 'created',
  filterUpdated: 'updated',
  filterPushed: 'pushed',
  filterFullName: 'name',
  forkSuccess: 'Fxxx Success',
  forkFail: 'Fxxx Fail',
  listEmpty: 'Empty(oﾟ▽ﾟ)o ',
  browserOpen: 'Browser Open',
  webRelativeLinkNeedRepoContext: 'Open this link from a repository page',
  copy: 'Copy Link',
  download: 'DownLoad',
  iosNotSupportDown: 'IOS Not Support Down',
  downloadDescription: 'Downloading：',
  userCreate: 'Created At：',
  profileJoined: 'Joined: %s',
  history: 'History',
  about: 'about',
  version: 'Version',
  appVersionPrefix: 'Version: ',
  author: 'Author',
  projectUrl: 'Project',
  feedback: 'Feedback',
  feedbackHint: 'Your feedback will be submitted as an issue to the GitHub repository. Please describe the problem or suggestion in as much detail as possible. Thank you!',
  issueSubmitSuccess: 'Feedback submitted successfully!',
  issueSubmitFail: 'Failed to submit feedback',
  person: 'User Info',
  infoName: 'Name',
  infoEmail: 'Email',
  infoBlog: 'Blog',
  infoCompany: 'Company',
  infoLocation: 'Location',
  infoBio: 'Bio',
  editField: 'Edit %{option1}',
  userInfoUpdateSuccess: 'User information updated successfully!',
  userInfoUpdateFail: 'Failed to update user information.',
  unFollowed: 'unFollow',
  doFollowed: 'Follow',
  register: 'Register',
  notFound: 'Request Not Found',
  errorUnKnow: 'UnKnow',
  noPower: 'No authority',
  share: 'Share',
  newestVersion: 'You are on the latest version',
  updateDialogTitle: 'New Version Available',
  updateDialogVersionLabel: 'Version',
  openLinkFailed: 'Cannot open browser, please copy URL manually',
  beStared100Title: ' Top 100 repository',
  update: 'Update',
  weekClosed: 'Week Closed: ',
  weekOpened: 'Week Opened： ',
  thisWeek: 'This Week ',
  userOrg: 'Org',
  reloadClick: 'Reload',
  language: 'Language',
  systemLanguage: 'System',
  zhLanguage: 'Chinese',
  enLanguage: 'English',
  gone410: '410 Gone',
  clearCache: 'clearCache',
  loginExpired: 'Login expired, please sign in again',
  networkOffline: 'Network is offline',
  networkOnline: 'Network is back online',
  contributionTitle: 'Contributions',
  contributionEmpty: 'No contributions',
  drawerProfile: 'Profile',
  drawerNotify: 'Notifications',
  drawerHistory: 'History',
  drawerSearch: 'Search',
  drawerSetting: 'Settings',
  drawerFeedback: 'Feedback',
  drawerPersonalInfo: 'Personal Info',
  drawerLanguage: 'Switch Language',
  drawerCheckUpdate: 'Check for Updates',
  drawerAbout: 'About',
  drawerLogout: 'Logout',
  custom: 'Custom',
  customHeaderTitle: 'User Custom Scripts',
  customComingSoon: 'Coming Soon',
  customScriptItem1: 'User Custom Scripts',
  customScriptHint1: 'Placeholder: future support for user script injection',
  customScriptItem2: 'Custom Render',
  customScriptHint2: 'Placeholder: future support for custom render pipeline',
  customScriptItem3: 'Custom Shortcut',
  customScriptHint3: 'Placeholder: future support for shortcut binding',
};

const zhTranslations: TranslationMap = {
  appName: 'GSYGitHubApp',
  netError: '网络错误',
  netTimeout: '网络超时',
  ok: '确定',
  cancel: '取消',
  tabRecommended: '趋势',
  tabDynamic: '动态',
  tabMy: '我的',
  setting: '设置',
  daysAgo: '%d 天前',
  monthsAgo: '%d 月前',
  yearsAgo: '%d 年前',
  hoursAgo: '%d 小时前',
  minutesAgo: '%d 分钟前',
  justNow: '刚刚',
  UserName: '请直接点击授权登陆',
  Password: '请直接点击授权登陆',
  Login: '授权登陆',
  LoginOut: '退出登录',
  LoginNameTip: '用户名不能为空',
  LoginPWTip: '密码不能为空',
  LoginFailTip: '登陆失败',
  LoginTitle: 'GSYGitHubAPP',
  LoginSubtitle: 'HarmonyOS 版本',
  LoginTokenLabel: '访问令牌',
  LoginTokenHint: '输入你的 GitHub 令牌',
  LoginTokenHelper: '在 github.com/settings/tokens 获取令牌，也可以直接 OAuth 登录',
  LoginButton: '登录',
  OAuthLogin: 'OAuth',
  GithubAuthorization: 'GitHub 授权',
  OAuthConfigMissingTip: '请先复制 oauth.local.example.json 为 oauth.local.json，并填写 GitHub OAuth client_id / client_secret',
  TokenLogin: '使用 Token 登录',
  TokenInputTip: '请粘贴 GitHub Personal Access Token（如 ghp_xxx）',
  TokenLoginFailTip: 'Token 登录失败，请检查 token 是否有效',
  TokenLoginExpiredTip: 'Token 已失效或被撤销，请到 github.com/settings/tokens 重新生成',
  refreshing: '刷新中...',
  loadMoreing: '正在加载更多···',
  loadMoreEnd: '后面没有数据了',
  loading: '加载中...',
  doublePressExit: '双击退出',
  userInfoNoting: 'Ta什么都没留下',
  staredText: '星标',
  beStaredText: '荣耀',
  FollowersText: '粉丝',
  FollowedText: '关注',
  repositoryText: '仓库',
  listRepositories: '%s 的仓库',
  listFollowers: '%s 的粉丝',
  listFollowing: '%s 的关注',
  listRepos: '%s 的仓库',
  listStargazers: '%s 的关注者',
  listStar: '%s 的星标',
  listWatchers: '%s 的订阅者',
  listForks: '%s 的复刻',
  listTopics: '%s 的主题',
  listOrgs: '%s 的组织',
  personDynamic: '动态',
  Member: '组织成员',
  trendDay: '今日',
  trendWeek: '本周',
  trendMonth: '本月',
  trendAll: '全部',
  search: '搜索',
  best_match: '最匹配',
  stars: 'star',
  forks: 'forks',
  updated: '更新',
  desc: '倒叙',
  asc: '正序',
  filerType: '类型',
  filterSort: '排序',
  filterLanguage: '语言',
  Java: 'Java',
  Kotlin: 'Kotlin',
  Objective_C: 'Objective-C',
  Swift: 'Swift',
  JavaScript: 'JavaScript',
  PHP: 'PHP',
  Go: 'Go',
  C__: 'C++',
  C: 'C',
  HTML: 'HTML',
  CSS: 'CSS',
  unknown: 'unknown',
  created_at: '创建于',
  forked_at: 'Forked from',
  latest_update: '最后更新',
  latest_commit: '最后提交',
  reposActivity: '详情',
  reposEvents: '事件',
  reposCommits: '提交',
  reposPush: '提交',
  reposReadme: 'Readme',
  reposFile: '文件',
  reposIssue: 'Issue',
  issueInfo: '说明',
  issueComment: '回复',
  issueCommentDelete: '刪除',
  issueCommentEdit: '编辑',
  issueEdit: '编辑',
  issueClose: '关闭',
  issueOpen: '打开',
  issueLocked: '锁定',
  issueUnlock: '解锁',
  issueInputTitleTip: '请输入标题',
  issueInputTip: '请输入答复哟',
  issueInputTipTitle: '请输入标题',
  closeIssue: '关闭？',
  openIssue: '打开？',
  closeIssueTip: '你确定要关闭这个Issue吗？',
  openIssueTip: '你确定要打开这个Issue吗？',
  lockIssueTip: '你确定要锁定这个Issue吗？',
  unLockIssueTip: '你确定要解锁这个Issue吗？',
  commentsIssue: '提交回复',
  editIssue: '编辑',
  copyComment: '复制',
  createIssue: '创建',
  reposStar: 'Star',
  reposUnStar: 'UnStar',
  reposWatcher: 'Watcher',
  reposUnWatcher: 'UnWatcher',
  reposRelease: '版本',
  reposFork: 'Fork',
  reposForked: '你已经Fxxx过了(⊙o⊙)',
  reposForkedTip: '你确定要Fxxx Ta吗?',
  reposBranch: '分支',
  reposTag: '标记',
  notifyUnread: '未读',
  notifyParticipating: '参与',
  notifyAll: '所有',
  notifyType: '类型',
  notifyStatus: '状态',
  notifyStatusUnread: '未读',
  notifyStatusRead: '已读',
  unread: '未读',
  readed: '已读',
  notify: '通知',
  notifyTitle: '消息通知',
  notifyMarkAllRead: '全部标记为已读',
  notifyEmpty: '暂无通知',
  fileNotSupport: '预览文件失败，可能文件类型不支持预览。',
  searchRepos: '搜索仓库',
  searchUser: '搜索用户',
  searchHint: '搜索 GitHub',
  searchIssue: '搜索 Issue',
  searchHistory: '搜索历史',
  issueAllText: '全部',
  issueOpenText: '打开',
  issueCloseText: '关闭',
  issueYoursText: '我的',
  issueOpenedBy: '由 %{user} 打开',
  hadCopy: '已经复制到粘贴板',
  copyClone: '复制克隆链接',
  filterCreated: '创建',
  filterUpdated: '更新',
  filterPushed: '提交',
  filterFullName: '名称',
  forkSuccess: 'Fxxx 成功了喔',
  forkFail: 'Fxxx 没能成功呢',
  listEmpty: '暂时还没找到什么(oﾟ▽ﾟ)o ',
  browserOpen: '浏览器打开',
  webRelativeLinkNeedRepoContext: '请回到对应仓库的代码页打开此链接',
  copy: '复制链接',
  download: '下载',
  iosNotSupportDown: 'IOS不支持下载',
  downloadDescription: '正在下载：',
  userCreate: '创建于：',
  profileJoined: '加入时间：%s',
  history: '浏览历史',
  about: '关于',
  version: '版本',
  appVersionPrefix: '版本：',
  author: '作者',
  projectUrl: '项目地址',
  feedback: '反馈',
  feedbackHint: '你输入的反馈会变成 issue 提交到 GitHub 仓库，请尽量详细描述你遇到的问题或建议，谢谢！',
  issueSubmitSuccess: '反馈提交成功！',
  issueSubmitFail: '反馈提交失败',
  person: '个人信息',
  infoName: '名字',
  infoEmail: '邮箱',
  infoBlog: '链接',
  infoCompany: '公司',
  infoLocation: '位置',
  infoBio: '简介',
  editField: '编辑 %{option1}',
  userInfoUpdateSuccess: '用户信息更新成功！',
  userInfoUpdateFail: '更新用户信息失败。',
  unFollowed: '取消关注',
  doFollowed: '关注',
  register: 'Github注册',
  notFound: '请求找不到地址啦·~',
  errorUnKnow: '就是不知道是什么错误···',
  noPower: '为啥你没有权限呢？',
  share: '分享',
  newestVersion: '当前是最新版本',
  updateDialogTitle: '发现新版本',
  updateDialogVersionLabel: '版本',
  openLinkFailed: '无法打开浏览器，请手动复制链接',
  beStared100Title: ' 最受欢迎前100仓库',
  update: '更新',
  weekClosed: '本周关闭: ',
  weekOpened: '本周打开: ',
  thisWeek: ' 本周动态 ',
  userOrg: '组织',
  reloadClick: '点击重新加载',
  language: '语言',
  systemLanguage: '系统',
  zhLanguage: '中文',
  enLanguage: '英文',
  gone410: '410 Gone，不存在吧？',
  clearCache: '清除缓存',
  loginExpired: '登录已过期，请重新登录',
  networkOffline: '网络已断开',
  networkOnline: '网络已恢复',
  contributionTitle: '贡献热力图',
  contributionEmpty: '暂无贡献数据',
  drawerProfile: '个人主页',
  drawerNotify: '消息通知',
  drawerHistory: '浏览历史',
  drawerSearch: '搜索',
  drawerSetting: '设置',
  drawerFeedback: '问题反馈',
  drawerPersonalInfo: '个人信息',
  drawerLanguage: '语言切换',
  drawerCheckUpdate: '检查更新',
  drawerAbout: '关于',
  drawerLogout: '退出登录',
  custom: '自定义',
  customHeaderTitle: '用户自定义脚本',
  customComingSoon: '即将推出',
  customScriptItem1: '用户自定义脚本',
  customScriptHint1: '占位：未来支持注入用户脚本',
  customScriptItem2: '自定义渲染',
  customScriptHint2: '占位：未来支持自定义渲染管线',
  customScriptItem3: '自定义快捷指令',
  customScriptHint3: '占位：未来支持快捷指令绑定',
};

export const translations: Record<LocaleKey, TranslationMap> = {
  'en': enTranslations,
  'zh-CN': zhTranslations,
};

export const defaultLocale: LocaleKey = 'zh-CN';

class I18nStore {
  locale: LocaleKey = defaultLocale;
  fallbackLocale: LocaleKey = defaultLocale;

  setLocale(locale: LocaleKey): void {
    this.locale = locale;
  }

  getLocale(): LocaleKey {
    return this.locale;
  }
}

export const I18nState: I18nStore = new I18nStore();

function readSystemLocale(): string {
  try {
    const sysLocale: string = i18n.System.getSystemLocale();
    return sysLocale !== undefined && sysLocale !== null ? sysLocale : '';
  } catch (e) {
    return '';
  }
}

function normalizeLocale(input: string): LocaleKey {
  const raw: string = input.replace(/_/g, '-');
  if (raw.indexOf('zh-Hans') !== -1) {
    return 'zh-CN';
  }
  if (raw.indexOf('zh-Hant') !== -1 || raw === 'zh-HK' || raw === 'zh-MO') {
    return 'zh-CN';
  }
  if (raw.indexOf('zh') === 0) {
    return 'zh-CN';
  }
  if (raw.indexOf('en') === 0) {
    return 'en';
  }
  return defaultLocale;
}

export function changeLocale(multilingual?: string | null): LocaleKey {
  if (multilingual === undefined || multilingual === null || multilingual === '' || multilingual === 'local') {
    const sys: string = readSystemLocale();
    I18nState.setLocale(normalizeLocale(sys));
    return I18nState.getLocale();
  }
  I18nState.setLocale(normalizeLocale(multilingual));
  return I18nState.getLocale();
}

function applyOptions(template: string, option1?: Record<string, string>, option2?: Record<string, string>): string {
  let result: string = template;
  if (option1 !== undefined && option1 !== null) {
    const keys1: string[] = Object.keys(option1);
    for (let i: number = 0; i < keys1.length; i++) {
      const k: string = keys1[i];
      result = result.split('%{' + k + '}').join(option1[k]);
    }
  }
  if (option2 !== undefined && option2 !== null) {
    const keys2: string[] = Object.keys(option2);
    for (let i: number = 0; i < keys2.length; i++) {
      const k: string = keys2[i];
      result = result.split('%{' + k + '}').join(option2[k]);
    }
  }
  return result;
}

export function I18n(name: keyof TranslationMap, option1?: Record<string, string>, option2?: Record<string, string>): string {
  const current: TranslationMap = translations[I18nState.getLocale()];
  const fallback: TranslationMap = translations[I18nState.fallbackLocale];
  const valueCurrent: string | undefined = (current as object as Record<string, string>)[name as string];
  const valueFallback: string | undefined = (fallback as object as Record<string, string>)[name as string];
  let template: string = '';
  if (valueCurrent !== undefined && valueCurrent !== null && valueCurrent.length > 0) {
    template = valueCurrent;
  } else if (valueFallback !== undefined && valueFallback !== null) {
    template = valueFallback;
  } else {
    template = String(name);
  }
  return applyOptions(template, option1, option2);
}

export default I18n;
