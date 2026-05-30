export interface CommitAuthorInfo {
  name: string;
  email: string;
  date: string;
}

export interface CommitInner {
  message: string;
  author: CommitAuthorInfo;
  committer: CommitAuthorInfo;
}

export interface CommitUserBrief {
  login: string;
  avatar_url: string;
  html_url: string;
}

export interface CommitFileItem {
  filename: string;
  status: string;
  additions: number;
  deletions: number;
  changes: number;
  blob_url: string;
  raw_url: string;
  patch: string;
  sha: string;
}

export interface CommitStats {
  additions: number;
  deletions: number;
  total: number;
}

export interface CommitDetail {
  sha: string;
  html_url: string;
  commit: CommitInner;
  author: CommitUserBrief | null;
  committer: CommitUserBrief | null;
  files: CommitFileItem[];
  stats: CommitStats;
}

@Observed
export class PushDetailStore {
  commit: CommitDetail | null = null;
  files: CommitFileItem[] = [];
  loading: boolean = false;
  error: string = '';

  reset(): void {
    this.commit = null;
    this.files = [];
    this.loading = false;
    this.error = '';
  }

  startLoading(): void {
    this.loading = true;
    this.error = '';
  }

  finishLoading(): void {
    this.loading = false;
  }

  setError(msg: string): void {
    this.loading = false;
    this.error = msg !== null && msg !== undefined ? msg : '';
  }

  setCommit(commit: CommitDetail): void {
    this.commit = commit;
    this.files = commit !== null && commit.files !== null && commit.files !== undefined
      ? commit.files.slice() : [];
    this.loading = false;
    this.error = '';
  }
}
