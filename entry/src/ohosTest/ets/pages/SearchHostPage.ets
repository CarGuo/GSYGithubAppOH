import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { SearchPage, SearchPageDeps } from '../../../main/ets/pages/SearchPage';
import { SearchStore } from '../../../main/ets/store/SearchStore';
import { SearchService } from '../../../main/ets/service/SearchService';
import {
  SearchHistoryManager,
  SearchHistoryStorage,
  KEY_SEARCH_HISTORY,
} from '../../../main/ets/utils/SearchHistory';

class HostStubProvider implements HttpProvider {
  callCount: number = 0;

  private buildReposBody(): string {
    const items: Object[] = [
      {
        'id': 1,
        'name': 'GSYGithubApp',
        'full_name': 'CarGuoUI/GSYGithubApp',
        'description': 'A GitHub client',
        'language': 'JavaScript',
        'stargazers_count': 12345,
        'forks_count': 100,
        'watchers_count': 200,
        'html_url': 'https://github.com/CarGuoUI/GSYGithubApp',
        'owner': { 'id': 1001, 'login': 'CarGuoUI', 'avatar_url': '' },
      },
      {
        'id': 2,
        'name': 'GSYGithubAppOH',
        'full_name': 'CarGuoUI/GSYGithubAppOH',
        'description': 'A HarmonyOS client',
        'language': 'TypeScript',
        'stargazers_count': 678,
        'forks_count': 50,
        'watchers_count': 80,
        'html_url': 'https://github.com/CarGuoUI/GSYGithubAppOH',
        'owner': { 'id': 1002, 'login': 'CarGuoUI', 'avatar_url': '' },
      },
    ];
    const body: Record<string, Object> = {
      'total_count': 2,
      'incomplete_results': false,
      'items': items as Object,
    };
    return JSON.stringify(body);
  }

  private buildUsersBody(): string {
    const items: Object[] = [
      {
        'id': 100,
        'login': 'CarGuo',
        'avatar_url': '',
        'html_url': 'https://github.com/CarGuo',
        'type': 'User',
      },
      {
        'id': 101,
        'login': 'CarGuoUI',
        'avatar_url': '',
        'html_url': 'https://github.com/CarGuoUI',
        'type': 'Organization',
      },
    ];
    const body: Record<string, Object> = {
      'total_count': 2,
      'incomplete_results': false,
      'items': items as Object,
    };
    return JSON.stringify(body);
  }

  private buildIssuesBody(): string {
    const items: Object[] = [
      {
        'id': 200,
        'number': 1,
        'title': 'Hello issue title',
        'state': 'open',
        'body': 'issue body',
        'html_url': 'https://github.com/x/y/issues/1',
        'repository_url': 'https://api.github.com/repos/x/y',
        'comments': 1,
        'user': { 'id': 1001, 'login': 'CarGuo', 'avatar_url': '' },
      },
    ];
    const body: Record<string, Object> = {
      'total_count': 1,
      'incomplete_results': false,
      'items': items as Object,
    };
    return JSON.stringify(body);
  }

  async request(url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    if (url.indexOf('search/users') >= 0) {
      return new RawResponse(SUCCESS, this.buildUsersBody(), {});
    }
    if (url.indexOf('search/issues') >= 0) {
      return new RawResponse(SUCCESS, this.buildIssuesBody(), {});
    }
    return new RawResponse(SUCCESS, this.buildReposBody(), {});
  }
}

class HostMemoryHistoryStorage implements SearchHistoryStorage {
  data: Map<string, string> = new Map<string, string>();

  async putString(key: string, value: string): Promise<void> {
    this.data.set(key, value);
  }

  async getString(key: string, defValue: string): Promise<string> {
    if (this.data.has(key)) {
      return this.data.get(key) as string;
    }
    return defValue;
  }

  async remove(key: string): Promise<void> {
    this.data.delete(key);
  }
}

const HOST_STUB: HostStubProvider = new HostStubProvider();
const HOST_HISTORY_STORAGE: HostMemoryHistoryStorage = new HostMemoryHistoryStorage();
const HOST_HISTORY: SearchHistoryManager = new SearchHistoryManager(HOST_HISTORY_STORAGE,
  KEY_SEARCH_HISTORY, 20);
const HOST_STORE: SearchStore = new SearchStore();
const HOST_SERVICE: SearchService = new SearchService(HOST_STORE);

@Entry
@Component
struct SearchHostPage {
  aboutToAppear(): void {
    HOST_HISTORY_STORAGE.data.clear();
    HOST_HISTORY_STORAGE.data.set(KEY_SEARCH_HISTORY,
      JSON.stringify(['react', 'flutter']));
    HOST_STORE.reset();
    SearchPageDeps.setStore(HOST_STORE);
    SearchPageDeps.setService(HOST_SERVICE);
    SearchPageDeps.setHistory(HOST_HISTORY);
    HttpManager.setMockProvider(HOST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
    SearchPageDeps.reset();
  }

  build(): void {
    Column() {
      SearchPage()
        .layoutWeight(1);
    }
    .id('search_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
