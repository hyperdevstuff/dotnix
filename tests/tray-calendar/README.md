# Tray and calendar checks

Run the fixture with Python's `dbus-next` package available:

```sh
nix-shell -p 'python3.withPackages (ps: [ ps.dbus-next ])' --run 'bash tests/tray-calendar/run.sh'
```

Alternatively set `PYTHON` to an interpreter containing `dbus-next`.

The test uses a private session bus, an offscreen copied shell and a real test
StatusNotifierItem/DBusMenu server. It checks registration, icon/status changes,
menu loading/action dispatch, primary/secondary activation, scrolling,
passive-item filtering and removal. It also exercises calendar month/day
navigation, leap-year clamping, locale week starts and Back navigation. No real
app actions are invoked.

Native Wayland popup positioning/focus and physical keyboard navigation need
separate live verification; offscreen checks cannot validate compositor grabs.
