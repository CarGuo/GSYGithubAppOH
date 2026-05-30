/**
 * EventActionUtil —— 严格对齐 RN 端 [eventUtils.js](https://github.com/CarGuo/GSYGithubApp/blob/master/app/utils/eventUtils.js#L6-L131)
 *
 * 把 GitHub 原始 event 解析为：
 *  - actionStr：列表 item 第二行的"动作摘要" (如 "opened issue 12 in CarGuo/GSYGithubApp")
 *  - des：可选的多行描述（issue.title / comment.body / push 提交信息列表）
 *
 * 对齐策略：完整覆盖 RN 处理过的全部 event.type 分支，避免出现"OH 端比 RN 少分支"。
 */

import { DynamicEvent } from '../store/DynamicStore';

export interface EventActionResult {
  actionStr: string;
  des: string;
}

function readPayloadString(payload: Record<string, Object>, key: string): string {
  const value: Object | undefined = payload[key];
  if (value === undefined || value === null) {
    return '';
  }
  if (typeof value === 'string') {
    return value as string;
  }
  return String(value);
}

function readPayloadObject(payload: Record<string, Object>, key: string): Record<string, Object> | null {
  const value: Object | undefined = payload[key];
  if (value === undefined || value === null) {
    return null;
  }
  return value as Record<string, Object>;
}

function safeRepoName(event: DynamicEvent): string {
  if (event.repo === null || event.repo === undefined) {
    return '';
  }
  return event.repo.name !== undefined && event.repo.name !== null ? event.repo.name : '';
}

export class EventActionUtil {
  static getComposeActionText(event: DynamicEvent): string {
    const repoName: string = safeRepoName(event);
    const eventType: string = event.type !== undefined && event.type !== null ? event.type : '';
    let actionText: string = '';
    if (eventType.indexOf('Push') >= 0) {
      actionText = 'pushed to';
    } else if (eventType.indexOf('Create') >= 0) {
      actionText = 'created';
    } else if (eventType.indexOf('Fork') >= 0) {
      actionText = 'forked';
    } else if (eventType.indexOf('Star') >= 0) {
      actionText = 'starred';
    } else if (eventType.indexOf('Watch') >= 0) {
      actionText = 'started watching';
    } else if (eventType.indexOf('Issue') >= 0) {
      actionText = 'created issue in';
    } else if (eventType.indexOf('PullRequest') >= 0) {
      actionText = 'created pull request in';
    } else {
      actionText = eventType.replace('Event', '').toLowerCase();
    }
    if (repoName.length === 0) {
      return actionText;
    }
    return actionText + ' ' + repoName;
  }

  static getActionAndDes(event: DynamicEvent): EventActionResult {
    let actionStr: string = '';
    let des: string = '';
    const repoName: string = safeRepoName(event);
    const payload: Record<string, Object> = event.payload !== undefined && event.payload !== null
      ? event.payload
      : ({} as Record<string, Object>);

    switch (event.type) {
      case 'CommitCommentEvent':
        actionStr = 'Commit comment at ' + repoName;
        break;
      case 'CreateEvent': {
        const refType: string = readPayloadString(payload, 'ref_type');
        const ref: string = readPayloadString(payload, 'ref');
        if (refType === 'repository') {
          actionStr = 'Created repository ' + repoName;
        } else {
          actionStr = 'Created ' + refType + ' ' + ref + ' at ' + repoName;
        }
        break;
      }
      case 'DeleteEvent': {
        const refType: string = readPayloadString(payload, 'ref_type');
        const ref: string = readPayloadString(payload, 'ref');
        actionStr = 'Delete ' + refType + ' ' + ref + ' at ' + repoName;
        break;
      }
      case 'ForkEvent': {
        const oriRepo: string = repoName;
        const newRepo: string = (event.actor !== null && event.actor !== undefined ? event.actor.login : '')
          + '/' + repoName;
        actionStr = 'Forked ' + oriRepo + ' to ' + newRepo;
        break;
      }
      case 'GollumEvent': {
        const login: string = event.actor !== null && event.actor !== undefined ? event.actor.login : '';
        actionStr = login + ' a wiki page ';
        break;
      }
      case 'InstallationEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' an GitHub App ';
        break;
      }
      case 'InstallationRepositoriesEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' repository from an installation ';
        break;
      }
      case 'IssueCommentEvent': {
        const action: string = readPayloadString(payload, 'action');
        const issue: Record<string, Object> | null = readPayloadObject(payload, 'issue');
        const comment: Record<string, Object> | null = readPayloadObject(payload, 'comment');
        const issueNumber: string = issue !== null ? readPayloadString(issue, 'number') : '';
        actionStr = action + ' comment on issue ' + issueNumber + ' in ' + repoName;
        if (comment !== null) {
          des = readPayloadString(comment, 'body');
        }
        break;
      }
      case 'IssuesEvent': {
        const action: string = readPayloadString(payload, 'action');
        const issue: Record<string, Object> | null = readPayloadObject(payload, 'issue');
        const issueNumber: string = issue !== null ? readPayloadString(issue, 'number') : '';
        actionStr = action + ' issue ' + issueNumber + ' in ' + repoName;
        if (issue !== null) {
          des = readPayloadString(issue, 'title');
        }
        break;
      }
      case 'MarketplacePurchaseEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' marketplace plan ';
        break;
      }
      case 'MemberEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' member to ' + repoName;
        break;
      }
      case 'OrgBlockEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' a user ';
        break;
      }
      case 'ProjectCardEvent':
      case 'ProjectColumnEvent':
      case 'ProjectEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' a project ';
        break;
      }
      case 'PublicEvent':
        actionStr = 'Made ' + repoName + ' public';
        break;
      case 'PullRequestEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' pull request ' + repoName;
        break;
      }
      case 'PullRequestReviewEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' pull request review at' + repoName;
        break;
      }
      case 'PullRequestReviewCommentEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' pull request review comment at' + repoName;
        break;
      }
      case 'PushEvent': {
        const refRaw: string = readPayloadString(payload, 'ref');
        const slashIdx: number = refRaw.lastIndexOf('/');
        const ref: string = slashIdx >= 0 ? refRaw.substring(slashIdx + 1) : refRaw;
        actionStr = 'Push to ' + ref + ' at ' + repoName;
        const commits: Object | undefined = payload['commits'];
        if (Array.isArray(commits)) {
          const commitArr: Record<string, Object>[] = commits as Record<string, Object>[];
          const maxLines: number = 4;
          const max: number = commitArr.length > maxLines ? maxLines - 1 : commitArr.length;
          let descSpan: string = '';
          for (let i: number = 0; i < max; i++) {
            const commit: Record<string, Object> = commitArr[i];
            const sha: string = readPayloadString(commit, 'sha');
            const shortSha: string = sha.length >= 7 ? sha.substring(0, 7) : sha;
            const message: string = readPayloadString(commit, 'message');
            if (i !== 0) {
              descSpan += '\n';
            }
            descSpan += shortSha + ' ' + message;
          }
          if (commitArr.length > maxLines) {
            descSpan = descSpan + '\n...';
          }
          des = descSpan;
        }
        break;
      }
      case 'ReleaseEvent': {
        const action: string = readPayloadString(payload, 'action');
        const release: Record<string, Object> | null = readPayloadObject(payload, 'release');
        const tagName: string = release !== null ? readPayloadString(release, 'tag_name') : '';
        actionStr = action + ' release ' + tagName + ' at ' + repoName;
        break;
      }
      case 'WatchEvent': {
        const action: string = readPayloadString(payload, 'action');
        actionStr = action + ' ' + repoName;
        break;
      }
      default:
        actionStr = event.type + ' ' + repoName;
        break;
    }

    return { actionStr: actionStr, des: des } as EventActionResult;
  }
}
