# Tests for you to run

Everything that could be checked from a script has been. These are the things
that need a person, a password, or hardware — ordered so the ones that could
invalidate the most work come first.

Tick as you go. If something fails, the file to look at is named.

Before starting, confirm the scripted half is still green — it takes a minute
and tells you whether a failure below is new:

```bash
./tests/run_gridsolver_tests.sh     # expect 93/93
./scripts/audit-reachability.sh     # expect "OK — nothing unreachable"
```

---

## 1. Playback — do this first

**Nothing in this repo has ever seen a real track.** Every check so far ran
against an empty player or the editor's frozen sample. If the controller layer
is wrong, some of what is built on top of it is wrong too, so this is the
highest-value hour you can spend.

(The player used to show `I'm Handsome` / `Me` / `Self Love` when idle — Anchor's
placeholder joke. That is fixed; §8 covers what idle should look like now.)

There is an **Automation permission dialog still open on your screen** from my
attempt at this. Allow it, or dismiss it and let Cadence prompt you itself.

- [ ] Play something in **Apple Music**. Title, artist, album and artwork all
      correct in the desktop player?
- [X] Does the progress bar advance smoothly, and do the times count up and
      down correctly?
- [X] Press play / pause / next / previous **on the widget**. Does the music
      respond?
- [X] Does the record start turning on play and **hold its position** on pause,
      rather than snapping back to the top?
- [ ] Drag the progress bar. Does it seek?
- [X] Click the **menu bar disc**. The first row should read
      `Title — Artist` while playing, and `Nothing playing` when not. It is
      read on open rather than subscribed, so a stale title here is a real bug.
- [X] Place a **Track time** element (the one readout that flips). Click it —
      does it swap between elapsed and remaining and stay swapped?

**All four sources, not just two.** Each is a different mechanism and only one
of them is event-driven the same way:

- [ ] **Apple Music** — AppleScript.
- [ ] **Spotify** — AppleScript. Switch source in Settings → Player → Source
      and confirm the player follows.
- [ ] **YouTube Music** — WebSocket, and the only source with a **2 s poll
      fallback**. Confirm it tracks at all, and that closing YouTube Music does
      not leave the poll running (check CPU with `scripts/measure.sh`).
- [ ] **Amazon Music** — AppleScript.
- [ ] **Now Playing** — the private MediaRemote path, which should cover every
      app. Apple removed part of this in 15.4, so it may simply not report;
      that is expected, not a crash.

- [ ] Play a **live stream** (a radio station) if you can find one. This is the
      one that crashed Anchor: a live stream reports a NaN duration and
      `Int(NaN)` traps. The times should read `--:--`, not crash.
- [X] Settings → Player → Elements → **Skip buttons**. Set it to seek rather
      than track and confirm next/previous scrub within the song instead of
      changing it.

*If artwork colour looks wrong:* `MusicManager.calculateAverageColor` →
`prominentOpposingColors` in `Sources/Extensions/NSImage+Extensions.swift`.

## 2. Artwork: cover, vinyl, tonearm, ring

This is the piece of the spec with the most surface area and **no automated
coverage at all** — the style lives on the placement, so it is only reachable
through the editor's inspector. Select the artwork element in
Settings → Layout to get these controls.

- [X] Set **Album cover**. Is it a plain square with the right corners?
- [X] Set **Vinyl record**. Is the album art *round*, masked to the record, and
      not a square sitting on a circle? That was a real bug —
      `CALayer.contents` from an `NSImage` honours neither `contentsGravity`
      nor the corner radius.
- [X] **Tonearm** on and off. Does it appear over the record and move?
- [X] **Progress ring around the record** on. Does it track playback? Turn it
      on *and* place a separate progress bar — both should work, they are
      independent.
- [X] Turn the progress ring **off**. Does the artwork shrink to fill the space
      it no longer needs, rather than leaving an empty strip? That exact bug
      shipped in Anchor (`VinylWidgetSize.height` was a fixed ratio).
- [ ] **Give each of the four surfaces a different style** — vinyl on the
      desktop, plain cover on the lock screen. They must not follow each other.
      Anchor had these as four global booleans; this is the test that they are
      no longer global.
- [ ] Does the record **swell or jump** when you drag the window between
      displays, or when the window resizes? It should not — `layout()` runs
      inside a `CATransaction` with actions disabled specifically to stop that.

## 3. The lock screen

Needs your password, which is why I could not do it.

You can preview both surfaces **without locking** from a Debug build, which is
worth doing first so a failure below is unambiguous:

```bash
open -n <build>/Cadence.app --env CADENCE_PREVIEW_LOCK=widget
open -n <build>/Cadence.app --env CADENCE_PREVIEW_LOCK=full
```

- [ ] Turn it on: Settings → Player → **Show on the lock screen**.
- [ ] Lock the screen (⌃⌘Q). **Does the widget actually appear?** This is the
      SkyLight delegation and it is completely unverified —
      `CGShieldingWindowLevel` alone clears ordinary windows but not
      loginwindow's shield.
- [ ] Double-click the artwork. Does it expand to the full-screen player?
- [ ] Double-click again. Does it collapse?
- [ ] Unlock. **Are both gone?** If one lingers, the unlock notification was
      late and the 500 ms poll in `LockScreenManager` did not catch it.
- [ ] Lock and unlock three or four times in a row. Anything left behind, or
      any crash? SkyLight is a private API and Anchor's notes say closing the
      window rather than ordering it out crashes it.

Its settings, all of which change what you see on a real lock screen and none
of which have been looked at:

- [ ] **Width** slider (260–620). Does the widget resize, and does its layout
      drop elements in priority order the way the desktop player does?
- [ ] **Vertical offset** slider (−240…240). Does it move, and does it stay on
      screen at both extremes?
- [ ] **Full-screen background** — switch between *Blurred album cover* and
      *Album cover colour*. Both should be visibly different and both should
      change when the track does. This is a spec item and it is untested.
- [ ] **Use Spotify Canvas video when there is one.** Play a Spotify track that
      has a Canvas (needs the `sp_dc` cookie set, §7). Does the full-screen
      background become the looping video? Turn it off — does it fall back
      cleanly rather than showing black?
- [ ] Remove the **Lyrics** element from the full-screen layout. The artwork
      should become the centred focus, not leave a hole. That is the
      "lyrics can be turned off" behaviour from the spec.

*If nothing appears:* `Sources/LockScreen/LockScreenPanelManager.swift`, the
`SkyLightOperator.delegateWindow` call.

## 4. Does the desktop player feel right?

Correctness here is measured; this is about whether it is pleasant.

- [ ] Grab each edge and corner and resize. Does the cursor change? Does the
      card follow without lag?
- [ ] Drag the **bottom** edge up. Elements should drop out in priority order —
      album first, then times, then artist. Does the order feel right, or do
      you want to reorder it in the editor?
- [ ] Shrink to the minimum and grow back. Does everything return in the same
      order, with nothing flickering in and out at a single drag step?
- [ ] Hover the card. If you have marked anything hover-only, does the reveal
      feel good or gimmicky? **`hoverGrowsWidget` turns the growth off** if it
      is the latter — it was built with that in mind.
- [ ] Hover near the **bottom edge of the screen**, where the card wants to
      grow downward and cannot. Does the clamp pull it up, or does it end up
      half off-screen?
- [ ] Hover *while resizing*. Growth is suppressed during a drag; the card must
      not fight the pointer.
- [ ] Double-click empty space. Does it go behind your windows?
- [ ] Now double-click the **progress bar**. It must *not* go behind — that is
      the `isInteractive` exclusion, and getting it wrong reads as the widget
      vanishing at random.
- [ ] Click the ✕. Does it offer *Send to back* and *Quit*, rather than acting
      silently?

## 5. Appearance settings

Settings → Player. Each of these is a live control with a visible effect and
none has been looked at by eye.

- [ ] **Show the desktop player** off. Does the window actually go away? Back
      on — does it return at the size and position it had?
- [ ] **Position** — Desktop / Normal / Floating. Desktop should sit behind
      everything (the same place double-clicking sends it), Floating above your
      windows. Confirm all three differ.
- [ ] **Tint with the album colour** on and off. Does the card take the album's
      colour, and does it *change* when the track does?
- [ ] **Colour taken from the artwork by** — Average vs Most vibrant. Play an
      album with a strong accent. The two settings should give visibly
      different cards; if they look the same the extraction has collapsed.
- [ ] **Progress bar colour** — step through every option and confirm each is
      distinct and readable against a tinted card.
- [ ] **Background** opacity slider at 0%, 50% and 100%. At 0 the card should
      be genuinely see-through, not merely dark. Check it is still *draggable*
      at 0 — an invisible window you cannot grab is the same failure as
      `keptOnScreen`.
- [ ] **Show in the Dock** on. Does an icon appear, and does Cadence show up in
      ⌘Tab? Off — does it leave the Dock without the windows closing?

## 6. The layout editor

Settings → Layout. Dragging is verified to persist; these are the edges.

- [ ] Drag an element onto an **occupied** cell. It must refuse — a no-op is
      correct, because two base elements sharing a cell is the grid's one
      invariant.
- [ ] Drag one **below the last row**. That should make a new bottom row.
- [ ] Add every element from the palette in turn and confirm each draws
      something real. **`Output`, `AirPlay`, `Volume` and `Timer` were inert
      icons until this session** and are the most likely to regress. The ones
      that need a *specific* track to prove: **Explicit badge** (play an
      explicit track), **App icon** (should change when you switch source),
      **Clock** (should be the real time and tick).
- [ ] Set an element to **On top** + **On hover**, then turn on *Show hover
      elements*. The surface must **not** grow. Switch it to **In the grid** and
      it must. That is the whole hover model in one test.
- [ ] Set something to priority 0 and shrink the desktop player to its minimum.
      It must survive.
- [ ] The keyboard: **⌘Z / ⇧⌘Z** undo and redo, **arrows** nudge, **⌫** removes,
      **esc** deselects. Verified live already — a quick pass is enough.
- [ ] **Reset this surface** — does it come back exactly as shipped?
- [ ] Change the desktop layout, then switch to Lock screen widget. **Is it
      untouched?** The four surfaces are meant to be completely independent, and
      this is the requirement most likely to have been broken by a shortcut.
      Check all four against each other, not just these two.

## 7. Lyrics

Off by default and **not covered anywhere else** — no automated test touches
this path, and it is the one feature that goes to the network.

- [ ] Settings → Player → Lyrics → **Fetch lyrics** on. Place the **Lyrics**
      element. Does it show the words for the current track?
- [ ] Do they **scroll in time**, with the current line highlighted?
- [ ] **Timing offset** slider. Negative should show each line earlier. Does
      moving it visibly shift the sync?
- [ ] **Visible lines** stepper, 0 through 9. At 0 it should fill whatever
      space it has; at 3 it should show three.
- [ ] **Translate lyrics** on. Does a translation appear, and does it fail
      quietly (not blank the element) when there is nothing to translate?
- [ ] Turn **Fetch lyrics** off with the element still placed. It should degrade
      to something sensible rather than an empty box or a spinner forever.
- [ ] Pause the music and leave it for a few minutes. **Watch CPU.** Anchor's
      lyric task woke once a second against paused playback for 0.24% of a core
      — the rule is to gate on the work existing, not the feature being on.
### The Spotify session (new — ported this session, never run)

Settings → Player → Source, with the source set to **Spotify**. None of this
existed until now; the manager was here but nothing drove it.

- [ ] **Sign in with Spotify.** Does the sheet open on Spotify's login page?
- [ ] Sign in with email and password. Does the sheet **capture and close by
      itself**, without you ever seeing the cookie? That is the whole point of
      it — the `WKHTTPCookieStore` observer fires the moment `sp_dc` appears.
- [ ] Does the status dot go **green** and the text say the session is good?
- [ ] **Google accounts are deliberately blocked** in the sheet — it cancels the
      navigation and tells you to use email, Apple, or Open in Browser. If yours
      is a Google login, confirm you get that message rather than a dead white
      page, then use the manual route below.
- [ ] **Open in Browser** — does it open the web player?
- [ ] **Reset Session** — does the sheet return to a logged-out login page?
- [ ] Reopen the sheet after a successful capture. It is a `.nonPersistent()`
      store, so you should have to **sign in again**. If you are still logged
      in, the store is persisting when it should not and `Clear` is a lie.
- [ ] **Validate Cookie** with a good cookie — green dot. Then corrupt a
      character by hand and validate again: it must go **red with an error**,
      not sit silently on the old green.
- [ ] **Clear.** Does the dot go grey, the field empty, and lyrics stop?
- [ ] **Paste from Clipboard** with a cookie copied. Does it sanitise a full
      `sp_dc=…; sp_key=…` string down to just the value?
- [ ] The **reveal eye**. Masked by default, shows on demand, and re-masks.
- [ ] The manual route still works: **Get the cookie manually** disclosure →
      DevTools → Application → Cookies → `open.spotify.com` → `sp_dc`.
- [ ] Now the payoff: **lyrics** should start working, and **Canvas** should
      switch on for tracks that have one. Canvas specifically was impossible
      before this — `.spotifyCanvasSessionDidChange` had no reachable poster.
- [ ] Playback should have worked all along **without** any of this.
- [ ] **This is a credential — confirm it never appears in a log, a crash
      report or `git status`.** This repo is public. The cookie lives in the
      prefs plist, not the working tree.

## 8. The audio elements

- [ ] Place **Output** on a surface. Does the menu list your real devices, and
      does picking one switch the Mac's output?
- [ ] Place **Volume**. Does the slider move the system volume, and does it
      show the right level when it first appears?
- [ ] Place **AirPlay** while Apple Music is playing. Does it list your AirPlay
      devices? *(Untested — needs an AirPlay device on your network.)*
- [ ] Place **Timer**, right-click it, pick 1 min. Does it count down and stop?
- [ ] Place **Visualiser**. Does it react to sound? This one acquires the
      CoreAudio process tap, so also check the CPU cost while it is on screen —
      that path cost Anchor 12× its idle CPU when it was left running.
- [ ] Settings → Player → Elements → **Real-time waveform** off. The visualiser
      should stop reading audio, and **the tap must be released** — idle CPU
      back to baseline. This is the reference-count rule; a tap still running
      with nothing consuming it is the exact regression the rule exists for.
- [ ] **Colour the visualiser from the album** on and off. Visibly different?
- [ ] Remove the visualiser from every surface while music plays. CPU must fall
      back to idle — 1→0 consumers must tear the tap down.

## 9. The launcher widget

It has no host in Cadence, but it is **not untestable** — there is a Debug
preview, and rendering it is the only thing standing between "built" and
"built and never once looked at":

```bash
open -n <build>/Cadence.app --env CADENCE_PREVIEW_LAUNCHER=1      # controls on hover
open -n <build>/Cadence.app --env CADENCE_PREVIEW_LAUNCHER=hover  # always visible
```

- [ ] Does it draw, on `.regularMaterial`, at the right size?
- [ ] **Hover.** The transport overlays the artist row, so revealing it must add
      **no height**. If the card grows, the overlay model is wrong here.
- [ ] Compare *controls on hover* against *always visible*. Both should be one
      layout, not two.
- [ ] Step through the three fixed sizes. There is no UI for this — the size
      and the always-visible flag are allowlisted as having no control until
      Anchor hosts them, so set them by hand:
      ```bash
      defaults write com.arronlingham.Cadence launcherWidgetSize -string compact  # or regular, wide
      ```
      Does the arrangement stay sane at `compact` (150pt)?

## 10. Two displays

I have not tested any of this; there is one screen attached here. **Check what
is actually plugged in before writing this off** — Anchor's notes record two
sessions that wrote "needs a monitor" while one was connected.

- [ ] Drag the player to a second display. Does it stay there?
- [ ] Unplug that display. Does the player come back onto the remaining one, or
      is it stranded off-screen? (`clampOnScreen` should catch it.)
- [ ] Sleep and wake. Is it still there and still correct?
- [ ] Lock the screen with two displays attached. Which one does the widget
      appear on, and is that the one you wanted? It follows the **menu-bar**
      screen deliberately, not `NSScreen.main`.
- [ ] Change resolution or scaling with the player open. Does it survive
      `didChangeScreenParameters`?

## 11. The things added last

- [ ] **Nothing playing.** With no music app running the player should say
      "Nothing playing", show a blank record, blank artist and album, `--:--`
      for both times, and a neutral dark card — **not** a pink card reading
      "I'm Handsome / Me / Self Love". That was Anchor's placeholder joke and it
      reached the screen as a fabricated track.
- [ ] **Then start playing.** It should fill in without a relaunch.
- [ ] **Open at login.** Settings → Player → General. In a Debug or ad-hoc
      build this correctly reads "Unavailable for this build"; it only works
      from a properly signed app in /Applications. Turn it on there, log out and
      back in.
- [ ] **The app icon.** A record on a purple-to-pink plate, in the Dock while
      Settings is open and in Finder. Regenerate with
      `swift scripts/make-icon.swift Sources/Assets.xcassets/AppIcon.appiconset`
      if you want to change it — it is drawn in code, not a binary blob.

## 12. Living with it

The things a short test cannot find.

- [ ] Leave it running for a day. Does memory stay flat? Re-run
      `scripts/measure.sh Cadence 180 "after a day"` and compare. **12+ minutes
      before believing any RSS figure** — this app settled 72 → 28 → 12.5 MB.
- [ ] Quit and relaunch. Is the player where you left it, at the size you left
      it, with your layout intact?
- [ ] Log out and back in. Same.
- [ ] Leave a track playing for an hour and watch idle CPU. Progress is drawn by
      a `TimelineView` interpolating locally; a publish per frame would show up
      here as a regression.
- [ ] Run it alongside Anchor. Turn Anchor's equivalents off first or you will
      get two of everything:
      ```bash
      defaults write com.arronlingham.Anchor enableLockScreenMediaWidget -bool false
      defaults write com.arronlingham.Anchor enableVinylWidget -bool false
      ```

---

## Known-unfinished, so don't report these as bugs

- **The launcher widget has no host.** It is built, uses the same engine, and
  can be previewed (§9), but nothing in Cadence opens it — it gets wired up
  when this folds into Anchor.

- **No updater**, deliberately. Anchor's Sparkle channels all point at upstream
  Atoll's appcast and once replaced Anchor with upstream.
- **The desktop card's artist and album sit side by side.** That is faithful to
  how `VinylWidgetView` draws its combined subtitle, transcribed into the grid.
  If you dislike it, delete `album` in the editor — the source falls back to
  bare artist too.
- **`vinylBackgroundOpacity` does nothing.** Known dead
  (`VinylWidgetView.swift:240` reads `.opacity(cond ? 1 : 1)`), to be fixed when
  that view is converted. It is not exposed in Settings, so you should not be
  able to reach it anyway.
