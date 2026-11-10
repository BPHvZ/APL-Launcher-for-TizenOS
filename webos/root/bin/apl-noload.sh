#!/bin/sh
# apl-noload.sh: the apps you don't use never open, even when the TV preloads them on its own (LG Channels).
# For each app in noload.list (one id per line, # for a note), its start page is covered in RAM by a blank one
# (noload/index.html) that closes at once: the TV may still try to open it, nothing runs. Nothing is written
# in the system, the app stays installed; apl-noload-undo.sh puts it back now, a restart without this hook too.
# Started at every boot by init.d/14-apl-noload. OFF-noload pauses it.
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:$PATH
APL=/media/developer/apl-debloat
LIST=$APL/noload.list
STUB=$APL/noload/index.html
[ -e $APL/OFF ] && exit 0
[ -e $APL/OFF-noload ] && exit 0
[ -r $STUB ] || { echo "apl-noload: missing $STUB"; exit 1; }
[ -r $LIST ] || printf '%s\n' "# Apps that never open (apl-noload.sh). One id per line." "com.webos.app.lgchannels" > $LIST

grep -v '^ *#' $LIST | while read -r id; do
    [ -n "$id" ] || continue
    case "$id" in com.knikt.*|org.webosbrew.*|com.webos.app.home|com.webos.app.livetv|com.webos.app.hdmi*|airplay) continue ;; esac
    dir=""
    for d in /media/system/apps/usr/palm/applications /usr/palm/applications /media/cryptofs/apps/usr/palm/applications; do
        [ -f "$d/$id/appinfo.json" ] && { dir="$d/$id"; break; }
    done
    [ -n "$dir" ] || { echo "apl-noload: $id is not installed"; continue; }
    main=$(sed -n 's/.*"main" *: *"\([^"]*\)".*/\1/p' "$dir/appinfo.json" | head -1)
    [ -n "$main" ] || main=index.html
    page="$dir/$main"
    [ -f "$page" ] || { echo "apl-noload: $id has no $main"; continue; }
    if ! grep -q " $page " /proc/mounts; then
        mount --bind $STUB "$page" && echo "apl-noload: $id never opens"
    fi
    luna-send -n 1 -w 3000 luna://com.webos.applicationManager/closeByAppId "{\"id\":\"$id\"}" </dev/null >/dev/null 2>&1
done
exit 0
