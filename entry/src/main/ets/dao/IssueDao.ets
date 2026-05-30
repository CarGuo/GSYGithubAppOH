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
  TABLE_REPOSITORY_ISSUE,
  TABLE_ISSUE_DETAIL,
  TABLE_ISSUE_COMMENT
} from './db/Schema';

export const ISSUE_TABLE_REPO_ISSUE: string = TABLE_REPOSITORY_ISSUE;
export const ISSUE_TABLE_DETAIL: string = TABLE_ISSUE_DETAIL;
export const ISSUE_TABLE_COMMENT: string = TABLE_ISSUE_COMMENT;

export class IssueDao {
  private store: RdbStoreLike;
  private specs: Map<string, TableSpec>;

  constructor(store?: RdbStoreLike) {
    this.store = store !== undefined ? store : defaultStore();
    this.specs = new Map<string, TableSpec>();
    this.specs.set(ISSUE_TABLE_REPO_ISSUE,
      new TableSpec(ISSUE_TABLE_REPO_ISSUE, ['fullName', 'state', 'page']));
    this.specs.set(ISSUE_TABLE_DETAIL,
      new TableSpec(ISSUE_TABLE_DETAIL, ['fullName', 'number']));
    this.specs.set(ISSUE_TABLE_COMMENT,
      new TableSpec(ISSUE_TABLE_COMMENT, ['fullName', 'number', 'page']));
  }

  private specOf(table: string): TableSpec {
    const spec: TableSpec | undefined = this.specs.get(table);
    if (spec === undefined) {
      throw new Error('IssueDao unknown table: ' + table);
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
      ISSUE_TABLE_REPO_ISSUE,
      ISSUE_TABLE_DETAIL,
      ISSUE_TABLE_COMMENT
    ];
    for (let i = 0; i < tables.length; i++) {
      total = total + await clearTable(this.store, tables[i]);
    }
    return total;
  }

  saveRepoIssue(fullName: string, state: string, page: number,
    jsonString: string): Promise<number> {
    const key: string = fullName + '|' + state + '|' + page.toString();
    return this.save(ISSUE_TABLE_REPO_ISSUE, key, jsonString);
  }

  readRepoIssue(fullName: string, state: string, page: number): Promise<ReadResult> {
    const key: string = fullName + '|' + state + '|' + page.toString();
    return this.read(ISSUE_TABLE_REPO_ISSUE, key);
  }

  saveIssueDetail(fullName: string, num: number, jsonString: string): Promise<number> {
    const key: string = fullName + '|' + num.toString();
    return this.save(ISSUE_TABLE_DETAIL, key, jsonString);
  }

  readIssueDetail(fullName: string, num: number): Promise<ReadResult> {
    const key: string = fullName + '|' + num.toString();
    return this.read(ISSUE_TABLE_DETAIL, key);
  }

  saveIssueComment(fullName: string, num: number, page: number,
    jsonString: string): Promise<number> {
    const key: string = fullName + '|' + num.toString() + '|' + page.toString();
    return this.save(ISSUE_TABLE_COMMENT, key, jsonString);
  }

  readIssueComment(fullName: string, num: number, page: number): Promise<ReadResult> {
    const key: string = fullName + '|' + num.toString() + '|' + page.toString();
    return this.read(ISSUE_TABLE_COMMENT, key);
  }
}
