"""Render a progress-party page from a state file.

render.py <state.json> <out.html> [--pct N]   (--pct overrides progress, for previews)
render.py --selftest

Prints a summary JSON: pct, tier, headline, counts, ascii.
"""

import datetime as dt
import html
import json
import pathlib
import sys

STATES = ("done", "running", "queued", "failed")
TIERS = [
    (0, "Warming up", "🙂"),
    (50, "Getting loud", "😄"),
    (65, "Now we're cooking", "🥳"),
    (80, "THE ROOF IS ON FIRE", "🤩"),
    (90, "UNSTOPPABLE", "🚀"),
    (100, "MAXIMUM GLORY", "👑"),
]
EMOJI = {"done": "🎉", "failed": "💥", "running": "🪩", "queued": "💤"}


def summarize(state, override=None):
    units = state["units"]
    for unit in units:
        if unit["state"] not in STATES:
            raise ValueError(
                f"unit {unit.get('label')!r}: state must be one of {STATES}"
            )
    counts = {s: sum(u["state"] == s for u in units) for s in STATES}
    progress = counts["done"] + sum(
        min(max(float(u.get("frac", 0)), 0), 0.97)
        for u in units
        if u["state"] == "running"
    )
    pct = round(100 * progress / len(units)) if units else 0
    if override is not None:
        pct = override
    tier = max(i for i, (low, _, _) in enumerate(TIERS) if pct >= low)
    if pct == 100 and counts["done"] < len(units) and override is None:
        tier = 4
    headline, face = TIERS[tier][1], TIERS[tier][2]
    if counts["failed"]:
        headline, face = f"Party paused: {counts['failed']} failed", "💥"
    filled = round(pct / 5)
    ascii_bar = (
        f"[{'█' * filled}{'░' * (20 - filled)}] {pct}% {headline} {face} · "
        + " · ".join(f"{counts[s]} {s}" for s in STATES)
    )
    return {
        "pct": pct,
        "tier": tier,
        "headline": headline,
        "face": face,
        **counts,
        "ascii": ascii_bar,
    }


def render(state, summary):
    pct, tier, h = summary["pct"], summary["tier"], summary["pct"] / 100
    rows = "".join(
        f'<div class="row {u["state"]}"><span class="nm">{html.escape(u["label"])}</span>'
        f'<span class="st">{EMOJI[u["state"]]} {html.escape(u.get("detail", u["state"]))}</span></div>'
        for u in state["units"]
    )
    meter = (
        "👑" * 5
        if tier == 5
        else "".join(
            f'<span class="flame{" on" if i < tier else ""}">🔥</span>'
            for i in range(5)
        )
    )
    counts = " · ".join(f"{summary[s]} {s}" for s in STATES if summary[s])
    cfg = {
        "confetti": round(6 + 230 * h**3),
        "fall": round(max(7.5 - 5 * h, 1.6), 2),
        "bursts": max(tier - 1, 0) + (3 if tier == 5 else 0),
        "emoji": 0 if tier < 3 else 8 * (tier - 2) + (20 if tier == 5 else 0),
    }
    css_vars = (
        f"--h:{h:.2f};--glow-px:{round(6 + 54 * h)}px;--bg-speed:{round(max(14 - 2.2 * tier, 2), 1)}s;"
        f"--stripe-speed:{round(max(1.8 - 1.4 * h, 0.35), 2)}s;--title:{22 + 3 * tier}px;"
    )
    return PAGE.format(
        css_vars=css_vars,
        tier=tier,
        pct=pct,
        rows=rows,
        meter=meter,
        counts=counts,
        cfg=json.dumps(cfg),
        headline=html.escape(summary["headline"]),
        face=summary["face"],
        title=html.escape(state.get("title", "Progress")),
        now=dt.datetime.now().strftime("%H:%M:%S"),
    )


def selftest():
    unit = lambda s, f=None: {
        "label": s,
        "state": s,
        **({"frac": f} if f is not None else {}),
    }
    assert summarize({"units": []})["pct"] == 0
    s = summarize(
        {"units": [unit("done"), unit("running", 0.5), unit("queued"), unit("failed")]}
    )
    assert (s["pct"], s["tier"], s["headline"]) == (38, 0, "Party paused: 1 failed"), s
    s = summarize({"units": [unit("done")] * 99 + [unit("running", 0.9)]})
    assert (s["pct"], s["tier"]) == (100, 4), s
    s = summarize({"units": [unit("done")] * 4})
    assert (s["pct"], s["tier"], s["headline"]) == (100, 5, "MAXIMUM GLORY"), s
    render({"units": [unit("done")]}, s)
    print("selftest ok")


PAGE = """<!doctype html><html><head><meta charset="utf-8"><style>
:root{{{css_vars}
 --c1:var(--chart-1,#e11d48);--c2:var(--chart-2,#f59e0b);--c3:var(--chart-3,#10b981);--c4:var(--chart-4,#3b82f6);--c5:var(--chart-5,#8b5cf6);--c6:var(--chart-6,#ec4899);
 --fg:var(--foreground,#18181b);--muted:var(--muted-foreground,#71717a);--cardc:var(--card,#fff);--sec:var(--secondary,#f4f4f5);
 --line:var(--border,#e4e4e7);--ok:var(--success,#16a34a);--bad:var(--destructive,#dc2626);--prim:var(--primary,#6366f1);--rad:var(--radius,12px)}}
body{{margin:0;font-family:var(--font-sans,system-ui,sans-serif);color:var(--fg)}}
.wrap{{position:relative;overflow:hidden;padding:18px 16px 16px;border-radius:var(--rad);isolation:isolate;
 background:linear-gradient(135deg,color-mix(in oklab,var(--c1) calc(10% + 25% * var(--h)),transparent),color-mix(in oklab,var(--c4) calc(10% + 25% * var(--h)),transparent),color-mix(in oklab,var(--c2) calc(10% + 25% * var(--h)),transparent),color-mix(in oklab,var(--c5) calc(10% + 25% * var(--h)),transparent));
 background-size:400% 400%;animation:bgshift var(--bg-speed) ease infinite}}
.t5 .wrap{{animation:bgshift var(--bg-speed) ease infinite,shake .45s ease-in-out infinite}}
@keyframes shake{{25%{{transform:translate(1px,-1px) rotate(-.25deg)}}75%{{transform:translate(-1px,1px) rotate(.25deg)}}}}
@keyframes bgshift{{0%{{background-position:0% 50%}}50%{{background-position:100% 50%}}100%{{background-position:0% 50%}}}}
.t3 .wrap::before,.t4 .wrap::before,.t5 .wrap::before{{content:"";position:absolute;inset:-50%;z-index:-1;pointer-events:none;
 background:conic-gradient(from 0deg,transparent 0 10%,color-mix(in oklab,var(--c3) 22%,transparent) 12%,transparent 14% 30%,color-mix(in oklab,var(--c1) 22%,transparent) 32%,transparent 34% 55%,color-mix(in oklab,var(--c6) 22%,transparent) 57%,transparent 59% 80%,color-mix(in oklab,var(--c4) 22%,transparent) 82%,transparent 84%);
 animation:spin calc(var(--bg-speed) * 2) linear infinite}}
h1{{margin:0 0 2px;font-size:var(--title);letter-spacing:.5px;display:flex;align-items:center;gap:10px;line-height:1.15}}
h1 .ball{{display:inline-block;animation:spin calc(3s - 2s * var(--h)) linear infinite}}
.t3 h1 .txt,.t4 h1 .txt,.t5 h1 .txt{{background:linear-gradient(90deg,var(--c1),var(--c2),var(--c3),var(--c4),var(--c5),var(--c6),var(--c1));background-size:200% 100%;
 -webkit-background-clip:text;background-clip:text;color:transparent;animation:rainbow 2s linear infinite}}
.t4 h1 .txt,.t5 h1 .txt{{animation:rainbow 1s linear infinite,throb .9s ease-in-out infinite;display:inline-block}}
@keyframes rainbow{{to{{background-position:200% 0}}}}
@keyframes throb{{50%{{transform:scale(1.06)}}}}
@keyframes spin{{to{{transform:rotate(360deg)}}}}
.sub{{color:var(--muted);font-size:13px;margin-bottom:10px;display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap}}
.meter{{letter-spacing:2px;font-size:15px}} .flame{{filter:grayscale(1);opacity:.25}} .flame.on{{filter:none;opacity:1;display:inline-block;animation:flick .6s ease-in-out infinite alternate}}
@keyframes flick{{to{{transform:translateY(-2px) scale(1.15)}}}}
.bar{{position:relative;height:34px;border-radius:999px;background:var(--sec);overflow:hidden;box-shadow:inset 0 0 0 1px var(--line)}}
.fill{{position:absolute;inset:0 auto 0 0;width:{pct}%;border-radius:999px;
 background:repeating-linear-gradient(115deg,var(--c1) 0 18px,var(--c2) 18px 36px,var(--c3) 36px 54px,var(--c4) 54px 72px,var(--c5) 72px 90px,var(--c6) 90px 108px);
 background-size:216px 100%;animation:stripes var(--stripe-speed) linear infinite,pulse 1.6s ease-in-out infinite;
 box-shadow:0 0 var(--glow-px) color-mix(in oklab,var(--prim) 70%,transparent),0 0 calc(var(--glow-px) * 1.6) color-mix(in oklab,var(--c4) calc(60% * var(--h)),transparent)}}
.fill::after{{content:"";position:absolute;inset:0;background:linear-gradient(100deg,transparent 30%,#fff8 50%,transparent 70%);background-size:250% 100%;animation:sheen calc(2.6s - 1.8s * var(--h)) linear infinite}}
@keyframes sheen{{from{{background-position:150% 0}}to{{background-position:-100% 0}}}}
@keyframes stripes{{to{{background-position:216px 0}}}}
@keyframes pulse{{50%{{filter:brightness(calc(1 + .4 * var(--h))) saturate(calc(1 + .6 * var(--h)))}}}}
.pct{{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-weight:900;font-size:calc(14px + 6px * var(--h));
 color:#fff;text-shadow:0 1px 3px #000a,0 0 10px #0008;letter-spacing:1px}}
.rows{{display:grid;gap:4px;margin-top:14px}}
.row{{display:grid;grid-template-columns:1fr auto;gap:10px;align-items:center;padding:7px 12px;border-radius:8px;font-size:13px;background:color-mix(in oklab,var(--cardc) 75%,transparent);border:1px solid var(--line)}}
.row .nm{{font-weight:600;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}}
.row .st{{text-align:right;font-size:12px;font-family:var(--font-mono,ui-monospace,monospace)}}
.row.done .st{{color:var(--ok)}} .row.failed{{border-color:var(--bad)}} .row.failed .st{{color:var(--bad)}}
.t4 .row.done .st,.t5 .row.done .st{{text-shadow:0 0 8px color-mix(in oklab,var(--ok) 70%,transparent)}}
.row.running{{background:linear-gradient(90deg,color-mix(in oklab,var(--c4) 30%,transparent),color-mix(in oklab,var(--c1) 30%,transparent));background-size:200% 100%;animation:bgshift 2s ease infinite}}
.row.running .st{{font-weight:700}} .row.queued{{opacity:.55}}
.foot{{margin-top:12px;font-size:12px;color:var(--muted);display:flex;justify-content:space-between;flex-wrap:wrap;gap:6px}}
.fx{{position:absolute;pointer-events:none;z-index:2}}
.confetti{{top:-14px;width:8px;height:14px;border-radius:2px;opacity:.9;animation:fall linear infinite}}
@keyframes fall{{to{{transform:translateY(800px) rotate(900deg)}}}}
.emo{{top:-30px;font-size:20px;animation:fall linear infinite}}
.spark{{width:5px;height:5px;border-radius:50%;animation:burst 1.6s ease-out infinite;opacity:0}}
@keyframes burst{{0%{{transform:translate(0,0) scale(1);opacity:1}}80%{{opacity:1}}100%{{transform:translate(var(--dx),var(--dy)) scale(.3);opacity:0}}}}
@media (prefers-reduced-motion:reduce){{*,*::before,*::after{{animation:none!important}}.fx{{display:none}}}}
</style></head><body class="t{tier}"><div class="wrap" id="w">
<h1><span class="ball">🪩</span><span class="txt">{headline}</span><span class="ball">{face}</span></h1>
<div class="sub"><span>{title} · checked {now}</span><span class="meter" title="hype level">{meter}</span></div>
<div class="bar"><div class="fill"></div><div class="pct">{pct}% {face}</div></div>
<div class="rows">{rows}</div>
<div class="foot"><span>{counts}</span><span>🎈 progress-party 🎈</span></div>
</div><script>
const cfg={cfg};const w=document.getElementById('w');
const c=['var(--c1)','var(--c2)','var(--c3)','var(--c4)','var(--c5)','var(--c6)'];
const R=Math.random;
for(let i=0;i<cfg.confetti;i++){{const d=document.createElement('div');d.className='fx confetti';d.style.left=R()*100+'%';
 d.style.background=c[i%6];d.style.animationDuration=(cfg.fall*(0.6+R()*0.8))+'s';d.style.animationDelay=(-R()*cfg.fall*1.4)+'s';
 if(i%3==0){{d.style.borderRadius='50%';d.style.width=d.style.height='9px'}}w.appendChild(d)}}
const E=['🎉','🥳','🪩','🎊','🦄','🍾','✨','🌈','🏆','💃','🕺','👑'];
for(let i=0;i<cfg.emoji;i++){{const d=document.createElement('div');d.className='fx emo';d.textContent=E[i%E.length];d.style.left=R()*96+'%';
 d.style.fontSize=(16+R()*18)+'px';d.style.animationDuration=(cfg.fall*(1+R()))+'s';d.style.animationDelay=(-R()*cfg.fall*2)+'s';w.appendChild(d)}}
for(let b=0;b<cfg.bursts;b++){{const x=8+R()*84,y=8+R()*60,delay=-R()*1.6,col=c[b%6];
 for(let k=0;k<26;k++){{const a=k/26*Math.PI*2,r=40+R()*50;const s=document.createElement('div');s.className='fx spark';
  s.style.left=x+'%';s.style.top=y+'%';s.style.background=col;s.style.boxShadow='0 0 6px '+col;
  s.style.setProperty('--dx',Math.cos(a)*r+'px');s.style.setProperty('--dy',Math.sin(a)*r+'px');
  s.style.animationDelay=(delay+b*0.37)+'s';s.style.animationDuration=(1.2+R()*0.8)+'s';w.appendChild(s)}}}}
</script></body></html>"""


def main():
    if sys.argv[1:] == ["--selftest"]:
        return selftest()
    state = json.loads(pathlib.Path(sys.argv[1]).read_text())
    override = (
        int(sys.argv[sys.argv.index("--pct") + 1]) if "--pct" in sys.argv else None
    )
    summary = summarize(state, override)
    pathlib.Path(sys.argv[2]).write_text(render(state, summary))
    print(json.dumps(summary, ensure_ascii=False))


main()
