import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
  TokenStorage,
  LoginExpiredBus,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS, NETWORK_ERROR, UNAUTHORIZED } from '../../../main/ets/net/NetworkCode';
import {
  ContributionService,
  CONTRIBUTION_API_HOST,
  ContributionResp,
  ContributionRespItem,
  FetchContributionsResult,
} from '../../../main/ets/service/ContributionService';
import {
  ContributionStore,
  ContributionDay,
} from '../../../main/ets/store/ContributionStore';

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

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.captured.url = url;
    this.captured.method = method;
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

const TEST_LOGIN: string = 'CarGuo';

function buildResp(items: ContributionRespItem[]): ContributionResp {
  const totals: Record<string, number> = { 'lastYear': items.length };
  const r: ContributionResp = {
    'total': totals,
    'contributions': items,
  } as ContributionResp;
  return r;
}

function buildItem(date: string, count: number, level: number): ContributionRespItem {
  return {
    'date': date,
    'count': count,
    'level': level,
  } as ContributionRespItem;
}

export default function ContributionServiceTest(): void {
  describe('ContributionServiceTest', (): void => {
    let provider: FakeHttpProvider;
    let storage: FakeTokenStorage;
    let store: ContributionStore;
    let service: ContributionService;

    beforeEach((): void => {
      provider = new FakeHttpProvider();
      storage = new FakeTokenStorage();
      store = new ContributionStore();
      service = new ContributionService(store);

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

    it('buildUrl_concats_host_and_login', 0, (): void => {
      const url: string = ContributionService.buildUrl(TEST_LOGIN);
      expect(url).assertEqual(`${CONTRIBUTION_API_HOST}${TEST_LOGIN}`);
      expect(url).assertEqual(`https://github-contributions-api.jogruber.de/v4/${TEST_LOGIN}`);
    });

    it('getContributions_uses_correct_url_and_get_method', 0, async (): Promise<void> => {
      const items: ContributionRespItem[] = [
        buildItem('2025-01-01', 0, 0),
        buildItem('2025-01-02', 1, 1),
      ];
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(buildResp(items));

      const res: FetchContributionsResult = await service.getContributions(TEST_LOGIN);

      expect(res.result).assertTrue();
      expect(res.fromCache).assertFalse();
      expect(provider.captured.url)
        .assertEqual(`https://github-contributions-api.jogruber.de/v4/${TEST_LOGIN}`);
      expect(provider.captured.method).assertEqual('GET');
      expect(store.days.length).assertEqual(2);
      expect(store.error).assertEqual('');
      expect(store.loading).assertFalse();
    });

    it('getContributions_parses_levels_within_bounds', 0, async (): Promise<void> => {
      const items: ContributionRespItem[] = [
        buildItem('2025-01-01', 0, 0),
        buildItem('2025-01-02', 1, 1),
        buildItem('2025-01-03', 5, 2),
        buildItem('2025-01-04', 10, 3),
        buildItem('2025-01-05', 20, 4),
      ];
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(buildResp(items));

      const res: FetchContributionsResult = await service.getContributions(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(5);
      expect(res.data[0].level).assertEqual(0);
      expect(res.data[1].level).assertEqual(1);
      expect(res.data[2].level).assertEqual(2);
      expect(res.data[3].level).assertEqual(3);
      expect(res.data[4].level).assertEqual(4);
      expect(store.days[0].level).assertEqual(0);
      expect(store.days[4].level).assertEqual(4);
    });

    it('getContributions_clamps_level_below_zero_to_zero', 0, async (): Promise<void> => {
      const items: ContributionRespItem[] = [
        buildItem('2025-01-01', 0, -3),
      ];
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(buildResp(items));

      const res: FetchContributionsResult = await service.getContributions(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.data.length).assertEqual(1);
      expect(res.data[0].level).assertEqual(0);
      expect(store.days[0].level).assertEqual(0);
    });

    it('getContributions_clamps_level_above_four_to_four', 0, async (): Promise<void> => {
      const items: ContributionRespItem[] = [
        buildItem('2025-01-01', 999, 9),
      ];
      provider.nextStatus = SUCCESS;
      provider.nextBody = JSON.stringify(buildResp(items));

      const res: FetchContributionsResult = await service.getContributions(TEST_LOGIN);
      expect(res.result).assertTrue();
      expect(res.data[0].level).assertEqual(4);
      expect(store.days[0].level).assertEqual(4);
    });

    it('getContributions_propagates_401_through_login_expired_bus', 0, async (): Promise<void> => {
      let fired: number = 0;
      const unsubscribe: () => void = LoginExpiredBus.subscribe((): void => {
        fired = fired + 1;
      });

      provider.nextStatus = UNAUTHORIZED;
      provider.nextBody = '';

      const res: FetchContributionsResult = await service.getContributions(TEST_LOGIN);
      unsubscribe();

      expect(res.result).assertFalse();
      expect(res.code).assertEqual(UNAUTHORIZED);
      expect(fired).assertEqual(1);
      expect(store.error.length > 0).assertTrue();
      expect(store.loading).assertFalse();
    });

    it('getContributions_returns_error_on_network_fail', 0, async (): Promise<void> => {
      provider.nextStatus = NETWORK_ERROR;
      provider.nextBody = '';

      const res: FetchContributionsResult = await service.getContributions(TEST_LOGIN);
      expect(res.result).assertFalse();
      expect(res.fromCache).assertFalse();
      expect(store.days.length).assertEqual(0);
      expect(store.error.length > 0).assertTrue();
    });

    it('getContributions_empty_login_does_not_request', 0, async (): Promise<void> => {
      const res: FetchContributionsResult = await service.getContributions('');
      expect(res.result).assertFalse();
      expect(provider.callCount).assertEqual(0);
      expect(store.error).assertEqual('empty login');
    });

    it('store_apply_days_normalizes_levels', 0, (): void => {
      const days: ContributionDay[] = [
        { 'date': '2025-01-01', 'count': 0, 'level': -1 } as ContributionDay,
        { 'date': '2025-01-02', 'count': 0, 'level': 99 } as ContributionDay,
      ];
      store.applyDays(days, true);
      expect(store.days[0].level).assertEqual(0);
      expect(store.days[1].level).assertEqual(4);
      expect(store.fromCache).assertTrue();
    });
  });
}
