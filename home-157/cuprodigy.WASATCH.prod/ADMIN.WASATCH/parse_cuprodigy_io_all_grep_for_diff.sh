# File: /home/cuprodigy/ADMIN/parse_cuprodigy_io_all_grep_for_diff.sh
# Gary Jay Peters
# 2007-12-21

# Support script for "parse_cuprodigy_io_all.sh" that further filters the I/O
# to strip out lines that are known to change with every call; this will allow
# the results to be "diff"ed.

echo "Not yet coded to grep for CUSA/FiServ XML tags!" 1>&2 ; exit 22

ls all.*.parse_cuprodigy_io.out.5 2> /dev/null | while read file ; do # {
	[ ! -f "${file}" ] && continue
	echo "Creating: g.${file}"
	cat ${file} | \
	grep -v \
		-e '^#' \
	| \
	grep -v \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTACCTUP ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTASOF ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTCLIENT ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTEND ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTPROFUP ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTSERVER ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.DTSTART ' \
		-e ' OFX\.[^ ][^ ]*\.[0-9][0-9][0-9][0-9][0-9]\.RECID ' \
	> g.${file}
done # }
