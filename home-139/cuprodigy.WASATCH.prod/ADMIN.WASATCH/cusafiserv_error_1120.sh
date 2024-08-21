# File: cusafiserv_error_1120.sh
# Gary Jay Peters
# 2010-08-04

# Scan for INQ failure due to CUSA/FiServ error "1120" on posting methods
# AccountList and AccountInquiry.
#
# The posting method MemberValidation (used to verify the initial password) is
# also known to respond with error "1120", but in this case the "1120" is how
# MemberValidation normally responds when the initial password value was invalid
# (and so this script is intentionally coded to ignore it).

USAGE="${0} [--other-errors]"

TAB="	"

CONF__IO_RECORDING__1_DIGIT_EXT_LIST="0 1 2 3 4 5 6 7 8 9"
CONF__IO_RECORDING__2_DIGIT_EXT_LIST="00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

ARG__ERROR_1120_ONLY=true
while [ $# -gt 0 ] ; do # {
	case "${1}" in -*) true ;; *) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    --other-errors)	ARG__ERROR_1120_ONLY=false ;;
	    *)	func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -ne 0 ] && func_abort 22 "USAGE: ${USAGE}"

func_path_IO_RECORDING(){
    (
	mbnum=`echo "000000000000${1}" | sed 's/[^0-9]//g; s/............$/ &/; s/^.* //'`
	path=`echo "${mbnum}" | sed 's#...$##; s#...#&/#g'`
	echo "${path}/${mbnum}" | sed 's#//*#/#g'
    )
}

func_grep(){
	if ${ARG__ERROR_1120_ONLY} ; then # {
		fgrep " Status Tag Block:" | \
		fgrep -e "${TAB}CUSA FiServ core: Failed using method: " -e "${TAB}Error c:Failed using method: " | \
		sed "s/^.*Status Tag Block: //; s/${TAB}999${TAB}CUSA FiServ core: Failed using method: /${TAB}/; s/${TAB}999${TAB}Error c:Failed using method: /${TAB}/; s/: /${TAB}/" | \
		fgrep "${TAB}Response: 1120 - " | \
		sed "/${TAB}Response: /s/ - .*\$//; s/${TAB}Response: /${TAB}/"
	else # } {
		fgrep " Status Tag Block:" | \
		fgrep -e "${TAB}CUSA FiServ core: Failed using method: " -e "${TAB}Error c:Failed using method: " | \
		sed "s/^.*Status Tag Block: //; s/${TAB}999${TAB}CUSA FiServ core: Failed using method: /${TAB}/; s/${TAB}999${TAB}Error c:Failed using method: /${TAB}/; s/: /${TAB}/" | \
		sed "/${TAB}Response: /s/ - .*\$//; s/${TAB}Response: /${TAB}/" | \
		sed "/Undefined .* value/s/[^${TAB}][^${TAB}]*\$/*empty*/" 
	fi # }
}

true && (
	cat `ls -tr dmshomecucusafiserv.log*` | func_grep | sort -n | uniq | \
	while read data_set ; do # {
		set x ${data_set} ; shift ; mbnum="${1}" ; method="${2}" ; method_error="${3}"
		if [ $# -gt 3 ] ; then method_error="*other*" ; fi 
		dir="CUSAFISERV_IO_RECORDING/`func_path_IO_RECORDING ${mbnum}`"
		file_base="`basename ${dir}`"
		pathfile_fixed=""
		pathfile_error=""
		for ext in ${CONF__IO_RECORDING__1_DIGIT_EXT_LIST} ${CONF__IO_RECORDING__2_DIGIT_EXT_LIST} ; do # {
			pathfile="${dir}/${file_base}.${ext}"
			if [ "" = "${pathfile_error}" ] ; then # {
				if [ -f "${pathfile}" ] ; then # {
					if [ `tail -10 ${pathfile} | grep -c "^# STATUS: INQUIRY${TAB}[0-9][0-9]*${TAB}000${TAB}NO ERROR"` -gt 0 ] ; then # {
						pathfile_fixed="${pathfile}"
					fi # }
					if [ `tail -10 ${pathfile} | grep -c "^# STATUS:.* Failed using method: "` -gt 0 ] ; then # {
						pathfile_error="${pathfile}"
					fi # }
				fi # }
			fi # }
		done # }
		desc=""
		timestamp="YYYYMMDDHHMMSS"
		if [ -f "${pathfile_error}" ] ; then # {
			timestamp=`date '+%Y%m%d%H%M%S' -r "${pathfile_error}"`
			desc=`grep "^# < DESC: " < "${pathfile_error}" | tail -1 | sed 's/^# < DESC: //'`
		fi # }
		if [ "" != "${pathfile_fixed}" ] ; then # {
			status="ok@"`echo "${pathfile_fixed}" | sed 's/^.*\.//'`
		else # } {
			status="fail"
		fi # }
		echo "${timestamp}${TAB}${mbnum}${TAB}${method}${TAB}${method_error}${TAB}${status}${TAB}${pathfile_error}${TAB}${desc}"
	done # }
)
