export const MARKDOWN_LINE_PARAGRAPH: string = 'paragraph';
export const MARKDOWN_LINE_HEADING: string = 'heading';
export const MARKDOWN_LINE_BULLET: string = 'bullet';
export const MARKDOWN_LINE_ORDERED: string = 'ordered';
export const MARKDOWN_LINE_QUOTE: string = 'quote';
export const MARKDOWN_LINE_CODE: string = 'code';
export const MARKDOWN_LINE_TABLE: string = 'table';
export const MARKDOWN_LINE_TASK: string = 'task';

export class MarkdownLine {
  kind: string = MARKDOWN_LINE_PARAGRAPH;
  text: string = '';
  marker: string = '';
  level: number = 0;
  cells: string[] = [];
  checked: boolean = false;
}

export class MarkdownUtil {
  static normalize(input: string | null | undefined): string {
    if (input === null || input === undefined) {
      return '';
    }
    let value: string = input as string;
    value = value.replace(/\r\n/g, '\n');
    value = value.replace(/\r/g, '\n');
    value = value.replace(/<h1[^>]*>/gi, '\n# ');
    value = value.replace(/<h2[^>]*>/gi, '\n## ');
    value = value.replace(/<h3[^>]*>/gi, '\n### ');
    value = value.replace(/<h4[^>]*>/gi, '\n#### ');
    value = value.replace(/<h5[^>]*>/gi, '\n##### ');
    value = value.replace(/<h6[^>]*>/gi, '\n###### ');
    value = value.replace(/<\/h[1-6]\s*>/gi, '\n');
    value = value.replace(/<blockquote[^>]*>/gi, '\n> ');
    value = value.replace(/<\/blockquote\s*>/gi, '\n');
    value = value.replace(/<pre[^>]*>\s*<code[^>]*>/gi, '\n```\n');
    value = value.replace(/<\/code\s*>\s*<\/pre\s*>/gi, '\n```\n');
    value = value.replace(/<pre[^>]*>/gi, '\n```\n');
    value = value.replace(/<\/pre\s*>/gi, '\n```\n');
    value = value.replace(/<ul[^>]*>/gi, '\n');
    value = value.replace(/<\/ul\s*>/gi, '\n');
    value = value.replace(/<ol[^>]*>/gi, '\n');
    value = value.replace(/<\/ol\s*>/gi, '\n');
    value = value.replace(/<li[^>]*>\s*<input[^>]*checked[^>]*>/gi, '\n- [x] ');
    value = value.replace(/<li[^>]*>\s*<input[^>]*>/gi, '\n- [ ] ');
    value = value.replace(/<li[^>]*>/gi, '\n- ');
    value = value.replace(/<br\s*\/?\s*>/gi, '\n');
    value = value.replace(/<\/p\s*>/gi, '\n');
    value = value.replace(/<\/div\s*>/gi, '\n');
    value = value.replace(/<\/li\s*>/gi, '\n');
    return value;
  }

  static stripInline(input: string): string {
    if (input.length === 0) {
      return '';
    }
    let value: string = input;
    value = value.replace(/<!--[\s\S]*?-->/g, '');
    value = value.replace(/!\[([^\]]*)\]\([^)]+\)/g, '$1');
    value = value.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
    value = value.replace(/`([^`]+)`/g, '$1');
    value = value.replace(/\*\*([^*]+)\*\*/g, '$1');
    value = value.replace(/__([^_]+)__/g, '$1');
    value = value.replace(/\*([^*]+)\*/g, '$1');
    value = value.replace(/_([^_]+)_/g, '$1');
    value = value.replace(/<[^>]+>/g, '');
    value = value.replace(/&nbsp;/g, ' ');
    value = value.replace(/&amp;/g, '&');
    value = value.replace(/&lt;/g, '<');
    value = value.replace(/&gt;/g, '>');
    value = value.replace(/&quot;/g, '"');
    value = value.replace(/&#39;/g, "'");
    return value.trim();
  }

  static parseLines(input: string | null | undefined): MarkdownLine[] {
    const normalized: string = MarkdownUtil.normalize(input);
    const rawLines: string[] = normalized.split('\n');
    const out: MarkdownLine[] = [];
    let inCode: boolean = false;
    let orderedIndex: number = 1;

    for (let i: number = 0; i < rawLines.length; i++) {
      const raw: string = rawLines[i];
      const trimmed: string = raw.trim();
      if (trimmed.indexOf('```') === 0) {
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        const codeLine: MarkdownLine = new MarkdownLine();
        codeLine.kind = MARKDOWN_LINE_CODE;
        codeLine.text = raw;
        out.push(codeLine);
        continue;
      }
      if (trimmed.length === 0) {
        orderedIndex = 1;
        continue;
      }
      if (MarkdownUtil.isTableSeparator(trimmed)) {
        continue;
      }

      if (MarkdownUtil.isTableRow(trimmed)) {
        const table: MarkdownLine = new MarkdownLine();
        table.kind = MARKDOWN_LINE_TABLE;
        table.cells = MarkdownUtil.parseTableCells(trimmed);
        table.level = MarkdownUtil.isNextTableSeparator(rawLines, i) ? 1 : 0;
        table.text = table.cells.join(' ');
        out.push(table);
        continue;
      }

      const headingLevel: number = MarkdownUtil.headingLevel(trimmed);
      if (headingLevel > 0) {
        const heading: MarkdownLine = new MarkdownLine();
        heading.kind = MARKDOWN_LINE_HEADING;
        heading.level = headingLevel;
        heading.text = MarkdownUtil.stripInline(trimmed.substring(headingLevel).trim());
        out.push(heading);
        continue;
      }

      if (trimmed.indexOf('>') === 0) {
        const quote: MarkdownLine = new MarkdownLine();
        quote.kind = MARKDOWN_LINE_QUOTE;
        quote.text = MarkdownUtil.stripInline(trimmed.substring(1).trim());
        out.push(quote);
        continue;
      }

      if (MarkdownUtil.isTask(trimmed)) {
        const task: MarkdownLine = new MarkdownLine();
        task.kind = MARKDOWN_LINE_TASK;
        task.checked = MarkdownUtil.isTaskChecked(trimmed);
        task.marker = task.checked ? '☑' : '☐';
        task.level = MarkdownUtil.indentLevel(raw);
        task.text = MarkdownUtil.stripInline(trimmed.substring(6).trim());
        out.push(task);
        continue;
      }

      if (MarkdownUtil.isBullet(trimmed)) {
        const bullet: MarkdownLine = new MarkdownLine();
        bullet.kind = MARKDOWN_LINE_BULLET;
        bullet.marker = '•';
        bullet.level = MarkdownUtil.indentLevel(raw);
        bullet.text = MarkdownUtil.stripInline(trimmed.substring(2).trim());
        out.push(bullet);
        continue;
      }

      const orderedDot: number = trimmed.indexOf('. ');
      if (orderedDot > 0 && MarkdownUtil.isDigits(trimmed.substring(0, orderedDot))) {
        const ordered: MarkdownLine = new MarkdownLine();
        ordered.kind = MARKDOWN_LINE_ORDERED;
        ordered.marker = orderedIndex.toString() + '.';
        ordered.level = MarkdownUtil.indentLevel(raw);
        ordered.text = MarkdownUtil.stripInline(trimmed.substring(orderedDot + 2).trim());
        out.push(ordered);
        orderedIndex = orderedIndex + 1;
        continue;
      }

      orderedIndex = 1;
      const paragraph: MarkdownLine = new MarkdownLine();
      paragraph.kind = MARKDOWN_LINE_PARAGRAPH;
      paragraph.text = MarkdownUtil.stripInline(trimmed);
      if (paragraph.text.length > 0) {
        out.push(paragraph);
      }
    }
    return out;
  }

  private static headingLevel(value: string): number {
    let level: number = 0;
    while (level < value.length && level < 6 && value.charAt(level) === '#') {
      level = level + 1;
    }
    if (level > 0 && level < value.length && value.charAt(level) === ' ') {
      return level;
    }
    return 0;
  }

  private static isBullet(value: string): boolean {
    if (value.length < 3) {
      return false;
    }
    const first: string = value.charAt(0);
    return (first === '-' || first === '*') && value.charAt(1) === ' ';
  }

  private static isTask(value: string): boolean {
    if (value.length < 6 || !MarkdownUtil.isBullet(value)) {
      return false;
    }
    const prefix: string = value.substring(2, 5).toLowerCase();
    return (prefix === '[ ]' || prefix === '[x]') && value.charAt(5) === ' ';
  }

  private static isTaskChecked(value: string): boolean {
    return value.length >= 5 && value.substring(2, 5).toLowerCase() === '[x]';
  }

  private static indentLevel(raw: string): number {
    let spaces: number = 0;
    while (spaces < raw.length && raw.charAt(spaces) === ' ') {
      spaces = spaces + 1;
    }
    const level: number = Math.floor(spaces / 2);
    return level > 4 ? 4 : level;
  }

  private static isTableRow(value: string): boolean {
    if (value.indexOf('|') < 0 || value.length < 3) {
      return false;
    }
    return MarkdownUtil.parseTableCells(value).length >= 2;
  }

  private static isTableSeparator(value: string): boolean {
    if (value.indexOf('|') < 0) {
      return false;
    }
    const cells: string[] = MarkdownUtil.parseTableCells(value);
    if (cells.length < 2) {
      return false;
    }
    for (let i: number = 0; i < cells.length; i++) {
      const cell: string = cells[i].replace(/:/g, '').replace(/-/g, '').trim();
      if (cell.length > 0) {
        return false;
      }
    }
    return true;
  }

  private static isNextTableSeparator(lines: string[], index: number): boolean {
    if (index + 1 >= lines.length) {
      return false;
    }
    return MarkdownUtil.isTableSeparator(lines[index + 1].trim());
  }

  private static parseTableCells(value: string): string[] {
    let row: string = value.trim();
    if (row.charAt(0) === '|') {
      row = row.substring(1);
    }
    if (row.length > 0 && row.charAt(row.length - 1) === '|') {
      row = row.substring(0, row.length - 1);
    }
    const rawCells: string[] = row.split('|');
    const cells: string[] = [];
    for (let i: number = 0; i < rawCells.length; i++) {
      const cell: string = MarkdownUtil.stripInline(rawCells[i].trim());
      cells.push(cell);
    }
    return cells;
  }

  private static isDigits(value: string): boolean {
    if (value.length === 0) {
      return false;
    }
    for (let i: number = 0; i < value.length; i++) {
      const code: number = value.charCodeAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return true;
  }
}
