# File: /home/cuprodigy/ADMIN/parse_cuprodigy_io_all+.sh
# Gary Jay Peters
# 2014-11-07

TAB="	"

# Support script for "parse_cuprodigy_io.sh" that simply runs the script for
# each and every file instead of just the default "*.0" file.

ls | grep -e '^[0-9][0-9]*\.[0-9][0-9]*$' | while read file ; do # {
	if [ -f "${file}" ] ; then # {
		file2=""
		ext=`echo "${file}" | sed 's/^.*\.//'`
		/home/cuprodigy/ADMIN/parse_cuprodigy_io.sh ${file}
		for x in `ls | grep -e '^parse_cuprodigy_io\.out\.[0-9]*'` ; do # {
			mv ${x} all.${ext}.${x}
			touch -r "${file}" all.${ext}.${x}
			case "${x}" in # {
			    (*.out.2)	file2="all.${ext}.${x}" ;;
			esac # }
		done # }
		if [ "" != "${file2}" ] ; then # {
			seq_regexp=`grep '^[<>] '"${TAB}"'Envelope\.[0-9][0-9]*\.Body\.[0-9][0-9]*\.' "${file2}" | head -n 1 | cut -d . -f 2 | sed 's/[0-9]/[0-9]/g'`
			(
				cat "${file2}"
			) | (
				sed '/^[<>] '"${TAB}"'/{ /^[<>] '"${TAB}"'Envelope\.[0-9][0-9]*\.Body\.[0-9][0-9]*\./!d; }' | \
				sed '/^[<>] '"${TAB}"'Envelope\./{ /\.[0-9][0-9]*'"${TAB}"'/!d; }'
			) >  ${file2}.A
			(
				cat "${file2}".A
			) | (
				grep -v '^[<>] '"${TAB}"'Envelope\.[0-9][0-9]*\.Body\.[0-9][0-9]*\..*'"${TAB}"'$'
			) > "${file2}".B
			(
				cat "${file2}".B
			) | (
				sed '/^[<>] '"${TAB}"'Envelope\./{ s/Envelope/<&/; s/\.'"${seq_regexp}"'\./></g; s/\.'"${seq_regexp}${TAB}"'/>'"${TAB}"'/; }'
			) > "${file2}".C
			touch -r "${file2}" "${file2}".A "${file2}".B "${file2}".C
		fi # }
	fi # }
done # }
