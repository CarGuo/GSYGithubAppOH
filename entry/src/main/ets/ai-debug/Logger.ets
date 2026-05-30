import hilog from '@ohos.hilog';

export type LogLevel = 'D' | 'I' | 'W' | 'E';

export interface LogEntry {
  ts: number;
  level: LogLevel;
  tag: string;
  msg: string;
}

const DOMAIN: number = 0x0666;
const HILOG_TAG: string = 'gsygithub';
const RING_CAPACITY: number = 500;

class LoggerImpl {
  private buffer: LogEntry[] = [];
  private capacity: number = RING_CAPACITY;

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

  snapshot(limit?: number): LogEntry[] {
    const all: LogEntry[] = this.buffer.slice();
    if (limit === undefined || limit <= 0 || limit >= all.length) {
      return all;
    }
    return all.slice(all.length - limit);
  }

  d(tag: string, msg: string): void {
    this.push('D', tag, msg);
    hilog.debug(DOMAIN, HILOG_TAG, '[%{public}s] %{public}s', tag, msg);
  }

  i(tag: string, msg: string): void {
    this.push('I', tag, msg);
    hilog.info(DOMAIN, HILOG_TAG, '[%{public}s] %{public}s', tag, msg);
  }

  w(tag: string, msg: string): void {
    this.push('W', tag, msg);
    hilog.warn(DOMAIN, HILOG_TAG, '[%{public}s] %{public}s', tag, msg);
  }

  e(tag: string, msg: string, err?: Error | string): void {
    let full: string = msg;
    if (err !== undefined) {
      if (typeof err === 'string') {
        full = msg + ' | ' + err;
      } else {
        const stack: string = err.stack !== undefined ? err.stack : err.message;
        full = msg + ' | ' + err.message + (stack.length > 0 ? ' | ' + stack : '');
      }
    }
    this.push('E', tag, full);
    hilog.error(DOMAIN, HILOG_TAG, '[%{public}s] %{public}s', tag, full);
  }

  private push(level: LogLevel, tag: string, msg: string): void {
    const entry: LogEntry = {
      ts: Date.now(),
      level: level,
      tag: tag,
      msg: msg,
    };
    this.buffer.push(entry);
    if (this.buffer.length > this.capacity) {
      this.buffer.shift();
    }
  }
}

export const Logger: LoggerImpl = new LoggerImpl();

export const LOGGER_DOMAIN: number = DOMAIN;
export const LOGGER_HILOG_TAG: string = HILOG_TAG;
export const LOGGER_RING_CAPACITY: number = RING_CAPACITY;
