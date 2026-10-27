#!/usr/bin/env bash
set -euo pipefail

script=$(realpath "${1:-$(dirname "$0")/../bin/nix-find}")
work=$(mktemp -d)
trap 'chmod -R u+w "$work"; rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/flake/.git" "$work/plain"
touch "$work/flake/flake.nix" "$work/flake/flake.lock" "$work/plain/flake.nix" "$work/plain/flake.lock"

stub() {
	printf '#!%s\n%s\n' "$BASH" "$2" >"$work/bin/$1"
	chmod +x "$work/bin/$1"
}
# shellcheck disable=SC2016
stub fzf '[[ -z ${FZF_STARTED:-} ]] || touch "$FZF_STARTED"
cat >/dev/null
if [[ -z ${ALT_ENTER:-} ]]; then
	printf "%s\n" "$SELECTION"
	exit
fi
for arg; do
	[[ $arg == alt-enter:become\(*\) ]] && action=${arg#alt-enter:become(} && action=${action%)}
done
eval "${action//"{}"/$(printf %q "$SELECTION")}"'
# shellcheck disable=SC2016
stub nix-search-tv '[[ $1 == print && $2 == --config ]] && cp "$3" "$SEEN_CONFIG"'

# shellcheck disable=SC2016
stub nix 'printf "%s\n" "$*" >>"$NIX_LOG"
if [[ -n ${CONCURRENCY:-} && $* == *"kind = \"inputs\""* ]]; then
	printf "c1\nc2\nc3\nc4\nc5\nc6\n"
	exit
fi
if [[ -n ${CONCURRENCY:-} && $* == *"kind = \"plan\""* ]]; then
	echo start >>"$CONCURRENCY"
	sleep 0.5
	echo end >>"$CONCURRENCY"
	exit
fi
if [[ -n ${SLOW_PLAN:-} && $* == *"kind = \"plan\""* ]]; then
	echo $$ >>"$SLOW_PIDS"
	exec sleep 30
fi
case "$*" in
	"flake metadata"*) echo "{\"path\": \"/nix/store/stub-source\", \"locked\": {\"narHash\": \"sha256-stub\"}}" ;;
	"config show system") echo x86_64-linux ;;
	*"kind = \"inputs\""*) printf "foo\nskipped\nifd\n../../evil\n" ;;
	*"kind = \"plan\""*"input = \"foo\""* | *"kind = \"plan\""*evil*) echo "github:o/foo/abc packages" ;;
	*"kind = \"plan\""*"input = \"ifd\""*) echo "github:o/ifd/abc packages" ;;
	*"kind = \"packages\""*"input = \"ifd\""*) exit 1 ;;
	*"kind = \"packageNames\""*) echo "{\"packages.built\": {\"description\": \"\", \"type\": \"package\"}}" ;;
	*"kind = \"plan\""*) ;;
	*"kind = \"packages\""*) echo "{\"packages.bar\": {\"description\": \"\", \"type\": \"package\"}}" ;;
	*) exit 1 ;;
esac'

check() {
	local got
	got=$(cd "$work/flake" && SELECTION=$1 PATH=$work/bin:$PATH XDG_CACHE_HOME=$work/cache \
		XDG_CONFIG_HOME=$work/config SEEN_CONFIG=$work/seen-config NIX_LOG=$work/nix.log \
		"$BASH" -euo pipefail "$script" 2>"$work/check.err")
	[[ $got == "$2" ]] || {
		printf 'FAIL: %q\n  want: %s\n  got:  %s\n' "$1" "$2" "$got" >&2
		cat "$work/check.err" >&2
		exit 1
	}
}

check 'nixpkgs/ hello' 'nix-shell -p hello'
check $'nixpkgs/ hello\ninputs.foo/ packages.bar' 'nix shell nixpkgs#hello github:o/foo/abc#bar'
check 'inputs.foo/ packages.bar.1' 'nix shell github:o/foo/abc#\"bar.1\"'
ALT_ENTER=1 check 'inputs.foo/ packages.bar' 'nix run github:o/foo/abc#bar'
jq -e '.experimental.options_file["inputs.foo"]' "$work/seen-config" >/dev/null || {
	echo "FAIL: nix-search-tv was not given an inputs.foo index" >&2
	exit 1
}
jq -e '.["packages.bar"]' "$(jq -r '.experimental.options_file["inputs.foo"]' "$work/seen-config")" >/dev/null || {
	echo "FAIL: the inputs.foo index does not list packages.bar" >&2
	exit 1
}
jq -e '.["packages.built"]' "$(jq -r '.experimental.options_file["inputs.ifd"]' "$work/seen-config")" >/dev/null || {
	echo "FAIL: an input whose packages fail to describe lost its package list" >&2
	exit 1
}
[[ $(grep -c 'kind = "inputs"' "$work/nix.log") == 1 ]] || {
	echo "FAIL: input indexes were rebuilt without a flake.lock change" >&2
	exit 1
}
echo changed >>"$work/flake/flake.lock"
check 'nixpkgs/ hello' 'nix-shell -p hello'
[[ $(grep -c 'kind = "inputs"' "$work/nix.log") == 2 ]] || {
	echo "FAIL: input indexes were not rebuilt after a flake.lock change" >&2
	exit 1
}
if [[ -n $(find "$work" -name 'evil*' -print -quit) ]]; then
	echo "FAIL: an input name escaped the cache directory" >&2
	exit 1
fi
mkdir -p "$work/flake/gitproject/.git"
before=$(grep -c 'flake metadata' "$work/nix.log")
(cd "$work/flake/gitproject" && SELECTION=x PATH=$work/bin:$PATH XDG_CACHE_HOME=$work/gitcache XDG_CONFIG_HOME=$work/config \
	SEEN_CONFIG=$work/seen-config NIX_LOG=$work/nix.log "$BASH" -euo pipefail "$script" >/dev/null 2>&1)
[[ $(grep -c 'flake metadata' "$work/nix.log") == "$before" ]] || {
	echo "FAIL: a git project without a flake indexed the flake above it" >&2
	exit 1
}
(cd "$work/plain" && SELECTION=x PATH=$work/bin:$PATH XDG_CACHE_HOME=$work/plaincache XDG_CONFIG_HOME=$work/config \
	SEEN_CONFIG=$work/seen-config NIX_LOG=$work/nix.log "$BASH" -euo pipefail "$script" >/dev/null 2>&1)
[[ $(grep -c 'flake metadata' "$work/nix.log") == "$before" ]] || {
	echo "FAIL: a flake outside a git repo was copied to the store for indexing" >&2
	exit 1
}
(cd "$work/flake" && SELECTION=x PATH=$work/bin:$PATH XDG_CACHE_HOME=$work/abortcache XDG_CONFIG_HOME=$work/config \
	SEEN_CONFIG=$work/seen-config NIX_LOG=$work/abort.log SLOW_PLAN=1 SLOW_PIDS=$work/slow.pids FZF_STARTED=$work/fzf.started \
	exec "$BASH" -euo pipefail "$script" >/dev/null 2>&1) &
pid=$!
for _ in {1..100}; do
	[[ -s $work/slow.pids ]] && break
	sleep 0.1
done
[[ -e $work/fzf.started ]] || {
	echo "FAIL: fzf waited for the input indexing instead of opening at once" >&2
	exit 1
}
aborted_at=$SECONDS
kill -TERM "$pid"
wait "$pid" && rc=0 || rc=$?
[[ $rc == 130 && $((SECONDS - aborted_at)) -lt 10 && -d $work/abortcache &&
	-z $(find "$work/abortcache" -mindepth 2 -print -quit) ]] || {
	echo "FAIL: aborting during indexing exited $rc after $((SECONDS - aborted_at))s or left a partial index behind" >&2
	exit 1
}
while read -r eval_pid; do
	[[ ! -e /proc/$eval_pid ]] || grep -q '^State:.*Z' "/proc/$eval_pid/status" || {
		echo "FAIL: aborting left the eval $eval_pid running" >&2
		exit 1
	}
done <"$work/slow.pids"
(cd "$work/flake" && SELECTION=x PATH=$work/bin:$PATH XDG_CACHE_HOME=$work/conccache XDG_CONFIG_HOME=$work/config \
	SEEN_CONFIG=$work/seen-config NIX_LOG=$work/conc.log CONCURRENCY=$work/concurrency.log \
	"$BASH" -euo pipefail "$script" >/dev/null 2>&1)
peak=$(awk '/start/ { if (++running > peak) peak = running } /end/ { running-- } END { print peak + 0 }' "$work/concurrency.log")
((peak >= 2 && peak <= 4)) || {
	echo "FAIL: indexing ran $peak evals at once, expected parallel but at most 4" >&2
	exit 1
}
mkdir "$work/realbin" "$work/foo" "$work/fakepkgs" "$work/src" "$work/root"
cp "$work/bin/fzf" "$work/bin/nix-search-tv" "$work/realbin/"
export NIX_CONFIG=$'store = '"$work"$'/store\nexperimental-features = nix-command flakes'
system=$(HOME=$work nix config show system)
cat >"$work/foo/flake.nix" <<NIX
{
  outputs = _: {
    packages.$system = {
      hello = { type = "derivation"; name = "hello"; meta.description = "says hello"; };
      "bar.1" = { type = "derivation"; name = "bar"; };
      broken = { type = "derivation"; name = "broken"; meta.description = throw "broken"; };
    };
  };
}
NIX
echo '{ outputs = _: { lib.nixosSystem = null; legacyPackages = { }; }; }' >"$work/fakepkgs/flake.nix"
touch "$work/src/README"
cat >"$work/root/flake.nix" <<NIX
{
  inputs.foo.url = "path:$work/foo";
  inputs.fakepkgs.url = "path:$work/fakepkgs";
  inputs.src = { url = "path:$work/src"; flake = false; };
  inputs.alias.follows = "foo";
  outputs = _: { };
}
NIX
(cd "$work/root" && git init -q && git add flake.nix && HOME=$work nix flake lock 2>"$work/real.err" && git add flake.lock) || {
	cat "$work/real.err" >&2
	exit 1
}
got=$(cd "$work/root" && SELECTION=$'inputs.foo/ packages.hello\ninputs.foo/ packages.bar.1' HOME=$work \
	PATH=$work/realbin:$PATH XDG_CACHE_HOME=$work/realcache XDG_CONFIG_HOME=$work/config \
	SEEN_CONFIG=$work/real-config "$BASH" -euo pipefail "$script" 2>"$work/real.err")
# shellcheck disable=SC2053
[[ $got == nix\ shell\ path:/nix/store/*-source#hello\ path:/nix/store/*-source#\\\"bar.1\\\" ]] || {
	printf 'FAIL: real nix eval\n  got: %s\n' "$got" >&2
	cat "$work/real.err" >&2
	exit 1
}
jq -e '.experimental.options_file | keys == ["inputs.foo"]' "$work/real-config" >/dev/null || {
	echo "FAIL: real nix eval did not index exactly inputs.foo" >&2
	exit 1
}
jq -e '.["packages.hello"].description == "says hello" and .["packages.broken"].description == ""' \
	"$(jq -r '.experimental.options_file["inputs.foo"]' "$work/real-config")" >/dev/null || {
	echo "FAIL: real nix eval produced wrong package descriptions" >&2
	exit 1
}
echo "nix-find: all checks passed"
