# File: find_new_scripts.sh
# Gary Jay Peters
# 2010-08-25

# Find new scripts by mtime and then copy them to a designated directory so that
# they can be compared.
#
# Development and enhancement and testing of a core interface often results in
# the creation of new tools (scripts) or the improvement of old tools (scripts).
# And the testing often involves cloning entire directories, and only creating
# or modifying scripts in some (not all) of those clones.
#
# But when the project is done then how do we identify those scripts that we
# might want for later use?  Well, that is what this script is for, to aid in
# the identification and comparison of newly created scripts and old scripts
# that have been recently modified; it finds those files and copies them into
# a destination directory so that they can be easily compared.

USAGE="${0} destination-directory number-of-days dir1 [ ... dirN]"

TAB="	"

LC_COLLATE="C" ; export LC_COLLATE

CONF__SEQUENCE_ORDER_BY="mtime"

func_abort(){ errno="${1}" ; shift ; echo "$@" 1>&2 ; exit ${errno} ; }

ARG__DESTINATION_DIR=""
ARG__MTIME_DAYS=""
while [ $# -gt 0 ] ; do # {
	case "${1}" in -*) true ;; *) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    --help)	func_abort 0 "USAGE: ${USAGE}" ;;
	    *)		func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -lt 3 ] && func_abort 22 "USAGE: ${USAGE}"
ARG__DESTINATION_DIR="${1}" ; shift
ARG__MTIME_DAYS="${1}" ; shift
[ `echo " ${ARG__MTIME_DAYS}" | sed 's/^ //' | grep -c -e '^[0-9][0-9]*$'` -ne 1 ] && func_abort 22 "USAGE: ${USAGE}"
[ -e "${ARG__DESTINATION_DIR}" ] && func_abort 17 "${0}: Already exists: ${ARG__DESTINATION_DIR}"
parent_dir=`dirname "${ARG__DESTINATION_DIR}"`
[ ! -d "${parent_dir}" ] && func_abort 17 "${0}: Directory does not exist: ${parent_dir}"

mkdir "${ARG__DESTINATION_DIR}" || func_abort ${?} "${0}: Can not mkdir(): ${ARG__DESTINATION_DIR}"

(
	find ${@} -type f -mtime -${ARG__MTIME_DAYS} \( -name "*.sh" -o -name "*.pl" -o -name "*.si" -o -name "*.pi" \) -print | sort | \
	while read file ; do # {
		timestamp=`date '+%Y%m%d%H%M%S' -r "${file}"`
		echo "${timestamp}${TAB}${file}"
	done # }
) | sort > "${ARG__DESTINATION_DIR}/_.list_by_mtime"

(
	cut -f 2-999 < "${ARG__DESTINATION_DIR}/_.list_by_mtime" | sort
) > "${ARG__DESTINATION_DIR}/_.list_by_path"

(
	sequence=0
	(
		case "${CONF__SEQUENCE_ORDER_BY}" in # {
		    (mtime)	cut -f 2-999 "${ARG__DESTINATION_DIR}/_.list_by_mtime" ;;
		    (path)	cat "${ARG__DESTINATION_DIR}/_.list_by_path" ;;
		    (*)		cut -f 2-999 "${ARG__DESTINATION_DIR}/_.list_by_mtime" ;;
		esac # }
	) | \
	while read file ; do # {
		sequence=`expr ${sequence} + 1 | sed 's/^/000000/; s/......$/ &/; s/^.* //'`
		basename=`basename "${file}"`
		echo "${basename}.${sequence}${TAB}${file}"
		cp -p "${file}" "${ARG__DESTINATION_DIR}/${basename}.${sequence}"
	done # }
) > "${ARG__DESTINATION_DIR}/_.log"

(
	cat "${ARG__DESTINATION_DIR}/_.log" | sed "s/\\.[0-9][0-9][0-9][0-9][0-9][0-9]${TAB}.*$//" | sort | uniq | \
	while read file ; do # {
		echo -n "${file}"
		(
			cat "${ARG__DESTINATION_DIR}/_.log" | grep -e "^${file}\.[0-9][0-9][0-9][0-9][0-9][0-9]${TAB}" | sed "s/^.*\\.[0-9][0-9][0-9][0-9][0-9][0-9]${TAB}//" | sort | uniq | \
			while read origfile ; do # {
				dir=`dirname "${origfile}"`
				echo -n "${TAB}${dir}"
			done # }
		)
		echo
	done # }
) > "${ARG__DESTINATION_DIR}/_.xref"

(

	prev_origfile=""
	cat "${ARG__DESTINATION_DIR}/_.log" | sed "s/${TAB}.*$//" | sort | uniq | \
	while read file ; do # {
		origfile=`echo "${file}" | sed 's/\.[0-9][0-9][0-9][0-9][0-9][0-9]$//'`
		[ "x${prev_origfile}" != "x" -a "x${prev_origfile}" != "x${origfile}" ] && echo
		prev_origfile="${origfile}"
		sum_r=`sum -r ${ARG__DESTINATION_DIR}/${file}`
		echo "${sum_r}${TAB}${file}"
	done # }
) > "${ARG__DESTINATION_DIR}/_.sum_r"
