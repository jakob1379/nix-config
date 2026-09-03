import assert from "node:assert/strict";
import { test } from "node:test";
import { parse, toMarkdown, withLinks } from "./nix.ts";

const B = "\x1b[1m";
const b = "\x1b[22m";
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";

test("parse splits index from attribute", () => {
  assert.deepEqual(parse("nixpkgs/ firefox"), [
    { line: "nixpkgs/ firefox", index: "nixpkgs", attr: "firefox" },
  ]);
});

test("parse handles every index and attributes with dots and dashes", () => {
  const out = [
    "nixpkgs/ CuboCore.coreaction",
    "home-manager/ programs.git.enable",
    "nixos/ services.openssh.enable",
    "nur/ nur.repos.0x4A6F.autorandr-rs",
  ].join("\n");
  assert.deepEqual(
    parse(out).map((e) => [e.index, e.attr]),
    [
      ["nixpkgs", "CuboCore.coreaction"],
      ["home-manager", "programs.git.enable"],
      ["nixos", "services.openssh.enable"],
      ["nur", "nur.repos.0x4A6F.autorandr-rs"],
    ],
  );
});

test("parse skips blank and malformed lines", () => {
  assert.deepEqual(parse("\n  \nnot-a-result\nnixpkgs/ \nnixpkgs/ jq\n"), [
    { line: "nixpkgs/ jq", index: "nixpkgs", attr: "jq" },
  ]);
});

test("parse caps results", () => {
  const out = Array.from({ length: 250 }, (_, i) => `nixpkgs/ pkg${i}`).join("\n");
  assert.equal(parse(out).length, 100);
});

test("toMarkdown headings the title, keeps inline bold and fences values", () => {
  const preview = [
    `\x1b[31mservices.emacs.\x1b[0m\x1b[31m${B}client\x1b[22m${RESET}`,
    `${DIM}Arguments for ${B}emacsclient${b}${DIM}.${b}`,
    "",
    `${B}type${b}`,
    "list of string",
  ].join("\n");
  assert.equal(
    toMarkdown(preview, "home-manager"),
    [
      "# services.emacs.client",
      "*home-manager*",
      "Arguments for **emacsclient**.",
      "**type**\n\n```nix\nlist of string\n```",
    ].join("\n\n"),
  );
});

test("toMarkdown unboxes and dedents literal values", () => {
  const preview = [
    `${B}pkg${b}`,
    "",
    `${B}default${b}`,
    "┌────────┐",
    "│ [      │",
    '│   "-c" │',
    "│ ]      │",
    "└────────┘",
  ].join("\n");
  assert.match(toMarkdown(preview), /```nix\n\[\n {2}"-c"\n]\n```/);
});

test("toMarkdown autolinks a lone url instead of fencing it", () => {
  const preview = [`${B}pkg${b}`, "", `${B}homepage${b}`, "https://example.com/x"].join("\n");
  assert.match(toMarkdown(preview), /\*\*homepage\*\*\n\n<https:\/\/example\.com\/x>/);
});

test("toMarkdown escapes markdown metacharacters in option paths", () => {
  const preview = `${B}services.foo.<name>.bar${b}`;
  assert.equal(toMarkdown(preview), "# services.foo.\\<name\\>.bar");
});

test("toMarkdown returns empty for empty preview", () => {
  assert.equal(toMarkdown(""), "");
});

test("withLinks appends homepage and source", () => {
  assert.equal(
    withLinks("# pkg", "https://a.com\n", "https://b.com\n"),
    "# pkg\n\n[Homepage](https://a.com) • [Source](https://b.com)",
  );
});

test("withLinks skips urls already in the preview and duplicates", () => {
  assert.equal(
    withLinks("# pkg\n\n<https://a.com>", "https://a.com", "https://b.com"),
    "# pkg\n\n<https://a.com>\n\n[Source](https://b.com)",
  );
  assert.equal(
    withLinks("# opt", "https://a.com", "https://a.com"),
    "# opt\n\n[Homepage](https://a.com)",
  );
  assert.equal(withLinks("# pkg\n\n<https://a.com>", "https://a.com", ""), "# pkg\n\n<https://a.com>");
});
