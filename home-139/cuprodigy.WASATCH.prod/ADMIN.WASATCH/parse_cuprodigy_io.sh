# File: /home/cuprodigy/ADMIN/parse_cuprodigy_io.sh
# Gary Jay Peters
# 2007-11-14

USAGE="${0} [ cuprodigy_io_recording_file ]"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

TAB="	"

ARG__FILE=""
if [ $# -gt 0 ] ; then # {
	ARG__FILE="${1}" ; shift
fi # }
[ $# -ne 0 ] && func_abort 22 "USAGE: ${USAGE}"
if [ "" = "${ARG__FILE}" ] ; then # {
	count=`ls -d *.0 *.00 *.000 2> /dev/null | grep -e '^[0-9][0-9]*\.00*$' | wc -l`
	if [ ${count} -eq 1 ] ; then # {
		ARG__FILE="`ls -d *.0 *.00 *.000 2> /dev/null | grep -e '^[0-9][0-9]*\.00*$'`"
	else # } {
		func_abort 13 "${0}: No single file matching: [0-9][0-9]*.00*"
	fi # }
fi # }
[ ! -f "${ARG__FILE}" ] && func_abort 13 "${0}: No file: ${ARG__FILE}"
[ ! -r "${ARG__FILE}" ] && func_abort 2 "${0}: Can not read file: ${ARG__FILE}"

echo "==="
echo "Creating files:"
echo "        parse_cuprodigy_io.out.1"
echo "        parse_cuprodigy_io.out.2"
echo "        parse_cuprodigy_io.out.3"
echo "        parse_cuprodigy_io.out.4"
echo "        parse_cuprodigy_io.out.5"
echo "==="
/home/cuprodigy/dmshomecucuprodigy.pl --parse-stdin < "${ARG__FILE}" > parse_cuprodigy_io.out.1 2> parse_cuprodigy_io.out.2
sed "s/^[<>] ${TAB}ENVELOPE\\.[0-9][0-9][0-9][0-9][0-9]${TAB}/&${TAB}/; s/^[<>] ${TAB}ENVELOPE\\.[^${TAB}]*\\.[0-9][0-9][0-9][0-9][0-9]${TAB}/&${TAB}/" < parse_cuprodigy_io.out.2 | /home/cuprodigy/ADMIN/columnize.pl --pass-thru-comments --save-blank-lines --strip-trailing-spaces > parse_cuprodigy_io.out.3
sed "s/^[<>] ${TAB}ENVELOPE\\.[0-9][0-9][0-9][0-9][0-9]${TAB}/&${TAB}/; s/^[<>] ${TAB}ENVELOPE\\.[^${TAB}]*\\.[0-9][0-9][0-9][0-9][0-9]${TAB}/&${TAB}/" < parse_cuprodigy_io.out.2 | grep -v -e "^[<>] ${TAB}ENVELOPE${TAB}[^${TAB}]" -e "^[<>] ${TAB}ENVELOPE\\.[^${TAB}]*${TAB}[^${TAB}]" | sed "s/${TAB}${TAB}/${TAB}/" | /home/cuprodigy/ADMIN/columnize.pl --pass-thru-comments --save-blank-lines --strip-trailing-spaces > parse_cuprodigy_io.out.4
sed "s/^[<>] ${TAB}ENVELOPE\\.[0-9][0-9][0-9][0-9][0-9]${TAB}/&${TAB}/; s/^[<>] ${TAB}ENVELOPE\\.[^${TAB}]*\\.[0-9][0-9][0-9][0-9][0-9]${TAB}/&${TAB}/" < parse_cuprodigy_io.out.2 | grep -v -e "^[<>] ${TAB}ENVELOPE${TAB}[^${TAB}]" -e "^[<>] ${TAB}ENVELOPE\\.[^${TAB}]*${TAB}[^${TAB}]" | sed "s/\\.[0-9][0-9][0-9][0-9][0-9]${TAB}${TAB}/${TAB}/" | sed "s/${TAB}${TAB}/${TAB}/" | /home/cuprodigy/ADMIN/columnize.pl --pass-thru-comments --save-blank-lines --strip-trailing-spaces > parse_cuprodigy_io.out.5
