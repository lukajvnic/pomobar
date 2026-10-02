# Pomobar

A small Pomodoro timer for the macOS menu bar. Requires macOS 26.

- 25/5 or 60/10 sessions
- A ring in the menu bar that turns red for focus and blue for breaks
- Optional alarm sound and macOS notification when a session ends
- An iPhone push one minute before a break ends, sent through [ntfy](https://ntfy.sh)

## Build

```sh
./scripts/build.sh            # builds build/Pomobar.app
./scripts/build.sh --install  # copies it to /Applications and launches it
```

The installed copy turns on "Open at login" the first time it runs. You can switch this off in Settings.

## iPhone alerts

1. Install **ntfy** from the App Store.
2. In Pomobar, click the gear and copy the topic. With Universal Clipboard you can paste it straight on the iPhone.
3. In ntfy, tap **+**, paste the topic, keep the default server (`ntfy.sh`) and subscribe.
4. Tap **Send test** in Pomobar, then turn on **iPhone alert**.

The push is scheduled on the ntfy server when a break starts, so it still arrives if the Mac goes to sleep. It's cancelled if you pause, reset or skip the break. ntfy.sh topics are public, so keep the topic name private.

## Development

- `POMOBAR_SCALE=0.02` shortens every session (25 min becomes 30 s).
- `POMOBAR_OPEN=1` opens the panel on launch.

```sh
POMOBAR_SCALE=0.02 ./build/Pomobar.app/Contents/MacOS/Pomobar
```
