# notchD design research — morph feel, QOL, and navigation

*26 November 2026. Read-only survey of notchD plus eight other island/control-centre
implementations, measured against Qt Quick's rendering model. No code changed.*

---

## 0. Summary

1. **The morph is not slow, it is unchoreographed.** The shell completes the
   pill→hub move in 253 ms while the content arrives on a *derived* fade that is
   also done by ~130 ms. Nothing exits first, nothing enters after, nothing
   shares a clock. The eye reads a window wipe, not a shape growing around content.
2. **The biggest single win is not the spring.** It is (a) stop resizing the
   window on tab change, and (b) give content an in/out choreography. Both are
   small diffs in `NotchD.qml` and `HubSurface.qml`.
3. **Vertical tabs fit all 9 destinations; horizontal cannot.** 9 rows of 36 px
   take 324 px of the hub's 470 px height, while 9 horizontal segments need
   ~940 px and leave nothing for the clock. But the count is a symptom: 6 of the
   9 are drill-downs behind a Back arrow, so the real question is whether the hub
   becomes a control centre with a flat 136 px rail or stays a three-tab HUD.
4. **notchD already vendors the better engine.** `vendor/dux/VectorSpringMotion.qml`
   comes from dux-shell, and upstream dux uses the same spring with a *morph-progress*
   content crossfade, 600/49 stiffness, and an outgoing-content freeze. notchD kept
   the engine and dropped the choreography.

---

## 1. What other islands actually do

Pulled from source, not screenshots.

| Project | Stack | Shell motion | Content motion |
|---|---|---|---|
| **Tide-island** (798★) | Quickshell | `Behavior on displayedWidth/displayedHeight` → `NumberAnimation`, `morphDuration: 280`, `Easing.OutQuint`; width also driven directly by swipe progress | Per-element reveal: `opacity: reveal`, `scale: 0.55 + reveal*0.45`, `y + (1-reveal)*10`. Blur regions follow the panels. Tells Hyprland `no_anim` on the layer surface, because compositor scaling stretches text |
| **impasto** (513★) | Quickshell | `Behavior on restWidth` → `durationMorph` + shared easing token; island is "one object that changes shape", each state sized to its content | Separate rest/band/island layers cross-faded by opacity; state ranks: panel > notification > transient > summary > modules |
| **dux-shell `DIsland`** (9.2k★, notchD's upstream) | Quickshell | `VectorSpringMotion`, **stiffness 600 / damping 49** (ζ=1.0) | `morphProgress` = normalised *cross-axis travel* (48→352 px), not a height ratio. `fadeCompact = 1 - m/0.34` (gone by 34 %), `fadeExpanded = (m-0.22)/0.42` (in from 22 %, full at 64 %). Outgoing page frozen at `outgoingMorph` + `activityFade` pause of `springTimeConstantMs`, then OutCubic |
| **boring.notch** (11.5k★, Swift) | AppKit | open spring `response 0.42, damping 0.8`; close `0.45, damping 1.0`; open size 640×190 | `matchedGeometryEffect` for album art; hover delay default 0.3 s (configurable 0–1 s) |
| **Caelestia `shell`** | Quickshell | `TabBar` with Material icon + label + sliding indicator, `Anim.DefaultEffects` | Per-tab state preserved by the tab bar; indicator is a state layer, not a floating pill |
| **DMS `CcPager`** | Quickshell | Swipe pager: `motion.value`, drag samples, gutter, wheel axis, no snap mid-drag | Pages owned by the pager; neighbour slides in from past the gutter |
| **dots-hyprland** | Quickshell | `SecondaryTabBar`: indicator spans *from min to max index* during a transition (`AnimatedTabIndexPair`) | Content swaps under the stretched indicator |
| **Apple HIG (Live Activities)** | — | Compact ↔ minimal ↔ expanded; tap opens the app, touch-and-hold expands; up to three minimal activities, detached ones circular/oval | Relative placement preserved across expansion; activity ends when the task ends |

**Pattern.** Every implementation that feels good animates the *shell* with one
curve and gives *content* its own, offset timing. None of them rely on a clip
aperture to reveal already-laid-out content.

---

## 2. Why notchD's morph feels bad

Measured, not guessed. Pill 60×26 → hub 980×470 is **Δw 920, Δh 444** (16.3× wide,
18.1× tall). `k=900, c=60` is critically damped (ζ = 1.00, ω = 30 rad/s).

| Quantity | Value |
|---|---|
| Peak edge speed, width | **170 px per 60 Hz frame** (~10 200 px/s) |
| Peak edge speed, height | 82 px per frame |
| 90 % of travel | 130 ms |
| Settled | 253 ms |
| Overshoot | 0 % (ζ = 1) |
| Content opacity at 130 ms | ~0.9 (derived from height) |
| Pill fade-out | 140 ms, **linear** |

For reference, a 300 ms OutQuint over the same 920 px peaks at 96 px/frame; a
400 ms OutQuint peaks at 72 px/frame. Above roughly 70 px/frame an edge reads as
a jump cut rather than growth.

### 2.1 Ranked causes

1. **Nothing exits.** `NotchD.qml:210-218` fades the idle pill out over 140 ms
   linear; the hub fades in on `hubReveal` (`NotchD.qml:334`). For ~140 ms both
   are painted on the same pixels.
2. **`hubReveal` is a height ratio, not a choreography.** `NotchD.qml:137`:
   `(surfaceH - osdH) / (revealTargetH - osdH)`. It is bound directly to the
   spring's height, so content is 90 % opaque at 130 ms and the shell still has
   120 ms of travel left. Content lands before the shape does.
3. **Opacity is applied per child, not to a group.** In Qt Quick a parent's
   `opacity` multiplies into every child, so text, icons, artwork and gauges
   blend with the cards underneath them. Mid-fade the hub looks washed out and
   hairlines shimmer. Needs `layer.enabled` during the fade (980×470×4 ≈ 1.8 MB,
   transient) or a single faded wrapper.
4. **The page is laid out at final size from frame one.** `HubSurface` is
   `width: root.pageW; height: root.pageH` (`NotchD.qml:326-335`) inside
   `surfaceContent { clip: true }` (`NotchD.qml:205-207`). The only motion is the
   aperture; no content translates, scales, or resolves. This is the "window
   wipe" — the single strongest reason it does not read as a morph.
5. **Tab switches are a second morph.** `pageW`/`pageH` differ per tab
   (`NotchD.qml:98-99`): Dashboard 980×470, Media 820×430, Performance 860×490,
   Calendar 600×(content+84), Tray 680×300. Combined with
   `Loader.active` flipping instantly (`HubSurface.qml:229-230`), every tab
   change is *content teleport + 253 ms spring resize*.
6. **The clock teleports.** It sits centred in the pill and top-right in
   `HubHeader`; there is no shared element, so it disappears and reappears
   rather than travelling.
7. **Two unrelated clocks.** `Motion.qml` tokens (140 / 260 / 300 / 420 / 820 ms)
   and the spring have no common time base. The header indicator runs 180 ms
   OutCubic (`HubHeader.qml:23-28`), fades run 140 ms linear, the shell runs
   253 ms of spring. Nothing is in phase.
8. **`Ctrl+Tab` bypasses the indicator animation.** `IslandState.qml:41-43`
   calls `selectTab(tab)` with no `animate`, so `animateTabChange` is false and
   the indicator snaps while the content jumps.
9. **Input-region churn.** `shell.qml` rebuilds a `Region` from spring values
   every frame. On NVIDIA/niri this is a per-frame mask commit for a 16× area
   change; hover can flicker at the edge of the growing surface.

### 2.2 What upstream dux does differently

`vendor/dux/VectorSpringMotion.qml` is upstream dux, but `DIslandSurface.qml`
drives it at **600/49** and, crucially, derives content opacity from
**cross-axis distance travelled**, not from height:

```qml
fadeCompact(m)  { return 1 - clamp(m / 0.34) }        // compact gone by 34 %
fadeExpanded(m) { return clamp((m - 0.22) / 0.42) }   // expanded in 22 % → 64 %
```

and freezes the outgoing page at its own progress value before crossfading, so
two pages are never both fully visible. notchD uses the same spring class with
harder numbers and a linear height ratio, which is why the same engine produces
a worse result.

---

## 3. Motion spec

Two rules: **one travel budget**, **content never arrives before the shape**.
Numbers below are for a 60 Hz panel.

### 3.1 Open (pill → hub), ~360 ms total

| t | Element | Property | Duration / spring | Easing |
|---|---|---|---|---|
| 0 | Pill content | `opacity 1→0` | 90 ms | OutQuad |
| 0 | Shell | `w 60→420`, `h 26→44` | 140 ms | OutCubic |
| 120 | Shell | `w 420→980`, `h 44→470` | spring **k≈220, c≈24** (ζ 0.81, ~1 % overshoot, ~280 ms) | — |
| 130 | Hub content | `opacity 0→1`, `scale .985→1`, `y −6→0` | 200 ms | OutCubic |
| 0 | Radius | derive from height, clamp `h/2` | — | — |

Staging matters: the second leg travels 560 px instead of 920 px, so peak edge
speed drops from 170 to ~62 px/frame. The small first leg also gives the eye a
"something is happening" beat before the big surface arrives.

### 3.2 Close (hub → pill), ~260 ms

Content out in 90 ms, shell springs back starting at 60 ms. Collapse should be
faster than expansion; iOS does the same.

### 3.3 Tab change: **no shell morph**

Freeze the frame for the three primary tabs at one size. Crossfade:

| t | Element | Property | Duration | Easing |
|---|---|---|---|---|
| 0 | Outgoing page | `opacity 1→0` | 90 ms | OutQuad |
| 40 | Incoming page | `opacity 0→1`, `y +4→0` | 160 ms | OutCubic |
| 0 | Header indicator | `x` | 180 ms (keep) | OutCubic |

If a secondary page genuinely needs a different frame (Calendar, Tray), animate
*it* on entry, not the window.

### 3.4 Reduced motion

`Motion.reduceMotion` already snaps the spring (`VectorSpringMotion.settle()`).
Extend it: shell duration 0, crossfades become opacity-only at 100 ms, no scale
or translate.

### 3.5 Spring candidates

Measured over Δw 920 / Δh 444:

| k / c | ζ | 90 % | settled | peak px/frame | overshoot |
|---|---|---|---|---|---|
| 900 / 60 (today) | 1.00 | 130 ms | 253 ms | **170** | 0 % |
| 600 / 49 (dux) | 1.00 | 159 ms | 309 ms | 139 | 0 % |
| 420 / 34 | 0.83 | 151 ms | 217 ms | 131 | 0.8 % |
| 320 / 30 | 0.84 | 175 ms | 254 ms | 113 | 0.7 % |
| 220 / 24 | 0.81 | 203 ms | 281 ms | 96 | 1.2 % |
| 144 / 22 | 0.92 | 291 ms | 489 ms | 72 | 0.1 % |

With staging, **220/24** is the sweet spot: 62 px/frame on the long leg, ~1 %
overshoot for life, no bounce that fights the screen edge.

---

## 4. QOL worth borrowing

Filtered to what notchD does not already have (see `DESIGN-STATUS.md` for the
current inventory).

### Tier 1 — do these

| Feature | Precedent | Why it fits notchD |
|---|---|---|
| **Hover-peek + click-to-commit**, 150 ms open / 150 ms close, fullscreen suppression | dux `hoverOpenDelay 150`; boring.notch 0.3 s default; Notchy's click-only mode | A peek expands to the *intermediate* capsule, not the hub — it reuses the staging above and makes the big morph rare |
| **Wheel on the pill**: volume, brightness, seek, Shift+wheel tab cycle | Caelestia `bar.scrollActions`; boring.notch gestures | The most common adjustments never open a surface at all |
| **Transient live-activity stack with TTL** (timer, download, charge, call) | DynamicLake; OnePlus Live Alerts; `ARTIFACTS.md` already defines the model | `ARTIFACTS.md` specifies the presentations but there is no TTL/stack runtime yet |
| **Direct tab keys** `Ctrl+1…5` plus animated `Ctrl+Tab` | NotchNook shortcuts; Caelestia `vimKeybinds` | `stepTab` exists; direct jumps and indicator animation do not |
| **Per-output pill / follow active display** | boring.notch 2.8 active-display; NotchNook | `DESIGN-STATUS.md` lists "surfaces still bound to the first Quickshell screen" as a real gap |
| **Unified OSD through the pill** (volume, brightness, mic, kb layout) | MediaMate; Caelestia `osd` | `osdW 196 × osdH 32` already exists; binding compositor keys removes duplicate overlays |
| **Notification mirroring with per-app allowlist** | boring.notch 2.8 filtering; dynamicSpot | Currently in-memory history only, no mirroring, no per-app mute |

### Tier 2 — later

Per-app volume mixer, calendar join buttons, clipboard pins/snippets, battery
wattage/health, weather tile, agent-session monitor, window switcher in the runner.

### Skip

File conversion, teleprompter, lock-screen widgets, plugin marketplace, full
shell replacement, browser download mirroring. All duplicate dedicated tools or
exceed the "notch-anchored" scope.

---

## 5. Tabs: horizontal or vertical?

**Vertical wins on capacity, and that part of the instinct is right.** The hub is
980×470. Nine destinations stack in 9×36 = 324 px of height with room for group
headers and a footer; the same nine horizontally need ~940 px and leave nothing
for the clock. A rail is the only orientation that can show all of them at once.

**But capacity is not the binding constraint — hierarchy is.** notchD has 9
destinations in two ranks:

- primary: Dashboard, Media, Performance (`IslandState.qml:27`)
- drill-downs behind dashboard tiles with a Back arrow
  (`HubSurface.qml:14, 250-256`): Calendar, Tray, Appearance, Activity, Clipboard, Limits

and `IslandState.qml:224-225` force-resets any drill-down to Dashboard when the
hub reopens. That is the real defect: no direct access, no way to jump sideways
between secondary pages, and a Back button in a surface that has no history.

A rail fixes all three at once by flattening the 9 into peers. That is a
different product: a control-centre window rather than a three-tab HUD. Whether
that is good depends on what the hub is for, so here are the numbers.

### 5.1 Scored for this hub

| Pattern | Discoverability | Space cost | Scalability | Keyboard | Notch fit | Total /25 |
|---|---:|---:|---:|---:|---:|---:|
| Horizontal segmented, 3 (today) | 5 | 5 | 2 | 5 | 5 | **22** |
| Horizontal segmented, 5 | 5 | 5 | 3 | 5 | 5 | **23** |
| **Vertical rail, labeled 136 px** | 5 | 3 | 5 | 5 | 3 | **21** |
| Vertical rail, icons 64 px | 3 | 4 | 5 | 4 | 4 | **20** |
| Horizontal tab strip, full width | 5 | 4 | 3 | 5 | 2 | 19 |

### 5.2 What a rail buys beyond capacity

- **No per-tab window resize.** `pageW`/`pageH` become one frame for all 9 pages,
  which deletes the second spring morph on every tab change (cause #5 in §2.1).
- **No Back dead-end** and no reset-to-Dashboard hack; any page is one click away.
- **A cheaper tab morph.** The rail is chrome that stays put; only the content
  pane crossfades (90 ms out / 160 ms in), so switching pages stops being a
  geometry event at all.
- **Keyboard fits the shape.** `Ctrl+1…9`, Up/Down, `j/k` all map naturally.

### 5.3 What it costs

| Rail width | Content pane | Dashboard columns (30 / 35 / 35) |
|---|---|---|
| 64 px (icons) | 868 px | 251 / 293 / 293 — unchanged layout |
| 136 px (labeled) | 796 px | 229 / 267 / 267 — still ≥ the 760 px `wide` threshold, but ~16 % tighter |
| 148 px (labeled) | 784 px | 226 / 264 / 264 |

Page margins are 16 px and the rail gap 16 px (`HubSurface.qml:18`), so a 136 px
rail leaves 796 px: above the dashboard's `wide >= 760` breakpoint
(`HubSurface.qml:31`), so **no layout rework is needed** — the three columns just
get tighter. Below ~120 px of rail the `wide` breakpoint fails and Dashboard
collapses to one column, which is worse than the tabs it replaced.

Height: 9 rows × 36 px + 2 group headers × 24 px + 16 px padding = 388 px of 470,
leaving ~80 px for a footer (session, settings, close).

### 5.4 Spec, if you take it

- **Width 136 px**, rows 36 px, radius 10 px, 12 px labels DemiBold, 18 px icons,
  selected row = accent container + accent ink (reuse `ActionButton` tokens).
- **Two groups**, not nine peers: `Overview · Media · Performance` then a hairline
  and `Activity · Calendar · Notifications/Tray · Clipboard · Appearance · Limits`.
  Grouping keeps the primary three legible as primary without a second control.
- **Header becomes** title + clock only; the segmented control and its indicator
  go away, freeing the 352 px the control occupied.
- **Indicator** slides vertically, 180 ms OutCubic, same token as today.
- **Motion:** the rail fades with the shell (no separate animation, `hubReveal`
  gated to start at 45 %), so it reads as part of the surface, not as content
  flying in. The pane crossfades on tab change as in §3.3.
- **Keyboard:** `Ctrl+1…9` direct, Up/Down within the rail, `Home/End` to ends,
  focus ring per `DESIGN-STATUS.md` rules.

### 5.5 Recommendation

- **If the hub is a glanceable HUD** (dashboard-first, media as a peek): keep the
  horizontal control, cap it at 5, and fix the `/ 3` hardcode and `Ctrl+Tab`
  animation. A rail buys capacity you do not need for 3 peers.
- **If the hub is becoming the control centre** (9 real destinations, used
  daily): take the **labeled 136 px rail**. It is the only layout that makes all
  9 reachable in one click, and it removes the per-tab resize, the Back button
  and the reopen reset — three separate defects for one structural change.
- **Do not** take an icon-only rail. Nine unlabeled icons in a transient surface
  is a memory test; labels are the whole reason vertical wins here.

My read: the drift is already toward control centre (nine pages, clipboard,
calendar, limits, appearance), so the rail is the honest structure — but it is a
product decision, not a polish task, and it should land after the P0 motion fixes
so the crossfade choreography it depends on already exists.

## 6. Implementation order

**P0 — feel (small diffs, no new features)**

1. Freeze the frame for the three primary tabs; drop the per-tab `pageW`/`pageH`
   (`NotchD.qml:98-99`). Kills the second morph on every tab switch.
2. Add an outgoing-page state + crossfade in `HubSurface` (90 ms out, 160 ms in
   at 40 ms offset) instead of `Loader.active` teleporting.
3. Replace `opacity: hubReveal` with a content transform (opacity + scale .985 +
   y −6) and isolate the fade with `layer.enabled` while `hubReveal` is between
   0 and 1.
4. Retune `shapeMotion` to 220/24 and stage the width expansion.
5. Fix `Ctrl+Tab` to animate the indicator.
6. Reduced motion: snap shell, opacity-only crossfade.

**P1 — reach**

Hover-peek (150/150), wheel on the pill, `Ctrl+1…5`, shared-element clock and
album art, and rebuild the input `Region` only on settle or on an 8 px threshold.

**P2 — breadth**

Per-output pill, live-activity TTL stack, notification mirroring + allowlist,
auto-DND/stealth on screen share, unified OSD, and the 136 px rail if §5.5 is
accepted.

**Verification.** `tests/notchd-polish/run.sh` covers behaviour offscreen, but the
software backend does not render `ClippingRectangle` or measure frame pacing.
Motion needs a real session: log `QSG_RENDER_TIMING=1` for frame times, and check
the mask with `wev`/niri's surface debug while the shell moves.

---

## 7. Sources

Source-level: `enhaoswen/Tide-island`, `andreumassanet/impasto`, `duxlabs-dev/dux-shell`
(`Modules/DIsland/*`, `Modules/SurfaceWidgets/VectorSpringMotion.qml`),
`TheBoredTeam/boring.notch`, `caelestia-dots/shell`, `AvengeMedia/DankMaterialShell`,
`end-4/dots-hyprland`.

Docs: [Qt Quick Scene Graph Default Renderer](https://doc.qt.io/qt-6/qtquick-visualcanvas-scenegraph-renderer.html),
[Qt Quick Performance](https://doc.qt.io/qt-6/qtquick-performance.html),
[Item Layers](https://doc.qt.io/qt-6/qml-qtquick-item.html#layer-prop),
[Behavior](https://doc.qt.io/qt-6/qml-qtquick-behavior.html),
[FrameAnimation](https://doc.qt.io/qt-6/qml-qtquick-frameanimation.html),
[Apple HIG Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities),
[Apple HIG Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars),
[Apple HIG Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls),
[M3 Navigation rail](https://m3.material.io/components/navigation-rail/guidelines),
[NN/g Tabs, Used Right](https://www.nngroup.com/articles/tabs-used-right/),
[beUI Dynamic Island](https://beui.dev/guides/dynamic-island-react).
