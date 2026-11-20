# Dashboard, media and performance checks

Run `bash tests/notchd-polish/run.sh` for an offscreen Quickshell fixture.
It copies the shell into a temporary directory, replaces only the MPRIS
provider with test players, and disconnects the session bus. It exercises
source disappearance, seek capability checks and bounds, unknown duration,
CPU/network deltas and reset counters, tab removal, detail Back navigation,
and page instantiation at 1000×560 and 500×240. No playback commands reach a
real player. The performance page may read local system metrics.

Run `python3 tests/notchd-polish/test_metrics.py` for helper checks. Fixtures
verify that a suspended NVIDIA GPU is not queried, a driver timeout returns
unavailable, and successful readings are parsed.

The waveform, gauges and sparklines use Canvas. Artwork and battery clipping
need a native GPU-backed scene for visual validation; the software offscreen
backend does not reliably render Quickshell's ClippingRectangle.
