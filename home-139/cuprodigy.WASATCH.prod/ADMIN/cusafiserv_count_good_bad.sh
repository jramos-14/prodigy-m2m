# File: cusafiserv_count_good_bad.sh
# Gary Jay Peters
# 2011-01-05

# The CUSA/FiServ core has various errors that skew the results of the command
# "./generic_cmd_status.sh | ./generic_cmd_status__count_good_bad.sh"; this
# script inserts a normalization filter between to the 2 scripts so as to mutate
# the normal CUSA/FiServ TRN posting rejection errors into "NO ERROR".

USAGE="${0} [#-recent-logfiles]"

TAB="	"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

ARG__NUMBER_RECENT_LOGFILES=""
while [ $# -gt 0 ] ; do # {
	case "${1}" in (-?*) true ;; (*) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    (--help)	func_abort 0 "USAGE: ${USAGE}" ;;
	    (*)		func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -le 1 ] || func_abort 22 "USAGE: ${USAGE}"
if [ $# -gt 0 ] ; then # {
	ARG__NUMBER_RECENT_LOGFILES="${1}" ; shift
	[ `echo " ${ARG__NUMBER_RECENT_LOGFILES}" | sed 's/^ //' | grep -v '^[0-9][0-9]*$' | wc -l` -eq 0 ] || func_abort 22 "${0}: Argument '#-recent-logfiles' value must be an integer: ${ARG__NUMBER_RECENT_LOGFILES}"
	[ `echo " ${ARG__NUMBER_RECENT_LOGFILES}" | sed 's/^ //' | sed 's/^0*//' | grep '^[1-9][0-9]*$' | wc -l` -eq 1 ] || func_abort 22 "${0}: Argument '#-recent-logfiles' value must be greater than zero: ${ARG__NUMBER_RECENT_LOGFILES}"
	ARG__NUMBER_RECENT_LOGFILES=`echo " ${ARG__NUMBER_RECENT_LOGFILES}" | sed 's/^ //' | sed 's/^0*//'`
fi # }

cd /home/cusafiserv/ADMIN
(
	[ "" = "${ARG__NUMBER_RECENT_LOGFILES}" ] && ./generic_cmd_status.sh
	[ "" = "${ARG__NUMBER_RECENT_LOGFILES}" ] || ./generic_cmd_status.sh --use-only-recent-logfiles ${ARG__NUMBER_RECENT_LOGFILES}
) | (
	sed \
		-e "/${TAB}INQ: /s/ | 999 | MEMBER ACCOUNT IS BUSY\$/ | 000 | NO ERROR/" \
		-e "/${TAB}INQ: /s/ | 999 | CUSA FiServ core: Failed using method: AccountList: Response: 1120 - No Records match selection criteria\$/ | 000 | NO ERROR/" \
		-e "/${TAB}INQ: /s/ | 999 | Error c:Failed using method: AccountList: Response: 1120 - No Records match selection criteria\$/ | 000 | NO ERROR/" \
		-e "/${TAB}TRN: /s/ | 999 | DMS\\/HomeCU internet appliance: .*\$/ | 000 | NO ERROR/" \
		-e "/${TAB}TRN: /s/ | 999 | Error m:.*\$/ | 000 | NO ERROR/" \
		-e "/${TAB}TRN: /s/ | 999 | CUSA FiServ core: 1120 - The service is currently inquiry only\$/ | 000 | NO ERROR/" \
		-e "/${TAB}TRN: /s/ | 999 | Error c:1120 - The service is currently inquiry only\$/ | 000 | NO ERROR/" \
		-e "/${TAB}TRN: /s/ | 999 | CUSA FiServ core: 1120 - Account  *[0-9][0-9]*  *[A-Za-z0-9], .*\$/ | 000 | NO ERROR/" \
		-e "/${TAB}TRN: /s/ | 999 | Error c:1120 - Account  *[0-9][0-9]*  *[A-Za-z0-9], .*\$/ | 000 | NO ERROR/"
) | ./generic_cmd_status__count_good_bad.sh --count-as-good-001 --count-as-good-002
