#!/usr/bin/perl
# File: grep_cusafiserv_failure.pl

open(FILES,"find /home/cusafiserv/ADMIN/CUSAFISERV_IO_RECORDING -type f -print | ") || die("${0}: Can not popen() for read.\n");

($TIMEZONE=`date '+%Z'`)=~s/[\r\n][\r\n]*$//; $TIMEZONE_ID=substr(${TIMEZONE},0,1);

while(defined($pathfile=<FILES>)){
	$pathfile=~s/[\r\n][\r\n]*$//;
	next if $pathfile !~ /\/\d\d*\.\d\d*$/;
	($file=$pathfile)=~s/^.*\///;
	($mbnum_padded,$ext)=split(/\./,${file},2);
	($mbnum=$mbnum_padded)=~s/^0*//; $mbnum=~s/^$/0/;
	$mtime=(stat(${pathfile}))[9];
	open(INPUT,"<${pathfile}") || die("${0}: Can not open/read: ${pathfile}\n");
	undef(@ERRORS);
	undef(@TIMESTAMPS);
	$timestamp="";
	while(defined($line=<INPUT>)){
		$line=~s/[\r\n][\r\n]*$//;
		if($line =~ /^# < DATE:\s\s*\d{14}$/){
			($timestamp=${line})=~s/^# < DATE:\s\s*//;
		}
		if($line =~ /^# STATUS: /){
			if($line =~ /^# STATUS: /){
				@f=split(/\t/,${line});
				if(@f >= 4){
					$prefix=shift(@f);
					if($f[0] eq ${mbnum}){
						if($f[2] ne "NO ERROR"){
							if(@ERRORS == 0){
								push(@ERRORS,$f[2]);
								push(@TIMESTAMPS,${timestamp});
							}elsif($ERRORS[$#ERRORS] ne $f[2]){
								push(@ERRORS,$f[2]);
								push(@TIMESTAMPS,${timestamp});
							}
						}
					}
				}
			}
		}
	}
	close(INPUT);
	undef(%ERRORS);
	($timezone=&timestamp_tz(${mtime}))=~s/^\d\d*//;
	while(@TIMESTAMPS > 0){
		$timestamp=shift(@TIMESTAMPS).${timezone};
		if($timestamp !~ /\d{14}/){
			$timestamp=&timestamp_tz(${mtime});
		}
		$error=shift(@ERRORS);
		$ERRORS{${timestamp}}.=${error}."\t";
	}
	foreach $timestamp (sort(keys(%ERRORS))){
		@errors=split(/\t/,$ERRORS{${timestamp}});
		print join("\t",${timestamp},${mbnum},@errors),"\n";
	}
}

sub timestamp_tz{
   local($time)=@_;
   local($rtrn);
   local(@f);
	if($time eq ""){ $time=time(); }
	@f=localtime(${time});
	if($f[8] == 0){
		$rtrn=sprintf("%04.0f%02.0f%02.0f%02.0f%02.0f%02.0f%sST",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0],${TIMEZONE_ID});
	}else{
		$rtrn=sprintf("%04.0f%02.0f%02.0f%02.0f%02.0f%02.0f%sDT",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0],${TIMEZONE_ID});
	}
}

# < DATE: \d{14}
