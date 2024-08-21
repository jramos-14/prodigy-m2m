# File: /home/cusafiserv/ADMIN/cusafiserv_inq_timed_out_members.sh
# Gary Jay Peters
# 2016-01-08

# Evaluate the "/home/cusafiserv/ADMIN/dmshomecucusafiserv.log*" files for the
# "Timed out communicating with core" failure.  The occurance of this failure
# likely indicates that CUSA/FiServ need to reconfigure "TomCat".

# This became a major issue when BUCKS moved into the CUSA/FiServ Data Center on
# 2015-08-03, where the "TomCat" was shared by multiple clients and the
# configuration of that "TomCat" was problematic for BUCKS's member data.

TAB="	"

cd /home/cusafiserv/ADMIN || exit ${?}

echo "Scanning log files ..." 1>&2
cat `ls -tr d*.log*` | grep -e ' INQ: ' -e 'INQUIRY Status Tag Block:.*Timed out communicating with the core' | grep -v -e '^[0-9][0-9]*  2015080[45]' > /tmp/cusafiserv_inq_timed_out_members.tmp

(
	fgrep 'Status Tag Block:' /tmp/cusafiserv_inq_timed_out_members.tmp | sed 's/^.*Status Tag Block: //' | cut -f 1 | sort -n | uniq 
) | (
	while read mbnum ; do # {
		echo "Processing member ${mbnum} ..." 1>&2
		if [ `grep -e "Status Tag Block: ${mbnum}[^0-9]" /tmp/cusafiserv_inq_timed_out_members.tmp | grep -v -e ' 20151025[0-9][0-9][0-9][0-9][0-9][0-9]  ' -e ' 20151026[0-9][0-9][0-9][0-9][0-9][0-9]  ' | wc -l` -gt 0 ] ; then # {
			echo "# MB: ${mbnum}"
			grep -e "INQ: ${mbnum}[^0-9]" -e "Status Tag Block: ${mbnum}[^0-9]" /tmp/cusafiserv_inq_timed_out_members.tmp
			echo
		fi # }
	done # }
) | sed "s/INQUIRY Status Tag Block: /FAIL: /; s/: fiHeader:.*\$//; s/${TAB}999${TAB}.*method: /${TAB}/" > /tmp/cusafiserv_inq_timed_out_members.tmpA
(
	echo 'g/^#/s/^/_/'
	echo 'g/^$/.-,.s/^/_/'
	echo 'g/FAIL:/.--,.s/^/_/'
	echo 'v/^_/d'
	echo '1,$s/^__*//'
	echo 'w'
	echo 'q'
) | ed /tmp/cusafiserv_inq_timed_out_members.tmpA > /dev/null 2>&1
cat /tmp/cusafiserv_inq_timed_out_members.tmpA ; rm -f /tmp/cusafiserv_inq_timed_out_members.tmpA

rm -f /tmp/cusafiserv_inq_timed_out_members.tmp
