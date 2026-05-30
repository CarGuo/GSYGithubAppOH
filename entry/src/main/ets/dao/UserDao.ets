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
  TABLE_USER_INFO,
  TABLE_USER_FOLLOWER,
  TABLE_USER_FOLLOWED,
  TABLE_ORG_MEMBER,
  TABLE_USER_ORGS,
  TABLE_USER_STARED,
  TABLE_USER_REPOS
} from './db/Schema';

export const USER_TABLE_INFO: string = TABLE_USER_INFO;
export const USER_TABLE_FOLLOWER: string = TABLE_USER_FOLLOWER;
export const USER_TABLE_FOLLOWED: string = TABLE_USER_FOLLOWED;
export const USER_TABLE_ORG_MEMBER: string = TABLE_ORG_MEMBER;
export const USER_TABLE_ORGS: string = TABLE_USER_ORGS;
export const USER_TABLE_STARED: string = TABLE_USER_STARED;
export const USER_TABLE_REPOS: string = TABLE_USER_REPOS;

export class UserDao {
  private store: RdbStoreLike;
  private specs: Map<string, TableSpec>;

  constructor(store?: RdbStoreLike) {
    this.store = store !== undefined ? store : defaultStore();
    this.specs = new Map<string, TableSpec>();
    this.specs.set(USER_TABLE_INFO, new TableSpec(USER_TABLE_INFO, ['login']));
    this.specs.set(USER_TABLE_FOLLOWER, new TableSpec(USER_TABLE_FOLLOWER, ['login']));
    this.specs.set(USER_TABLE_FOLLOWED, new TableSpec(USER_TABLE_FOLLOWED, ['login']));
    this.specs.set(USER_TABLE_ORG_MEMBER, new TableSpec(USER_TABLE_ORG_MEMBER, ['org']));
    this.specs.set(USER_TABLE_ORGS, new TableSpec(USER_TABLE_ORGS, ['login']));
    this.specs.set(USER_TABLE_STARED, new TableSpec(USER_TABLE_STARED, ['login']));
    this.specs.set(USER_TABLE_REPOS, new TableSpec(USER_TABLE_REPOS, ['login']));
  }

  private specOf(table: string): TableSpec {
    const spec: TableSpec | undefined = this.specs.get(table);
    if (spec === undefined) {
      throw new Error('UserDao unknown table: ' + table);
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
      USER_TABLE_INFO,
      USER_TABLE_FOLLOWER,
      USER_TABLE_FOLLOWED,
      USER_TABLE_ORG_MEMBER,
      USER_TABLE_ORGS,
      USER_TABLE_STARED,
      USER_TABLE_REPOS
    ];
    for (let i = 0; i < tables.length; i++) {
      total = total + await clearTable(this.store, tables[i]);
    }
    return total;
  }

  saveUserInfo(login: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_INFO, login, jsonString);
  }

  readUserInfo(login: string): Promise<ReadResult> {
    return this.read(USER_TABLE_INFO, login);
  }

  saveFollower(login: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_FOLLOWER, login, jsonString);
  }

  readFollower(login: string): Promise<ReadResult> {
    return this.read(USER_TABLE_FOLLOWER, login);
  }

  saveFollowed(login: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_FOLLOWED, login, jsonString);
  }

  readFollowed(login: string): Promise<ReadResult> {
    return this.read(USER_TABLE_FOLLOWED, login);
  }

  saveOrgMember(org: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_ORG_MEMBER, org, jsonString);
  }

  readOrgMember(org: string): Promise<ReadResult> {
    return this.read(USER_TABLE_ORG_MEMBER, org);
  }

  saveUserOrgs(login: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_ORGS, login, jsonString);
  }

  readUserOrgs(login: string): Promise<ReadResult> {
    return this.read(USER_TABLE_ORGS, login);
  }

  saveUserStared(login: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_STARED, login, jsonString);
  }

  readUserStared(login: string): Promise<ReadResult> {
    return this.read(USER_TABLE_STARED, login);
  }

  saveUserRepos(login: string, jsonString: string): Promise<number> {
    return this.save(USER_TABLE_REPOS, login, jsonString);
  }

  readUserRepos(login: string): Promise<ReadResult> {
    return this.read(USER_TABLE_REPOS, login);
  }
}
