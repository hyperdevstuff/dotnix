# Vendored components

All files below are MIT-licensed and copied verbatim from upstream, with a
3-line provenance header prepended. Upstream drift is ignored until we choose
to re-sync; pin by the commit SHA recorded here.

| Local file | Upstream repo | Upstream path | Commit SHA |
|---|---|---|---|
| `dux/GothCorner.qml` | duxlabs-dev/dux-shell | `quickshell/Modules/SurfaceWidgets/GothCorner.qml` | 5235d5ebc4309aae64247f0f34201d0fafb93d0b |
| `dux/VectorSpringMotion.qml` | duxlabs-dev/dux-shell | `quickshell/Modules/SurfaceWidgets/VectorSpringMotion.qml` | 5235d5ebc4309aae64247f0f34201d0fafb93d0b |
| `ukishima/Motion.qml` | amanhex/Ukishima | `Singletons/Motion.qml` | 5a96a30c327b9e5c0f74e05e846d373e61ce6c4b |
| `ukishima/WmGeneric.qml` | amanhex/Ukishima | `Singletons/WmGeneric.qml` | 5a96a30c327b9e5c0f74e05e846d373e61ce6c4b |

Notes:
- `dux/IslandController.qml` and `dux/MorphSurface.qml` were NOT vendored: they
  depend on `qs.Common`, `Flags`, `Style`, `Theme.hostSurface`, etc. Reimplement
  the ~50 lines we need instead.
- `ukishima/Wm.qml` was NOT vendored: niri-only, reimplemented as
  `services/Compositor.qml`.
- Notch geometry + ears (section 3 of notchd-research.md) are reimplemented in
  `NotchD.qml`, not copied. Tide Island Extended is GPL-3.0.

Modifications made to vendored files: none (only the provenance header).

The Dux vector spring now drives notchD's width, height and corner radii as one
motion, retaining velocity during reversals. Hub content keeps its final layout
and follows the surface's reveal progress. Caelestia's drawer wrappers informed
this separation between stable content and animated reveal; reference inspected:
`caelestia-dots/shell` at `e72df8eb687246aa6c6ec6daa631073b374e5215`,
`modules/drawers/Panels.qml` and `modules/dashboard/Wrapper.qml`.
No Caelestia source was vendored in this adaptation.

Dux artwork and button adaptations have their own attribution in
`../components/ATTRIBUTION.md`.
