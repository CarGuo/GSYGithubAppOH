import http from '@ohos.net.http';
import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { RepositoryStarPage } from '../../../main/ets/pages/RepositoryStarPage';
import { UserDetailPage } from '../../../main/ets/pages/UserDetailPage';
import { RouteName } from '../../../main/ets/navigation/Routes';

const HOST_OWNER: string = 'CarGuoUI';
const HOST_NAME: string = 'GSYGithubAppOH';
const HOST_FULL_NAME: string = HOST_OWNER + '/' + HOST_NAME;
const STATUS_NO_CONTENT: number = 204;

class SubListHostProvider implements HttpProvider {
  callCount: number = 0;

  private buildStarsBody(): string {
    const users: Object[] = [
      {
        'id': 1,
        'login': 'StarUserOne',
        'avatar_url': '',
        'html_url': 'https://github.com/StarUserOne',
      },
      {
        'id': 2,
        'login': 'StarUserTwo',
        'avatar_url': '',
        'html_url': 'https://github.com/StarUserTwo',
      },
    ];
    return JSON.stringify(users);
  }

  private buildUserInfoBody(login: string): string {
    const user: Object = {
      'id': 99,
      'login': login,
      'name': 'NameOf' + login,
      'avatar_url': '',
      'bio': 'sub list user bio',
      'company': '',
      'location': '',
      'email': '',
      'blog': '',
      'type': 'User',
      'followers': 1,
      'following': 1,
      'public_repos': 1,
      'public_gists': 0,
      'created_at': '2020-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
    return JSON.stringify(user);
  }

  async request(url: string,
                _method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    if (url.indexOf('/repos/' + HOST_FULL_NAME + '/stargazers') >= 0) {
      return new RawResponse(SUCCESS, this.buildStarsBody(), {});
    }
    if (url === Address.getUserInfo('StarUserOne')) {
      return new RawResponse(SUCCESS, this.buildUserInfoBody('StarUserOne'), {});
    }
    if (url === Address.getUserInfo('StarUserTwo')) {
      return new RawResponse(SUCCESS, this.buildUserInfoBody('StarUserTwo'), {});
    }
    if (url.indexOf('/users/StarUserOne/repos') >= 0
      || url.indexOf('/users/StarUserTwo/repos') >= 0) {
      return new RawResponse(SUCCESS, '[]', {});
    }
    if (url === Address.getFollowStatus('StarUserOne')
      || url === Address.getFollowStatus('StarUserTwo')) {
      return new RawResponse(STATUS_NO_CONTENT, '', {});
    }
    return new RawResponse(SUCCESS, '{}', {});
  }
}

const SUB_LIST_HOST_STUB: SubListHostProvider = new SubListHostProvider();

@Entry
@Component
struct SubListHostPage {
  @State navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    HttpManager.setMockProvider(SUB_LIST_HOST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  @Builder
  navMap(name: string): void {
    if (name === RouteName.RepositoryStar) {
      RepositoryStarPage();
    } else if (name === RouteName.UserDetail) {
      UserDetailPage();
    }
  }

  build(): void {
    Column() {
      Navigation(this.navStack) {
      }
      .id('sub_list_host_nav')
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .navDestination(this.navMap)
      .onAppear((): void => {
        this.navStack.pushPath({
          name: RouteName.RepositoryStar,
          param: { 'fullName': HOST_FULL_NAME } as Record<string, Object>,
        });
      });
    }
    .id('sub_list_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}

const _httpKeepAlive: typeof http = http;
