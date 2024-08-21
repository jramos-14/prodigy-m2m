#!/usr/bin/perl

$USAGE="${0} [--debug] [--include-column-ticks|--include-column-ticks-1|--include-column-ticks-2|--include-column-ticks-3] [--input-delim delimiter-char] [--output-delim delimiter-string] [--pass-thru-comments] [--pass-thru-header #] [--pass-thru-empty-lines] [--past-thru-lines-beginning string] [--pass-thru-lines-not-beginning string] [--strip-trailing-spaces] [--max-columns #] [--type-using [c?][c?]...[c?]] [--type-pass-thru-empty-as-number] [--type-pass-thru-spaces-as-number] [--justify-using [l?r][l?r]...[l?r]]";

$DELIM_INPUT="\t";
$DELIM_OUTPUT="   ";

$ARG_DEBUG=0;
$ARG_INPUT_DELIM="";
$ARG_OUTPUT_DELIM="";
$ARG_INCLUDE_COLUMN_TICKS=0;
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
while(@ARGV>0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV); $arg=~s/^-//;
	while($arg ne ""){
		if    ($arg eq "-debug"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_DEBUG=1;
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
			die("USAGE: ${USAGE}\n") if $ARGV[0] =~ /[^c?]/i;
			@ARG_TYPE_USING=split(//,shift(@ARGV));
		}elsif($arg eq "-type-pass-thru-empty-as-number"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_TYPE_PASS_THRU_EMPTY_AS_NUMBER=1;
		}elsif($arg eq "-type-pass-thru-spaces-as-number"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_TYPE_PASS_THRU_SPACES_AS_NUMBER=1;
		}elsif($arg eq "-justify-using"){
			if($arg =~ /^-/){ $arg=""; }else{ $arg=substr($arg,1); }
			$ARG_JUSTIFY_USING=1;
			die("USAGE: ${USAGE}\n") if @ARGV == 0;
			die("USAGE: ${USAGE}\n") if $ARGV[0] =~ /[^l?r]/i;
			@ARG_JUSTIFY_USING=split(//,shift(@ARGV));
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
}
die("USAGE: ${USAGE}\n") if @ARGV != 0;

if(${ARG_INPUT_DELIM} ne ""){ $DELIM_INPUT=${ARG_INPUT_DELIM}; }
if(${ARG_OUTPUT_DELIM} ne ""){ $DELIM_OUTPUT=${ARG_OUTPUT_DELIM}; }

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
	$line_prefix=""; if($line=~/^\f/){ $line_prefix.=${`}.${&}; $line=${'}; }
	if(${ARG_PASS_THRU_COMMENTS} and $line =~ /^#/){ push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line}); next; }
	if(${ARG_PASS_THRU_LINES_BEGINNING} and &pass_thru_lines_beginning(${line})){ push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line}); next; }
	if(${ARG_PASS_THRU_LINES_NOT_BEGINNING} and &pass_thru_lines_not_beginning(${line})){ push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line}); next; }
	if(${ARG_STRIP_TRAILING_SPACES}){ $line=~s/  *\Q${DELIM_INPUT}\E/${DELIM_INPUT}/g; $line=~s/  *$//; }
	push(@LINES_PREFIX,${line_prefix}); push(@LINES,${line});
	if(${ARG_MAX_COLUMNS} eq ""){
		@f=split(/\Q${DELIM_INPUT}\E/,$line);
	}else{
		@f=split(/\Q${DELIM_INPUT}\E/,$line,${ARG_MAX_COLUMNS});
	}
	for($idx=0;$idx<=$#f;$idx++){
		$len=length($f[$idx]);
		if($width[$idx] < $len){
			$width[$idx]=$len;
		}
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
			$type[$idx]="char";
		}
		if    ($type_integer[$idx] < ${type_integer}){
			$type_integer[$idx]=${type_integer};
		}
		if    ($type_decimals[$idx] < ${type_decimals}){
			$type_decimals[$idx]=${type_decimals};
		}
		if(${type_zerofill}){ $type_zerofill[$idx]=1; }
	}
}
for($idx=0;$idx<=$#width;$idx++){
	if($width[$idx] eq ""){
		$width[$idx]=sprintf("%.0f",1);
		$type[$idx]="char";
	}
}

($DELIM_OUTPUT_PRINTF_SAFE=${DELIM_OUTPUT})=~s/\%/\%\%/g;	# Make safe for printf() usage.
undef(@PRINTF_FMT); $PRINTF_FMT=""; 
for($idx=0;$idx<=$#width;$idx++){
	print STDERR ${idx},"${DELIM_INPUT}",$type[$idx],"\n" if ${ARG_DEBUG};
	if(${PRINTF_FMT} ne ""){ $PRINTF_FMT.=${DELIM_OUTPUT_PRINTF_SAFE}; }
	if($type[$idx] eq "" or $type[$idx] eq "char"){
		if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^r$/i){
			push(@PRINTF_FMT,"%-$width[$idx].$width[$idx]s");	# Standard -- Left Justified Text
		}else{
			push(@PRINTF_FMT,"%$width[$idx].$width[$idx]s");	# Alternate -- Right Justified Text
		}
	}else{
		$width[$idx]=$type_integer[$idx];
		if($type_decimals[$idx] > 0){
			$width[$idx]=sprintf("%.0f",$width[$idx] + 1 + $type_decimals[$idx]);
		}
		if($type_zerofill[$idx]){
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^l$/i){
				push(@PRINTF_FMT,"%0$width[$idx].$type_decimals[$idx]f");	# Standard -- Right Justified Numeric
			}else{
				push(@PRINTF_FMT,"%-0$width[$idx].$type_decimals[$idx]f");	# Alternate -- Left Justified Numeric
			}
		}else{
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx] !~ /^l$/i){
				push(@PRINTF_FMT,"%$width[$idx].$type_decimals[$idx]f");	# Standard -- Right Justified Numeric
			}else{
				push(@PRINTF_FMT,"%-$width[$idx].$type_decimals[$idx]f");	# Alternate -- Left Justified Numeric
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
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx_column] !~ /^l$/i){
				$tick_space=~s/^./>/;
			}else{
				$tick_space=~s/.$/</;
			}
		}else{
			# Numeric
			if(!${ARG_JUSTIFY_USING} or $ARG_JUSTIFY_USING[$idx_column] !~ /^r$/i){
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
		if(!${ARG_TYPE_PASS_THRU_SPACES_AS_NUMBER} and !${ARG_TYPE_PASS_THRU_EMPTY_AS_NUMBER}){
			printf(${PRINTF_FMT},@values);
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
