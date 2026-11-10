#!/bin/sh
# apl-noload-undo.sh: the apps of noload.list open normally again, now (their start pages uncovered).
# To keep it after a restart too: touch /media/developer/apl-debloat/OFF-noload, or empty noload.list.
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:$PATH
STUB=/media/developer/apl-debloat/noload/index.html
# Every page covered by the blank one (mounted from the same file)
awk '{print $2}' /proc/mounts | while read -r m; do
    case "$m" in */usr/palm/applications/*) ;; *) continue ;; esac
    if cmp -s "$m" "$STUB" 2>/dev/null; then umount "$m" && echo "apl-noload: $m back"; fi
done
exit 0
