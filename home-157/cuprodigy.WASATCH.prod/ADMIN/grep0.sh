func_input(){
	cat /home/cusafiserv/ADMIN/dmshomecucusafiserv.log
}

func_filter(){
	fgrep \
		-e "  Start process (" \
		-e "  Stop process (" \
		-e "  Waiting for request." \
		-e "  Command: " \
		-e " Status Tag Block: "
}

func_eval(){
    (
	start="";
	IFS=""
	while read line ; do # { 
		echo "${line}"
		case "${line}" in # {
		    *"  Start process "*)	sec_start="" ; sec_stop="" ;;
		    *"  Stop process "*)	sec_start="" ; sec_stop="" ;;
		    *"  Waiting for request."*) # {
			if [ "" != "${sec_start}" ] ; then # {
				sec_stop=`echo "${line}" | sed 's/ .*$//'`
				echo -n "Elapsed: "
				echo "${sec_stop} - ${sec_start}" | bc
			fi # }
			sec_start=""
			sec_stop=""
		    ;; # }
		    *"  Command: "*) # {
			sec_start=`echo "${line}" | sed 's/ .*$//'`
			sec_stop=""
		    ;; # }
		esac # }
	done # }
    )
}

func_input | func_filter | func_eval
