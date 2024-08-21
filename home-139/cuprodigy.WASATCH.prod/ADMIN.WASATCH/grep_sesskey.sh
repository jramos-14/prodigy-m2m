func_cat_logs(){ cat dmshomecuharlandfs.logO dmshomecuharlandfs.log 2> /dev/null ; }

func_cat_logs | cut -d " " -f 5 | sort | uniq | while read pid ; do
	func_cat_logs | fgrep "  ${pid}  " | head -1
done | sort | cut -d " " -f 5 | while read pid ; do # {
	func_cat_logs | fgrep -e "  ${pid}  " | fgrep -e "<SESSKEY>=" -e " Command: "
	echo "==="
done # }
