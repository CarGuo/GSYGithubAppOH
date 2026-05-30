import {
  RdbStoreLike,
  TableSpec,
  ReadResult,
  readByKey,
  saveByKey,
  clearTable,
  defaultStore
} from './DaoBase';
import {
  TABLE_REPOSITORY_PULSE,
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
  TABLE_REPOSITORY_COMMIT_INFO_DETAIL
} from './db/Schema';

export const REPO_TABLE_PULSE: string = TABLE_REPOSITORY_PULSE;
export const REPO_TABLE_BRANCH: string = TABLE_REPOSITORY_BRANCH;
export const REPO_TABLE_COMMITS: string = TABLE_REPOSITORY_COMMITS;
export const REPO_TABLE_WATCHER: string = TABLE_REPOSITORY_WATCHER;
export const REPO_TABLE_STAR: string = TABLE_REPOSITORY_STAR;
export const REPO_TABLE_FORK: string = TABLE_REPOSITORY_FORK;
export const REPO_TABLE_DETAIL: string = TABLE_REPOSITORY_DETAIL;
export const REPO_TABLE_DETAIL_README: string = TABLE_REPOSITORY_DETAIL_README;
export const REPO_TABLE_EVENT: string = TABLE_REPOSITORY_EVENT;
export const REPO_TABLE_FILE_LIST: string = TABLE_REPOSITORY_FILE_LIST;
export const REPO_TABLE_CODE_CONTENT: string = TABLE_REPOSITORY_CODE_CONTENT;
export const REPO_TABLE_ISSUE: string = TABLE_REPOSITORY_ISSUE;
export const REPO_TABLE_COMMIT_INFO_DETAIL: string = TABLE_REPOSITORY_COMMIT_INFO_DETAIL;

export class RepositoryDao {
  private store: RdbStoreLike;
  private specs: Map<string, TableSpec>;

  constructor(store?: RdbStoreLike) {
    this.store = store !== undefined ? store : defaultStore();
    this.specs = new Map<string, TableSpec>();
    this.specs.set(REPO_TABLE_PULSE, new TableSpec(REPO_TABLE_PULSE, ['fullName']));
    this.specs.set(REPO_TABLE_BRANCH, new TableSpec(REPO_TABLE_BRANCH, ['fullName']));
    this.specs.set(REPO_TABLE_COMMITS,
      new TableSpec(REPO_TABLE_COMMITS, ['fullName', 'branch', 'page']));
    this.specs.set(REPO_TABLE_WATCHER, new TableSpec(REPO_TABLE_WATCHER, ['fullName']));
    this.specs.set(REPO_TABLE_STAR, new TableSpec(REPO_TABLE_STAR, ['fullName']));
    this.specs.set(REPO_TABLE_FORK, new TableSpec(REPO_TABLE_FORK, ['fullName']));
    this.specs.set(REPO_TABLE_DETAIL, new TableSpec(REPO_TABLE_DETAIL, ['fullName']));
    this.specs.set(REPO_TABLE_DETAIL_README,
      new TableSpec(REPO_TABLE_DETAIL_README, ['fullName']));
    this.specs.set(REPO_TABLE_EVENT, new TableSpec(REPO_TABLE_EVENT, ['fullName']));
    this.specs.set(REPO_TABLE_FILE_LIST,
      new TableSpec(REPO_TABLE_FILE_LIST, ['fullName', 'branch', 'path']));
    this.specs.set(REPO_TABLE_CODE_CONTENT,
      new TableSpec(REPO_TABLE_CODE_CONTENT, ['fullName', 'branch', 'path']));
    this.specs.set(REPO_TABLE_ISSUE,
      new TableSpec(REPO_TABLE_ISSUE, ['fullName', 'state', 'page']));
    this.specs.set(REPO_TABLE_COMMIT_INFO_DETAIL,
      new TableSpec(REPO_TABLE_COMMIT_INFO_DETAIL, ['fullName', 'sha']));
  }

  private specOf(table: string): TableSpec {
    const spec: TableSpec | undefined = this.specs.get(table);
    if (spec === undefined) {
      throw new Error('RepositoryDao unknown table: ' + table);
    }
    return spec;
  }

  save(table: string, key: string, jsonString: string): Promise<number> {
    return saveByKey(this.store, this.specOf(table), key, jsonString);
  }

  read(table: string, key: string): Promise<ReadResult> {
    return readByKey(this.store, this.specOf(table), key);
  }

  clear(table?: string): Promise<number> {
    if (table !== undefined) {
      return clearTable(this.store, this.specOf(table).table);
    }
    return this.clearAll();
  }

  private async clearAll(): Promise<number> {
    let total: number = 0;
    const tables: string[] = [
      REPO_TABLE_PULSE,
      REPO_TABLE_BRANCH,
      REPO_TABLE_COMMITS,
      REPO_TABLE_WATCHER,
      REPO_TABLE_STAR,
      REPO_TABLE_FORK,
      REPO_TABLE_DETAIL,
      REPO_TABLE_DETAIL_README,
      REPO_TABLE_EVENT,
      REPO_TABLE_FILE_LIST,
      REPO_TABLE_CODE_CONTENT,
      REPO_TABLE_ISSUE,
      REPO_TABLE_COMMIT_INFO_DETAIL
    ];
    for (let i = 0; i < tables.length; i++) {
      total = total + await clearTable(this.store, tables[i]);
    }
    return total;
  }

  savePulse(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_PULSE, fullName, jsonString);
  }

  readPulse(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_PULSE, fullName);
  }

  saveBranch(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_BRANCH, fullName, jsonString);
  }

  readBranch(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_BRANCH, fullName);
  }

  saveCommits(fullName: string, branch: string, page: number,
    jsonString: string): Promise<number> {
    const key: string = fullName + '|' + branch + '|' + page.toString();
    return this.save(REPO_TABLE_COMMITS, key, jsonString);
  }

  readCommits(fullName: string, branch: string, page: number): Promise<ReadResult> {
    const key: string = fullName + '|' + branch + '|' + page.toString();
    return this.read(REPO_TABLE_COMMITS, key);
  }

  saveWatcher(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_WATCHER, fullName, jsonString);
  }

  readWatcher(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_WATCHER, fullName);
  }

  saveStar(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_STAR, fullName, jsonString);
  }

  readStar(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_STAR, fullName);
  }

  saveFork(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_FORK, fullName, jsonString);
  }

  readFork(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_FORK, fullName);
  }

  saveDetail(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_DETAIL, fullName, jsonString);
  }

  readDetail(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_DETAIL, fullName);
  }

  saveReadme(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_DETAIL_README, fullName, jsonString);
  }

  readReadme(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_DETAIL_README, fullName);
  }

  saveEvent(fullName: string, jsonString: string): Promise<number> {
    return this.save(REPO_TABLE_EVENT, fullName, jsonString);
  }

  readEvent(fullName: string): Promise<ReadResult> {
    return this.read(REPO_TABLE_EVENT, fullName);
  }

  saveIssue(fullName: string, state: string, page: number,
    jsonString: string): Promise<number> {
    const key: string = fullName + '|' + state + '|' + page.toString();
    return this.save(REPO_TABLE_ISSUE, key, jsonString);
  }

  readIssue(fullName: string, state: string, page: number): Promise<ReadResult> {
    const key: string = fullName + '|' + state + '|' + page.toString();
    return this.read(REPO_TABLE_ISSUE, key);
  }

  saveCommitInfoDetail(fullName: string, sha: string, jsonString: string): Promise<number> {
    const key: string = fullName + '|' + sha;
    return this.save(REPO_TABLE_COMMIT_INFO_DETAIL, key, jsonString);
  }

  readCommitInfoDetail(fullName: string, sha: string): Promise<ReadResult> {
    const key: string = fullName + '|' + sha;
    return this.read(REPO_TABLE_COMMIT_INFO_DETAIL, key);
  }

  saveFile(fullName: string, branch: string, path: string,
    jsonString: string): Promise<number> {
    const safeBranch: string = branch !== null && branch !== undefined ? branch : '';
    const safePath: string = path !== null && path !== undefined ? path : '';
    const key: string = fullName + '|' + safeBranch + '|' + safePath;
    return this.save(REPO_TABLE_FILE_LIST, key, jsonString);
  }

  readFile(fullName: string, branch: string, path: string): Promise<ReadResult> {
    const safeBranch: string = branch !== null && branch !== undefined ? branch : '';
    const safePath: string = path !== null && path !== undefined ? path : '';
    const key: string = fullName + '|' + safeBranch + '|' + safePath;
    return this.read(REPO_TABLE_FILE_LIST, key);
  }

  saveCodeContent(fullName: string, branch: string, path: string,
    rawContent: string): Promise<number> {
    const safeBranch: string = branch !== null && branch !== undefined ? branch : '';
    const safePath: string = path !== null && path !== undefined ? path : '';
    const key: string = fullName + '|' + safeBranch + '|' + safePath;
    return this.save(REPO_TABLE_CODE_CONTENT, key, rawContent);
  }

  readCodeContent(fullName: string, branch: string, path: string): Promise<ReadResult> {
    const safeBranch: string = branch !== null && branch !== undefined ? branch : '';
    const safePath: string = path !== null && path !== undefined ? path : '';
    const key: string = fullName + '|' + safeBranch + '|' + safePath;
    return this.read(REPO_TABLE_CODE_CONTENT, key);
  }
}
