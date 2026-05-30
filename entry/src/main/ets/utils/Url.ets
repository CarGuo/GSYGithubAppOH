export class DeepLinkInfo {
  scheme: string;
  host: string;
  path: string;
  query: Map<string, string>;

  constructor(scheme: string, host: string, path: string, query: Map<string, string>) {
    this.scheme = scheme;
    this.host = host;
    this.path = path;
    this.query = query;
  }
}

export class Url {
  static parseQuery(query: string): Map<string, string> {
    const out: Map<string, string> = new Map<string, string>();
    if (!query || query.length === 0) {
      return out;
    }
    let raw: string = query;
    const hash: number = raw.indexOf('#');
    if (hash >= 0) {
      raw = raw.substring(0, hash);
    }
    const qIndex: number = raw.indexOf('?');
    if (qIndex >= 0) {
      raw = raw.substring(qIndex + 1);
    }
    if (raw.length === 0) {
      return out;
    }
    const parts: string[] = raw.split('&');
    for (let i: number = 0; i < parts.length; i++) {
      const part: string = parts[i];
      if (part.length === 0) {
        continue;
      }
      const eq: number = part.indexOf('=');
      let key: string;
      let value: string;
      if (eq < 0) {
        key = Url.safeDecode(part);
        value = '';
      } else {
        key = Url.safeDecode(part.substring(0, eq));
        value = Url.safeDecode(part.substring(eq + 1));
      }
      if (key.length > 0) {
        out.set(key, value);
      }
    }
    return out;
  }

  static buildQuery(params: Record<string, string>): string {
    if (params === null || params === undefined) {
      return '';
    }
    const keys: string[] = Object.keys(params);
    if (keys.length === 0) {
      return '';
    }
    const parts: string[] = [];
    for (let i: number = 0; i < keys.length; i++) {
      const key: string = keys[i];
      const value: string = params[key] !== undefined && params[key] !== null
        ? String(params[key])
        : '';
      parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
    }
    return parts.join('&');
  }

  static parseDeepLink(url: string): DeepLinkInfo {
    if (!url || url.length === 0) {
      return new DeepLinkInfo('', '', '', new Map<string, string>());
    }
    const schemeIdx: number = url.indexOf('://');
    let scheme: string = '';
    let rest: string = url;
    if (schemeIdx >= 0) {
      scheme = url.substring(0, schemeIdx);
      rest = url.substring(schemeIdx + 3);
    }
    let queryPart: string = '';
    const qIdx: number = rest.indexOf('?');
    let head: string = rest;
    if (qIdx >= 0) {
      head = rest.substring(0, qIdx);
      queryPart = rest.substring(qIdx + 1);
    }
    const hashIdx: number = queryPart.indexOf('#');
    if (hashIdx >= 0) {
      queryPart = queryPart.substring(0, hashIdx);
    }
    const pathIdx: number = head.indexOf('/');
    let host: string = head;
    let path: string = '';
    if (pathIdx >= 0) {
      host = head.substring(0, pathIdx);
      path = head.substring(pathIdx);
    }
    const query: Map<string, string> = Url.parseQuery(queryPart);
    return new DeepLinkInfo(scheme, host, path, query);
  }

  private static safeDecode(input: string): string {
    if (!input || input.length === 0) {
      return '';
    }
    try {
      return decodeURIComponent(input.replace(/\+/g, ' '));
    } catch (_e) {
      return input;
    }
  }
}
