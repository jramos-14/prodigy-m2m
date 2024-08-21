#!/usr/bin/perl

open(FILES,"find /home/cusafiserv/ADMIN/CUSAFISERV_IO_RECORDING -type f -name '*.[0-9]' -print |") || die("${0}: Can not popen/read: find /home/cusafiserv/ADMIN/CUSAFISERV_IO_RECORDING -type f -name '*.[0-9]' -print\n");

while(defined($file=<FILES>)){
	$file=~s/[\r\n][\r\n]*$//;
	next if ! -f ${file};
	open(INPUT,"<${file}") || die("${0}: Can not open/read: ${file}\n");
	$timestamp=""; $dms_request="";
	while(defined($line=<INPUT>)){
		$line=~s/[\r\n][\r\n]*$//;
		if($line =~ /^# DATE:\s\s*/){
			if(${timestamp} eq ""){
				$timestamp=${'};
			}
		}
		if($line =~ /^# COMMAND:\s/){
		 	last if $line !~ /^# COMMAND:\s\s*TRN:\s\s*/;
			$dms_request=${'};
		}
		if($line =~ /^< <\?xml version=/){
			$buf=$line;
			while($buf =~ /<Response>|<[A-Za-z0-9]+:Response>/){
				$buf=${&}.${'};
				if($buf =~ /<\/Response>|<\/[A-Za-z0-9]+:Response>/){
					$status=${`}.${&};
					$buf=${'};
					if($status =~ /<Status>|<[A-Za-z0-9]+:Status>/){
						$status=${&}.${'};
						if($status =~ /<\/Status>|<\/[A-Za-z0-9]+:Status>/){
							$status=${`}.${&};
							$status =~ s/<Status>|<[A-Za-z0-9]+:Status>//;
							$status =~ s/<\/Status>|<\/[A-Za-z0-9]+:Status>//;
							print ${timestamp},"\t",${dms_request},"\t",${status},"\n";
						}
					}
				}
			}
		}
	}
}
