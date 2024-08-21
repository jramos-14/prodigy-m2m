# File: transaction_amount_exceeds_payoff.sh
# Gary Jay Peters
# 2010-04-15

# So, the CUSA/FiServ was having problems rejecting LP because it incorrectly
# thought that the transaction amount exceeded the payfoff; I manually used this
# script to daily check for LP failures, so that I could let Daryl at CCU know
# to contact the member and confirm if they still wanted the LP to occur.
#
# The problem was realized on 2010-04-15, and reported as fixed by CUSA/FiServ
# on 2010-04-29; though I had continued to look for a few weeks just to make
# sure that the problem was resolved.

cd /home/cusafiserv/ADMIN
grep -v '	$' q_trn.log | cut -f 1,5,6,7,8,10 | grep -e "	LP	" | sed 's/CUSA FiServ core: 1120 - //' | ./columnize.pl | cut -c 7-999 | sed 's/   LP   /   /' | cut -c 1-152
