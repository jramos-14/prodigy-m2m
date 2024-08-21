# File: /home/cuprodigy/ADMIN/parse_cuprodigy_io_all.sh
# Gary Jay Peters
# 2007-12-21

# Support script for "parse_cuprodigy_io.sh" that simply runs the script for
# each and every file instead of just the default "*.0" file.

ls | grep -e '^[0-9][0-9]*\.[0-9][0-9]*$' | while read file ; do # {
	if [ -f "${file}" ] ; then # {
		ext=`echo "${file}" | sed 's/^.*\.//'`
		/home/cuprodigy/ADMIN/parse_cuprodigy_io.sh ${file}
		for x in `ls | grep -e '^parse_cuprodigy_io\.out\.[0-9]*'` ; do # {
			mv ${x} all.${ext}.${x}
			touch -r "${file}" all.${ext}.${x}
		done # }
	fi # }
done # }
