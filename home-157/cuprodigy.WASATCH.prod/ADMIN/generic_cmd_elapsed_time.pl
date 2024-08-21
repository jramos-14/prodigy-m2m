#!/usr/bin/perl
# File: generic_cmd_elapsed_time.pl
# Gary Jay Peters
# 2010-04-21

# Most of the DMS I/A interfaces written by GJP have share a normalized format
# of the "ADMIN/dmshomecu*.log" file; hence this script can use that normalcy as
# it parses STDIN (redirect data from "ADMIN/dmshomecu*.log*") to calculate
# elapsed time, printing to STDOUT the individual command times and to STDERR a
# summary report (grouped using $CONF__SUMMARY_GROUP_BY);

# Try a command like:
#	cat d*.logO d*.log | ./generic_cmd_elapsed_time.pl > rpt.out 2> rpt.err
# or:
#	cat `ls -tr d*.logO* d*.log` | ./generic_cmd_elapsed_time.pl > rpt.out 2> rpt.err

# Argument '--as-simple-status' is intended for use by "generic_cmd_status.sh"
# (but you can use '--as-simple-status' if it produces results that you want).

# Argument '--no-sort' prevents the output from being resorted to match the
# sequence of the input (saving CPU and RAM resources).

# Argument '--wide-sequence' is used when input lines are expected to exceed the
# default of 9999999 (the limit of the "%07.0f" format).  Usage is not critical,
# rather it just ensures consistant formatting ("%011.0f") of the input line
# number across the entire sequence range.  The '--wide-sequence' has no affect
# on '--as-simple-status' (hence they are exclusive).

# NOTE: Detecting the ending time (successfull completion or termination abort)
# NOTE> would have been easier if all of the log entries resulting in an abort
# NOTE> had been begun with the common prefix "Abort," (or "Exit," when normal),
# NOTE> and if all of the log entries resulting in a completion had begun with
# NOTE> the common prefix "Complete,".  Maybe the existing interfaces will
# NOTE> eventually mature to that level of normalcy.

$USAGE="${0} [--pass-data-format-exceptions] [--ignore-data-format-exceptions] [--no-sort] [--as-simple-status] [--as-simple-status-with-elapsed] [--wide-sequence] [--timestamp-range yyyymmddhhmmss yyyymmddhhmmss]";

$CONF__SUMMARY_GROUP_BY__TEXT="YYYYMMDDHH";

$CONF__SIMPLE_STATUS__HANGING_AT_EOF__MAX_SECONDS_FOR_WORKING=sprintf("%.0f",6*60);

if    (${CONF__SUMMARY_GROUP_BY__TEXT} eq ""){
	$CONF__SUMMARY_GROUP_BY__BEG=0;
	$CONF__SUMMARY_GROUP_BY__LEN=0;
}elsif(index("YYYYMMDDHHMMSS",${CONF__SUMMARY_GROUP_BY__TEXT}) >= 0){
	$CONF__SUMMARY_GROUP_BY__BEG=index("YYYYMMDDHHMMSS",${CONF__SUMMARY_GROUP_BY__TEXT});
	$CONF__SUMMARY_GROUP_BY__LEN=length(${CONF__SUMMARY_GROUP_BY__TEXT});
}else{
	die("${0}: Invalid configuration of \$CONF__SUMMARY_GROUP_BY__TEXT.\n");
}

$ARG__PASS_DATA_FORMAT_EXCEPTIONS=0;
$ARG__IGNORE_DATA_FORMAT_EXCEPTIONS=0;
$ARG__NO_SORT=0;
$ARG__AS_SIMPLE_STATUS=0;
$ARG__AS_SIMPLE_STATUS_WITH_ELAPSED=0;
$ARG__WIDE_SEQUENCE=0;
$ARG__TIMESTAMP_RANGE_BEG="";
$ARG__TIMESTAMP_RANGE_END="";
while(@ARGV > 0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV); $arg=~s/^-//;
	while($arg ne ""){
		if    ($arg =~ /^-help$/){
			$arg="";
			die("USAGE: ${USAGE}\n");
		}elsif($arg =~ /^-pass-data-format-exceptions$/){
			$arg="";
			$ARG__PASS_DATA_FORMAT_EXCEPTIONS=1;
		}elsif($arg =~ /^-ignore-data-format-exceptions$/){
			$arg="";
			$ARG__IGNORE_DATA_FORMAT_EXCEPTIONS=1;
		}elsif($arg =~ /^-no-sort$/){
			$arg="";
			$ARG__NO_SORT=1;
		}elsif($arg =~ /^-as-simple-status$/){
			$arg="";
			$ARG__AS_SIMPLE_STATUS=1;
		}elsif($arg =~ /^-as-simple-status-with-elapsed$/){
			$arg="";
			$ARG__AS_SIMPLE_STATUS_WITH_ELAPSED=1;
		}elsif($arg =~ /^-wide-sequence$/){
			$arg="";
			$ARG__WIDE_SEQUENCE=1;
		}elsif($arg =~ /^-timestamp-range$/){
			$arg="";
			die("USAGE: ${USAGE}\n") if @ARGV < 2;
			$ARG__TIMESTAMP_RANGE_BEG=shift(@ARGV);
			$ARG__TIMESTAMP_RANGE_END=shift(@ARGV);
			die("${0}: Argument '--timestamp-range' 1st qualifier not in YYYYMMDDHHMMSS format: ${ARG__TIMESTAMP_RANGE_BEG}\n") if $ARG__TIMESTAMP_RANGE_BEG !~ /^\d{14}$/;
			die("${0}: Argument '--timestamp-range' 2nd qualifier not in YYYYMMDDHHMMSS format: ${ARG__TIMESTAMP_RANGE_END}\n") if $ARG__TIMESTAMP_RANGE_END !~ /^\d{14}$/;
			if(${ARG__TIMESTAMP_RANGE_BEG} gt ${ARG__TIMESTAMP_RANGE_END}){
				($ARG__TIMESTAMP_RANGE_BEG,$ARG__TIMESTAMP_RANGE_END)=(${ARG__TIMESTAMP_RANGE_END},${ARG__TIMESTAMP_RANGE_BEG});
			}
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
}
die("USAGE: ${USAGE}\n") if @ARGV > 0;
die("${0}: Arguments '--pass-data-format-exceptions' and '--ignore-data-format-exceptions-with-elapsed' are exclusive.\n") if ${ARG__PASS_DATA_FORMAT_EXCEPTIONS} and ${ARG__IGNORE_DATA_FORMAT_EXCEPTIONS};
die("${0}: Arguments '--as-simple-status' and '--wide-sequence' are exclusive.\n") if ${ARG__AS_SIMPLE_STATUS} and ${ARG__WIDE_SEQUENCE};
die("${0}: Arguments '--as-simple-status-with-elapsed' and '--wide-sequence' are exclusive.\n") if ${ARG__AS_SIMPLE_STATUS_WITH_ELAPSED} and ${ARG__WIDE_SEQUENCE};
die("${0}: Arguments '--as-simple-status' and '--as-simple-status-with-elapsed' are exclusive.\n") if ${ARG__AS_SIMPLE_STATUS} and ${ARG__AS_SIMPLE_STATUS_WITH_ELAPSED};

if(${ARG__AS_SIMPLE_STATUS_WITH_ELAPSED}){ $ARG__AS_SIMPLE_STATUS=1; }

if(${ARG__NO_SORT}){
	open(OUTPUT_SORT,"| cut -f 2-999") || die("${0}: Can not popen for write: cut -f 2-999\n");
}else{
	open(OUTPUT_SORT,"| sort | cut -f 2-999") || die("${0}: Can not popen for write: sort | cut -f 2-999\n");
}

while(defined($line=<STDIN>)){
	$line=~s/[\r\n][\r\n]*$//;
	if    ($line =~ /^\d{8,11}  \d{14}  \d{7}  Output \d\d*: Finished$/ or $line =~ /^\d{8,11}  \d{14}  \d{7}  Output \d\d* [A-Z][A-Z]*: Finished$/ or $line =~ /^\d{8,11}  \d{14}  \d{7}  Syncronize\.$/){
		$line=~s/  [A-Z].*$/  Waiting for request./;
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  Output closed\.$/){
		@f=split(/  /,$line,4);
		$PID{$f[2],"terminated"}="Aborting, Output closed";
		$PID{$f[2],"status"}=join(" | ","-","899","(Aborting, Output closed)");
		# $line=~s/  [A-Z].*$/  Waiting for request./;
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  Output \d\d*: Error$/){
		@f=split(/  /,$line,4);
		$PID{$f[2],"terminated"}="Aborting, Output error";
		$PID{$f[2],"status"}=join(" | ","-","899","(Aborting, Output error)");
		# $line=~s/  [A-Z].*$/  Waiting for request./;
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  [A-Z][A-Z]* Status Tag Block:/){
		@f=split(/  /,$line,4);
		$status_errno=(split(/\t/,$f[3]))[1];
		if($status_errno eq "000"){
			# Quirk of TRN where it always includes a status.
			$account=(split(/\t/,$f[3]))[0];
			$account=~s/^.*: //;
			$PID{$f[2],"status"}=join(" | ",${account},${status_errno},(split(/\t/,$f[3],3))[2]);
		}else{
			$PID{$f[2],"terminated"}="Status Error: ${status_errno}";
			$account=(split(/\t/,$f[3]))[0];
			$account=~s/^.*: //;
			$PID{$f[2],"status"}=join(" | ",${account},${status_errno},(split(/\t/,$f[3],3))[2]);
			$line=~s/  [A-Z].*$/  Waiting for request./;
		}
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  Stacking error \d\d* for later use/){
		@f=split(/  /,$line,4);
		$status_errno=$f[3]; $status_errno=~s/^.*Stacking error  *//; $status_errno=~s/ .*$//;
		$PID{$f[2],"terminated"}="Status Error: ${status_errno}";
		$PID{$f[2],"status"}=join(" | ","-",${status_errno},"(".$f[3].")");
		# $line=~s/  [A-Z].*$/  Waiting for request./;
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  Stop process / or $line =~ /^\d{8,11}  \d{14}  \d{7}  Trapped signal /){
		@f=split(/  /,$line,4);
		if    ($line =~/Stop process/){
			if($PID{$f[2],"terminated"} eq ""){
				$PID{$f[2],"terminated"}="Aborting, Stop process";
				$PID{$f[2],"status"}=join(" | ","-","899","(Aborting, Stop process)");
			}
			if($PID{$f[2],"command"} =~ /^QUIT$/i){
				$PID{$f[2],"terminated"}="";
				$PID{$f[2],"status"}="";
			}
		}elsif($line =~ /Trapped signal/){
			if($PID{$f[2],"terminated"} eq ""){
				$PID{$f[2],"terminated"}="Aborting, Trapped signal";
				$PID{$f[2],"status"}=join(" | ","-","899","(Aborting, Trapped signal)");
			}
		}
		$line=~s/  [A-Z].*$/  Waiting for request./;
		# Does not handle: /^\d{8,11}  \d{14}  \d{7}  Killing distantly related process \(\d\d*\)\./
	}
	if    ($line =~ /^\d{8,11}  \d{14}  \d{7}  Command: /){
		@f=split(/  /,$line,4);
		($command=$f[3])=~s/^Command:  *//;
		$PID{$f[2],"seconds"}=$f[0];
		$PID{$f[2],"timestamp"}=$f[1];
		$PID{$f[2],"pid"}=$f[2];
		$PID{$f[2],"sequence"}=$.;
		$PID{$f[2],"command"}=${command};
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  Waiting for request\.$/){
		@f=split(/  /,$line,4);
		if($PID{$f[2],"seconds"} ne ""){
			&process_completed_request($f[0],$f[1],$f[2],$.);
		}
		delete($PID{$f[2],"seconds"});
		delete($PID{$f[2],"timestamp"});
		delete($PID{$f[2],"pid"});
		delete($PID{$f[2],"sequence"});
		delete($PID{$f[2],"command"});
		delete($PID{$f[2],"terminated"});
		delete($PID{$f[2],"status"});
		delete($PID{$f[2],"lastseen_fields"});
		delete($PID{$f[2],"lastseen_sequence"});
	}elsif($line =~ /^\d{8,11}  \d{14}  \d{7}  /){
		@f=split(/  /,$line,4);
		if($PID{$f[2],"seconds"} ne ""){
			$PID{$f[2],"lastseen_fields"}=join("\t",@f);
			$PID{$f[2],"lastseen_sequence"}=$.;
		}
	}else{
		if    (${ARG__IGNORE_DATA_FORMAT_EXCEPTIONS}){
			1;
		}elsif(${ARG__PASS_DATA_FORMAT_EXCEPTIONS}){
			print STDERR "# ${0}: Unexpected data format at line $..\n";
		}else{
			die("${0}: Unexpected data format at line $..\n");
		}
	}
}

if(${HIGH_SECONDS} > 0){
	foreach $key (sort(keys(%PID))){
		($hanging_pid,$hanging_identifier)=split(/$;/,${key});
		next if ${hanging_identifier} ne "seconds";
		next if $PID{${hanging_pid},"lastseen_fields"} eq "";
		@f=split(/\t/,$PID{${hanging_pid},"lastseen_fields"},4);
		$f[3]=~s/\n/\\n/g;
		$f[3]=~s/\r/\\r/g;
		$f[3]=~s/\t/\\t/g;
		$hanging_elapsed=sprintf("%.0f",${HIGH_SECONDS}-$PID{${hanging_pid},"seconds"});
		if($PID{${hanging_pid},"terminated"} eq ""){
			if(${hanging_elapsed} <= ${CONF__SIMPLE_STATUS__HANGING_AT_EOF__MAX_SECONDS_FOR_WORKING}){
				$PID{${hanging_pid},"terminated"}=join(" | ","Incomplete by EOF, is possible that Middleware is still working on the command request.","Last saw: ".$f[3]);
				$PID{${hanging_pid},"status"}=join(" | ","-","899","(Incomplete by EOF, is possible that Middleware is still working on the command request)","Last saw: ".$f[3]);
			}else{
				$PID{${hanging_pid},"terminated"}=join(" | ","Incomplete by EOF, is probable that Middleware had terminated ungracefully while working on the command request.","Last saw: ".$f[3]);
				$PID{${hanging_pid},"status"}=join(" | ","-","899","(Incomplete by EOF, is probable that Middleware had terminated ungracefully while working on the command request)","Last saw: ".$f[3]);
			}
		}
		&process_completed_request($f[0],$f[1],$f[2],$PID{${hanging_pid},"lastseen_sequence"});
	}
}

close(OUTPUT_SORT);

foreach $key (sort(keys(%ELAPSED_SUMMARY_GROUP))){
	($command,$summary_group,$elapsed,$status)=split(/$;/,$key);
	$count=$ELAPSED_SUMMARY_GROUP{${key}};
	print STDERR join("\t",$command,$summary_group,$elapsed,sprintf("%7.0f",$count),$status),"\n";
}

sub process_completed_request{
   local($end_seconds,$end_timestamp,$end_pid,$end_sequence)=@_;
   local($command);
   local($elapsed);
   local($summary_group);
   local($use);
	if(${ARG__TIMESTAMP_RANGE_BEG} eq "" and ${ARG__TIMESTAMP_RANGE_END} eq ""){
		$use=1;
	}else{
		$use=0;
		if($PID{${end_pid},"timestamp"} ge ${ARG__TIMESTAMP_RANGE_BEG} and $PID{${end_pid},"timestamp"} le ${ARG__TIMESTAMP_RANGE_END}){
			$use=1;
		}
		if(${end_timestamp} ge ${ARG__TIMESTAMP_RANGE_BEG} and ${end_timestamp} le ${ARG__TIMESTAMP_RANGE_END}){
			$use=1;
		}
	}
	if(${use}){
		if(${HIGH_SECONDS} < $PID{${end_pid},"seconds"}){
			$HIGH_SECONDS=$PID{${end_pid},"seconds"};
		}
		if(${ARG__AS_SIMPLE_STATUS}){
			($command=$PID{${end_pid},"command"})=~s/\t/ | /g;
			if(${ARG__AS_SIMPLE_STATUS_WITH_ELAPSED}){
				$elapsed=sprintf("%.0f",${end_seconds}-$PID{${end_pid},"seconds"});
				if($PID{${end_pid},"status"} eq ""){
					print OUTPUT_SORT join("\t",
						sprintf("%011.0f",$PID{${end_pid},"sequence"}),
						$PID{${end_pid},"seconds"},
						$PID{${end_pid},"timestamp"},
						${end_timestamp},
						sprintf("%7.0f",${elapsed}),
						$PID{${end_pid},"pid"},
						${command}
					),"\n";
				}else{
					print OUTPUT_SORT join("\t",
						sprintf("%011.0f",$PID{${end_pid},"sequence"}),
						$PID{${end_pid},"seconds"},
						$PID{${end_pid},"timestamp"},
						${end_timestamp},
						sprintf("%7.0f",${elapsed}),
						$PID{${end_pid},"pid"},
						${command},
						$PID{${end_pid},"status"}
					),"\n";
				}
			}else{
				if($PID{${end_pid},"status"} eq ""){
					print OUTPUT_SORT join("\t",
						sprintf("%011.0f",$PID{${end_pid},"sequence"}),
						$PID{${end_pid},"seconds"},
						$PID{${end_pid},"timestamp"},
						$PID{${end_pid},"pid"},
						${command}
					),"\n";
				}else{
					print OUTPUT_SORT join("\t",
						sprintf("%011.0f",$PID{${end_pid},"sequence"}),
						$PID{${end_pid},"seconds"},
						$PID{${end_pid},"timestamp"},
						$PID{${end_pid},"pid"},
						${command},
						$PID{${end_pid},"status"}
					),"\n";
				}
			}
		}else{
			$elapsed=sprintf("%.0f",${end_seconds}-$PID{${end_pid},"seconds"});
			if(${ARG__WIDE_SEQUENCE}){
				print OUTPUT_SORT join("\t",
					sprintf("%011.0f",$PID{${end_pid},"sequence"}),
					$PID{${end_pid},"timestamp"},
					sprintf("%011.0f",$PID{${end_pid},"sequence"}),
					${end_timestamp},
					sprintf("%011.0f",${end_sequence}),
					sprintf("%7.0f",${elapsed}),
					${end_pid},
					$PID{${end_pid},"command"},
					$PID{${end_pid},"terminated"}
				),"\n";
			}else{
				print OUTPUT_SORT join("\t",
					sprintf("%011.0f",$PID{${end_pid},"sequence"}),
					$PID{${end_pid},"timestamp"},
					sprintf("%07.0f",$PID{${end_pid},"sequence"}),
					${end_timestamp},
					sprintf("%07.0f",${end_sequence}),
					sprintf("%7.0f",${elapsed}),
					${end_pid},
					$PID{${end_pid},"command"},
					$PID{${end_pid},"terminated"}
				),"\n";
			}
			($command=$PID{${end_pid},"command"})=~s/[:\s].*$//;
			$summary_group=substr($PID{${end_pid},"timestamp"},${CONF__SUMMARY_GROUP_BY__BEG},${CONF__SUMMARY_GROUP_BY__LEN});
			if($PID{${end_pid},"terminated"} eq ""){
				$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.0f",${elapsed}),"okay"}++;
				$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.7s","total"),"okay"}++;
			}else{
				if    ($PID{${end_pid},"terminated"} =~ /^Status Error: 001$|^Status Error: 002$|^Status Error: 003$/){
					# "001"/"INVALID ACCOUNT NUMBER"
					# "002"/"INVALID PASSWORD"
					# "003"/"ACCOUNT CLOSED"
					$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.0f",${elapsed}),"deny"}++;
					$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.7s","total"),"deny"}++;
				}elsif($PID{${end_pid},"terminated"} =~ /^Status Error: 009$/){
					# "009"/"CORE WORKING ON RETRIEVING CURRENT DATA"
					$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.0f",${elapsed}),"skip"}++;
					$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.7s","total"),"skip"}++;
				}else{
					$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.0f",${elapsed}),"fail"}++;
					$ELAPSED_SUMMARY_GROUP{${command},${summary_group},sprintf("%7.7s","total"),"fail"}++;
				}
			}
		}
	}
}
