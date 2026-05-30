import {
  HttpManager,
  HttpProvider,
  RawResponse,
} from '../../../main/ets/net/HttpManager';
import { HttpHeaders } from '../../../main/ets/net/Result';
import { SUCCESS } from '../../../main/ets/net/NetworkCode';
import { Address } from '../../../main/ets/net/Address';
import { RepositoryDetailPage } from '../../../main/ets/pages/RepositoryDetailPage';
import { RouteName } from '../../../main/ets/navigation/Routes';

const TARGET_OWNER: string = 'CarGuoUI';
const TARGET_REPO: string = 'GSYTestRepo';
const TARGET_FULL_NAME: string = TARGET_OWNER + '/' + TARGET_REPO;
const STATUS_NO_CONTENT: number = 204;
const STATUS_NOT_FOUND: number = 404;
const STATUS_ACCEPTED: number = 202;

interface RepoHostOwner {
  id?: number;
  login: string;
  avatar_url: string;
  html_url?: string;
}

interface RepoHostDetail {
  id: number;
  name: string;
  full_name: string;
  description: string;
  default_branch: string;
  html_url: string;
  language: string;
  stargazers_count: number;
  watchers_count: number;
  forks_count: number;
  open_issues_count: number;
  subscribers_count: number;
  owner: RepoHostOwner;
}

interface RepoHostReadme {
  content: string;
  encoding: string;
}

interface RepoHostRepoRef {
  id: number;
  name: string;
}

interface RepoHostEvent {
  id: string;
  type: string;
  actor: RepoHostOwner;
  repo: RepoHostRepoRef;
  created_at: string;
  payload: Record<string, Object>;
}

interface RepoHostIssue {
  id: number;
  number: number;
  title: string;
  body: string;
  state: string;
  user: RepoHostOwner;
  comments: number;
  created_at: string;
  updated_at: string;
  html_url: string;
}

interface RepoHostFile {
  name: string;
  path: string;
  sha: string;
  size: number;
  type: string;
  download_url: string;
  html_url: string;
}

class RepoHostProvider implements HttpProvider {
  callCount: number = 0;
  starGetCount: number = 0;
  watchGetCount: number = 0;
  starPutCount: number = 0;
  starDeleteCount: number = 0;
  forkPostCount: number = 0;

  private buildDetailBody(): string {
    const detail: RepoHostDetail = {
      id: 1,
      name: TARGET_REPO,
      full_name: TARGET_FULL_NAME,
      description: 'host repo desc',
      default_branch: 'master',
      html_url: 'https://github.com/' + TARGET_FULL_NAME,
      language: 'TypeScript',
      stargazers_count: 12345,
      watchers_count: 6789,
      forks_count: 4321,
      open_issues_count: 7,
      subscribers_count: 999,
      owner: {
        login: TARGET_OWNER,
        avatar_url: '',
        html_url: 'https://github.com/' + TARGET_OWNER,
      },
    };
    return JSON.stringify(detail);
  }

  private buildReadmeBody(): string {
    const obj: RepoHostReadme = {
      content: 'IyBIZWxsbwo=',
      encoding: 'base64',
    };
    return JSON.stringify(obj);
  }

  private buildEventsBody(): string {
    const events: RepoHostEvent[] = [
      {
        id: 'evt-1',
        type: 'PushEvent',
        actor: { login: TARGET_OWNER, avatar_url: '' },
        repo: { id: 1, name: TARGET_FULL_NAME },
        created_at: '2024-01-01T00:00:00Z',
        payload: {} as Record<string, Object>,
      },
    ];
    return JSON.stringify(events);
  }

  private buildIssuesBody(): string {
    const issues: RepoHostIssue[] = [
      {
        id: 1,
        number: 1,
        title: 'host issue title',
        body: '',
        state: 'open',
        user: { login: TARGET_OWNER, avatar_url: '' },
        comments: 3,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        html_url: '',
      },
    ];
    return JSON.stringify(issues);
  }

  private buildFilesBody(): string {
    const files: RepoHostFile[] = [
      {
        name: 'README.md',
        path: 'README.md',
        sha: 'sha-readme',
        size: 100,
        type: 'file',
        download_url: '',
        html_url: '',
      },
    ];
    return JSON.stringify(files);
  }

  async request(url: string,
                method: string,
                _headers: HttpHeaders,
                _body: string | null,
                _timeoutMs: number): Promise<RawResponse> {
    this.callCount = this.callCount + 1;
    const starUrl: string = Address.getStar(TARGET_OWNER, TARGET_REPO);
    const watchUrl: string = Address.getWatch(TARGET_OWNER, TARGET_REPO);
    const forkUrl: string = Address.createFork(TARGET_OWNER, TARGET_REPO);

    if (url === starUrl && method === 'GET') {
      this.starGetCount = this.starGetCount + 1;
      return new RawResponse(STATUS_NOT_FOUND, '', {});
    }
    if (url === watchUrl && method === 'GET') {
      this.watchGetCount = this.watchGetCount + 1;
      return new RawResponse(STATUS_NOT_FOUND, '', {});
    }
    if (url === starUrl && method === 'PUT') {
      this.starPutCount = this.starPutCount + 1;
      return new RawResponse(STATUS_NO_CONTENT, '', {});
    }
    if (url === starUrl && method === 'DELETE') {
      this.starDeleteCount = this.starDeleteCount + 1;
      return new RawResponse(STATUS_NO_CONTENT, '', {});
    }
    if (url === watchUrl && method === 'PUT') {
      return new RawResponse(STATUS_NO_CONTENT, '', {});
    }
    if (url === watchUrl && method === 'DELETE') {
      return new RawResponse(STATUS_NO_CONTENT, '', {});
    }
    if (url === forkUrl && method === 'POST') {
      this.forkPostCount = this.forkPostCount + 1;
      return new RawResponse(STATUS_ACCEPTED, '{}', {});
    }
    if (url === Address.getReposDetail(TARGET_OWNER, TARGET_REPO)) {
      return new RawResponse(SUCCESS, this.buildDetailBody(), {});
    }
    if (url.indexOf('/readme') >= 0) {
      return new RawResponse(SUCCESS, this.buildReadmeBody(), {});
    }
    if (url.indexOf('/events') >= 0) {
      return new RawResponse(SUCCESS, this.buildEventsBody(), {});
    }
    if (url.indexOf('/issues') >= 0) {
      return new RawResponse(SUCCESS, this.buildIssuesBody(), {});
    }
    if (url.indexOf('/contents') >= 0) {
      return new RawResponse(SUCCESS, this.buildFilesBody(), {});
    }
    return new RawResponse(SUCCESS, '{}', {});
  }
}

const REPO_HOST_STUB: RepoHostProvider = new RepoHostProvider();

export function getRepoHostStub(): RepoHostProvider {
  return REPO_HOST_STUB;
}

@Entry
@Component
struct RepositoryDetailHostPage {
  @State navStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    HttpManager.setMockProvider(REPO_HOST_STUB);
  }

  aboutToDisappear(): void {
    HttpManager.setMockProvider(null);
  }

  @Builder
  navMap(name: string): void {
    if (name === RouteName.RepositoryDetail) {
      RepositoryDetailPage();
    }
  }

  build(): void {
    Column() {
      Navigation(this.navStack) {
      }
      .id('repo_detail_host_nav')
      .width('100%')
      .height('100%')
      .hideTitleBar(true)
      .navDestination(this.navMap)
      .onAppear((): void => {
        this.navStack.pushPath({
          name: RouteName.RepositoryDetail,
          param: { 'fullName': TARGET_FULL_NAME } as Record<string, Object>,
        });
      });
    }
    .id('repo_detail_host_root')
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF');
  }
}
