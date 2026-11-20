# Runner and appearance

`RunnerSurface` accepts `state` (optional), `initialQuery`, and `refresh()`; it emits `actionRequested(action, value)` and `closeRequested()`. The parent owns action execution and dismissal. Actions are `wallpaper`, `theme` (light/dark/auto), `scheme` (wallpaper or #RRGGBB), `variant` (matugen scheme-*), `transparency` (opaque/translucent or a decimal from 0.70 to 1), `lock`, and `sleep`. App results execute their DesktopEntry directly. Focus the surface to focus its search field. Escape returns from a nested command list, then closes the runner.

`wp scheme` reads the palette source; `wp scheme wallpaper` or `wp scheme '#aabbcc'` sets it. `wp variant` reads the configured variant (`auto` if unset); `wp variant scheme-vibrant` sets it; `wp variant auto` restores the wallpaper-aware default. With no explicit variant, wallpapers under `walls/bw` use monochrome and others use tonal spot. These settings persist across wallpaper and theme changes. Appearance commands query the current wallpaper when needed, but do not change it.

Run `python3 -m unittest discover -s tests/runner -v` for isolated CLI tests. They use a temporary home and stub desktop commands; no real wallpaper or palette is changed.
