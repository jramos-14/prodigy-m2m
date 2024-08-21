#!/usr/bin/perl
# File: parse_xxxxx_io_filter_out_2.pl
# Gary Jay Peters
# 2010-08-11

# Generic (core independent) script for use in conjunction with XML parsing
# scripts "parse_*_io.pl" (core dependent) that reduces (boils down) the
# contents from "parse_*_io.out.2".

$USAGE="${0} [--extreme-reduction] [inputfile]";

$ARG__EXTREME_REDUCTION=0;
while(@ARGV>0){
	last if $ARGV[0] !~ /^-/;
	$arg=shift(@ARGV); $arg=~s/^-//;
	while(${arg} ne ""){
		if    ($arg eq "-help"){
			$arg="";
			die("USAGE: ${USAGE}\n");
		}elsif($arg eq "-extreme-reduction"){
			$arg="";
			$ARG__EXTREME_REDUCTION=1;
		}else{
			die("USAGE: ${USAGE}\n");
		}
	}
}
die("USAGE: ${USAGE}\n") if @ARGV > 1;
if    (@ARGV == 0){
	&parse(STDIN);
}elsif($ARGV[0] eq "-"){
	&parse(STDIN);
}else{
	die("${0}: Not a file: $ARGV[0]\n") if ! -f $ARGV[0];
	open(INPUT,"<$ARGV[0]") || die("${0}: Can not open/read: $ARGV[0]\n");
	&parse(INPUT);
	close(INPUT);
}

sub parse{
   local(*INPUT)=@_;
   local($line,$line_no_eol);
   local($direction,$key,$value);
   local($may_be_xml_group__line,$may_be_xml_group__direction_key);
	while(defined($line=<INPUT>)){
		if    ($line !~ /^[<>] \t/){
			print ${line};	# Not part of the XML
		}elsif($line =~ /^[<>] \t<?.*?>/){
			print ${line};	# Standalones like '<?xml version="1.0"?>'
		}else{
			($line_no_eol=${line})=~s/[\r\n][\r\n]*$//;
			($direction,$key,$value)=split(/\t/,${line_no_eol},3);
			if($key !~ /\.\d\d*$/){
				1;	# Is not a data element from the XML (is a reserved control key of associative array).
			}else{
				# Is a data element from the XML (as stored in the associative array).
				if(!${ARG__EXTREME_REDUCTION}){
					print ${line};
				}else{
					if(${value} eq ""){
						if(${may_be_xml_group__direction_key} ne "" and index(${direction}.${key},"${may_be_xml_group__direction_key}.") != 0){
							print ${may_be_xml_group__line};	# Prior line was not an not simply a parent XML group
						}
						$may_be_xml_group__line=${line};
						$may_be_xml_group__direction_key=${direction}.${key};
					}else{
						if(${may_be_xml_group__direction_key} ne "" and index(${direction}.${key},"${may_be_xml_group__direction_key}.") != 0){
							print ${may_be_xml_group__line};	# Prior line was not an not simply a parent XML group
						}
						print ${line};
						$may_be_xml_group__line="";
						$may_be_xml_group__direction_key="";
					}
				}
			}
		}
	}
}
