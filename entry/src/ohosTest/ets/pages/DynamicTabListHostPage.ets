import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { DynamicTabPage } from '../../../main/ets/pages/tabs/DynamicTabPage';

class ListProvider implements HttpProvider {
  callCount: number = 0;

  private buildBody(): string {
    const items: Object[] = [
      {
        'id': 'evt-0',
        'type': 'PushEvent',
        'actor': {
          'id': 1,
          'login': 'CarGuoUI',
          'display_login': 'CarGuoUI',
          'avatar_url': '',
        },
        'repo': {
          'id': 11,
          'name': 'CarGuoUI/RepoZero',
          'url': '',
        },
        'created_at': '2024-01-01T00:00:00Z',
        'payload': {} as Record<string, Object>,
      },
      {
        'id': 'evt-1',
        'type': 'WatchEvent',
        'actor': {
          'id': 2,
          'login': 'CarGuoUITwo',
          'display_login': 'CarGuoUITwo',
          'avatar_url': '',
        },
        'repo': {
          'id': 12,
          'name': 'CarGuoUI/RepoOne',
          'url': '',
        },
        'created_at': '2024-01-02T00:00:00Z',
        'payload': {} as Record<string, Object>,
      },
    ];
    return JSON.stringify(items);
  }

  async request(_url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    return new RawResponse(SUCCESS, this.buildBody(), {});
  }
}

const LIST_STUB: ListProvider = new ListProvider();

@Entry
@Component
struct DynamicTabListHostPage {
  aboutToAppear(): void {
    HttpManager.setMockProvider(LIST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  build(): void {
    Column() {
      DynamicTabPage({ user: 'CarGuoUI' })
        .layoutWeight(1);
    }
    .id('dynamic_host_list_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
