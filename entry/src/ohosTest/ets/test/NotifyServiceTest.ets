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
  NotifyService,
  FetchNotifyResult,
  MarkNotifyResult,
  NotifyFilterParam,
  resolveFilterParam,
} from '../../../main/ets/service/NotifyService';
import {
  NotifyStore,
  NotifyThread,
  NotifySubject,
  NotifyRepository,
  NOTIFY_FILTER_UNREAD,
  NOTIFY_FILTER_PARTICIPATING,
  NOTIFY_FILTER_ALL,
} from '../../../main/ets/store/NotifyStore';

class CapturedRequest {
  url: string = '';
  method: string = '';
}

class FakeHttpProvider implements HttpProvider {
  nextStatus: number = SUCCESS;
  nextBody: string = '{}';
  nextHeaders: HttpHeaders = {};
  shouldThrow: boolean = false;
  callCount: number = 0;
  captured: CapturedRequest = new CapturedRequest();
  capturedAll: CapturedRequest[] = [];
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
    const c: CapturedRequest = new CapturedRequest();
    c.url = url;
    c.method = method;
    this.capturedAll.push(c);
    if (this.shouldThrow) {
      throw new Error('boom');
    }
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
const REPO_FULL: string = 'CarGuo/GSYGithubAppOH';
const STATUS_NO_CONTENT: number = 204;

function buildSubject(title: string, url: string, type: string): NotifySubject {
  return {
    'title': title,
    'url': url,
    'latest_comment_url': '',
    'type': type,
  } as NotifySubject;
}

function buildRepository(fullName: string): NotifyRepository {
  const slash: number = fullName.indexOf('/');
  const owner: string = slash >= 0 ? fullName.substring(0, slash) : fullName;
  const name: string = slash >= 0 ? fullName.substring(slash + 1) : '';
  return {
    'id': 1,
    'name': name,
    'full_name': fullName,
    'owner_login': owner,
    'html_url': '',
  } as NotifyRepository;
}

function buildThread(id: string, title: string, type: string, unread: boolean): NotifyThread {
  return {
    'id': id,
    'unread': unread,
    'reason': 'mention',
    'updated_at': '2024-01-01T00:00:00Z',
    'last_read_at': '',
    'url': 'https://api.github.com/notifications/threads/' + id,
    'subject': buildSubject(title, 'https://api.github.com/repos/' + REPO_FULL + '/issues/1', type),
    'repository': buildRepository(REPO_FULL),
  } as NotifyThread;
}

function buildThreads(count: number): NotifyThread[] {
  const out: NotifyThread[] = [];
  for (let i = 0; i < count; i++) {
    out.push(buildThread('t' + i.toString(), 'title-' + i.toString(), 'Issue', true));
  }
  return out;
}

export default function NotifyServiceTest(): void {
  describe('NotifyServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let store: NotifyStore;
    let service: NotifyService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      store = new NotifyStore();
      service = new NotifyService(store, PAGE_SIZE);

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

    it('resolveFilterParam_unread_maps_to_all_false_participating_false', 0, (): void => {
      const p: NotifyFilterParam = resolveFilterParam(NOTIFY_FILTER_UNREAD);
      expect(p.all).assertFalse();
      expect(p.participating).assertFalse();
    });

    it('resolveFilterParam_participating_maps_to_all_false_participating_true', 0, (): void => {
      const p: NotifyFilterParam = resolveFilterParam(NOTIFY_FILTER_PARTICIPATING);
      expect(p.all).assertFalse();
      expect(p.participating).assertTrue();
    });

    it('resolveFilterParam_all_maps_to_all_true_participating_false', 0, (): void => {
      const p: NotifyFilterParam = resolveFilterParam(NOTIFY_FILTER_ALL);
      expect(p.all).assertTrue();
      expect(p.participating).assertFalse();
    });

    it('getNotifications_unread_uses_all_false_and_participating_false_in_url', 0,
      async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(buildThreads(PAGE_SIZE));

        const res: FetchNotifyResult = await service.getNotifications(NOTIFY_FILTER_UNREAD, 1);

        expect(res.result).assertTrue();
        const expected: string = Address.getNotifications(false, false, 1, PAGE_SIZE);
        expect(provider.captured.url).assertEqual(expected);
        expect(provider.captured.method).assertEqual('GET');
        expect(store.list.length).assertEqual(PAGE_SIZE);
        expect(store.filter).assertEqual(NOTIFY_FILTER_UNREAD);
        expect(store.page).assertEqual(1);
        expect(store.hasMore).assertTrue();
      });

    it('getNotifications_participating_uses_all_false_and_participating_true_in_url', 0,
      async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(buildThreads(2));

        const res: FetchNotifyResult = await service.getNotifications(
          NOTIFY_FILTER_PARTICIPATING, 1);

        expect(res.result).assertTrue();
        const expected: string = Address.getNotifications(false, true, 1, PAGE_SIZE);
        expect(provider.captured.url).assertEqual(expected);
        expect(store.filter).assertEqual(NOTIFY_FILTER_PARTICIPATING);
        expect(store.list.length).assertEqual(2);
        expect(store.hasMore).assertFalse();
      });

    it('getNotifications_all_uses_all_true_and_participating_false_in_url', 0,
      async (): Promise<void> => {
        provider.nextStatus = SUCCESS;
        provider.nextBody = JSON.stringify(buildThreads(PAGE_SIZE));

        const res: FetchNotifyResult = await service.getNotifications(NOTIFY_FILTER_ALL, 1);
        expect(res.result).assertTrue();
        const expected: string = Address.getNotifications(true, false, 1, PAGE_SIZE);
        expect(provider.captured.url).assertEqual(expected);
        expect(store.filter).assertEqual(NOTIFY_FILTER_ALL);
      });

    it('getNotifications_appends_on_second_page', 0, async (): Promise<void> => {
      const firstPage: NotifyThread[] = buildThreads(PAGE_SIZE);
      const secondPage: NotifyThread[] = [
        buildThread('t-extra-0', 'extra-0', 'PullRequest', true),
        buildThread('t-extra-1', 'extra-1', 'Commit', false),
      ];
      provider.pushResponse(SUCCESS, JSON.stringify(firstPage));
      provider.pushResponse(SUCCESS, JSON.stringify(secondPage));

      await service.getNotifications(NOTIFY_FILTER_UNREAD, 1);
      await service.getNotifications(NOTIFY_FILTER_UNREAD, 2);

      const expectedSecond: string = Address.getNotifications(false, false, 2, PAGE_SIZE);
      expect(provider.capturedAll.length).assertEqual(2);
      expect(provider.capturedAll[1].url).assertEqual(expectedSecond);
      expect(store.list.length).assertEqual(PAGE_SIZE + 2);
      expect(store.page).assertEqual(2);
      expect(store.hasMore).assertFalse();
    });

    it('getNotifications_returns_unauthorized_and_sets_error_on_401', 0,
      async (): Promise<void> => {
        provider.nextStatus = UNAUTHORIZED;
        provider.nextBody = '';

        const res: FetchNotifyResult = await service.getNotifications(NOTIFY_FILTER_UNREAD, 1);
        expect(res.result).assertFalse();
        expect(res.code).assertEqual(UNAUTHORIZED);
        expect(store.error.length > 0).assertTrue();
        expect(store.list.length).assertEqual(0);
      });

    it('getNotifications_returns_failure_on_network_error', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchNotifyResult = await service.getNotifications(NOTIFY_FILTER_UNREAD, 1);
      expect(res.result).assertFalse();
      expect(store.error.length > 0).assertTrue();
    });

    it('markAsRead_uses_patch_threads_url_and_marks_thread_read', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, JSON.stringify(buildThreads(PAGE_SIZE)));
      await service.getNotifications(NOTIFY_FILTER_UNREAD, 1);

      provider.pushResponse(STATUS_NO_CONTENT, '');
      const res: MarkNotifyResult = await service.markAsRead('t1');

      expect(res.result).assertTrue();
      const expected: string = Address.markNotificationsThread('t1');
      expect(provider.capturedAll[provider.capturedAll.length - 1].url).assertEqual(expected);
      expect(provider.capturedAll[provider.capturedAll.length - 1].method).assertEqual('PATCH');

      let unreadAfter: boolean = true;
      for (let i = 0; i < store.list.length; i++) {
        if (store.list[i].id === 't1') {
          unreadAfter = store.list[i].unread;
        }
      }
      expect(unreadAfter).assertFalse();
    });

    it('markAsRead_returns_unauthorized_on_401', 0, async (): Promise<void> => {
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';
      const res: MarkNotifyResult = await service.markAsRead('t-x');
      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
    });

    it('markAsRead_with_empty_id_does_not_request_network', 0, async (): Promise<void> => {
      const res: MarkNotifyResult = await service.markAsRead('');
      expect(res.result).assertFalse();
      expect(provider.callCount).assertEqual(0);
    });

    it('markAllAsRead_without_repo_uses_put_notifications_url', 0, async (): Promise<void> => {
      provider.nextStatus = STATUS_NO_CONTENT;
      provider.nextBody = '';
      const res: MarkNotifyResult = await service.markAllAsRead();
      expect(res.result).assertTrue();
      expect(provider.captured.url).assertEqual(Address.setAllNotificationAsRead());
      expect(provider.captured.method).assertEqual('PUT');
    });

    it('markAllAsRead_with_repo_uses_put_repos_notifications_url', 0,
      async (): Promise<void> => {
        provider.nextStatus = STATUS_NO_CONTENT;
        provider.nextBody = '';
        const res: MarkNotifyResult = await service.markAllAsRead(REPO_FULL);
        expect(res.result).assertTrue();
        expect(provider.captured.url).assertEqual(Address.markRepoNotifications(REPO_FULL));
        expect(provider.captured.method).assertEqual('PUT');
      });

    it('markAllAsRead_returns_unauthorized_on_401', 0, async (): Promise<void> => {
      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';
      const res: MarkNotifyResult = await service.markAllAsRead();
      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
    });

    it('store_filter_resets_list_when_filter_changes', 0, async (): Promise<void> => {
      provider.pushResponse(SUCCESS, JSON.stringify(buildThreads(PAGE_SIZE)));
      await service.getNotifications(NOTIFY_FILTER_UNREAD, 1);
      expect(store.list.length).assertEqual(PAGE_SIZE);

      provider.pushResponse(SUCCESS, JSON.stringify(buildThreads(1)));
      await service.getNotifications(NOTIFY_FILTER_ALL, 1);
      expect(store.filter).assertEqual(NOTIFY_FILTER_ALL);
      expect(store.list.length).assertEqual(1);
    });
  });
}
