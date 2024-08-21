# File: grep_time.sh

TAB="	"

func_elapsed_seconds(){
    (
    	beg_yyyymmdd="${1}"
    	beg_hhmmss="${2}"
    	end_yyyymmdd="${3}"
    	end_hhmmss="${4}"
	beg_seconds=`echo ${beg_hhmmss} | sed 's/^[0-9][0-9]/&*60*60+/; s/[0-9][0-9]$/*60+&/'`
	end_seconds=`echo ${end_hhmmss} | sed 's/^[0-9][0-9]/&*60*60+/; s/[0-9][0-9]$/*60+&/'`
	echo "(${end_seconds}) - (${beg_seconds})" | bc
    )
}

put_tag=""; put_action=""; put_beg="" ; put_end=""
get_tag=""; get_action=""; get_beg="" ; get_end=""

(
	if [ $# -eq 0 ] ; then # {
		grep -e "^# [<>] " [0-9]*.0
	else # } {
		grep -e "^# [<>] " < "${1}"
	fi # }
) | \
sed '/^# [<>] DATE:/s/[0-9][0-9][0-9][0-9][0-9][0-9]$/ &/' | \
while read line ; do # {
	set x ${line} ; shift
	case ${line} in # {
	    ("# > DATE:"*) # {
	    	if [ "" = "${put_beg}" ] ; then # {
			put_beg="${4} ${5}"
		else # } {
			if [ "_skip_" != "${put_tag}" ] ; then # {
				put_end="${4} ${5}"
				elapsed_sec=`func_elapsed_seconds ${put_beg} ${put_end}`
				echo "${put_tag}${TAB}${put_action}${TAB}${elapsed_sec}${TAB}${put_beg}${TAB}${put_end}"
			fi # }
			put_tag=""
			put_action=""
			put_beg=""
			put_end=""
		fi # }
	    ;; # }
	    ("# < DATE:"*) # {
	    	if [ "" = "${get_beg}" ] ; then # {
			get_beg="${4} ${5}"
		else # } {
			if [ "_skip_" != "${get_tag}" ] ; then # {
				get_end="${4} ${5}"
				elapsed_sec=`func_elapsed_seconds ${get_beg} ${get_end}`
				echo "${get_tag}${TAB}${get_action}${TAB}${elapsed_sec}${TAB}${get_beg}${TAB}${get_end}"
			fi # }
			get_tag=""
			get_action=""
			get_beg=""
			get_end=""
		fi # }
	    ;; # }
	    ("# > DESC:"*)	shift 3; put_action="${@}" ; put_tag="PUT" ;;
	    ("# < DESC:"*)	shift 3; get_action="${@}" ; get_tag="GET" ;;
	    ("# > WORK:"*)	shift 3; put_action="${@}" ; put_tag="WORK/BEG" put_tag="_skip_" ;;
	    ("# < WORK:"*)	shift 3; get_action="${@}" ; get_tag="WORK/END" get_tag="WORK" ;;
	    ("# < STATUS:"*)	true ;;
	    (*)			echo "${line}" 1>&2 ;;
	esac # }
done | /home/harlandfs/ADMIN/columnize.pl # }
