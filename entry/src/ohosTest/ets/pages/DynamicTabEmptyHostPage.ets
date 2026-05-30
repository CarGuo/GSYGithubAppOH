import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { DynamicTabPage } from '../../../main/ets/pages/tabs/DynamicTabPage';

class EmptyProvider implements HttpProvider {
  callCount: number = 0;

  async request(_url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    return new RawResponse(SUCCESS, '[]', {});
  }
}

const EMPTY_STUB: EmptyProvider = new EmptyProvider();

@Entry
@Component
struct DynamicTabEmptyHostPage {
  aboutToAppear(): void {
    HttpManager.setMockProvider(EMPTY_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  build(): void {
    Column() {
      DynamicTabPage({ user: 'CarGuoUIEmpty' })
        .layoutWeight(1);
    }
    .id('dynamic_host_empty_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
