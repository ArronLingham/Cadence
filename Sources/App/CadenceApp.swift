/*
 * Cadence
 * Derived from Anchor, itself derived from Atoll (DynamicIsland) and boring.notch.
 * Copyright (C) 2024-2026 Atoll Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import AppKit
import Combine
import Defaults
import SwiftUI

extension Notification.Name {
    /// Posted when playback moves to a different track. Surfaces observe this
    /// if they want to react; nothing observes it yet, which is deliberate.
    static let cadenceTrackDidChange = Notification.Name("Cadence.trackDidChange")
}

@main
struct CadenceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // No WindowGroup and no Settings scene: Cadence is LSUIElement, so
        // there is no key window for `showSettingsWindow:` to reach and the
        // action silently found no responder. `SettingsWindowController` owns
        // an ordinary NSWindow instead. This empty scene exists only because
        // `App` requires one.
        Settings { EmptyView() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Never construct a manager from a stored property here.
    ///
    /// SwiftUI builds the delegate on the main thread *before* the run loop
    /// starts, so any singleton that blocks in `init` deadlocks the whole app
    /// at launch and `applicationDidFinishLaunching` never runs. Anchor lost
    /// several sessions to exactly this, and the symptom is not a crash — the
    /// process is alive and looks healthy while being completely hung.
    ///
    /// Everything below is `lazy` for that reason. Keep it that way, and defer
    /// blocking work in any new manager's `init` with `DispatchQueue.main.async`.
    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var cancellables = Set<AnyCancellable>()

    /// `.regular` puts Cadence in the Dock and ⌘Tab; `.accessory` keeps it to
    /// the menu bar. The settings window promotes to `.regular` while it is
    /// open regardless, because an accessory app cannot be raised by clicking
    /// it, and drops back on close — so this is the resting state, not an
    /// absolute.
    static func applyActivationPolicy() {
        NSApp.setActivationPolicy(Defaults[.showInDock] ? .regular : .accessory)
    }

    func applyActivationPolicy() { AppDelegate.applyActivationPolicy() }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // `.accessory` means no Dock icon and no ⌘Tab entry — the normal shape
        // for a menu-bar app, and the reason Cadence has no Dock icon by
        // default. It is a setting now rather than a hardcoded policy.
        applyActivationPolicy()
        // Before any surface is built, so nothing renders the old arrangement
        // first and then jumps.
        let migration = Defaults[.layoutMigration]
        if migration < PlayerLayouts.currentMigration {
            Defaults[.playerLayouts] = PlayerLayouts.migrated(
                Defaults[.playerLayouts], from: migration)
            Defaults[.layoutMigration] = PlayerLayouts.currentMigration
        }
        Defaults.publisher(.showInDock, options: [])
            .sink { _ in
                MainActor.assumeIsolated { AppDelegate.applyActivationPolicy() }
            }
            .store(in: &cancellables)
        setUpStatusItem()
        // Touching `shared` builds it; its `init` wires the controllers.
        // Deferred off the launch path because `init` reaches AppleScript and
        // CoreAudio, and blocking here is what deadlocks a SwiftUI delegate.
        DispatchQueue.main.async {
            _ = MusicManager.shared
            PlayerWindowManager.shared.start()
            LockScreenManager.shared.start()
            #if DEBUG
                LockScreenPanelManager.shared.previewIfRequested()
                LauncherPreview.showIfRequested()
            #endif
        }
    }

    private func setUpStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: "opticaldisc.fill", accessibilityDescription: "Cadence")
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        // A real action, so AppKit does not grey it out. `autoenablesItems`
        // disables anything with no action and draws it in the disabled label
        // colour — that grey was not styling, it was the item being dead, and
        // the row could not be clicked because there was nothing to click.
        let nowPlaying = NSMenuItem(
            title: "Nothing playing", action: #selector(openPlayer), keyEquivalent: "")
        nowPlaying.target = self
        nowPlaying.tag = Self.nowPlayingTag
        menu.addItem(nowPlaying)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit Cadence", action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q")
        menu.delegate = self
        return menu
    }

    private static let nowPlayingTag = 1

    /// Clicking the now-playing row opens the full-screen player, which is the
    /// obvious thing for a row showing the current track to do.
    @objc private func openPlayer() {
        MainActor.assumeIsolated { DesktopFullScreenController.shared.open() }
    }

    @objc private func openSettings() {
        // AppKit sends menu actions on the main thread.
        MainActor.assumeIsolated { SettingsWindowController.shared.show() }
    }
}

extension AppDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // AppKit calls this on the main thread; `assumeIsolated` says so rather
        // than deferring with a Task, which would not run — the app is on its
        // way out and the run loop stops before a hop could be serviced.
        MainActor.assumeIsolated { PlayerWindowManager.shared.persistFrame() }
    }
}

extension AppDelegate: NSMenuDelegate {
    /// Read the track when the menu opens rather than subscribing to
    /// `MusicManager` — a status item that is closed 99.9% of the time has no
    /// business re-rendering on every publish.
    func menuWillOpen(_ menu: NSMenu) {
        guard let item = menu.item(withTag: Self.nowPlayingTag) else { return }
        let music = MusicManager.shared
        // Two lines with artwork, drawn by AppKit. `subtitle` and `image` are
        // macOS 14+, and this project's floor is 26, so they are available
        // unconditionally — and AppKit handles vibrancy, highlighting, Reduce
        // Transparency and dark mode, none of which a custom NSView would get.
        if music.hasTrack {
            item.title = music.songTitle
            item.subtitle = music.artistName.isEmpty ? nil : music.artistName
            let art = music.albumArt
            let thumb = NSImage(size: NSSize(width: 28, height: 28), flipped: false) { rect in
                NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5).addClip()
                art.draw(in: rect)
                return true
            }
            item.image = thumb
            item.isEnabled = true
        } else {
            item.title = "Nothing playing"
            item.subtitle = nil
            item.image = nil
            // Nothing to open, so it is honestly disabled rather than a live
            // control that does nothing.
            item.isEnabled = false
        }
    }
}

/// The settings window.
struct SettingsRootView: View {
    var body: some View {
        TabView {
            LayoutEditorView()
                .tabItem { Label("Layout", systemImage: "square.grid.3x2") }
            PlayerSettingsView()
                .tabItem { Label("Player", systemImage: "opticaldisc") }
        }
        .frame(minWidth: 760, minHeight: 600)
    }
}
