import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { PushDetailPage } from '../../../main/ets/pages/PushDetailPage';
import { CodeDetailPage } from '../../../main/ets/pages/CodeDetailPage';
import { RouteName } from '../../../main/ets/navigation/Routes';

const TARGET_OWNER: string = 'CarGuoUI';
const TARGET_REPO: string = 'GSYTestRepo';
const TARGET_FULL_NAME: string = TARGET_OWNER + '/' + TARGET_REPO;
const TARGET_SHA: string = 'abc1234567890abcdef1234567890abcdef1234';
const STATUS_NOT_FOUND: number = 404;

class PushHostProvider implements HttpProvider {
  callCount: number = 0;
  detailHitCount: number = 0;

  private buildBody(): string {
    const body: Object = {
      'sha': TARGET_SHA,
      'html_url': 'https://github.com/' + TARGET_FULL_NAME + '/commit/' + TARGET_SHA,
      'commit': {
        'message': 'host commit message',
        'author': {
          'name': 'CarGuoAuthor',
          'email': 'author@example.com',
          'date': '2024-01-02T03:04:05Z',
        },
        'committer': {
          'name': 'CarGuoCommitter',
          'email': 'committer@example.com',
          'date': '2024-01-02T03:04:05Z',
        },
      },
      'author': {
        'login': 'CarGuoAuthor',
        'avatar_url': '',
        'html_url': '',
      },
      'committer': {
        'login': 'CarGuoCommitter',
        'avatar_url': '',
        'html_url': '',
      },
      'files': [
        {
          'filename': 'README.md',
          'status': 'modified',
          'additions': 10,
          'deletions': 2,
          'changes': 12,
          'blob_url': '',
          'raw_url': '',
          'patch': '@@ host patch @@',
          'sha': 'sha-readme',
        },
        {
          'filename': 'src/index.ts',
          'status': 'added',
          'additions': 8,
          'deletions': 0,
          'changes': 8,
          'blob_url': '',
          'raw_url': '',
          'patch': '@@ added @@',
          'sha': 'sha-index',
        },
      ],
      'stats': {
        'additions': 18,
        'deletions': 2,
        'total': 20,
      },
    };
    return JSON.stringify(body);
  }

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    if (url === Address.getCommitDetail(TARGET_OWNER, TARGET_REPO, TARGET_SHA) && method === 'GET') {
      this.detailHitCount = this.detailHitCount + 1;
      return new RawResponse(SUCCESS, this.buildBody(), {});
    }
    return new RawResponse(STATUS_NOT_FOUND, '', {});
  }
}

const PUSH_HOST_STUB: PushHostProvider = new PushHostProvider();

export function getPushHostStub(): PushHostProvider {
  return PUSH_HOST_STUB;
}

@Entry
@Component
struct PushDetailHostPage {
  @State navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    HttpManager.setMockProvider(PUSH_HOST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  @Builder
  navMap(name: string): void {
    if (name === RouteName.PushDetail) {
      PushDetailPage();
    } else if (name === RouteName.CodeDetail) {
      CodeDetailPage();
    }
  }

  build(): void {
    Column() {
      Navigation(this.navStack) {
      }
      .id('push_detail_host_nav')
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .navDestination(this.navMap)
      .onAppear((): void => {
        this.navStack.pushPath({
          name: RouteName.PushDetail,
          param: {
            'fullName': TARGET_FULL_NAME,
            'sha': TARGET_SHA,
          } as Record<string, Object>,
        });
      });
    }
    .id('push_detail_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
