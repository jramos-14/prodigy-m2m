#!/bin/sh
# File: save_rotated_log.sh
# Gary Jay Peters
# 2010-04-13

# Script to save log rotations; arguments are required because is generic form.

# This script DOES NOT check for inactivity; if the specified file exists then
# it is saved (renamed with a sequence).

# Contrab example:
#	0,15,30,45 * * * * /home/cusafiserv/ADMIN/save_rotated_log.sh /home/cusafiserv/ADMIN/dmshomecucusafiserv.logO

USAGE="${0} [--sequence-width=1|2|3|4|5|6] rotated-log-file-path-and-name1 [ ... rotated-log-file-path-and-nameN ]"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

ARG__SEQUENCE_WIDTH="3"
while [ $# -gt 0 ] ; do # {
	case "${1}" in -*) true ;; *) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    --help)		func_abort 0 "USAGE: ${USAGE}" ;;
	    --sequence-width=*)	ARG__SEQUENCE_WIDTH=`echo "${arg}" | sed 's/^[^=]*=//'` ;;
	    *)			func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ `echo " ${ARG__SEQUENCE_WIDTH}" | grep -e '^ [0-9][0-9]*$' | wc -l` -eq 0 ] && func_abort 22 "USAGE: ${USAGE}"
[ "${ARG__SEQUENCE_WIDTH}" -lt 1 -o "${ARG__SEQUENCE_WIDTH}" -gt 5 ] && func_abort 22 "USAGE: ${USAGE}"
[ $# -lt 0 ] && func_abort 22 "USAGE: ${USAGE}"

case "${ARG__SEQUENCE_WIDTH}" in # {
    1)	SEQ_PATTERN="[0-9]" ;;
    2)	SEQ_PATTERN="[0-9][0-9]" ;;
    3)	SEQ_PATTERN="[0-9][0-9][0-9]" ;;
    4)	SEQ_PATTERN="[0-9][0-9][0-9][0-9]" ;;
    5)	SEQ_PATTERN="[0-9][0-9][0-9][0-9][0-9]" ;;
    6)	SEQ_PATTERN="[0-9][0-9][0-9][0-9][0-9][0-9]" ;;
    *)	SEQ_PATTERN="[0-9][0-9][0-9]" ;;
esac # }

while [ $# -gt 0 ] ; do # {
	dir=`dirname "${1}"` ; rotated_logfile=`basename "${1}"` ; shift
	if [ ! -d "${dir}" ] ; then # {
		echo "${0}: No directory: ${dir}" 1>&2
	else # } {
		(
			if cd "${dir}" ; then # {
				if [ -f "${rotated_logfile}" ] ; then # {
					last_seq=`ls | grep "^${rotated_logfile}.${SEQ_PATTERN}\$" | tail -1 | sed "s/${SEQ_PATTERN}\$/ &/; s/^.* //"`
					if [ "" = "${last_seq}" ] ; then # {
						next_seq="0"
					else # } {
						next_seq=`expr 0${last_seq} + 1`
					fi # }
					if [ `expr length "${next_seq}"` -lt "${ARG__SEQUENCE_WIDTH}" ] ; then # {
						while true ; do # {
							case "${next_seq}" in # {
							    ${SEQ_PATTERN}) break ;;
							esac # }
							next_seq="0${next_seq}"
						done # }
					fi # }
					# echo mv "${rotated_logfile}" "${rotated_logfile}.${next_seq}"
					mv "${rotated_logfile}" "${rotated_logfile}.${next_seq}"
				fi # }
			fi # }
		)
	fi # }
done # }
