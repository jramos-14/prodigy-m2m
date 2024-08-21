if [ $# -ne 1 ] ; then echo "USAGE: ${0} mbnum" 1>&2 ; exit 22 ; fi
(
	mbnum=`echo "000000000000${1}" | sed 's/[^0-9]//g; s/............$/ &/; s/^.* //'`
	path=`echo "${mbnum}" | sed 's#...$##; s#...#&/#g'`
	dir="CUPRODIGY_IO_RECORDING/${path}${mbnum}"
	if [ ! -d "${dir}" ] ; then # {
		echo "No directory: ${dir}" 1>&2
	else # } {
		admin=`dirname "${0}"` ; admin=`cd "${admin}" 2> /dev/null && pwd` ; export admin
		if [ `ls -d "${admin}"/parse_*_io.sh 2> /dev/null | wc -l` -eq 1 ] ; then # {
			parse_io=`ls -d "${admin}"/parse_*_io.sh 2> /dev/null` ; export parse_io
			if [ `ls -d "${admin}"/parse_*_io_all.sh 2> /dev/null | wc -l` -eq 1 ] ; then # {
				parse_io_all=`ls -d "${admin}"/parse_*_io_all.sh 2> /dev/null` ; export parse_io_all
			fi # }
			if [ `ls -d "${admin}"/parse_*_io_all_grep_for_diff.sh 2> /dev/null | wc -l` -eq 1 ] ; then # {
				parse_io_diff=`ls -d "${admin}"/parse_*_io_all_grep_for_diff.sh 2> /dev/null` ; export parse_io_diff
			fi # }
		fi # }
		cd "${dir}"
		if [ $? -ne 0 ] ; then #{
			echo "Failed chdir() to: ${dir}" 1>&2
		else # } {
			PS1="${mbnum}>> " ; export PS1
			echo 
			echo 'Use environment variable shortcuts: $parse_io, $parse_io_all, $parse_io_diff'
			echo 
			pwd
			ls -l
			echo "Type 'exit' to terminate subshell."
			sh
		fi # }
	fi # }
)
