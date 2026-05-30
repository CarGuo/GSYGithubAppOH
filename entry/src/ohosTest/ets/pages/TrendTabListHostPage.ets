import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { TrendTabPage } from '../../../main/ets/pages/tabs/TrendTabPage';

class TrendListProvider implements HttpProvider {
  callCount: number = 0;
  lastUrl: string = '';

  private buildBody(): string {
    const items: Object[] = [
      {
        'author': 'CarGuoUI',
        'name': 'TrendDemoZero',
        'avatar': '',
        'url': 'https://github.com/CarGuoUI/TrendDemoZero',
        'description': 'Trend demo description zero',
        'language': 'TypeScript',
        'languageColor': '#3178c6',
        'stars': 1234,
        'forks': 56,
        'currentPeriodStars': 12,
        'builtBy': [] as Object[],
      },
      {
        'author': 'CarGuoUI',
        'name': 'TrendDemoOne',
        'avatar': '',
        'url': 'https://github.com/CarGuoUI/TrendDemoOne',
        'description': 'Trend demo description one',
        'language': 'JavaScript',
        'languageColor': '#f1e05a',
        'stars': 999,
        'forks': 33,
        'currentPeriodStars': 8,
        'builtBy': [] as Object[],
      },
    ];
    return JSON.stringify(items);
  }

  async request(url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    this.lastUrl = url;
    return new RawResponse(SUCCESS, this.buildBody(), {});
  }
}

const TREND_LIST_STUB: TrendListProvider = new TrendListProvider();

@Entry
@Component
struct TrendTabListHostPage {
  aboutToAppear(): void {
    HttpManager.setMockProvider(TREND_LIST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  build(): void {
    Column() {
      TrendTabPage()
        .layoutWeight(1);
    }
    .id('trend_host_list_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
