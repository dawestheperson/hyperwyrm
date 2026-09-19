#!/bin/sh
# Shortcuts for recording demos and testing a live shell.
#   tools/demo/demo.sh xp 300         grow to that much XP (evolves)
#   tools/demo/demo.sh badges moon    give every badge except the ones listed
#   tools/demo/demo.sh gift           the dragon leaves a gift on the floor
#   tools/demo/demo.sh joy 20         set happiness (below 35 it sulks)
#   tools/demo/demo.sh max            fullness, happiness and energy to 100
#   tools/demo/demo.sh fire           max everything and breathe fire (Emperor Dragon)
#   tools/demo/demo.sh poop           digest a snack now
#   tools/demo/demo.sh out            let the dragon out of the bar
exec qs -p "${OMARCHY_SHELL_PATH:-/usr/share/omarchy/shell}" ipc call hyperwyrm demo "$1" "${2:-0}"
