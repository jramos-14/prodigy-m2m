# File: scan_idte+.sh

# To see if HarlandFS has fixed the problem, scan ALL members for the occurance
# "Internal data transalation error(AcctInfo)", which will end up as 
# "099"/"SYSTEM TEMPORARILY UNAVALIABLE".

TAB="	"

find /home/harlandfs/ADMIN/HARLANDFS_IO_RECORDING -type f -name "0*.0" -exec fgrep -i -e "<Description>Internal data transalation error" /dev/null {} \; | sed 's/:.*$//; s#^.*/##; s/\.[0-9]$//' | sort -n | sed 's/^00*//'
