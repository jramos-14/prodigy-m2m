# File: grep_timing_simple.sh
# Gary Jay Peters
# 2010-02-02

if [ $# -eq 0 ] ; then # {
	set x `ls -t | grep '^[0-9][0-9]*\.[0-9][0-9]*$' | head -n 1` ; shift
fi # }
[ $# -gt 0 ] && grep -e "^# [<>] DATE: " -e "^# [<>] DESC: " ${@} | sed "s/[<>] DATE:/  DATE:/" | uniq
