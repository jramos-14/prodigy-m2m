#!/usr/bin/perl
# File: generic_cmd_elapsed_time__order_by_member.pl
# Gary Jay Peters
# 2011-12-21

# Split out requests by member using:
#	cat `ls -tr d*.logO* d*.log` | \
#	    ./generic_cmd_elapsed_time.pl --as-simple-status-with-elapsed

# Argument "--pass-data-format-exceptions" is directly passed through for use
# as an "generic_cmd_elapsed_time.pl" argument.

# Argument "--cut-fields" allows you to limit which fields will be printed; a
# common "--cut-fields" qualifier is "2,4,6,7", which results in the output
# consisting of beginning timestamp, elapsed time, command, and status.

$USAGE="${0} [--pass-data-format-exceptions] [--cut-fields {1,2,3,4,5,6,7}] [mbnum1 [...mbnumN]]";


$ARG__PASS_DATA_FORMAT_EXCEPTIONS="";
$ARG__CUT_FIELDS=0; undef(%ARG__CUT_FIELDS); undef(@ARG__CUT_FIELDS);
while(@ARGV>0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV); $arg=~s/^-//;
	while($arg ne ""){
		if    ($arg eq "-help"){
			$arg="";
			die("USAGE: ${USAGE}\n");
		}elsif($arg eq "-pass-data-format-exceptions"){
			$arg="";
			$ARG__PASS_DATA_FORMAT_EXCEPTIONS="--pass-data-format-exceptions";;
		}elsif($arg eq "-cut-fields"){
			$arg="";
			$ARG__CUT_FIELDS=1;
			die("USAGE: ${USAGE}\n") if @ARGV < 1;
			$list=shift(@ARGV);
			die("USAGE: ${USAGE}\n") if $list eq "" or $list =~ /[^-,0-9]/;
			@f=split(/,/,${list});
			while(@f>0){
				$range=shift(@f);
				if($range=~/^\d\d*$/){ $range=${range}."-".${range}; }
				die("USAGE: ${USAGE}") if $range =~ /-.*-/;
				($range_low,$range_high)=split(/-/,${range});
				$range_low=sprintf("%.0f",${range_low});
				$range_high=sprintf("%.0f",${range_high});
				die("USAGE: ${USAGE}") if ${range_low} > ${range_high};
				for($digit=${range_low};$digit<=${range_high};$digit=sprintf("%.0f",${digit}+1)){
					die("USAGE: ${USAGE}") if ${digit} !~ /^[1234567]$/;
					$ARG__CUT_FIELDS{sprintf("%.0f",${digit}-1)}=1;
				}
			}
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
}
if(${ARG__CUT_FIELDS}){
	@ARG__CUT_FIELDS=(sort(keys(%ARG__CUT_FIELDS)));
}
if(@ARGV>0){
	$ARG__SELECT_MBNUM=1;
	while(@ARGV>0){
		$mbnum=shift(@ARGV);
		die("${0}: Argument value for 'mbnum' must be an integer.\n") if $mbnum !~ /^\d\d*$/;
		$ARG__SELECT_MBNUM{${mbnum}}=1;
	}
}

open(INPUT,'cat `ls -tr d*.logO* d*.log` | ./generic_cmd_elapsed_time.pl.99 --as-simple-status-with-elapsed ${ARG__PASS_DATA_FORMAT_EXCEPTIONS} |') || die("${0}: Can not popen() for read: ".'cat `ls -tr d*.logO* d*.log` | ./generic_cmd_elapsed_time.pl --as-simple-status-with-elapsed ${ARG__PASS_DATA_FORMAT_EXCEPTIONS}'."\n");

while(defined($line=<INPUT>)){
	$line=~s/[\r\n][\r\n]*$//;
	($beg_seconds,$beg_timestamp,$end_timestamp,$elapsed,$pid,$command,$status)=split(/\t/,$line,7);
	next if $command !~ /^INQ:|^XAC:|^TRN:/;
	($mbnum=${command})=~s/^[A-Z][A-Z]*:\s*//; $mbnum=~s/ \| .*$//; $mbnum=~s/ *$//;
	if(${ARG__SELECT_MBNUM}){
		if($ARG__SELECT_MBNUM{${mbnum}}){
			if(${ARG__CUT_FIELDS}){
				@f=split(/\t/,$line,7);
				$line=join("\t",@f[@ARG__CUT_FIELDS]);
			}
			$DATA{sprintf("%20.20s",${mbnum})}.=${line}."\n";
		}
	}else{
		if(${ARG__CUT_FIELDS}){
			@f=split(/\t/,$line,7);
			$line=join("\t",@f[@ARG__CUT_FIELDS]);
		}
		$DATA{sprintf("%20.20s",${mbnum})}.=${line}."\n";
	}
}

$count=0;
foreach $key (sort(keys(%DATA))){
	($mbnum=${key})=~s/^ *//;
	print "\n" if ${count} > 0; $count++;
	print STDOUT "# ${mbnum}\n";
	print $DATA{${key}};
}
