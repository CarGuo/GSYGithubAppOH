import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { CodeDetailPage } from '../../../main/ets/pages/CodeDetailPage';
import { RouteName } from '../../../main/ets/navigation/Routes';

const TARGET_OWNER: string = 'CarGuoUI';
const TARGET_REPO: string = 'GSYTestRepo';
const TARGET_FULL_NAME: string = TARGET_OWNER + '/' + TARGET_REPO;
const TARGET_BRANCH: string = 'master';
const TARGET_PATH: string = 'docs/README.md';
const STATUS_NOT_FOUND: number = 404;

class CodeHostProvider implements HttpProvider {
  callCount: number = 0;
  rawHitCount: number = 0;
  apiHitCount: number = 0;

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    const rawUrl: string = Address.getRawFile(TARGET_OWNER, TARGET_REPO, TARGET_BRANCH, TARGET_PATH);
    const apiUrl: string = Address.getReposFileDir(TARGET_OWNER, TARGET_REPO, TARGET_PATH, TARGET_BRANCH);
    if (url === rawUrl && method === 'GET') {
      this.rawHitCount = this.rawHitCount + 1;
      return new RawResponse(SUCCESS, '# Hello nested\nprint("hi")\n', {});
    }
    if (url === apiUrl && method === 'GET') {
      this.apiHitCount = this.apiHitCount + 1;
      const body: Object = {
        'content': 'IyBIZWxsbwo=',
        'encoding': 'base64',
        'path': TARGET_PATH,
        'name': 'README.md',
      };
      return new RawResponse(SUCCESS, JSON.stringify(body), {});
    }
    return new RawResponse(STATUS_NOT_FOUND, '', {});
  }
}

const CODE_HOST_STUB: CodeHostProvider = new CodeHostProvider();

export function getCodeHostStub(): CodeHostProvider {
  return CODE_HOST_STUB;
}

@Entry
@Component
struct CodeDetailHostPage {
  @State navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    HttpManager.setMockProvider(CODE_HOST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  @Builder
  navMap(name: string): void {
    if (name === RouteName.CodeDetail) {
      CodeDetailPage();
    }
  }

  build(): void {
    Column() {
      Navigation(this.navStack) {
      }
      .id('code_detail_host_nav')
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .navDestination(this.navMap)
      .onAppear((): void => {
        this.navStack.pushPath({
          name: RouteName.CodeDetail,
          param: {
            'fullName': TARGET_FULL_NAME,
            'branch': TARGET_BRANCH,
            'path': TARGET_PATH,
          } as Record<string, Object>,
        });
      });
    }
    .id('code_detail_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
