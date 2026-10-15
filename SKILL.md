---
name: flipping-kitty-themes
description: Use when the user wants already-open kitty terminal windows switched to a light/white or dark theme, "flip"/"toggle" the terminal themes, or when `kitten @` fails with "open /dev/tty: device not configured" from a shell with no controlling tty (such as Claude Code's Bash tool).
---

# Flipping kitty themes on all open windows

## Overview
This skill expects the [kitty-but-like-iterm](https://github.com/atharva-2001/kitty-but-like-iterm) setup in `~/.config/kitty/`, which gives each **new** window a random theme that matches the macOS appearance (`random-theme.sh` from `.zshrc`), and `theme-watcher.py` re-rolls windows **only when macOS appearance changes**. Windows that are already open never change on their own. `flip.sh` recolors every open window right away.

## Quick reference
```bash
~/.claude/skills/flipping-kitty-themes/flip.sh light    # "whiteish"
~/.claude/skills/flipping-kitty-themes/flip.sh dark
~/.claude/skills/flipping-kitty-themes/flip.sh toggle   # opposite of last flip (~/.cache/kitty-flip/mode)
```
The script prints one `<window-id> <theme>` line per window and then `done`, followed by any errors. Each window gets a random `light-*.conf` / `dark-*.conf` from `~/.config/kitty/themes/` (a different theme per window, on purpose, so windows are easy to tell apart). Its tab is tinted to match, using the theme's cursor color, or its foreground color when the theme has no cursor color.

Requires `allow_remote_control yes` in kitty.conf, `python3`, and `timeout` (stock macOS lacks it: `brew install coreutils`).

## Why plain `kitten @` doesn't work here
- `allow_remote_control yes` is set, but there is **no `listen_on` socket**. Remote control then only works through a kitty window's tty.
- Claude Code's Bash tool has no controlling tty, so `kitten @ …` fails with `open /dev/tty: device not configured`.

## How flip.sh works around it
1. It walks up the process tree to the nearest ancestor that has a tty (for example `ttysNNN`). That is the kitty window running this session.
2. It runs `kitten @ launch --type=background --allow-remote-control flip.sh --relight <mode>` inside `script -q /dev/null` (a fake pty), so kitten prints its `ESC P @kitty-cmd{json} ESC \` sequence, which the script captures.
3. It sets `"no_response": true` in that JSON. **This is required**: otherwise kitty's reply arrives as keystrokes in the session's input.
4. It writes the sequence to the ancestor tty. kitty reads it as program output and runs the command, which spawns the background helper with real remote-control access.
5. The helper runs `kitten @ ls` to get the real window IDs, then `set-colors` + `set-tab-color` for each one, and writes the log to `~/.cache/kitty-flip/log.txt`.

## Common mistakes
| Mistake | Result |
|---|---|
| Writing a big burst of raw set-colors escapes, one per guessed ID (1..400), to the tty | Some windows were silently missed. Use the launched helper with real IDs instead |
| Leaving `no_response` false | kitty's reply gets injected as typed input |
| Assuming every theme has a `cursor` line | `dark-one-half` and `light-one-half` don't have one, so `set-tab-color` fails with "is not a valid color" |
| Claiming success without reading the log | The log is the only evidence. You can't see the screen, so ask the user to confirm |

If a window still looks wrong after a clean log, the program running inside it (vim, a TUI, Claude Code's own theme) is probably drawing its own background.

## Permanent alternative
Add `listen_on unix:/tmp/kitty` to `kitty.conf` and restart kitty once. After that, `kitten @ --to unix:/tmp/kitty-<pid> …` works from anywhere and none of this is needed.
