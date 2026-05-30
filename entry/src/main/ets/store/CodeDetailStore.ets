@Observed
export class CodeDetailStore {
  path: string = '';
  content: string = '';
  htmlContent: string = '';
  loading: boolean = false;
  error: string = '';

  reset(): void {
    this.path = '';
    this.content = '';
    this.htmlContent = '';
    this.loading = false;
    this.error = '';
  }

  setPath(path: string): void {
    this.path = path !== null && path !== undefined ? path : '';
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

  setContent(raw: string, html: string): void {
    this.content = raw !== null && raw !== undefined ? raw : '';
    this.htmlContent = html !== null && html !== undefined ? html : '';
    this.loading = false;
    this.error = '';
  }
}
