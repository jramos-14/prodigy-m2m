# File: generic_cmd_status__filter__cusafiserv_cusa.sh
# Gary Jay Peters
# 2010-11-01

# For use as "generic_cmd_status__count_good_bad.sh" argument "--filter-script"
# qualifier when evalating logs for a CUSA/FiServ interface using a CUSA core.

TAB="	"
(
	sed \
		-e "s/${TAB}[^${TAB}]* | 999 | CUSA FiServ core: 1120 - [^${TAB}]*\$//" \
		-e "s/${TAB}[^${TAB}]* | 999 | Error c: 1120 - [^${TAB}]*\$//" \
		-e "s/${TAB}[^${TAB}]* | 999 | CUSA FiServ core: Failed using method: [^${TAB}]*: 1120 - [^${TAB}]*$//" \
		-e "s/${TAB}[^${TAB}]* | 999 | Error c: Failed using method: [^${TAB}]*: 1120 - [^${TAB}]*$//" \
		-e "s/${TAB}[^${TAB}]* | 999 | CUSA FiServ core: Failed using method: [^${TAB}]* <STATUSCODE>='1120' [^${TAB}]*$//" \
		-e "s/${TAB}[^${TAB}]* | 999 | Error c: Failed using method: [^${TAB}]* <STATUSCODE>='1120' [^${TAB}]*$//"
) | cat
