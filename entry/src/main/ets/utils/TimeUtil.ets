import { I18n } from '../i18n/I18n';

const SECOND: number = 1000;
const MINUTE: number = SECOND * 60;
const HOUR: number = MINUTE * 60;
const DAY: number = HOUR * 24;
const MONTH_DAYS: number = 30;
const YEAR_DAYS: number = 365;
const YEAR_MONTHS: number = 12;

const TEN: number = 10;

export class TimeUtil {
  static parseISO(input: string | number | Date | null | undefined): number {
    if (input === null || input === undefined) {
      return 0;
    }
    if (typeof input === 'number') {
      return input;
    }
    if (input instanceof Date) {
      return input.getTime();
    }
    const text: string = String(input).trim();
    if (text.length === 0) {
      return 0;
    }
    const direct: number = Date.parse(text);
    if (!isNaN(direct)) {
      return direct;
    }
    const normalized: string = text.replace(' ', 'T');
    const fallback: number = Date.parse(normalized);
    if (!isNaN(fallback)) {
      return fallback;
    }
    return 0;
  }

  static pad(value: number): string {
    return value < TEN ? '0' + value : '' + value;
  }

  static formatYMD(time: number): string {
    const d: Date = new Date(time);
    return d.getFullYear() + '-' + TimeUtil.pad(d.getMonth() + 1) + '-' + TimeUtil.pad(d.getDate());
  }

  static formatMDHM(time: number): string {
    const d: Date = new Date(time);
    return TimeUtil.pad(d.getMonth() + 1) + '-' + TimeUtil.pad(d.getDate())
      + ' ' + TimeUtil.pad(d.getHours()) + ':' + TimeUtil.pad(d.getMinutes());
  }

  static resolveTime(longTime: string | number | Date | null | undefined): string {
    return TimeUtil.resolveTimeWithLocale(
      longTime,
      I18n('justNow'),
      I18n('minutesAgo'),
      I18n('hoursAgo'),
      I18n('daysAgo'),
      I18n('monthsAgo'),
      I18n('yearsAgo'),
    );
  }

  static resolveTimeWithLocale(longTime: string | number | Date | null | undefined,
    justNow: string, minutesAgo: string, hoursAgo: string, daysAgo: string,
    monthsAgo: string = daysAgo, yearsAgo: string = daysAgo): string {
    const time: number = TimeUtil.parseISO(longTime);
    if (time <= 0) {
      return '';
    }
    const now: number = Date.now();
    const delta: number = Math.abs(now - time);
    const minutes: number = Math.floor(delta / MINUTE);
    const hours: number = Math.floor(delta / HOUR);
    const days: number = Math.floor(delta / DAY);
    const months: number = Math.floor(days / MONTH_DAYS);
    const years: number = Math.floor(days / YEAR_DAYS);
    if (months >= YEAR_MONTHS) {
      return TimeUtil.formatRelative(years, yearsAgo);
    }
    if (days >= MONTH_DAYS) {
      return TimeUtil.formatRelative(months, monthsAgo);
    }
    if (delta > DAY) {
      return TimeUtil.formatRelative(days, daysAgo);
    }
    if (delta > HOUR) {
      return TimeUtil.formatRelative(hours, hoursAgo);
    }
    if (delta > MINUTE) {
      return TimeUtil.formatRelative(minutes, minutesAgo);
    }
    return justNow;
  }

  private static formatRelative(value: number, pattern: string): string {
    if (pattern.length === 0) {
      return value.toString();
    }
    if (pattern.indexOf('%d') >= 0) {
      return pattern.replace('%d', value.toString());
    }
    const first: string = pattern.substring(0, 1);
    const needsSpace: boolean = first !== ' ' && /[A-Za-z]/.test(first);
    return value.toString() + (needsSpace ? ' ' : '') + pattern;
  }

  static getDeltaSeconds(longTime: string | number | Date | null | undefined): number {
    const time: number = TimeUtil.parseISO(longTime);
    if (time <= 0) {
      return 0;
    }
    return Math.floor((Date.now() - time) / SECOND);
  }
}
