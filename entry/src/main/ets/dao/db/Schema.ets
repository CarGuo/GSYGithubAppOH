export const DB_NAME: string = 'gsygithub_oh.db';
export const DB_VERSION: number = 1;
export const DB_SECURITY_LEVEL: number = 1;

export const TABLE_REPOSITORY_PULSE: string = 'RepositoryPulse';
export const TABLE_READ_HISTORY: string = 'ReadHistory';
export const TABLE_REPOSITORY_BRANCH: string = 'RepositoryBranch';
export const TABLE_REPOSITORY_COMMITS: string = 'RepositoryCommits';
export const TABLE_REPOSITORY_WATCHER: string = 'RepositoryWatcher';
export const TABLE_REPOSITORY_STAR: string = 'RepositoryStar';
export const TABLE_REPOSITORY_FORK: string = 'RepositoryFork';
export const TABLE_REPOSITORY_DETAIL: string = 'RepositoryDetail';
export const TABLE_REPOSITORY_DETAIL_README: string = 'RepositoryDetailReadme';
export const TABLE_REPOSITORY_EVENT: string = 'RepositoryEvent';
export const TABLE_REPOSITORY_FILE_LIST: string = 'RepositoryFileList';
export const TABLE_REPOSITORY_CODE_CONTENT: string = 'RepositoryCodeContent';
export const TABLE_REPOSITORY_ISSUE: string = 'RepositoryIssue';
export const TABLE_REPOSITORY_COMMIT_INFO_DETAIL: string = 'RepositoryCommitInfoDetail';
export const TABLE_TREND_REPOSITORY_V2: string = 'TrendRepositoryV2';
export const TABLE_USER_INFO: string = 'UserInfo';
export const TABLE_USER_FOLLOWER: string = 'UserFollower';
export const TABLE_USER_FOLLOWED: string = 'UserFollowed';
export const TABLE_ORG_MEMBER: string = 'OrgMember';
export const TABLE_USER_ORGS: string = 'UserOrgs';
export const TABLE_USER_STARED: string = 'UserStared';
export const TABLE_USER_REPOS: string = 'UserRepos';
export const TABLE_RECEIVED_EVENT: string = 'ReceivedEvent';
export const TABLE_USER_EVENT: string = 'UserEvent';
export const TABLE_ISSUE_DETAIL: string = 'IssueDetail';
export const TABLE_ISSUE_COMMENT: string = 'IssueComment';

export const SQL_CREATE_REPOSITORY_PULSE: string =
  "CREATE TABLE IF NOT EXISTS RepositoryPulse (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_READ_HISTORY: string =
  "CREATE TABLE IF NOT EXISTS ReadHistory (" +
  "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
  "type TEXT NOT NULL, " +
  "fullName TEXT NOT NULL, " +
  "title TEXT, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_INDEX_READ_HISTORY_FULL: string =
  "CREATE INDEX IF NOT EXISTS idx_read_history_full ON ReadHistory(fullName)";

export const SQL_CREATE_REPOSITORY_BRANCH: string =
  "CREATE TABLE IF NOT EXISTS RepositoryBranch (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_COMMITS: string =
  "CREATE TABLE IF NOT EXISTS RepositoryCommits (" +
  "fullName TEXT NOT NULL, " +
  "branch TEXT, " +
  "page INTEGER NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, branch, page)" +
  ")";

export const SQL_CREATE_REPOSITORY_WATCHER: string =
  "CREATE TABLE IF NOT EXISTS RepositoryWatcher (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_STAR: string =
  "CREATE TABLE IF NOT EXISTS RepositoryStar (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_FORK: string =
  "CREATE TABLE IF NOT EXISTS RepositoryFork (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_DETAIL: string =
  "CREATE TABLE IF NOT EXISTS RepositoryDetail (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_DETAIL_README: string =
  "CREATE TABLE IF NOT EXISTS RepositoryDetailReadme (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "branch TEXT, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_EVENT: string =
  "CREATE TABLE IF NOT EXISTS RepositoryEvent (" +
  "fullName TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_REPOSITORY_FILE_LIST: string =
  "CREATE TABLE IF NOT EXISTS RepositoryFileList (" +
  "fullName TEXT NOT NULL, " +
  "branch TEXT NOT NULL, " +
  "path TEXT NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, branch, path)" +
  ")";

export const SQL_CREATE_REPOSITORY_CODE_CONTENT: string =
  "CREATE TABLE IF NOT EXISTS RepositoryCodeContent (" +
  "fullName TEXT NOT NULL, " +
  "branch TEXT NOT NULL, " +
  "path TEXT NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, branch, path)" +
  ")";

export const SQL_CREATE_REPOSITORY_ISSUE: string =
  "CREATE TABLE IF NOT EXISTS RepositoryIssue (" +
  "fullName TEXT NOT NULL, " +
  "state TEXT NOT NULL, " +
  "page INTEGER NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, state, page)" +
  ")";

export const SQL_CREATE_REPOSITORY_COMMIT_INFO_DETAIL: string =
  "CREATE TABLE IF NOT EXISTS RepositoryCommitInfoDetail (" +
  "fullName TEXT NOT NULL, " +
  "sha TEXT NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, sha)" +
  ")";

export const SQL_CREATE_TREND_REPOSITORY_V2: string =
  "CREATE TABLE IF NOT EXISTS TrendRepositoryV2 (" +
  "since TEXT NOT NULL, " +
  "lang TEXT NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (since, lang)" +
  ")";

export const SQL_CREATE_USER_INFO: string =
  "CREATE TABLE IF NOT EXISTS UserInfo (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_USER_FOLLOWER: string =
  "CREATE TABLE IF NOT EXISTS UserFollower (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_USER_FOLLOWED: string =
  "CREATE TABLE IF NOT EXISTS UserFollowed (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_ORG_MEMBER: string =
  "CREATE TABLE IF NOT EXISTS OrgMember (" +
  "org TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_USER_ORGS: string =
  "CREATE TABLE IF NOT EXISTS UserOrgs (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_USER_STARED: string =
  "CREATE TABLE IF NOT EXISTS UserStared (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_USER_REPOS: string =
  "CREATE TABLE IF NOT EXISTS UserRepos (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_RECEIVED_EVENT: string =
  "CREATE TABLE IF NOT EXISTS ReceivedEvent (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_USER_EVENT: string =
  "CREATE TABLE IF NOT EXISTS UserEvent (" +
  "login TEXT PRIMARY KEY NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER" +
  ")";

export const SQL_CREATE_ISSUE_DETAIL: string =
  "CREATE TABLE IF NOT EXISTS IssueDetail (" +
  "fullName TEXT NOT NULL, " +
  "number INTEGER NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, number)" +
  ")";

export const SQL_CREATE_ISSUE_COMMENT: string =
  "CREATE TABLE IF NOT EXISTS IssueComment (" +
  "fullName TEXT NOT NULL, " +
  "number INTEGER NOT NULL, " +
  "page INTEGER NOT NULL, " +
  "data TEXT NOT NULL, " +
  "updateAt INTEGER, " +
  "PRIMARY KEY (fullName, number, page)" +
  ")";

export const ALL_CREATE_SQL: string[] = [
  SQL_CREATE_REPOSITORY_PULSE,
  SQL_CREATE_READ_HISTORY,
  SQL_INDEX_READ_HISTORY_FULL,
  SQL_CREATE_REPOSITORY_BRANCH,
  SQL_CREATE_REPOSITORY_COMMITS,
  SQL_CREATE_REPOSITORY_WATCHER,
  SQL_CREATE_REPOSITORY_STAR,
  SQL_CREATE_REPOSITORY_FORK,
  SQL_CREATE_REPOSITORY_DETAIL,
  SQL_CREATE_REPOSITORY_DETAIL_README,
  SQL_CREATE_REPOSITORY_EVENT,
  SQL_CREATE_REPOSITORY_FILE_LIST,
  SQL_CREATE_REPOSITORY_CODE_CONTENT,
  SQL_CREATE_REPOSITORY_ISSUE,
  SQL_CREATE_REPOSITORY_COMMIT_INFO_DETAIL,
  SQL_CREATE_TREND_REPOSITORY_V2,
  SQL_CREATE_USER_INFO,
  SQL_CREATE_USER_FOLLOWER,
  SQL_CREATE_USER_FOLLOWED,
  SQL_CREATE_ORG_MEMBER,
  SQL_CREATE_USER_ORGS,
  SQL_CREATE_USER_STARED,
  SQL_CREATE_USER_REPOS,
  SQL_CREATE_RECEIVED_EVENT,
  SQL_CREATE_USER_EVENT,
  SQL_CREATE_ISSUE_DETAIL,
  SQL_CREATE_ISSUE_COMMENT
];

export const ALL_TABLES: string[] = [
  TABLE_REPOSITORY_PULSE,
  TABLE_READ_HISTORY,
  TABLE_REPOSITORY_BRANCH,
  TABLE_REPOSITORY_COMMITS,
  TABLE_REPOSITORY_WATCHER,
  TABLE_REPOSITORY_STAR,
  TABLE_REPOSITORY_FORK,
  TABLE_REPOSITORY_DETAIL,
  TABLE_REPOSITORY_DETAIL_README,
  TABLE_REPOSITORY_EVENT,
  TABLE_REPOSITORY_FILE_LIST,
  TABLE_REPOSITORY_CODE_CONTENT,
  TABLE_REPOSITORY_ISSUE,
  TABLE_REPOSITORY_COMMIT_INFO_DETAIL,
  TABLE_TREND_REPOSITORY_V2,
  TABLE_USER_INFO,
  TABLE_USER_FOLLOWER,
  TABLE_USER_FOLLOWED,
  TABLE_ORG_MEMBER,
  TABLE_USER_ORGS,
  TABLE_USER_STARED,
  TABLE_USER_REPOS,
  TABLE_RECEIVED_EVENT,
  TABLE_USER_EVENT,
  TABLE_ISSUE_DETAIL,
  TABLE_ISSUE_COMMENT
];
