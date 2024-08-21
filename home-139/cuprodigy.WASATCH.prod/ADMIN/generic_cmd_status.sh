# File: generic_cmd_status.sh
# Gary Jay Peters
# 2010-11-03

# Most of the DMS I/A interfaces written by GJP have share a normalized format
# of the "ADMIN/dmshomecu*.log" file; hence this script can use that normalcy as
# it parses STDIN (redirect data from "ADMIN/dmshomecu*.log*") to evaluate their
# commands and status.

# Use "./generic_cmd_elapsed_time.pl" to pre-filter "./dmshomecu*.log*" files
# (in the current directory) to a normal (sane) state.

# Also see "generic_cmd_status__count_good_bad.sh" for additional evaluation.

USAGE="${0} [--use-only-recent-logfiles #] [--ignore-data-format-exceptions] [--columnize]"

TAB="	"

TMPFILE0="/tmp/generic_cmd_status.tmp.$$-0"
TMPFILE1="/tmp/generic_cmd_status.tmp.$$-1"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

ARG__USE_ONLY_RECENT_LOGFILES=""
ARG__IGNORE_DATA_FORMAT_EXEPTIONS=""
ARG__COLUMNIZE=false
while [ $# -gt 0 ] ; do # {
	case "${1}" in -*) true ;; *) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    --help)				func_abort 0 "USAGE: ${USAGE}" ;;
	    --columnize)			ARG__COLUMNIZE=true ;;
	    --use-only-recent-logfiles)		ARG__USE_ONLY_RECENT_LOGFILES="${1}" ; shift ;;
	    --use-only-recent-logfiles=*)	ARG__USE_ONLY_RECENT_LOGFILES=`echo " ${arg}" | sed 's/^ //' | sed 's/^[^=]*=//'` ;;
	    --ignore-data-format-exceptions)	ARG__IGNORE_DATA_FORMAT_EXEPTIONS="${arg}" ;;
	    *)					func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -ne 0 ] && func_abort 22 "USAGE: ${USAGE}"
[ `echo "0${ARG__USE_ONLY_RECENT_LOGFILES}" | grep -v '^[0-9][0-9]*$' | wc -l` -gt 0 ] && func_abort 22 "${0}: Invalid argument '--use-only-recent-logfiles' qualifier: ${ARG__USE_ONLY_RECENT_LOGFILES}"
if ${ARG__COLUMNIZE} ; then # {
	ARG__COLUMNIZE_SCRIPT="./columnize.pl"
	[ ! -f "${ARG__COLUMNIZE_SCRIPT}" ] && func_abort 2 "${0}: Not a filter script file: ${ARG__COLUMNIZE_SCRIPT}"
	[ ! -r "${ARG__COLUMNIZE_SCRIPT}" ] && func_abort 13 "${0}: Invalid permissions on filter script file: ${ARG__COLUMNIZE_SCRIPT}"
	[ ! -x "${ARG__COLUMNIZE_SCRIPT}" ] && func_abort 13 "${0}: Invalid permissions on filter script file: ${ARG__COLUMNIZE_SCRIPT}"
fi # }

func_log_files(){
	if [ `ls -tr | grep -e '^dmshomecu.*\.log' | grep -v -e '\.lock$' | wc -l` -eq 0 ] ; then # {
		echo "${0}: func_log_files(): No log files in current directory matching the pattern: ^dmshomecu.*\\.log" 1>&2
		exit 2
	else # } {
		ls -tr | grep -e '^dmshomecu.*\.log' | grep -v -e '\.lock$'
	fi # }
}

func_cat_logs(){
    (
	arg__use_only_recent_logfiles="${1}"
	(
		func_log_files
	) | (
		[ "0${arg__use_only_recent_logfiles}" -gt 0 ] && tail -n "${arg__use_only_recent_logfiles}"
		[ "0${arg__use_only_recent_logfiles}" -gt 0 ] || cat
	) | (
		while read file ; do # {
			[ ! -f "${file}" ] && continue
			echo "Scanning: ${file}" 1>&2
			cat "${file}"
		done # }
	) | grep -v "^[0-9][0-9][0-9]${TAB}[^ ${TAB}]"
    )
}

func_cat_logs ${ARG__USE_ONLY_RECENT_LOGFILES} | ./generic_cmd_elapsed_time.pl --as-simple-status ${ARG__IGNORE_DATA_FORMAT_EXEPTIONS} | ( if ${ARG__COLUMNIZE} ; then "${ARG__COLUMNIZE_SCRIPT}" ; else cat ; fi )

exit

#	func_insert_extra_log_column(){
#		grep -n -e "." | sed 's/:/  /'	# Inserts an extra column for "linenumber"
#	}
#	
#	func_columnize_logs_4(){
#		sed "s/  /${TAB}/; s/  /${TAB}/; s/  /${TAB}/; s/  /${TAB}/"	# Splits out columns for "linenumber" and "seconds" and "timestamp" and "pid" and "data"
#	}
#	
#	func_cat_logs | func_insert_extra_log_column | grep -e "  Command: " -e " Status Tag Block: " -e "  Waiting for request" -e "  Stop process " | sed "s/${TAB}/ | /g" | func_columnize_logs_4 > ${TMPFILE0}
#	
#	echo "Evaluating data from the scanned log files (this may take a long time)." 1>&2
#	
#	cut -f 4 < ${TMPFILE0} | sort | uniq > ${TMPFILE1}
#	
#	OIFS="${IFS}" ; IFS="${TAB}"
#	cat ${TMPFILE1} | while read pid ; do # {
#		fgrep "${TAB}${pid}${TAB}" ${TMPFILE0} | while read line ; do # {
#			case "${line}" in # {
#			    (*"${TAB}Command: "*) # {
#				echo -n "${line}"
#			    ;; # }
#			    (*"${TAB}Waiting for request"*) # {
#				echo ""
#			    ;; # }
#			    (*"${TAB}Stop process "*) # {
#				echo ""
#			    ;; # }
#			    (*) # {
#				status=`echo "${line}" | sed 's/^.* Status Tag Block: //'`
#				echo -n "${TAB}${status}"
#			    ;; # }
#			esac # }
#		done # }
#		echo ""
#	done | grep -v '^$' | sed "s/${TAB}Command: /${TAB}/" | sort -n | cut -f 2-999 | ( if ${ARG__COLUMNIZE} ; then "${ARG__COLUMNIZE_SCRIPT}" ; else cat ; fi ) # }
#	IFS="${OIFS}"
#	
#	rm -f "${TMPFILE0}" "${TMPFILE1}"
