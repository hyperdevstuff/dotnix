# Two-page lock presentation checks

Run from the repository root:

```sh
bash tests/lockscreen/run.sh
```

This launches a copied visual component in an offscreen ordinary Qt window,
with a synthetic controller. It does not acquire a Wayland session lock,
invoke PAM, use a real password or modify session preferences.

The fixture exercises first-key consumption, password masking, typing, Escape
to clear/back, explicit Tab navigation, submit-button and input-Enter activation,
busy/error focus behavior, stable error geometry, 12-hour formatting, the dark
lock palette under a light desktop, reduced motion and constrained form geometry
down to 320×360 at 120% text size.

Native ordinary-overlay previews were also inspected with synthetic media,
notifications and authentication states. Real authentication, display hotplug
while locked and suspend/resume were not exercised in this design pass.
The controller functions and PAM block were compared with the formatted baseline
and are unchanged.

| Before | After | Why |
|---|---|---|
| Near-centered time with no date | Clock/date group centered at 25% of screen height, without an instruction label | Halfway between the top edge and screen center |
| 58px avatar, 46px field, 30px submit target and small labels | 96px avatar, 64px field, 48px submit target and larger type | Appropriate scale for a full-screen sign-in surface |
| White glass chrome independent of matugen | Dark semantic matugen surfaces and accent roles | A coherent Material palette without a white lock screen in light mode |
| Fixed centered form | Bounded, scrollable form with password visibility adjustment | Keeps sign-in reachable on short or small outputs |

The existing two-page sequence is retained. The design research covered
[illogical-impulse's Windows-style Waffle lock](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/waffle/lock/WaffleLock.qml),
[Caelestia's lock layout](https://github.com/caelestia-dots/shell/blob/main/modules/lock/Content.qml)
and [Dux's authentication widget](https://github.com/duxlabs-dev/dux-shell/blob/master/quickshell/Modules/Lock/Widgets/LockAuthWidget.qml).
These are design references; no upstream lock or PAM implementation is vendored
by this change.
