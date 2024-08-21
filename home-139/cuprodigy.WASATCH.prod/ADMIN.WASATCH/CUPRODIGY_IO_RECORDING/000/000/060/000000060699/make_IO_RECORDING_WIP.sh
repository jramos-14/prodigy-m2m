timestamp=`date '+%Y%m%d%H%M%S'`
set -x
mkdir "WIP.${timestamp}"
cp -p 0*.[0-9][0-9]* "WIP.${timestamp}/."
cp -p /tmp/xenia-idadiv/mbcache/000/001/502/000001502625 "WIP.${timestamp}/000001502625.mbcache"
