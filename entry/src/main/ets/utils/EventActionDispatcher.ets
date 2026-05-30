/**
 * EventActionDispatcher —— 对齐 Android Compose EventItem 点击行为。
 *
 * 职责：把 GitHub 原始 event 的点击行为统一分发到对应路由，避免 OH 端 4 个调用方
 * （DynamicTabPage / MyTabPage / ActivityTab / UserDetailPage）各写一份散弹版。
 *
 * Compose 分发分支：
 *  1. 没有 event.repo                    → UserDetail (login=actor.login)
 *  2. PushEvent + 0 commits              → RepositoryDetail (owner/name)
 *  3. PushEvent + 1 commit               → PushDetail (fullName + sha)
 *  4. PushEvent + 多 commits             → ActionSheet 让用户选哪条 commit
 *  5. ReleaseEvent                       → external browser (release.tarball_url)
 *  6. IssueCommentEvent / IssuesEvent    → IssueDetail (fullName + number)
 *  7. MemberEvent                        → UserDetail (login=actor.login)
 *  8. 默认（含 ForkEvent）                → RepositoryDetail (owner/name)
 *
 * currentRepoFullName：当前所在仓库（'owner/name'），用于避免在 ActivityTab 内部
 * 跳转到自身（与 RN 同源行为对齐）。其他调用方可不传。
 */

import { DynamicEvent } from '../store/DynamicStore';
import { NavigationService } from '../navigation/NavigationService';
import { RouteName } from '../navigation/Routes';
import { CommonModal, CommonOptionItem } from '../common/CommonModal';
import { BOOT_USER_KEY, BOOT_REPO_KEY, BOOT_PUSH_KEY, BOOT_ISSUE_KEY } from '../entryability/EntryAbility';
import hilog from '@ohos.hilog';

export type ExternalUrlHandler = (url: string) => boolean;

interface PushCommit {
  sha: string;
  message: string;
}

export class EventActionDispatcher {
  static dispatch(event: DynamicEvent,
                  currentRepoFullName: string = '',
                  openExternalUrl?: ExternalUrlHandler): void {
    if (event === null || event === undefined) {
      return;
    }

    const actorLogin: string = EventActionDispatcher.safeActorLogin(event);

    if (event.repo === null || event.repo === undefined) {
      EventActionDispatcher.gotoUser(actorLogin);
      return;
    }
    const repoNameRaw: string = event.repo.name !== null && event.repo.name !== undefined
      ? event.repo.name : '';
    if (repoNameRaw.length === 0) {
      EventActionDispatcher.gotoUser(actorLogin);
      return;
    }

    const slashIdx: number = repoNameRaw.indexOf('/');
    if (slashIdx <= 0 || slashIdx >= repoNameRaw.length - 1) {
      return;
    }
    const owner: string = repoNameRaw.substring(0, slashIdx);
    const name: string = repoNameRaw.substring(slashIdx + 1);
    const fullName: string = owner + '/' + name;

    if (event.type === 'PushEvent') {
      const commits: PushCommit[] = EventActionDispatcher.readCommits(event);
      if (commits.length === 0) {
        if (fullName === currentRepoFullName) {
          return;
        }
        EventActionDispatcher.gotoRepo(owner, name);
        return;
      }
      if (commits.length === 1) {
        EventActionDispatcher.gotoPush(fullName, commits[0].sha);
        return;
      }
      EventActionDispatcher.showCommitPicker(fullName, commits);
      return;
    }

    if (event.type === 'ReleaseEvent') {
      const releaseUrl: string = EventActionDispatcher.readReleaseUrl(event);
      if (releaseUrl.length > 0) {
        if (openExternalUrl !== undefined && openExternalUrl(releaseUrl)) {
          return;
        }
        EventActionDispatcher.gotoWeb(releaseUrl);
        return;
      }
      if (fullName === currentRepoFullName) {
        return;
      }
      EventActionDispatcher.gotoRepo(owner, name);
      return;
    }

    if (event.type === 'IssueCommentEvent' || event.type === 'IssuesEvent') {
      const issueNumber: number = EventActionDispatcher.readIssueNumber(event);
      if (issueNumber > 0) {
        EventActionDispatcher.gotoIssue(fullName, issueNumber);
        return;
      }
      if (fullName === currentRepoFullName) {
        return;
      }
      EventActionDispatcher.gotoRepo(owner, name);
      return;
    }

    if (event.type === 'MemberEvent') {
      EventActionDispatcher.gotoUser(actorLogin);
      return;
    }

    if (fullName === currentRepoFullName) {
      return;
    }
    EventActionDispatcher.gotoRepo(owner, name);
  }

  static dispatchUser(login: string): void {
    EventActionDispatcher.gotoUser(login);
  }

  private static safeActorLogin(event: DynamicEvent): string {
    if (event.actor === null || event.actor === undefined) {
      return '';
    }
    return event.actor.login !== null && event.actor.login !== undefined
      ? event.actor.login : '';
  }

  private static gotoUser(login: string): void {
    if (login.length === 0) {
      return;
    }
    // KI-045 同款：NavPathStack ctx.pathInfo.param 在某些路径下拿不到，
    // 走 BOOT_USER_KEY 旁路兜底，目标页 aboutToAppear/onReady 直读 AppStorage 解析。
    AppStorage.setOrCreate<string>(BOOT_USER_KEY, login);
    const param: Record<string, Object> = { 'login': login };
    hilog.info(0x0666, 'EventDispatcher', 'gotoUser login=%{public}s', login);
    NavigationService.push(RouteName.UserDetail, param);
    setTimeout((): void => {
      AppStorage.setOrCreate<string>(BOOT_USER_KEY, '');
    }, 1500);
  }

  private static gotoRepo(owner: string, name: string): void {
    if (owner.length === 0 || name.length === 0) {
      return;
    }
    const fullName: string = owner + '/' + name;
    AppStorage.setOrCreate<string>(BOOT_REPO_KEY, fullName);
    const param: Record<string, Object> = {
      'fullName': fullName,
      'reposOwner': owner,
      'reposName': name,
    };
    hilog.info(0x0666, 'EventDispatcher', 'gotoRepo fullName=%{public}s', fullName);
    NavigationService.push(RouteName.RepositoryDetail, param);
    setTimeout((): void => {
      AppStorage.setOrCreate<string>(BOOT_REPO_KEY, '');
    }, 1500);
  }

  private static gotoPush(fullName: string, sha: string): void {
    if (fullName.length === 0 || sha.length === 0) {
      return;
    }
    AppStorage.setOrCreate<string>(BOOT_PUSH_KEY, fullName + '|' + sha);
    const param: Record<string, Object> = {
      'fullName': fullName,
      'sha': sha,
    };
    hilog.info(0x0666, 'EventDispatcher', 'gotoPush fullName=%{public}s sha=%{public}s', fullName, sha);
    NavigationService.push(RouteName.PushDetail, param);
    setTimeout((): void => {
      AppStorage.setOrCreate<string>(BOOT_PUSH_KEY, '');
    }, 1500);
  }

  private static gotoIssue(fullName: string, number: number): void {
    if (fullName.length === 0 || number <= 0) {
      return;
    }
    AppStorage.setOrCreate<string>(BOOT_ISSUE_KEY, fullName + '|' + String(number));
    const param: Record<string, Object> = {
      'fullName': fullName,
      'number': number,
    };
    hilog.info(0x0666, 'EventDispatcher', 'gotoIssue fullName=%{public}s number=%{public}d', fullName, number);
    NavigationService.push(RouteName.IssueDetail, param);
    setTimeout((): void => {
      AppStorage.setOrCreate<string>(BOOT_ISSUE_KEY, '');
    }, 1500);
  }

  private static gotoWeb(uri: string): void {
    if (uri.length === 0) {
      return;
    }
    const param: Record<string, Object> = { 'uri': uri };
    NavigationService.push(RouteName.WebPage, param);
  }

  private static showCommitPicker(fullName: string, commits: PushCommit[]): void {
    const items: CommonOptionItem[] = commits.map((c: PushCommit): CommonOptionItem => {
      const shortSha: string = c.sha.length > 7 ? c.sha.substring(0, 7) : c.sha;
      const msg: string = c.message.length > 0 ? c.message : '(no message)';
      const itemName: string = shortSha + '  ' + msg;
      const trimmed: string = itemName.length > 80 ? itemName.substring(0, 80) + '...' : itemName;
      return { itemName: trimmed } as CommonOptionItem;
    });
    CommonModal.options(
      { title: fullName, items: items },
      (idx: number, _item: CommonOptionItem): void => {
        if (idx < 0 || idx >= commits.length) {
          return;
        }
        EventActionDispatcher.gotoPush(fullName, commits[idx].sha);
      },
    );
  }

  private static readCommits(event: DynamicEvent): PushCommit[] {
    const out: PushCommit[] = [];
    if (event.payload === null || event.payload === undefined) {
      return out;
    }
    const commitsRaw: Object | undefined = event.payload['commits'] as Object | undefined;
    if (commitsRaw !== undefined && commitsRaw !== null) {
      const commits: Object[] = commitsRaw as Object[];
      for (let i: number = 0; i < commits.length; i++) {
        const item: Record<string, Object> = commits[i] as Record<string, Object>;
        const shaRaw: Object | undefined = item['sha'] as Object | undefined;
        const msgRaw: Object | undefined = item['message'] as Object | undefined;
        const sha: string = shaRaw !== undefined && shaRaw !== null ? String(shaRaw) : '';
        const msg: string = msgRaw !== undefined && msgRaw !== null ? String(msgRaw) : '';
        if (sha.length === 0) {
          continue;
        }
        out.push({ sha: sha, message: msg });
      }
      if (out.length > 0) {
        return out;
      }
    }
    // received_events 接口的 PushEvent.payload 不含 commits，只有 head sha；
    // 用 head 兜底当作单 commit，用户体验上点 PushEvent 直接进 PushDetail。
    const headRaw: Object | undefined = event.payload['head'] as Object | undefined;
    if (headRaw !== undefined && headRaw !== null) {
      const head: string = String(headRaw);
      if (head.length > 0) {
        out.push({ sha: head, message: '' });
      }
    }
    return out;
  }

  private static readReleaseUrl(event: DynamicEvent): string {
    if (event.payload === null || event.payload === undefined) {
      return '';
    }
    const releaseRaw: Object | undefined = event.payload['release'] as Object | undefined;
    if (releaseRaw === undefined || releaseRaw === null) {
      return '';
    }
    const release: Record<string, Object> = releaseRaw as Record<string, Object>;
    let urlRaw: Object | undefined = release['tarball_url'] as Object | undefined;
    if (urlRaw === undefined || urlRaw === null) {
      urlRaw = release['tarballUrl'] as Object | undefined;
    }
    if (urlRaw === undefined || urlRaw === null) {
      urlRaw = release['html_url'] as Object | undefined;
    }
    if (urlRaw === undefined || urlRaw === null) {
      return '';
    }
    return String(urlRaw);
  }

  private static readIssueNumber(event: DynamicEvent): number {
    if (event.payload === null || event.payload === undefined) {
      return 0;
    }
    const issueRaw: Object | undefined = event.payload['issue'] as Object | undefined;
    if (issueRaw === undefined || issueRaw === null) {
      return 0;
    }
    const issue: Record<string, Object> = issueRaw as Record<string, Object>;
    const numRaw: Object | undefined = issue['number'] as Object | undefined;
    if (numRaw === undefined || numRaw === null) {
      return 0;
    }
    if (typeof numRaw === 'number') {
      return numRaw as number;
    }
    const parsed: number = parseInt(String(numRaw), 10);
    return isNaN(parsed) ? 0 : parsed;
  }
}
