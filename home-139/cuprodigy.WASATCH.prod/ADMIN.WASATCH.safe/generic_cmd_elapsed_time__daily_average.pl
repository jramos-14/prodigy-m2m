#!/usr/bin/perl
# File: generic_cmd_elapsed_time__daily_average.pl
# Gary Jay Peters
# 2010-12-17

# Calculate averages by day using elapsed INQ time from:
#	cat `ls -tr d*.logO* d*.log` | ./generic_cmd_elapsed_time.pl

$USAGE="${0} [--ignore-below-seconds=#] [--ignore-above-seconds=#] [--ignore-low-high-count=# [--ignore-low-high-percent=#]";


$ARG__IGNORE_BELOW_SECONDS="";
$ARG__IGNORE_ABOVE_SECONDS="";
$ARG__IGNORE_LOW_HIGH_COUNT="";
$ARG__IGNORE_LOW_HIGH_PERCENT="";
while(@ARGV>0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV); $arg=~s/^-//;
	while($arg ne ""){
		$arg=~s/^-ignore-before-seconds/-ignore-below-seconds/;
		$arg=~s/^-ignore-after-seconds/-ignore-above-seconds/;
		if    ($arg eq "-ignore-below-seconds" or $arg =~ /^-ignore-below-seconds=/){
			if($arg=~/-.*=/){ unshift(@ARGV,(split(/=/,${arg},2))[1]); }
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			$ARG__IGNORE_BELOW_SECONDS=shift(@ARGV);
			die("USAGE: ${USAGE}\n") if $ARG__IGNORE_BELOW_SECONDS !~ /^\d\d*$/;
			$ARG__IGNORE_BELOW_SECONDS=sprintf("%.0f",${ARG__IGNORE_BELOW_SECONDS});
		}elsif($arg eq "-ignore-above-seconds" or $arg =~ /^-ignore-above-seconds=/){
			if($arg=~/-.*=/){ unshift(@ARGV,(split(/=/,${arg},2))[1]); }
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			$ARG__IGNORE_ABOVE_SECONDS=shift(@ARGV);
			die("USAGE: ${USAGE}\n") if $ARG__IGNORE_ABOVE_SECONDS !~ /^\d\d*$/;
			$ARG__IGNORE_ABOVE_SECONDS=sprintf("%.0f",${ARG__IGNORE_ABOVE_SECONDS});
		}elsif($arg eq "-ignore-low-high-count" or $arg =~ /^-ignore-low-high-count=/){
			if($arg=~/-.*=/){ unshift(@ARGV,(split(/=/,${arg},2))[1]); }
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			$ARG__IGNORE_LOW_HIGH_COUNT=shift(@ARGV);
			die("USAGE: ${USAGE}\n") if $ARG__IGNORE_LOW_HIGH_COUNT !~ /^\d\d*$/;
			$ARG__IGNORE_LOW_HIGH_COUNT=sprintf("%.0f",${ARG__IGNORE_LOW_HIGH_COUNT});
		}elsif($arg eq "-ignore-low-high-percent" or $arg =~ /^-ignore-low-high-percent=/){
			if($arg=~/-.*=/){ unshift(@ARGV,(split(/=/,${arg},2))[1]); }
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			$ARG__IGNORE_LOW_HIGH_PERCENT=shift(@ARGV);
			die("USAGE: ${USAGE}\n") if $ARG__IGNORE_LOW_HIGH_PERCENT !~ /^\d\d*$/ and $ARG__IGNORE_LOW_HIGH_PERCENT !~ /^\d\d*\.\d*$/;
			$ARG__IGNORE_LOW_HIGH_PERCENT=sprintf("%.6f",${ARG__IGNORE_LOW_HIGH_PERCENT});
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
}
print STDOUT "IGNORE_BELOW_SECONDS\t${ARG__IGNORE_BELOW_SECONDS}\n" if ${ARG__IGNORE_BELOW_SECONDS} ne "";
print STDOUT "IGNORE_ABOVE_SECONDS\t${ARG__IGNORE_ABOVE_SECONDS}\n" if ${ARG__IGNORE_ABOVE_SECONDS} ne "";
print STDOUT "IGNORE_LOW_HIGH_COUNT\t${ARG__IGNORE_LOW_HIGH_COUNT}\n" if ${ARG__IGNORE_LOW_HIGH_COUNT} ne "";
print STDOUT "IGNORE_LOW_HIGH_PERCENT\t",&trim_percent(${ARG__IGNORE_LOW_HIGH_PERCENT}),"\n" if ${ARG__IGNORE_LOW_HIGH_PERCENT} ne "" and ${ARG__IGNORE_LOW_HIGH_COUNT} eq "";

open(INPUT,'cat `ls -tr d*.logO* d*.log` | ./generic_cmd_elapsed_time.pl 2>&1 1>/dev/null |') || die("${0}: Can not popen() for read: ".'cat `ls -tr d*.logO* d*.log` | ./generic_cmd_elapsed_time.pl 2>&1 1>/dev/null'."\n");

while(defined($line=<INPUT>)){
	$line=~s/[\r\n][\r\n]*$//;
	$line=~s/ //g;
	($group,$timestamp,$seconds,$count,$status)=split(/\t/,$line);
	next if ${group} ne "INQ";
	next if ${status} ne "okay";
	next if ${seconds} eq "total";
	$seconds=sprintf("%.0f",${seconds});
	$count=sprintf("%.0f",${count});
	next if ${ARG__IGNORE_BELOW_SECONDS} ne "" and ${seconds} < ${ARG__IGNORE_BELOW_SECONDS};
	next if ${ARG__IGNORE_ABOVE_SECONDS} ne "" and ${seconds} > ${ARG__IGNORE_ABOVE_SECONDS};
	$yyyymmdd=substr(${timestamp}."00000000",0,8);
	$fmt_seconds=sprintf("%011.0f",${seconds});
	$SECONDS{${yyyymmdd},${fmt_seconds}}=sprintf("%.0f",$SECONDS{${yyyymmdd},${fmt_seconds}}+sprintf("%.0f",${count}));
	$YYYYMMDD_COUNT{${yyyymmdd}}=sprintf("%.0f",$YYYYMMDD_COUNT{${yyyymmdd}}+sprintf("%.0f",${count}));
	$YYYYMMDD_WEIGHT{${yyyymmdd}}=sprintf("%.0f",$YYYYMMDD_WEIGHT{${yyyymmdd}}+sprintf("%.0f",sprintf("%.0f",${count})*sprintf("%.0f",${seconds})));
}

if((${ARG__IGNORE_LOW_HIGH_COUNT} ne "" and ${ARG__IGNORE_LOW_HIGH_COUNT} > 0) or (${ARG__IGNORE_LOW_HIGH_PERCENT} ne "" and ${ARG__IGNORE_LOW_HIGH_PERCENT} > 0)){
	foreach $key (sort(keys(%SECONDS))){
		@f=split($;,${key},2);
		$KEYS_SECONDS{$f[0]}.=$f[1]."\t";
	}
	foreach $yyyymmdd (sort(keys(%YYYYMMDD_COUNT))){
		if    (${ARG__IGNORE_LOW_HIGH_COUNT} ne "" and ${ARG__IGNORE_LOW_HIGH_COUNT} > 0){
			$ignore_count_below=sprintf("%.0f",${ARG__IGNORE_LOW_HIGH_COUNT});
			$ignore_count_above=sprintf("%.0f",${ARG__IGNORE_LOW_HIGH_COUNT});
		}elsif(${ARG__IGNORE_LOW_HIGH_PERCENT} ne "" and ${ARG__IGNORE_LOW_HIGH_PERCENT} > 0){
			$day_count=sprintf("%.0f",$YYYYMMDD_COUNT{${yyyymmdd}});
			$day_weight=sprintf("%.0f",$YYYYMMDD_WEIGHT{${yyyymmdd}});
			$fractional_remainder_for_6_decimal_places=substr("00"."000000".sprintf("%.0f",${day_count}*${ARG__IGNORE_LOW_HIGH_PERCENT}*1000000),-length("00"."000000"),length("00"."000000"));
			if(sprintf("%.0f",${fractional_remainder_for_6_decimal_places}) == 0){
				$round_up_to_next_integer=0;
			}else{
				$round_up_to_next_integer=1;
			}
			$ignore_count=sprintf("%.0f",sprintf("%.0f",sprintf("%.0f",sprintf("%.0f",${day_count})*${ARG__IGNORE_LOW_HIGH_PERCENT})/100)+${round_up_to_next_integer});
			$ignore_count_below=sprintf("%.0f",${ignore_count});
			$ignore_count_above=sprintf("%.0f",${ignore_count});
		}else{
			$ignore_count_below=sprintf("%.0f",0);
			$ignore_count_above=sprintf("%.0f",0);
		}
		$IGNORE_COUNT_BELOW{${yyyymmdd}}=${ignore_count_below};
		$IGNORE_COUNT_ABOVE{${yyyymmdd}}=${ignore_count_above};
		foreach $fmt_seconds (split(/\t/,$KEYS_SECONDS{${yyyymmdd}})){
			$count=sprintf("%.0f",$SECONDS{${yyyymmdd},${fmt_seconds}});
			$seconds=sprintf("%.0f",${fmt_seconds});
			while(${count}>0 and ${ignore_count_below}>0){
				$YYYYMMDD_COUNT{${yyyymmdd}}=sprintf("%.0f",$YYYYMMDD_COUNT{${yyyymmdd}}-1);
				$YYYYMMDD_WEIGHT{${yyyymmdd}}=sprintf("%.0f",$YYYYMMDD_WEIGHT{${yyyymmdd}}-${seconds});
				$SECONDS{${yyyymmdd},${fmt_seconds}}=sprintf("%.0f",$SECONDS{${yyyymmdd},${fmt_seconds}}-1);
				$count=sprintf("%.0f",${count}-1);
				$ignore_count_below=sprintf("%.0f",${ignore_count_below}-1);
			}
		}
		foreach $fmt_seconds (reverse(split(/\t/,$KEYS_SECONDS{${yyyymmdd}}))){
			$count=sprintf("%.0f",$SECONDS{${yyyymmdd},${fmt_seconds}});
			$seconds=sprintf("%.0f",${fmt_seconds});
			while(${count}>0 and ${ignore_count_above}>0){
				$YYYYMMDD_COUNT{${yyyymmdd}}=sprintf("%.0f",$YYYYMMDD_COUNT{${yyyymmdd}}-1);
				$YYYYMMDD_WEIGHT{${yyyymmdd}}=sprintf("%.0f",$YYYYMMDD_WEIGHT{${yyyymmdd}}-${seconds});
				$SECONDS{${yyyymmdd},${fmt_seconds}}=sprintf("%.0f",$SECONDS{${yyyymmdd},${fmt_seconds}}-1);
				$count=sprintf("%.0f",${count}-1);
				$ignore_count_above=sprintf("%.0f",${ignore_count_above}-1);
			}
		}
	}
}

$column_headers=join("\t",
	"YYYYMMDD",
	sprintf("%7.7s","Average"),
	sprintf("%7.7s","Seconds"),
	sprintf("%7.7s","Count"),
);
($column_underlines=${column_headers})=~s/[^\t]/-/g;

print STDOUT ${column_headers},"\n";
print STDOUT ${column_underlines},"\n";
foreach $yyyymmdd (sort(keys(%YYYYMMDD_COUNT))){
	if($YYYYMMDD_COUNT{${yyyymmdd}} > 0){
		print STDOUT join("\t",
			${yyyymmdd},
			sprintf("%7.2f",$YYYYMMDD_WEIGHT{${yyyymmdd}}/$YYYYMMDD_COUNT{${yyyymmdd}}),
			sprintf("%7.0f",$YYYYMMDD_WEIGHT{${yyyymmdd}}),
			sprintf("%7.0f",$YYYYMMDD_COUNT{${yyyymmdd}})
		),"\n";
	}
}
print STDOUT ${column_underlines},"\n";
print STDOUT ${column_headers},"\n";

sub trim_percent(){
   local($percent)=@_;
	if($percent !~ /./){ $percent.=".0"; }
	$percent=~s/0*$//;
	$percent=~s/\.$//;
	return(${percent});
}
