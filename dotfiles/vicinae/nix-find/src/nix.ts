import { execFile } from "node:child_process";

export type Entry = { line: string; index: string; attr: string };

const RESULT_LIMIT = 100;
const SGR = /\x1b\[([0-9;]*)m/g;
const BOX_EDGE = /^[┌└][─┐┘]*$/;
const BOX_ROW = /^│(.*)│$/;

export function run(cmd: string, args: string[]): Promise<string> {
  return new Promise((resolve, reject) =>
    execFile(cmd, args, { maxBuffer: 64 << 20 }, (err, stdout) =>
      err ? reject(err) : resolve(stdout),
    ),
  );
}

/** Parses `nix-find -p` output lines, which look like `nixpkgs/ firefox`. */
export function parse(stdout: string): Entry[] {
  const entries: Entry[] = [];
  for (const line of stdout.split("\n")) {
    const match = line.match(/^([^/\s]+)\/\s+(\S.*)$/);
    if (!match) continue;
    entries.push({ line, index: match[1]!, attr: match[2]!.trim() });
    if (entries.length === RESULT_LIMIT) break;
  }
  return entries;
}

type Span = { text: string; bold: boolean };
type Line = Span[];

/** Splits one ANSI-coloured line into spans, tracking only bold (SGR 1/22/0). */
function spans(line: string): Line {
  const out: Line = [];
  let bold = false;
  let at = 0;
  SGR.lastIndex = 0;
  for (let m = SGR.exec(line); m; m = SGR.exec(line)) {
    if (m.index > at) out.push({ text: line.slice(at, m.index), bold });
    for (const code of m[1]!.split(";")) {
      if (code === "1") bold = true;
      else if (code === "" || code === "0" || code === "22") bold = false;
    }
    at = SGR.lastIndex;
  }
  if (at < line.length) out.push({ text: line.slice(at), bold });
  return out;
}

const escape = (text: string) => text.replace(/([\\`*_[\]<>])/g, "\\$1");

const inline = (line: Line) =>
  line
    .filter((span) => span.text)
    .map((span) => (span.bold ? `**${escape(span.text)}**` : escape(span.text)))
    .join("");

const plain = (line: Line) => line.map((span) => span.text).join("");

const isHeader = (line: Line) => Boolean(line[0]?.bold && line[0].text.trim() === line[0].text);

/** Drops the box-drawing frame `nix-search-tv` puts around literal values. */
function unbox(lines: string[]): string[] {
  if (!lines.some((line) => BOX_EDGE.test(line))) return lines;
  const rows = lines.flatMap((line) => {
    if (BOX_EDGE.test(line)) return [];
    const row = line.match(BOX_ROW);
    return [(row ? row[1]! : line).trimEnd()];
  });
  const indent = Math.min(
    ...rows.filter((row) => row).map((row) => row.length - row.trimStart().length),
  );
  return rows.map((row) => row.slice(indent));
}

/** A header plus its value, as bold text over a `nix` block or an autolink. */
function section(header: Line, value: Line[]): string {
  const body = unbox(value.map(plain)).join("\n").trim();
  if (!body) return inline(header);
  const fenced = /^https?:\/\/\S+$/.test(body) ? `<${body}>` : "```nix\n" + body + "\n```";
  return `${inline(header)}\n\n${fenced}`;
}

/** Appends homepage/source links; homepage is skipped if the preview already shows it. */
export function withLinks(markdown: string, homepage: string, source: string): string {
  const links: string[] = [];
  const home = homepage.trim();
  const src = source.trim();
  if (home && !markdown.includes(home)) links.push(`[Homepage](${home})`);
  if (src) links.push(`[Source](${src})`);
  return links.length ? `${markdown}\n\n${links.join(" • ")}` : markdown;
}

/**
 * Renders `nix-search-tv preview` output as markdown: the attribute becomes a
 * heading, bold ANSI runs stay bold, and literal values become `nix` code
 * blocks so Vicinae syntax-highlights them.
 */
export function toMarkdown(preview: string, index?: string): string {
  const lines = preview.replace(/\s+$/, "").split("\n").map(spans);
  if (lines.length === 0 || !plain(lines[0]!).trim()) return "";

  const blocks = [`# ${escape(plain(lines[0]!).trim())}`];
  if (index) blocks.push(`*${escape(index)}*`);

  let header: Line | null = null;
  let value: Line[] = [];
  const flush = () => {
    if (header) blocks.push(section(header, value));
    else if (value.length) blocks.push(value.map(inline).join("\n"));
    header = null;
    value = [];
  };

  for (const line of lines.slice(1)) {
    if (isHeader(line)) {
      flush();
      header = line;
    } else if (plain(line).trim()) {
      value.push(line);
    } else {
      flush();
    }
  }
  flush();

  return blocks.join("\n\n");
}
