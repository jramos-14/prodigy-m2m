#!/usr/bin/perl
# File: grep_raw_io_recording.pl
# Gary Jay Peters
# 2010-02-18

# Script to print the mtime and filename of raw IO_RECORDING files when the
# specified grep (or fgrep) pattern is matched within the raw IO_RECORDING file.

$USAGE="${0} [--find-dir dir-name] [--find-name find-file-name-pattern] [--find-mtime find-mtime-value ] [-find-newer find-newer-file] [--use-fgrep-pattern-match] grep-arg1 [... grep-argN]";

$DFLT__FIND_DIRS__PATTERN="/home/*/ADMIN/*IO_RECORDING";

undef(@DFLT__FIND_NAMES);
push(@DFLT__FIND_NAMES,'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\.[0-9]');
push(@DFLT__FIND_NAMES,'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\.[0-9][0-9]');
push(@DFLT__FIND_NAMES,'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\.[0-9][0-9][0-9]');

undef(@ARG__FIND_DIRS);
undef(@ARG__FIND_NAMES);
$ARG__FIND_MTIME="";
$ARG__FIND_NEWER="";
$ARG__USE_FGREP_PATTERN_MATCH=0;
$ARG__GREP_IGNORE_CASE=0;
undef(@ARG__GREP_PATTERNS);
while(@ARGV > 0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV);
	if    (${arg} eq "--help"){
		die("USAGE: ${USAGE}\n");
	}elsif(${arg} eq "--find-dir"){
		die("USAGE: ${USAGE}\n") if @ARGV < 1;
		$qualifier=shift(@ARGV);
		if($qualifier !~ /^\//){ $qualifier="./".${qualifier}; }
		push(@ARG__FIND_DIRS,${qualifier});
	}elsif(${arg} eq "--find-name"){
		die("USAGE: ${USAGE}\n") if @ARGV < 1;
		$qualifier=shift(@ARGV);
		die("USAGE: ${USAGE}\n    Qualifer to '--find-name' can not contain '/'.\n") if $qualifier =~ /\//;
		push(@ARG__FIND_NAMES,${qualifier});
	}elsif(${arg} eq "--find-mtime"){
		die("USAGE: ${USAGE}\n") if @ARGV == 0;
		$ARG__FIND_MTIME=shift(@ARGV);
		die("USAGE: ${USAGE}\n    Qualifer to '--find-mtime' must be an integer optionally prefixed with a '+' or '-'.\n") if $ARG__FIND_MTIME !~ /^[-+\d]\d*$/;
	}elsif(${arg} eq "--find-newer"){
		die("USAGE: ${USAGE}\n") if @ARGV == 0;
		$ARG__FIND_NEWER=shift(@ARGV);
		die("USAGE: ${USAGE}\n    Qualifer to '--find-newer' must be an existant object in the filesystem.\n") if ! -e ${ARG__FIND_NEWER};
	}elsif(${arg} eq "--use-fgrep-pattern-match"){
		$ARG__USE_FGREP_PATTERN_MATCH=1;
	}elsif(${arg} eq "-i"){
		$ARG__GREP_IGNORE_CASE=1;
	}elsif(${arg} eq "-e"){
		die("USAGE: ${USAGE}\n") if @ARGV == 0;
		push(@ARG__GREP_PATTERNS,shift(@ARGV));
	}else{
		die("USAGE: ${USAGE}\n");
	}
}
if(@ARGV__GREP_PATTERNS == 0 and @ARGV == 1){ push(@ARG__GREP_PATTERNS,shift(@ARGV)); }	# Normal grep command without '-e' arguments
die("USAGE: ${USAGE}\n") if @ARGV > 0;

# Create pattern matching subroutine
$subroutine_code="";
$subroutine_code.="sub has_pattern{";
# $subroutine_code.=  " \$*=1;";
$subroutine_code.=  " local(\$*)=1;";
$subroutine_code.=  " return(1) if \$buf =~ ";
$subroutine_code.=       "/";
	$first_pattern_arg=1;
	while(@ARG__GREP_PATTERNS > 0){
		$pattern=shift(@ARG__GREP_PATTERNS);
		if(${ARG__USE_FGREP_PATTERN_MATCH}){
			# Make fgrep pattern safe for perl pattern matching.
			$pattern='\Q'.${pattern}.'\E';
		}else{
			# Make grep pattern safe for perl pattern matching.
			$pattern=~s/\|/\\$&/g;	# Escape the "|" character
			$pattern=~s/\//\\$&/g;	# Escape the "/" character
		}
		if(${first_pattern_arg}){
			$subroutine_code.=${pattern};
			$first_pattern_arg=0;
		}else{
			$subroutine_code.="|".${pattern};
		}
	}
$subroutine_code.=       "/o" . ( ${ARG__GREP_IGNORE_CASE} ? "i" : "" ) . ";";
$subroutine_code.=  " return(0);";
$subroutine_code.=" ";
$subroutine_code.="}";
print STDERR ${subroutine_code},"\n";
eval ${subroutine_code};

# Create the "find" command
if(@ARG__FIND_DIRS == 0){
	open(LS,"ls -d ${DFLT__FIND_DIRS__PATTERN} 2> /dev/null | ");
	while(defined($dir=<LS>)){
		$dir=~s/[\r\n][\r\n]*$//; push(@ARG__FIND_DIRS,${dir});
	}
	close(LS);
}
die("USAGE: ${USAGE}\n    Nothing matches default directory pattern: ${DFLT__FIND_DIRS__PATTERN}\n") if @ARG__FIND_DIRS == 0;
if(@ARG__FIND_NAMES == 0){ @ARG__FIND_NAMES=@DFLT__FIND_NAMES; }
die("USAGE: ${USAGE}\n    No file names specified.\n") if @ARG__FIND_NAMES == 0;
	$find_args="";
	while(@ARG__FIND_DIRS > 0){
		$dir=shift(@ARG__FIND_DIRS);
		$dir=~s/'/'"'"'/g;
		$find_args.=" '${dir}'";
	}
	$find_args.=" -type f";
	if(@ARG__FIND_NAMES <= 1){
		$file=shift(@ARG__FIND_NAMES);
		$file=~s/'/'"'"'/g;
		$find_args.=" -name '${file}'";
	}else{
		$find_args.=' \(';
		$file=shift(@ARG__FIND_NAMES);
		$file=~s/'/'"'"'/g;
		$find_args.=" -name '${file}'";
		while(@ARG__FIND_NAMES > 0){
			$file=shift(@ARG__FIND_NAMES);
			$file=~s/'/'"'"'/g;
			$find_args.=" -o -name '${file}'";
		}
		$find_args.=' \)';
	}
	if(${ARG__FIND_MTIME} ne ""){
		$find_args.=" -mtime '${ARG__FIND_MTIME}'";
	}
	if(${ARG__FIND_NEWER} ne ""){
		$file=${ARG__FIND_NEWER};
		$file=~s/'/'"'"'/g;
		$find_args.=" -newer '${file}'";
	}
	open(FIND,"find ${find_args} -print |");


	# Process files
	while(defined($file=<FIND>)){
		$file=~s/[\r\n][\r\n]*$//;
		if(-f ${file}){
			if(!open(INPUT,"<${file}")){
				print STDERR "${0}: Can not open/read: ${file}\n";
			}else{
				$buf=""; while(read(INPUT,$buf,1024,length($buf))> 0){ 1;  }
				close(INPUT);
				print &timestamp((stat(${file}))[9]),"\t",${file},"\n"  if &has_pattern();
			}
	}
}

sub timestamp{
   local($time)=@_;
   local($rtrn);
   local(@f);
	if($time eq ""){ $time=time(); }
	@f=localtime($time);
	$rtrn=sprintf("%04.0f%02.0f%02.0f%02.0f%02.0f%02.0f%02.0f",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	return(${rtrn});
}
