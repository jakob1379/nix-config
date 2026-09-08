import assert from "node:assert/strict";
import { test } from "node:test";
import { optionsUrl, parse, run, toMarkdown, withLinks } from "./nix.ts";

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

test("withLinks inserts a homepage/source section under the heading and index", () => {
  assert.equal(
    withLinks("# pkg\n\n*nixpkgs*\n\ndescription", "https://a.com\n", "https://b.com\n"),
    "# pkg\n\n*nixpkgs*\n\n**homepage/source**\n\n<https://a.com>\n\n<https://b.com>\n\ndescription",
  );
  assert.equal(
    withLinks("# pkg\n\ndescription", "https://a.com", ""),
    "# pkg\n\n**homepage/source**\n\n<https://a.com>\n\ndescription",
  );
});

test("withLinks drops empty links and skips the section when both are empty", () => {
  assert.equal(withLinks("# pkg", "", "  "), "# pkg");
  assert.equal(withLinks("", "https://a.com", ""), "");
});

test("optionsUrl points Home-Manager options at the option search", () => {
  assert.equal(
    optionsUrl({ line: "home-manager/ programs.mcp.enable", index: "home-manager", attr: "programs.mcp.enable" }),
    "https://home-manager-options.extranix.com/?query=programs.mcp.enable&release=master",
  );
  assert.equal(
    optionsUrl({
      line: 'home-manager/ targets.darwin.defaults."com.apple.Safari".AutoFillPasswords',
      index: "home-manager",
      attr: 'targets.darwin.defaults."com.apple.Safari".AutoFillPasswords',
    }),
    "https://home-manager-options.extranix.com/?query=targets.darwin.defaults.%22com.apple.Safari%22.AutoFillPasswords&release=master",
  );
  assert.equal(
    optionsUrl({ line: "nixos/ services.openssh.enable", index: "nixos", attr: "services.openssh.enable" }),
    null,
  );
});

test("run never overlaps processes", async () => {
  const log = `${process.env.TMPDIR ?? "/tmp"}/nix-find-run-${process.pid}`;
  const step = `echo start >> ${log}; sleep 0.1; echo end >> ${log}`;
  await Promise.all([
    run("sh", ["-c", step]),
    run("false", []).catch(() => ""),
    run("sh", ["-c", step]),
  ]);
  assert.equal(await run("cat", [log]), "start\nend\nstart\nend\n");
  await run("rm", [log]);
});
