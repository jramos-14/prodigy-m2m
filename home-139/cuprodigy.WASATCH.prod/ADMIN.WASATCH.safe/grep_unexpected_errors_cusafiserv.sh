# File: grep_unexpected_errors_cusafiserv.sh

TAB="	"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

logfile_std_prefix="^[0-9][0-9]*  [0-9][0-9]*  [0-9][0-9]*"

func_expected_dmshomecucusafiserv_entries(){
	grep -v \
		-e "${logfile_std_prefix}  Start process " \
		-e "${logfile_std_prefix}  Process arguments used: " \
		-e "${logfile_std_prefix}  Process source version: " \
		-e "${logfile_std_prefix}  Input closed\." \
		-e "${logfile_std_prefix}  Also detecting new PID *\." \
		-e "${logfile_std_prefix}  Stop process " \
		-e "${logfile_std_prefix}  Invalid AccountNumber format\$" \
		-e "${logfile_std_prefix}  Invalid Format: AccountNumber and/or PIN\$" \
		-e "${logfile_std_prefix}  Checking for distantly related process ([0-9][0-9]*)\.\$" \
		-e "${logfile_std_prefix}  Killing distantly related process ([0-9][0-9]*)\.\$" \
		-e "${logfile_std_prefix}  Shutdown: Life Cycle reached Maximum Time\.\$" \
		-e "${logfile_std_prefix}  Shutdown: Life Cycle reached Maximum Requests\.\$" \
		-e "${logfile_std_prefix}  Shutdown: Stop/Restart until [0-9]" \
		-e "${logfile_std_prefix}  Renaming expired Run/Stop/Restart file " \
		-e "${logfile_std_prefix}  Trapped signal SIGUSR1\.\$" \
		-e "${logfile_std_prefix}  Stacking error 099 for later use\.\$" \
		-e "${logfile_std_prefix}  Output closed\.\$" \
		-e "${logfile_std_prefix}  KNOWN LIMITATION: " \
		-e "${logfile_std_prefix}  Custom Included: " \
		-e "${logfile_std_prefix}  Custom Not Included: " \
		-e "${logfile_std_prefix}  Using " \
		-e "${logfile_std_prefix}  STATE BLOCKING: " \
		-e "${logfile_std_prefix}  Using Service Set ID: " \
		-e "${logfile_std_prefix}  Intializing " \
		-e "${logfile_std_prefix}  Waiting for request\." \
		-e "${logfile_std_prefix}  Command: " \
		-e "${logfile_std_prefix}  Syncronize\." \
		-e "${logfile_std_prefix}  .* Status Tag Block: .*${TAB}000${TAB}NO ERROR" \
		-e "${logfile_std_prefix}  Transaction: " \
		-e "${logfile_std_prefix}  TRANSACTION Status Tag Block: .*${TAB}[0-9][0-9][0-9]${TAB}" \
		-e "${logfile_std_prefix}  .* Transfer: Response: Failure in .*='1120' " \
		-e "${logfile_std_prefix}  CrossAccount: " \
		-e "${logfile_std_prefix}  Inquiry: " \
		-e "${logfile_std_prefix}  Member Overrides" \
		-e "${logfile_std_prefix}  DP History " \
		-e "${logfile_std_prefix}  LN History " \
		-e "${logfile_std_prefix}  CC History " \
		-e "${logfile_std_prefix}  Query [0-9]" \
		-e "${logfile_std_prefix}  Output [0-9]"
}

func_common_FiServ_errors(){
	grep -v \
		-e "${logfile_std_prefix}  cusafiserv_xml_balances(): CUSA FiServ core: Failed using method: AccountList: Response: Failure in XML body <FIAPI><RESPONSE><STATUS> where <STATUSCODE>='1120' and <STATUSDESC>='No Records match selection criteria'." \
		-e "${logfile_std_prefix}  cusafiserv_xml_member_verification(): CUSA FiServ core: Failed using method: MemberVerification: fiHeader: Failure in XML body <FIAPI><FIHEADER><SERVICE><STATUS> where <STATUSCODE>='100' and <STATUSDESC>='.* is longer than maximum of 4'." \
		-e "${logfile_std_prefix}  cusafiserv_xml_member_verification(): CUSA FiServ core: Failed using method: MemberVerification: Response: Failure in XML body <FIAPI><RESPONSE><STATUS> where <STATUSCODE>='1120' and <STATUSDESC>='No Records match selection criteria'."
}

func_common_DMS_Status_Tag_Blocks(){
	grep -v \
		-e "${TAB}001${TAB}INVALID ACCOUNT NUMBER\$"
}

cd /home/cusafiserv/ADMIN || func_abort $? "${0}: Can not chdir(): /home/cusafiserv/ADMIN"
ls -tr | grep -e "^dmshomecucusafiserv.log" | grep -v -e '\.lock$' | \
while read file ; do # {
	[ ! -f "${file}" ] && continue
	echo "Scanning: ${file}" 1>&2
	cat ${file} | \
	func_expected_dmshomecucusafiserv_entries | \
	func_common_FiServ_errors | \
	func_common_DMS_Status_Tag_Blocks
done # }
