# Tests for you to run

Your last pass ticked 68 of these and found ~30 defects. All of them are fixed;
this file is what proves it.

**Most of your old ticks are gone, deliberately.** Seven commits touched about
twenty files, including the panel's entire event path, the grid engine and every
surface's renderer. A tick against the previous build is not evidence about this
one. The only section kept ticked is the Spotify sign-in sheet, which nothing
since has touched.

Ordered so the things that would waste your time if broken come first. If
something fails, the file to look at is named.

Before starting, the scripted half should be green — it takes a minute and tells
you whether a failure below is new:

```bash
./tests/run_gridsolver_tests.sh          # 143 assertions
./scripts/audit-reachability.sh          # dead switches
./scripts/audit-main-actor.sh            # the deadlock shape
./scripts/audit-inert-settings.sh        # settings that do nothing
```

---

## 0. Smoke test — two minutes

If any of these fail, stop and tell me; the rest of the file is not worth your
time until they pass.

- [ ] The player is on screen and shows the current Spotify track.
- [ ] **Drag the progress bar.** It must scrub, and the window must NOT move.
      This was the single worst bug and it had two independent causes.
- [ ] **Grab the top edge and each of the four corners.** All eight handles
      should resize. There used to be five, and none at the top.
- [ ] **Click the artwork once.** A full-screen player opens. Click again or
      press Escape to leave.
- [ ] Open Settings → Layout. The element palette should be a **wrapping grid**
      with no sideways scrolling.

## 1. The pointer

The worst cluster, and all of it traced to the window claiming drags before
SwiftUI could.

- [ ] Drag the scrubber slowly from end to end. Does the bar follow your pointer
      *live*, and seek only when you let go?
- [ ] Tap the scrubber without dragging. Still seeks?
- [ ] Drag from **dead space** (not an element). The window should move.
- [ ] Drag from a **button** or the scrubber. The window must NOT move.
- [ ] Resize from every edge and corner: left, right, top, bottom, and all four
      corners. Does the cursor change on each?
- [ ] **Drag the bottom edge down to make the card taller.** It must actually
      grow — this was clamped and silently ignored, so twenty drags produced
      twenty identical heights.
- [ ] Drag the bottom edge up. Elements drop out in priority order.
- [ ] Shrink to minimum and grow back. Same order returning, nothing flickering.
- [ ] **Double-click dead space.** It goes behind your windows. **Double-click
      again — it must come back to the front.** That used to be a one-way trip.
- [ ] Double-click the **progress bar**. It must NOT go behind.
- [ ] Click the ✕. Does it offer *Send to back* and *Quit*? **Now move the
      pointer off the ✕ towards the menu without it vanishing** — reaching for
      it used to unmount the button that owned it.
- [ ] Move the player, quit Cadence, relaunch. Is it where you left it? AppKit
      no longer moves the window, so the position is saved by hand now.

*If a drag misbehaves:* `Sources/Player/PlayerPanel.swift`, `sendEvent`.

## 2. Hover

- [ ] Mark something hover-only. Hover the card — does it reveal cleanly?
- [ ] **Move the player to the very bottom of a display and hover.** The card
      should grow *upward*. It used to grow down, off-screen, and then get
      yanked up by the clamp — jumping under your pointer.
- [ ] Hover while resizing. Growth is suppressed; the card must not fight you.
- [ ] Turn **Grow on hover** off. The revealed element must simply have to fit.

## 3. Artwork, the record, and the ring

- [ ] **Progress ring on.** It must be a *complete faint circle* with a brighter
      arc filling it as the track plays. It used to be an arc only — a dot at
      twelve o'clock that grew into a circle, which is what "the ring expands"
      was.
- [ ] The ring must sit **inside** the artwork's square, not overflow it.
- [ ] Toggle the ring on and off. **The record must not change size** — the
      space is reserved either way.
- [ ] Vinyl: is the art round and masked to the record, not a square on a circle?
- [ ] **Tonearm on pause.** The arm should lift *promptly*, keeping pace with the
      record stopping dead. Dropping back down is deliberately slower.
- [ ] Album cover style: a plain square with the right corners.
- [ ] Drag the player between your two displays. Does the record swell or jump?
      It must not.

## 4. The layout editor

- [ ] The palette wraps and needs no horizontal scroll at any window width.
- [ ] Every element in the palette adds something that draws.
- [ ] **Drop an element in the gap between two rows.** A new row opens there.
      This was impossible before — the only way to make a row was to drop below
      everything.
- [ ] Drop onto an occupied cell. Still refused.
- [ ] Drop below the last row. Still makes a bottom row.
- [ ] **⌘-click several elements.** All highlight. Change **priority** or
      **Shown** — it applies to all of them, as one ⌘Z step.
- [ ] With several selected, press ⌫. All go, as one undo step.
- [ ] **Width and Height must NOT fan out** across a multi-selection — a span
      legal for one element overflows the grid for another further right.
- [ ] **Height stepper.** Set an element to 2+ rows. Does it occupy them and
      fill the space, rather than reserving it and drawing small?
- [ ] **Presets** menu: As shipped / Compact / Artwork only / Everything. Each
      applies, and ⌘Z takes it back.
- [ ] **Reset this surface** — and check the bottom elements come back. Reset
      used to leave the height budget shrunk, so they dropped straight out again.
- [ ] Mark something hover-only and turn the hover preview **off**. Its dashed
      box should now be **labelled with the element's name and icon**, so you can
      read the layout without toggling.
- [ ] Change one surface, then check the other four are untouched. **There are
      five now** — Desktop, Lock widget, Lock full screen, Desktop full screen,
      Launcher.

## 5. The full-screen players

Two of them now, with separate layouts.

- [ ] **Single-click the desktop player's artwork.** A full-screen view opens on
      the display the player is on.
- [ ] Escape closes it. So does clicking empty space.
- [ ] Its layout: artwork with title, artist, progress and transport beneath it
      on the **left half**; **lyrics filling the whole right half**.
- [ ] Settings → Layout → **Desktop full screen**. Rearrange it, and confirm the
      lock screen's full screen is untouched.
- [ ] The lock screen's full screen should have the same two-half shape. **Your
      stored layout was migrated once on first launch** — if it still looks like
      the old single-row arrangement, the migration did not run and I want to
      know.
- [ ] Remove lyrics from a full-screen layout. The artwork should become the
      focus rather than leaving a hole.
- [ ] **Full-screen background** — *Blurred album cover* vs *Album cover colour*.
      Both visibly different, both changing with the track. **Never tested.**

## 6. Lock screen

- [ ] Settings → Player → **Show on the lock screen**, then lock (⌃⌘Q).
- [ ] **Is the widget's content centred?** It used to sit against the leading
      edge with all the slack on one side.
- [ ] **Single-click the artwork** to expand. It was a double-click, and on a
      transparent strip *guessed* to be the artwork's width — it now hangs off
      the artwork element wherever you actually put it.
- [ ] Click it again to collapse. Escape also works.
- [ ] Unlock. Both gone? Lock and unlock four times — anything left behind?
- [ ] **Vertical offset** now reaches ±600. Push it low enough to sit **below
      the login field**, which ±240 could not do.
- [ ] Width slider still resizes and drops elements in priority order.
- [ ] **Spotify Canvas video.** Play a track with a Canvas. Does the background
      become the looping video? **Never tested** — and it was impossible before
      the sign-in sheet existed.

## 7. Settings that used to do nothing

Every one of these had a control, a key and a reader, and changed nothing you
could see.

- [ ] **Progress bar colour** — step through White / Match album art / Accent.
      Each must be visibly different, on the bar **and** on the ring. It only
      ever affected a waveform view you probably never had on screen.
- [ ] Change it while the player is open. It should update **immediately**.
- [ ] **Average vs Most vibrant** — switch while a track plays. The card tint
      must change **without waiting for the next song**. It only recomputed on
      track change, which is why they looked identical.
- [ ] **Colour the visualiser from the album** — now in Settings → Player →
      Elements *and* in the Layout inspector when the visualiser is selected.
      Toggling it must change the **bars**. It used to gate album-colour
      extraction globally instead, which silently broke the card tint too.
- [ ] **Visualiser bar count** — in the Layout inspector, with the visualiser
      selected. Changing it must redraw the bars. Nothing rebuilt them before.
- [ ] **Liquid glass background** — Settings → Player → Desktop player. The card
      becomes glass. Check it against a busy desktop and with the opacity slider.
- [ ] **Follow me between desktops** — off by default. With it off the player
      stays on one Space; on, it appears on all of them.
- [ ] **Volume slider controls the app** — on, the slider moves *Spotify's* own
      volume, not the Mac's. Off, it moves the system volume.
- [ ] **Lyrics on the desktop player.** Place the Lyrics element at 2+ columns
      wide. Words should appear. Below 3 columns it silently drew a toggle
      *button* instead, which is why lyrics only ever worked on full screen.

## 8. Playback and staying up to date

- [ ] Play, pause, skip. Title, artist, album, artwork all correct.
- [ ] **Quit Spotify, then relaunch it and play something.** Cadence should pick
      it up without a relaunch of its own — Spotify does not announce its own
      launch, so nothing noticed before.
- [ ] Leave it running for a few hours with music on and off. **Does it ever go
      stale?** The observer now re-arms itself if the notification stream ends;
      that silent death is the best candidate for what you saw.
- [ ] **Menu bar disc.** The first row is now a **two-line item with artwork** —
      title over artist — and it is **clickable**, opening the full-screen
      player. It was greyed out because it had no action at all.
- [ ] With nothing playing it reads "Nothing playing" and is properly disabled.
- [ ] **Show in the Dock** on. Settings and the player should be **two separate
      windows** in the Window menu and ⌘`.
- [ ] Play a **live stream** (a radio station). Times must read `--:--`, not
      crash. **Never tested, and this is the one that SIGTRAP'd Anchor** —
      `Int(NaN)` on a live stream's duration.

## 9. The audio elements

- [ ] **Visualiser with Real-time waveform ON.** Do the bars actually move with
      the music? They sat frozen because the tap gave up permanently if no music
      app was running when it started, and never retried.
- [ ] Start Cadence with Spotify closed, place a visualiser, *then* open Spotify.
      The bars should come alive — that retry is new.
- [ ] Resize the player with a visualiser placed. The bars should scale with the
      space, not stay a fixed 14pt strip.
- [ ] Turn Real-time waveform **off**. Bars stop, and idle CPU returns to
      baseline — the tap must be released.
- [ ] Remove the visualiser entirely while music plays. CPU back to idle.
- [ ] **Output** lists your real devices and switching works.
- [ ] **Timer**, right-click, 1 min. Counts down and stops.
- [ ] **AirPlay** — still untested, needs a device on your network.

## 10. Two displays

You have two: the built-in Retina and the external EK271 at x=-1920.

- [ ] Drag the player to the other display. Does it stay?
- [ ] Resize it there. Smooth, no jumping?
- [ ] Unplug that display. Does the player come back onto the remaining one?
- [ ] Sleep and wake.
- [ ] Change resolution or scaling with the player open.
- [ ] Lock with both attached — the widget follows the **menu-bar** screen.

## 11. Living with it

- [ ] Leave it running a full day. `scripts/measure.sh Cadence 180 "after a day"`
      and compare. **12+ minutes before believing any RSS figure.**
- [ ] An hour with a track playing, watching idle CPU. Several new observers went
      in — none of them is a poll, and this is where that claim gets tested.
- [ ] Quit and relaunch: position, size and layouts intact.
- [ ] Log out and back in.
- [ ] **Open at login.** Settings → Player → General. You now have a properly
      signed build in /Applications, so this is testable for the first time.
      **Never tested.**
- [ ] Alongside Anchor, with Anchor's equivalents off:
      ```bash
      defaults write com.arronlingham.Anchor enableLockScreenMediaWidget -bool false
      defaults write com.arronlingham.Anchor enableVinylWidget -bool false
      ```

---
## 7. Lyrics

Off by default and **not covered anywhere else** — no automated test touches
this path, and it is the one feature that goes to the network.

- [ ] Settings → Player → Lyrics → **Fetch lyrics** on. Place the **Lyrics**
      element. Does it show the words for the current track?
- [X] Do they **scroll in time**, with the current line highlighted?
- [-] **Timing offset** slider. Negative should show each line earlier. Does
      moving it visibly shift the sync?
- [ ] **Visible lines** stepper, 0 through 9. At 0 it should fill whatever
      space it has; at 3 it should show three.
- [-] **Translate lyrics** on. Does a translation appear, and does it fail
      quietly (not blank the element) when there is nothing to translate?
- [-] Turn **Fetch lyrics** off with the element still placed. It should degrade
      to something sensible rather than an empty box or a spinner forever.
- [X] Pause the music and leave it for a few minutes. **Watch CPU.** Anchor's
      lyric task woke once a second against paused playback for 0.24% of a core
      — the rule is to gate on the work existing, not the feature being on.
### The Spotify session (new — ported this session, never run)

Settings → Player → Source, with the source set to **Spotify**. None of this
existed until now; the manager was here but nothing drove it.

- [X] **Sign in with Spotify.** Does the sheet open on Spotify's login page?
- [X] Sign in with email and password. Does the sheet **capture and close by
      itself**, without you ever seeing the cookie? That is the whole point of
      it — the `WKHTTPCookieStore` observer fires the moment `sp_dc` appears.
- [X] Does the status dot go **green** and the text say the session is good?
- [X] **Google accounts are deliberately blocked** in the sheet — it cancels the
      navigation and tells you to use email, Apple, or Open in Browser. If yours
      is a Google login, confirm you get that message rather than a dead white
      page, then use the manual route below.
- [X] **Open in Browser** — does it open the web player?
- [X] **Reset Session** — does the sheet return to a logged-out login page?
- [X] Reopen the sheet after a successful capture. It is a `.nonPersistent()`
      store, so you should have to **sign in again**. If you are still logged
      in, the store is persisting when it should not and `Clear` is a lie.
- [X] **Validate Cookie** with a good cookie — green dot. Then corrupt a
      character by hand and validate again: it must go **red with an error**,
      not sit silently on the old green.
- [X] **Clear.** Does the dot go grey, the field empty, and lyrics stop?
- [X] **Paste from Clipboard** with a cookie copied. Does it sanitise a full
      `sp_dc=…; sp_key=…` string down to just the value?
- [X] The **reveal eye**. Masked by default, shows on demand, and re-masks.
- [X] The manual route still works: **Get the cookie manually** disclosure →
      DevTools → Application → Cookies → `open.spotify.com` → `sp_dc`.
- [X] Now the payoff: **lyrics** should start working, and **Canvas** should
      switch on for tracks that have one. Canvas specifically was impossible
      before this — `.spotifyCanvasSessionDidChange` had no reachable poster.
- [X] Playback should have worked all along **without** any of this.
- [X] **This is a credential — confirm it never appears in a log, a crash
      report or `git status`.** This repo is public. The cookie lives in the
      prefs plist, not the working tree.

