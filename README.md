# Cadence

A native macOS music player. One playback core drives five surfaces — a
lock-screen widget, a lock-screen full-screen player, a full-screen desktop
player, a launcher widget and a free-floating desktop player — and each one has
its own layout you compose by hand from the same set of elements.

> **Status: it builds, runs, and has been driven against real playback.**
> That first hand pass found about thirty defects — a scrubber with no drag
> handler, three of eight resize handles missing, a progress ring with no track
> circle, and four settings that were stored, read and inert — and they are
> fixed. What remains unverified is listed in `MANUAL-TESTS.md`: a live stream's
> NaN duration, Spotify Canvas, open-at-login, and a full day of uptime.

## The idea

Most now-playing widgets give you one fixed arrangement. Cadence gives you a
**snap grid** per surface and 24 placeable elements — artwork, title, artist,
album, transport, shuffle, repeat, seek, progress bar, elapsed and remaining
time, lyrics, output device, AirPlay, volume, visualiser, app icon, explicit
badge, wall clock, timer — and lets you put them where you want, independently
on every surface.

- **Vinyl or album cover**, with or without the stylus arm, with the progress
  bar optionally running around the record.
- **Resize the desktop player with the mouse.** Elements drop out in a priority
  order you set once, rather than squashing.
- **Hover reveals more.** Mark an element hover-only; the widget grows only if
  what you revealed doesn't fit — an overlaid play button costs no space, a
  progress bar needs a row.
- **Arrange it in a live preview** that is the real player, not a diagram, with
  undo and keyboard nudging.

## Requirements

macOS 26+, Apple Silicon.

## Sources

Now Playing (every app), Apple Music, Spotify, YouTube Music, Amazon Music.

## Building

```bash
xcodebuild -project Cadence.xcodeproj -scheme Cadence -configuration Release \
  -destination 'platform=macOS,arch=arm64' build
```

## Checking it

| | |
|---|---|
| `tests/run_gridsolver_tests.sh` | 143 assertions on the layout engine, compiling the real source |
| `tests/run_runtime_stress.sh` | **live** — hostile settings and malformed layouts against the running app |
| `scripts/audit-reachability.sh` | finds settings, notifications and elements no user can reach |
| `scripts/audit-main-actor.sh` | a `@Published` written off the main actor — the shape that deadlocked the app |
| `scripts/audit-inert-settings.sh` | a setting named after something on screen that its renderer never reads |
| `scripts/check-debug-hooks.sh` | asserts the debug hooks are compiled out of Release |
| `scripts/measure.sh` | CPU and RSS sampler |

Every guard in those was proved non-vacuous by breaking the thing it checks and
watching it go red. The results are recorded in each file.

Idle cost, Release, after a 13-minute settle: **0.01% CPU, median 0.00, 12.5 MB**.

## Licence

GPL-3.0. Cadence derives from Anchor, itself derived from Atoll and
boring.notch; the audio spectrum processor derives from rtaudio and FineTune.
See `LICENSE` and `NOTICE` — the copyright headers on ported files are preserved
as the GPL requires.

Not affiliated with or endorsed by the Atoll or boring.notch projects.
