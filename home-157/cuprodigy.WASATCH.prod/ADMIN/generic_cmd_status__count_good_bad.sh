# File: generic_cmd_status__count_good_bad.sh
# Gary Jay Peters
# 2010-11-03

# Parse the TAB delimited output of "generic_cmd_status.sh" producing a count
# result grouped by response status of good and bad.

# Usage example for any interface would be:
#	cd /home/${interfacename}/ADMIN
#	./generic_cmd_status.sh | \
#	    ./generic_cmd_status__count_good_bad.sh \
#		--count-as-good-001 \
#		--count-as-good-002
# 
# Usage example specific to a CUSA/FiServ interface on a CUSA core would be:
#	cd /home/cusafiserv/ADMIN
#	./generic_cmd_status.sh | \
#	    ./generic_cmd_status__count_good_bad.sh \
#		--count-as-good-001 \
#		--count-as-good-002 \
#		--filter-script ./generic_cmd_status__filter__cusafiserv_cusa.sh
# 
# Usage example specific to a HarlandFS interface would be:
#	cd /home/harlandfs/ADMIN
#	./generic_cmd_status.sh | \
#	    ./generic_cmd_status__count_good_bad.sh \
#		--count-as-good-001 \
#		--count-as-good-002 \
#		--filter-script ./generic_cmd_status__filter__harlandfs.sh

# Also see "generic_cmd_status__count_freq__bad.pl", which uses the output from
# "generic_cmd_status__count_good_bad.sh", evaluating and report the frequency
# of "bad" response statuses grouped by time-of-day.

# The "--count-as-good-*" arguments make it easy to ignore (recast as good) any
# of the common INQ and TRN return statuses.
#
# The "--filter-script" argument allows for an additional filtering script to
# be used to ignore (recast as good) selecte errors; the contents of the script
# file should process the TAB delimited field and strip off the 5th field when
# it is deemed to not be an error; for example:
#	TAB="	"
#	sed "s/${TAB}[^${TAB}]* | 000 | NO ERROR\$//"
# or:
#	TAB="	"
#	sed "s/${TAB}[^${TAB}]* | 001 | [^${TAB}]*\$//" | \
#	sed "s/${TAB}[^${TAB}]* | 002 | [^${TAB}]*\$//"

USAGE="${0} [--count-as-good-001] [--count-as-good-002] [--count-as-good-003] [--count-as-good-099] [--count-as-good-999] [--filter-script=script-name]"

TAB="	"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

ARG__FILTER_SCRIPT=""
ARG__COUNT_AS_GOOD_LIST=""
while [ $# -gt 0 ] ; do # {
	case "${1}" in -*) true ;; *) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    --count-as-good-001)	ARG__COUNT_AS_GOOD_LIST="${ARG__COUNT_AS_GOOD_LIST} 001" ;;
	    --count-as-good-002)	ARG__COUNT_AS_GOOD_LIST="${ARG__COUNT_AS_GOOD_LIST} 002" ;;
	    --count-as-good-003)	ARG__COUNT_AS_GOOD_LIST="${ARG__COUNT_AS_GOOD_LIST} 003" ;;
	    --count-as-good-099)	ARG__COUNT_AS_GOOD_LIST="${ARG__COUNT_AS_GOOD_LIST} 099" ;;
	    --count-as-good-999)	ARG__COUNT_AS_GOOD_LIST="${ARG__COUNT_AS_GOOD_LIST} 999" ;;
	    --filter-script|--filter-script=*) # {
		case "${arg}" in # {
		    *=*)	ARG__FILTER_SCRIPT=`echo " ${arg}" | sed 's/^[^=]*=//'` ;;
		    *)		ARG__FILTER_SCRIPT="${1}" ; shift ;;
		esac # }
		[ "" = "${ARG__FILTER_SCRIPT}" ] && func_abort 22 "USAGE: ${USAGE}"
		[ ! -f "${ARG__FILTER_SCRIPT}" ] && func_abort 2 "${0}: Not a filter script file: ${ARG__FILTER_SCRIPT}"
		[ ! -r "${ARG__FILTER_SCRIPT}" ] && func_abort 13 "${0}: Invalid permissions on filter script file: ${ARG__FILTER_SCRIPT}"
		[ ! -x "${ARG__FILTER_SCRIPT}" ] && func_abort 13 "${0}: Invalid permissions on filter script file: ${ARG__FILTER_SCRIPT}"
	    ;; # }
	    *)				func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -ne 0 ] && func_abort 22 "USAGE: ${USAGE}"

if [ "" = "${ARG__COUNT_AS_GOOD_LIST}" ] ; then # {
	sed_count_as_good=""
else # } {
	sed_count_as_good=""
	for error_number in `set x ${ARG__COUNT_AS_GOOD_LIST} ; shift ; while [ $# -gt 0 ] ; do echo "${1}" ; shift ; done | sort | uniq` ; do # {
		if [ "" != "${sed_count_as_good}" ] ; then # {
			sed_count_as_good="${sed_count_as_good}; "
		fi # }
		sed_count_as_good="${sed_count_as_good} s/${TAB}[^${TAB}]* | ${error_number} | [^${TAB}]*\$//; s/${TAB}[^${TAB}]* | ${error_number} | [^${TAB}]*${TAB}..............................................................//"
	done # }
fi # }

# For input try running "generic_cmd_status.sh" as:
#	`dirname ${0}`/generic_cmd_status.sh
# or:
#	`dirname ${0}`/generic_cmd_status.sh --columnize | \
#		sed 's/  *$//' | sed "s/    */${TAB}/g"
grep -v -e '  SYN: [0-9][0-9]*$' | \
fgrep -e "${TAB}INQ: " -e "${TAB}TRN: " | \
sed "s/${TAB}[^${TAB}]* | 000 | NO ERROR\$//" | \
( if [ "" = "${sed_count_as_good}" ] ; then cat ; else sed "${sed_count_as_good}; s/  *\$//" ; fi ) | \
( if [ "" = "${ARG__FILTER_SCRIPT}" ] ; then cat ; else "${ARG__FILTER_SCRIPT}" | sed 's/  *$//' ; fi ) | \
(
	IFS="${TAB}"
	mode_prev="" ; reason_prev=""
	while true ; do # {
		read line || break
		set x ${line} ; shift
		timestamp_curr="${2}"
		case "${5}" in # {
		    "") mode_curr="good" ; reason_curr="" ;;
		    *)	mode_curr="bad" ; reason_curr=`echo "${5}" | cut -d '|' -f 2-999` ;;
		esac # }
		if [ "${mode_prev} ${reason_prev}" = "${mode_curr} ${reason_curr}" ] ; then # {
			count="${count}."
			timestamp_end="${timestamp_curr}"
		else # } {
			if [ "" != "${mode_prev}" ] ; then # {
				count=`expr length "${count}"`
				echo "${count}${TAB}${mode_prev}${TAB}${timestamp_beg}${TAB}${timestamp_end}${TAB}${reason_prev}"
			fi # }
			count="."
			timestamp_beg="${timestamp_curr}"
			timestamp_end="${timestamp_beg}"
			mode_prev="${mode_curr}"
			reason_prev="${reason_curr}"
		fi # }
	done # }
	if [ "" != "${mode_prev}" ] ; then # {
		count=`expr length "${count}"`
		echo "${count}${TAB}${mode_prev}${TAB}${timestamp_beg}${TAB}${timestamp_end}${TAB}${reason_prev}"
	fi # }
)
