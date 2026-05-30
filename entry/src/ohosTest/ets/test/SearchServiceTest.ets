import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS, UNAUTHORIZED, NETWORK_ERROR } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import {
  SearchService,
  SearchRepoResult,
  SearchUserResult,
  SearchIssueResult,
} from '../../../main/ets/service/SearchService';
import {
  SearchStore,
  SearchUserItem,
  SearchIssueItem,
  SEARCH_TAB_REPO,
  SEARCH_TAB_USER,
  SEARCH_TAB_ISSUE,
} from '../../../main/ets/store/SearchStore';
import { RecommendOwner, RecommendRepo } from '../../../main/ets/store/RecommendStore';
import {
  SearchHistoryManager,
  SearchHistoryStorage,
  KEY_SEARCH_HISTORY,
} from '../../../main/ets/utils/SearchHistory';

class CapturedRequest {
  url: string = '';
  method: string = '';
}

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '{}';
  nextHeaders: HttpHeaders = {};
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();
  responses: RawResponse[] = [];

  pushResponse(status: number, body: string): void {
    this.responses.push(new RawResponse(status, body, {}));
  }

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
    if (this.responses.length > 0) {
      const head: RawResponse | undefined = this.responses.shift();
      return head as RawResponse;
    }
    return new RawResponse(this.nextStatus, this.nextBody, this.nextHeaders);
  }
}

class FakeTokenStorage implements TokenStorage {
  value: string | null = null;

  async load(): Promise<string | null> {
    return this.value;
  }

  async save(token: string): Promise<void> {
    this.value = token;
  }

  async clear(): Promise<void> {
    this.value = null;
  }
}

class FakePreferencesRdb implements SearchHistoryStorage {
  data: Map<string, string> = new Map<string, string>();
  putCount: number = 0;
  removeCount: number = 0;

  async putString(key: string, value: string): Promise<void> {
    this.data.set(key, value);
    this.putCount = this.putCount + 1;
  }

  async getString(key: string, defValue: string): Promise<string> {
    if (this.data.has(key)) {
      return this.data.get(key) as string;
    }
    return defValue;
  }

  async remove(key: string): Promise<void> {
    this.data.delete(key);
    this.removeCount = this.removeCount + 1;
  }
}

const PAGE_SIZE: number = 3;

function buildOwner(login: string): RecommendOwner {
  return {
    'id': 1001,
    'login': login,
    'avatar_url': '',
  } as RecommendOwner;
}

function buildRepo(id: number, login: string, name: string): RecommendRepo {
  return {
    'id': id,
    'name': name,
    'full_name': login + '/' + name,
    'description': name + ' description',
    'language': 'TypeScript',
    'stargazers_count': 100 + id,
    'forks_count': 10,
    'watchers_count': 20,
    'html_url': 'https://github.com/' + login + '/' + name,
    'owner': buildOwner(login),
  } as RecommendRepo;
}

function buildUser(id: number, login: string): SearchUserItem {
  return {
    'id': id,
    'login': login,
    'avatar_url': '',
    'html_url': 'https://github.com/' + login,
    'type': 'User',
  } as SearchUserItem;
}

function buildIssue(id: number, num: number, title: string): SearchIssueItem {
  return {
    'id': id,
    'number': num,
    'title': title,
    'state': 'open',
    'body': title + ' body',
    'html_url': 'https://github.com/x/y/issues/' + num.toString(),
    'repository_url': 'https://api.github.com/repos/x/y',
    'comments': 0,
    'user': buildOwner('CarGuo'),
  } as SearchIssueItem;
}

function buildReposBody(items: RecommendRepo[]): string {
  const obj: Record<string, Object> = {
    'total_count': items.length,
    'incomplete_results': false,
    'items': items as Object,
  };
  return JSON.stringify(obj);
}

function buildUsersBody(items: SearchUserItem[]): string {
  const obj: Record<string, Object> = {
    'total_count': items.length,
    'incomplete_results': false,
    'items': items as Object,
  };
  return JSON.stringify(obj);
}

function buildIssuesBody(items: SearchIssueItem[]): string {
  const obj: Record<string, Object> = {
    'total_count': items.length,
    'incomplete_results': false,
    'items': items as Object,
  };
  return JSON.stringify(obj);
}

export default function SearchServiceTest(): void {
  describe('SearchServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let store: SearchStore;
    let service: SearchService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      store = new SearchStore();
      service = new SearchService(store, PAGE_SIZE);

      HttpManager.setMockProvider(provider);
      HttpManager.setTokenStorage(storage);
      HttpManager.setTimeout(15000);
      HttpManager.setAuthorization(null);
      LoginExpiredBus.clear();
    });

    afterEach((): void => {
      HttpManager.setMockProvider(null);
      LoginExpiredBus.clear();
    });

    it('search_repo_uses_search_repos_url', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildReposBody([buildRepo(1, 'CarGuo', 'r1'),
        buildRepo(2, 'CarGuo', 'r2'), buildRepo(3, 'CarGuo', 'r3')]);

      await service.searchRepo('flutter', 'stars', 1);

      const expected: string = Address.getSearchRepos('flutter', 'stars', 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
      expect(store.repos.length).assertEqual(3);
      expect(store.hasMore).assertTrue();
      expect(store.error).assertEqual('');
    });

    it('search_user_uses_search_users_url', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildUsersBody([buildUser(1, 'a'), buildUser(2, 'b')]);

      await service.searchUser('octocat', null, 1);

      const expected: string = Address.getSearchUsers('octocat', null, 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
      expect(store.users.length).assertEqual(2);
      expect(store.hasMore).assertFalse();
    });

    it('search_issue_uses_search_issues_url', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildIssuesBody([buildIssue(1, 1, 'i1'),
        buildIssue(2, 2, 'i2'), buildIssue(3, 3, 'i3')]);

      await service.searchIssue('bug', null, 1);

      const expected: string = Address.getSearchIssues('bug', null, 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
      expect(store.issues.length).assertEqual(3);
      expect(store.hasMore).assertTrue();
    });

    it('search_repo_hasMore_true_full_then_false_short', 0, async (): Promise<void> => {
      const fullPage: RecommendRepo[] = [buildRepo(1, 'A', 'a'), buildRepo(2, 'B', 'b'),
        buildRepo(3, 'C', 'c')];
      const shortPage: RecommendRepo[] = [buildRepo(4, 'D', 'd')];
      provider.pushResponse(SUCCESS, buildReposBody(fullPage));
      provider.pushResponse(SUCCESS, buildReposBody(shortPage));

      const r1: SearchRepoResult = await service.searchRepo('q', 'stars', 1);
      expect(r1.result).assertTrue();
      expect(store.hasMore).assertTrue();
      expect(store.repos.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);

      const r2: SearchRepoResult = await service.searchRepo('q', 'stars', 2);
      expect(r2.result).assertTrue();
      expect(store.hasMore).assertFalse();
      expect(store.repos.length).assertEqual(PAGE_SIZE + 1);
      expect(store.page).assertEqual(2);
    });

    it('search_user_hasMore_paging', 0, async (): Promise<void> => {
      const page1: SearchUserItem[] = [buildUser(1, 'u1'), buildUser(2, 'u2'),
        buildUser(3, 'u3')];
      const page2: SearchUserItem[] = [buildUser(4, 'u4')];
      provider.pushResponse(SUCCESS, buildUsersBody(page1));
      provider.pushResponse(SUCCESS, buildUsersBody(page2));

      const r1: SearchUserResult = await service.searchUser('u', null, 1);
      expect(r1.result).assertTrue();
      expect(store.hasMore).assertTrue();
      expect(store.users.length).assertEqual(PAGE_SIZE);

      const r2: SearchUserResult = await service.searchUser('u', null, 2);
      expect(r2.result).assertTrue();
      expect(store.hasMore).assertFalse();
      expect(store.users.length).assertEqual(PAGE_SIZE + 1);
    });

    it('search_issue_hasMore_paging', 0, async (): Promise<void> => {
      const page1: SearchIssueItem[] = [buildIssue(1, 1, 't1'), buildIssue(2, 2, 't2'),
        buildIssue(3, 3, 't3')];
      const page2: SearchIssueItem[] = [buildIssue(4, 4, 't4')];
      provider.pushResponse(SUCCESS, buildIssuesBody(page1));
      provider.pushResponse(SUCCESS, buildIssuesBody(page2));

      const r1: SearchIssueResult = await service.searchIssue('q', null, 1);
      expect(r1.result).assertTrue();
      expect(store.hasMore).assertTrue();
      expect(store.issues.length).assertEqual(PAGE_SIZE);

      const r2: SearchIssueResult = await service.searchIssue('q', null, 2);
      expect(r2.result).assertTrue();
      expect(store.hasMore).assertFalse();
      expect(store.issues.length).assertEqual(PAGE_SIZE + 1);
    });

    it('search_repo_failure_sets_error_and_keeps_repos_empty', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: SearchRepoResult = await service.searchRepo('q', null, 1);

      expect(res.result).assertFalse();
      expect(store.repos.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('search_repo_401_publishes_login_expired', 0, async (): Promise<void> => {
      let fired: number = 0;
      LoginExpiredBus.subscribe((): void => {
        fired = fired + 1;
      });
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '{"message":"Bad credentials"}';

      const res: SearchRepoResult = await service.searchRepo('q', null, 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(store.repos.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
    });

    it('search_user_401_publishes_login_expired', 0, async (): Promise<void> => {
      let fired: number = 0;
      LoginExpiredBus.subscribe((): void => {
        fired = fired + 1;
      });
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '{"message":"Bad credentials"}';

      const res: SearchUserResult = await service.searchUser('u', null, 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(store.users.length).assertEqual(0);
    });

    it('search_issue_401_publishes_login_expired', 0, async (): Promise<void> => {
      let fired: number = 0;
      LoginExpiredBus.subscribe((): void => {
        fired = fired + 1;
      });
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '{"message":"Bad credentials"}';

      const res: SearchIssueResult = await service.searchIssue('q', null, 1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(store.issues.length).assertEqual(0);
    });

    it('search_by_tab_dispatches_repo_user_issue', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, buildReposBody([buildRepo(1, 'a', 'r')]));
      provider.pushResponse(SUCCESS, buildUsersBody([buildUser(1, 'u')]));
      provider.pushResponse(SUCCESS, buildIssuesBody([buildIssue(1, 1, 'i')]));

      await service.searchByTab(SEARCH_TAB_REPO, 'q', null, 1);
      const url1: string = provider.captured.url;
      expect(url1.indexOf('search/repositories') >= 0).assertTrue();

      await service.searchByTab(SEARCH_TAB_USER, 'q', null, 1);
      const url2: string = provider.captured.url;
      expect(url2.indexOf('search/users') >= 0).assertTrue();

      await service.searchByTab(SEARCH_TAB_ISSUE, 'q', null, 1);
      const url3: string = provider.captured.url;
      expect(url3.indexOf('search/issues') >= 0).assertTrue();
    });

    it('store_set_tab_resets_page_and_hasMore', 0, (): void => {
      store.applyReposRefresh([buildRepo(1, 'a', 'r')], PAGE_SIZE);
      store.page = 5;
      store.hasMore = false;
      store.setTab(SEARCH_TAB_USER);
      expect(store.tab).assertEqual(SEARCH_TAB_USER);
      expect(store.page).assertEqual(1);
      expect(store.hasMore).assertTrue();
    });

    it('zero_or_negative_page_falls_back_to_one', 0, async (): Promise<void> => {
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildReposBody([buildRepo(1, 'a', 'r')]);
      const res: SearchRepoResult = await service.searchRepo('q', null, 0);
      expect(res.result).assertTrue();
      const expected: string = Address.getSearchRepos('q', null, 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
    });
  });

  describe('SearchHistoryTest', (): void => {
    let pref: FakePreferencesRdb;
    let history: SearchHistoryManager;

    beforeEach((): void => {
      pref = new FakePreferencesRdb();
      history = new SearchHistoryManager(pref, KEY_SEARCH_HISTORY, 20);
    });

    it('history_list_initially_empty', 0, async (): Promise<void> => {
      const list: string[] = await history.list();
      expect(list.length).assertEqual(0);
    });

    it('history_add_persists_to_search_history_key_as_json', 0, async (): Promise<void> => {
      await history.add('flutter');
      expect(pref.data.has(KEY_SEARCH_HISTORY)).assertTrue();
      const stored: string = pref.data.get(KEY_SEARCH_HISTORY) as string;
      const parsed: Object = JSON.parse(stored) as Object;
      expect(Array.isArray(parsed)).assertTrue();
      const arr: string[] = parsed as string[];
      expect(arr.length).assertEqual(1);
      expect(arr[0]).assertEqual('flutter');
    });

    it('history_add_dedupe_and_move_to_front', 0, async (): Promise<void> => {
      await history.add('a');
      await history.add('b');
      await history.add('a');
      const list: string[] = await history.list();
      expect(list.length).assertEqual(2);
      expect(list[0]).assertEqual('a');
      expect(list[1]).assertEqual('b');
    });

    it('history_add_keeps_at_most_20', 0, async (): Promise<void> => {
      for (let i = 0; i < 25; i++) {
        await history.add('q' + i.toString());
      }
      const list: string[] = await history.list();
      expect(list.length).assertEqual(20);
      expect(list[0]).assertEqual('q24');
      expect(list[19]).assertEqual('q5');
    });

    it('history_add_empty_or_whitespace_is_no_op', 0, async (): Promise<void> => {
      await history.add('');
      await history.add('   ');
      const list: string[] = await history.list();
      expect(list.length).assertEqual(0);
    });

    it('history_clear_removes_key', 0, async (): Promise<void> => {
      await history.add('x');
      await history.clear();
      expect(pref.data.has(KEY_SEARCH_HISTORY)).assertFalse();
      const list: string[] = await history.list();
      expect(list.length).assertEqual(0);
    });

    it('history_corrupt_json_returns_empty', 0, async (): Promise<void> => {
      await pref.putString(KEY_SEARCH_HISTORY, 'not-a-json');
      const list: string[] = await history.list();
      expect(list.length).assertEqual(0);
    });
  });
}
