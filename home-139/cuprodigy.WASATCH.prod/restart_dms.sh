# File: /home/cuprodigy/restart_dms.sh
# Gary Jay Peters
# 2017-09-06

# Based on the simple "restart_dms.sh" that had been being used before, but this
# smarter version know how to handle middlware run with the "--cuid".

USAGE="${0} [--cuid cuid]"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

#
ARG__CUID=""
while [ $# -gt 0 ] ; do # {
	case "${1}" in (-?*) true ;; (*) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    (--help)	func_abort 0 "USAGE: ${USAGE}" ;;
	    (--cuid|--cuid=*) # {
		case "${arg}" in (*=*)	qualifier=`echo " ${arg}" | sed 's/^ //' | cut -d = -f 2-999` ;; (*) [ $# -gt 0 ] || func_abort 22 "USAGE: ${USAGE}" ; qualifier=${1} ; shift ;; esac
		ARG__CUID="${qualifier}"
		[ `echo " ${ARG__CUID}" | sed 's/^ //' | grep -v -i '^[A-Z][A-Z0-9_][A-Z0-9_]*$' | wc -l` -eq 0 ] || func_abort 22 "${0}: Argument '--cuid' qualifier invalid format: ${ARG__CUID}"
		[ -d "TMP.${ARG__CUID}" ] || func_abort 2 "${0}: No directory: `pwd`/TMP.${ARG__CUID}"
	    ;; # }
	esac # }
done # }
[ $# -eq 0 ] || func_abort 22 "USAGE: ${USAGE}"

(
	[ "" != "${ARG__CUID}" ] && echo "TMP.${ARG__CUID}"
	[ "" != "${ARG__CUID}" ] || find TMP/pipe_pid_usage.* TMP.*/pipe_pid_usage.* -mtime -1 2> /dev/null | cut -d / -f 1 | uniq
) | (
	while read tmp_dir ; do # {
		echo "Setting: `pwd`/${tmp_dir}/run_stop_restart"
		date > "`pwd`/${tmp_dir}/run_stop_restart"
	done # }
)
