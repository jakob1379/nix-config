import {
  Action,
  ActionPanel,
  Icon,
  List,
  open,
  showToast,
  Toast,
  type Image,
} from "@vicinae/api";
import { useEffect, useState } from "react";
import { parse, run, toMarkdown, withLinks, type Entry } from "./nix.ts";

/**
 * The index is shown as its own logo so the whole row width stays with the
 * attribute. All four are the Nix snowflake; Home-Manager, which has no mark of
 * its own, gets it under a roof.
 */
const INDEX_ICONS: Record<string, Image.ImageLike> = {
  nixpkgs: "nixpkgs.svg",
  nixos: "nixos.svg",
  "home-manager": "home-manager.svg",
  nur: "nur.svg",
};

function useSearch(query: string) {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!query.trim()) {
      setEntries([]);
      setIsLoading(false);
      return;
    }
    let cancelled = false;
    setIsLoading(true);
    run("nix-find", ["-p", query])
      .then((stdout) => !cancelled && setEntries(parse(stdout)))
      .catch((err: Error) => {
        if (cancelled) return;
        setEntries([]);
        showToast(Toast.Style.Failure, "nix-find failed", err.message);
      })
      .finally(() => !cancelled && setIsLoading(false));
    return () => {
      cancelled = true;
    };
  }, [query]);

  return { entries, isLoading };
}

function usePreview(entry: Entry | undefined) {
  const [markdown, setMarkdown] = useState("");

  useEffect(() => {
    if (!entry) {
      setMarkdown("");
      return;
    }
    let cancelled = false;
    const resolve = (subcommand: string) =>
      run("nix-search-tv", [subcommand, entry.line]).catch(() => "");
    Promise.all([resolve("preview"), resolve("homepage"), resolve("source")]).then(
      ([preview, homepage, source]) =>
        !cancelled &&
        setMarkdown(withLinks(toMarkdown(preview, entry.index), homepage, source)),
    );
    return () => {
      cancelled = true;
    };
  }, [entry?.line]);

  return markdown;
}

async function openResolved(subcommand: "homepage" | "source", entry: Entry) {
  try {
    const url = (await run("nix-search-tv", [subcommand, entry.line])).trim();
    if (!url) throw new Error(`nothing published for ${entry.attr}`);
    await open(url);
  } catch (err) {
    showToast(Toast.Style.Failure, `No ${subcommand}`, (err as Error).message);
  }
}

export default function Search() {
  const [query, setQuery] = useState("");
  const [selected, setSelected] = useState<string | null>(null);
  const [showDetail, setShowDetail] = useState(true);
  const { entries, isLoading } = useSearch(query);
  const current = entries.find((entry) => entry.line === selected);
  const markdown = usePreview(current);

  return (
    <List
      isShowingDetail={showDetail}
      isLoading={isLoading}
      throttle
      filtering={false}
      onSearchTextChange={setQuery}
      onSelectionChange={setSelected}
      searchBarPlaceholder="Search nixpkgs, nixos, home-manager and nur at once"
    >
      {entries.map((entry) => (
        <List.Item
          key={entry.line}
          id={entry.line}
          title={entry.attr}
          icon={INDEX_ICONS[entry.index] ?? Icon.QuestionMarkCircle}
          detail={<List.Item.Detail markdown={markdown} />}
          actions={
            <ActionPanel>
              <Action.CopyToClipboard title="Copy Attribute" content={entry.attr} />
              <Action.CopyToClipboard
                title="Copy Nix-Shell Command"
                content={`nix-shell -p ${entry.attr}`}
              />
              <Action
                title={showDetail ? "Hide Preview" : "Show Preview"}
                icon={showDetail ? Icon.EyeDisabled : Icon.Eye}
                shortcut={{ modifiers: ["opt"], key: "l" }}
                onAction={() => setShowDetail((shown) => !shown)}
              />
              <Action
                title="Open Homepage"
                icon={Icon.Globe01}
                onAction={() => openResolved("homepage", entry)}
              />
              <Action
                title="Open Source"
                icon={Icon.Code}
                onAction={() => openResolved("source", entry)}
              />
            </ActionPanel>
          }
        />
      ))}
      <List.EmptyView
        title={query.trim() ? "No matches" : "Search Nix"}
        description={
          query.trim()
            ? "Nothing matched that query."
            : "Type to fuzzy-search packages and options across nixpkgs, nixos, home-manager and nur."
        }
      />
    </List>
  );
}
