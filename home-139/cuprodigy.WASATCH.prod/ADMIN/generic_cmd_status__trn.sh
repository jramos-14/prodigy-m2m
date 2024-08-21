# File: generic_cmd_status__trn.sh
# Gary Jay Peters
# 2012-09-24

# Wrapper for "generic_cmd_status.sh" to extract just the TRN entries and
# show pass fail by type.

TAB="	"

./generic_cmd_status.sh | grep "${TAB}TRN:" | cut -f 2,4,5 | sed "s/TRN: [^|]*| //; s/ | .*${TAB}/${TAB}/"
