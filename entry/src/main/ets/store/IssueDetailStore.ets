export interface IssueUser {
  login: string;
  avatar_url: string;
  html_url: string;
}

export interface IssueDetailModel {
  id: number;
  number: number;
  title: string;
  body: string;
  body_html: string;
  state: string;
  locked: boolean;
  comments: number;
  user: IssueUser;
  created_at: string;
  updated_at: string;
  closed_at: string;
  html_url: string;
}

export interface IssueCommentModel {
  id: number;
  body: string;
  body_html: string;
  user: IssueUser;
  created_at: string;
  updated_at: string;
  html_url: string;
}

export const ISSUE_STATE_OPEN: string = 'open';
export const ISSUE_STATE_CLOSED: string = 'closed';

@Observed
export class IssueDetailStore {
  issue: IssueDetailModel | null = null;
  comments: IssueCommentModel[] = [];
  loading: boolean = false;
  page: number = 1;
  hasMore: boolean = true;
  error: string = '';
  state: string = ISSUE_STATE_OPEN;

  reset(): void {
    this.issue = null;
    this.comments = [];
    this.loading = false;
    this.page = 1;
    this.hasMore = true;
    this.error = '';
    this.state = ISSUE_STATE_OPEN;
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setError(msg: string): void {
    this.error = msg;
    this.loading = false;
  }

  setIssue(issue: IssueDetailModel): void {
    this.issue = issue;
    this.state = issue.state !== null && issue.state !== undefined && issue.state.length > 0
      ? issue.state : ISSUE_STATE_OPEN;
  }

  setState(state: string): void {
    this.state = state !== null && state !== undefined && state.length > 0
      ? state : ISSUE_STATE_OPEN;
    if (this.issue !== null) {
      const current: IssueDetailModel = this.issue as IssueDetailModel;
      current.state = this.state;
      this.issue = current;
    }
  }

  applyCommentsRefresh(items: IssueCommentModel[], pageSize: number): void {
    this.comments = items.slice();
    this.page = 1;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  applyCommentsAppend(items: IssueCommentModel[], page: number, pageSize: number): void {
    const merged: IssueCommentModel[] = this.comments.slice();
    for (let i = 0; i < items.length; i++) {
      merged.push(items[i]);
    }
    this.comments = merged;
    this.page = page;
    this.hasMore = items.length >= pageSize;
    this.loading = false;
    this.error = '';
  }

  appendComment(comment: IssueCommentModel): void {
    const merged: IssueCommentModel[] = this.comments.slice();
    merged.push(comment);
    this.comments = merged;
    if (this.issue !== null) {
      const current: IssueDetailModel = this.issue as IssueDetailModel;
      current.comments = current.comments + 1;
      this.issue = current;
    }
  }

  replaceCommentAt(index: number, item: IssueCommentModel): void {
    if (index < 0 || index >= this.comments.length) {
      return;
    }
    const merged: IssueCommentModel[] = this.comments.slice();
    merged.splice(index, 1, item);
    this.comments = merged;
  }

  removeCommentAt(index: number): void {
    if (index < 0 || index >= this.comments.length) {
      return;
    }
    const merged: IssueCommentModel[] = this.comments.slice();
    merged.splice(index, 1);
    this.comments = merged;
    if (this.issue !== null) {
      const current: IssueDetailModel = this.issue as IssueDetailModel;
      const next: number = current.comments - 1;
      current.comments = next > 0 ? next : 0;
      this.issue = current;
    }
  }
}
