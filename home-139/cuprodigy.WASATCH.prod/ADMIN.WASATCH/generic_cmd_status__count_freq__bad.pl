#!/usr/bin/perl
# File: generic_cmd_status__count_freq__bad.pl
# Gary Jay Peters
# 2010-11-04

# Parse the TAB delimited output of "generic_cmd_status__count_good_bad.sh"
# producing a weighted frequency count for occurances of "bad" entries.

# CAUTION: Remember that the STDOUT from "generic_cmd_status.sh" is the STDIN to
# CAUTION> "generic_cmd_status__count_good_bad.sh", so the complete series of
# CAUTION> piped I/O commands probably like:
# CAUTION>    ./generic_cmd_status.sh | \
# CAUTION>        ./generic_cmd_status__count_good_bad.sh | \
# CAUTION>            ./generic_cmd_status__count_freq__bad.pl

# The results are grouped by a composite of YYYY-MM and HH:MM, and for important
# reasons.
#
# The 1st level grouping by YYYY-MM allows group behavior to be summarized at
# the month level, which is more useful than grouping either without the month
# level (no YYYY-MM would be unable to isolate short-term malfunctions from the
# past) or with the day level (YYYY-MM-DD would be too fine to see a day-to-day
# recurring pattern).
#
# The 2nd level grouping by HH:MM allows group behavior to be summarized at the
# minute level, which is more useful than grouping at either at the hour level
# (HH would be too course with not enough detail) or at the second level
# (HH:MM:SS would be too fine with too much detail).

# The results are grouped by a composite of YYYY-MM and HH:MM.  Grouping by
# YYYY-MM allows group behavior to be reset every month, which is useful for
# isolating short-term malfunctions.  Grouping by HH:MM allows group behavior
# to be summarized at the minute level, which is more useful than grouping at
# either the hour level (HH would be too course with not enough detail) or the
# second level (HH:MM:SS would be too fine with too much detail).
#
# The STDOUT stream contains frequency counts without sub-group by error text.
#
# The STDERR stream contains frequency counts with sub-group by error text.
#
# Suggested usage depends on how extreme do you want the down-time recurring
# pattern to be.  Using the output from "generic_cmd_status__count_good_bad.sh"
# as input, for no filtering use the command:
#	generic_cmd_status__count_freq__bad.pl 2> /dev/null
# for minimal filtering use the commands:
#	generic_cmd_status__count_freq__bad.pl 2> /dev/null | \
#	    grep -v -e '^ *1[^0-9]'
# for avarage filtering use the commands:
#	generic_cmd_status__count_freq__bad.pl 2> /dev/null | \
#	    grep -v -e '^ *[12][^0-9]'
# for agressive filtering use the commands:
#	generic_cmd_status__count_freq__bad.pl 2> /dev/null | \
#	    grep -v -e '^ *[123][^0-9]'

$CONF__SUM_EACH_MINUTE_USING_TOTAL_FOR_GROUP=0;

while(defined($line=<STDIN>)){
	$line=~s/[\r\n][\r\n]*$//;
	($count,$status,$beg,$end,$text)=split(/\t/,${line},5);
	next if ${status} ne "bad";
	$yyyymmddhhmm_beg=substr(${beg},0,12);
	$yyyymmddhhmm_end=substr(${end},0,12);
	while(${yyyymmddhhmm_beg} le ${yyyymmddhhmm_end}){
		$group="YYYY-MM=".substr(${yyyymmddhhmm_beg},0,4)."-".substr(${yyyymmddhhmm_beg},4,2).",HH:MM=".substr(${yyyymmddhhmm_beg},8,2).":".substr(${yyyymmddhhmm_beg},10,2);
		if(${CONF__SUM_EACH_MINUTE_USING_TOTAL_FOR_GROUP}){
			# Result is skewed high by large number of requests over extended period of failure.
			$WEIGHTED{${group},${text}}+=sprintf("%.0f",${count});
			$WEIGHTED{${group},""}+=sprintf("%.0f",${count});
		}else{
			# Result may be skewed low, but is probably more useful for a realistic comparison.
			$WEIGHTED{${group},${text}}++;
			$WEIGHTED{${group},""}++;
		}
		$dd=substr(${yyyymmddhhmm_beg},6,2);
		$hh=substr(${yyyymmddhhmm_beg},8,2);
		$mm=substr(${yyyymmddhhmm_beg},10,2);
		$mm=sprintf("%02.0f",${mm}+1);
		if(${mm} >= 60){
			$mm="00";
			$hh=sprintf("%02.f0",${hh}+1);
			if(${hh} >= 24){
				$dd=sprintf("%02.f0",${dd}+1);
				$dd=substr(${yyyymmddhhmm_end},6,2);
				substr(${yyyymmddhhmm_beg},0,8)=substr(${yyyymmddhhmm_end},0,8);
			}
		}
		substr(${yyyymmddhhmm_beg},6,6)="${dd}${hh}${mm}";
	}
}

foreach $key (sort(keys(%WEIGHTED))){
	@f=split(/$;/,${key});
	if($f[1] eq ""){
		print STDOUT sprintf("%7.0f\t%s\t%s\n",$WEIGHTED{${key}},$f[0],$f[1]);
	}else{
		print STDERR sprintf("%7.0f\t%s\t%s\n",$WEIGHTED{${key}},$f[0],$f[1]);
	}
}
