#!/usr/bin/perl

$USAGE="${0} [--debug] [--expect-huge-data] [--tmp-dir dir] [--report-ram-usage] [--include-column-ticks|--include-column-ticks-1|--include-column-ticks-2|--include-column-ticks-3] [--input-whitespaces-as-delim] [--max-columns-input-whitespaces-as-delim-columns #] [--input-delim delimiter-char] [--output-delim delimiter-string] [--has-header #] [--pass-thru-comments] [--pass-thru-header #] [--pass-thru-empty-lines] [--pass-thru-lines-beginning string] [--pass-thru-lines-not-beginning string] [--strip-trailing-spaces] [--max-columns #] [--type-using [{1-999}c?][{1-999}c?]...[{1-999}c?]] [--type-pass-thru-empty-as-number] [--type-integer-no-zero-padding] [--type-pass-thru-spaces-as-number] [--justify-using [{1-999}l?r][{1-999}l?r]...[{1-999}l?r]]";

$DELIM_INPUT="\t";
$DELIM_OUTPUT="   ";

$ARG_DEBUG=0;
$ARG_EXPECT_HUGE_DATA=0;
$ARG_TMP_DIR="/tmp";
$ARG_REPORT_RAM_USAGE=0;
$ARG_INPUT_WHITESPACES_AS_DELIM=0;
$ARG_MAX_COLUMNS_INPUT_WHITESPACES_AS_DELIM=0;
$ARG_INPUT_DELIM="";
$ARG_OUTPUT_DELIM="";
$ARG_INCLUDE_COLUMN_TICKS=0;
$ARG_HAS_HEADER=0;
$ARG_HAS_HEADER_LINES="";
$ARG_PASS_THRU_COMMENTS=0;
$ARG_PASS_THRU_HEADER=0;
$ARG_PASS_THRU_HEADER_LINES="";
$ARG_PASS_THRU_EMPTY_LINES=0;
$ARG_PASS_THRU_LINES_BEGINNING=0;
@ARG_PASS_THRU_LINES_BEGINNING;
$ARG_PASS_THRU_LINES_NOT_BEGINNING=0;
@ARG_PASS_THRU_LINES_NOT_BEGINNING;
$ARG_STRIP_TRAILING_SPACES=0;
$ARG_JUSTIFY_USING=0; undef(@ARG_JUSTIFY_USING);
$ARG_MAX_COLUMNS="";
$ARG_TYPE_USING=0; undef(@ARG_TYPE_USING);
$ARG_TYPE_PASS_THRU_EMPTY_AS_NUMBER=0;
$ARG_TYPE_PASS_THRU_SPACES_AS_NUMBER=0;
$ARG_TYPE_INTEGER_NO_ZERO_PADDING=0;
while(@ARGV>0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV); $arg=~s/^-//;
	while($arg ne ""){
		if    ($arg eq "-debug"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_DEBUG=1;
		}elsif($arg eq "-expect-huge-data"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_EXPECT_HUGE_DATA=1;
		}elsif($arg eq "-tmp-dir"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if length($ARGV[0]) < 1;
			$ARG_TMP_DIR=shift(@ARGV);
			die("${0}: Argument '--tmp-dir' qualifier is not an existant directory: ${ARG_TMP_DIR}\n") unless -d ${ARG_TMP_DIR};
			die("${0}: Argument '--tmp-dir' qualifier is a directory without read permission: ${ARG_TMP_DIR}\n") unless -r ${ARG_TMP_DIR};
			die("${0}: Argument '--tmp-dir' qualifier is a directory without write permission: ${ARG_TMP_DIR}\n") unless -w ${ARG_TMP_DIR};
			die("${0}: Argument '--tmp-dir' qualifier is a directory without exec permission: ${ARG_TMP_DIR}\n") unless -x ${ARG_TMP_DIR};
		}elsif($arg eq "-report-ram-usage"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_REPORT_RAM_USAGE=1;
		}elsif($arg eq "-input-whitespaces-as-delim"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_INPUT_WHITESPACES_AS_DELIM=1;
		}elsif($arg eq "-max-columns-input-whitespaces-as-delim"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if $ARGV[0] !~ /^\d\d*$/;
			$ARG_MAX_COLUMNS_INPUT_WHITESPACES_AS_DELIM=sprintf("%.0f",shift(@ARGV));
			die("USAGE: ${USAGE}\n") if ${ARG_MAX_COLUMNS_INPUT_WHITESPACES_AS_DELIM} < 1;
			$ARG_INPUT_WHITESPACES_AS_DELIM=1;	# The '--max-columns-input-whitespaces-as-delim' implies '--input-whitespaces-as-delim'.
		}elsif($arg eq "-input-delim"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if length($ARGV[0]) != 1;
			$ARG_INPUT_DELIM=shift(@ARGV);
		}elsif($arg eq "-output-delim"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if length($ARGV[0]) < 1;
			$ARG_OUTPUT_DELIM=shift(@ARGV);
		}elsif($arg eq "-include-column-ticks"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_INCLUDE_COLUMN_TICKS=3;
		}elsif($arg eq "-include-column-ticks-1"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_INCLUDE_COLUMN_TICKS=1;
		}elsif($arg eq "-include-column-ticks-2"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_INCLUDE_COLUMN_TICKS=2;
		}elsif($arg eq "-include-column-ticks-3"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_INCLUDE_COLUMN_TICKS=3;
		}elsif($arg eq "-has-header"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_HAS_HEADER=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if $ARGV[0] !~ /^\d\d*$/;
			$ARG_HAS_HEADER_LINES=sprintf("%.0f",shift(@ARGV));
		}elsif($arg eq "-pass-thru-comments"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_PASS_THRU_COMMENTS=1;
		}elsif($arg eq "-pass-thru-header"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_PASS_THRU_HEADER=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if $ARGV[0] !~ /^\d\d*$/;
			$ARG_PASS_THRU_HEADER_LINES=sprintf("%.0f",shift(@ARGV));
		}elsif($arg eq "-pass-thru-empty-lines"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_PASS_THRU_EMPTY_LINES=1;
		}elsif($arg eq "-pass-thru-lines-beginning"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_PASS_THRU_LINES_BEGINNING=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			for($idx=0;$idx<=$#ARG_PASS_THRU_LINES_BEGINNING;$idx++){
				last if $ARG_PASS_THRU_LINES_BEGINNING[${idx}] eq $ARGV[0];
			}
			$ARG_PASS_THRU_LINES_BEGINNING[${idx}]=shift(@ARGV);
		}elsif($arg eq "-pass-thru-lines-not-beginning"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_PASS_THRU_LINES_NOT_BEGINNING=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			for($idx=0;$idx<=$#ARG_PASS_THRU_LINES_NOT_BEGINNING;$idx++){
				last if $ARG_PASS_THRU_LINES_NOT_BEGINNING[${idx}] eq $ARGV[0];
			}
			$ARG_PASS_THRU_LINES_NOT_BEGINNING[${idx}]=shift(@ARGV);
		}elsif($arg eq "-save-blank-lines"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_PASS_THRU_EMPTY_LINES=1;
			print STDERR "${0}: Warning: \"--save-blank-lines\" syntax is deprecated, please use \"--pass-thru-empty-lines\".\n";
		}elsif($arg eq "-strip-trailing-spaces"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_STRIP_TRAILING_SPACES=1;
		}elsif($arg eq "-max-columns"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if $ARGV[0] !~ /^\d\d*$/;
			$ARG_MAX_COLUMNS=sprintf("%.0f",shift(@ARGV));
			die("USAGE: ${USAGE}\n") if ${ARG_MAX_COLUMNS} < 1;
		}elsif($arg eq "-type-using"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_TYPE_USING=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			$ARGV[0]=&expand_numeric_repeating_of_char($ARGV[0],999,1);
			die("USAGE: ${USAGE}\n") if $ARGV[0] =~ /[^c?]/i;
			@ARG_TYPE_USING=split(//,shift(@ARGV));
		}elsif($arg eq "-type-pass-thru-empty-as-number"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_TYPE_PASS_THRU_EMPTY_AS_NUMBER=1;
		}elsif($arg eq "-type-pass-thru-spaces-as-number"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_TYPE_PASS_THRU_SPACES_AS_NUMBER=1;
		}elsif($arg eq "-type-integer-no-zero-padding"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_TYPE_INTEGER_NO_ZERO_PADDING=1;
		}elsif($arg eq "-justify-using"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_JUSTIFY_USING=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			$ARGV[0]=&expand_numeric_repeating_of_char($ARGV[0],999,1);
			die("USAGE: ${USAGE}\n") if $ARGV[0] =~ /[^l?r]/i;
			@ARG_JUSTIFY_USING=split(//,shift(@ARGV));
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
}
die("USAGE: ${USAGE}\n") if @ARGV != 0;
die("${0}: Arguments '--has-header' (columnize the header) and '--pass-thru-header' (do not columnize the header) are exclusive.\n") if ${ARG_HAS_HEADER} and ${ARG_PASS_THRU_HEADER};

if(${ARG_INPUT_DELIM} ne ""){ $DELIM_INPUT=${ARG_INPUT_DELIM}; }
if(${ARG_OUTPUT_DELIM} ne ""){ $DELIM_OUTPUT=${ARG_OUTPUT_DELIM}; }

if(${ARG_EXPECT_HUGE_DATA}){
	die("${0}: No directory: ${ARG_TMP_DIR}\n") unless -d ${ARG_TMP_DIR};
	die("${0}: No read permission on directory: ${ARG_TMP_DIR}\n") unless -r ${ARG_TMP_DIR};
	die("${0}: No write permission on directory: ${ARG_TMP_DIR}\n") unless -w ${ARG_TMP_DIR};
	die("${0}: No exec permission on directory: ${ARG_TMP_DIR}\n") unless -x ${ARG_TMP_DIR};
	open(HUGE_DATA__LINES,          "+>${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-0") || die("${0}: Can not create/read/write: ${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-0"); unlink("${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-0");
	open(HUGE_DATA__LINES_PREFIX,   "+>${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-1") || die("${0}: Can not create/read/write: ${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-1"); unlink("${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-1");
	open(HUGE_DATA__LINES_IS_HEADER,"+>${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-2") || die("${0}: Can not create/read/write: ${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-2"); unlink("${ARG_TMP_DIR}/columnize.tmp.$$.HUGE_DATA-2");
}

if(${ARG_PASS_THRU_HEADER}){
	if(${ARG_PASS_THRU_HEADER_LINES} > 0){
		while(defined($line=<STDIN>)){
			$line=~s/[\r\n][\r\n]*$//;
			print ${line},"\n";
			$ARG_PASS_THRU_HEADER_LINES=sprintf("%.0f",${ARG_PASS_THRU_HEADER_LINES}-1);
			last if ${ARG_PASS_THRU_HEADER_LINES} <= 0;
		}
	}
}
while(defined($line=<STDIN>)){
	$line=~s/[\r\n][\r\n]*$//;
	if(${ARG_EXPECT_HUGE_DATA}){
		while(@LINES > 0){
			print HUGE_DATA__LINES           shift(@LINES),"\n";
			print HUGE_DATA__LINES_PREFIX    shift(@LINES_PREFIX),"\n";
			print HUGE_DATA__LINES_IS_HEADER shift(@LINES_IS_HEADER),"\n";
		}
	}
	if(${ARG_HAS_HEADER_LINES} == 0){
		$is_header_line=0;
	}else{
		$is_header_line=1;
		$ARG_HAS_HEADER_LINES=sprintf("%.0f",${ARG_HAS_HEADER_LINES}-1);
	}
	$line_prefix=""; if($line=~/^\f/){ $line_prefix.=${`}.${&}; $line=${'}; }
	if(!${is_header_line}){
		if(${ARG_PASS_THRU_COMMENTS} and $line =~ /^#/){ push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line}); next; }
		if(${ARG_PASS_THRU_LINES_BEGINNING} and &pass_thru_lines_beginning(${line})){ push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line}); next; }
		if(${ARG_PASS_THRU_LINES_NOT_BEGINNING} and &pass_thru_lines_not_beginning(${line})){ push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line}); next; }
	}
	if(${ARG_INPUT_WHITESPACES_AS_DELIM}){
		@f=split(/[ \t][ \t]*/,${line}."_",${ARG_MAX_COLUMNS_INPUT_WHITESPACES_AS_DELIM}); $f[$#f]=~s/_$//;
		$line=join(${DELIM_INPUT},@f);
	}
	if(${ARG_STRIP_TRAILING_SPACES}){ $line=~s/  *\Q${DELIM_INPUT}\E/${DELIM_INPUT}/g; $line=~s/  *$//; }
	push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line});
	if(${is_header_line}){ $LINES_IS_HEADER[$#LINES]=1; }
	if(${ARG_MAX_COLUMNS} eq ""){
		@f=split(/\Q${DELIM_INPUT}\E/,$line."\n"); $f[$#f]=~s/\n$//;	# Using "\n" as a unique EOL marker (because we happen to know that this script splits STDIN lines on "\n").
	}else{
		@f=split(/\Q${DELIM_INPUT}\E/,$line."\n",${ARG_MAX_COLUMNS}); $f[$#f]=~s/\n$//;	# Using "\n" as a unique EOL marker (because we happen to know that this script splits STDIN lines on "\n").
	}
	for($idx=0;$idx<=$#f;$idx++){
		$len=length($f[$idx]);
		if($width[$idx] < $len){
			$width[$idx]=$len;
		}
		if(!${is_header_line}){
			$type_integer=0;
			$type_decimals=0;
			$type_zerofill=0;
			if(${ARG_TYPE_USING} and $ARG_TYPE_USING[$idx] =~ /^c$/i){
				$type="char";
			}elsif($f[$idx] =~ /^$/){
				$type="";
			}elsif($f[$idx] =~ /^\d\d*$/ or $f[$idx] =~ /^-\d\d*$/){
				$type="dec";
				$type_decimals=0;
				$type_integer=$len;
				if($f[$idx] =~ /^0/ and $f[$idx] ne "0"){ $type_zerofill=1; }
			}elsif($f[$idx] =~ /^\.\d\d*$/ or $f[$idx] =~ /^-\.\d\d*$/){
				$type="dec";
				($decimals=$f[$idx])=~s/^.*\.//;
				$type_decimals=length($decimals);
				$type_integer=$len-(1+${type_decimals});
				if($f[$idx] =~ /^0/){ $type_zerofill=1; }
			}elsif($f[$idx] =~ /^0.\d\d*$/ or $f[$idx] =~ /^-0.\d\d*$/){
				$type="dec";
				($decimals=$f[$idx])=~s/^.*\.//;
				$type_decimals=length($decimals);
				$type_integer=$len-(1+${type_decimals});
				if($f[$idx] =~ /^0/ and $f[$idx] !~ /^0\./){ $type_zerofill=1; }
			}elsif($f[$idx] =~ /^\d\d*\.\d\d*$/ or $f[$idx] =~ /^-\d\d*\.\d\d*$/){
				$type="dec";
				($decimals=$f[$idx])=~s/^.*\.//;
				$type_decimals=length($decimals);
				$type_integer=$len-(1+${type_decimals});
				if($f[$idx] =~ /^0/ and $f[$idx] !~ /^0\./){ $type_zerofill=1; }
			}else{
				$type="char";
			}
			if    ($type[$idx] eq ""){
				$type[$idx]=${type};
				$type_integer[$idx]=${type_integer};
				$type_decimals[$idx]=${type_decimals};
				$type_zerofill[$idx]=${type_zerofill};
			}elsif($type[$idx] ne ${type}){
				if(${type} eq ""){
					1; # Do not change $type[$idx] because this could just be a numeric column with an empty value (and so the $type[$idx] is left unchanged even if it is unassigned)
				}else{
					$type[$idx]="char";
				}
			}
			if    ($type_integer[$idx] < ${type_integer}){
				$type_integer[$idx]=${type_integer};
			}
			if    ($type_decimals[$idx] < ${type_decimals}){
				$type_decimals[$idx]=${type_decimals};
			}
			if(${type_zerofill}){ $type_zerofill[$idx]=1; }
		}else{
			if($header_width[$idx] < ${len}){
				$header_width[$idx]=${len};
			}
		}
	}
}
if(${ARG_EXPECT_HUGE_DATA}){
	while(@LINES > 0){
		print HUGE_DATA__LINES           shift(@LINES),"\n";
		print HUGE_DATA__LINES_PREFIX    shift(@LINES_PREFIX),"\n";
		print HUGE_DATA__LINES_IS_HEADER shift(@LINES_IS_HEADER),"\n";
	}
}
for($idx=0;$idx<=$#width;$idx++){
	if($type[$idx] eq ""){
		$type[$idx]="char";		# Fake column that had  no "type" assigned, which likely exists because script suspected that this could just be a numeric column with an empty value (and so the $type[$idx] was left unassigned)
	}
}
for($idx=0;$idx<=$#width;$idx++){
	if($width[$idx] eq ""){
		$width[$idx]=sprintf("%.0f",1);	# Fake column with no values
		$type[$idx]="char";		# Fake column with no values
	}
}

($DELIM_OUTPUT_PRINTF_SAFE=${DELIM_OUTPUT})=~s/\%/\%\%/g;	# Make safe for printf() usage.
undef(@PRINTF_FMT); $PRINTF_FMT=""; 
for($idx=0;$idx<=$#width;$idx++){
	print STDERR ${idx},"${DELIM_INPUT}",$type[$idx],"\n" if ${ARG_DEBUG};
	if(${PRINTF_FMT} ne ""){ $PRINTF_FMT.=${DELIM_OUTPUT_PRINTF_SAFE}; }
	if($type[$idx] eq "" or $type[$idx] eq "char"){
		if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^r$/i){
			if($width[$idx] >= $header_width[$idx]){
				push(@PRINTF_FMT,"%-$width[$idx].$width[$idx]s");	# Standard -- Left Justified Text
			}else{
				push(@PRINTF_FMT,"%-$header_width[$idx].$header_width[$idx]s");	# Standard -- Left Justified Text
			}
		}else{
			if($width[$idx] >= $header_width[$idx]){
				push(@PRINTF_FMT,"%$width[$idx].$width[$idx]s");	# Alternate -- Right Justified Text
			}else{
				push(@PRINTF_FMT,"%$header_width[$idx].$header_width[$idx]s");	# Alternate -- Right Justified Text
			}
		}
	}else{
		$width[$idx]=$type_integer[$idx];
		if($type_decimals[$idx] > 0){
			$width[$idx]=sprintf("%.0f",$width[$idx] + 1 + $type_decimals[$idx]);
		}
		if    (${ARG_TYPE_INTEGER_NO_ZERO_PADDING} and $type_decimals[$idx] eq "0"){
			# Treat integers like strings, leaving prefixed "0"s intact, but rigth justify the result.
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^l$/i){
				if($width[$idx] >= $header_width[$idx]){
					push(@PRINTF_FMT,"%$width[$idx].$width[$idx]s");	# Standard -- Right Justified Integer as Text
				}else{
					push(@PRINTF_FMT,"%$header_width[$idx].$header_width[$idx]s");	# Standard -- Right Justified Integer as Text
				}
			}else{
				if($width[$idx] >= $header_width[$idx]){
					push(@PRINTF_FMT,"%-$width[$idx].$width[$idx]s");	# Alternate -- Left Justified Integer as Text
				}else{
					push(@PRINTF_FMT,"%-$header_width[$idx].$header_width[$idx]s");	# Alternate -- Left Justified Integer as Text
				}
			}
		}elsif($type_zerofill[$idx]){
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^l$/i){
				push(@PRINTF_FMT,"%0$width[$idx].$type_decimals[$idx]f");	# Standard -- Right Justified Numeric
				if($width[$idx] >= $header_width[$idx]){
					1;
				}else{
					$PRINTF_FMT[$#PRINTF_FMT]= ' ' x sprintf("%.0f",$header_width[$idx]-$width[$idx]) . $PRINTF_FMT[$#PRINTF_FMT];
				}
			}else{
				push(@PRINTF_FMT,"%-0$width[$idx].$type_decimals[$idx]f");	# Alternate -- Left Justified Numeric
				if($width[$idx] >= $header_width[$idx]){
					1;
				}else{
					$PRINTF_FMT[$#PRINTF_FMT]= $PRINTF_FMT[$#PRINTF_FMT] .  ' ' x sprintf("%.0f",$header_width[$idx]-$width[$idx]);
				}
			}
		}else{
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^l$/i){
				push(@PRINTF_FMT,"%$width[$idx].$type_decimals[$idx]f");	# Standard -- Right Justified Numeric
				if($width[$idx] >= $header_width[$idx]){
					1;
				}else{
					$PRINTF_FMT[$#PRINTF_FMT]= ' ' x sprintf("%.0f",$header_width[$idx]-$width[$idx]) . $PRINTF_FMT[$#PRINTF_FMT];
				}
			}else{
				push(@PRINTF_FMT,"%-$width[$idx].$type_decimals[$idx]f");	# Alternate -- Left Justified Numeric
				if($width[$idx] >= $header_width[$idx]){
					1;
				}else{
					$PRINTF_FMT[$#PRINTF_FMT]= $PRINTF_FMT[$#PRINTF_FMT] .  ' ' x sprintf("%.0f",$header_width[$idx]-$width[$idx]);
				}
			}
		}
	}
	$PRINTF_FMT.=$PRINTF_FMT[$#PRINTF_FMT];
}
$PRINTF_FMT.="\n";
print STDERR ${PRINTF_FMT} if ${ARG_DEBUG};

if(${ARG_INCLUDE_COLUMN_TICKS} > 0){
	for($idx_column=0;$idx_column<=$#PRINTF_FMT;$idx_column++){
		$value=$values[${idx_column}];
		$printf_fmt=$PRINTF_FMT[${idx_column}];
		print ${DELIM_OUTPUT} if ${idx_column} > 0;
		($tick_space=sprintf(${printf_fmt},0))=~s/./ /g;
		if($type[${idx_column}] eq "" or $type[${idx_column}] eq "char"){
			# Text
			if    (!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx_column] =~ /^l$/i){
				$tick_space=~s/^./>/;
			}else{
				$tick_space=~s/.$/</;
			}
		}else{
			# Numeric
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx_column] =~ /^r$/i){
				$tick_space=~s/.$/</;
			}else{
				$tick_space=~s/^./>/;
			}
		}
		if(${ARG_INCLUDE_COLUMN_TICKS} eq "1"){
			$tick_space=~s/[^ ]/./;
		}
		if(${ARG_INCLUDE_COLUMN_TICKS} eq "3"){
			$tick_space=~s/^.$/v/;
		}
		print ${tick_space};
	}
	print "\n";
}
if(${ARG_EXPECT_HUGE_DATA}){
	seek(HUGE_DATA__LINES,0,0);
	seek(HUGE_DATA__LINES_PREFIX,0,0);
	seek(HUGE_DATA__LINES_IS_HEADER,0,0);
}
if(${ARG_EXPECT_HUGE_DATA}){
	while(@LINES > 0){
		print HUGE_DATA__LINES           shift(@LINES),"\n";
		print HUGE_DATA__LINES_PREFIX    shift(@LINES_PREFIX),"\n";
		print HUGE_DATA__LINES_IS_HEADER shift(@LINES_IS_HEADER),"\n";
	}
}
while(1){
	if(${ARG_EXPECT_HUGE_DATA}){
		undef(@LINES);
		undef(@LINES_PREFIX);
		undef(@LINES_IS_HEADER);
		for($huge_data__idx=0;$huge_data__idx<500;$huge_data__idx++){
			$huge_data__eof=1; while(defined($huge_data__line=<HUGE_DATA__LINES>)){ $huge_data__eof=0; last; }
			last if ${huge_data__eof};
			while(defined($huge_data__line_prefix=<HUGE_DATA__LINES_PREFIX>)){ last; }
			while(defined($huge_data__line_is_header=<HUGE_DATA__LINES_IS_HEADER>)){ last; }
			$huge_data__line=~s/\n$//; push(@LINES,${huge_data__line});
			$huge_data__line_prefix=~s/\n$//; push(@LINES_PREFIX,${huge_data__line_prefix});
			$huge_data__line_is_header=~s/\n$//; push(@LINES_IS_HEADER,${huge_data__line_is_header});
		}
		last if ${huge_data__eof} and @LINES == 0;
	}
	for($idx=0;$idx<=$#LINES;$idx++){
		if    (${ARG_PASS_THRU_EMPTY_LINES} and $LINES[$idx] eq ""){
			print $LINES_PREFIX[$idx],"\n";
		}elsif(${ARG_PASS_THRU_COMMENTS} and $LINES[$idx] =~ /^#/){
			print $LINES_PREFIX[$idx],$LINES[$idx],"\n";
		}elsif(${ARG_PASS_THRU_LINES_BEGINNING} and &pass_thru_lines_beginning($LINES[$idx])){
			print $LINES_PREFIX[$idx],$LINES[$idx],"\n";
		}elsif(${ARG_PASS_THRU_LINES_NOT_BEGINNING} and &pass_thru_lines_not_beginning($LINES[$idx])){
			print $LINES_PREFIX[$idx],$LINES[$idx],"\n";
		}else{
			print $LINES_PREFIX[$idx];
			# printf(${PRINTF_FMT},(split(/\Q${DELIM_INPUT}\E/,$LINES[$idx])));
			if(${ARG_MAX_COLUMNS} eq ""){
				@values=(split(/\Q${DELIM_INPUT}\E/,$LINES[$idx]." ")); $values[$#values]=~s/ $//;
			}else{
				@values=(split(/\Q${DELIM_INPUT}\E/,$LINES[$idx]." ",${ARG_MAX_COLUMNS})); $values[$#values]=~s/ $//;
			}
			if(!$LINES_IS_HEADER[$idx] and !${ARG_TYPE_PASS_THRU_SPACES_AS_NUMBER} and !${ARG_TYPE_PASS_THRU_EMPTY_AS_NUMBER}){
				printf(${PRINTF_FMT},@values);
			}elsif($LINES_IS_HEADER[$idx]){
				for($idx_column=0;$idx_column<=$#PRINTF_FMT;$idx_column++){
					$value=$values[${idx_column}];
					$printf_fmt=$PRINTF_FMT[${idx_column}];
					print ${DELIM_OUTPUT} if ${idx_column} > 0;
					($header_space=sprintf(${printf_fmt},0))=~s/./ /g;
					if($type[${idx_column}] eq "" or $type[${idx_column}] eq "char"){
						# Text
						if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx_column] !~ /^l$/i){
							substr($header_space,0,length(${value}))=${value};
						}else{
							substr($header_space,-length(${value}),length(${value}))=${value};
						}
					}else{
						# Numeric
						if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx_column] !~ /^r$/i){
							substr($header_space,-length(${value}),length(${value}))=${value};
						}else{
							substr($header_space,0,length(${value}))=${value};
						}
					}
					print ${header_space};
				}
				print "\n";
			}else{
				for($idx_column=0;$idx_column<=$#PRINTF_FMT;$idx_column++){
					$value=$values[${idx_column}];
					$printf_fmt=$PRINTF_FMT[${idx_column}];
					print ${DELIM_OUTPUT} if ${idx_column} > 0;
					
					if    (${ARG_TYPE_PASS_THRU_EMPTY_AS_NUMBER} and ${value} eq ""){
						($value_padded_blank=sprintf(${printf_fmt},${value}))=~s/./ /g;
						print ${value_padded_blank};
					}elsif(${ARG_TYPE_PASS_THRU_SPACES_AS_NUMBER} and ${value} =~ /^\s\s*$/){
						($value_padded_blank=sprintf(${printf_fmt},${value}))=~s/./ /g;
						print ${value_padded_blank};
					}else{
						printf(${printf_fmt},${value});
					}
				}
				print "\n";
			}
		}
	}
	last if !${ARG_EXPECT_HUGE_DATA};
}
if(${ARG_REPORT_RAM_USAGE}){
	$ram_usage=`ps --no-headers -o rss -p $$`;
	$ram_usage=~s/[\r\n][\r\n]*$//;
	$ram_usage=~s/^ *//;
	$ram_usage=~s/ *$//;
	if($ram_usage=~/[0-9]$/){ $ram_usage.="K"; }
	print STDERR "RAM USAGE: ${ram_usage}\n";
}

sub expand_numeric_repeating_of_char{
   local($string,$max_expansion,$parens_indicate_repeating_group)=@_;
   local($insert,$expand,$append);
   local($expand_count,$expand_char);
   local($paren_open,$paren_close)=("(",")");
	if($max_expansion <= 0){ $max_expansion=999; }
	$max_expansion=sprintf("%.0f",${max_expansion});
	while($string =~ /\d\d*[^\d]/){
		$insert=${`};
		$expand=${&};
		$append=${'};
		($expand_count=${expand})=~s/.$//;
		$expand_char=substr(${expand},-1,1);
		if(${parens_indicate_repeating_group}){
			if(${expand_char} eq ${paren_open}){
				if(index(${append},${paren_close}) < $[){
					print STDERR "${0}: expand_numeric_repeating_of_char(): Expansion group began with '${paren_open}' but could not find the matching '${paren_close}'.\n";
					last;
				}
				$expand_char=substr(${append},0,index(${append},${paren_close}));
				$append=substr(${append},index(${append},${paren_close})+1);
				if(index(${expand_char},${paren_open}) >= $[){
					print STDERR "${0}: expand_numeric_repeating_of_char(): Nested expansion groups (like '7${paren_open}...2${paren_open}...${paren_close}...${paren_close}' form) are not supported.\n";
					last;
				}
			}
		}
		if(sprintf("%.0f",${expand_count}) > ${max_expansion}){	# Actively prevent excessive expansion.
			print STDERR "${0}: expand_numeric_repeating_of_char(): Expansion count of ${expand_count} exceeds allowed maximum of ${max_expansion} (not allowed to expand repeat a character that many times).\n";
			last;
		}
		$string=${insert} . ${expand_char} x sprintf("%.0f",${expand_count}) . ${append};
	}
	if($string =~ /\d$/){
		print STDERR "${0}: expand_numeric_repeating_of_char(): Expansion count of ${expand_count} ocurred at end-of-string (was not followed by a character to be expand repeated).\n";
	}
	return(${string});
}

sub pass_thru_lines_beginning{
   # arg($line)=@_; #
   local($rtrn)=0;
   local($idx);
   local($match);
	if(${ARG_PASS_THRU_LINES_BEGINNING}){
		for($match=0,$idx=0;$idx<=$#ARG_PASS_THRU_LINES_BEGINNING;$idx++){
			if(index($_[0],$ARG_PASS_THRU_LINES_BEGINNING[${idx}])==$[){ $match=1; last; }
		}
		if(${match}){ $rtrn=1; }
   local($rtrn)=0;
	}
	return(${rtrn});
}

sub pass_thru_lines_not_beginning{
   # arg($line)=@_; #
   local($rtrn)=0;
   local($idx);
   local($match);
	if(${ARG_PASS_THRU_LINES_NOT_BEGINNING}){
		for($match=0,$idx=0;$idx<=$#ARG_PASS_THRU_LINES_NOT_BEGINNING;$idx++){
			if(index($_[0],$ARG_PASS_THRU_LINES_NOT_BEGINNING[${idx}])==$[){ $match=1; last; }
		}
		if(!${match}){ $rtrn=1; }
	}
	return(${rtrn});
}
