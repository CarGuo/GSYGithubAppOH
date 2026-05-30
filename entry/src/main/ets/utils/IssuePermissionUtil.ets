export class IssuePermissionUtil {
  static repoOwner(fullName: string): string {
    const safe: string = fullName !== null && fullName !== undefined ? fullName : '';
    const idx: number = safe.indexOf('/');
    return idx > 0 ? safe.substring(0, idx) : safe;
  }

  static isRepoOwner(fullName: string, currentLogin: string): boolean {
    const login: string = currentLogin !== null && currentLogin !== undefined ? currentLogin : '';
    return login.length > 0 && IssuePermissionUtil.repoOwner(fullName) === login;
  }

  static canReply(isRepoOwner: boolean, isIssueCreator: boolean, isIssueLocked: boolean): boolean {
    return isRepoOwner || isIssueCreator || !isIssueLocked;
  }

  static canEdit(isRepoOwner: boolean, isIssueCreator: boolean, isIssueLocked: boolean): boolean {
    return isRepoOwner || (isIssueCreator && !isIssueLocked);
  }

  static canOpenClose(isRepoOwner: boolean, isIssueCreator: boolean): boolean {
    return isRepoOwner || isIssueCreator;
  }

  static canLockUnlock(isRepoOwner: boolean): boolean {
    return isRepoOwner;
  }
}
