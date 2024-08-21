# File: core_degredation_check.sh
# Gary Jay Peters
# 2016-08-31

# Extract the more useful pieces of data from the "core_degredation_check"
# logfile entries, so can see patterns of when the CUSA/FiServ core has becomes
# slow.
#
# The CUSA/FiServ slowness is most commonly caused by an excessive number of
# hung "i_inter" processes on the CUSA/FiServ core sucking up the CPU cycles
# (which can be identified and killed by my "/process__aix__cusa__i_inter.pl"
# script); or the CU can simply reboot their CUSA/FiServ server.

USAGE="${0} [--descending] [--use-only-recent-logfiles #]"

TAB="	"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

#
ARG__DESCENDING=false
ARG__USE_ONLY_RECENT_LOGFILES="10"
while [ $# -gt 0 ] ; do # {
	case "${1}" in -*) true ;; *) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    --help)				func_abort 0 "USAGE: ${USAGE}" ;;
	    --descending)			ARG__DESCENDING=true ;;
	    --use-only-recent-logfiles)		ARG__USE_ONLY_RECENT_LOGFILES="${1}" ; shift ;;
	    --use-only-recent-logfiles=*)	ARG__USE_ONLY_RECENT_LOGFILES=`echo " ${arg}" | sed 's/^ //' | sed 's/^[^=]*=//'` ;;
	    *)					func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -ne 0 ] && func_abort 22 "USAGE: ${USAGE}"
[ `echo "0${ARG__USE_ONLY_RECENT_LOGFILES}" | grep -v '^[0-9][0-9]*$' | wc -l` -gt 0 ] && func_abort 22 "${0}: Invalid argument '--use-only-recent-logfiles' qualifier: ${ARG__USE_ONLY_RECENT_LOGFILES}"

#
echo "Timestamp${TAB}Elapse${TAB}Rows/s${TAB}Status"
# echo "Timestamp${TAB}Pass${TAB}Fail${TAB}Other" 1>&2
echo "Timestamp${TAB}Norm${TAB}Slow${TAB}Other" 1>&2
(
	cat `ls -tr dmshomecu*.log* | tail -${ARG__USE_ONLY_RECENT_LOGFILES}`
) | (
	fgrep 'core_degradation_check(calculate)' | fgrep -v ': Skipped: too few rows'
) | (
	sed "s/^[0-9][0-9]*  //; s/  .* rows, /${TAB}/; s/ seconds, /${TAB}/; s/ rows per second, /${TAB}/; s/ minimum.*\$//"
) | (
	${ARG__DESCENDING} && tac
	${ARG__DESCENDING} || cat
) | (
	(
		while read line ; do # {
			echo "${line}" 1>&3
			echo "${line}"
		done # }
	) | (
		cut -f 1,4 | sed "s/....${TAB}/mmss${TAB}/" | sort | uniq -c
	) | (
		${ARG__DESCENDING} && tac
		${ARG__DESCENDING} || cat
	) | (
		prev_yyyymmddhh="" ; prev_pass="" ; prev_fail="" ; prev_other=""
		while true ; do # {
			read data || break
			set x ${data} ; shift ; count="${1}" ; yyyymmddhh="${2}" ; status="${3}"
			if [ "${prev_yyyymmddhh}" != "${yyyymmddhh}" ] ; then # {
				if [ "" != "${prev_yyyymmddhh}" ] ; then # {
					if [ "" = "${prev_other}" ] ; then # {
						echo "${prev_yyyymmddhh}${TAB}${prev_pass}${TAB}${prev_fail}" 1>&2
					else # } {
						echo "${prev_yyyymmddhh}${TAB}${prev_pass}${TAB}${prev_fail}${TAB}${prev_other}" 1>&2
					fi # }
				fi # }
				prev_yyyymmddhh="${yyyymmddhh}"
				prev_pass=""
				prev_fail=""
				prev_other=""
			fi # }
			case "${status}" in # {
			    (passed)	prev_pass="${count}" ;;
			    (failed)	prev_fail="${count}" ;;
			    (*)		prev_other="${count}" ;;
			esac # }
		done # }
		if [ "" = "${prev_other}" ] ; then # {
			echo "${prev_yyyymmddhh}${TAB}${prev_pass}${TAB}${prev_fail}" 1>&2
		else # } {
			echo "${prev_yyyymmddhh}${TAB}${prev_pass}${TAB}${prev_fail}${TAB}${prev_other}" 1>&2
		fi # }
	)
) 3>&1
