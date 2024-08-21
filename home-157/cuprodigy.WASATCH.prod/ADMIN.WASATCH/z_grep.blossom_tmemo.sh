#!/bin/bash
# File: z_grep.blossom_tmemo.sh
# Gary Jay Peters
# 2023-03-22

# On a 2023-03-17 meeting with Brayan Quitian, when I asked about why what
# Brayan was showing me about the "fee" problem did not also show the full
# transaction description from the INQ/Inquiry request, which lead to the
# "tmemo" value typed by members, and how Blossom is not passing that value in
# the URL (instead passing a "Batch Id:[###]" or a "Trx Id:[###]") and that
# the "tmemo" value is only being kept on the Blossom server.
#
# As I have explained to Amy and Cerise, this will screw-up printed statements.

# fgrep '	TRN	' requests.log | cut -f 1,2,14 | grep -v '	 *$'

cat `ls -tr dmshomecucuprodigy.log*` | fgrep '  Command: TRN: ' | sed 's/  /	/; s/  /	/; s/  /	/; s/TRN: /TRN:	/' | cut -f 1,2,14 | grep -v '	 *$'
