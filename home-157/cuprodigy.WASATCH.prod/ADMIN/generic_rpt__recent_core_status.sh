#!/bin/bash
# File: generic_rpt__recent_core_status.sh
# Gary Jay Peters
# 2012-11-30

# Run common reports that are useful for evaluating status of the CU's core.

USAGE="${0} [corename-ext]"

TAB="	"

CONF__USE_ONLY_RECENT_LOGFILES=10

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

#
ARG__CORENAME_EXT=""
while [ $# -gt 0 ] ; do # {
	case "${1}" in (-*) true ;; (*) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    (--help)	func_abort 0 "USAGE: ${USAGE}" ;;
	    (*)		func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
if [ $# -ge 1 ] ; then ARG__CORENAME_EXT="${1}" ; shift ; fi
[ $# -gt 0 ] && func_abort 22 "USAGE: ${USAGE}"

#
curr_pwd=`pwd`
curr_subdir=`basename "${curr_pwd}"`
curr_path=`dirname "${curr_pwd}"`
case "${curr_subdir}" in # {
    (ADMIN|ADMIN.*)	true ;;
    (*)			func_abort 22 "${0}: Invalid current path: ${curr_pwd}" ;;
esac # }
corename=`basename "${curr_path}" | sed 's/[^a-z].*$//'`
filter_script=""
if   [ `ls -d ./generic_cmd_status__filter__${corename}_*.sh 2> /dev/null | wc -l` -eq 0 ] ; then # {
	filter_script="./generic_cmd_status__filter__${corename}.sh"
elif [ `ls -d ./generic_cmd_status__filter__${corename}_*.sh 2> /dev/null | wc -l` -eq 1 ] ; then # } {
	filter_script=`ls -d ./generic_cmd_status__filter__${corename}_*.sh 2> /dev/null`
else # } {
	(
		echo "Multiple extentions exists for '${corename}'; include one of these as a"
		echo "command line argument:"
		for corename_ext in `ls -d ./generic_cmd_status__filter__${corename}_*.sh 2> /dev/null | sed "s/\\.sh\$//; s/^.*__fitler__${corename}_//"` ; do # {
			echo "${TAB}${corename_ext}"
		done # }
	) 1>&2
	exit 22
fi # }
if [ ! -f "${filter_script}" ] ; then # {
	echo "Proceeding without filter script: ${filter_script}" 1>&2
	filter_script="cat"
fi # }

#
echo "#### Evaluating ${CONF__USE_ONLY_RECENT_LOGFILES} most recent logfiles ####" 1>&2

#
echo "Generating: /tmp/generic_rpt__recent_core_status.out.elapsed_time.detail" 1>&2
echo "Generating: /tmp/generic_rpt__recent_core_status.out.elapsed_time.summary" 1>&2
cat `ls -tr dmshomecu*.logO* dmshomecu*.log | tail -n ${CONF__USE_ONLY_RECENT_LOGFILES}` | ./generic_cmd_elapsed_time.pl > /tmp/generic_rpt__recent_core_status.out.elapsed_time.detail 2> /tmp/generic_rpt__recent_core_status.out.elapsed_time.summary

#
echo "Generating: /tmp/generic_rpt__recent_core_status.out.count_good_bad.summary" 1>&2
./generic_cmd_status.sh --use-only-recent-logfiles ${CONF__USE_ONLY_RECENT_LOGFILES} | \
	./generic_cmd_status__count_good_bad.sh \
		--count-as-good-001 \
		--count-as-good-002 \
		--filter-script "${filter_script}" \
> /tmp/generic_rpt__recent_core_status.out.count_good_bad.summary
