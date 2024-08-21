# File: scan_idte.sh

# To see if HarlandFS has fixed the problem, scan the members known to have
# occurances of "Internal data transalation error(AcctInfo)", which will end up
# as "099"/"SYSTEM TEMPORARILY UNAVALIABLE".

TAB="	"

func_grep_mbnum(){
	cat dmshomecuharlandfs.logO dmshomecuharlandfs.log 2> /dev/null | \
	grep -e "Command: INQ: ${1}${TAB}" -e "INQUIRY Status Tag Block: ${1}${TAB}099${TAB}" | tail -1
}

for mbnum in 9492 10954 12114 12345 15532 15767 16211 ; do # {
	most_recent_status="`func_grep_mbnum ${mbnum}`"
	if [ "" != "${most_recent_status}" ] ; then # {
		set x ${most_recent_status} ; shift
		seconds="${1}"
		timestamp="${2}"
	else # } {
		seconds="N/A"
		timestamp="N/A"
	fi # }
	case "${most_recent_status}" in # {
	    (*"Command: INQ: "*)		echo "Good${TAB}${mbnum}${TAB}${timestamp}" ;;
	    (*"INQUIRY Status Tag Block: "*)	echo "Bad${TAB}${mbnum}${TAB}${timestamp}" ;;
	    (*)					echo "N/A${TAB}${mbnum}${TAB}${timestamp}" ;;
	esac # }
done # }
