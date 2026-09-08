#!/bin/bash
# A setting named after a thing on screen must be read by the code that draws
# that thing.
#
# This is NOT audit-reachability.sh, which asks only "does anything read this
# key" and passes as soon as one file does. Two settings passed that check for
# months while being visibly dead, and they failed in the same shape:
#
#   sliderColor         named for the progress slider. Its only reader was
#                       RealTimeWaveformScrubberView — a view on screen only
#                       when the real-time waveform is enabled AND a visualiser
#                       is placed. PlayerSurfaceView, which draws the actual
#                       progress bar, hardcoded its colour.
#   coloredSpectrogram  named for the visualiser. It gated album-colour
#                       EXTRACTION inside MusicManager instead, so the one
#                       control named after the visualiser was the one thing it
#                       did not affect — while silently starving the card tint.
#
# "Lone consumer" was tried first as the signal and rejected: playerWidth being
# read only by PlayerWindowManager is correct, and that version flagged 29 keys
# of which 27 were fine. This asks the narrower question that actually caught
# the bugs.
# Proved non-vacuous, both directions:
#   rename `sliderColor` throughout PlayerSurfaceView
#       => "sliderColor: not read where it is drawn" FAILS
#   remove BOTH real uses of coloredSpectrogram from RealTimeAudioSpectrum
#       => "coloredSpectrogram: not read where it is drawn" FAILS
# Removing only ONE of the two coloredSpectrogram uses correctly still passes,
# and an earlier version of this script passed the control outright because the
# word match hit the doc comment describing the bug. Comments are stripped now.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 <<'PY'
import re, sys, os

# key -> (files that MUST read it, why)
REQUIRED = {
    'sliderColor': (
        ['Sources/Layout/PlayerSurfaceView.swift'],
        'names the progress slider; PlayerSurfaceView draws it'),
    'coloredSpectrogram': (
        ['Sources/Visualizer/RealTimeAudioSpectrum.swift'],
        'names the visualiser; that view draws the bars'),
    'visualizerBarCount': (
        ['Sources/Visualizer/RealTimeAudioSpectrum.swift',
         'Sources/Visualizer/MusicVisualizer.swift'],
        'names the visualiser bars'),
    'playerTintsWithAlbum': (
        ['Sources/Player/PlayerWindowManager.swift'],
        'names the player card, which that file draws'),
    'playerUsesGlass': (
        ['Sources/Player/PlayerWindowManager.swift'],
        'names the player background'),
    'playerBackgroundOpacity': (
        ['Sources/Player/PlayerWindowManager.swift'],
        'names the player background'),
    'lockFullBackground': (
        ['Sources/LockScreen/LockScreenPanelManager.swift'],
        'names the lock full-screen background'),
    'volumeControlsApp': (
        ['Sources/Layout/AudioElements.swift'],
        'names the volume element'),
}

failures = []
for key, (files, why) in REQUIRED.items():
    hit = False
    for path in files:
        if not os.path.exists(path):
            failures.append((key, f'{path} does not exist'))
            hit = True
            break
        # Comments stripped FIRST. A doc comment explaining why a key matters
        # is not a use of it, and leaving them in made the negative control
        # pass: the audit matched the very sentence describing the bug.
        # A word match, not `Defaults[.key]`: sliderColor reaches
        # PlayerSurfaceView as a PARAMETER, deliberately, because a Defaults
        # read inside a view body is never observed and the picker would look
        # dead. What matters is that the drawing code names it at all — before
        # the fix, PlayerSurfaceView did not mention it anywhere.
        body = open(path).read()
        body = re.sub(r'//[^\n]*', '', body)
        body = re.sub(r'/\*.*?\*/', '', body, flags=re.S)
        if re.search(r'\b' + key + r'\b', body):
            hit = True
            break
    if not hit:
        failures.append((key, f'not read by any of {", ".join(files)} — {why}'))

print(f"Checked {len(REQUIRED)} settings against the code that draws them")
if failures:
    print()
    for key, detail in failures:
        print(f"  {key}: {detail}")
    print()
    print(f"FAIL: {len(failures)} setting(s) not read where they are drawn.")
    sys.exit(1)
print()
print("OK — every named setting is read by the view it names")
PY
