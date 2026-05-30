export interface HttpRecord {
  ts: number;
  url: string;
  method: string;
  status: number;
  ms: number;
  errorCode?: number;
}

export interface HttpRecordInput {
  url: string;
  method: string;
  status: number;
  ms: number;
  errorCode?: number;
}

const HTTP_RING_CAPACITY: number = 30;

class HttpRecorderImpl {
  private buffer: HttpRecord[] = [];
  private capacity: number = HTTP_RING_CAPACITY;

  setCapacity(n: number): void {
    if (n > 0) {
      this.capacity = n;
      while (this.buffer.length > this.capacity) {
        this.buffer.shift();
      }
    }
  }

  getCapacity(): number {
    return this.capacity;
  }

  size(): number {
    return this.buffer.length;
  }

  clear(): void {
    this.buffer = [];
  }

  record(input: HttpRecordInput): void {
    const safeUrl: string = this.stripSensitive(input.url);
    const entry: HttpRecord = {
      ts: Date.now(),
      url: safeUrl,
      method: input.method,
      status: input.status,
      ms: input.ms,
      errorCode: input.errorCode,
    };
    this.buffer.push(entry);
    if (this.buffer.length > this.capacity) {
      this.buffer.shift();
    }
  }

  snapshot(limit?: number): HttpRecord[] {
    const all: HttpRecord[] = this.buffer.slice();
    if (limit === undefined || limit <= 0 || limit >= all.length) {
      return all;
    }
    return all.slice(all.length - limit);
  }

  private stripSensitive(url: string): string {
    let result: string = url;
    const qIndex: number = result.indexOf('?');
    if (qIndex >= 0) {
      const head: string = result.substring(0, qIndex);
      const query: string = result.substring(qIndex + 1);
      const parts: string[] = query.split('&');
      const kept: string[] = [];
      for (let i: number = 0; i < parts.length; i++) {
        const seg: string = parts[i];
        const eq: number = seg.indexOf('=');
        const key: string = eq >= 0 ? seg.substring(0, eq).toLowerCase() : seg.toLowerCase();
        if (key === 'access_token' || key === 'token' || key === 'client_secret' || key === 'password') {
          kept.push((eq >= 0 ? seg.substring(0, eq) : seg) + '=***');
        } else {
          kept.push(seg);
        }
      }
      result = head + (kept.length > 0 ? '?' + kept.join('&') : '');
    }
    return result;
  }
}

export const HttpRecorder: HttpRecorderImpl = new HttpRecorderImpl();

export const HTTP_RECORDER_CAPACITY: number = HTTP_RING_CAPACITY;
