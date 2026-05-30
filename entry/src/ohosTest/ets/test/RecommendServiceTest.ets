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
import { RecommendService, FetchRecommendResult } from '../../../main/ets/service/RecommendService';
import { RecommendRepo, RecommendStore } from '../../../main/ets/store/RecommendStore';

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

const PAGE_SIZE: number = 3;

function buildRepo(id: number, owner: string, name: string,
                   stars: number, language: string): RecommendRepo {
  return {
    'id': id,
    'name': name,
    'full_name': owner + '/' + name,
    'description': name + ' description',
    'language': language,
    'stargazers_count': stars,
    'forks_count': 0,
    'watchers_count': 0,
    'html_url': 'https://github.com/' + owner + '/' + name,
    'owner': {
      'id': id + 1000,
      'login': owner,
      'avatar_url': '',
    },
  } as RecommendRepo;
}

function buildItems(count: number, prefix: string): RecommendRepo[] {
  const out: RecommendRepo[] = [];
  for (let i = 0; i < count; i++) {
    out.push(buildRepo(i + 1, 'CarGuo', prefix + i.toString(), 100 + i, 'TypeScript'));
  }
  return out;
}

function buildBody(items: RecommendRepo[]): string {
  const obj: Record<string, Object> = {
    'total_count': items.length,
    'incomplete_results': false,
    'items': items as Object,
  };
  return JSON.stringify(obj);
}

export default function RecommendServiceTest(): void {
  describe('RecommendServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let store: RecommendStore;
    let service: RecommendService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      store = new RecommendStore();
      service = new RecommendService(store, PAGE_SIZE);

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

    it('uses_search_repos_url_with_page_and_per_page', 0, async (): Promise<void> => {
      const items: RecommendRepo[] = buildItems(PAGE_SIZE, 'r');
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildBody(items);

      await service.fetchRecommend(1);

      const expected: string = Address.getSearchRepos('stars:>1', 'stars', 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(provider.captured.method).assertEqual('GET');
    });

    it('first_page_success_updates_store', 0, async (): Promise<void> => {
      const items: RecommendRepo[] = buildItems(PAGE_SIZE, 'first');
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildBody(items);

      const res: FetchRecommendResult = await service.fetchRecommend(1);

      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(PAGE_SIZE);
      expect(store.list.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);
      expect(store.hasMore).assertTrue();
      expect(store.loading).assertFalse();
      expect(store.error).assertEqual('');
    });

    it('hasMore_true_when_full_page_and_false_when_short_page', 0, async (): Promise<void> => {
      const fullPage: RecommendRepo[] = buildItems(PAGE_SIZE, 'p1');
      const shortPage: RecommendRepo[] = buildItems(1, 'p2');
      provider.pushResponse(SUCCESS, buildBody(fullPage));
      provider.pushResponse(SUCCESS, buildBody(shortPage));

      const r1: FetchRecommendResult = await service.fetchRecommend(1);
      expect(r1.result).assertTrue();
      expect(store.hasMore).assertTrue();
      expect(store.list.length).assertEqual(PAGE_SIZE);
      expect(store.page).assertEqual(1);

      const r2: FetchRecommendResult = await service.fetchRecommend(2);
      expect(r2.result).assertTrue();
      expect(store.hasMore).assertFalse();
      expect(store.list.length).assertEqual(PAGE_SIZE + 1);
      expect(store.page).assertEqual(2);
    });

    it('failure_sets_error_and_keeps_list_empty', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchRecommendResult = await service.fetchRecommend(1);

      expect(res.result).assertFalse();
      expect(res.data.length).assertEqual(0);
      expect(store.list.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
      expect(store.hasMore).assertTrue();
    });

    it('failure_does_not_write_cache_for_hot_stream', 0, async (): Promise<void> => {
      const fullPage: RecommendRepo[] = buildItems(PAGE_SIZE, 'p1');
      provider.pushResponse(SUCCESS, buildBody(fullPage));
      provider.pushResponse(NETWORK_ERROR, '');

      const r1: FetchRecommendResult = await service.fetchRecommend(1);
      expect(r1.result).assertTrue();
      expect(store.list.length).assertEqual(PAGE_SIZE);

      const previousLength: number = store.list.length;
      const r2: FetchRecommendResult = await service.fetchRecommend(2);
      expect(r2.result).assertFalse();
      expect(store.list.length).assertEqual(previousLength);
      expect(store.error.length > 0).assertTrue();
    });

    it('on_401_publishes_login_expired_and_keeps_list_empty', 0, async (): Promise<void> => {
      let fired: number = 0;
      LoginExpiredBus.subscribe((): void => {
        fired = fired + 1;
      });
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '{"message":"Bad credentials"}';

      const res: FetchRecommendResult = await service.fetchRecommend(1);

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(store.list.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('on_401_does_not_pollute_existing_list', 0, async (): Promise<void> => {
      const fullPage: RecommendRepo[] = buildItems(PAGE_SIZE, 'p1');
      provider.pushResponse(SUCCESS, buildBody(fullPage));
      provider.pushResponse(UNAUTHORIZED, '{"message":"Bad credentials"}');

      const r1: FetchRecommendResult = await service.fetchRecommend(1);
      expect(r1.result).assertTrue();
      const beforeList: RecommendRepo[] = store.list.slice();
      expect(beforeList.length).assertEqual(PAGE_SIZE);

      const r2: FetchRecommendResult = await service.fetchRecommend(2);
      expect(r2.result).assertFalse();
      expect(r2.code).assertEqual(UNAUTHORIZED);
      expect(store.list.length).assertEqual(beforeList.length);
      for (let i = 0; i < beforeList.length; i++) {
        expect(store.list[i].full_name).assertEqual(beforeList[i].full_name);
      }
    });

    it('zero_or_negative_page_falls_back_to_page_one', 0, async (): Promise<void> => {
      const items: RecommendRepo[] = buildItems(PAGE_SIZE, 'z');
      provider.nextStatus = SUCCESS;
      provider.nextBody = buildBody(items);

      const res: FetchRecommendResult = await service.fetchRecommend(0);
      expect(res.result).assertTrue();
      const expected: string = Address.getSearchRepos('stars:>1', 'stars', 1, PAGE_SIZE);
      expect(provider.captured.url).assertEqual(expected);
      expect(store.page).assertEqual(1);
    });

    it('default_query_and_sort_are_stars_gt_one_and_stars', 0, (): void => {
      const url: string = Address.getSearchRepos('stars:>1', 'stars', 2, 30);
      expect(url.indexOf('q=stars:>1') >= 0).assertTrue();
      expect(url.indexOf('sort=stars') >= 0).assertTrue();
      expect(url.indexOf('page=2') >= 0).assertTrue();
      expect(url.indexOf('per_page=30') >= 0).assertTrue();
    });
  });
}
