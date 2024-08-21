# File: cusafiserv_eof.sh
# Gary Jay Peters
# 2010-12-17

# Scan for occurances of CUSA/FiServ closing the connection (EOF).

TAB="	"

cd /home/cusafiserv/ADMIN
cat `ls -tr d*.log*` | grep ': EOF$' | sed "s/  /${TAB}/; s/  /${TAB}/; s/  /${TAB}/" | cut -f 2 | cut -c 1-8 | sort | uniq -c
