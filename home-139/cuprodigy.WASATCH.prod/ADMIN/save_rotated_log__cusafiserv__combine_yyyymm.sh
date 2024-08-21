# File: save_rotated_log__cusafiserv__combine_yyyymm.sh
# Gary Jay Peters
# 2011-03-08

TAB="	"

DIR_SRC="/home/cusafiserv/ADMIN"
DIR_DST="/tmp"
LOGFILE_BASENAME="dmshomecucusafiserv.log"

cd "${DIR_SRC}" || exit ${?}

(
	ls | grep -e "${LOGFILE_BASENAME}O.[0-9][0-9][0-9]" | while read file ; do # {
		timestamp_beg=`head -n 4 ${file} | grep -e "^[0-9][0-9]*  [0-9][0-9]*  [0-9][0-9]*  " | head -n 1 | sed 's/^[0-9][0-9]*  //; s/ .*$//'`
		timestamp_end=`tail -n 4 ${file} | grep -e "^[0-9][0-9]*  [0-9][0-9]*  [0-9][0-9]*  " | tail -n 1 | sed 's/^[0-9][0-9]*  //; s/ .*$//'`
		yyyymm_beg=`expr substr ${timestamp_beg} 1 6`
		yyyymm_end=`expr substr ${timestamp_end} 1 6`
		echo "${timestamp_beg}${TAB}${timestamp_end}${TAB}${yyyymm_beg}${TAB}${yyyymm_end}${TAB}${file}"
	done # }
) | (
	prev_yyyymm=""
	while read group ; do # {
		echo "${group}"
		set x ${group} ; shift	
		timestamp_beg="${1}" ; timestamp_end="${2}" ; yyyymm_beg="${3}" yyyymm_end="${4}" ; file="${5}"
		output_beg="${DIR_DST}/${LOGFILE_BASENAME}O.yyyymm=${yyyymm_beg}"
		output_end="${DIR_DST}/${LOGFILE_BASENAME}O.yyyymm=${yyyymm_end}"
		if [ "${prev_yyyymm}" != "${yyyymm_beg}" ] ; then # {
			rm -f "${output_beg}"
			prev_yyyymm="${yyyymm_beg}"
		fi # }
		if [ "${prev_yyyymm}" != "${yyyymm_end}" ] ; then # {
			rm -f "${output_end}"
			prev_yyyymm="${yyyymm_end}"
		fi # }
		if [ "${yyyymm_beg}" = "${yyyymm_end}" ] ; then # {
			cat "${file}" >> "${output_end}"
			touch -r "${file}" "${output_end}"
		else # } {
			sed -n "/^[0-9][0-9]*  ${yyyymm_end}/q; p" < "${file}" >> "${output_beg}"
			timestamp_last=`tail -n 4 "${output_beg}" | grep -e "^[0-9][0-9]*  [0-9][0-9]*  [0-9][0-9]*  " | tail -n 1 | sed 's/^[0-9][0-9]*  //; s/ .*$//'`
			touch_timestamp=`echo "${timestamp_last}" | sed 's/..$/.&/'`
			touch -t ${touch_timestamp} "${output_beg}"
			sed -n "/^[0-9][0-9]*  ${yyyymm_end}/,\$p" < "${file}" >> "${output_end}"
			touch -r "${file}" "${output_end}"
		fi # }
	done # }
)
