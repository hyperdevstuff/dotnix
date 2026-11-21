# Shell status and design review — 21 November 2026

This is a source audit of the eight requested features, plus a full polish
review limited to the shared dashboard controls, header, tray menu and clipboard.
The framework is Qt Quick / Quickshell; changes use the existing matugen palette,
Material Symbols and QML component system. This is not a claim that the whole
shell conforms to every Material 3 Expressive specification.

## Feature status

| Addition | Status | Present | Remaining |
|---|---|---|---|
| Privacy indicators | Partial | Active PipeWire microphone/camera links, app names when available, niri cast state, header badges and Activity details. | No reliable receiving-app attribution for niri casts; direct V4L2 access is outside detection. Badges are in the expanded header, not the idle pill. |
| Keep-awake | Implemented | Real Wayland idle inhibition; 15/30/60 minutes; remaining time and Stop in Activity; expiry and lock/hide cleanup. | Remaining time is not displayed in the collapsed pill. |
| Agent usage | Missing adapters | Limits reads and validates an optional local `usage.json`, including stale/error states. | No Codex, Claude or OpenCode collector is installed. Provider quotas must come from supported data, not inferred token totals. |
| Rich runner | Partial | Application launching, appearance/session actions, nested choices, prefix/substring ranking and basic subsequence fuzzy matching. | Calculator, unit conversions, emoji search, favorites, window search and file search. |
| Application audio mixer | External fallback | Device volume, mic, default-device selection and a Mixer button opening pavucontrol. | Native per-application stream volume and output routing. |
| Persistent notifications | Missing persistence | Native actionable notifications, bounded in-memory history, date grouping, expiry and global DND. | History across restarts, app grouping/filtering and per-app mute. |
| Capture | Partial | Mod+Shift+S area selection, Swappy annotation/crop/blur, explicit Copy and Save, private temporary-file cleanup. | Delay controls, recording backend, stop action and elapsed-time activity. |
| Monitor awareness | Partial infrastructure | Compositor helpers can identify focused output; panel geometry is bounded to its assigned output. | Shell surfaces are still bound to the first Quickshell screen. Focused-output placement and richer external-display controls are missing. |

Evidence: `services/Privacy.qml`, `services/KeepAwake.qml`,
`components/ActivitySurface.qml`, `components/HubHeader.qml`, `NotchD.qml`,
`components/UsageSurface.qml`, `components/RunnerSurface.qml`,
`flyouts/AudioFlyout.qml`, `services/Notifications.qml`,
`services/NotificationStore.qml`, `components/NotificationCenter.qml`,
`../../bin/notchd-screenshot`, `services/Compositor.qml`
and `shell.qml`.

## Design direction

Use Material's semantic surfaces, readable type hierarchy, grouped controls and
purposeful size/shape differences in the expanded control center. Expressiveness
should make important actions easier to find. It should not turn every utility
into an oversized pill. Google's research explicitly warns that visual novelty
cannot compensate for broken familiar interactions.
[Google Design research](https://design.google/library/expressive-material-design-google-research),
[official M3 Expressive guidelines](https://m3.material.io/blog/building-with-m3-expressive).

For interaction feedback, use one content-tinted layer, with 8% hover and 12%
focus/press opacity from Material Web's published state tokens. Keep selection
independent from focus. Focus is indicated by tonal emphasis, without dash markers. This is a notchD
desktop adaptation; Material Web itself provides keyboard-visible focus rings.
Removing an outline must not remove the visible keyboard position.
[Material state layers](https://m3.material.io/foundations/interaction/states/state-layers),
[published tokens](https://github.com/material-components/material-web/blob/main/tokens/versions/v0_192/_md-sys-state.scss),
[focus-ring behavior](https://github.com/material-components/material-web/blob/main/docs/components/focus-ring.md).

Use Apple's guidance for activity behavior: prioritize essential ongoing
information, preserve relative placement through expansion, keep actions direct,
use stable compact geometry, and end activities when their tasks end. The
control center is a separate destination; an activity's compact presentation
should lead straight to its related details. Apple's actual Dynamic Island uses
an opaque black background; retaining matugen here is a platform adaptation.
[Apple Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities).

The next island design task is a common presentation/priority policy for media,
privacy, keep-awake and future recording. Today these features have separate
presentations. Adding every status beside the clock would recreate the oversized
bar problem. This audit does not mark that policy as implemented.

## Changes in this pass

| Severity | Location | Before | After | Why |
|---|---|---|---|---|
| Medium | `components/ActionButton.qml:34`, `QuickSetting.qml:35`, `HubHeader.qml:53`, `TrayButton.qml:53`, `TrayMenuItem.qml:16`, `StateLayer.qml:1`, `Theme.qml:73` | Thin focus borders; filled/tonal buttons could suppress hover/press feedback. | Shared content-tinted state layer with tonal focus emphasis; filled and tonal controls retain feedback. | A consistent focus position without outlining every container, and feedback on all button styles. |
| Medium | `components/ClipboardSurface.qml:138` and `:214` | Outlined selected row; outlined search; search field and list selection looked similar. | Filled tonal selection and filled search with a search symbol; focus uses tonal emphasis without dash markers. | Separate active preview selection from text-entry focus. |
| Medium | `components/ClipboardSurface.qml:26` | Filtering after scrolling could leave the first result offscreen. | Reset the list position when filtering. | Keyboard selection must stay visible. |
| Medium | `components/QuickSetting.qml:26`, `NotchSlider.qml:37` | Detail target 30px wide; mute had no independent keyboard target. | 40px detail target; keyboard and accessible activation for details, primary controls and mute. | Separate toggle/navigation targets and reachable audio controls. |
| Low | `components/NotchSlider.qml:80` | Focus outlined the narrow handle. | Tonal track backdrop and a larger solid handle on focus. | Focus is readable at the scale of the control. |

## Coverage

| Category | Evidence inspected | Result |
|---|---|---|
| Typography | Shared label tokens, control labels, clipboard search/rows, light/dark fixture renders. | Existing type scale retained; a shell-wide emphasized type scale remains future work. |
| Surfaces | Resting, hover, pressed, focus, selection and disabled branches of changed controls; clipboard loading/empty/error paths. | Shared state-layer treatment; clipboard selection and search differentiated. |
| Animations | Existing button press/quick-setting radius transitions; new focus and search-selection paths. | New keyboard feedback is immediate. No new focus animation, blur effect or continuous timer. Existing spring/morph timing was not retuned. |
| Icons | Material Symbol search icon and existing rounded-symbol control paths. | Existing vector family retained; app-provided tray icons remain app assets. |
| Performance | State bindings, timers and process paths touched by the change. | No new background process, polling timer or image asset. Existing clipboard helper runs on demand. No frame-time benchmark was run. |

## Considered but rejected

| Candidate | Reason |
|---|---|
| Animate the clipboard highlight through each keyboard step. | Frequent navigation needs immediate feedback; motion adds delay and makes selection ambiguous. |
| Generate raster artwork for the controls or empty states. | These are small, theme-reactive native UI surfaces. Existing scalable Material Symbols fit better and do not introduce bitmap assets. |
| Remove every focus cue along with borders. | Keyboard users still need a clear current target, including on filled and selected controls. |
| Replace all shell geometry with mobile Material sizes in this pass. | A desktop island needs an explicit density policy and output-size testing; a wholesale resize would exceed this targeted polish pass. |

## Verification

- `bash tests/clipboard/run.sh`: synthetic key events for navigation, scrolling,
  filtering, copying, deletion/refresh, tonal-button activation, disabled
  behavior, slider adjustment and independent mute activation; pointer events
  verify button activation and separate toggle/detail targets. The backend is
  a private fixture and never accesses the real session clipboard.
- `bash tests/notchd-polish/run.sh`: full copied-app regression harness, including
  constrained geometry, tab/detail transitions, media seeking and metrics.
- `PYTHON=<dbus-next Python> bash tests/tray-menu/run.sh`: menu/submenu geometry,
  state handling and a private fixture action.
- Native clipboard fixture checked in light and dark palettes; no global theme
  command or wallpaper application is used for this check.
- Native dashboard rendered after loading the updated shell. User-selected
  panel opacity was preserved; translucent panels can reduce readability over
  high-contrast window content.
- `bash tests/activities/run.sh`: private privacy/keep-awake fixtures passed.
- Nix evaluation of the Home Manager Quickshell source passed, including the
  new shared component.
- Changed QML parsed with `qmlformat`; `git diff --check` passed.

Not verified: every wallpaper-generated color palette, screen-reader output,
physical multi-monitor placement, frame-time performance and a complete
shell-wide typography/hit-target audit. The feature gaps above remain open.

Verdict: the targeted focus/clipboard changes pass the exercised checks. The
whole-shell design remains **Needs changes**, specifically for compact activity
presentation, type/density consistency and the unimplemented feature gaps.
