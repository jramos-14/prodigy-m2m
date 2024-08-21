#!/usr/bin/perl
# File: generic_cmd_elapsed_time_graph.pl
# Gary Jay Peters
# 2016-12-02

# Graph the STDERR from "generic_cmd_elapsed_time.pl".
#
# May be wise to pipe it to "columnize.pl | sed 's/ 0/  /g' | sed 's/ *$//'".
#
# May wish to further filter using "grep -e '^FOR' -e '^INQ'".

# Use "--fill-in-gaps" to populate missing days and hours in the STDIN data; and
# if you want to strip them out for selected exceptions, could filter STDOUT
# through something like:
#	grep -v -e '^XAC.*:mm:ss$' -e '^TRN.*:mm:ss$'
# (the filled-in rows are not TAB delimited beyond the "HH:MM:SS" column value)

$USAGE="${0} [--by-day] [--fill-in-gaps] [--insert-dow] [--append-dow]";

#
$CONF__MAX_ELAPSED_SECONDS_BUCKET=100;

#
$ARG__BY_DAY=0;
$ARG__FILL_IN_GAPS=0;
$ARG__INSERT_DOW=0;
$ARG__APPEND_DOW=0;
while(@ARGV > 0){
	last if $ARGV[0] !~ /^-./;
	($arg=shift(@ARGV))=~s/^-//;
	while(${arg} ne ""){
		if    ($arg =~ /^-help/){
			die("USAGE: ${USAGE}\n");
		}elsif($arg =~ /^-by-day$/){
			$arg="";
			$ARG__BY_DAY=1;
		}elsif($arg =~ /^-fill-in-gaps$/){
			$arg="";
			$ARG__FILL_IN_GAPS=1;
		}elsif($arg =~ /^-insert-dow$/){
			$arg="";
			$ARG__INSERT_DOW=1;
		}elsif($arg =~ /^-append-dow$/){
			$arg="";
			$ARG__APPEND_DOW=1;
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
	
}
die("USAGE: ${USAGE}\n") unless @ARGV == 0;

#
&print_header_key();
for( $seconds=0 ; $seconds <= 99 and $seconds <= ${CONF__MAX_ELAPSED_SECONDS_BUCKET} ; $seconds=sprintf("%.0f",${seconds}+1) ){
	print "\t",${seconds};
}
print "\n";

#
while(defined($line=<STDIN>)){
	next if $line !~ /^INQ\t|^XAC\t|^MIR\t|^TRN\t/;
	next if $line !~ /\tokay$/;
	$line=~s/[\r\n][\r\n]*$//;
	$line=~s/ //g;
	@f=split(/\t/,$line);
	next if $f[2] eq "total";
	next if $f[2] =~ /^-\d\d*$/;	# OpSys time drift adjustment.
	die("${0}: Invalid data format on line $. as: ${line}\n") if $f[2] !~ /^\d\d*$/;
	die("${0}: Invalid data format on line $. as: ${line}\n") if $f[3] !~ /^\d\d*$/;
	if(${ARG__BY_DAY}){
		$f[1]=~s/[0-9][0-9]$/hh/;	# Truncatate group to Day from Day and Hour 
	}
	$key=join("\t",$f[0],$f[1]);
	if(${prev_key} ne ${key}){
		if(${prev_key} ne ""){
			&fill_in_gaps(split(/\t/,${prev_key})) if ${ARG__FILL_IN_GAPS};
			&print_row();
		}
		$prev_key=${key};
		undef(@ELAPSED_SECONDS);
	}
	if($f[2] < ${CONF__MAX_ELAPSED_SECONDS_BUCKET}){
		$ELAPSED_SECONDS[$f[2]]+=$f[3];
	}else{
		$ELAPSED_SECONDS[${CONF__MAX_ELAPSED_SECONDS_BUCKET}]+=$f[3];
	}
}
if(${prev_key} ne ""){
	&fill_in_gaps(split(/\t/,${prev_key})) if ${ARG__FILL_IN_GAPS};
	&print_row();
}

sub print_row{
	@k=split(/\t/,${prev_key});
	$k[1]=~s/^..../$&-/;
	$k[1]=~s/-../$&-/;
	$k[1]=~s/-..-../$&\t/;
	$k[1]=~s/..$/$&:mm:ss/;
	&print_row_key($k[0],$k[1]);
	while(@ELAPSED_SECONDS > 0){
		print "\t",shift(@ELAPSED_SECONDS);
	}
	print "\n";
}

sub print_header_key{
   local($hdr_group,$hdr_yyyymmdd,$hdr_hhmmss)=("FOR","YYYY-MM-DD","HH:MM:SS");
	if(${ARG__APPEND_DOW}){
		$hdr_yyyymmdd.="_DOW";
	}
	if(${ARG__INSERT_DOW}){
		print join("\t",${hdr_group},"DOW",${hdr_yyyymmdd},${hdr_hhmmss});
	}else{
		print join("\t",${hdr_group},${hdr_yyyymmdd},${hdr_hhmmss});
	}
}

sub print_row_key{
   local($group,$yyyymmdd,$hhmmss)=@_;
   local($dow);
	if($yyyymmdd=~/\t/){
   		($yyyymmdd,$hhmmss)=split(/\t/,${yyyymmdd},2);
	}
	if(${ARG__INSERT_DOW} or ${ARG__APPEND_DOW}){
		$dow=&get_dow(${yyyymmdd});
	}
	if(${ARG__APPEND_DOW}){
		$yyyymmdd.="_".${dow};
	}
	if(${ARG__INSERT_DOW}){
		print join("\t",${group},${dow},${yyyymmdd},${hhmmss});
	}else{
		print join("\t",${group},${yyyymmdd},${hhmmss});
	}
}

sub fill_in_gaps{
   local($group,$yyyymmddhh)=@_;
   local($yyyy,$mm,$dd);
   local($next_yyyymmdd);
	${ARG__FILL_IN_GAPS} || return;
	if(${prev_fill_in_gaps__group} ne ${group}){
		$prev_fill_in_gaps__group="";
		$prev_fill_in_gaps__yyyymmddhh="";
	}
	if(${prev_fill_in_gaps__yyyymmddhh} ne ""){
		if(substr(${prev_fill_in_gaps__yyyymmddhh},0,8) eq substr(${yyyymmddhh},0,8)){
			# Same day, check gap in hours
			if(${ARG__BY_DAY}){
				1;
			}else{
				$hh=substr(${prev_fill_in_gaps__yyyymmddhh},8,2);
				if(sprintf("%02.0f",${hh}+1) eq substr(${yyyymmddhh},8,2)){
					1;
				}else{
					$yyyy=substr(${prev_fill_in_gaps__yyyymmddhh},0,4);
					$mm=substr(${prev_fill_in_gaps__yyyymmddhh},4,2);
					$dd=substr(${prev_fill_in_gaps__yyyymmddhh},6,2);
					for($hh=sprintf("%02.0f",${hh}+1);${hh} ne substr(${yyyymmddhh},8,2);$hh=sprintf("%02.0f",${hh}+1)){
						&print_row_key(${group},"${yyyy}-${mm}-${dd}","${hh}:mm:ss"); print "\n";
					}
				}
			}
		}else{
			# Different day
			$yyyy=substr(${prev_fill_in_gaps__yyyymmddhh},0,4);
			$mm=substr(${prev_fill_in_gaps__yyyymmddhh},4,2);
			$dd=substr(${prev_fill_in_gaps__yyyymmddhh},6,2);
			$hh=substr(${prev_fill_in_gaps__yyyymmddhh},8,2);
			# Fill in gap at end of prior day
			if(${ARG__BY_DAY}){
				1;
			}else{
				for($hh=sprintf("%02.0f",${hh}+1);${hh} ne "24";$hh=sprintf("%02.0f",${hh}+1)){
					&print_row_key(${group},"${yyyy}-${mm}-${dd}","${hh}:mm:ss"); print "\n";
				}
			}
			# Fill in gap of missing days
			if(${dd} < 28){
				$dd=sprintf("%02.0f",${dd}+1);
			}else{
				($next_yyyymmdd=`date '+%Y%m%d' --date="${yyyy}-${mm}-${dd} + 1 day"`)=~s/[\r\n][\r\n]*$//;
				$yyyy=substr(${next_yyyymmdd},0,4);
				$mm=substr(${next_yyyymmdd},4,2);
				$dd=substr(${next_yyyymmdd},6,2);
			}
			while("${yyyy}${mm}${dd}" ne substr(${yyyymmddhh},0,8)){
				if(${ARG__BY_DAY}){
					&print_row_key(${group},"${yyyy}-${mm}-${dd}","hh:mm:ss"); print "\n";
				}else{
					for($hh=sprintf("%02.0f",0);${hh} ne "24";$hh=sprintf("%02.0f",${hh}+1)){
						&print_row_key(${group},"${yyyy}-${mm}-${dd}","${hh}:mm:ss"); print "\n";
					}
				}
				if(${dd} < 28){
					$dd=sprintf("%02.0f",${dd}+1);
				}else{
					($next_yyyymmdd=`date '+%Y%m%d' --date="${yyyy}-${mm}-${dd} + 1 day"`)=~s/[\r\n][\r\n]*$//;
					$yyyy=substr(${next_yyyymmdd},0,4);
					$mm=substr(${next_yyyymmdd},4,2);
					$dd=substr(${next_yyyymmdd},6,2);
				}
			}
			# Fill in gap at begin of current day
			if(${ARG__BY_DAY}){
				1;
			}else{
				for($hh=sprintf("%02.0f",0);${hh} ne substr(${yyyymmddhh},8,2);$hh=sprintf("%02.0f",${hh}+1)){
					&print_row_key(${group},"${yyyy}-${mm}-${dd}","${hh}:mm:ss"); print "\n";
				}
			}
		}
	}
	$prev_fill_in_gaps__group=${group};
	$prev_fill_in_gaps__yyyymmddhh=${yyyymmddhh};
}

sub get_dow{
   local($date)=@_;
   local($yyyymmdd);
   local($yyyy,$mm,$dd,$dow);
   local(@DOW)=("Sun","Mon","Tue","Wed","Thu","Fri","Sat");
   local($list_search_began_as);
   local($tmp);
	if    ($date =~ /^\d{8}$/){
		$yyyymmdd=${date};
	}elsif($date =~ /^\d{4}-\d{2}-\d{2}$/){
		$date=~s/-//g; $yyyymmdd=$date;
	}elsif($date =~ /^\d{2}\/\d{2}\/\d{4}$/){
		$date=~s/\///g; $yyyymmdd=substr(${date},4,4).substr(${date},0,2).substr(${date},2,2);
	}
	if(${yyyymmdd} ne ""){
		if($GLOB__DOW{${yyyymmdd}} eq ""){
   			$yyyy=substr(${yyyymmdd},0,4);
   			$mm=substr(${yyyymmdd},4,2);
   			$dd="01";
			($dow=`date '+%a' --date="${yyyy}-${mm}-${dd} 00:00:00" 2> /dev/null`)=~s/[\r\n][\r\n]*$//;
			$list_search_began_as=$DOW[0];
			while($DOW[0] ne ${dow}){
				push(@DOW,shift(@DOW));
				last if $DOW[0] eq ${list_search_began_as};
			}
			if($DOW[0] eq ${dow}){
				for($dd=sprintf("%02.0f",1);$dd<=31;$dd=sprintf("%02.0f",${dd}+1)){
					$GLOB__DOW{"${yyyy}${mm}${dd}"}=$DOW[0];
					push(@DOW,shift(@DOW));
				}
			}else{
				for($dd=sprintf("%02.0f",1);$dd<=31;$dd=sprintf("%02.0f",${dd}+1)){
					$GLOB__DOW{"${yyyy}${mm}${dd}"}="???";
				}
			}
		}
	}
	return($GLOB__DOW{${yyyymmdd}});
}
