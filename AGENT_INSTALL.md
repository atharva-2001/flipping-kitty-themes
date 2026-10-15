# Agent install guide: flipping-kitty-themes

You are an AI coding agent setting up this tool for your user. Follow these steps in order. Do not
overwrite or delete any user file. If a step fails, stop and tell the user.

## Preconditions

1. `uname` prints `Darwin`, and `/Applications/kitty.app/Contents/MacOS/kitten` exists. If not, stop
   and tell the user that macOS and kitty are required.
2. `command -v python3` works.
3. `command -v timeout` works. If it doesn't, ask the user whether to run `brew install coreutils`.
   Don't install it without their yes.
4. `~/.config/kitty/kitty.conf` contains `allow_remote_control yes`. If it doesn't, ask the user before
   adding it, and tell them it lets programs running in kitty control kitty. Once it's added, they must
   quit kitty and reopen it.
5. `~/.config/kitty/themes/` holds at least one `light-*.conf` and one `dark-*.conf`. If it doesn't,
   suggest installing https://github.com/atharva-2001/kitty-but-like-iterm (it ships 26 themes), or
   saving themes from `kitten themes` under those names.

## Install

- **Claude Code:** if `~/.claude/skills/flipping-kitty-themes` already exists, stop and ask. Otherwise run
  `git clone https://github.com/atharva-2001/flipping-kitty-themes ~/.claude/skills/flipping-kitty-themes`.
- **Any other agent or plain shell:** clone it wherever the user wants. Your agent may have its own skills
  folder. If so, put it there and tell the user where.

Then run `chmod +x <install dir>/flip.sh`.

## Verify

Run `<install dir>/flip.sh toggle`. Success is one `<window-id> <theme path>` line per open kitty window,
then `done`, with no `--- errors:` block. Show the user the output. You can't see their screen, so ask
them to confirm their windows changed color. Run it once more to flip back if they want.

## Finish

Tell the user the three commands: `flip.sh light`, `flip.sh dark`, `flip.sh toggle`. For Claude Code,
also tell them they can just say "make my terminals light".
