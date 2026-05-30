/**
 * MyTabPage UI 单测的 Host 页：
 *
 *  - 与 [DynamicTabListHostPage](./DynamicTabListHostPage.ets)
 *    / [RecommendTabListHostPage](./RecommendTabListHostPage.ets) 同款
 *    `HttpManager.setMockProvider(...)` 模板，避免真实网络。
 *  - 进入页面前，预先把 `auth.userInfo` 写入 AppStorage，让 `@StorageLink` 镜像
 *    立即拿到一份 user 信息，UI 测用例可以稳定断言头像 / bio / counters / 入口。
 *  - 测试用例侧通过 `MyTabPageDeps.setLoginUseCase(mock)` + `NavigationService.setRouter(fake)`
 *    注入 mock，验证 logout 与入口跳转。
 */

import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { APP_STORAGE_KEY_USER_INFO } from '../../../main/ets/store/AuthStore';
import { MyTabPage } from '../../../main/ets/pages/tabs/MyTabPage';

const HOST_USER_BODY: string =
  '{"login":"CarGuoUI","name":"GsyUI","avatar_url":"",' +
  '"html_url":"https://github.com/CarGuoUI","bio":"Hello GSY UI",' +
  '"followers":7,"following":8,"public_repos":9}';

class MyHostProvider implements HttpProvider {
  callCount: number = 0;

  async request(_url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    return new RawResponse(SUCCESS, HOST_USER_BODY, {});
  }
}

const MY_STUB: MyHostProvider = new MyHostProvider();

@Entry
@Component
struct MyTabPageHost {
  aboutToAppear(): void {
    AppStorage.setOrCreate<string>(APP_STORAGE_KEY_USER_INFO, HOST_USER_BODY);
    HttpManager.setMockProvider(MY_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  build(): void {
    Column() {
      MyTabPage()
        .layoutWeight(1);
    }
    .id('my_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
