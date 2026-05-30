export class StringUtil {
  static trim(text: string | null | undefined): string {
    if (text === null || text === undefined) {
      return '';
    }
    return String(text).replace(/^\s*|\s*$/g, '');
  }

  static isEmpty(text: string | null | undefined): boolean {
    if (text === null || text === undefined) {
      return true;
    }
    return String(text).length === 0;
  }

  static isBlank(text: string | null | undefined): boolean {
    if (text === null || text === undefined) {
      return true;
    }
    return StringUtil.trim(text).length === 0;
  }

  static defaultIfEmpty(text: string | null | undefined, fallback: string): string {
    return StringUtil.isEmpty(text) ? fallback : (text as string);
  }

  static getFullName(repositoryUrl: string | null | undefined): string {
    if (StringUtil.isEmpty(repositoryUrl)) {
      return '';
    }
    let url: string = repositoryUrl as string;
    if (url.charAt(url.length - 1) === '/') {
      url = url.substring(0, url.length - 1);
    }
    const parts: string[] = url.split('/');
    if (parts.length > 2) {
      return parts[parts.length - 2] + '/' + parts[parts.length - 1];
    }
    return '';
  }

  static formName(name: string | null | undefined): string {
    if (StringUtil.isEmpty(name)) {
      return '';
    }
    const value: string = name as string;
    if (value === 'sh') {
      return 'shell';
    }
    if (value === 'js') {
      return 'javascript';
    }
    if (value === 'kt') {
      return 'kotlin';
    }
    if (value === 'c' || value === 'cpp') {
      return 'cpp';
    }
    if (value === 'md') {
      return 'markdown';
    }
    if (value === 'html') {
      return 'xml';
    }
    return value;
  }

  static isImageEnd(path: string | null | undefined): boolean {
    if (StringUtil.isEmpty(path)) {
      return false;
    }
    const tails: string[] = ['.png', '.jpg', '.jpeg', '.gif', '.svg'];
    const value: string = (path as string).toLowerCase();
    for (let i: number = 0; i < tails.length; i++) {
      const tail: string = tails[i];
      if (value.indexOf(tail) >= 0 && value.indexOf(tail) + tail.length === value.length) {
        return true;
      }
    }
    return false;
  }

  static replaceAll(source: string, search: string, replace: string): string {
    if (StringUtil.isEmpty(source) || StringUtil.isEmpty(search)) {
      return source;
    }
    return source.split(search).join(replace);
  }
}
