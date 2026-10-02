# Pomobar: notes for coding agents

A macOS 26 menu bar Pomodoro timer. SwiftPM only (no Xcode project), Swift 6 strict concurrency, bundle id `com.luka.pomobar`.

## Build and run
- `./scripts/build.sh` builds `build/Pomobar.app`. Add `--install` to copy it to `/Applications` and relaunch.
- Always run the app from the `.app` bundle. The bare `.build/debug/Pomobar` binary crashes in `UNUserNotificationCenter`.
- Debug env vars:
  - `POMOBAR_SCALE=0.02` shortens sessions (25 min becomes 30 s).
  - `POMOBAR_OPEN=1` opens the panel at launch.
- Reinstalling kills the running copy. If a break is running, that also cancels its scheduled iPhone alert, so check before reinstalling.

## Architecture
- `TimerEngine`: pure countdown state. It's based on an `endDate`, so it survives sleep.
- `AppModel`: side effects (alarm, notifications, ntfy). Every user action must end with `syncPhone()`.
- `StatusItemController`: the menu bar ring and the time text, plus showing and hiding the panel.
- `GlassPanel`: an `NSPanel` whose content is an `NSGlassEffectView` hosting the SwiftUI views.
- `PanelView`: the timer and settings pages sit side by side in a `ZStack`. The gear slides between them by changing their offsets, and the panel animates to the height of the page that's showing.

## Gotchas (each one was learned the hard way)
- Don't switch to `MenuBarExtra`. On macOS 26 it still draws the old, murky menu material.
- `GlassContainer` pins its own size to the window (`setFrameSize`) and pins the glass and hosting frames (`resizeSubviews`). The window sometimes applies a resize to its content view twice, which leaves a strip of empty window above the glass that looks like a gap under the menu bar.
- Never override `NSWindow.setFrame` on `GlassPanel`. `animator().setFrame` calls the override on a proxy object, and that crashes the app.
- The glass sits inside a rounded `masksToBounds` container. Without it, the window shadow shows square corners.
- Panel height comes from SwiftUI's `onGeometryChange`, measured per page, through `fit(height:)`. Both pages always stay laid out, so the off-screen page needs `allowsHitTesting(false)`.
- Position the panel from `screen.visibleFrame.maxY`, the real menu bar edge. If the menu bar auto-hides, fall back to the notch/bar height. The user sometimes has an external display connected.
- While the panel is open, `StatusItemController` posts the distributed `com.apple.HIToolbox.begin/endMenuTrackingNotification`. That keeps an auto-hiding menu bar down like a real menu does, and closes other menu bar menus. Every hide path, including quitting, must post the end notification.
- The panel becomes key, so it takes keystrokes while open. Don't add keyboard shortcuts to it (the user removed space for play/pause).
- Custom glyphs must be template `NSImage`s (see `ResetArrow.image`). A plain SwiftUI `Shape` misses the glass panel's vibrancy and looks much lighter than the SF Symbols next to it.
- Launch at login turns itself on once, and only when the app runs from `/Applications`.

## ntfy (iPhone alerts)
- Each install generates a random topic on first launch and stores it in UserDefaults. It must never go into the repo.
- Read it with `defaults read com.luka.pomobar topic`.
- When a break starts, the app POSTs to `ntfy.sh/<topic>/pomobar-break` with an `In: <n>s` header (minimum 10 s).
- Pause, reset, skip, a mode change and quitting all `DELETE` that same URL.
- Requests are sent one at a time, in order.
- To see what's scheduled: `curl -s "https://ntfy.sh/<topic>/json?poll=1&sched=1"`.

## Design rules (user preferences)
- Minimal and native. No gradients, glows, emoji or heavy shadows. Use the system font and flat colors.
- Phase colors live in `Theme.swift`: red for focus, blue for break. Only the ring and the mode switch pill use the phase color.
- The controls copy the system Now Playing panel: bare gray glyphs (a custom `ResetArrow`, `play.fill`/`pause.fill`, `forward.fill`) with no circles, and tight padding.
- The main view holds only the mode switch, the gear, the ring and the three controls. New settings go on the gear page. Quit sits at the top right of the Settings page.
- Keep replies to the user short.

## Testing the UI
- The terminal has Screen Recording permission, so `screencapture -x` works. With an external display connected, pass one file per display (`screencapture -x main.png ext.png`); the panel opens on whichever screen holds the status item.
- It doesn't have Accessibility permission, so synthetic clicks fail. To reach a UI state, add a temporary env-var hook in `main.swift`, take the screenshot, then remove the hook.
