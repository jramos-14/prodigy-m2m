# File: cusafiserv_hist_pending_raw_io_recording.sh 
# Gary Jay Peters
# 2011-01-11

# Search the CUSAFISERV_IO_RECORDING for special "Pending" transaction history
# records.

# Normlly, the CUSA/FiServ interface is configured where transaction codes for
# pending transactions (such as "PA") have the special description "Pending"
# (the default for "PA" appears to be "ATM Payment" rather than "Pending").

USAGE="${0}"

TAB="	"

cd /home/cusafiserv/ADMIN/CUSAFISERV_IO_RECORDING || exit ${?}
find . -type f -name "[0-9]*.[0-9]" -exec grep -c -i -e "TransactionID>[0-9][0-9][0-9][0-9][0-9][0-9]235959[0-9][0-9][0-9][0-9][0-9][0-9][0-9]<" -e "TransactionCode>Pending<" {} /dev/null \; | grep -v ':0$'
