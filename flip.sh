#!/bin/zsh
# Recolor EVERY open kitty window with a random light or dark theme from
# ~/.config/kitty/themes/{light,dark}-*.conf, tinting each tab to match.
#
#   flip.sh light|dark|toggle      (toggle = opposite of the last flip)
#
# Works even from a shell with no controlling tty (e.g. Claude Code's Bash
# tool), where plain `kitten @` fails with "open /dev/tty: device not
# configured" and kitty has no listen_on socket. Trick: capture the escape
# sequence `kitten @ launch` would send (by running it inside `script`),
# set no_response, and write it to the tty of the nearest kitty ancestor.
# kitty then launches THIS script in --relight mode as a background process
# with --allow-remote-control, where `kitten @ ls` / set-colors work normally.

THEMES="$HOME/.config/kitty/themes"
STATE="$HOME/.cache/kitty-flip"
K=/Applications/kitty.app/Contents/MacOS/kitten
mkdir -p "$STATE"

if [[ $1 == --relight ]]; then
    mode=$2; cd "$THEMES" || exit 1
    themes=($mode-*.conf(N)); (( ${#themes} )) || { echo "no $mode-*.conf" > "$STATE/err.txt"; exit 1; }
    : > "$STATE/log.txt"; : > "$STATE/err.txt"
    ids=$($K @ ls 2>>"$STATE/err.txt" | python3 -c 'import json,sys;print(*[w["id"] for o in json.load(sys.stdin) for t in o["tabs"] for w in t["windows"]])')
    for id in ${=ids}; do
        t=${themes[RANDOM % ${#themes} + 1]}
        get() { awk -v k=$1 '$1==k{print $2;exit}' $t; }
        $K @ set-colors --match id:$id $t
        b=$(get background); a=$(get cursor); a=${a:-$(get foreground)}; d=$(get color0)
        $K @ set-tab-color --match window_id:$id active_bg=$a active_fg=$b inactive_bg=${d:-$b} inactive_fg=$a
        echo "$id $t" >> "$STATE/log.txt"
    done 2>>"$STATE/err.txt"
    echo $mode > "$STATE/mode"
    echo done >> "$STATE/log.txt"
    exit 0
fi

mode=$1
if [[ $mode == toggle ]]; then
    [[ $(cat "$STATE/mode" 2>/dev/null) == light ]] && mode=dark || mode=light
fi
[[ $mode == light || $mode == dark ]] || { echo "usage: flip.sh light|dark|toggle"; exit 2; }

# Nearest ancestor process attached to a kitty tty.
p=$$; tty=""
while (( p > 1 )); do
    t=$(ps -o tty= -p $p | tr -d ' ')
    [[ -n $t && $t != "??" ]] && { tty=/dev/$t; break; }
    p=$(ps -o ppid= -p $p | tr -d ' ')
done
[[ -n $tty ]] || { echo "no kitty tty found among ancestors"; exit 1; }

rm -f "$STATE/log.txt"
python3 - "${0:A}" "$mode" "$tty" "$K" <<'PY' || exit 1
import json, re, subprocess, sys
script, mode, tty, kitten = sys.argv[1:]
out = subprocess.run(['timeout', '2', 'script', '-q', '/dev/null', kitten, '@', 'launch',
                      '--type=background', '--allow-remote-control', script, '--relight', mode],
                     stdin=subprocess.DEVNULL, capture_output=True).stdout.decode()
m = re.search(r'kitty-cmd(\{.*\})\x1b\\', out)
if not m: sys.exit('could not capture kitten escape:\n' + out)
c = json.loads(m.group(1)); c['no_response'] = True  # else kitty's reply lands as keystrokes
open(tty, 'wb').write(('\x1bP@kitty-cmd' + json.dumps(c) + '\x1b\\').encode())
PY

for _ in {1..20}; do grep -q '^done' "$STATE/log.txt" 2>/dev/null && break; sleep 0.5; done
cat "$STATE/log.txt" 2>/dev/null || echo "no log — helper did not run (is allow_remote_control on?)"
[[ -s $STATE/err.txt ]] && { echo "--- errors:"; cat "$STATE/err.txt"; }
exit 0
