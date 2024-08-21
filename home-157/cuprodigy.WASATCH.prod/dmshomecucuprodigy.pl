#!/usr/bin/perl
# File: /home/cuprodigy/dmshomecucuprodigy.pl
# Gary Jay Peters @ DMS
# 2017-03-29

if($ENV{"LANG"} ne "C"){ $ENV{"LANG"}="C" ; sleep(2) ; exec(${0},@ARGV); die("${0}: Failed exec() at line ",__LINE__,"\n"); }

open(FH_DEBUG,">&STDERR");
close(FH_DEBUG);

$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{"Share"}="N";
$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{"Draft"}="Y";
$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{"Certificate"}="O";
$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{""}="O";
# $TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{"Share"}="N";
# $TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{"Draft"}="Y";
# $TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{"Certificate"}="O";
$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{""}="O";

## ========================================================================== ##
## ==========  COPYRIGHT BY                                        ========== ##
## ==========  Database Management Services, Inc. / HomeCU         ========== ##
## ==========  Boise, Idaho                                        ========== ##
## ========================================================================== ##

#
# DMS/HomeCU Perl script for interaction to CUDP's CUProdigy Interface.
#

#
# To run as a UNIX service on the DMS/HomeCU Cobalt appliance:
#
# Configure "/etc/services" like:
#	cuprodigy	9000/tcp			# CUProdigy 
#
# Configure "/etc/inetd.conf" like:
#	cuprodigy	stream	tcp	nowait	root	/usr/bin/perl /usr/bin/perl /home/cuprodigy/dmshomecucuprodigy.pl "--#" web --servicesets 01,02,03 --homedir /home/cuprodigy
#


#===============================================================================
# COMMAND LINE ARGUMENT USAGE
#===============================================================================

$USAGE="${0} [ [--test-mode--do-not-submit-transactions] [--# comment|--#comment] [[-s|--servicesets] list] [[-e|--extension] extension] [--cuid cuid] [--homedir homedir] [--customdir customdir] ] | [ --parse-stdin ] ";

# If no arguments are specified, the default values used will be identical to
# having specified the arguments:
#	-e ""
#	-s 1
#	--homedir /home/cuprodigy
#	--customdir /home/cuprodigy/CUSTOM

# Arguments "--cuid cuid" are for controlling the production ".cfg" files and
# sub-directories in a shared production directory, while arguments
# "--extension extension" are for controlling testing (alternate) ".cfg" files
# and sub-directories within the production directory.
#
# Because "--extension extension" (${ARG_EXTENSION}) is used for "testing" it
# requires seperate (must be named including the value in ${VAR_EXTENSION}):
#	"${DMS_HOMEDIR}/ADMIN${VAR_CUID}${VAR_EXTENSION}" directory (see where
#		use_arg_extension_always() is called)
#	"${DMS_HOMEDIR}/TMP${VAR_CUID}${VAR_EXTENSION}" directory (see where
#		use_arg_extension_always() is called)
# but allows usage of the "extension" (${VAR_EXTENSION}) to be optional (re-use
# the existing base when an "extension"ed one does not exist):
#	"${DMS_HOMEDIR}/dmshomecucuprodigy.cfg${VAR_CUID}" file (see where
#		use_arg_extension_if_exists() is called)
#	"${DMS_HOMEDIR}/CACHE__MB_OVERRIDES${VAR_CUID}" directory (see where
#		use_arg_extension_if_exists() is called)
#	"${DMS_HOMEDIR}/CACHE__MB_DP_MICR${VAR_CUID}" directory (see where
#		use_arg_extension_if_exists() is called)
#	"${DMS_HOMEDIR}/CUSTOM${VAR_CUID}" directory (see where
#		use_arg_extension_if_exists() is called)
#	"${DMS_HOMEDIR}/MICR_OVERRIDES${VAR_CUID}" directory (see where
#		use_arg_extension_if_exists() is called)

#===============================================================================
# INITIAL SETUP
#===============================================================================

# Look for keyword "MARK"
# Look for keyword "FEATURE"

$|=1;

if(@ARGV>0){ $arg_list="'".join("' '",@ARGV)."'"; }

use Net::Telnet();
if(sprintf("%.8f") < 5.008){
	$NET_TELNET_METHOD="5.003";
}else{
	$NET_TELNET_METHOD="5.008";
}

$SCRIPT_START_TIME=time();

$DMS_HOMEDIR="/home/cuprodigy";

$ARG_TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS=0;
$ARG_COMMENT="";
$ARG_SERVICESETS="";
$ARG_EXTENSION="";
$ARG_CUID="";
$ARG_DMSHOMEDIR="";
$ARG_CUSTOMDIR="";
$ARG_PARSE_STDIN="";
&process_args(@ARGV);

do "${DMS_HOMEDIR}/cuprodigy_post_request.pi";
do "${DMS_HOMEDIR}/cuprodigy_soap_like.pi";
do "${DMS_HOMEDIR}/cuprodigy_xml_parse.pi";
do "${DMS_HOMEDIR}/cuprodigy_message_xml.pi";
do "${DMS_HOMEDIR}/cuprodigy_message_methods.pi";

if(${ARG_PARSE_STDIN}){
	&special_mode__parse_STDIN();
	exit(0);
}

do "${DMS_HOMEDIR}/incl_mathquirk.pi";
die("${0}: Failure in: math_quirk__tests_ok()\n") if ! &math_quirk__tests_ok();

if(${ARG_CUSTOMDIR} ne ""){
	$CUSTOM{DIR}=${ARG_CUSTOMDIR};
	die("${0}: Use '--custom-dir' argument to specify a value other than: ${DMS_HOMEDIR}\n") if $CUSTOM{DIR} eq ${DMS_HOMEDIR};
}else{
	$CUSTOM{DIR}=&use_arg_extension_if_exists("-d","${DMS_HOMEDIR}/CUSTOM",${VAR_CUID},${VAR_EXTENSION});
}
$CUSTOM{LIST}=join("\t","custom_TRN_memo_prefix.pi","custom_TRN_MM_prioritized.pi","custom_baldesc.pi","custom_block.pi","custom_micr.pi","custom_parsing_mir.pi","custom_password.pi","custom_prehistory.pi","custom_preproc.pi","custom_sso.pi","custom_xmlrequest_memberpwd.pi","custom_xxxhistory_sortkey.pi");
foreach $custom_file (split(/\s\s*/,$CUSTOM{LIST})){
	if(${custom_file} ne ""){
		if(-f "$CUSTOM{DIR}/${custom_file}" && -r "$CUSTOM{DIR}/${custom_file}"){
			do "$CUSTOM{DIR}/${custom_file}";
			$CUSTOM{${custom_file}}=1;
		}
	}
}

&config_debug();
&config_xml(); local(%XML_NAMESPACE_BY_TAG_INDEX,%XML_ATTRIBUTES_BY_TAG_INDEX,%XML_DATA_BY_TAG_INDEX,%XML_SEQ_BY_TAG_INDEX,%XML_TAGS_FOUND);
&config_dms_interface();
&config_cuprodigy_interface();
&config_tempfiles();
&config_adminfiles();
&config_processcontrol();
&config_runstoprestartcontrol();
&config_coredegradationcheck();
# &config_dms_interface();
&config_dms_values();
&config_cuprodigy_loan_payoff();

&config_load_overrides();

if(defined(${CTRL__ALLOW_BLIND_TRANSFERS_WITHOUT_XAC_RELATION})){ $CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION=${CTRL__ALLOW_BLIND_TRANSFERS_WITHOUT_XAC_RELATION};	} # For backwards compatibility of existing configuration files ("dmshomecucuprodigy.cfg"); on 2018-07-13 the HomeCU terminology changed from "Blind Transfers" to "Unrestricted Transfers", so this ("dmshomecucuprodigy.pl") script's coding and logging has been re-fitted to reflect HomeCU's new terminology.

$SELFNAME="dmshomecucuprodigy";
# if(${CTRL__DMS_ADMINDIR} eq ""){
# 	$SELFPIDFILE="${DMS_HOMEDIR}/${SELFNAME}.pid${VAR_CUID}${VAR_EXTENSION}";
# }else{
# 	$SELFPIDFILE="${CTRL__DMS_ADMINDIR}/${SELFNAME}.pid${VAR_CUID}${VAR_EXTENSION}";
# }

if(${CTRL__DMS_ADMINDIR} eq ""){
	&logfile_init(${CTRL__LOGFILE_MAX_BYTES},"${DMS_HOMEDIR}/${SELFNAME}.log");
}else{
	&logfile_init(${CTRL__LOGFILE_MAX_BYTES},"${CTRL__DMS_ADMINDIR}/${SELFNAME}.log");
}
&logfile("Start process ($$).\n");
&logfile("Process arguments used: ${0} ${arg_list}\n");
&logfile("Process source version: ".`ls -l "${0}" 2> /dev/null`);
&logfile_queue_flush();
&config_sanitize_settings();
&config_warnings();
&known_limitations();
foreach $custom_file (split(/\s\s*/,$CUSTOM{LIST})){
	if($CUSTOM{${custom_file}}>0){
		&logfile("Custom Included: $CUSTOM{DIR}/${custom_file}\n");
	}else{
		&logfile("Custom Not Included: $CUSTOM{DIR}/${custom_file}\n");
	}
}
$GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST="";
if($CUSTOM{"custom_xxxhistory_sortkey.pi"}>0){
	if(defined(&custom_xxxhistory_sortkey)){
		$GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST=&custom_xxxhistory_sortkey("list",",");
		&logfile("custom_xxxhistory_sortkey('list'): List value: ${GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST}\n");
		if(${GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST} ne ""){
			$GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST=",".${GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST}.",";
		}
	}
}
if(sprintf("%.0f",${CTRL__CUPRODIGY_SERVER__POST_REQUEST_PARALLEL_MAX}) > 1){
	&logfile("Using PARALLEL(".sprintf("%04.0f",${CTRL__CUPRODIGY_SERVER__POST_REQUEST_PARALLEL_MAX}).") mode to post requests to ${CTRL__SERVER_REFERENCE__CUPRODIGY}.\n");
}else{
	&logfile("Using SERIAL mode to post requests to ${CTRL__SERVER_REFERENCE__CUPRODIGY}.\n");
}
&logfile("Using MESSAGEDIGEST implementation: ${CTRL__FIHEADER_SECURITY_MESSAGEDIGEST__IMPLEMENTATION}\n");


#===============================================================================
# MAIN BODY
#===============================================================================

($SCRIPT_SERVICE_ID,$SCRIPT_SERVICE_ID_EXT)=&start();
if(${CTRL__CHILD_OF_INETD} != 0){
	$SIGNAL_PIPE_RD_CLOSED=$SIG{"PIPE"};
	$SIGNAL_PIPE_WR_CLOSED="output_closed";
}
&life_cycle_init(${CTRL__LIFE_CYCLE_MAX_REQUESTS},${CTRL__LIFE_CYCLE_MAX_SECONDS});
if(${DEBUG__INQ_MINIMUM_DATE__FLAG}){
	if(&date_to_CCYYMMDD(${DEBUG__INQ_MINIMUM_DATE__VALUE}) ne ""){
		$DEBUG__INQ_MINIMUM_DATE__VALUE=&date_to_CCYYMMDD(${DEBUG__INQ_MINIMUM_DATE__VALUE});
		&logfile("DEBUG__INQ_MINIMUM_DATE__FLAG: Will be enforcing an Inquiry date minimum value of: ${DEBUG__INQ_MINIMUM_DATE__VALUE}\n");
	}else{
		&logfile("DEBUG__INQ_MINIMUM_DATE__FLAG: Invalid value for \$DEBUG__INQ_MINIMUM_DATE__VALUE ('${DEBUG__INQ_MINIMUM_DATE__VALUE}'), deactivating DEBUG__INQ_MINIMUM_DATE__FLAG.\n");
		$DEBUG__INQ_MINIMUM_DATE__FLAG=0;
		$DEBUG__INQ_MINIMUM_DATE__VALUE="";
	}
}
local($MB_OVERRIDES,%MB_OVERRIDES);
local(%CACHE_MB_DP_TO_MICR);	# Since MICRs are sent through transaction history (rather than balance record), need to be able to lookup the last value (from a cache file) when no current transaction history has a MICR.
local(@XML_MB_UNIQID);
local(@XML_MB_DP_UNIQID);
local(@XML_MB_LN_UNIQID);
local(@XML_MB_CC_UNIQID);
local(@XML_MB_DP_BALS);
local(@XML_MB_LN_BALS);
local(@XML_MB_CC_BALS,%XML_MB_CC_TO_UNIQ,%XML_MB_CC_FROM_UNIQ);
local(@XML_MB_DP_ATTRS);
local(@XML_MB_LN_ATTRS);
local(@XML_MB_CC_ATTRS);
local(@XML_MB_XAC);
local(@XML_MB_DP_GROUPS);
local(@XML_MB_LN_GROUPS);
local(@XML_MB_CC_GROUPS);
local(@XML_MB_DP_ACCESS_INFO);
local(@XML_MB_LN_ACCESS_INFO);
local(@XML_MB_CC_ACCESS_INFO);
local(@XML_MB_DP_EXPIRED);
local(@XML_MB_LN_EXPIRED);
local(@XML_MB_CC_EXPIRED);
local(@XML_MB_LN_PAYOFF);
local(@XML_MB_CC_PAYOFF);
local(@XML_MB_ESTATEMENTACTIVE);
if(${CTRL__DBM_FILE__XML_DATA_BY_TAG_INDEX}){
	$DBM_FILE__XML_DATA_BY_TAG_INDEX=${CTRL__DMS_TMPDIR}."/DBM_FILE__XML_DATA_BY_TAG_INDEX".${SCRIPT_SERVICE_ID_EXT};
	foreach $dbm_file (${DBM_FILE__XML_DATA_BY_TAG_INDEX}.".dir",${DBM_FILE__XML_DATA_BY_TAG_INDEX}.".pag"){
		unlink(${dbm_file}) if -f ${dbm_file}; # Do remove the DBM file at process startup.  Removing the DBM file only at startup (and not shutdown) prevents a program that is stopping from removing a DBM file being used by a program that is starting.
		&logfile_and_die("${0}: Failed to remove DBM file: ${dbm_file}\n") if -f ${dbm_file};
	}
	&logfile_and_die("${0}: dbm_local_scoping__XML_DATA_BY_TAG_INDEX(): ${error}\n") if ($error=&dbm_local_scoping__XML_DATA_BY_TAG_INDEX("dbmopen",${DBM_FILE__XML_DATA_BY_TAG_INDEX},0666)) ne "";	# dbmopen(%XML_DATA_BY_TAG_INDEX,${DBM_FILE__XML_DATA_BY_TAG_INDEX},0666);
	undef(%XML_DATA_BY_TAG_INDEX);	# Though we remove the expected DBM files (".dir"and ".pag"), use "undef()" just in case DBM uses other files.
}

$GLOB__STACKED_ERROR_099=0;
$GLOB__STACKED_ERROR_099_FORCE_ABORT=0;
&logfile("Intializing the interface to ${CTRL__SERVER_REFERENCE__CUPRODIGY}.\n");
&cuprodigy_io_recording("START","0","Intializing the interface to ${CTRL__SERVER_REFERENCE__CUPRODIGY}.");
$error=&initialize_cuprodigy();
if(${error} ne ""){
	&logfile("${error}\n");
	$GLOB__STACKED_ERROR_099=1; &logfile("Stacking error 099 for later use.\n");
	$GLOB__STACKED_ERROR_099_FORCE_SHUTDOWN=1; &logfile("Stacked error 099 will force a shutdown.\n");
}
&cuprodigy_io_recording("STOP","0","Intializing the interface to ${CTRL__SERVER_REFERENCE__CUPRODIGY}.");
&configure_account_by_cuprodigy_type__usage_history__load();

print STDOUT ${CTRL__READY_PROMPT};
&logfile("Waiting for request.\n");
while((($line,$status_STDIN)=&timedread_eol_STDIN(${CTRL__STDIN_TIMEOUT_READ_SECONDS}))[1] ne "EOF"){
	$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS="";
	$GLOB__PACKET_FETCH_DEBUGGING_NOTE="";
	$GLOB__CMD_NET_TIMEOUT_TIME=sprintf("%.0f",time()+${CTRL__CMD_NET_TIMEOUT_SECONDS});
	$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR=0;
	$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG="";
	if(${line} eq "" && ${status_STDIN} eq "TIM"){
		last if !&life_cycle_seconds_check();
		last if !&run_stop_restart_check();
		next;
	}
	if(${CTRL__CHILD_OF_INETD} != 0){
		$SIG{"PIPE"}=${SIGNAL_PIPE_WR_CLOSED};
	}
	$line=&filter_user_input($line);
	&logfile("Command: ${line}\n");
	undef(@MIR_RESPONSE_NOTES); undef(@INQ_RESPONSE_NOTES); undef(@XAC_RESPONSE_NOTES);
	$skip_custom_preproc=0;
	if(!${CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__TRN_MA_QUESTIONS}){
		if($line =~ /^TRN: /){
			$tran_code=(split(/\t/,$line." "))[1];
			$tran_code=~tr/a-z/A-Z/;
			if($tran_code eq "MA"){
				$skip_custom_preproc=1;	# Because TRN MA is handled in "CUSTOM/custom_preproc.pi".
			}
		}
	}
	$continue_after_custom_preproc=1;
	if(!${skip_custom_preproc}){
		if($CUSTOM{"custom_preproc.pi"}>0){
			if(defined(&custom_preproc)){
				($continue_after_custom_preproc,$line)=&custom_preproc(0,$line);
			}
		}
	}
	if($continue_after_custom_preproc){
		if    ($line =~ /^QUIT$/){
			&logfile("Stop process ($$); exiting normally.\n");
			&selfpidfile_stop();
			exit(0);
		}elsif($line =~ /^SYN: /){
			&syncronize_dms($line);
		}elsif($line =~ /^INQ: /){
			$line=~s/^INQ: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(&sane_input_field_count("Inquiry",$f[0],scalar(@f),1,2,3,4,5,6,7,8)){	# member, password, cutoff, email, Balance|Account|Loan, member, account, cert
				if(&sane_mb_num_pwd("Inquiry",$f[0],$f[1])){
					&set_glob_mbnum($f[0]);
					&logfile("Inquiry: ".join("\t",@f)."\n");
					&datastream_tag_set("Inquiry",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(${DEBUG__INQ_MINIMUM_DATE__FLAG}){
						if(&date_to_CCYYMMDD($f[2]) ne ""){
							if(&date_to_CCYYMMDD($f[2]) gt ${DEBUG__INQ_MINIMUM_DATE__VALUE}){
								&logfile("DEBUG__INQ_MINIMUM_DATE__FLAG: Forcing adjustement of Inquiry date minimum value from '$f[2]' to '${DEBUG__INQ_MINIMUM_DATE__VALUE}'.\n");
								$f[2]=${DEBUG__INQ_MINIMUM_DATE__VALUE};
							}
						}
					}
					if(&simultanious_request_blocking("START","INQ",$f[0],$f[2])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"INQ: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"INQ: ".$line); $line=~s/^INQ: //;
							}
						}
						if($continue_after_custom_preproc){
							($inquiry_rtrn_error,@inquiry_rtrn_other)=&inquiry(1,$f[0],$f[1],$f[2],$f[2],$f[3],$f[4],$f[5],$f[6],$f[7]);
							if(${inquiry_rtrn_error} eq ""){
								if(${CONF__EMAILUPDATE}){
									&emailupdate($f[0],$f[3]);
								}
							}
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"INQ: ".$line); $line=~s/^INQ: //;
								}
							}
						}
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"INQ: ".$line);
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"INQ: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"INQ: ".$line); $line=~s/^INQ: //;
							}
						}
						if($continue_after_custom_preproc){
							($inquiry_rtrn_error,@inquiry_rtrn_other)=&inquiry(1,$f[0],$f[1],$f[2],$f[2],$f[3],$f[4],$f[5],$f[6],$f[7]);
							if(${inquiry_rtrn_error} eq ""){
								if(${CONF__EMAILUPDATE}){
									&emailupdate($f[0],$f[3]);
								}
							}
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"INQ: ".$line); $line=~s/^INQ: //;
								}
							}
						}
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"INQ: ".$line);
					}
					&simultanious_request_blocking("STOP","INQ",$f[0],$f[2]);
					&configure_account_by_cuprodigy_type__usage_history__save();
				}else{
					&logfile("Invalid Format: AccountNumber and/or PIN\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^XAC: /){
			$line=~s/^XAC: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(&sane_input_field_count("CrossAccount",$f[0],scalar(@f),1,2)){	# member, email
				if(&sane_mb_num_pwd("CrossAccount",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("CrossAccount: ".join("\t",@f)."\n");
					&datastream_tag_set("CrossAccount",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","XAC",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"XAC: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"XAC: ".$line); $line=~s/^XAC: //;
							}
						}
						if($continue_after_custom_preproc){
							&xac_inquiry($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"XAC: ".$line); $line=~s/^XAC: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"XAC: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"XAC: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"XAC: ".$line); $line=~s/^XAC: //;
							}
						}
						if($continue_after_custom_preproc){
							&xac_inquiry($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"XAC: ".$line); $line=~s/^XAC: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"XAC: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","XAC",$f[0]);
					&configure_account_by_cuprodigy_type__usage_history__save();
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^TRN: /){
			$line=~s/^TRN: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
				$min_TRN_field_count=9;
			}else{
				$min_TRN_field_count=8;
			}
			if(&sane_input_field_count("Transaction",$f[0],scalar(@f),${min_TRN_field_count},9,10)){
				if(&sane_mb_num_pwd("Transaction",$f[0],"")){
					if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
						&set_glob_mbnum($f[8]);		# Must override with TRN TAUTH value when is XJO (rather than use default TRN MEMBER value)
					}else{
						if($f[8] ne ""){
							&set_glob_mbnum($f[8]);		# Use existant TRN TAUTH value when is not XJO (should be the same as TRN MEMBER value)
						}else{
							&set_glob_mbnum($f[0]);		# Use TRN MEMBER value when is not XJO (for some reason the TRN TAUTH value was not sent)
						}
					}
					&logfile("Transaction: ".join("\t",@f)."\n");
					&datastream_tag_set("Transaction",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					&mb_overrides_load($f[0]);
					&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"TRN: ".$line);
					if($CUSTOM{"custom_preproc.pi"}>0){
						if(defined(&custom_preproc)){
							($continue_after_custom_preproc,$line)=&custom_preproc(1,"TRN: ".$line); $line=~s/^TRN: //;
						}
					}
					if($continue_after_custom_preproc){
						&transaction(@f);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(2,"TRN: ".$line); $line=~s/^TRN: //;
							}
						}
					}
					&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"TRN: ".$line);
					&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
					&datastream_tag_set("","");
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^MIR: /){
			$line=~s/^MIR: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(&sane_input_field_count("MemberInfo",$f[0],scalar(@f),1,2)){	# member, email
				if(&sane_mb_num_pwd("MemberInfo",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("MemberInfo: ".join("\t",@f)."\n");
					&datastream_tag_set("MemberInfo",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","MIR",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"MIR: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"MIR: ".$line); $line=~s/^MIR: //;
							}
						}
						if($continue_after_custom_preproc){
							&mir_inquiry($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"MIR: ".$line); $line=~s/^MIR: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"MIR: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"MIR: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"MIR: ".$line); $line=~s/^MIR: //;
							}
						}
						if($continue_after_custom_preproc){
							&mir_inquiry($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"MIR: ".$line); $line=~s/^MIR: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"MIR: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","MIR",$f[0]);
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^ETOC: /){
			$line=~s/^ETOC: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(&sane_input_field_count("EStatementTOC",$f[0],scalar(@f),1,2)){	# member, email
				if(&sane_mb_num_pwd("EStatementTOC",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("EStatementTOC: ".join("\t",@f)."\n");
					&datastream_tag_set("EStatementTOC",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","ETOC",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"ETOC: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"ETOC: ".$line); $line=~s/^ETOC: //;
							}
						}
						if($continue_after_custom_preproc){
							&etoc_inquiry($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"ETOC: ".$line); $line=~s/^ETOC: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"ETOC: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"ETOC: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"ETOC: ".$line); $line=~s/^ETOC: //;
							}
						}
						if($continue_after_custom_preproc){
							&etoc_inquiry($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"ETOC: ".$line); $line=~s/^ETOC: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"ETOC: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","ETOC",$f[0]);
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^ESTM: /){
			$line=~s/^ESTM: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(&sane_input_field_count("EStatement",$f[0],scalar(@f),2,3)){	# member, yyyymm, email
				if(&sane_mb_num_pwd("EStatement",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("EStatement: ".join("\t",@f)."\n");
					&datastream_tag_set("EStatement",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","ESTM",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"ESTM: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"ESTM: ".$line); $line=~s/^ESTM: //;
							}
						}
						if($continue_after_custom_preproc){
							&estm_inquiry($f[0],$f[1]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"ESTM: ".$line); $line=~s/^ESTM: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"ESTM: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"ESTM: ".$line);
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"ESTM: ".$line); $line=~s/^ESTM: //;
							}
						}
						if($continue_after_custom_preproc){
							&estm_inquiry($f[0],$f[1]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"ESTM: ".$line); $line=~s/^ESTM: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"ESTM: ".$line);
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","ESTM",$f[0]);
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^NEWAPP: /){
			$line=~s/^NEWAPP: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if($f[0] =~ /^\s*<root>.*<\/root>\s*$/){ @f=("0",@f); }	# The leading "member number" field may or may not be included in the "NEWAPP" request, so normalize the "NEWAPP" fields when the leading "member number" field is found to be missing.
			if(&sane_input_field_count("LoanAppNew",$f[0],scalar(@f),2,3)){	# member, xmldata, email
				if(&sane_mb_num_pwd("LoanAppNew",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("LoanAppNew: ".join("\t",@f)."\n");
					&datastream_tag_set("LoanAppNew",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","NEWAPP",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"NEWAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						# &cuprodigy_io_recording("START","NEWAPP_WITHOUT_MEMBER","NEWAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "NEWAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"NEWAPP: ".$line); $line=~s/^NEWAPP: //;
							}
						}
						if($continue_after_custom_preproc){
							&loanapp_new($f[0],$f[1]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"NEWAPP: ".$line); $line=~s/^NEWAPP: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"NEWAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						# &cuprodigy_io_recording("STOP","NEWAPP_WITHOUT_MEMBER","NEWAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "NEWAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"NEWAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						&cuprodigy_io_recording("START","NEWAPP_WITHOUT_MEMBER","NEWAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "NEWAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"NEWAPP: ".$line); $line=~s/^NEWAPP: //;
							}
						}
						if($continue_after_custom_preproc){
							&loanapp_new($f[0],$f[1]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"NEWAPP: ".$line); $line=~s/^NEWAPP: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"NEWAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						&cuprodigy_io_recording("STOP","NEWAPP_WITHOUT_MEMBER","NEWAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "NEWAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","NEWAPP",$f[0]);
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^INQAPP: /){
			$line=~s/^INQAPP: //;
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(@f == 1){ @f=("0",@f); }	# The leading "member number" field may or may not be included in the "INQAPP" request, so normalize the "INQAPP" fields when the leading "member number" field is found to be missing.
			if(&sane_input_field_count("LoanAppInq",$f[0],scalar(@f),2,3)){	# member, loanappid, email
				if(&sane_mb_num_pwd("LoanAppInq",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("LoanAppInq: ".join("\t",@f)."\n");
					&datastream_tag_set("LoanAppInq",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","INQAPP",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"INQAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						# &cuprodigy_io_recording("START","INQAPP_WITHOUT_MEMBER","INQAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "INQAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"INQAPP: ".$line); $line=~s/^INQAPP: //;
							}
						}
						if($continue_after_custom_preproc){
							&loanapp_status($f[0],$f[1]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"INQAPP: ".$line); $line=~s/^INQAPP: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"INQAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						# &cuprodigy_io_recording("STOP","INQAPP_WITHOUT_MEMBER","INQAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "INQAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"INQAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						&cuprodigy_io_recording("START","INQAPP_WITHOUT_MEMBER","INQAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "INQAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"INQAPP: ".$line); $line=~s/^INQAPP: //;
							}
						}
						if($continue_after_custom_preproc){
							&loanapp_status($f[0],$f[1]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"INQAPP: ".$line); $line=~s/^INQAPP: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"INQAPP: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						&cuprodigy_io_recording("STOP","INQAPP_WITHOUT_MEMBER","INQAPP: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "INQAPP_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","INQAPP",$f[0]);
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}elsif($line =~ /^LOANTYPES: / or $line =~ /^LOANTYPES:$/ or $line =~ /^LOANTYPES$/){
			if    ($line =~ /^LOANTYPES: /){
				$line=~s/^LOANTYPES: //;
			}elsif($line =~ /^LOANTYPES:$/){
				$line=~s/^LOANTYPES:$//;
			}elsif($line =~ /^LOANTYPES$/){
				$line=~s/^LOANTYPES$//;
			}
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if(@f == 0){ @f=("0",@f); }	# The leading "member number" field may or may not be included in the "LOANTYPES" request, so normalize the "LOANTYPES" fields when the leading "member number" field is found to be missing.
			if(@f == 1 and $f[0] eq ""){ $f[0]="0"; }	# The leading "member number" field may or may not be included in the "LOANTYPES" request, so normalize the "LOANTYPES" fields when the leading "member number" field is found to be missing.
			if(&sane_input_field_count("LoanTypes",$f[0],scalar(@f),1)){	# member
				if(&sane_mb_num_pwd("LoanTypes",$f[0],"")){
					&set_glob_mbnum($f[0]);
					&logfile("LoanTypes: ".join("\t",@f)."\n");
					&datastream_tag_set("LoanTypes",$f[0]);
					&selfpidfile_check();	# Call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters
					if(&simultanious_request_blocking("START","LOANTYPES",$f[0])){
						&mb_overrides_load($f[0]);
						# &cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						# &cuprodigy_io_recording("START","LOANTYPES_WITHOUT_MEMBER","LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "LOANTYPES_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"LOANTYPES: ".$line); $line=~s/^LOANTYPES: //;
							}
						}
						if($continue_after_custom_preproc){
							&loanapp_types($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"LOANTYPES: ".$line); $line=~s/^LOANTYPES: //;
								}
							}
						}
						# &cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						# &cuprodigy_io_recording("STOP","LOANTYPES_WITHOUT_MEMBER","LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "LOANTYPES_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}else{
						&mb_overrides_load($f[0]);
						&cuprodigy_io_recording("START",&get_glob_mbnum($f[0]),"LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						&cuprodigy_io_recording("START","LOANTYPES_WITHOUT_MEMBER","LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "LOANTYPES_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						if($CUSTOM{"custom_preproc.pi"}>0){
							if(defined(&custom_preproc)){
								($continue_after_custom_preproc,$line)=&custom_preproc(1,"LOANTYPES: ".$line); $line=~s/^LOANTYPES: //;
							}
						}
						if($continue_after_custom_preproc){
							&loanapp_types($f[0]);
							if($CUSTOM{"custom_preproc.pi"}>0){
								if(defined(&custom_preproc)){
									($continue_after_custom_preproc,$line)=&custom_preproc(2,"LOANTYPES: ".$line); $line=~s/^LOANTYPES: //;
								}
							}
						}
						&cuprodigy_io_recording("STOP",&get_glob_mbnum($f[0]),"LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) !~ /^0*$/;
						&cuprodigy_io_recording("STOP","LOANTYPES_WITHOUT_MEMBER","LOANTYPES: ".$line) if &get_glob_mbnum($f[0]) =~ /^0*$/;	# Replacing the member number with string "LOANTYPES_WITHOUT_MEMBER" works only becuase (1) we have already rejected any non-numeric member number and (2) the cuprodigy_io_recording() as special code for regexp /_WITHOUT_MEMBER$/.
						&selfpidfile_check();	# Call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters
						&datastream_tag_set("","");
					}
					&simultanious_request_blocking("STOP","LOANTYPES",$f[0]);
				}else{
					&logfile("Invalid Format: AccountNumber\n");
				}
			}else{
				&logfile("Invalid field count.\n");
			}
			last if !&life_cycle_request_check();
		}else{
			&logfile("Invalid command: ${line}\n");
		}
		&set_glob_mbnum("");
	}
	if(${GLOB__STACKED_ERROR_099_FORCE_SHUTDOWN}){
		&logfile("Shutdown: Forced by stacked error 099.\n");
		last;
	}else{
		$GLOB__STACKED_ERROR_099=0;
		$GLOB__STACKED_ERROR_099_FORCE_SHUTDOWN=0;
	}
	undef(@MIR_RESPONSE_NOTES); undef(@INQ_RESPONSE_NOTES); undef(@XAC_RESPONSE_NOTES);
	last if !&life_cycle_seconds_check();
	last if !&run_stop_restart_check();
	print STDOUT ${CTRL__READY_PROMPT} if ${CTRL__USE_READY_PROMPT_MORE_THAN_ONCE};
	&logfile("Waiting for request.\n");
	if(${CTRL__CHILD_OF_INETD} != 0){
		$SIG{"PIPE"}=${SIGNAL_PIPE_RD_CLOSED};
	}
	&post_request_force_close_all_connections() if ${CONF__CUPRODIGY_SERVER__TELNET_CONNECTIONS_SHORT_LIVED} > 0;
	$GLOB__PACKET_FETCH_DEBUGGING_NOTE="";
}
&post_request_force_close_all_connections(); # &soap_like_connection_close(${glob_soap_like_connection});
&input_closed() if ${status_STDIN} eq "EOF";
if(${CTRL__DBM_FILE__XML_DATA_BY_TAG_INDEX}){
	if(${DBM_FILE__XML_DATA_BY_TAG_INDEX} ne ""){
		&logfile_and_die("${0}: dbm_local_scoping__XML_DATA_BY_TAG_INDEX(): ${error}\n") if ($error=&dbm_local_scoping__XML_DATA_BY_TAG_INDEX("dbmclose")) ne ""; 	# dbmclose(%XML_DATA_BY_TAG_INDEX);
		foreach $dbm_file (${DBM_FILE__XML_DATA_BY_TAG_INDEX}.".dir",${DBM_FILE__XML_DATA_BY_TAG_INDEX}.".pag"){
			# unlink(${dbm_file}) if -f ${dbm_file}; # Do not remove the DBM file at process shutdown.  Removing the DBM file only at startup (and not shutdown) prevents a program that is stopping from removing a DBM file being used by a program that is starting.
			# &logfile_and_die("${0}: Failed to remove DBM file: ${dbm_file}\n") if -f ${dbm_file};
		}
	}
}
&selfpidfile_stop();
exit(0);

sub use_arg_extension_always{
   local($type,$base,$cuid,$extension,$trailing)=@_;
	return(${base}.${cuid}.${extension}.${trailing});
}

sub use_arg_extension_if_exists{
   local($type,$base,$cuid,$extension,$trailing)=@_;
   local($rtrn)=${base}.${cuid}.${extension}.${trailing};
	if($type eq "-f"){
		if(-f "${base}${cuid}" and ! -f "${base}${cuid}${extension}"){
			$rtrn=${base}.${cuid}.${trailing};	# Re-use the normal file (without the extension (${VAR_EXTENSION}) appended to the name) when a seperate file does not already exist with the extension (${VAR_EXTENSION}) appended to the name.
		}
	}
	if($type eq "-d"){
		if(-d "${base}${cuid}" and ! -d "${base}${cuid}${extension}"){
			$rtrn=${base}.${cuid}.${trailing};	# Re-use the normal directory (without the extension (${VAR_EXTENSION}) appended to the name) when a seperate directory does not already exist with the extension (${VAR_EXTENSION}) appended to the name.
		}
	}
	return(${rtrn});
}

sub process_args{
   local(@argv)=@_;
   local($arg,$arg_desc);
	while(@argv>0){
		$arg=shift(@argv);
		$arg=&filter_inetd_conf_quotes($arg);	# Filter out quotations
		# Evaluate the argument.
		if($arg =~ /^-/){
			$arg=~s/^-//;
			while($arg ne ""){
				if    (${arg} eq "-test-mode--do-not-submit-transactions"){
					$arg="";
					$ARG_TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS=1;	# Will later be used to override "dmshomecucuprodigy.cfg" related setting of $CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS.
				}elsif(${arg} eq "-#" || $arg =~ /^-#/ || $arg =~ /^#/){
					$arg_desc="'--#'";
					if(${arg} eq "-#"){
						die("${0}: Argument ${arg_desc} requires a qualifier argument.\n") if @argv == 0;
						$ARG_COMMENT=&filter_inetd_conf_quotes(shift(@argv));
					}else{
						$ARG_COMMENT=substr(${arg},2);
					}
					if($arg =~ /^-/){ $arg=""; }else{ $arg=~s/^.//; }
				}elsif(${arg} eq "-servicesets" || $arg =~ /^s/){
					if($arg =~ /^-/){ $arg=""; }else{ $arg=~s/^.//; }
					$arg_desc="'--servicesets' (or '-s')";
					die("${0}: Argument ${arg_desc} requires a qualifier argument.\n") if @argv == 0;
					$ARG_SERVICESETS=&filter_inetd_conf_quotes(shift(@argv));
				}elsif(${arg} eq "-extension" || $arg =~ /^e/){
					# NOTE: Arguments "--extension extension" are for controlling testing (alternate) ".cfg" files and sub-directories within the production directory, while arguments "--cuid cuid" are for controlling the production ".cfg" files and sub-directories in a shared production directory.
					# Because "--extension extension" (${ARG_EXTENSION}) is used for "testing" it requires seperate (must be named including the value in ${VAR_EXTENSION}):
					#	"${DMS_HOMEDIR}/ADMIN${VAR_CUID}${VAR_EXTENSION}" directory (see where use_arg_extension_always() is called)
					#	"${DMS_HOMEDIR}/TMP${VAR_CUID}${VAR_EXTENSION}" directory (see where use_arg_extension_always() is called)
					# but allows usage of the "extension" (${VAR_EXTENSION}) to be optional (re-use the existing base when an "extension"ed one does not exist):
					#	"${DMS_HOMEDIR}/dmshomecucuprodigy.cfg${VAR_CUID}" file (see where use_arg_extension_if_exists() is called)
					#	"${DMS_HOMEDIR}/CACHE__MB_OVERRIDES${VAR_CUID}" directory (see where use_arg_extension_if_exists() is called)
					#	"${DMS_HOMEDIR}/CACHE__MB_DP_MICR${VAR_CUID}" directory (see where use_arg_extension_if_exists() is called)
					#	"${DMS_HOMEDIR}/CUSTOM${VAR_CUID}" directory (see where use_arg_extension_if_exists() is called)
					#	"${DMS_HOMEDIR}/MICR_OVERRIDES${VAR_CUID}" directory (see where use_arg_extension_if_exists() is called)
					if($arg =~ /^-/){ $arg=""; }else{ $arg=~s/^.//; }
					$arg_desc="'--extension' (or '-e')";
					die("${0}: Argument ${arg_desc} requires a qualifier argument.\n") if @argv == 0;
					$ARG_EXTENSION=&filter_inetd_conf_quotes(shift(@argv));
					die("${0}: The ${arg_desc} qualifier argument must be ALPHA, DIGIT, and UNDERSCORE chars.\n") if ${ARG_EXTENSION} =~ /\W/;
					if(${ARG_EXTENSION} ne ""){
						$VAR_EXTENSION=".${ARG_EXTENSION}";
					}
				}elsif(${arg} eq "-cuid"){
					# NOTE: Arguments "--cuid cuid" are for controlling the production ".cfg" files and sub-directories in a shared production directory, while arguments "--extension extension" are for controlling testing (alternate) ".cfg" files and sub-directories within the production directory.
					$arg="";
					$arg_desc="'--cuid'";
					die("${0}: Argument ${arg_desc} requires a qualifier argument.\n") if @argv == 0;
					$ARG_CUID=&filter_inetd_conf_quotes(shift(@argv));
					die("${0}: The ${arg_desc} qualifier argument must be at least 2 characters long and contain only the characters \"A\" to \"Z\" and \"0\" to \"9\" and \"_\".\n") if ${ARG_CUID} !~ /^[a-z][a-z0-9_][a-z0-9_]*$/i;
					($VAR_CUID=".".${ARG_CUID})=~tr/a-z/A-Z/;
				}elsif(${arg} eq "-homedir"){
					$arg="";
					$arg_desc="'--homedir'";
					die("${0}: Argument ${arg_desc} requires a qualifier argument.\n") if @argv == 0;
					$ARG_DMSHOMEDIR=&filter_inetd_conf_quotes(shift(@argv));
					die("${0}: The ${arg_desc} qualifier argument must be a full path.\n") if ${ARG_DMSHOMEDIR} !~ /^\//;
					die("${0}: The ${arg_desc} a qualifier argument must be an existant directory.\n") if ! -d ${ARG_DMSHOMEDIR};
				}elsif(${arg} eq "-customdir"){
					$arg="";
					$arg_desc="'--customdir'";
					die("${0}: Argument ${arg_desc} requires a qualifier argument.\n") if @argv == 0;
					$ARG_CUSTOMDIR=&filter_inetd_conf_quotes(shift(@argv));
					die("${0}: The ${arg_desc} qualifier argument must be a full path.\n") if ${ARG_CUSTOMDIR} !~ /^\//;
					die("${0}: The ${arg_desc} a qualifier argument must be an existant directory.\n") if ! -d ${ARG_CUSTOMDIR};
				}elsif(${arg} eq "-parse-stdin"){
					$arg="";
					$arg_desc="'--parse-stdin'";
					$ARG_PARSE_STDIN=1;
					die("${0}: The ${arg_desc} can not be used in combination with any other command line argument.\n") if @ARGV != 1;
				}else{
					print(STDERR "${0}: Invalid argument: -${arg}\n");
					die("USAGE: ${USAGE}\n");
				}
			}
		}else{
			print(STDERR "${0}: Invalid argument: ${arg}\n");
			die("USAGE: ${USAGE}\n");
		}
	}
	# Change some global variables if an argument overrides it.
	if(${ARG_DMSHOMEDIR} ne ""){
		$DMS_HOMEDIR=${ARG_DMSHOMEDIR};
	}
}

sub filter_inetd_conf_quotes{
   local($arg)=@_;
	# When using INETD.CONF, quotes are passed as literal characters,
	# so we need to strip them from the argument.
	if    ($arg=~/^"/ && $arg=~/"$/){
		$arg=substr($arg,1);
		$arg=substr($arg,0,length($arg)-1);
	}elsif($arg=~/^'/ && $arg=~/'$/){
		$arg=substr($arg,1);
		$arg=substr($arg,0,length($arg)-1);
	}
	return($arg);
}

sub sane_input_field_count{
   local($htmltag,$guess_mbnum,$count,@allowed)=@_;
   local($rtrn)=0;
	while(@allowed>0){
		if(${count} == $allowed[0]){
			$rtrn=1;
		}
		shift(@allowed);
	}
	if($rtrn==0){
		print STDOUT "<${htmltag}>${CTRL__EOL_CHARS}";
		&dms_status(${htmltag},${guess_mbnum},"999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."INVALID NUMBER OF INPUT FIELDS");
		print STDOUT "</${htmltag}>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	return($rtrn);
}

sub sane_mb_num_pwd{
   local($htmltag,$mbnum,$mbpwd)=@_;
   local($sane)=1;
	if($mbnum !~ /^\d\d*$/ || length($mbnum)>${CTRL__MAX_LEN_MBNUM}){
		$sane=0;
		&logfile("Invalid AccountNumber format\n");
	}
	if($mbpwd ne ""){ 1; }else{ 1; }	# The initial password can be anything.
	if(!$sane){
		print STDOUT "<${htmltag}>${CTRL__EOL_CHARS}";
		&dms_status(${htmltag},${mbnum},"001");
		print STDOUT "</${htmltag}>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	return($sane);
}

sub syncronize_dms{
   local($sync_text)=@_;
	&logfile("Syncronize.\n");
	print STDOUT "${sync_text}${CTRL__EOL_CHARS}";
	print STDOUT "EOT${CTRL__EOL_CHARS}";
	return(1);
}

sub life_cycle_init{
   local($max_requests,$max_seconds)=@_;
	# +--[ NOTE ]---------------------------------------------------------+
	# | To prevent this script getting too low of a UNIX priority, force  |
	# | the script to automatically exit when any of the specified limits |
	# | (number of requests or number of seconds) has been reached.       |
	# +-------------------------------------------------------------------+
	$max_requests=sprintf("%.0f",${max_requests});
	$max_seconds=sprintf("%.0f",${max_seconds});
	if(${max_requests} > 0){
		$life_cycle__request_remaining=sprintf("%.0f",${max_requests});
	}else{
		$life_cycle__request_remaining="";
	}
	if(${max_seconds} > 0){
		$life_cycle__max_time=sprintf("%.0f",time()+${max_seconds});
	}else{
		$life_cycle__max_time="";
	}
}

sub run_stop_restart_check{
   local($rtrn)=1;
   local($mtime);
   local($expiration_seconds);
   local(@f);
   local($timestamp);
	if(-f ${CTRL__RUN_STOP_RESTART__FILE}){
		$mtime=sprintf("%.0f",(stat(${CTRL__RUN_STOP_RESTART__FILE}))[9]);
		if(${mtime} > ${SCRIPT_START_TIME}){
			@f=localtime(${mtime});
			$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
			&run_stop_restart_shutdown_notification("until ${timestamp} (MTIME of file '${CTRL__RUN_STOP_RESTART__FILE}').");
			$rtrn=0;
		}else{
			$expiration_seconds=sprintf("%.0f",${CTRL__STDIN_TIMEOUT_READ_SECONDS} * ${CTRL__RUN_STOP_RESTART__EXPIRATION_MULTIPLIER});
			if(${mtime} + ${expiration_seconds} < time()){
				&logfile("Renaming expired Run/Stop/Restart file '${CTRL__RUN_STOP_RESTART__FILE}' to '${CTRL__RUN_STOP_RESTART__FILE}.old'.\n");
				if(!rename(${CTRL__RUN_STOP_RESTART__FILE},"${CTRL__RUN_STOP_RESTART__FILE}.old")){
					system("mv '${CTRL__RUN_STOP_RESTART__FILE}' '${CTRL__RUN_STOP_RESTART__FILE}.old' 2> /dev/null");
				}
			}
		}
	}
	return(${rtrn});
}

sub run_stop_restart_shutdown_notification{
   local($reason)=@_;
	&logfile("Shutdown: Stop/Restart ${reason}\n");
	print STDOUT "<Exiting>${CTRL__EOL_CHARS}";
	print STDOUT join("\t",0,"099","Please try again."),${CTRL__EOL_CHARS};
	print STDOUT "</Exiting>${CTRL__EOL_CHARS}";
}

sub life_cycle_seconds_check{
   local($rtrn)=0;
	if    (${life_cycle__max_time} eq ""){
		$rtrn=1;
	}elsif(${life_cycle__max_time} > time()){
		$rtrn=1;
	}else{
		&life_cycle_shutdown_notification("Maximum Time");
		$rtrn=0;
	}
	return(${rtrn});
}

sub life_cycle_request_check{
   local($rtrn)=0;
	if(${life_cycle__request_remaining} eq ""){
		$rtrn=1;
	}else{
		$life_cycle__request_remaining=sprintf("%.0f",${life_cycle__request_remaining}-1);
		if(${life_cycle__request_remaining} > 0){
			$rtrn=1;
		}else{
			&life_cycle_shutdown_notification("Maximum Requests");
			$rtrn=0;
		}
	}
	return(${rtrn});
}

sub life_cycle_shutdown_notification{
   local($reason)=@_;
	&logfile("Shutdown: Life Cycle reached ${reason}.\n");
	print STDOUT "<Exiting>${CTRL__EOL_CHARS}";
	print STDOUT join("\t",0,"099","Please try again."),${CTRL__EOL_CHARS};
	print STDOUT "</Exiting>${CTRL__EOL_CHARS}";
}

sub mb_overrides_load{
   my($mbnum)=@_;
   my($rtrn)=0;
   my($cachefile);
   my($mb_overrides,$mtime);
   my($line);
   my(@f);
   my($mb_override_key,$mb_override_value);
   local($SPOOL_DIR)=&use_arg_extension_if_exists("-d","${DMS_HOMEDIR}/CACHE__MB_OVERRIDES",${VAR_CUID},${VAR_EXTENSION});
   local($SPOOL_MBNUM_MAXLEN)=12;
   local($SPOOL_BTREE_WIDTH)=3;
	# Will populate (calling routine must have declared as "local()"):
	#	$MB_OVERRIDES
	#	%MB_OVERRIDES
	undef $MB_OVERRIDES;
	undef %MB_OVERRIDES;
	$cachefile=&cache_spoolmbfile(${mbnum},"NOCREATE");
	if(-f ${cachefile}){
		&logfile("Member Overrides Found: ${cachefile}\n");
		$MB_OVERRIDES=${mbnum};
		($mb_overrides,$mtime)=&cache_read(${mbnum},"NOCREATE");
		if($mb_overrides ne ""){
			$rtrn=1;
			foreach $line (split(/\n/,$mb_overrides)){
				$line=~s/[\r\n][\r\n]*$//;
				$line=~s/^\s\s*//;
				next if $line eq "";
				next if $line =~ /^#/;
				@f=split(/\t/,${line}." "); $f[$#f]=~s/ $//;
				next if $f[0] !~ /^\d{14}$/;	# Must be YYYYMMDDHHMMSS
				next if $f[1] ne ${mbnum};
				shift(@f);
				$mb_override_value=pop(@f);
				$mb_override_key=join($;,@f);
				$MB_OVERRIDES{${mb_override_key}}=${mb_override_value};
			}
		}
	}else{
		&logfile("Member Overrides Not Found: ${cachefile}\n");
	}
	return(${rtrn});
}

sub mb_dp_micr_cache{
   my($action,$mbnum,%micr_history)=@_;
   my(%MB_DP_MICR_CACHE);
   my($cachefile);
   my($mb_dp_micr_cache,$mtime);
   my($mb_dp_micr_cache_old,$mb_dp_micr_cache_new);
   my($line);
   my(@f);
   my($key);
   my($most_recent_date,$most_recent_micr);
   local($SPOOL_DIR)=&use_arg_extension_if_exists("-d","${DMS_HOMEDIR}/CACHE__MB_DP_MICR",${VAR_CUID},${VAR_EXTENSION});
   local($SPOOL_MBNUM_MAXLEN)=12;
   local($SPOOL_BTREE_WIDTH)=3;
	$cachefile=&cache_spoolmbfile(${mbnum});
	if($action =~ /^load$/i){
		($mb_dp_micr_cache,$mtime)=&cache_read(${mbnum});
		if($mb_dp_micr_cache ne ""){
			foreach $line (split(/\n/,$mb_dp_micr_cache)){
				$line=~s/[\r\n][\r\n]*$//;
				$line=~s/^\s\s*//;
				next if $line eq "";
				next if $line =~ /^#/;
				@f=split(/\t/,${line}." "); $f[$#f]=~s/ $//;
				next if @f < 4;
				next if $f[0] ne ${mbnum};
				$key=join($;,$f[0],$f[1],$f[2]); shift(@f); shift(@f); shift(@f);
				while(@f>0){
					if($f[0] =~ /^\d{14}:/){	# Must begin with YYYYMMDDHHMMSS
						if($MB_DP_MICR_CACHE{${key}} eq ""){
							$MB_DP_MICR_CACHE{${key}}=$f[0];
						}else{
							$MB_DP_MICR_CACHE{${key}}.="\t".$f[0];
						}
					}
					shift(@f);
				}
			}
		}
		foreach $key (sort(keys(%MB_DP_MICR_CACHE))){
			@f=reverse(sort(split(/\t/,$MB_DP_MICR_CACHE{${key}})));
			$MB_DP_MICR_CACHE{${key}}=join("\t",@f);
		}
	}
	if($action =~ /^save$/i){
		$mb_dp_micr_cache_new="";
		foreach $key (sort(keys(%micr_history))){
			@f=(reverse(sort(split(/\t/,$micr_history{${key}}))));
			while(@f > 10){ pop(@f); }	# Remember the MICR's last 10 mutations.
			$micr_history{${key}}=join("\t",@f);
			$mb_dp_micr_cache_new.=join("\t",(split(/$;/,${key})))."\t".$micr_history{${key}}."\n";
		}
		($mb_dp_micr_cache_old,$mtime)=&cache_read(${mbnum});
		if(${mb_dp_micr_cache_old} ne ${mb_dp_micr_cache_new}){
			&cache_write(${mbnum},${mb_dp_micr_cache_new});
		}
	}
	return(%MB_DP_MICR_CACHE);
}

sub inquiry{
   local($full_inquiry,$mbnum,$initial_password,$override_date_dp,$override_date_ln,$email,$single_dp_ln,$single_member,$single_account,$single_cert)=@_;
   local(%XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY);
   local(@XML_MB_DP_HIST);
   local(@XML_MB_LN_HIST);
   local(@XML_MB_CC_HIST);
   local(@XML_MB_HOLDS);
   local(@XML_MB_PLASTIC_CARDS,@XML_MB_PLASTIC_CARDS_WIP);
   local(@f);
   local($idx);
   local($line);
   local($mbpwd);
   local($failure_text);
   local($balances_row,$balances_before,$balances_after);
   local($cuprodigy_beg_ccyymmdd_dp,$cuprodigy_beg_ccyymmdd_ln,$cuprodigy_beg_ccyymmdd_cc);
   local($cuprodigy_beg_ccyymmdd_all,@cuprodigy_beg_ccyymmdd_all);
   local($cuprodigy_cutoff_ccyymmdd);
   local($cutoff_ccyymmdd,$cutoff_ccyymmdd_dp,$cutoff_ccyymmdd_ln);
   local($CURR_TIME);
   local($BEG_CCYYMMDD_DP,$END_CCYYMMDD_DP);
   local($BEG_CCYYMMDD_LN,$END_CCYYMMDD_LN);
   local($override_CCYYMMDD_dp,$override_CCYYMMDD_ln);
   local($core_degradation_check__remaining);
   local($core_degradation_check__time_beg,$core_degradation_check__time_end,$core_degradation_check__row_count,$core_degradation_check__bal_count);
   local($cuprodigy_method_used_for_inquiry_of_everything)	="Inquiry";			# As is known will be choosen in cuprodigy_xml_balances_and_history() for balances and history
   local($cuprodigy_method_used_for_inquiry_of_balances_only)	="AccountInquiry";		# As is known will be choosen in cuprodigy_xml_balances_and_history() for balances only
   local($cuprodigy_method_used_for_inquiry_of_single_dp)	="AccountDetailInquiry";	# As is known will be choosen in cuprodigy_xml_balances_and_history() for a single DP
   local($cuprodigy_method_used_for_inquiry_of_single_ln)	="AccountDetailInquiry";	# As is known will be choosen in cuprodigy_xml_balances_and_history() for a single LN
   local($cuprodigy_method_used);
	# Will populate (calling routine must have declared as "local()"):
	#	%CACHE_MB_DP_TO_MICR
	#	@XML_MB_EMAIL
	#	@XML_MB_UNIQID
	#	@XML_MB_DP_UNIQID
	#	@XML_MB_LN_UNIQID
	#	@XML_MB_CC_UNIQID
	#	@XML_MB_DP_BALS
	#	@XML_MB_LN_BALS
	#	@XML_MB_CC_BALS, %XML_MB_CC_TO_UNIQ, %XML_MB_CC_FROM_UNIQ
	#	@XML_MB_XAC
	#	@XML_MB_DP_GROUPS
	#	@XML_MB_LN_GROUPS
	#	@XML_MB_CC_GROUPS
	#	@XML_MB_DP_ATTRS
	#	@XML_MB_LN_ATTRS
	#	@XML_MB_CC_ATTRS
	#	@XML_MB_DP_ACCESS_INFO
	#	@XML_MB_LN_ACCESS_INFO
	#	@XML_MB_CC_ACCESS_INFO
	#	@XML_MB_DP_EXPIRED
	#	@XML_MB_LN_EXPIRED
	#	@XML_MB_CC_EXPIRED
	#	@XML_MB_LN_PAYOFF
	#	@XML_MB_CC_PAYOFF
	undef(%CACHE_MB_DP_TO_MICR);
	undef(@XML_MB_EMAIL);
	undef(@XML_MB_UNIQID);
	undef(@XML_MB_DP_UNIQID);
	undef(@XML_MB_LN_UNIQID);
	undef(@XML_MB_CC_UNIQID);
	undef(@XML_MB_DP_BALS);
	undef(@XML_MB_LN_BALS);
	undef(@XML_MB_CC_BALS); undef(%XML_MB_CC_TO_UNIQ); undef(%XML_MB_CC_FROM_UNIQ);
	undef(@XML_MB_XAC);
	undef(@XML_MB_XJO);
	undef(@XML_MB_DP_GROUPS);
	undef(@XML_MB_LN_GROUPS);
	undef(@XML_MB_CC_GROUPS);
	undef(@XML_MB_DP_ATTRS);
	undef(@XML_MB_LN_ATTRS);
	undef(@XML_MB_CC_ATTRS);
	undef(@XML_MB_DP_ACCESS_INFO);
	undef(@XML_MB_LN_ACCESS_INFO);
	undef(@XML_MB_CC_ACCESS_INFO);
	undef(@XML_MB_DP_EXPIRED);
	undef(@XML_MB_LN_EXPIRED);
	undef(@XML_MB_CC_EXPIRED);
	undef(@XML_MB_LN_PAYOFF);
	undef(@XML_MB_CC_PAYOFF);
	if(${failure_text} eq ""){
		if(!${CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__INQ_INITIAL_PASSWORD}){
			if(${initial_password} ne ""){
				&logfile("The \$CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__INQ_INITIAL_PASSWORD is disabled, so the INQ request with an \"initial password\" value is not permitted.\n");
				$failure_text=join("\t","002",${CTRL__ERROR_NNN_PREFIX__DMS_ABNORMAL}."Initial password method not allowed.","The configuration variable \$CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__INQ_INITIAL_PASSWORD is disabled, so the INQ initial password value is rejected.");
			}
		}
	}
	if(${failure_text} eq ""){
		if(${full_inquiry}){
			if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_INQ_REQUEST}){
				if(($core_degradation_check__remaining=&core_degradation_check("remaining","INQ|${mbnum}|${initial_password}|${override_date_dp}|${override_date_ln}")) > 0){
					$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
				}else{
					&core_degradation_check("began","INQ|${mbnum}|${initial_password}|${override_date_dp}|${override_date_ln}");
				}
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		if(${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__VALIDATE_PASSWORD} or ${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__GET_MEMBER_AUTO_ENROLL_INFO}){
			if(${initial_password} ne ""){
				$failure_text=&cuprodigy_xml_initial_password(${mbnum},${mbpwd},${initial_password});
				$initial_password="";	# Now that cuprodigy_xml_initial_password() has checked the initial password, clear it so that nothing else will attempt to check it later in the script.
			}
		}elsif($CUSTOM{"custom_password.pi"}>0){
			if(${initial_password} ne ""){
				if(&custom_password__validate(${mbnum},${mbpwd},${initial_password})){
					$initial_password="";	# Now that custom_password__validate() has checked the initial password, clear it so that nothing else will attempt to check it later in the script.
				}else{
					$failure_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
				}
			}
		}
	}
	if(${failure_text} eq ""){
		if(${full_inquiry} > 0){
			$CURR_TIME=time();
			$BEG_CCYYMMDD_DP=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__HISTORY_DAYS_DP}*24*60*60));
			$END_CCYYMMDD_DP=&time_to_CCYYMMDD(${CURR_TIME}+(${CTRL__HISTORY_DAYS_FUTURE}*24*60*60));
			$BEG_CCYYMMDD_LN=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__HISTORY_DAYS_LN}*24*60*60));
			$END_CCYYMMDD_LN=&time_to_CCYYMMDD(${CURR_TIME}+(${CTRL__HISTORY_DAYS_FUTURE}*24*60*60));
			if(${override_date_dp} ne ""){
				$override_CCYYMMDD_dp=&date_to_CCYYMMDD(${override_date_dp});
				if(${BEG_CCYYMMDD_DP} < ${override_CCYYMMDD_dp}){
					$BEG_CCYYMMDD_DP=${override_CCYYMMDD_dp};
				}
			}
			if(${override_date_ln} ne ""){
				$override_CCYYMMDD_ln=&date_to_CCYYMMDD(${override_date_ln});
				if(${BEG_CCYYMMDD_LN} < ${override_CCYYMMDD_ln}){
					$BEG_CCYYMMDD_LN=${override_CCYYMMDD_ln};
				}
			}
			if(${CONF__MINDATE_VALID_CUPRODIGY_HISTORY} ne ""){
				if(${BEG_CCYYMMDD_DP} lt ${CONF__MINDATE_VALID_CUPRODIGY_HISTORY}){
					$BEG_CCYYMMDD_DP=${CONF__MINDATE_VALID_CUPRODIGY_HISTORY};
				}
				if(${BEG_CCYYMMDD_LN} lt ${CONF__MINDATE_VALID_CUPRODIGY_HISTORY}){
					$BEG_CCYYMMDD_LN=${CONF__MINDATE_VALID_CUPRODIGY_HISTORY};
				}
			}
		}
	}
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} > 0){
			$core_degradation_check__time_beg=time();
		}
	}
	if(${failure_text} eq ""){
		if    ($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
			if($single_member =~ /^\s*$/){ $single_member=${mbnum}; }
			$cuprodigy_method_used="${cuprodigy_method_used_for_inquiry_of_balances_only}";	# As is known will be choosen in cuprodigy_xml_balances_and_history() for balances only
			&logfile("Query ${mbnum}: ${cuprodigy_method_used}\n") if ${full_inquiry} > 0;
			$mbpwd=&cuprodigy_request_memberpwd(${mbnum});
			$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},${initial_password},"","",( ${full_inquiry} > 0 ? 1 : 0 ),${single_dp_ln});
		}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
			$cuprodigy_method_used="${cuprodigy_method_used_for_inquiry_of_single_dp} for ".join("/","DP",${single_member},${single_account},${single_cert});	# As is known will be choosen in cuprodigy_xml_balances_and_history() for a single DP
			&logfile("DP History from ".${BEG_CCYYMMDD_DP}." to ".${END_CCYYMMDD_DP}.".\n") if ${full_inquiry} > 0;
			push(@INQ_RESPONSE_NOTES,join("\t","DP",${mbnum},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"DP History from ".${BEG_CCYYMMDD_DP}." to ".${END_CCYYMMDD_DP}.".\n")) if ${full_inquiry} > 0;
			if(!${CTRL__RECHECK_BALANCES_AFTER_HISTORY} or !${full_inquiry}){
				&logfile("Query ${mbnum}: ${cuprodigy_method_used}\n") if ${full_inquiry} > 0;
			}else{
				&logfile("Query ${mbnum}: ${cuprodigy_method_used} (before)\n") if ${full_inquiry} > 0;
			}
			$mbpwd=&cuprodigy_request_memberpwd(${mbnum});
			$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},${initial_password},${BEG_CCYYMMDD_DP},"",( ${full_inquiry} > 0 ? 1 : 0 ),${single_dp_ln},${single_member},${single_account},${single_cert});
		}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
			$cuprodigy_method_used="${cuprodigy_method_used_for_inquiry_of_single_ln} for ".join("/","LN",${single_member},${single_account});	# As is known will be choosen in cuprodigy_xml_balances_and_history() for a single LN
			&logfile("LN History from ".${BEG_CCYYMMDD_LN}." to ".${END_CCYYMMDD_LN}.".\n") if ${full_inquiry} > 0;
			push(@INQ_RESPONSE_NOTES,join("\t","LN",${mbnum},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"LN History from ".${BEG_CCYYMMDD_LN}." to ".${END_CCYYMMDD_LN}.".\n")) if ${full_inquiry} > 0;
			if(!${CTRL__RECHECK_BALANCES_AFTER_HISTORY} or !${full_inquiry}){
				&logfile("Query ${mbnum}: ${cuprodigy_method_used}\n") if ${full_inquiry} > 0;
			}else{
				&logfile("Query ${mbnum}: ${cuprodigy_method_used} (before)\n") if ${full_inquiry} > 0;
			}
			$mbpwd=&cuprodigy_request_memberpwd(${mbnum});
			$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},${initial_password},"",${BEG_CCYYMMDD_LN},( ${full_inquiry} > 0 ? 1 : 0 ),${single_dp_ln},${single_member},${single_account},${single_cert});
		}else{
			$cuprodigy_method_used="${cuprodigy_method_used_for_inquiry_of_everything}";	# As is known will be choosen in cuprodigy_xml_balances_and_history() for balances and history
			&logfile("DP History from ".${BEG_CCYYMMDD_DP}." to ".${END_CCYYMMDD_DP}.".\n") if ${full_inquiry} > 0;
			&logfile("LN History from ".${BEG_CCYYMMDD_LN}." to ".${END_CCYYMMDD_LN}.".\n") if ${full_inquiry} > 0;
			push(@INQ_RESPONSE_NOTES,join("\t","DP",${mbnum},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"DP History from ".${BEG_CCYYMMDD_DP}." to ".${END_CCYYMMDD_DP}.".\n")) if ${full_inquiry} > 0;
			push(@INQ_RESPONSE_NOTES,join("\t","LN",${mbnum},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"LN History from ".${BEG_CCYYMMDD_LN}." to ".${END_CCYYMMDD_LN}.".\n")) if ${full_inquiry} > 0;
			$mbpwd=&cuprodigy_request_memberpwd(${mbnum});
			if(!${CTRL__RECHECK_BALANCES_AFTER_HISTORY} or !${full_inquiry}){
				&logfile("Query ${mbnum}: ${cuprodigy_method_used}\n") if ${full_inquiry} > 0;
			}else{
				&logfile("Query ${mbnum}: ${cuprodigy_method_used} (before)\n") if ${full_inquiry} > 0;
			}
			$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},${initial_password},${BEG_CCYYMMDD_DP},${BEG_CCYYMMDD_LN},( ${full_inquiry} > 0 ? 1 : 0 ));
		}
	}
	if(${full_inquiry} <= 0){
		return(${failure_text});
	}
	if(${failure_text} eq ""){
		if(${CTRL__RECHECK_BALANCES_AFTER_HISTORY}!=0){
			foreach $balances_row (sort(@XML_MB_DP_BALS)){
				$balances_before.=$balances_row."\n";
			}
			foreach $balances_row (sort(@XML_MB_LN_BALS)){
				$balances_before.=$balances_row."\n";
			}
			foreach $balances_row (sort(@XML_MB_CC_BALS)){
				$balances_before.=$balances_row."\n";
			}
			if    ($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
				$balances_after=${balances_before};
			}else{
				&logfile("Query ${mbnum}: ${cuprodigy_method_used} (after)\n");
				if    ($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
					$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},"","","",0,${single_dp_ln},${single_member},${single_account},${single_cert});
				}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
					$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},"","","",0,${single_dp_ln},${single_member},${single_account},${single_cert});
				}else{
					$failure_text=&cuprodigy_xml_balances_and_history(${full_inquiry},${mbnum},${mbpwd},"","","",0);
				}
				if(${failure_text} eq ""){
					foreach $balances_row (sort(@XML_MB_DP_BALS)){
						$balances_after.=$balances_row."\n";
					}
					foreach $balances_row (sort(@XML_MB_LN_BALS)){
						$balances_after.=$balances_row."\n";
					}
					foreach $balances_row (sort(@XML_MB_CC_BALS)){
						$balances_after.=$balances_row."\n";
					}
					if($balances_before ne $balances_after){
						&busy_bals_log(${mbnum},${balances_before},${balances_after});
						$failure_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."MEMBER ACCOUNT IS BUSY");
					}
				}
			}
		}
	}
	if(${failure_text} eq ""){
		if(${CONF__PLASTIC_CARD__USE}){
			while(@XML_MB_PLASTIC_CARDS_WIP > 0){
				($dms_accountnumber,$dms_cardsignature_composit,$dms_cardstatus,$dms_issuedate,$dms_expiredate,$dms_description,$dms_attached_deposittype,$dms_attached_membernumber,$dms_attached_subaccount,$dms_attached_description,$dms_pan,$cuprodigy_code)=split(/\t/,shift(@XML_MB_PLASTIC_CARDS_WIP));
				($failure_text,$dms_attached_deposittype,$dms_attached_membernumber,$dms_attached_subaccount,$dms_attached_description)=&cuprodigy_xml_get_plastic_card_attached(${mbnum},${mbpwd},${dms_pan});
				if(${failure_text} ne ""){
					&logfile("inquiry(): cuprodigy_xml_get_plastic_card_attached(): ".${failure_text}."\n");
					push(@INQ_RESPONSE_NOTES,join("\t","PC",${mbnum},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"inquiry(): cuprodigy_xml_get_plastic_card_attached(): ".${failure_text}."\n"));
					$failure_text="";
				}
				push(@XML_MB_PLASTIC_CARDS,
					join("\t",
						${dms_accountnumber},
						${dms_cardsignature_composit},
						${dms_cardstatus},
						${dms_issuedate},
						${dms_expiredate},
						${dms_description},
						${dms_attached_deposittype},
						${dms_attached_membernumber},
						${dms_attached_subaccount},
						${dms_attached_description}
					)
				);
			}
		}
	}
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} > 0){
			$core_degradation_check__time_end=time();
		}
	}
	if(${failure_text} eq ""){
		# CUProdigy does allow DMS/HomeCU to specify a date range for transaction history.
		$cutoff_ccyymmdd=&min_date(${BEG_CCYYMMDD_DP},${BEG_CCYYMMDD_LN});
		$cutoff_ccyymmdd_dp=${BEG_CCYYMMDD_DP};
		$cutoff_ccyymmdd_ln=${BEG_CCYYMMDD_LN};
		# Note that because CUProdigy does allow DMS/HomeCU to specify a date range for transaction history, the $CONF__MINDATE_VALID_CUPRODIGY_HISTORY is handled as part of the query (in the subroutine cuprodigy_xml_balances_and_history__parse_history()) instead of as a filter after the query (here in subroutine inquiry()).
	}
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} > 0){
			# Calculation of $core_degradation_check__row_count occurs in "inquiry()" and "core_degradation_check__killed__estimate_row_count()".
			$core_degradation_check__row_count=0;
			$core_degradation_check__row_count+=@XML_MB_DP_BALS;
			$core_degradation_check__row_count+=@XML_MB_LN_BALS;
			$core_degradation_check__row_count+=@XML_MB_CC_BALS;
			$core_degradation_check__row_count+=@XML_MB_DP_HIST;
			$core_degradation_check__row_count+=@XML_MB_LN_HIST;
			$core_degradation_check__row_count+=@XML_MB_CC_HIST;
			$core_degradation_check__row_count+=@XML_MB_HOLDS;
			$core_degradation_check__row_count+=@XML_MB_PLASTIC_CARDS;
			if(${CTRL__RECHECK_BALANCES_AFTER_HISTORY}!=0){
				$core_degradation_check__row_count+=@XML_MB_DP_BALS;
				$core_degradation_check__row_count+=@XML_MB_LN_BALS;
				$core_degradation_check__row_count+=@XML_MB_CC_BALS;
			}
			$core_degradation_check__bal_count=0;
			$core_degradation_check__bal_count+=@XML_MB_DP_BALS;
			$core_degradation_check__bal_count+=@XML_MB_LN_BALS;
			$core_degradation_check__bal_count+=@XML_MB_CC_BALS;
			&core_degradation_check("calculate","INQ|${mbnum}|${initial_password}|${cutoff_ccyymmdd_dp}|${cutoff_ccyymmdd_ln}",${core_degradation_check__time_beg},${core_degradation_check__time_end},${core_degradation_check__row_count},${core_degradation_check__bal_count});
		}
	}
	if(${failure_text} eq ""){
		&logfile("Output ${mbnum}: Details\n");
		print STDOUT "<Inquiry>${CTRL__EOL_CHARS}";
		&dms_status("Inquiry",${mbnum},"000");
		if    ($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
			print STDOUT "<Parameters>${CTRL__EOL_CHARS}"; print STDOUT join("\t",${mbnum},"99991231",${single_dp_ln},${single_member}),${CTRL__EOL_CHARS}; print STDOUT "</Parameters>${CTRL__EOL_CHARS}";
		}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
			if(1){
				# Re-align $single_cert to a known (that will match the database) value if it happened to get submitted in the INQ request as "" instead of "0".
				if((split(/\t/,$XML_MB_DP_BALS[0]))[2] =~ /\d/){ $single_cert=(split(/\t/,$XML_MB_DP_BALS[0]))[2]; }
				if($single_cert =~ /^\s*$/){ $single_cert="0"; }	
			}
			print STDOUT "<Parameters>${CTRL__EOL_CHARS}"; print STDOUT join("\t",${mbnum},${cutoff_ccyymmdd},${single_dp_ln},${single_member},${single_account},${single_cert}),${CTRL__EOL_CHARS}; print STDOUT "</Parameters>${CTRL__EOL_CHARS}";
		}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
			print STDOUT "<Parameters>${CTRL__EOL_CHARS}"; print STDOUT join("\t",${mbnum},${cutoff_ccyymmdd},${single_dp_ln},${single_member},${single_account}),${CTRL__EOL_CHARS}; print STDOUT "</Parameters>${CTRL__EOL_CHARS}";
		}else{
			print STDOUT "<Parameters>${CTRL__EOL_CHARS}"; print STDOUT join("\t",${mbnum},${cutoff_ccyymmdd}),${CTRL__EOL_CHARS}; print STDOUT "</Parameters>${CTRL__EOL_CHARS}";
		}
		print STDOUT "<Member>${CTRL__EOL_CHARS}"; print STDOUT ${mbnum},"\t",${CTRL__EOL_CHARS}; print STDOUT "</Member>${CTRL__EOL_CHARS}";
		print STDOUT "<Messages>${CTRL__EOL_CHARS}"; print STDOUT "</Messages>${CTRL__EOL_CHARS}";
		if(${CONF__SUBACCOUNT_RECAST_UNIQID__USE}){
			print STDOUT "<MemberUniqId>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			print STDOUT "</MemberUniqId>${CTRL__EOL_CHARS}";
			if($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
				print STDOUT "<AccountUniqId>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_DP_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
				print STDOUT "</AccountUniqId>${CTRL__EOL_CHARS}";
			}
			if($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
				print STDOUT "<LoanUniqId>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_LN_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
				foreach $line (@XML_MB_CC_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
				print STDOUT "</LoanUniqId>${CTRL__EOL_CHARS}";
			}
		}
		if($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
			print STDOUT "<AccountBalance>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_DP_BALS){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			print STDOUT "</AccountBalance>${CTRL__EOL_CHARS}";
			if(${CONF__INQ__BALANCE_ATTRIBUTES}){
				print STDOUT "<AccountAttributes>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_DP_ATTRS){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
				print STDOUT "</AccountAttributes>${CTRL__EOL_CHARS}";
			}
		}
		if($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
			print STDOUT "<LoanBalance>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_LN_BALS){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			foreach $line (@XML_MB_CC_BALS){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			print STDOUT "</LoanBalance>${CTRL__EOL_CHARS}";
			if(${CONF__INQ__BALANCE_ATTRIBUTES}){
				print STDOUT "<LoanAttributes>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_LN_ATTRS){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
				foreach $line (@XML_MB_CC_ATTRS){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
				print STDOUT "</LoanAttributes>${CTRL__EOL_CHARS}";
			}
		}
		if    ($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
			if($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
				print STDOUT "<AccountHistory>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_DP_HIST){ print STDOUT $line,${CTRL__EOL_CHARS}; }
				print STDOUT "</AccountHistory>${CTRL__EOL_CHARS}";
			}
			if($single_dp_ln !~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
				print STDOUT "<LoanHistory>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_LN_HIST){ print STDOUT $line,${CTRL__EOL_CHARS}; }
				foreach $line (@XML_MB_CC_HIST){ print STDOUT $line,${CTRL__EOL_CHARS}; }
				print STDOUT "</LoanHistory>${CTRL__EOL_CHARS}";
			}
		}
		if($single_dp_ln =~ /^\s*$/ or $single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io or $single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io or $single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
			print STDOUT "<Holds>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_HOLDS){ print STDOUT $line,${CTRL__EOL_CHARS}; }
			print STDOUT "</Holds>${CTRL__EOL_CHARS}";
		}
		if($single_dp_ln =~ /^\s*$/ or $single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io or $single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io or $single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
			if(${CONF__PLASTIC_CARD__USE}){
				print STDOUT "<PlasticCards>${CTRL__EOL_CHARS}";
				foreach $line (@XML_MB_PLASTIC_CARDS){ print STDOUT $line,${CTRL__EOL_CHARS}; }
				print STDOUT "</PlasticCards>${CTRL__EOL_CHARS}";
			}
		}
		&xxx_response_notes_print_STDOUT_as_XML("INQ",@INQ_RESPONSE_NOTES) if ${CONF__INQ__RESPONSE_NOTES__INCLUDE};
		print STDOUT "</Inquiry>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	if(${failure_text} ne ""){
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<Inquiry>${CTRL__EOL_CHARS}";
		&dms_status("Inquiry",${mbnum},(split("\t",${failure_text},2)));
		&xxx_response_notes_print_STDOUT_as_XML("INQ",@INQ_RESPONSE_NOTES) if ${CONF__INQ__RESPONSE_NOTES__INCLUDE};
		print STDOUT "</Inquiry>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		return(${failure_text});
	}
	&logfile("Output ${mbnum}: Finished\n");
	return(${failure_text});
}

sub emailupdate{
   local($mbnum,$email)=@_;
   local($failure_text);
   local($found_mbnum,$found_email);
   local($mbpwd);
	($found_mbnum,$found_email)=split("\t",$XML_MB_EMAIL[0]);	# As loaded by cuprodigy_xml_balances_and_history__parse_email() (as called by cuprodigy_xml_balances_and_history() as called by inquiry()).
	if(${mbnum} eq ${found_mbnum}){
		$mbpwd=&cuprodigy_request_memberpwd(${mbnum});
		$failure_text=&cuprodigy_xml_emailupdate(${mbnum},${mbpwd},${email},${found_email});
	}
	return(${failure_text});
}

sub xac_inquiry{
   local($mbnum)=@_;
   local($line);
   local($failure_text);
   local(@XML_MB_UNIQID);
   local(@XML_MB_DP_UNIQID);
   local(@XML_MB_LN_UNIQID);
   local(@XML_MB_CC_UNIQID);
   local(@XML_MB_XAC);
   local(@XML_MB_XAC_LN_PAYOFF);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_XAC_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","XAC|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		$failure_text=&cuprodigy_xml_crossaccount(${mbnum},"",1);
	}
	if(${failure_text} ne ""){
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<CrossAccount>${CTRL__EOL_CHARS}";
		&dms_status("CrossAccount",${mbnum},(split("\t",${failure_text},2)));
		&xxx_response_notes_print_STDOUT_as_XML("XAC",@XAC_RESPONSE_NOTES) if ${CONF__XAC__RESPONSE_NOTES__INCLUDE};
		print STDOUT "</CrossAccount>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}else{
		# Send the output
		&logfile("Output ${mbnum} XAC: Details\n");
		print STDOUT "<CrossAccount>${CTRL__EOL_CHARS}";
		&dms_status__was_not_used_here("CrossAccount",${mbnum},"000","");
		print STDOUT "<Member>${CTRL__EOL_CHARS}"; print STDOUT ${mbnum},${CTRL__EOL_CHARS}; print STDOUT "</Member>${CTRL__EOL_CHARS}";
		if(${CONF__SUBACCOUNT_RECAST_UNIQID__USE}){
			print STDOUT "<MemberUniqId>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			print STDOUT "</MemberUniqId>${CTRL__EOL_CHARS}";
			print STDOUT "<AccountUniqId>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_DP_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			print STDOUT "</AccountUniqId>${CTRL__EOL_CHARS}";
			print STDOUT "<LoanUniqId>${CTRL__EOL_CHARS}";
			foreach $line (@XML_MB_LN_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			foreach $line (@XML_MB_CC_UNIQID){ print STDOUT $line,${CTRL__EOL_CHARS} if ${line} ne ""; }
			print STDOUT "</LoanUniqId>${CTRL__EOL_CHARS}";
		}
		print STDOUT "<TxAccount>${CTRL__EOL_CHARS}";
		foreach $line (@XML_MB_XAC){ print STDOUT $line,${CTRL__EOL_CHARS}; }
		print STDOUT "</TxAccount>${CTRL__EOL_CHARS}";
		&xxx_response_notes_print_STDOUT_as_XML("XAC",@XAC_RESPONSE_NOTES) if ${CONF__XAC__RESPONSE_NOTES__INCLUDE};
		print STDOUT "</CrossAccount>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	&logfile("Output ${mbnum} XAC: Finished\n");
	return(${failure_text});
}

sub xjo_overloaded_account_list{
   local($mbnum)=@_;
   local($line);
   local($failure_text,$composit_mir_data);
   local(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_MIR_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","MIR|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		$failure_text=&cuprodigy_xml_xjo_overloaded_accounts(${mbnum},${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD},1);
	}
	if(${failure_text} eq ""){
		return(${failure_text},@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST);
	}else{
		return(${failure_text});
	}
}

sub mir_inquiry{
   local($mbnum,$only_return_mir_data)=@_;
   local($line);
   local($failure_text,$composit_mir_data);
   local(%XML_MB_MIR);
   local($mir_firstname,$mir_middlename,$mir_lastname);
   local($mir_homephone,$mir_workphone,$mir_cellphone,$mir_faxphone);
   local($mir_ssn);
   local(@MIR_REQUEST_DEBUGGING);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_MIR_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","MIR|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		$failure_text=&cuprodigy_xml_get_member_auto_enroll_info(${mbnum},${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD});
	}
	if(${failure_text} eq ""){
		if($CUSTOM{"custom_parsing_mir.pi"}>0){

			($XML_MB_MIR{"NAMEFIRST"}, $XML_MB_MIR{"NAMEMIDDLE"}, $XML_MB_MIR{"NAMELAST"})=&custom_parsing_mir("name",${mbnum});
		}
		if($CUSTOM{"custom_parsing_mir.pi"}>0){
			($XML_MB_MIR{"PHONEHOME"},$XML_MB_MIR{"PHONEWORK"},$XML_MB_MIR{"PHONECELL"},$XML_MB_MIR{"PHONEFAX"})=&custom_parsing_mir("phone",${mbnum});
		}
		if($CUSTOM{"custom_parsing_mir.pi"}>0){
			$XML_MB_MIR{"SSN"}=&custom_parsing_mir("ssn",${mbnum});
		}
	}
	if(${only_return_mir_data}>0){
		$composit_mir_data=join("\t",
			$XML_MB_MIR{"ACCOUNTNUMBER"},
			$XML_MB_MIR{"NAMEFIRST"},
			$XML_MB_MIR{"NAMEMIDDLE"},
			$XML_MB_MIR{"NAMELAST"},
			$XML_MB_MIR{"EMAIL"},
			$XML_MB_MIR{"PHONEHOME"},
			$XML_MB_MIR{"PHONEWORK"},
			$XML_MB_MIR{"PHONECELL"},
			$XML_MB_MIR{"PHONEFAX"},
			$XML_MB_MIR{"SSN"},
			$XML_MB_MIR{"ADDRESS","ADDRESS1"},
			$XML_MB_MIR{"ADDRESS","ADDRESS2"},
			$XML_MB_MIR{"ADDRESS","CITY"},
			$XML_MB_MIR{"ADDRESS","STATE"},
			$XML_MB_MIR{"ADDRESS","POSTALCODE"},
			$XML_MB_MIR{"ADDRESS","COUNTRY"},
			$XML_MB_MIR{"DATEOFBIRTH"},
			$XML_MB_MIR{"MEMBERTYPE"}
		);
	}else{
		if(${failure_text} ne ""){
			$failure_text=~s/^.*\n//;	# Use just the last failure message.
			&logfile("Output ${mbnum}: Error\n");
			print STDOUT "<MemberInfo>${CTRL__EOL_CHARS}";
			&dms_status("MemberInfo",${mbnum},(split("\t",${failure_text},2)));
			&xxx_response_notes_print_STDOUT_as_XML("MIR",@MIR_RESPONSE_NOTES) if ${CONF__MIR__RESPONSE_NOTES__INCLUDE};
			print STDOUT "</MemberInfo>${CTRL__EOL_CHARS}";
			print STDOUT "EOT${CTRL__EOL_CHARS}";
		}else{
			# Send the output
			&logfile("Output ${mbnum} MIR: Details\n");
			print STDOUT "<MemberInfo>${CTRL__EOL_CHARS}";
			&dms_status__was_not_used_here("MemberInfo",${mbnum},"000","");
			print STDOUT "<Member>${CTRL__EOL_CHARS}"; print STDOUT ${mbnum},${CTRL__EOL_CHARS}; print STDOUT "</Member>${CTRL__EOL_CHARS}";
			print STDOUT "<Info>${CTRL__EOL_CHARS}";
			print STDOUT join("\t",
				$XML_MB_MIR{"ACCOUNTNUMBER"},
				$XML_MB_MIR{"NAMEFIRST"},
				$XML_MB_MIR{"NAMEMIDDLE"},
				$XML_MB_MIR{"NAMELAST"},
				$XML_MB_MIR{"EMAIL"},
				$XML_MB_MIR{"PHONEHOME"},
				$XML_MB_MIR{"PHONEWORK"},
				$XML_MB_MIR{"PHONECELL"},
				$XML_MB_MIR{"PHONEFAX"},
				$XML_MB_MIR{"SSN"},
				$XML_MB_MIR{"ADDRESS","ADDRESS1"},
				$XML_MB_MIR{"ADDRESS","ADDRESS2"},
				$XML_MB_MIR{"ADDRESS","CITY"},
				$XML_MB_MIR{"ADDRESS","STATE"},
				$XML_MB_MIR{"ADDRESS","POSTALCODE"},
				$XML_MB_MIR{"ADDRESS","COUNTRY"},
				$XML_MB_MIR{"DATEOFBIRTH"} .
				( ${CONF__MIR__MEMBERTYPE__INCLUDE} ? "\t".$XML_MB_MIR{"MEMBERTYPE"} : "" )
			),${CTRL__EOL_CHARS};
			print STDOUT "</Info>${CTRL__EOL_CHARS}";
			if(${CONF__MIR_REQUEST_INCLUDE_DEBUGGING} and @MIR_REQUEST_DEBUGGING > 0){
				print STDOUT "<Debugging>${CTRL__EOL_CHARS}";
				print STDOUT join(${CTRL__EOL_CHARS},@MIR_REQUEST_DEBUGGING),${CTRL__EOL_CHARS};
				print STDOUT "</Debugging>${CTRL__EOL_CHARS}";
			}
			&xxx_response_notes_print_STDOUT_as_XML("MIR",@MIR_RESPONSE_NOTES) if ${CONF__MIR__RESPONSE_NOTES__INCLUDE};
			print STDOUT "</MemberInfo>${CTRL__EOL_CHARS}";
			print STDOUT "EOT${CTRL__EOL_CHARS}";
		}
		&logfile("Output ${mbnum} MIR: Finished\n");
	}
	if(${composit_mir_data} ne ""){
		return(${failure_text},${composit_mir_data});
	}else{
		return(${failure_text});
	}
}

sub etoc_inquiry{
   local($mbnum)=@_;
   local($line);
   local($failure_text);
   local(@XML_MB_ETOC);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_ETOC_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","ETOC|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		$failure_text=&cuprodigy_xml_getstatement_toc(${mbnum});
	}
	if(${failure_text} ne ""){
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<EStatementTOC>${CTRL__EOL_CHARS}";
		&dms_status("EStatementTOC",${mbnum},(split("\t",${failure_text},2)));
		print STDOUT "</EStatementTOC>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}else{
		# Send the output
		&logfile("Output ${mbnum} ETOC: Details\n");
		print STDOUT "<EStatementTOC>${CTRL__EOL_CHARS}";
		&dms_status__was_not_used_here("EStatementTOC",${mbnum},"000","");
		print STDOUT "<Member>${CTRL__EOL_CHARS}"; print STDOUT ${mbnum},${CTRL__EOL_CHARS}; print STDOUT "</Member>${CTRL__EOL_CHARS}";
		print STDOUT "<TOC>${CTRL__EOL_CHARS}";
		foreach $line (@XML_MB_ETOC){ print STDOUT $line,${CTRL__EOL_CHARS}; }
		print STDOUT "</TOC>${CTRL__EOL_CHARS}";
		print STDOUT "</EStatementTOC>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	&logfile("Output ${mbnum} ETOC: Finished\n");
	return(${failure_text});
}

sub estm_inquiry{
   local($mbnum,$yyyy_mm)=@_;
   local($line);
   local($failure_text,$composit_estm_data);
   local($estm_period,$estm_type,$estm_end_date,$estm_description,$estm_data_type,$estmt_other);
   local($eom__yyyy_mm_dd);
   local($encoded_data);
	if($yyyy_mm =~ /^\d{6}/){ $yyyy_mm=~s/^..../$&-/; }
	if($yyyy_mm =~ /^\d{4}-\d{2}/){ $yyyy_mm=substr(${yyyy_mm},0,7); }
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_ESTM_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","ESTM|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		($failure_text,$encoded_data)=&cuprodigy_xml_getstatement(${mbnum},${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD},${yyyy_mm});
	}
	if(${failure_text} ne ""){
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<EStatement>${CTRL__EOL_CHARS}";
		&dms_status("EStatement",${mbnum},(split("\t",${failure_text},2)));
		print STDOUT "</EStatement>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		&estm_log(1,"error","ESTM",${mbnum},${yyyy_mm},${failure_text});
	}else{
		# Send the output
		$eom__yyyy_mm_dd=${yyyy_mm}."-".&date_last_day_of_month(substr(${yyyy_mm},0,4),substr(${yyyy_mm},-2,2));
		($estm_period,$estm_type,$estm_end_date,$estm_description,$estm_data_type,$estm_other)=(${yyyy_mm},"M",${eom__yyyy_mm_dd},"${yyyy_mm}-Statement","PDF","");
		&logfile("Output ${mbnum} ESTM: Details\n");
		print STDOUT "<EStatement>${CTRL__EOL_CHARS}";
		&dms_status__was_not_used_here("EStatement",${mbnum},"000","");
		print STDOUT "<Member>${CTRL__EOL_CHARS}"; print STDOUT join("\t",${mbnum},${estm_period},${estm_type},${estm_end_date},${estm_description},${estm_data_type},${estm_other}),${CTRL__EOL_CHARS}; print STDOUT "</Member>${CTRL__EOL_CHARS}";
		print STDOUT "<Data>${CTRL__EOL_CHARS}";
		print STDOUT ${encoded_data},${CTRL__EOL_CHARS};
		print STDOUT "</Data>${CTRL__EOL_CHARS}";
		print STDOUT "</EStatement>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		&logfile("estm_inquiry(): The ${CTRL__SERVER_REFERENCE__CUPRODIGY} statement data for ${mbnum}/${yyyy_mm} is base64 encoded size: ".length(${encoded_data})."\n");
		&estm_log(1,"base64","ESTM",${mbnum},${yyyy_mm},length(${encoded_data})." bytes");
	}
	&logfile("Output ${mbnum} ESTM: Finished\n");
	return(${failure_text});
}

sub loanapp_new{
   local($mbnum,$data_composit_xml)=@_;
   local(%data_composit_assoc_array);
   local($failure_text,$loanappid);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_NEWAPP_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","NEWAPP|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		# Each client's HomeCU Loan Apps are customized to that client's Vendor core specifications (asking only data for the values that the client's Vendor core supports and formatting/enumerating the values to match what the Vendor core permits); hence, for clients on the CUProdigy core, their HomeCU Loan App data has a direct 1-to-1 XML tag relation (with a small bit of mutation) to what the CUProdigy API expects; and if the HomeCU Loan app data gets a new XML field added then that new XML field automatically flows into the CUProdigy API request.
		&loanapp_log(1,"request","NEWAPP",${mbnum},${loanappid},${data_composit_xml},"");
		($failure_text,%data_composit_assoc_array)=&loanapp_new_xml_to_assoc_array(${data_composit_xml});
	}
	if(${failure_text} eq ""){
		if(${CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
			$failure_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."In test mode, loanapp not submitted to ".${CTRL__SERVER_REFERENCE__CUPRODIGY}.".");
			if(1){
				local($TEST_MODE_LOANAPP_LOGFILE_NAME);
				local(*TEST_MODE_LOANAPP_LOGFILE);
				local($time);
				local($key,@key);
				if(${CTRL__DMS_ADMINDIR} eq ""){
					$TEST_MODE_LOANAPP_LOGFILE_NAME="${DMS_HOMEDIR}/q_loanapp.test_mode.NEWAPP";
				}else{
					$TEST_MODE_LOANAPP_LOGFILE_NAME="${CTRL__DMS_ADMINDIR}/q_loanapp.test_mode.NEWAPP";
				}
				$time=time();
				open(TEST_MODE_LOANAPP_LOGFILE,">>${TEST_MODE_LOANAPP_LOGFILE_NAME}");
				print TEST_MODE_LOANAPP_LOGFILE "# {\n";
				print TEST_MODE_LOANAPP_LOGFILE "LOGREF:\t",join("  ",${time},&timestamp(${time}),sprintf("%07.0f",${$})),"\n";	# See formatting in logfile()
				print TEST_MODE_LOANAPP_LOGFILE "MBNUM:\t${mbnum}\n";
				print TEST_MODE_LOANAPP_LOGFILE "XML:\t${data_composit_xml}\n";
				foreach $key (sort(keys(%data_composit_assoc_array))){
					@key=split(/$;/,${key});
					print TEST_MODE_LOANAPP_LOGFILE "DATA:\t",join(",",@key),"\t",$data_composit_assoc_array{${key}},"\n";
				}
				print TEST_MODE_LOANAPP_LOGFILE "# }\n";
				close(TEST_MODE_LOANAPP_LOGFILE);
			}
		}
	}
	if(${failure_text} eq ""){
		($failure_text,$loanappid)=&cuprodigy_xml_loanapplication(${mbnum},${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD},${data_composit_xml},%data_composit_assoc_array);
	}
	if(${failure_text} ne "" and (split(/\t/,${failure_text}))[0] !~ /^000$|^026$|^027$|^029$/){	# HomeCU LoanApp non-error specs "000"/"", "026"/"Application Pending", "027"/"Application Approved", "029"/"Application Requires Additional Review"
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<Application>${CTRL__EOL_CHARS}";
		&dms_status("Application",${CTRL__LOANAPP_FAILURE_OF_NEWAPP_USE_LOANAPPID},(split("\t",${failure_text},2)));
		print STDOUT "</Application>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		&loanapp_log(2,"error","NEWAPP",${mbnum},${loanappid},${data_composit_xml},${failure_text});
	}else{
		# Send the output
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum} NEWAPP: Details\n");
		print STDOUT "<Application>${CTRL__EOL_CHARS}";
		&dms_status("Application",${loanappid},(split("\t",${failure_text},2)));
		print STDOUT "</Application>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		&loanapp_log(2,"posted","NEWAPP",${mbnum},${loanappid},${data_composit_xml},${failure_text});
	}
	&logfile("Output ${mbnum} NEWAPP: Finished\n");
	return(${failure_text});
}

sub loanapp_new_xml_to_assoc_array{
   local($data_composit_xml)=@_;
   local(%data_composit_assoc_array);
   local($key,@key);
   local($count)=0;
   local($errormsg)="";
   local(%XML_NAMESPACE_BY_TAG_INDEX,%XML_ATTRIBUTES_BY_TAG_INDEX,%XML_DATA_BY_TAG_INDEX,%XML_SEQ_BY_TAG_INDEX,%XML_TAGS_FOUND);	# As used by xml_parse()
   local(%xml_original_order,$xml_original_key,$xml_original_tag,$xml_original_seq,$xml_original_sort_sequence);
	$data_composit_xml=~s/^ *//; $data_composit_xml=~s/ *$//; 	# Sanitize some common formatting issues with the XML originating from HomeCU
	$data_composit_xml=~s/< */</g; $data_composit_xml=~s/ *>/>/g; 	# Sanitize some common formatting issues with the XML originating from HomeCU
	if($data_composit_xml !~ /^<root>.*<\/root>$/){
		if($data_composit_xml !~ /^<root>/){
			$errormsg=join("\t","999","XML data not wrapped between tags <root> and </root>; missing leading <root> tag.");
		}else{
			$errormsg=join("\t","999","XML data not wrapped between tags <root> and </root>; missing trailing </root> tag.");
		}
	}else{
		&xml_parse(${data_composit_xml});	# No return status to check because xml_parse() will just die() (via logfile_and_die()) if the XML syntax is bad.
		if(1){
			foreach $xml_original_key (split(/</,${data_composit_xml})){
				next if $xml_original_key =~ /^\s*$/;
				next if $xml_original_key =~ /^\//;
				($xml_original_tag=${xml_original_key})=~s/>.*$//;
				next if $xml_original_tag eq "root";
				$xml_original_order{${xml_original_tag}}.=sprintf("%07.0f",${xml_original_sequence})."\t";
				$xml_original_sequence++;
			}
		}
		foreach $key (sort(keys(%XML_DATA_BY_TAG_INDEX))){
			@key=split(/$;/,${key});
			next if @key != 4;
			next if $key[0] ne "root";
			if(1){
				$xml_original_sort_sequence=(split(/\t/,$xml_original_order{$key[2]}))[0];
				$xml_original_order{$key[2]}=~s/^[^\t]*\t//;
				if(${xml_original_sort_sequence} eq ""){
					$xml_original_sort_sequence=sprintf("%07.0f",${xml_original_sequence});
				}
			}
			if($key[3] eq ${XML_SINGLE}){
				$data_composit_assoc_array{${xml_original_sort_sequence}.":".sprintf("%07.0f",${count}),$key[2]}=$XML_DATA_BY_TAG_INDEX{${key}};
			}else{
				$data_composit_assoc_array{${xml_original_sort_sequence}.":".sprintf("%07.0f",${count}),$key[2],sprintf("%.0f",$key[3])}=$XML_DATA_BY_TAG_INDEX{${key}};
			}
			$count++;
		}
		if($count == 0){
			$errormsg=join("\t","999","XML data between tags <root> and </root> does not contain any of the expected values.");
		}
	}
	if    (${errormsg} ne ""){
		return(${errormsg});
	}else{
		return("",%data_composit_assoc_array);
	}
}

sub loanapp_status{
   local($mbnum,$loanappid)=@_;
   local($failure_text);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_INQAPP_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","INQAPP|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		&loanapp_log(1,"request","INQAPP",${mbnum},${loanappid},"","");
	}
	if(${failure_text} eq ""){
		($failure_text,$loanappid)=&cuprodigy_xml_loanapplicationstatus(${mbnum},${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD},${loanappid});
	}
	if(${failure_text} ne "" and (split(/\t/,${failure_text}))[0] !~ /^000$|^026$|^027$|^029$/){	# HomeCU LoanApp non-error specs "000"/"", "026"/"Application Pending", "027"/"Application Approved", "029"/"Application Requires Additional Review"
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<Application>${CTRL__EOL_CHARS}";
		&dms_status("Application",${loanappid},(split("\t",${failure_text},2)));
		print STDOUT "</Application>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		&loanapp_log(2,"error","INQAPP",${mbnum},${loanappid},"",${failure_text});
	}else{
		# Send the output
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum} INQAPP: Details\n");
		print STDOUT "<Application>${CTRL__EOL_CHARS}";
		&dms_status("Application",${loanappid},(split("\t",${failure_text},2)));
		print STDOUT "</Application>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
		&loanapp_log(2,"posted","INQAPP",${mbnum},${loanappid},"",${failure_text});
	}
	&logfile("Output ${mbnum} INQAPP: Finished\n");
	return(${failure_text});
}

sub loanapp_types{
   local($mbnum)=@_;
   local($line);
   local($failure_text);
   local(@XML_LOANTYPES);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_INQAPP_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","INQAPP|${mbnum}")) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${failure_text} eq ""){
		$failure_text=&cuprodigy_xml_getvendorloantypes(${mbnum},${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD});
	}
	if(${failure_text} ne ""){
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum}: Error\n");
		print STDOUT "<LoanTypes>${CTRL__EOL_CHARS}";
		&dms_status("LoanTypes",${mbnum},(split("\t",${failure_text},2)));
		print STDOUT "</LoanTypes>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}else{
		# Send the output
		$failure_text=~s/^.*\n//;	# Use just the last failure message.
		&logfile("Output ${mbnum} LOANTYPES: Details\n");
		print STDOUT "<LoanTypes>${CTRL__EOL_CHARS}";
		&dms_status__was_not_used_here("LoanTypes",${mbnum},"000","");
		print STDOUT "<Data>${CTRL__EOL_CHARS}";
		foreach $line (@XML_LOANTYPES){ print STDOUT $line,${CTRL__EOL_CHARS}; }
		print STDOUT "</Data>${CTRL__EOL_CHARS}";
		print STDOUT "</LoanTypes>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	&logfile("Output ${mbnum} LOANTYPES: Finished\n");
	return(${failure_text});
}

sub transaction{
   local($mbnum_from,$tran_code,$acct_from,$acct_to,$tran_id,$rfu1,$mbnum_to,$amt,$optional_auth_mbnum,$optional_memo)=@_;
   local($tran_code_unrestricted_transfer)=0;
   local($dplncc_from,$dplncc_to);
   local($error_num,$error_text);
   local($tran_code_okay);
   local($mbnum,$mbpwd);
   local($mbnum_auth);
   local($subroutine_reference)="transaction(${mbnum_from},${tran_code},${acct_from},${acct_to},${tran_id},${rfu1},${mbnum_to},${amt},${optional_auth_mbnum},${optional_memo})";
   local($mbnum_for_inquiry);
   local($acct_from__is_not_xjo,$acct_to__is_not_xjo)=(0,0);
   local($member_to_member__orig_ach_account_type_code,$member_to_member__orig_lookup_identifier);
   local($core_degradation_check__description_optionals);
   local(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST);
   local(%XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS);
   local($idx);
	return(&transaction_ES(@_)) if $tran_code =~ /^ES$/i;
	return(&transaction_PC(@_)) if $tran_code =~ /^PC$/i;
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_TRN_REQUEST}){
			if(@_ > 8){
				$core_degradation_check__description_optionals="|".join("|",@_[8..$#_]);
			}
			if(($core_degradation_check__remaining=&core_degradation_check("remaining","TRN|${mbnum_from}|${tran_code}|${acct_from}|${acct_to}|${tran_id}|${rfu1}|${mbnum_to}|${amt}".${core_degradation_check__description_optionals})) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${error_text} eq ""){
		$tran_code=~tr/a-z/A-Z/;	# Ensure the transaction code is upper case
		$mbnum_from=sprintf("%.0f",${mbnum_from});
		$mbnum_to=sprintf("%.0f",${mbnum_to});
		$mbnum_auth=sprintf("%.0f",( ${optional_auth_mbnum} ne "" ? ${optional_auth_mbnum} : ${mbnum_from} ));
		if(${tran_code} eq "MM" or ${tran_code} eq "XMM"){
			$member_to_member__orig_ach_account_type_code=${acct_to};
			if    ($acct_to eq "10"){	# Matches standard ACH account type code for Draft/Checking account
				$acct_to="<${acct_to}:Lookup:1st:Draft:${rfu1}>";
				$member_to_member__orig_lookup_identifier=${acct_to};
			}elsif($acct_to eq "20"){	# Matches standard ACH account type code for Share/Savings account
				$acct_to="<${acct_to}:Lookup:1st:Share:${rfu1}>";
				$member_to_member__orig_lookup_identifier=${acct_to};
			}else{
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware implementation of Member-to-Member Transfers does not know what the destination (as a standard ACH account type code) DP/LN code '${acct_to}' refers to.";
				$acct_to="<${acct_to}:Lookup:1st:?????:${rfu1}>";
				$member_to_member__orig_lookup_identifier=${acct_to};
			}
		}
		if(${error_text} eq ""){
			if($tran_code =~ /^X[A-Z][A-Z]$/i){ $acct_to__is_not_xjo=1; }	# Unrestricted Transfers ("X" prefixed) where (after the "X" prefix) the $tran_code is (likely 1 of the values) "AT", "LP", "LA", "LC", "CW", "ED", "CP", "MP", or "VP".	# Like values "XAT", "XLP", "XLA", "XLC", "XCW", "XED", "XCP", "XMP", and "XVP".
			if($tran_code =~ /^MM$/i){ $acct_to__is_not_xjo=1; }		# Member-to-Member Transfers where $tran_code is "MM"
			if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
				$mbnum=${mbnum_auth}; $mbpwd=&cuprodigy_request_memberpwd(${mbnum});
				($error_text,@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST)=&xjo_overloaded_account_list(${mbnum},${mbpwd},1);
				if(${error_text} ne ""){
					&logfile("${subroutine_reference}: xjo_overloaded_account_list(${mbnum},${mbpwd},0): Failed.\n");
					$error_text=~s/^.*\n//;	# Use just the last failure message.
					($error_num,$error_text)=split(/\t/,${error_text},2);
				}else{
					for($idx=0;$idx<=$#XML_MB_XJO_OVERLOADED_ACCOUNT_LIST;$idx++){
						$XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{join($;,(split(/\t/,$XML_MB_XJO_OVERLOADED_ACCOUNT_LIST[${idx}]))[5,8])}=1;	# Value list like: $xjo_cuprodigy_memberNumber, $xjo_cuprodigy_accountCategory, $xjo_cuprodigy_accountType, $xjo_cuprodigy_accountNumber, $xjo_cuprodigy_transactionsRestricted, $xjo_dp_ln_cc, $xjo_cuprodigy_accountNumber__mb, $xjo_cuprodigy_accountNumber__dplncc, $xjo_dms_xjo_overloaded_composit
					}
					if(!${acct_from__is_not_xjo}){
						$acct_from__is_not_xjo=1;
						if    (${tran_code} eq "AT" or
						       ${tran_code} eq "LP" or
						       ${tran_code} eq "CW" or
						       ${tran_code} eq "CP" or
						       ${tran_code} eq "MP" or
						       ${tran_code} eq "VP"
						){
							if($XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{"DP",(&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from}))[1]}){
								$acct_from__is_not_xjo=0;
							}
						}elsif(${tran_code} eq "LA"){
							if($XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{"LN",(&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from}))[1]}){
								$acct_from__is_not_xjo=0;
							}
							if($XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{"CC",(&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from}))[1]}){
								$acct_from__is_not_xjo=0;
							}
						}else{
							$acct_from__is_not_xjo=0;
						}
					}
					if(!${acct_to__is_not_xjo}){
						$acct_to__is_not_xjo=1;
						if    (${tran_code} eq "AT" or
						       ${tran_code} eq "LA"
						){
							if($XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{"DP",(&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to}))[1]}){
								$acct_to__is_not_xjo=0;
							}
						}elsif(${tran_code} eq "LP" or
						       ${tran_code} eq "CP" or
						       ${tran_code} eq "MP" or
						       ${tran_code} eq "VP"
						){
							if($XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{"LN",(&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to}))[1]}){
								$acct_to__is_not_xjo=0;
							}
							if($XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{"CC",(&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to}))[1]}){
								$acct_to__is_not_xjo=0;
							}
						}else{
							$acct_to__is_not_xjo=0;
						}
					}
				}
			}else{
   				$acct_from__is_not_xjo=1;
				$acct_to__is_not_xjo=1;
			}
		}
		if(${error_text} eq ""){
			&transaction_log(1,"request",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},"");
		}
		if(${error_text} ne ""){
			&transaction_log(2,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
		}
	}
	if(${error_text} eq ""){
		if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
			$mbnum=${mbnum_auth}; $mbpwd=&cuprodigy_request_memberpwd(${mbnum});
		}else{
			$mbnum=${mbnum_from}; $mbpwd=&cuprodigy_request_memberpwd(${mbnum});
		}
	}
	if(${error_text} eq ""){
		($mbnum_auth,$mbnum_from,$acct_from,$mbnum_to,$acct_to,$amt,$error_num,$error_text)=&transaction_adjust($mbnum_auth,$mbnum_from,$acct_from,$mbnum_to,$acct_to,$amt,$tran_code,$acct_from__is_not_xjo,$acct_to__is_not_xjo);
		if(${error_text} ne ""){
			&transaction_log(2,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
		}else{
			&transaction_log(2,"adjust",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},"");
		}
	}
	if(${error_text} eq ""){
		$tran_code_okay=0;
		if($tran_code =~ /^X[A-Z][A-Z]$/){	# Like values "XAT", "XLP", "XLA", "XLC", "XCW", "XED", "XCP", "XMP", and "XVP".
			if(${CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION}){
				$tran_code_unrestricted_transfer=1;
				$tran_code=~s/^X//;
			}else{
				&logfile("The \$CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION is disabled; to enable Unrestricted Transfers the \$CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION must be enabled.\n");
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware is not configured to allow Unrestricted Transfers using transaction code '${tran_code}'.";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}
		}
		if    ($tran_code eq "AT"){
			$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
		}elsif($tran_code eq "LP"){
			$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","LN");
		}elsif($tran_code eq "LA"){
			$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("LN","DP");
		}elsif($tran_code eq "LC"){
			$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("LN","");
		}elsif($tran_code eq "CW"){
			$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","");
		}elsif($tran_code eq "ED"){
			$tran_code_okay=0; ($dplncc_from,$dplncc_to)=("","DP");
		}elsif($tran_code eq "GT"){
			if(${tran_code_unrestricted_transfer}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware does not allow Unrestricted Transfers on G/L Transfers (transaction code 'X${tran_code}').";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}else{
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","GL");
			}
		}elsif($tran_code eq "GF"){
			if(${tran_code_unrestricted_transfer}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware does not allow Unrestricted Transfers on G/L Transfers (transaction code 'X${tran_code}').";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}else{
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("GL","DP");
			}
		}elsif($tran_code eq "GA"){
			if(${tran_code_unrestricted_transfer}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware does not allow Unrestricted Transfers on G/L Transfers (transaction code 'X${tran_code}').";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}else{
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("LN","GL");
			}
		}elsif($tran_code eq "GP"){
			if(${tran_code_unrestricted_transfer}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware does not allow Unrestricted Transfers on G/L Transfers (transaction code 'X${tran_code}').";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}else{
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("GL","LN");
			}
		}elsif($tran_code eq "CP"){
			if(${acct_to} ne ""){
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","CC");
			}
		}elsif($tran_code eq "MP"){
			if(${acct_to} ne ""){
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","CC");
			}
		}elsif($tran_code eq "VP"){
			if(${acct_to} ne ""){
				$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","CC");
			}
		}elsif($tran_code eq "MD"){	0;
		}elsif($tran_code eq "MA"){
			if(${CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__TRN_MA_QUESTIONS}){
				&logfile("The \$CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__TRN_MA_QUESTIONS is enabled, but the \"CUSTOM/custom_preproc.pi\" does not appear to have handled the TRN \"MA\" request.\n");
			}else{
				&logfile("The \$CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__TRN_MA_QUESTIONS is disabled, so the TRN \"MA\" request is not permitted.\n");
			}
		}elsif($tran_code eq "ES"){	0;
		}elsif($tran_code eq "PC"){	0;
		}elsif($tran_code eq "MM"){
			if(${tran_code_unrestricted_transfer}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware does not allow Unrestricted Transfers on a Member-to-Member Transfers (transaction code 'X${tran_code}').";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}elsif(!${CTRL__ALLOW_MEMBER_TO_MEMBER_TRANSFERS_WITHOUT_XAC_RELATION}){
				&logfile("The \$CTRL__ALLOW_MEMBER_TO_MEMBER_TRANSFERS_WITHOUT_XAC_RELATION is disabled; to enable Member-to-Member Transfers the \$CTRL__ALLOW_MEMBER_TO_MEMBER_TRANSFERS_WITHOUT_XAC_RELATION must be enabled.\n");
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware is not configured to allow Member-to-Member Transfers using transaction code '${tran_code}'.";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}else{
				if    ($member_to_member__orig_lookup_identifier =~ /^<.*:Lookup:1st:Draft:.*>$/){
					$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
				}elsif($member_to_member__orig_lookup_identifier =~ /^<.*:Lookup:2nd:Draft:.*>$/){
					$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
				}elsif($member_to_member__orig_lookup_identifier =~ /^<.*:Lookup:3rd:Draft:.*>$/){
					$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
				}elsif($member_to_member__orig_lookup_identifier =~ /^<.*:Lookup:1st:Share:.*>$/){
					$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
				}elsif($member_to_member__orig_lookup_identifier =~ /^<.*:Lookup:2nd:Share:.*>$/){
					$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
				}elsif($member_to_member__orig_lookup_identifier =~ /^<.*:Lookup:3rd:Share:.*>$/){
					$tran_code_okay=1; ($dplncc_from,$dplncc_to)=("DP","DP");
				}else{
					$error_num="999";
					$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware implementation of Member-to-Member Transfers does not know what the destination (as a standard ACH account type code) DP/LN code '${member_to_member__orig_ach_account_type_code}' refers to.";
					&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
				}
			}
		}else{				0;
		}
		if(${tran_code_unrestricted_transfer}){ $tran_code=~s/^/X/; }
		if(${error_text} eq ""){
			if(!${tran_code_okay}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Unsupported transaction code '${tran_code}'.";
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}
		}
	}
	if(${error_text} eq ""){
		if(${CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
			$error_num="999";
			$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."In test mode, transaction not submitted to ".${CTRL__SERVER_REFERENCE__CUPRODIGY}.".";
			&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
		}else{
			if    ($dplncc_from !~ /^\s*$/ and $dplncc_to !~ /^\s*$/){
				if    (${dplncc_from} eq "DP" and ${dplncc_to} eq "DP"){
					$error_text=&cuprodigy_xml_accounttransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
				}elsif(${dplncc_from} eq "DP" and ${dplncc_to} eq "LN"){
					if    ($configure_account_by_cuprodigy_type__creditcard_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "offbook-nonsweep"){
						$error_text=&cuprodigy_xml_accounttransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, and when is a "non-sweep" offbook then must change the posting of the $tran_code "LP" (or "CP"/"VP"/"MP") to "AT" instead.
					}elsif($configure_account_by_cuprodigy_type__creditcard_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "offbook-sweep"){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not allow payments to be posted directly to '${acct_to}', instead the payments must be posted to the related sweep deposit account.");	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, and when is a "sweep" offbook then the payments must be posted to the related DP sweep account.
					}elsif($configure_account_by_cuprodigy_type__loan_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "3rdparty-nonsweep"){
						$error_text=&cuprodigy_xml_accounttransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});	# CUProdigy treats (non-sweep and sweep) 3rdparty LNs as a DP, and when is a "non-sweep" 3rdparty then must change the posting of the $tran_code "LP" (or "CP"/"VP"/"MP") to "AT" instead.
					}elsif($configure_account_by_cuprodigy_type__loan_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "3rdparty-sweep"){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not allow payments to be posted directly to '${acct_to}', instead the payments must be posted to the related sweep deposit account.");	# CUProdigy treats (non-sweep and sweep) 3rdparty LNs as a DP, and when is a "sweep" offbook then the payments must be posted to the related DP sweep account.
					}else{
						$error_text=&cuprodigy_xml_loanpayment(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
					}
				}elsif(${dplncc_from} eq "LN" and ${dplncc_to} eq "DP"){
					if    ($configure_account_by_cuprodigy_type__creditcard_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "offbook-nonsweep"){
						$error_text=&cuprodigy_xml_accounttransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, and when is a "non-sweep" offbook then change the posting of the $tran_code of "LA" to "AT" instead.
					}elsif($configure_account_by_cuprodigy_type__creditcard_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "offbook-sweep"){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not allow advances to be posted directly from '${acct_to}', instead the advances must be posted from the related sweep deposit account.");	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, and when is a "sweep" offbook then the advances must be posted from the related DP sweep account.
					}elsif($configure_account_by_cuprodigy_type__loan_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "3rdparty-nonsweep"){
						$error_text=&cuprodigy_xml_accounttransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});	# CUProdigy treats (non-sweep and sweep) 3rdparty LNs as a DP, and when is a "non-sweep" 3rdparty then change the posting of the $tran_code of "LA" to "AT" instead.
					}elsif($configure_account_by_cuprodigy_type__loan_behavior{&convert_dms_dplncc_to_cuprodigy_accountType(${acct_to})} eq "3rdparty-sweep"){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not allow advances to be posted directly from '${acct_to}', instead the advances must be posted from the related sweep deposit account.");	# CUProdigy treats (non-sweep and sweep) 3rdparty LNs as a DP, and when is a "sweep" offbook then the advances must be posted from the related DP sweep account.
					}else{
						$error_text=&cuprodigy_xml_loanaddon(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
					}
				}elsif(${dplncc_from} eq "GL" and ${dplncc_to} eq "DP"){
					if(${mbnum_from} ne ${mbnum_to}){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}." THE \"${tran_code}\" REQUIRES THE FROM AND TO MEMBER NUMBER MATCH","The request's \"from\" and \"to\" member numbers do not match (\"${mbnum_from}\" <> \"${mbnum_to}\").","error");
					}else{
						$error_text=&cuprodigy_xml_gltomembertransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
					}
				}elsif(${dplncc_from} eq "DP" and ${dplncc_to} eq "GL"){
					if(${mbnum_from} ne ${mbnum_to}){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}." THE \"${tran_code}\" REQUIRES THE FROM AND TO MEMBER NUMBER MATCH","The request's \"from\" and \"to\" member numbers do not match (\"${mbnum_from}\" <> \"${mbnum_to}\").","error");
					}else{
						$error_text=&cuprodigy_xml_membertogltransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
					}
				}elsif(${dplncc_from} eq "GL" and ${dplncc_to} eq "LN"){
					if(${mbnum_from} ne ${mbnum_to}){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}." THE \"${tran_code}\" REQUIRES THE FROM AND TO MEMBER NUMBER MATCH","The request's \"from\" and \"to\" member numbers do not match (\"${mbnum_from}\" <> \"${mbnum_to}\").","error");
					}else{
						$error_text=&cuprodigy_xml_gltomembertransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
					}
				}elsif(${dplncc_from} eq "LN" and ${dplncc_to} eq "GL"){
					if(${mbnum_from} ne ${mbnum_to}){
						$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}." THE \"${tran_code}\" REQUIRES THE FROM AND TO MEMBER NUMBER MATCH","The request's \"from\" and \"to\" member numbers do not match (\"${mbnum_from}\" <> \"${mbnum_to}\").","error");
					}else{
						$error_text=&cuprodigy_xml_membertogltransfer(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
					}
				}else{
					$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Do not have a ${CTRL__SERVER_REFERENCE__CUPRODIGY} method to post the requested transaction.");
				}
			}elsif($dplncc_from !~ /^\s*$/ and $dplncc_to =~ /^\s*$/){
				if    (${dplncc_from} eq "DP"){
					$error_text=&cuprodigy_xml_checkwithdrawal(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
				}elsif(${dplncc_from} eq "LN"){
					$error_text=&cuprodigy_xml_checkwithdrawalloan(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
				}elsif(${dplncc_from} eq "CC"){
					$error_text=&cuprodigy_xml_creditcardpayment(${mbnum},${mbpwd},${dplncc_from},${mbnum_from},${acct_from},${dplncc_to},${mbnum_to},${acct_to},${amt},${optional_memo});
				}else{
					$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Do not have a ${CTRL__SERVER_REFERENCE__CUPRODIGY} method to post the requested transaction.");
				}
			}elsif($dplncc_from =~ /^\s*$/ and $dplncc_to !~ /^\s*$/){
				$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Not yet coded to handle Electronic Deposit.");
			}else{
				$error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Not yet coded to handle a No-Affect transaction.");
			}
			if(${error_text} ne ""){
				($error_num,$error_text)=split(/\t/,${error_text},2);
				&transaction_log(3,"error",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},${error_text});
			}
		}
	}
	if(${error_text} eq ""){
		&transaction_log(3,"posted",${tran_code},join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_from},${acct_from},${acct_from__is_not_xjo})),join("/",&join_dms_xjo_overloaded_composit(${mbnum_auth},${mbnum_to},${acct_to},${acct_to__is_not_xjo})),${amt},${optional_memo},${tran_id},"");
		print STDOUT "<Transaction>${CTRL__EOL_CHARS}";
		&dms_status("Transaction",${mbnum_from},"000");
		print STDOUT "</Transaction>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	if(${error_text} ne ""){
		print STDOUT "<Transaction>${CTRL__EOL_CHARS}";
		&dms_status("Transaction",${mbnum_from},${error_num},${error_text});
		print STDOUT "</Transaction>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	return(${error_text});
}

sub transaction_ES{
   local(@dms_trn_arguments)=@_;
   local($error_num,$error_text);
   local($tran_code_okay);
   local($mbnum)=$dms_trn_arguments[0];
   local($tran_code)=$dms_trn_arguments[1];
   local($enable_estatement_electronic)=$dms_trn_arguments[6];
   local($estatementactive_before,$estatementactive_after);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_TRN_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining",join("|","TRN",@dms_trn_arguments))) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${error_text} eq ""){
		$tran_code=~tr/a-z/A-Z/;	# Ensure the transaction code is upper case
		&transaction_log_XX("ES",1,"request",@dms_trn_arguments,"");
	}
	if(${error_text} eq ""){
		$mbnum=${mbnum_from}; $mbpwd=&cuprodigy_request_memberpwd(${mbnum});
	}
	if(${error_text} eq ""){
		if    ($enable_estatement_electronic =~ /^Y$/i){
			$enable_estatement_electronic=1;
		}elsif($enable_estatement_electronic =~ /^N$/i){
			$enable_estatement_electronic=0;
		}else{
			$error_num="999";
			$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Transaction code '${tran_code}' requested with an invalid flag value: ${enable_estatement_electronic}";
			&transaction_log_XX("ES",2,"error",@dms_trn_arguments,${error_text});
			$enable_estatement_electronic="";
		}
	}
	if(${error_text} eq ""){
		&transaction_log_XX("ES",2,"permit",@dms_trn_arguments,"");
	}
	if(${error_text} eq ""){
		if(${CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
			$error_num="999";
			$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."In test mode, transaction not submitted to ".${CTRL__SERVER_REFERENCE__CUPRODIGY}.".";
			&transaction_log_XX("ES",3,"error",@dms_trn_arguments,${error_text});
		}else{
			$error_text=&cuprodigy_xml_estatementinquiry(${mbnum},${mbpwd});
			$estatementactive_before=join(",",@XML_MB_ESTATEMENTACTIVE);
			if(${error_text} eq ""){
				$error_text=&cuprodigy_xml_estatementchange(${mbnum},${mbpwd},${enable_estatement_electronic});
				if(${error_text} eq ""){
					$error_text=&cuprodigy_xml_estatementinquiry(${mbnum},${mbpwd});
					$estatementactive_after=join(",",@XML_MB_ESTATEMENTACTIVE);
				}
			}
			if(${error_text} ne ""){
				($error_num,$error_text)=split(/\t/,${error_text},2);
				if(${CONF__DMS_HOMECU_ODYSSEY_QUIRK__TRN_ES__NO_ERROR_ON_FAILURE_FOR_NO_METHOD_TO_DISABLE}){
					if(join("\t",${error_num},${error_text}) eq join("\t","999","The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not have any ${CTRL__SERVER_REFERENCE__DMS} request method available to disable E-Statements")){
						&logfile("transaction_ES(): Faking status for ${mbnum} as \"000\"/\"".$CTRL__STATUS_TEXT{"000"}."\" because \$CONF__DMS_HOMECU_ODYSSEY_QUIRK__TRN_ES__NO_ERROR_ON_FAILURE_FOR_NO_METHOD_TO_DISABLE is enabled.\n");
						$error_text=join("\t",$CTRL__STATUS_TEXT{"000"},join("/",${error_num},${error_text}));
						$error_num="000";
					}
				}
				&transaction_log_XX("ES",3,"error",@dms_trn_arguments,${error_text},"NOTE: EStatementInquiry found '${estatementactive_before}'");
			}
		}
	}
	if(${error_text} eq ""){
		&transaction_log_XX("ES",3,"posted",@dms_trn_arguments,"","NOTE: EStatementChange updated from '${estatementactive_before}' to '${estatementactive_after}'");
		print STDOUT "<Transaction>${CTRL__EOL_CHARS}";
		&dms_status("Transaction",${mbnum_from},"000");
		print STDOUT "</Transaction>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	if(${error_text} ne ""){
		print STDOUT "<Transaction>${CTRL__EOL_CHARS}";
		&dms_status("Transaction",${mbnum_from},${error_num},${error_text});
		print STDOUT "</Transaction>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	return(${error_text});
}

sub transaction_PC{
   local(@dms_trn_arguments)=@_;
   local($error_num,$error_text,$error_text_extra);
   local($tran_code_okay);
   local($mbnum)=$dms_trn_arguments[0];
   local($tran_code)=$dms_trn_arguments[1];
   local($plastic_card_signature)=$dms_trn_arguments[2];
   local($plastic_card_pan,$plastic_card_code,$plastic_card_state);
   local($enable_plastic_card)=$dms_trn_arguments[6];
   local($plastic_card_active_before,$plastic_card_active_after);
   local($mbpwd);
	if(${failure_text} eq ""){
		if(${CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_TRN_REQUEST}){
			if(($core_degradation_check__remaining=&core_degradation_check("remaining",join("|","TRN",@dms_trn_arguments))) > 0){
				$failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}.${CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099});
			}
		}
	}
	if(${failure_text} eq ""){
		if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}){ $failure_text=join("\t",${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO},${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT}); }	# Do not try to record a simultanious request state in &cuprodigy_io_recording().
		if(${GLOB__STACKED_ERROR_099}){ $failure_text=join("\t","099",$CTRL__STATUS_TEXT{"099"}); &cuprodigy_io_recording("NOTE",${mbnum},"Stacked Error 099"); }
	}
	if(${error_text} eq ""){
		$tran_code=~tr/a-z/A-Z/;	# Ensure the transaction code is upper case
		&transaction_log_XX("PC",1,"request",@dms_trn_arguments,"");
	}
	if(${error_text} eq ""){
		$mbnum=${mbnum_from}; $mbpwd=&cuprodigy_request_memberpwd(${mbnum});
	}
	if(${error_text} eq ""){
		if    ($enable_plastic_card =~ /^Y$/i){
			$enable_plastic_card=1;
		}elsif($enable_plastic_card =~ /^N$/i){
			$enable_plastic_card=0;
		}else{
			$error_num="999";
			$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Transaction code '${tran_code}' requested with an invalid flag value: ${enable_plastic_card}";
			&transaction_log_XX("PC",2,"error",@dms_trn_arguments,${error_text});
			$enable_plastic_card="";
		}
	}
	if(${error_text} eq ""){
		&transaction_log_XX("PC",2,"permit",@dms_trn_arguments,"");
	}
	if(${error_text} eq ""){
		$mbpwd=&cuprodigy_request_memberpwd(${mbnum});
		($error_text,$plastic_card_pan,$plastic_card_code,$plastic_card_state)=&cuprodigy_xml_lookup_plastic_card_from_signature(${mbnum},${mbpwd},${plastic_card_signature});
		if(${error_text} ne ""){
			if($error_text =~ /^\d{3}\t/){
				$error_text=$';
				$error_num=$&;
				$error_num=~s/\t$//;
			}else{
				$error_num="999";
			}
		}
		if(${error_text} eq ""){
			 if(${plastic_card_pan} eq ""){
				$error_num="999";
				$error_text="cuprodigy_xml_lookup_plastic_card_from_signature() failed to identify an exising card from card signature.";
				($error_text,$error_text_extra)=("FAILED UPDATE PLASTIC CARD STATUS",${error_text});
				&transaction_log_XX("PC",3,"error",@dms_trn_arguments,${error_text},${error_text_extra});
				$error_text=join("\t",${error_text},${error_text_extra});
			}else{
				$dms_trn_arguments[2]=${plastic_card_pan};
			}
		}
	}
	if(${error_text} eq ""){
		&transaction_log_XX("PC",3,"adjust",@dms_trn_arguments,"");
	}
	if(${error_text} eq ""){
		if(${CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
			$error_num="999";
			$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."In test mode, transaction not submitted to ".${CTRL__SERVER_REFERENCE__CUPRODIGY}.".";
			&transaction_log_XX("PC",4,"error",@dms_trn_arguments,${error_text});
		}else{
			if    (${plastic_card_state} eq "unblocked"){
				if(${enable_plastic_card}){
					$error_num="000";
					$error_text="NO ERROR";
					$error_text_extra="Plastic Card has \"code\" which is already unblocked (enabled).";
					&transaction_log_XX("PC",4,"as-is",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: AccountInquiry found code '${plastic_card_code}'");
					$error_text=join("\t",${error_text},${error_text_extra});
				}
			}elsif(${plastic_card_state} eq "blocked"){
				if(!${enable_plastic_card}){
					$error_num="000";
					$error_text="NO ERROR";
					$error_text_extra="Plastic Card has \"code\" which is already blocked (disabled).";
					&transaction_log_XX("PC",4,"as-is",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: AccountInquiry found code '${plastic_card_code}'");
					$error_text=join("\t",${error_text},${error_text_extra});
				}
			}elsif(${plastic_card_state} eq "cancelled"){
				$error_num="999";
				$error_text="PLASTIC CARD CAN NOT BE CHANGED";
				$error_text_extra="Plastic Card has \"code\" which can not be changed (unblocked (enabled) nor blocked (disabled)).";
				&transaction_log_XX("PC",4,"error",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: AccountInquiry found code '${plastic_card_code}'");
				$error_text=join("\t",${error_text},${error_text_extra});
			}else{
				$error_num="999";
				$error_text="PLASTIC CARD CAN NOT BE CHANGED";
				$error_text="Plastic Card has \"code\" which is unknown and hence can not be changed (unblocked (enabled) nor blocked (disabled)).";
				&transaction_log_XX("PC",4,"error",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: AccountInquiry found code '${plastic_card_code}'");
				$error_text=join("\t",${error_text},${error_text_extra});
			}
			if(${error_text} eq ""){
				$plastic_card_active_before=${plastic_card_state};
				$error_text=&cuprodigy_xml_changecardstatus(${mbnum},${mbpwd},${plastic_card_pan},${enable_plastic_card});
				if(${error_text} ne ""){
					($error_num,$error_text)=split(/\t/,${error_text},2);
					($error_text,$error_text_extra)=("FAILED UPDATE PLASTIC CARD STATUS",${error_text});
					&transaction_log_XX("PC",4,"error",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: CardInquiry found '${plastic_card_active_before}'");
					$error_text=join("\t",${error_text},${error_text_extra});
				}
				if(${error_text} eq ""){
					($error_text,$plastic_card_pan,$plastic_card_code,$plastic_card_state)=&cuprodigy_xml_lookup_plastic_card_from_signature(${mbnum},${mbpwd},${plastic_card_pan});
					$plastic_card_active_after=${plastic_card_state};
					if(${error_text} ne ""){
						if($error_text =~ /^\d{3}\t/){
							$error_text=$';
							$error_num=$&;
							$error_num=~s/\t$//;
						}else{
							$error_num="999";
						}
						($error_text,$error_text_extra)=("FAILED UPDATE PLASTIC CARD STATUS",${error_text});
						&transaction_log_XX("PC",4,"error",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: CardInquiry found '${plastic_card_active_before}'");
						$error_text=join("\t",${error_text},${error_text_extra});
					}else{
						if(${plastic_card_active_before} eq ${plastic_card_active_after}){
							$error_num="999";
							$error_text="cuprodigy_xml_changecardstatus(): ChangeCardStatus did not change the card's status";
							($error_text,$error_text_extra)=("FAILED UPDATE PLASTIC CARD STATUS",${error_text});
							&transaction_log_XX("PC",4,"error",@dms_trn_arguments,${error_text},${error_text_extra},"NOTE: CardInquiry found '${plastic_card_active_before}'");
							$error_text=join("\t",${error_text},${error_text_extra});
						}
					}
				}
			}
		}
	}
	if(${error_text} eq ""){
		&transaction_log_XX("PC",4,"posted",@dms_trn_arguments,"NO ERROR","Core successfully updated","NOTE: ChangeCardStatus updated from '${plastic_card_active_before}' to '${plastic_card_active_after}'");
		print STDOUT "<Transaction>${CTRL__EOL_CHARS}";
		&dms_status("Transaction",${mbnum_from},"000");
		print STDOUT "</Transaction>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	if(${error_text} ne ""){
		print STDOUT "<Transaction>${CTRL__EOL_CHARS}";
		&dms_status("Transaction",${mbnum_from},${error_num},${error_text});
		print STDOUT "</Transaction>${CTRL__EOL_CHARS}";
		print STDOUT "EOT${CTRL__EOL_CHARS}";
	}
	return(${error_text});
}

sub transaction_split_gl_ach_desc{
   local($xfer_mode,$from_mbnum,$from_subacct,$to_mbnum,$to_subacct)=@_;
   local($gl_subacct,$xfer_text);
   local($gl_ach_desc);
	if    (substr(${xfer_mode},0,1) eq "G"){	# The "From" is a G/L
		if    (!${CTRL__GL__ACH_DESCRIPTION__USE}){
			$xfer_text="Withdrawal from CU's G/L code \"${from_subacct}\" (for member number ${from_mbnum})";
			$gl_subacct=${from_subacct};
		}elsif(${CTRL__GL__ACH_DESCRIPTION__DELIMITER} eq ""){
			$xfer_text="Src: ${from_subacct} Dst: ${to_mbnum}-${to_subacct}";
			$gl_subacct=${from_subacct};
		}else{
			if(index(${from_subacct},${CTRL__GL__ACH_DESCRIPTION__DELIMITER})<0){
	   			$gl_ach_desc=${from_subacct};
				$gl_subacct=${from_subacct};
			}else{
	   			$gl_ach_desc=substr(${from_subacct},index(${from_subacct},${CTRL__GL__ACH_DESCRIPTION__DELIMITER})+length(${CTRL__GL__ACH_DESCRIPTION__DELIMITER}));
				$gl_subacct=substr(${from_subacct},0,index(${from_subacct},${CTRL__GL__ACH_DESCRIPTION__DELIMITER}));
				$gl_subacct=~s/ *$//;
				$gl_ach_desc=~s/^ *//;
				$gl_ach_desc=~s/ *$//;
				if(${gl_ach_desc} eq ""){
					$gl_ach_desc=${gl_subacct};
				}else{
					$gl_ach_desc="(ACH) ${gl_ach_desc}";
				}
			}
			$xfer_text="Src: ${gl_ach_desc} Dst: ${to_mbnum}-${to_subacct}";
		}
	}elsif(substr(${xfer_mode},1,1) eq "G"){	# The "To" is a G/L
		if    (!${CTRL__GL__ACH_DESCRIPTION__USE}){
			$xfer_text="Deposit to CU's G/L code \"${to_subacct}\" (for member number ${to_mbnum})";
			$gl_subacct=${to_subacct};
		}elsif(${CTRL__GL__ACH_DESCRIPTION__DELIMITER} eq ""){
			$xfer_text="Src: ${from_mbnum}-${from_subacct} Dst: ${to_subacct}";
			$gl_subacct=${to_subacct};
		}else{
			if(index(${to_subacct},${CTRL__GL__ACH_DESCRIPTION__DELIMITER})<0){
	   			$gl_ach_desc=${to_subacct};
				$gl_subacct=${to_subacct};
			}else{
	   			$gl_ach_desc=substr(${to_subacct},index(${to_subacct},${CTRL__GL__ACH_DESCRIPTION__DELIMITER})+length(${CTRL__GL__ACH_DESCRIPTION__DELIMITER}));
				$gl_subacct=substr(${to_subacct},0,index(${to_subacct},${CTRL__GL__ACH_DESCRIPTION__DELIMITER}));
				$gl_subacct=~s/ *$//;
				$gl_ach_desc=~s/^ *//;
				$gl_ach_desc=~s/ *$//;
				if(${gl_ach_desc} eq ""){
					$gl_ach_desc=${gl_subacct};
				}else{
					$gl_ach_desc="(ACH) ${gl_ach_desc}";
				}
			}
			$xfer_text="Src: ${from_mbnum}-${from_subacct} Dst: ${gl_ach_desc}";
		}
	}
	return(${gl_subacct},${xfer_text});
}

sub transaction_log{
   local($level_order,$level_text,$tran_code,$composit_from,$composit_to,$amt,$tmemo,$other,$comment)=@_;
   local($TRAN_LOGFILE_MAX_BYTES)=20971520;
   local($TRAN_LOGFILE_NAME);
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f);
   local($timestamp);
   local($fmt_pid);
   local(*TRAN_LOGFILE_LOCK,*TRAN_LOGFILE_FH);
   local($textfilter_mode_SANE,$textfilter_mode_HTML,$textfilter_mode_POSTGRES)=(0,0,0);	# Temporarily override global setting used by textfilter() and textfilter_html()
	$fmt_pid=sprintf("%07.0f",$$);
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	if(${CTRL__DMS_ADMINDIR} eq ""){
		$TRAN_LOGFILE_NAME="${DMS_HOMEDIR}/q_trn.log";
	}else{
		$TRAN_LOGFILE_NAME="${CTRL__DMS_ADMINDIR}/q_trn.log";
	}
	if(! -f "${TRAN_LOGFILE_NAME}.lock"){
		open(TRAN_LOGFILE_LOCK,"+>>${TRAN_LOGFILE_NAME}.lock");
		chmod(0666,"${TRAN_LOGFILE_NAME}.lock");
	}else{
		open(TRAN_LOGFILE_LOCK,"+>>${TRAN_LOGFILE_NAME}.lock");
	}
	flock(TRAN_LOGFILE_LOCK,${LOCK_EX});
	seek(TRAN_LOGFILE_LOCK,0,2);
	if(! -f ${TRAN_LOGFILE_NAME}){
		open(TRAN_LOGFILE_FH,"+>>${TRAN_LOGFILE_NAME}");
		chmod(0666,${TRAN_LOGFILE_NAME});
	}else{
		open(TRAN_LOGFILE_FH,"+>>${TRAN_LOGFILE_NAME}");
	}
	if(-s TRAN_LOGFILE_FH > ${TRAN_LOGFILE_MAX_BYTES} and ${level_order} eq "1"){
		if(-f "${TRAN_LOGFILE_NAME}O.8"){
			if(!rename("${TRAN_LOGFILE_NAME}O.8","${TRAN_LOGFILE_NAME}O.9")){
				system("mv '${TRAN_LOGFILE_NAME}O.8' '${TRAN_LOGFILE_NAME}O.9'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.7"){
			if(!rename("${TRAN_LOGFILE_NAME}O.7","${TRAN_LOGFILE_NAME}O.8")){
				system("mv '${TRAN_LOGFILE_NAME}O.7' '${TRAN_LOGFILE_NAME}O.8'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.6"){
			if(!rename("${TRAN_LOGFILE_NAME}O.6","${TRAN_LOGFILE_NAME}O.7")){
				system("mv '${TRAN_LOGFILE_NAME}O.6' '${TRAN_LOGFILE_NAME}O.7'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.5"){
			if(!rename("${TRAN_LOGFILE_NAME}O.5","${TRAN_LOGFILE_NAME}O.6")){
				system("mv '${TRAN_LOGFILE_NAME}O.5' '${TRAN_LOGFILE_NAME}O.6'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.4"){
			if(!rename("${TRAN_LOGFILE_NAME}O.4","${TRAN_LOGFILE_NAME}O.5")){
				system("mv '${TRAN_LOGFILE_NAME}O.4' '${TRAN_LOGFILE_NAME}O.5'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.3"){
			if(!rename("${TRAN_LOGFILE_NAME}O.3","${TRAN_LOGFILE_NAME}O.4")){
				system("mv '${TRAN_LOGFILE_NAME}O.3' '${TRAN_LOGFILE_NAME}O.4'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.2"){
			if(!rename("${TRAN_LOGFILE_NAME}O.2","${TRAN_LOGFILE_NAME}O.3")){
				system("mv '${TRAN_LOGFILE_NAME}O.2' '${TRAN_LOGFILE_NAME}O.3'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.1"){
			if(!rename("${TRAN_LOGFILE_NAME}O.1","${TRAN_LOGFILE_NAME}O.2")){
				system("mv '${TRAN_LOGFILE_NAME}O.1' '${TRAN_LOGFILE_NAME}O.2'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.0"){
			if(!rename("${TRAN_LOGFILE_NAME}O.0","${TRAN_LOGFILE_NAME}O.1")){
				system("mv '${TRAN_LOGFILE_NAME}O.0' '${TRAN_LOGFILE_NAME}O.1'");
			}
		}
		if(!rename("${TRAN_LOGFILE_NAME}","${TRAN_LOGFILE_NAME}O.0")){
			system("mv '${TRAN_LOGFILE_NAME}' '${TRAN_LOGFILE_NAME}O.0'");
		}
		open(TRAN_LOGFILE_FH,"+>>${TRAN_LOGFILE_NAME}");
		chmod(0666,${TRAN_LOGFILE_NAME});
	}
	print TRAN_LOGFILE_FH join("\t",${timestamp},${fmt_pid},${level_order},${level_text},${tran_code},${composit_from},${composit_to},${amt},&textfilter(${tmemo}),${other},${comment}),"\n";
	close(TRAN_LOGFILE_FH);
	flock(TRAN_LOGFILE_LOCK,${LOCK_UN});
	close(TRAN_LOGFILE_LOCK);
}

sub transaction_log_XX{
   local($group,$level_order,$level_text,@values)=@_;
   local($TRAN_LOGFILE_MAX_BYTES)=20971520;
   local($TRAN_LOGFILE_NAME);
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f);
   local($timestamp);
   local($fmt_pid);
   local(*TRAN_LOGFILE_LOCK,*TRAN_LOGFILE_FH);
	$fmt_pid=sprintf("%07.0f",$$);
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	if(${CTRL__DMS_ADMINDIR} eq ""){
		$TRAN_LOGFILE_NAME="${DMS_HOMEDIR}/q_trn_${group}.log";
	}else{
		$TRAN_LOGFILE_NAME="${CTRL__DMS_ADMINDIR}/q_trn_${group}.log";
	}
	if(! -f "${TRAN_LOGFILE_NAME}.lock"){
		open(TRAN_LOGFILE_LOCK,"+>>${TRAN_LOGFILE_NAME}.lock");
		chmod(0666,"${TRAN_LOGFILE_NAME}.lock");
	}else{
		open(TRAN_LOGFILE_LOCK,"+>>${TRAN_LOGFILE_NAME}.lock");
	}
	flock(TRAN_LOGFILE_LOCK,${LOCK_EX});
	seek(TRAN_LOGFILE_LOCK,0,2);
	if(! -f ${TRAN_LOGFILE_NAME}){
		open(TRAN_LOGFILE_FH,"+>>${TRAN_LOGFILE_NAME}");
		chmod(0666,${TRAN_LOGFILE_NAME});
	}else{
		open(TRAN_LOGFILE_FH,"+>>${TRAN_LOGFILE_NAME}");
	}
	if(-s TRAN_LOGFILE_FH > ${TRAN_LOGFILE_MAX_BYTES} and ${level_order} eq "1"){
		if(-f "${TRAN_LOGFILE_NAME}O.8"){
			if(!rename("${TRAN_LOGFILE_NAME}O.8","${TRAN_LOGFILE_NAME}O.9")){
				system("mv '${TRAN_LOGFILE_NAME}O.8' '${TRAN_LOGFILE_NAME}O.9'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.7"){
			if(!rename("${TRAN_LOGFILE_NAME}O.7","${TRAN_LOGFILE_NAME}O.8")){
				system("mv '${TRAN_LOGFILE_NAME}O.7' '${TRAN_LOGFILE_NAME}O.8'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.6"){
			if(!rename("${TRAN_LOGFILE_NAME}O.6","${TRAN_LOGFILE_NAME}O.7")){
				system("mv '${TRAN_LOGFILE_NAME}O.6' '${TRAN_LOGFILE_NAME}O.7'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.5"){
			if(!rename("${TRAN_LOGFILE_NAME}O.5","${TRAN_LOGFILE_NAME}O.6")){
				system("mv '${TRAN_LOGFILE_NAME}O.5' '${TRAN_LOGFILE_NAME}O.6'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.4"){
			if(!rename("${TRAN_LOGFILE_NAME}O.4","${TRAN_LOGFILE_NAME}O.5")){
				system("mv '${TRAN_LOGFILE_NAME}O.4' '${TRAN_LOGFILE_NAME}O.5'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.3"){
			if(!rename("${TRAN_LOGFILE_NAME}O.3","${TRAN_LOGFILE_NAME}O.4")){
				system("mv '${TRAN_LOGFILE_NAME}O.3' '${TRAN_LOGFILE_NAME}O.4'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.2"){
			if(!rename("${TRAN_LOGFILE_NAME}O.2","${TRAN_LOGFILE_NAME}O.3")){
				system("mv '${TRAN_LOGFILE_NAME}O.2' '${TRAN_LOGFILE_NAME}O.3'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.1"){
			if(!rename("${TRAN_LOGFILE_NAME}O.1","${TRAN_LOGFILE_NAME}O.2")){
				system("mv '${TRAN_LOGFILE_NAME}O.1' '${TRAN_LOGFILE_NAME}O.2'");
			}
		}
		if(-f "${TRAN_LOGFILE_NAME}O.0"){
			if(!rename("${TRAN_LOGFILE_NAME}O.0","${TRAN_LOGFILE_NAME}O.1")){
				system("mv '${TRAN_LOGFILE_NAME}O.0' '${TRAN_LOGFILE_NAME}O.1'");
			}
		}
		if(!rename("${TRAN_LOGFILE_NAME}","${TRAN_LOGFILE_NAME}O.0")){
			system("mv '${TRAN_LOGFILE_NAME}' '${TRAN_LOGFILE_NAME}O.0'");
		}
		open(TRAN_LOGFILE_FH,"+>>${TRAN_LOGFILE_NAME}");
		chmod(0666,${TRAN_LOGFILE_NAME});
	}
	print TRAN_LOGFILE_FH join("\t",${timestamp},${fmt_pid},${level_order},${level_text},@values),"\n";
	close(TRAN_LOGFILE_FH);
	flock(TRAN_LOGFILE_LOCK,${LOCK_UN});
	close(TRAN_LOGFILE_LOCK);
}

sub transaction_adjust{
   local($orig_auth_mb,$orig_from_mb,$orig_from_accttype,$orig_to_mb,$orig_to_accttype,$orig_amt,$tran_code,$xxxx_from_accttype__is_not_xjo,$xxxx_to_accttype__is_not_xjo)=@_;
   local($rtrn_auth_mb,$rtrn_from_mb,$rtrn_from_accttype,$rtrn_to_mb,$rtrn_to_accttype,$rtrn_amt);
   local($rtrn_error_num,$rtrn_error_text)=(0,"");
   local($tran_code_unrestricted_transfer)=0;
   local($class_from_accttype,$class_to_accttype);
   local($idx);
   local(@f);
   local($found_from,$found_to);
   local($payoff_amount);
   local($cuprodigy_from_accttype);
   local($cuprodigy_to_accttype);
   local($subroutine_reference)="transaction_adjust(${orig_auth_mb},${orig_from_mb},${orig_from_accttype},${orig_to_mb},${orig_to_accttype},${orig_amt},${tran_code},${xxxx_from_accttype__is_not_xjo},${xxxx_to_accttype__is_not_xjo})";
   local($excl_reason);
   local($from_xjo_composit_dplncc,$to_xjo_composit_dplncc);
   local($from_xjo_composit_dplncc__is_an_xjo,$to_xjo_composit_dplncc__is_an_xjo);
	# Will populate (calling routine must have declared as "local()"):
	($rtrn_auth_mb,$rtrn_from_mb,$rtrn_from_accttype,$rtrn_to_mb,$rtrn_to_accttype,$rtrn_amt)=($orig_auth_mb,$orig_from_mb,$orig_from_accttype,$orig_to_mb,$orig_to_accttype,$orig_amt);
	$rtrn_auth_mb=${rtrn_from_mb} if $rtrn_auth_mb !~ /[1-9]/;
	$rtrn_auth_mb=sprintf("%.0f",${rtrn_auth_mb});
	$rtrn_from_mb=sprintf("%.0f",${rtrn_from_mb});
	$rtrn_to_mb=${rtrn_from_mb} if ${rtrn_to_mb} !~ /[1-9]/;
	$rtrn_to_mb=sprintf("%.0f",${rtrn_to_mb});
	if(${rtrn_error_text} eq ""){
		if(${rtrn_from_mb} < 1){
			$rtrn_error_num="999";
			$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Invalid Transfer FROM Member Number.";
		}
	}
	if(${rtrn_error_text} eq ""){
		if(${rtrn_to_mb} < 1){
			$rtrn_error_num="999";
			$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Invalid Transfer TO Member Number.";
		}
	}
	if(${rtrn_error_text} eq ""){
		$rtrn_error_text=&inquiry(0,${rtrn_auth_mb});
		if(${rtrn_error_text} ne ""){
			&logfile("${subroutine_reference}: inquiry(0,${rtrn_auth_mb}): Failed.\n");
			$rtrn_error_text=~s/^.*\n//;	# Use just the last failure message.
			($rtrn_error_num,$rtrn_error_text)=split(/\t/,${rtrn_error_text},2);
		}
		if(${rtrn_error_text} eq ""){
			local(@XML_MB_UNIQID);
			local(@XML_MB_DP_UNIQID);
			local(@XML_MB_LN_UNIQID);
			local(@XML_MB_CC_UNIQID);
			$rtrn_error_text=&cuprodigy_xml_crossaccount(${rtrn_auth_mb},"",0);
			if(${rtrn_error_text} ne ""){
				&logfile("${subroutine_reference}: cuprodigy_xml_crossaccount(${rtrn_auth_mb},,0): Failed.\n");
				$rtrn_error_text=~s/^.*\n//;	# Use just the last failure message.
				($rtrn_error_num,$rtrn_error_text)=split(/\t/,${rtrn_error_text},2);
			}
		}
		if(${rtrn_error_text} eq ""){
			if(${tran_code} eq "GF" or ${tran_code} eq "GP"){
				$from_xjo_composit_dplncc="";
				$from_xjo_composit_dplncc__is_an_xjo=0;
			}else{
				$from_xjo_composit_dplncc=&join_dms_xjo_overloaded_composit(${rtrn_auth_mb},${rtrn_from_mb},${rtrn_from_accttype},${xxxx_from_accttype__is_not_xjo});
				if(${from_xjo_composit_dplncc} ne ${rtrn_from_accttype}){
					$from_xjo_composit_dplncc__is_an_xjo=1;
				}
			}
			if(${tran_code} eq "GT" or ${tran_code} eq "GA"){
				$to_xjo_composit_dplncc="";
				$to_xjo_composit_dplncc__is_an_xjo=0;
			}else{
				$to_xjo_composit_dplncc=&join_dms_xjo_overloaded_composit(${rtrn_auth_mb},${rtrn_to_mb},${rtrn_to_accttype},${xxxx_to_accttype__is_not_xjo});
				if(${to_xjo_composit_dplncc} ne ${rtrn_to_accttype}){
					$to_xjo_composit_dplncc__is_an_xjo=1;
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		# Determine class of each account based upon the DMS/HomeCU transaction code.
		$class_from_accttype="";
		$class_to_accttype="";
		if($tran_code =~ /^X[A-Z][A-Z]$/){	# Like values "XAT", "XLP", "XLA", "XLC", "XCW", "XED", "XCP", "XMP", and "XVP".
			if(${CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION}){
				$tran_code_unrestricted_transfer=1;
				$tran_code=~s/^X//;
			}else{
				&logfile("${subroutine_reference}: The \$CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION is disabled; to enable Unrestricted Transfers the \$CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION must be enabled.\n");
				$rtrn_error_num="999";
				$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware is not configured to allow Unrestricted Transfers using transaction code '${tran_code}'.";
			}
		}
		if    ($tran_code eq "AT"){
			$class_from_accttype="DP"; $class_to_accttype="DP";
		}elsif($tran_code eq "MM"){
			if(${tran_code_unrestricted_transfer}){
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware does not allow Unrestricted Transfers on a Member-to-Member Transfers (transaction code 'X${tran_code}').";
			}elsif($orig_to_accttype =~ /^<.*:Lookup:1st:Draft:.*>$/){
				$class_from_accttype="DP"; $class_to_accttype="DP";
			}elsif($orig_to_accttype =~ /^<.*:Lookup:1st:Share:.*>$/){
				$class_from_accttype="DP"; $class_to_accttype="DP";
			}else{
				$error_num="999";
				$error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Middleware subroutine transaction_adjust() not yet coded to handle Member-to-Member Transfers resolution for what '${orig_to_accttype}' refers to.";
			}
		}elsif($tran_code eq "LP"){
			$class_from_accttype="DP"; $class_to_accttype="LN";
		}elsif($tran_code eq "LA"){
			$class_from_accttype="LN"; $class_to_accttype="DP";
		}elsif($tran_code eq "GT"){
			$class_from_accttype="DP"; $class_to_accttype="GL";
		}elsif($tran_code eq "GF"){
			$class_from_accttype="GL"; $class_to_accttype="DP";
		}elsif($tran_code eq "GA"){
			$class_from_accttype="LN"; $class_to_accttype="GL";
		}elsif($tran_code eq "GP"){
			$class_from_accttype="GL"; $class_to_accttype="LN";
		}elsif($tran_code eq "LC"){
			$class_from_accttype="LN"; $class_to_accttype="";
		}elsif($tran_code eq "CW"){
			$class_from_accttype="DP"; $class_to_accttype="";
		}elsif($tran_code eq "ED"){
			$class_from_accttype=""; $class_to_accttype="DP";
		}elsif($tran_code eq "CP"){
			$class_from_accttype="DP"; $class_to_accttype="CC";
		}elsif($tran_code eq "MP"){
			$class_from_accttype="DP"; $class_to_accttype="CC";
		}elsif($tran_code eq "VP"){
			$class_from_accttype="DP"; $class_to_accttype="CC";
		}elsif($tran_code eq "MD"){
			$class_from_accttype=""; $class_to_accttype="";
		}elsif($tran_code eq "MA"){
			$class_from_accttype=""; $class_to_accttype="";
		}elsif($tran_code eq "ES"){
			$class_from_accttype=""; $class_to_accttype="";
		}elsif($tran_code eq "PC"){
			$class_from_accttype=""; $class_to_accttype="";
		}else{
			$class_from_accttype=""; $class_to_accttype="";
		}
		if(${tran_code_unrestricted_transfer}){ $tran_code=~s/^/X/; }
	}
	if(${class_from_accttype} eq "" and ${class_to_accttype} eq "" and ${rtrn_error_text} eq ""){
		$rtrn_error_num="999";
		$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Unsupported transaction code '${tran_code}'.";
	}
	if(0){	# MARK -- Need to rewrite this section for CUProdigy; also need to implement anything special for XJO account validation (review transaction_adjust() in "dmshomecusymitar.pl"), probably based on data that inquiry() will populate into @XML_MB_XJO, @XML_MB_XAC, @XML_MB_UNIQID, @XML_MB_DP_UNIQID, @XML_MB_LN_UNIQID, @XML_MB_CC_UNIQID, @XML_MB_DP_BALS, @XML_MB_LN_BALS, @XML_MB_CC_BALS, @XML_MB_DP_ATTRS, @XML_MB_LN_ATTRS, and @XML_MB_CC_ATTRS.
		if(${rtrn_error_text} eq ""){
			# Validate and expand short CC numbers to full CC numbers
			if(${class_from_accttype} eq "CC"){
				if(&full_cc_num(${rtrn_from_mb},${rtrn_from_accttype}) eq ""){
					&logfile("${subroutine_reference}: full_cc_num(${rtrn_from_mb},${rtrn_from_accttype}): Could not find a unique full credit card number value for the short credit card number value.\n");
					$rtrn_error_num="999";
					$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Unable to resolve transfer FROM credit card reference.";
				}else{
					$rtrn_from_accttype=&full_cc_num(${rtrn_from_mb},${rtrn_from_accttype});
				}
			}
			if(${class_to_accttype} eq "CC"){
				if(&full_cc_num(${rtrn_to_mb},${rtrn_to_accttype}) eq ""){
					&logfile("${subroutine_reference}: full_cc_num(${rtrn_to_mb},${rtrn_to_accttype}): Could not find a unique full credit card number value for the short credit card number value.\n");
					$rtrn_error_num="999";
					$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."Unable to resolve transfer TO credit card reference.";
				}else{
					$rtrn_to_accttype=&full_cc_num(${rtrn_to_mb},${rtrn_to_accttype});
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		# Validate transfer From account
		if(${class_from_accttype} eq ""){
			$found_from=1;
		}else{
			$found_from=0;
			if    (${class_from_accttype} eq "DP"){
				for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
					@f=split(/\t/,$XML_MB_DP_BALS[${idx}]);
					if($f[0] eq ${rtrn_auth_mb} and $f[1] eq ${from_xjo_composit_dplncc} and $f[2] eq "0"){
						$found_from=1;
					}
				}
			}elsif(${class_from_accttype} eq "LN"){
				for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
					@f=split(/\t/,$XML_MB_LN_BALS[${idx}]);
					if($f[0] eq ${rtrn_auth_mb} and $f[1] eq ${from_xjo_composit_dplncc}){
						$found_from=1;
					}
				}
			}elsif(${class_from_accttype} eq "CC"){
				for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
					@f=split(/\t/,$XML_MB_CC_BALS[${idx}]);
					if($f[0] eq ${rtrn_auth_mb} and $XML_MB_CC_TO_UNIQ{${rtrn_auth_mb},${from_xjo_composit_dplncc}} ne ""){
						$found_from=1;
					}
				}
			}elsif(${class_from_accttype} eq "GL"){
				$found_from=1;
			}
			if(!${found_from}){
				if(${CTRL__VALIDATE_ACCOUNTS_BEFORE_SENDING_REQUEST}){
					$rtrn_error_num="999";
					$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer FROM is for an unknown account.";
				}else{
					$found_from=1;
					&logfile("${subroutine_reference}: Allowing transfer FROM for an unknown account.\n");
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		# Validate transfer To account
		if(${class_to_accttype} eq ""){
			$found_to=1;
		}else{
			$found_to=0;
			if    (${class_to_accttype} eq "DP"){
				for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
					@f=split(/\t/,$XML_MB_DP_BALS[${idx}]);
					if($f[0] eq ${rtrn_auth_mb} and $f[1] eq ${to_xjo_composit_dplncc} and $f[2] eq "0"){
						$found_to=1;
					}
				}
				for($idx=0;$idx<=$#XML_MB_XAC;$idx++){
					@f=split(/\t/,$XML_MB_XAC[${idx}]);
					if($f[1] eq ${rtrn_to_mb} and $f[2] eq ${rtrn_to_accttype} and &list_found($f[3],${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN})){
						$found_to=1;
					}
				}
			}elsif(${class_to_accttype} eq "LN"){
				for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
					@f=split(/\t/,$XML_MB_LN_BALS[${idx}]);
					if($f[0] eq ${rtrn_auth_mb} and $f[1] eq ${to_xjo_composit_dplncc}){
						$found_to=1;
					}
				}
				for($idx=0;$idx<=$#XML_MB_XAC;$idx++){
					@f=split(/\t/,$XML_MB_XAC[${idx}]);
					if($f[1] eq ${rtrn_to_mb} and $f[2] eq ${rtrn_to_accttype} and &list_found($f[3],${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN})){
						$found_to=1;
					}
				}
			}elsif(${class_to_accttype} eq "CC"){
				for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
					@f=split(/\t/,$XML_MB_CC_BALS[${idx}]);
					if($f[0] eq ${rtrn_auth_mb} and $XML_MB_CC_TO_UNIQ{${rtrn_auth_mb},${to_xjo_composit_dplncc}} ne ""){
						$found_to=1;
					}
				}
				for($idx=0;$idx<=$#XML_MB_XAC;$idx++){
					@f=split(/\t/,$XML_MB_XAC[${idx}]);
					if($f[1] eq ${rtrn_to_mb} and $f[2] eq ${rtrn_to_accttype} and &list_found($f[3],${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN})){
						$found_to=1;
					}
				}
			}elsif(${class_to_accttype} eq "GL"){
				$found_to=1;
			}
			if($tran_code eq "MM"){
				($rtrn_to_accttype,$rtrn_error_num,$rtrn_error_text)=&transaction_adjust__resolve_member_to_member(${rtrn_auth_mb},${rtrn_to_mb},${rtrn_to_accttype});
				if(${rtrn_error_text} ne ""){
					$rtrn_to_accttype=${orig_to_accttype};
					$found_to=0;
				}else{
					$found_to=1;
				}
			}else{
				if(!${found_to}){
					if(${CTRL__VALIDATE_ACCOUNTS_BEFORE_SENDING_REQUEST} and !${tran_code_unrestricted_transfer}){
						$rtrn_error_num="999";
						$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer TO is for an unknown account.";
					}else{
						$found_to=1;
						&logfile("${subroutine_reference}: Allowing transfer TO for an unknown account.\n");
					}
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		if(${class_to_accttype} eq ""){
			1;
		}else{
			# Adjust To Payoff amounts
			if(!${tran_code_unrestricted_transfer}){	# Not an Unrestricted Transfers where $tran_code is "XLP" or "XCP" or "XMP" or "XVP".
				$payoff_amount=0;
				if    (${class_to_accttype} eq "LN"){
					if(${CTRL__VALIDATE_ACCOUNTS_BEFORE_SENDING_REQUEST}){
						$payoff_amount="";
						if(${payoff_amount} eq ""){
							if(${xxxx_to_accttype__is_not_xjo}){
								for($idx=0;$idx<=$#XML_MB_XAC_LN_PAYOFF;$idx++){
									@f=split(/\t/,$XML_MB_XAC_LN_PAYOFF[${idx}]);
									if($f[1] eq ${rtrn_to_mb} and $f[2] eq ${rtrn_to_accttype}){
										$payoff_amount=sprintf("%.2f",$f[3]);
									}
								}
							}
						}
						if(${payoff_amount} eq ""){
							if(${xxxx_to_accttype__is_not_xjo}){
								for($idx=0;$idx<=$#XML_MB_LN_PAYOFF;$idx++){
									@f=split(/\t/,$XML_MB_LN_PAYOFF[${idx}]);
									if($f[1] eq ${rtrn_to_mb} and $f[2] eq ${rtrn_to_accttype}){
										$payoff_amount=sprintf("%.2f",$f[3]);
									}
								}
							}else{
								for($idx=0;$idx<=$#XML_MB_LN_PAYOFF;$idx++){
									@f=split(/\t/,$XML_MB_LN_PAYOFF[${idx}]);
									if($f[1] eq ${rtrn_auth_mb} and $f[2] eq ${to_xjo_composit_dplncc}){
										$payoff_amount=sprintf("%.2f",$f[3]);
									}
								}
							}
						}
						if(${payoff_amount} < 0){
							$payoff_amount=sprintf("%.2f",0);
						}
						if(${payoff_amount} <= 0){
							&logfile("${subroutine_reference}: Rejecting loan payment because the loan balance has already been paid off.\n");
							$rtrn_error_num="999";
							$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."The loan balance has already been paid off.";
						}
						if(${payoff_amount} > 0 and sprintf("%.2f",${orig_amt}) > ${payoff_amount}){
							if($CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT =~ /^ACCEPT$/i){
								&logfile("${subroutine_reference}: Allowing loan payment of '".sprintf("%.2f",${orig_amt})."' when payoff is '".sprintf("%.2f",${payoff_amount})."'.\n");
								$rtrn_amt=sprintf("%.2f",${orig_amt});
							}
							if($CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT =~ /^ADJUST$/i){
								&logfile("${subroutine_reference}: Adjusting loan payment from '".sprintf("%.2f",${orig_amt})."' to  '".sprintf("%.2f",${payoff_amount})."'.\n");
								$rtrn_amt=sprintf("%.2f",${payoff_amount});
							}
							if($CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT =~ /^REJECT$/i){
								&logfile("${subroutine_reference}: Rejecting loan payment because '".sprintf("%.2f",${orig_amt})."' exceeds payoff of '".sprintf("%.2f",${payoff_amount})."'.\n");
								$rtrn_error_num="999";
								$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Amount exceeds the loan payoff amount.";
								# $rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Amount exceeds the loan payoff amount of \$".sprintf("%.2f",${payoff_amount}).".";
							}
						}
					}else{
						&logfile("${subroutine_reference}: Allowing loan payment without first checking for payoff.\n");
					}
				}elsif(${class_to_accttype} eq "CC"){
					if(${CTRL__VALIDATE_ACCOUNTS_BEFORE_SENDING_REQUEST}){
						for($idx=0;$idx<=$#XML_MB_CC_PAYOFF;$idx++){
							@f=split(/\t/,$XML_MB_CC_PAYOFF[${idx}]);
							if($f[1] eq ${rtrn_auth_mb} and $f[2] eq ${to_xjo_composit_dplncc}){
								$payoff_amount=sprintf("%.2f",$f[3]);
							}
						}
						if(${payoff_amount} < 0){
							$payoff_amount=sprintf("%.2f",0);
						}
						if(${payoff_amount} <= 0){
							&logfile("${subroutine_reference}: Rejecting credit card payment because the credit card balance has already been paid off.\n");
							$rtrn_error_num="999";
							$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."The credit card balance has already been paid off.";
						}
						if(${payoff_amount} > 0 and sprintf("%.2f",${orig_amt}) > ${payoff_amount}){
							if($CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT =~ /^ACCEPT$/i){
								&logfile("${subroutine_reference}: Allowing credit card payment of '".sprintf("%.2f",${orig_amt})."' when payoff is '".sprintf("%.2f",${payoff_amount})."'.\n");
								$rtrn_amt=sprintf("%.2f",${orig_amt});
							}
							if($CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT =~ /^ADJUST$/i){
								&logfile("${subroutine_reference}: Adjusting credit card payment from '".sprintf("%.2f",${orig_amt})."' to  '".sprintf("%.2f",${payoff_amount})."'.\n");
								$rtrn_amt=sprintf("%.2f",${payoff_amount});
							}
							if($CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT =~ /^REJECT$/i){
								&logfile("${subroutine_reference}: Rejecting credit card payment because '".sprintf("%.2f",${orig_amt})."' exceeds payoff of '".sprintf("%.2f",${payoff_amount})."'.\n");
								$rtrn_error_num="999";
								$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Amount exceeds the credit card payoff amount.";
								# $rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Amount exceeds the credit card payoff amount of \$".sprintf("%.2f",${payoff_amount}).".";
							}
						}
					}else{
						&logfile("${subroutine_reference}: Allowing credit card payment without first checking for payoff.\n");
					}
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		# Determine CUProdigy Type of each account.
		if(${rtrn_error_text} eq ""){
			if    (${class_from_accttype} eq ""){
				$cuprodigy_from_accttype="";
			}elsif(${class_from_accttype} eq "GL"){
				$cuprodigy_from_accttype="";
			}else{
				($cuprodigy_from_accttype=${rtrn_from_accttype})=~s/:\d\d$//;	# Extract just CUProdigy account "Type" from account "Type:Seq"
			}
			if    (${class_to_accttype} eq ""){
				$cuprodigy_to_accttype="";
			}elsif(${class_to_accttype} eq ""){
				$cuprodigy_to_accttype="";
			}else{
				($cuprodigy_to_accttype=${rtrn_to_accttype})=~s/:\d\d$//;	# Extract just CUProdigy account "Type" from account "Type:Seq"
			}
		}
		if    (${class_from_accttype} eq ""){
			1;
		}elsif(${class_from_accttype} eq "GL"){
			1;
		}else{
			# Apply rules from configured exclusion lists for Account Group Type and Account Type.
			if(${rtrn_error_text} eq ""){
				if(${class_from_accttype} ne ""){
					if(($excl_reason=&transaction_excl_xfer_from(${class_from_accttype},${cuprodigy_from_accttype},"GEN")) ne ""){
						$rtrn_error_num="999";
						$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer FROM is not allowed for account '${orig_from_accttype}' because of its ${excl_reason}.";
					}
				}
			}
		}
		if    (${class_to_accttype} eq ""){
			1;
		}elsif(${class_to_accttype} eq "GL"){
			1;
		}else{
			if(${rtrn_error_text} eq ""){
				if(${class_to_accttype} ne ""){
					if(($excl_reason=&transaction_excl_xfer_to(${class_to_accttype},${cuprodigy_to_accttype},"GEN")) ne ""){
						$rtrn_error_num="999";
							$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer TO is not allowed for account '${orig_to_accttype}' because of its ${excl_reason}.";
					}
				}
			}
		}
		if(${rtrn_from_mb} != ${rtrn_to_mb}){
			if(${rtrn_error_text} eq ""){
				if(${class_from_accttype} ne ""){
					if(($excl_reason=&transaction_excl_xfer_from(${class_from_accttype},${cuprodigy_from_accttype},"XAC")) ne ""){
						$rtrn_error_num="999";
						$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer FROM is not allowed for account '${orig_from_accttype}' because of its ${excl_reason}.";
					}
				}
			}
			if(${rtrn_error_text} eq ""){
				if(${class_to_accttype} ne ""){
					if(($excl_reason=&transaction_excl_xfer_to(${class_to_accttype},${cuprodigy_to_accttype},"XAC")) ne ""){
						$rtrn_error_num="999";
						$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer TO is not allowed for account '${orig_to_accttype}' because of its ${excl_reason}.";
					}
				}
			}
		}else{
			if(${rtrn_error_text} eq ""){
				if(${class_from_accttype} ne ""){
					if(($excl_reason=&transaction_excl_xfer_from(${class_from_accttype},${cuprodigy_from_accttype},"SELF")) ne ""){
						$rtrn_error_num="999";
						$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer FROM is not allowed for account '${orig_from_accttype}' because of its ${excl_reason}.";
					}
				}
			}
			if(${rtrn_error_text} eq ""){
				if(${class_to_accttype} ne ""){
					if(($excl_reason=&transaction_excl_xfer_to(${class_to_accttype},${cuprodigy_to_accttype},"SELF")) ne ""){
						$rtrn_error_num="999";
						$rtrn_error_text=${CTRL__ERROR_999_PREFIX__DMS_NORMAL}."Transfer TO is not allowed for account '${orig_to_accttype}' because of its ${excl_reason}.";
					}
				}
			}
		}
	}
	&logfile("${subroutine_reference}: ${rtrn_error_text}\n") if ${rtrn_error_text} ne "";
	return(${rtrn_auth_mb},${rtrn_from_mb},${rtrn_from_accttype},${rtrn_to_mb},${rtrn_to_accttype},${rtrn_amt},${rtrn_error_num},${rtrn_error_text});
}

sub transaction_adjust__resolve_member_to_member{
   local($auth_mb,$to_mb,$to_accttype)=@_;
   local($rtrn_to_accttype,$rtrn_error_num,$rtrn_error_text)=("","","");
   local($subroutine_reference)="transaction_adjust__resolve_member_to_member(${auth_mb},${to_mb},${to_accttype})";
   local($find_draft,$find_share)=(0,0);
   local($member_last_name)="";
   local($error_num_and_text,$composit_mir_data,%XML_MB_MIR);
   local($idx,@f);
   local($look_for_group,$look_for_count,$look_for_deposittype);
   local(%SEQUENTIAL_ORDERED_LIST);
   local($key);
   local(%CACHE_MB_DP_TO_MICR);	# Since MICRs are sent through transaction history (rather than balance record), need to be able to lookup the last value (from a cache file) when no current transaction history has a MICR.
   local(@XML_MB_UNIQID);
   local(@XML_MB_DP_UNIQID);
   local(@XML_MB_LN_UNIQID);
   local(@XML_MB_CC_UNIQID);
   local(@XML_MB_DP_BALS);
   local(@XML_MB_LN_BALS);
   local(@XML_MB_CC_BALS,%XML_MB_CC_TO_UNIQ,%XML_MB_CC_FROM_UNIQ);
   local(@XML_MB_XAC);
   local(@XML_MB_DP_GROUPS);
   local(@XML_MB_LN_GROUPS);
   local(@XML_MB_CC_GROUPS);
   local(@XML_MB_DP_ATTRS);
   local(@XML_MB_LN_ATTRS);
   local(@XML_MB_CC_ATTRS);
   local(@XML_MB_DP_ACCESS_INFO);
   local(@XML_MB_LN_ACCESS_INFO);
   local(@XML_MB_CC_ACCESS_INFO);
   local(@XML_MB_DP_EXPIRED);
   local(@XML_MB_LN_EXPIRED);
   local(@XML_MB_CC_EXPIRED);
   local(@XML_MB_LN_PAYOFF);
   local(@XML_MB_CC_PAYOFF);
	if    ($to_accttype =~ /^<.*:Lookup:1st:Draft:.*>$/){
		$find_draft=1;
		($member_last_name=${to_accttype})=~s/^(<.*:Lookup:1st:Draft:)(.*)(>)$/$2/;
	}elsif($to_accttype =~ /^<.*:Lookup:2nd:Draft:.*>$/){
		$find_draft=2;
		($member_last_name=${to_accttype})=~s/^(<.*:Lookup:2nd:Draft:)(.*)(>)$/$2/;
	}elsif($to_accttype =~ /^<.*:Lookup:3rd:Draft:.*>$/){
		$find_draft=3;
		($member_last_name=${to_accttype})=~s/^(<.*:Lookup:3rd:Draft:)(.*)(>)$/$2/;
	}elsif($to_accttype =~ /^<.*:Lookup:1st:Share:.*>$/){
		$find_share=1;
		($member_last_name=${to_accttype})=~s/^(<.*:Lookup:1st:Share:)(.*)(>)$/$2/;
	}elsif($to_accttype =~ /^<.*:Lookup:2nd:Share:.*>$/){
		$find_share=2;
		($member_last_name=${to_accttype})=~s/^(<.*:Lookup:2nd:Share:)(.*)(>)$/$2/;
	}elsif($to_accttype =~ /^<.*:Lookup:3rd:Share:.*>$/){
		$find_share=3;
		($member_last_name=${to_accttype})=~s/^(<.*:Lookup:3rd:Share:)(.*)(>)$/$2/;
	}
	if(${find_draft} > 0 or ${find_share} > 0){
		($error_num_and_text,$composit_mir_data)=&mir_inquiry(${to_mb},1);
		if(${error_num_and_text} ne ""){
			($rtrn_error_num,$rtrn_error_text)=split(/\t/,${error_num_and_text},2);
		}else{
			($XML_MB_MIR{"ACCOUNTNUMBER"},$XML_MB_MIR{"NAMEFIRST"},$XML_MB_MIR{"NAMEMIDDLE"},$XML_MB_MIR{"NAMELAST"},$XML_MB_MIR{"EMAIL"},$XML_MB_MIR{"PHONEHOME"},$XML_MB_MIR{"PHONEWORK"},$XML_MB_MIR{"PHONECELL"},$XML_MB_MIR{"PHONEFAX"},$XML_MB_MIR{"SSN"},$XML_MB_MIR{"ADDRESS","ADDRESS1"},$XML_MB_MIR{"ADDRESS","ADDRESS2"},$XML_MB_MIR{"ADDRESS","CITY"},$XML_MB_MIR{"ADDRESS","STATE"},$XML_MB_MIR{"ADDRESS","POSTALCODE"},$XML_MB_MIR{"ADDRESS","COUNTRY"},$XML_MB_MIR{"DATEOFBIRTH"},$XML_MB_MIR{"MEMBERTYPE"})=split(/\t/,${composit_mir_data});
			$member_last_name=~s/^\s*//; $member_last_name=~s/\s*$//; $member_last_name=~s/\s\s*/ /; $member_last_name=~tr/a-z/A-Z/;
			$XML_MB_MIR{"NAMELAST"}=~s/^\s*//; $XML_MB_MIR{"NAMELAST"}=~s/\s*$//; $XML_MB_MIR{"NAMELAST"}=~s/\s\s*/ /; $XML_MB_MIR{"NAMELAST"}=~tr/a-z/A-Z/;
			if    (${member_last_name} eq ""){
				($rtrn_error_num,$rtrn_error_text)=("999","${CTRL__SERVER_REFERENCE__DMS} middleware blocked the transfer request because the last name is blank on the ${CTRL__SERVER_REFERENCE__CUPRODIGY}.");
			}elsif(${member_last_name} ne $XML_MB_MIR{"NAMELAST"}){
				($rtrn_error_num,$rtrn_error_text)=("999","${CTRL__SERVER_REFERENCE__DMS} middleware blocked the transfer request because the last name provided does not match last name on the ${CTRL__SERVER_REFERENCE__CUPRODIGY}.");
				&logfile("${subroutine_reference}: '${member_last_name}' ne '".$XML_MB_MIR{"NAMELAST"}."'.\n");
			}else{
				$error_num_and_text=&inquiry(0,${to_mb});
				if(${error_num_and_text} ne ""){
					&logfile("${subroutine_reference}: inquiry(0,${to_mb}): Failed.\n");
					$error_num_and_text=~s/^.*\n//;	# Use just the last failure message.
					($rtrn_error_num,$rtrn_error_text)=split(/\t/,${error_num_and_text},2);
				}
				if(${rtrn_error_text} eq ""){
					if(${find_draft} > 0){
						$look_for_group="Draft";
						$look_for_count=sprintf("%.0f",${find_draft});
						$look_for_deposittype="Y";
					}
					if(${find_share} > 0){
						$look_for_group="Share";
						$look_for_count=sprintf("%.0f",${find_share});
						$look_for_deposittype="N";
					}
					if(${look_for_count} > 0){
						for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
							@f=split(/\t/,$XML_MB_DP_BALS[${idx}]);
							next if ${CONF__XJO__USE} and $f[1]=~/@\d\d*$/;
							if($f[3] eq  ${look_for_deposittype}){
								$SEQUENTIAL_ORDERED_LIST{sprintf("%07.0f",${idx})}=$f[1];
							}
						}
						if($CUSTOM{"custom_TRN_MM_prioritized.pi"}>0){
							$rtrn_to_accttype=&custom_TRN_MM_prioritized(${auth_mb},${to_mb},${to_accttype},${look_for_group},${look_for_count},%SEQUENTIAL_ORDERED_LIST);
						}else{
							foreach $key (sort(keys(%SEQUENTIAL_ORDERED_LIST))){
								if(${look_for_count} == 1){
									$rtrn_to_accttype=$SEQUENTIAL_ORDERED_LIST{${key}};
									last;
								}
								$look_for_count=sprintf("%.0f",${look_for_count}-1);
							}
						}
					}
				}
			}
		}
	}
	return(${rtrn_to_accttype},${rtrn_error_num},${rtrn_error_text});
}

sub transaction_excl_xfer_from{
   local($balance_class,$cuprodigy_accttype,$rule_group)=@_;
   local($excl_reason)="";
   local($cuprodigy_accttype__part_to_compare);
   local($delimiter)=",";
   local($ignore_case)=1;
	if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
		if($cuprodigy_accttype =~ /:..@\d\d*$/){	# Regexp matches 2 digit sequence followed by XJO '@' overloaded member number.
			if($cuprodigy_accttype =~ /@\d\d*$/){	# Regexp matches XJO '@' overloaded member number.
				$cuprodigy_accttype=$`;
			}
		}
	}
	($cuprodigy_accttype__part_to_compare=${cuprodigy_accttype})=~s/:\d\d$//;	# Extract just CUProdigy account "Type" from account "Type:Seq"
	if($rule_group =~ /^GEN$/i){
		if(${balance_class} eq "LN" or ${balance_class} eq "CC"){
			if(${excl_reason} eq ""){ $excl_reason="LN Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN},${delimiter},${ignore_case}); }
		}
		if(${balance_class} eq "DP"){
			if(${excl_reason} eq ""){ $excl_reason="DP Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_DP},${delimiter},${ignore_case}); }
		}
	}
	if($rule_group =~ /^XAC$/i){
		if(${balance_class} eq "LN" or ${balance_class} eq "CC"){
			if(${excl_reason} eq ""){ $excl_reason="LN Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN},${delimiter},${ignore_case}); }
		}
		if(${balance_class} eq "DP"){
			if(${excl_reason} eq ""){ $excl_reason="DP Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_DP},${delimiter},${ignore_case}); }
		}
	}
	if($rule_group =~ /^SELF$/i){
		if(${balance_class} eq "LN" or ${balance_class} eq "CC"){
			if(${excl_reason} eq ""){ $excl_reason="LN Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN},${delimiter},${ignore_case}); }
		}
		if(${balance_class} eq "DP"){
			if(${excl_reason} eq ""){ $excl_reason="DP Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_DP},${delimiter},${ignore_case}); }
		}
	}
	return(${excl_reason});
}

sub transaction_excl_xfer_to{
   local($balance_class,$cuprodigy_accttype,$rule_group)=@_;
   local($excl_reason)="";
   local($cuprodigy_accttype__part_to_compare);
   local($delimiter)=",";
   local($ignore_case)=1;
	if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
		if($cuprodigy_accttype =~ /:..@\d\d*$/){	# Regexp matches 2 digit sequence followed by XJO '@' overloaded member number.
			if($cuprodigy_accttype =~ /@\d\d*$/){	# Regexp matches XJO '@' overloaded member number.
				$cuprodigy_accttype=$`;
			}
		}
	}
	($cuprodigy_accttype__part_to_compare=${cuprodigy_accttype})=~s/:\d\d$//;	# Extract just CUProdigy account "Type" from account "Type:Seq"
	if($rule_group =~ /^GEN$/i){
		if(${balance_class} eq "LN" or ${balance_class} eq "CC"){
			if(${excl_reason} eq ""){ $excl_reason="LN Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN},${delimiter},${ignore_case}); }
		}
		if(${balance_class} eq "DP"){
			if(${excl_reason} eq ""){ $excl_reason="DP Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_DP},${delimiter},${ignore_case}); }
		}
	}
	if($rule_group =~ /^XAC$/i){
		if(${balance_class} eq "LN" or ${balance_class} eq "CC"){
			if(${excl_reason} eq ""){ $excl_reason="LN Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN},${delimiter},${ignore_case}); }
		}
		if(${balance_class} eq "DP"){
			if(${excl_reason} eq ""){ $excl_reason="DP Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_DP},${delimiter},${ignore_case}); }
		}
	}
	if($rule_group =~ /^SELF$/i){
		if(${balance_class} eq "LN" or ${balance_class} eq "CC"){
			if(${excl_reason} eq ""){ $excl_reason="LN Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN},${delimiter},${ignore_case}); }
		}
		if(${balance_class} eq "DP"){
			if(${excl_reason} eq ""){ $excl_reason="DP Type" if &list_found(${cuprodigy_accttype__part_to_compare},${CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_DP},${delimiter},${ignore_case}); }
		}
	}
	return(${excl_reason});
}

sub full_cc_num{
   local($mbnum,$ccnum)=@_;
   local($short_ccnum,$full_ccnum);
   local($key);
   local($search_mbnum,$search_ccnum);
   local($found_ccnum_count);
	if(!${CTRL__SHORTEN_CC_TO_LAST_4_DIGITS}){
		$full_ccnum=$ccnum;
	}else{
		$short_ccnum=substr("0" x 6 .${ccnum},-6,6);	# Short CC numbers are the last 4 digits with a 2 digit sequence prefix.
		$full_ccnum=$XML_MB_CC_FROM_UNIQ{${mbnum},${short_ccnum}};
		if(${full_ccnum} eq ""){
			# The 2 digit sequence prefix must have changed, so lets search the long way.
			foreach $key (keys(%XML_MB_CC_FROM_UNIQ)){
				($search_mbnum,$search_ccnum)=split(/$;/,${key});
				if(${mbnum} eq ${search_mbnum}){
					if(substr(${short_ccnum},2) eq substr(${search_ccnum},2)){
						$full_ccnum=$XML_MB_CC_FROM_UNIQ{${key}};
						$found_ccnum_count=sprintf("%.0f",${found_ccnum_count}+1);
					}
				}
			}
			if(${found_ccnum_count} != 1){
				# Could not find a unique occurrance of the last 4 digits, so return nothing.
				$full_ccnum="";
			}
		}
	}
	return(${full_ccnum});
}

sub loanapp_log{
   local($level_order,$level_text,$request_code,$mbnum,$loanappid,$xmldata,$comment)=@_;
   local($LOANAPP_LOGFILE_MAX_BYTES)=20971520;
   local($LOANAPP_LOGFILE_NAME);
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f);
   local($timestamp);
   local($fmt_pid);
   local(*LOANAPP_LOGFILE_LOCK,*LOANAPP_LOGFILE_FH);
	$fmt_pid=sprintf("%07.0f",$$);
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	if(${CTRL__DMS_ADMINDIR} eq ""){
		$LOANAPP_LOGFILE_NAME="${DMS_HOMEDIR}/q_loanapp.log";
	}else{
		$LOANAPP_LOGFILE_NAME="${CTRL__DMS_ADMINDIR}/q_loanapp.log";
	}
	if(! -f "${LOANAPP_LOGFILE_NAME}.lock"){
		open(LOANAPP_LOGFILE_LOCK,"+>>${LOANAPP_LOGFILE_NAME}.lock");
		chmod(0666,"${LOANAPP_LOGFILE_NAME}.lock");
	}else{
		open(LOANAPP_LOGFILE_LOCK,"+>>${LOANAPP_LOGFILE_NAME}.lock");
	}
	flock(LOANAPP_LOGFILE_LOCK,${LOCK_EX});
	seek(LOANAPP_LOGFILE_LOCK,0,2);
	if(! -f ${LOANAPP_LOGFILE_NAME}){
		open(LOANAPP_LOGFILE_FH,"+>>${LOANAPP_LOGFILE_NAME}");
		chmod(0666,${LOANAPP_LOGFILE_NAME});
	}else{
		open(LOANAPP_LOGFILE_FH,"+>>${LOANAPP_LOGFILE_NAME}");
	}
	if(-s LOANAPP_LOGFILE_FH > ${LOANAPP_LOGFILE_MAX_BYTES} and ${level_order} eq "1"){
		if(-f "${LOANAPP_LOGFILE_NAME}O.8"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.8","${LOANAPP_LOGFILE_NAME}O.9")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.8' '${LOANAPP_LOGFILE_NAME}O.9'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.7"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.7","${LOANAPP_LOGFILE_NAME}O.8")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.7' '${LOANAPP_LOGFILE_NAME}O.8'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.6"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.6","${LOANAPP_LOGFILE_NAME}O.7")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.6' '${LOANAPP_LOGFILE_NAME}O.7'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.5"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.5","${LOANAPP_LOGFILE_NAME}O.6")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.5' '${LOANAPP_LOGFILE_NAME}O.6'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.4"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.4","${LOANAPP_LOGFILE_NAME}O.5")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.4' '${LOANAPP_LOGFILE_NAME}O.5'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.3"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.3","${LOANAPP_LOGFILE_NAME}O.4")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.3' '${LOANAPP_LOGFILE_NAME}O.4'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.2"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.2","${LOANAPP_LOGFILE_NAME}O.3")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.2' '${LOANAPP_LOGFILE_NAME}O.3'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.1"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.1","${LOANAPP_LOGFILE_NAME}O.2")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.1' '${LOANAPP_LOGFILE_NAME}O.2'");
			}
		}
		if(-f "${LOANAPP_LOGFILE_NAME}O.0"){
			if(!rename("${LOANAPP_LOGFILE_NAME}O.0","${LOANAPP_LOGFILE_NAME}O.1")){
				system("mv '${LOANAPP_LOGFILE_NAME}O.0' '${LOANAPP_LOGFILE_NAME}O.1'");
			}
		}
		if(!rename("${LOANAPP_LOGFILE_NAME}","${LOANAPP_LOGFILE_NAME}O.0")){
			system("mv '${LOANAPP_LOGFILE_NAME}' '${LOANAPP_LOGFILE_NAME}O.0'");
		}
		open(LOANAPP_LOGFILE_FH,"+>>${LOANAPP_LOGFILE_NAME}");
		chmod(0666,${LOANAPP_LOGFILE_NAME});
	}
	$xmldata=~s/\t/\\t/g; $xmldata=~s/\r/\\r/g; $xmldata=~s/\n/\\n/g;	# Sanitize just so the unexpected does not make the logfile look abnormal
	$comment=~s/^(\d\d*)(\t)/$1 | /g;					# Sanatize the expected occurance where the $comment is a TAB delimited composit of an error number and an error message
	$comment=~s/\t/\\t/g; $comment=~s/\r/\\r/g; $comment=~s/\n/\\n/g;	# Sanitize just so the unexpected does not make the logfile look abnormal
	print LOANAPP_LOGFILE_FH join("\t",${timestamp},${fmt_pid},${level_order},${level_text},${request_code},${mbnum},${loanappid},${xmldata},${comment}),"\n";
	close(LOANAPP_LOGFILE_FH);
	flock(LOANAPP_LOGFILE_LOCK,${LOCK_UN});
	close(LOANAPP_LOGFILE_LOCK);
}

sub estm_log{
   local($level_order,$level_text,$request_code,$mbnum,$estmid,$comment)=@_;
   local($ESTM_LOGFILE_MAX_BYTES)=20971520;
   local($ESTM_LOGFILE_NAME);
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f);
   local($timestamp);
   local($fmt_pid);
   local(*ESTM_LOGFILE_LOCK,*ESTM_LOGFILE_FH);
	$fmt_pid=sprintf("%07.0f",$$);
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	if(${CTRL__DMS_ADMINDIR} eq ""){
		$ESTM_LOGFILE_NAME="${DMS_HOMEDIR}/q_estm.log";
	}else{
		$ESTM_LOGFILE_NAME="${CTRL__DMS_ADMINDIR}/q_estm.log";
	}
	if(! -f "${ESTM_LOGFILE_NAME}.lock"){
		open(ESTM_LOGFILE_LOCK,"+>>${ESTM_LOGFILE_NAME}.lock");
		chmod(0666,"${ESTM_LOGFILE_NAME}.lock");
	}else{
		open(ESTM_LOGFILE_LOCK,"+>>${ESTM_LOGFILE_NAME}.lock");
	}
	flock(ESTM_LOGFILE_LOCK,${LOCK_EX});
	seek(ESTM_LOGFILE_LOCK,0,2);
	if(! -f ${ESTM_LOGFILE_NAME}){
		open(ESTM_LOGFILE_FH,"+>>${ESTM_LOGFILE_NAME}");
		chmod(0666,${ESTM_LOGFILE_NAME});
	}else{
		open(ESTM_LOGFILE_FH,"+>>${ESTM_LOGFILE_NAME}");
	}
	if(-s ESTM_LOGFILE_FH > ${ESTM_LOGFILE_MAX_BYTES} and ${level_order} eq "1"){
		if(-f "${ESTM_LOGFILE_NAME}O.8"){
			if(!rename("${ESTM_LOGFILE_NAME}O.8","${ESTM_LOGFILE_NAME}O.9")){
				system("mv '${ESTM_LOGFILE_NAME}O.8' '${ESTM_LOGFILE_NAME}O.9'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.7"){
			if(!rename("${ESTM_LOGFILE_NAME}O.7","${ESTM_LOGFILE_NAME}O.8")){
				system("mv '${ESTM_LOGFILE_NAME}O.7' '${ESTM_LOGFILE_NAME}O.8'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.6"){
			if(!rename("${ESTM_LOGFILE_NAME}O.6","${ESTM_LOGFILE_NAME}O.7")){
				system("mv '${ESTM_LOGFILE_NAME}O.6' '${ESTM_LOGFILE_NAME}O.7'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.5"){
			if(!rename("${ESTM_LOGFILE_NAME}O.5","${ESTM_LOGFILE_NAME}O.6")){
				system("mv '${ESTM_LOGFILE_NAME}O.5' '${ESTM_LOGFILE_NAME}O.6'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.4"){
			if(!rename("${ESTM_LOGFILE_NAME}O.4","${ESTM_LOGFILE_NAME}O.5")){
				system("mv '${ESTM_LOGFILE_NAME}O.4' '${ESTM_LOGFILE_NAME}O.5'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.3"){
			if(!rename("${ESTM_LOGFILE_NAME}O.3","${ESTM_LOGFILE_NAME}O.4")){
				system("mv '${ESTM_LOGFILE_NAME}O.3' '${ESTM_LOGFILE_NAME}O.4'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.2"){
			if(!rename("${ESTM_LOGFILE_NAME}O.2","${ESTM_LOGFILE_NAME}O.3")){
				system("mv '${ESTM_LOGFILE_NAME}O.2' '${ESTM_LOGFILE_NAME}O.3'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.1"){
			if(!rename("${ESTM_LOGFILE_NAME}O.1","${ESTM_LOGFILE_NAME}O.2")){
				system("mv '${ESTM_LOGFILE_NAME}O.1' '${ESTM_LOGFILE_NAME}O.2'");
			}
		}
		if(-f "${ESTM_LOGFILE_NAME}O.0"){
			if(!rename("${ESTM_LOGFILE_NAME}O.0","${ESTM_LOGFILE_NAME}O.1")){
				system("mv '${ESTM_LOGFILE_NAME}O.0' '${ESTM_LOGFILE_NAME}O.1'");
			}
		}
		if(!rename("${ESTM_LOGFILE_NAME}","${ESTM_LOGFILE_NAME}O.0")){
			system("mv '${ESTM_LOGFILE_NAME}' '${ESTM_LOGFILE_NAME}O.0'");
		}
		open(ESTM_LOGFILE_FH,"+>>${ESTM_LOGFILE_NAME}");
		chmod(0666,${ESTM_LOGFILE_NAME});
	}
	$comment=~s/^(\d\d*)(\t)/$1 | /g;					# Sanatize the expected occurance where the $comment is a TAB delimited composit of an error number and an error message
	$comment=~s/\t/\\t/g; $comment=~s/\r/\\r/g; $comment=~s/\n/\\n/g;	# Sanitize just so the unexpected does not make the logfile look abnormal
	print ESTM_LOGFILE_FH join("\t",${timestamp},${fmt_pid},${level_order},${level_text},${request_code},${mbnum},${estmid},${comment}),"\n";
	close(ESTM_LOGFILE_FH);
	flock(ESTM_LOGFILE_LOCK,${LOCK_UN});
	close(ESTM_LOGFILE_LOCK);
}

#===============================================================================
# CONFIGURATION SETUP SUBROUTINES
#===============================================================================

sub config_debug{
	$DEBUG__LOG_CUPRODIGY_IO__FLAG=0;	# Write all CUProdigy XML data to a log file.
	$DEBUG__INQ_MINIMUM_DATE__FLAG=0;	# Enforce an Inquiry date minimum value
	$DEBUG__INQ_MINIMUM_DATE__VALUE="YYYYMMDD";	# Inquiry date minimum value
}

sub config_xml{
	&xml_config();
}

sub config_cuprodigy_interface{
	# MARK -- Clean-up this configuration routine for CUProdigy (!ShareTec)
	$CONF__CUPRODIGY_SERVER__TELNET_IPADDR="";
	$CONF__CUPRODIGY_SERVER__TELNET_PORT="";
	$CONF__CUPRODIGY_SERVER__PROTOCOL="";       # "HTTP" (send an http "post" of SOAP wrapped "<request>...</request>") or "SOCKET" (just XML "<request>...</request>")
	$CONF__CUPRODIGY_AUTHENTICATION__VENDORNUMBER="";
	$CONF__CUPRODIGY_AUTHENTICATION__VENDORPASSWORD="";
	$CONF__CUPRODIGY_SERVER__TELNET_CONNECTIONS_SHORT_LIVED=0;
	$CONF__CUPRODIGY_SERVER__TELNET_CONNECTIONS_QUIET=0;
	$CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD="";
	$CTRL__CUPRODIGY_SERVER__TELNET_TIMEOUT=50;
	$CTRL__CUPRODIGY_SERVER__TELNET_EOL="\n";
	$CTRL__CUPRODIGY_SERVER__DISCONNECT_SECONDS__LIFECYCLE=120;
	$CTRL__CUPRODIGY_SERVER__DISCONNECT_SECONDS__INACTIVITY=20;
	$CTRL__CUPRODIGY_SERVER__DISCONNECT_SECONDS__LIFECYCLE="";
	$CTRL__CUPRODIGY_SERVER__DISCONNECT_SECONDS__INACTIVITY=20;
	$CTRL__CUPRODIGY_SERVER__POST_REQUEST_PARALLEL_MAX=0;
	$CTRL__CUPRODIGY_SERVER__CHARACTERSET__POST_HEADER="utf-8";	# Common settings: iso-8859-1, iso-latin-1, us-ascii, utf-8
	$CTRL__CUPRODIGY_SERVER__CHARACTERSET__XML="utf-8";		# Common settings: iso-8859-1, iso-latin-1, us-ascii, utf-8
	$CTRL__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__TEXT="timed out waiting for response to be posted";
	$CTRL__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__HINT='the CUProdigy API/Core needs to have its "Web Service Configuration Timeout" reconfigured to a higher value.';
	$CTRL__CMD_NET_TIMEOUT_SECONDS=20;	# Related to the maximum seconds that DMS/HomeCU will wait for a response.
	$CTRL__XML_RESPONSE_VERIFICATION__ECHO_REQUEST_IN_RESPONSE_FROM_CUPRODIGY=0;
	$CTRL__XML_RESPONSE_VERIFICATION__CHECK_REQUESTID_FROM_CUPRODIGY=0;
	$CTRL__XML_RESPONSE_VERIFICATION__USE_ROLLING_SESSIONID=1;
	$CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL=1;
	$CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__INQ_INITIAL_PASSWORD=1;
	$CONF__MEMBER_IDENTITY_CONFIRMATION__USE_METHOD__TRN_MA_QUESTIONS=0;
	$CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__VALIDATE_PASSWORD=0;
	$CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__GET_MEMBER_AUTO_ENROLL_INFO=1;
	$CTRL__BALANCE_ONLY_NO_HISTORY=0;
	$CTRL__RECHECK_BALANCES_AFTER_HISTORY=1;
	$CTRL__HISTORY_DAYS_FUTURE=10;
	$CTRL__HISTORY_SORTKEY_BY_XML_ORDER=0;
	$CTRL__HISTORY_DATE_INCLUDES_TIME=0;
	$CTRL__HISTORY_AMOUNTS_ARE_UNSIGNED_DP=0;
	$CTRL__HISTORY_AMOUNTS_ARE_UNSIGNED_LN=0;
	$CTRL__HISTORY_AMOUNTS_ARE_UNSIGNED_LN__CUDP_CORE_DEBIT_QUIRK=0;
	$CTRL__HISTORY_AMOUNTS_ARE_UNSIGNED_CC=0;
	$CTRL__HISTORY_AMOUNTS_ARE_UNSIGNED_CC__CUDP_CORE_DEBIT_QUIRK=0;
	$CONF__HISTORY_TRACENUMBERS_RECALCULATE_TO_BACKWARD_COMPATIBLE=0;
	$CONF__HISTORY_TRACENUMBERS_RECALCULATE_LOG_WARNINGS=1;
	$CONF__HISTORY_TRACENUMBERS_RECALCULATE_MAX_YYYYMMDD="99991231";
	$CONF__TRN__MUTATE_TRASFER_MEMO_TO_LIKE_CUPRODIGY_INCLUDE_OF_SRC_AND_DST=1;
	$CTRL__HOLDS__GENERATED_TRACENUMBER_COULD_BE_TOO_LONG=1;
	$CTRL__HOLDS__INCLUDE_PLEDGES=1;
	$CTRL__HOLDS__INCLUDE_ACH_CREDITS=1;
	$CTRL__HOLDS__INCLUDE_PENDING_CREDITS=1;
	$CTRL__HOLDS__ACH_CREDITS__INCLUDES_DEBITS_WITHOUT_SIGNED_AMOUNT=1;
	$CTRL__HOLDS__ACH_CREDITS__DP_ENCODE_ACH_CREDIT_AS_HOMECU_MODE_PENDING=0;
	$CTRL__HOLDS__ACH_CREDITS__DP_ENCODE_ACH_DEBIT_AS_HOMECU_MODE_PENDING=0;
	$CTRL__HOLDS__ACH_CREDITS__LN_ENCODE_ACH_CREDIT_AS_HOMECU_MODE_PENDING=0;
	$CTRL__HOLDS__ACH_CREDITS__LN_ENCODE_ACH_DEBIT_AS_HOMECU_MODE_PENDING=0;
	$CTRL__HOLDS__PENDING_CREDITS__INCLUDES_DEBITS_WITHOUT_SIGNED_AMOUNT=1;
	$CTRL__HOLDS__PLEDGE__FAKE_END_YYYYMMDD_VALUE="99991231";
	$CTRL__HOLDS__ACH_CREDITS__FAKE_BEGIN_YYYYMMDD_VALUE="today";	# "99991231";
	$CTRL__HOLDS__PENDING_CREDITS__FAKE_END_YYYYMMDD_VALUE="99991231";
	$CTRL__CUPRODIGY_GLITCH__HOLDS__INCLUDES_OTHER_MEMBERS_PENDINGS_FOR_CROSS_ACCOUNT_TRANSFERS=1;
	$CTRL__RATE_MULTIPLIER_DP=100;
	$CTRL__RATE_MULTIPLIER_LN=100;
	$CTRL__RATE_MULTIPLIER_CC=100;
	$CTRL__DESCRIP_BLANK{"reg"}=":SHARE:";
	$CTRL__DESCRIP_BLANK{"sd"}=":DRAFT:";
	$CTRL__DESCRIP_BLANK{"cd"}=":CERTIFICATE:";
	$CTRL__DESCRIP_BLANK{"ira"}=":IRA:";
	$CTRL__DESCRIP_BLANK{"irac"}=":IRA CERTIFICATE:";
	$CTRL__DESCRIP_BLANK{"conv"}=":LOAN:";
	$CTRL__DESCRIP_BLANK{"mort"}=":MORTGAGE:";
	$CTRL__DESCRIP_BLANK{"cc"}=":CREDIT CARD:";
	$CTRL__WHEN_DMS_REQUEST_EXCEED_CUPRODIGY_MAX_HISTORY_DAYS="19000101";
	$CTRL__CUPRODIGY_QUIRK__BAD_CC_PYTDINT=1;
	$CTRL__CUPRODIGY_QUIRK__BAD_MICR_VALUES=0;
	$CONF__INQ__BALANCE_ATTRIBUTES=0;
	$CONF__XXX__RESPONSE_NOTES__FORCE_TAGS=1;
	$CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER="-";
	$CONF__INQ__RESPONSE_NOTES__INCLUDE=0;
	$CONF__XAC__RESPONSE_NOTES__INCLUDE=0;
	$CONF__MIR__RESPONSE_NOTES__INCLUDE=0;
	$CONF__MIR_REQUEST_INCLUDE_DEBUGGING=1;
	$CONF__MIR_DEFAULT_COUNTRY_CODE="";
	$CONF__MIR__MEMBERTYPE__INCLUDE=0;
	%CTRL__MIR__MEMBERTYPE__CUPRODIGY_REMAP=("","P","Personal","P","Organization","B","Trust","T");
	$CONF__MIR__FAKE_DATA_FOR_TESTING=0;
	$CONF__ETOC__FAKE_DATA_FOR_TESTING=0;
	$CONF__ESTM__FAKE_DATA_FOR_TESTING=0;
	$CONF__PLASTIC_CARD__USE=0;
	%CTRL__PLASTIC_CARD__CODE__KNOWN_VALUES=(
		# Values as per 2022-02-24 email from Jeremy Smith (CUProdigy), that Jeremy referred to as "Reject Codes"
		# Code and composit of Result;Capture;Meaning
		"00","00;N;Good Card",
		"07","AL;Y;Pick-up, Special Conditions",
		"34","AE;Y;Suspected Fraud",
		"36","AK;Y;Restricted Card",
		"41","AD;Y;Lost Card",
		"43","AD;Y;Stolen Card",
		"59","NE;N;Suspected Fraud",
		"62","NK;N;Restricted Card",
		"67","AL;Y;Hard Capture, Pick-up"
	);
	%CTRL__PLASTIC_CARD__CODE__ENABLED=("00",1);		# Rules as per 2022-04-14 email from Jeremy Smith (CUProdigy)
	%CTRL__PLASTIC_CARD__CODE__DISABLED=("59",1,"62",1);	# Rules as per 2022-04-14 email from Jeremy Smith (CUProdigy)
	%CONF__PLASTIC_CARD__CARD_TYPE=();			# Manual configuration required of CU's unique <cardType> values CU's preferred description (no CUProdigy API method to provides) as per 2022-04-14 email from Jeremy Smith (CUProdigy).
	$CONF__PLASTIC_CARD__SIGNATURE__CLIENTID="";		# FIS/EZCardInfo uses a 6 digit number
	$CONF__PLASTIC_CARD__SIGNATURE__CARDTYPE="P";		# FIS/EZCardInfo uses "P" or "B"
	$CONF__PLASTIC_CARD__SIGNATURE__LENGTH_RANDOM=17;	# FIS/EZCardInfo uses "17" (not "18" as specs incorrectly state)
	$CONF__XJO__USE=0;
	$CONF__XJO_OVERLOADED__EXCLUDE_HISTORY_BECAUSE_IS_TOO_SLOW=0;
	$CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES=1;	# Does nothing in CUProdigy (because methods Inquiry and AccountInquiry and AccountDetailInquiry only include requested member), but keeping it (not stripping code) for now just in case CUProdigy changes what those methods return.
	$CTRL__CUPRODIGY_HAS_CC_HIST=0;	# Only temporary CC History exists on CUProdigy; todays payments can be seen today, but are gone by tomorrow.
	$CTRL__DP_SHARE_DRAFT_POSTING_ECHECK_TRANCODES="DRWDDC";	# Alas, for CUProdigy "DRWDDC" is used for both "Withdrawal Draft Clearing" (standard S/D Clearing) and "Withdrawal Draft Clearing ACH CHECK" (alternate Check Conversion to ACH).
	$CTRL__DP_SHARE_DRAFT_POSTING_ECHECK_DESCRIPTION_CONTAINS=" ACH CHECK ";	# Alas, for CUProdigy "DRWDDC" is used for both "Withdrawal Draft Clearing" (standard S/D Clearing) and "Withdrawal Draft Clearing ACH CHECK" (alternate Check Conversion to ACH).
	$CTRL__BAL_EXCLUDE_WHEN_IS_AN_ACCTSWEEP=1;	# The standard IFX specification does not have an XML tag "<AcctSweep>"; but the CUProdigy interface uses this tag to identify balance records are not real (fake DPs that exists only for use by CC LNs).
	$CTRL__FIHEADER_SECURITY_MESSAGEDIGEST__IMPLEMENTATION="NORMAL";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"GetMemberAutoEnrollInfo","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"GetMemberAutoEnrollInfo","Invalid Member Number or Password",DMSSTATUSCODE}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"GetMemberAutoEnrollInfo","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__CUPRODIGY} method GetMemberAutoEnrollInfo is used to validate the initial password value, the cause is either that the initial password values does not match what the GetMemberAutoEnrollInfo method expects for the member, or maybe the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware), or that maybe the member does not exist";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"ValidatePassword","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"ValidatePassword","Invalid Member Number or Password",DMSSTATUSCODE}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"ValidatePassword","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__CUPRODIGY} method ValidatePassword is used to validate the initial password value, the cause is either that the initial password values does not match what the ValidatePassword method expects for the member, or maybe the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware), or that maybe the member does not exist";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"Inquiry","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"Inquiry","Invalid Member Number or Password",DMSSTATUSCODE}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"Inquiry","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__DMS} middleware does not send a member specific password, the cause is probably either that the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware) or else that the member does not exist";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"AccountInquiry","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"AccountInquiry","Invalid Member Number or Password",DMSSTATUSCODE,}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"AccountInquiry","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__DMS} middleware does not send a member specific password, the cause is probably either that the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware) or else that the member does not exist";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"AccountDetailInquiry","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"AccountDetailInquiry","Invalid Member Number or Password",DMSSTATUSCODE}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"AccountDetailInquiry","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__DMS} middleware does not send a member specific password, the cause is probably either that the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware) or else that the member does not exist";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"GetMemberRelatedAccounts","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"GetMemberRelatedAccounts","Invalid Member Number or Password",DMSSTATUSCODE}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"GetMemberRelatedAccounts","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__DMS} middleware does not send a member specific password, the cause is probably either that the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware) or else that the member does not exist";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"CrossAccountAuthority","Invalid Member Number or Password",CUPRODIGYMSG}=1;
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"CrossAccountAuthority","Invalid Member Number or Password",DMSSTATUSCODE}="001";
	$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{"CrossAccountAuthority","Invalid Member Number or Password",HINT}="since the ${CTRL__SERVER_REFERENCE__DMS} middleware does not send a member specific password, the cause is probably either that the member does exist but is not enabled for access (by the ${CTRL__SERVER_REFERENCE__DMS} middleware) or else that the member does not exist";
	$CONF__EMAILUPDATE=1;
	$CONF__EMAILUPDATE__LOG_WHEN_NO_CHANGE=1;
	$CONF__CUPRODIGY_IO_RECORDING__MAX_ARCHIVE_COPIES="";
	$CONF__SUBACCOUNT_RECAST_UNIQID__USE=0;
	$CONF__SUBACCOUNT_RECAST_UNIQID__REQUIRES_MEMBER=1;
	$CONF__SUBACCOUNT_RECAST_UNIQID__REQUIRES_CATEGORY=1;
	$CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE=0;
	$CONF__NET_TELNET__MAX_BUFFER_LENGTH=sprintf("%.0f",2*1024*1024);
	$CONF__NET_TELNET__TIMEOUT{""}=sprintf("%.0f",30-2);			# Set to 2 seconds less than the HomeCU's default apache ".mp" config "telnet_timeout" for Net::Telnet timeout configuration for HomeCU middleware to CUProdigy API
	$CONF__NET_TELNET__TIMEOUT{"new Net::Telnet"}=5;			# Should be just a few seconds rather than the longer $CONF__NET_TELNET__TIMEOUT{""} value;
	$CONF__NET_TELNET__TIMEOUT{"GetStatement"}=sprintf("%.0f",40-2);	# Set to 2 seconds less than the HomeCU's default apache ".mp" config "telnet_timeout_ESTM" for Net::Telnet timeout configuration for HomeCU middleware to CUProdigy API (the "ESTM" uses API method "GetStatement")
}

sub config_tempfiles{
	$CTRL__DMS_TMPDIR=&use_arg_extension_always("-d","${DMS_HOMEDIR}/TMP",${VAR_CUID},${VAR_EXTENSION});
	$CTRL__BUSY_BALS_LOG_MAX=20;
}

sub config_adminfiles{
	$CTRL__DMS_ADMINDIR=&use_arg_extension_always("-d","${DMS_HOMEDIR}/ADMIN",${VAR_CUID},${VAR_EXTENSION});
	if(! -d ${CTRL__DMS_ADMINDIR}){
		system("mkdir ${CTRL__DMS_ADMINDIR}");
	}
	if(! -d ${CTRL__DMS_ADMINDIR} || ! -r ${CTRL__DMS_ADMINDIR} || ! -w ${CTRL__DMS_ADMINDIR}){
		$CTRL__DMS_ADMINDIR="${DMS_HOMEDIR}";
	}
	$CONF__DMS_PERL_EXECUTABLE="${DMS_HOMEDIR}/perl";
	if(! -f ${CONF__DMS_PERL_EXECUTABLE} || ! -x ${CONF__DMS_PERL_EXECUTABLE}){
		if(-f "/usr/bin/perl" && -x "/usr/bin/perl"){
			$CONF__DMS_PERL_EXECUTABLE="/usr/bin/perl";
		}
	}
}

sub config_processcontrol{
	$CTRL__PROCESS_CONTROL__PS_SIMILAR_CMD=0;
	$CTRL__PROCESS_CONTROL__CYCLE_SECONDS=5;
	$CTRL__PROCESS_CONTROL__FILE="${CTRL__DMS_TMPDIR}/pipe_pid_usage";
	$CTRL__PROCESS_CONTROL__LOCK_FILE="${CTRL__DMS_TMPDIR}/pipe_lockfile";
}

sub config_runstoprestartcontrol{
	$CTRL__RUN_STOP_RESTART__FILE="${CTRL__DMS_TMPDIR}/run_stop_restart";
	$CTRL__RUN_STOP_RESTART__EXPIRATION_MULTIPLIER=4;
}

sub config_coredegradationcheck{
	$CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE="${CTRL__DMS_TMPDIR}/core_degradation_check";
	$CTRL__CORE_DEGRADATION_CHECK__APPEND_TO_STATUS_TEXT_FOR_099=" BECAUSE IT IS RUNNING TOO SLOWLY";
	$CTRL__CORE_DEGRADATION_CHECK__KILLED_MAX_SECONDS_FOR_FAILURE=30;
	$CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND=5;
	$CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_INQ_REQUEST=1;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_XAC_REQUEST=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_TRN_REQUEST=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_MIR_REQUEST=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_ETOC_REQUEST=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_ESTM_REQUEST=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_NEWAPP_REQUEST=0;
	$CONF__CORE_DEGRADATION_CHECK__ENFORCE_099_ON_INQAPP_REQUEST=0;
}

sub config_dms_interface{
	$CTRL__DBM_FILE__XML_DATA_BY_TAG_INDEX=1;
	$CTRL__DBM_FILE__PERL_GLITCH_IGNORES_LOCAL_SCOPING=1;	# Scoping with "local(%XML_DATA_BY_TAG_INDEX);" is ignored by DBM.
	$CTRL__STDIN_TIMEOUT_READ_SECONDS=5;
	$CTRL__LOGFILE_MAX_BYTES=20971520;
	$CTRL__MARKER__CUPRODIGY_XML_ERROR="ERROR";
	$CTRL__MARKER__CUPRODIGY_XML_WARNING="WARNING";
	$CTRL__SERVER_REFERENCE__CUPRODIGY="CUProdigy core";
	$CTRL__SERVER_REFERENCE__DMS="DMS/HomeCU internet appliance";
	$CTRL__ERROR_999_PREFIX__CUPRODIGY="CUProdigy core: ";
	$CTRL__ERROR_999_PREFIX__DMS_NORMAL="";
	$CTRL__ERROR_999_PREFIX__DMS_ABNORMAL="DMS/HomeCU internet appliance: ";
	$CTRL__ERROR_NNN_PREFIX__DMS_NORMAL="";
	$CTRL__ERROR_NNN_PREFIX__DMS_ABNORMAL="DMS/HomeCU internet appliance: ";
	$CTRL__DATE_WHEN_NOT_CLOSED="00000000";
	$CTRL__MAX_LEN_MBNUM=12;
	$CTRL__USE_READY_PROMPT_MORE_THAN_ONCE=0;
	$CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS=0;
	$CTRL__COMBINE_CUPRODIGY_ACCT_ACCTCODE_AND_ACCTSUBCODE=1;
	$CTRL__ALLOW_UNRESTRICTED_TRANSFERS_WITHOUT_XAC_RELATION=0;
	$CTRL__ALLOW_MEMBER_TO_MEMBER_TRANSFERS_WITHOUT_XAC_RELATION=0;
	$CTRL__VALIDATE_ACCOUNTS_BEFORE_SENDING_REQUEST=1;
	$CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST=1;
	$CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO="009";	# "009"/"CORE WORKING ON RETRIEVING CURRENT DATA"
	$CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES="Balance";	# Possible 5th argument on INQ request
	$CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP="Account";	# Possible 5th argument on INQ request
	$CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN="Loan";		# Possible 5th argument on INQ request
	$CONF__DMS_HOMECU_ODYSSEY_QUIRK__TRN_ES__NO_ERROR_ON_FAILURE_FOR_NO_METHOD_TO_DISABLE=1;
}

sub config_dms_values{
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__CUPRODIGY="Share,Draft,Certificate";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__DMS_OPEN="N,Y,o";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__DMS_CLOSED="n,y,o";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__CUPRODIGY="Loan";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__DMS_OPEN="L";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__DMS_CLOSED="l";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_XX__CUPRODIGY="Custom";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_XX__DMS_OPEN="?";
	$CTRL__REMAP_LIST_ACCOUNTCATEGORY_XX__DMS_CLOSED="?";
	$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY="";
	$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN="";
	$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_CLOSED="";
	$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY="";
	$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN="";
	$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED="";
	$CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_DRAFT="Draft";
	$CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES="Certificate";
	$CTRL__LIST_ACCOUNTCATEGORY_LN__CUPRODIGY_CREDITCARD="Custom";
	$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT="";
	$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES="";
	$CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD="";
	$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_DP="";
	$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_DP="";	
	$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_DP="";
	$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_DP="";
	$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_DP="";
	$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_DP="";
	$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN="";
	$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN="";
	$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN="";
	$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN="";
	$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN="";
	$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN="";
	$CONF__HIS_EXCL_LIST_ACCTTYPE_DP="";
	$CONF__HIS_EXCL_LIST_ACCTTYPE_LN="";
	$CONF__HIS__DESC_INCLUDE_TRANSACTION_CODE=0;
	$CONF__HIS__SORTKEY_INCLUDE_ROUTINGTRANSITNUMBER=1;
	$CONF__HIS__SORTKEY_INCLUDE_CHECKDIGIT=1;
	$CONF__HIS__SORTKEY__LOG_WHEN_SHORTEND=0;
	$CONF__BAL_DP__CERT_DESC__INCLUDE_APR=1;
	$CONF__BAL_DP__CERT_DESC__INCLUDE_MATURITY_DATE=1;
	$CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__APPEND=0;
	$CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__REPLACE=0;
	$CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__AUGMENT=1;
	$CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN=0;
	$CONF__BAL_CC__INCLUDE=1;
	$CONF__BAL_CC__USE_INTEREST=1;
	$CONF__BAL_CC__DESC__INCLUDE_LAST_4_DIGITS=1;
	$CONF__BAL_CC__DESC__PREFIX_TO_LAST_4_DIGITS=" ending ";	# Orginally was using the clunkier default value " -- Ending in "
	$CONF__MINDATE_VALID_CUPRODIGY_HISTORY="";	# Leave blank or set to a value formatted as YYYYMMDD.
	$CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE="";	# Leave blank or set to a value formatted as YYYYMMDD
	$CTRL__EOL_CHARS="\n";
	$CTRL__READY_PROMPT="READY${CTRL__EOL_CHARS}";
	$CTRL__EXPORT_NULL{CHARACTER}="";	# "\\N";
	$CTRL__EXPORT_NULL{DATE}="";		# "\\N";
	$CTRL__EXPORT_NULL{NUMBER}="";	# "\\N";
	$CTRL__STATUS_TEXT{"000"}="NO ERROR";
	$CTRL__STATUS_TEXT{"001"}="INVALID ACCOUNT NUMBER";
	$CTRL__STATUS_TEXT{"002"}="INVALID PASSWORD";
	$CTRL__STATUS_TEXT{"003"}="ACCOUNT CLOSED";
	$CTRL__STATUS_TEXT{"009"}="CORE WORKING ON RETRIEVING CURRENT DATA";
	$CTRL__STATUS_TEXT{"012"}="STATEMENT NOT FOUND";
	$CTRL__STATUS_TEXT{"099"}="SYSTEM TEMPORARILY UNAVAILABLE";
	$CTRL__STATUS_DONT_SEND{"INQUIRY","000"}=1;
	$CTRL__HISTORY_DAYS_DP=94;
	$CTRL__HISTORY_DAYS_LN=187;
	$CTRL__BAL_CLOSED_DAYS_DP="94";
	$CTRL__BAL_CLOSED_DAYS_LN="94";
	$CTRL__SHORTEN_CC_TO_LAST_4_DIGITS=0;
	$CTRL__LN_CREDIT_BUREAU_PURP_CODE="00";
	$CTRL__LN_CREDIT_BUREAU_PURP_CODE_3RD_PARTY="XX";	# 2017-08-25 -- An undocument HomeCU usage that I heard about recently for 3rd Party mortgage loans.
	$CTRL__CC_CREDIT_BUREAU_PURP_CODE="18";
	$CTRL__CHILD_OF_INETD=1;
	$CTRL__LIFE_CYCLE_MAX_REQUESTS=500;
	$CTRL__LIFE_CYCLE_MAX_SECONDS=28800;
	$CTRL__DP_BALANCE_INCLUDE_XFER_AUTH=0;
	$CTRL__LN_BALANCE_INCLUDE_XFER_AUTH=0;
	$CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW=0;
	$CTRL__LOANAPP_FAILURE_OF_NEWAPP_USE_LOANAPPID="-1";	# 2018-09-11 -- What Mark (HomeCU) says should be returned (was not documented anywhere).
	$CTRL__GL__ACH_DESCRIPTION__USE=1;
	$CTRL__GL__ACH_DESCRIPTION__DELIMITER=";";
	&textfilter_mode("SANE","POSTGRES");	# Do not need "HTML" mode since data is coming in from CUProdigy as XML (which will already by HTML safe).
}

sub config_cuprodigy_loan_payoff{
	$CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT="REJECT";
}

sub config_load_overrides{
   local($prefix)="CONFIG WARNING: ";
   local($configfile)=&use_arg_extension_if_exists("-f","${DMS_HOMEDIR}/dmshomecucuprodigy.cfg",${VAR_CUID},${VAR_EXTENSION});
	require "${configfile}" if -f "${configfile}" && -r "${configfile}";
	# Want to intentionally log the state of $CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS so that it is possible for programmers to positively confirm that it is enabled in situations when testing must be done against the CU's live data.
	if(${CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
		&logfile(${prefix}."The \$CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS is enabled (by configuration file).\n");
	}
	if(${ARG_TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
		$CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS=1;
		&logfile(${prefix}."The \$CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS is enabled (by command line argument '--test-mode--do-not-submit-transactions').\n");
	}
	if(!${CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS}){
		&logfile(${prefix}."The \$CTRL__TEST_MODE__DO_NOT_SUBMIT_TRANSACTIONS is disabled (not enabled in configuration file nor by command line argument '--test-mode--do-not-submit-transactions')).\n");
	}
}

sub config_sanitize_settings{
	return("");	# MARK -- 2008-02-04 -- Still returning early rather than confirming these configuration variables.
	&logfile_and_die("Need IP Address value; set \$CONF__CUPRODIGY_SERVER__TELNET_IPADDR in DMS/HomeCU config file.\n") if ${CONF__CUPRODIGY_SERVER__TELNET_IPADDR} eq "";
	&logfile_and_die("Need Port value; set \$CONF__CUPRODIGY_SERVER__TELNET_PORT in DMS/HomeCU config file.\n") if ${CONF__CUPRODIGY_SERVER__TELNET_PORT} eq "";
	&logfile_and_die("Need valid setting for \$CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT: ACCEPT, ADJUST, or REJECT\n") if !list_found(${CONF__LOAN_PAYOFF_EXCEEDED__ACCEPT_ADJUST_REJECT},"ACCEPT,ADJUST,REJECT");
	&logfile("".${CTRL__SERVER_REFERENCE__CUPRODIGY}." access: ${CONF__CUPRODIGY_SERVER__TELNET_IPADDR}:${CONF__CUPRODIGY_SERVER__TELNET_PORT}\n");
  &logfile_and_die("Need valid setting for \$CONF__MINDATE_VALID_CUPRODIGY_HISTORY; must be either blank or an 8 digit value formatted as YYYYMMDD.\n") if ${CONF__MINDATE_VALID_CUPRODIGY_HISTORY} ne "" and $CONF__MINDATE_VALID_CUPRODIGY_HISTORY !~ /^\d{8}$/;
  &logfile_and_die("Need valid setting for \$CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE; must be either blank or an 8 digit value formatted as YYYYMMDD.\n") if ${CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE} ne "" and $CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE !~ /^\d{8}$/;
	&logfile("No pre-history detail will be included because the setting of \$CONF__MINDATE_VALID_CUPRODIGY_HISTORY is greater than \$CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE.\n") if ${CONF__MINDATE_VALID_CUPRODIGY_HISTORY} ne "" and ${CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE} ne "" and ${CONF__MINDATE_VALID_CUPRODIGY_HISTORY} gt ${CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE};
	if(1){
		# CUProdigy has mixed case account "Category"
		$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_DP=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_DP=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_DP=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_DP=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_DP=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_DP=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN=~tr/a-z/A-Z/;
		$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN=~tr/a-z/A-Z/;
	}
	if(1){
		# CUProdigy has upper-case account "Type"
		$CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__CUPRODIGY=~tr/a-z/A-Z/;
		$CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__CUPRODIGY=~tr/a-z/A-Z/;
		$CTRL__REMAP_LIST_ACCOUNTCATEGORY_XX__CUPRODIGY=~tr/a-z/A-Z/;
		$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY=~tr/a-z/A-Z/;
		$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY=~tr/a-z/A-Z/;
		$CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_DRAFT=~tr/a-z/A-Z/;
		$CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES=~tr/a-z/A-Z/;
		$CTRL__LIST_ACCOUNTCATEGORY_LN__CUPRODIGY_CREDITCARD=~tr/a-z/A-Z/;
		$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT=~tr/a-z/A-Z/;
		$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES=~tr/a-z/A-Z/;
		$CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD=~tr/a-z/A-Z/;
	}
}

sub known_limitations{
   local($prefix)="KNOWN LIMITATION: ";
   local($source)="${CTRL__SERVER_REFERENCE__CUPRODIGY}: ";
	&logfile(${prefix}.${source}."Still unknown as to if when an account is closed (close, mature, payoff, etc) if it immediately disappears or hangs around for a specific period of time or hangs around forever.\n");
}

sub config_warnings{
   local($prefix)="CONFIG WARNING: ";
   local($source)="${CTRL__SERVER_REFERENCE__CUPRODIGY}: ";
   local($text);
	if(${CONF__XJO__USE}){
		&logfile(${prefix}."The \$CONF__XJO__USE is enabled.\n");
	}else{
		&logfile(${prefix}."The \$CONF__XJO__USE is disabled.\n");
	}
	if(${CONF__XJO__USE} and !${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
		&logfile(${prefix}."It is abnormal (but valid) to have \$CONF__XJO__USE enabled while \$CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES is disabled; this will result in all XJO/Overloaded accounts being discarded unless something is done with \@XML_MB_XJO, but that could also be the intended (needed) affect.\n");
	}
	if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
		&logfile(${prefix}."Since \$CONF__XJO__USE and \$CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES are enabled, it is possible for a member to transfer between two XJO/Overloaded accounts; so for the ${CTRL__SERVER_REFERENCE__CUPRODIGY} to properly understand and enforce account authorizations, the ${CTRL__SERVER_REFERENCE__DMS} must include the 'tauth' value with the 'TRN' requests.\n");
	}
	if($CUSTOM{"custom_password.pi"}>0){
		&logfile(${prefix}."The \"CUSTOM/custom_password.pi\" is currently defined, therefore the \"CUSTOM/custom_password.pi\" will be used to verify the INQ initial password value (rather than the default of using ${CTRL__SERVER_REFERENCE__CUPRODIGY} GetMemberAutoEnrollInfo or ValidatePassword methods).\n");
	}else{
		&logfile(${prefix}."No \"CUSTOM/custom_password.pi\" is currently defined, therefore the ${CTRL__SERVER_REFERENCE__CUPRODIGY} GetMemberAutoEnrollInfo or ValidatePassword method will be used to verify the INQ initial password value.\n");
	}
}

sub configure_account_by_cuprodigy_type{
   local($class_dplncc,$core_balance_type,$core_account_group,$core_account_type,$core_allow_xfer_from,$core_allow_xfer_to,$normalized_type,$dms_depositloantype_open,$dms_depositloantype_closed)=@_;
	# Enumerated values for $class_dplncc: DP, LN, CC
	# Suggested values for DP $core_account_group: reg, club, sd, mm, cd, ira, med
	# Suggested values for LN $core_account_group: conv, mort, cc
	# Suggested values for DP $core_account_type: reg, sd, cd
	# Suggested values for LN $core_account_type: cel, oel, visa
	# Enumerated values for $core_allow_xfer_from: Y, N
	# Enumerated values for $core_allow_xfer_to: Y, N
	# Enumerated values for DP $normalized_type: reg, sd, cd
	# Enumerated values for LN $normalized_type: cel, oel, cc
	# Suggested values for DP $dms_depositloantype_open list: N, Y, O, n, y, o
	# Suggested values for LN $dms_depositloantype_open list: L, l
	# Suggested values for DP $dms_depositloantype_open list: n, y, o
	# Suggested values for LN $dms_depositloantype_open list: l
   local($CONF__SOFTWARE_CLASS__DP_NORMALIZED_TYPE__DRAFT)=join(",","sd");
   local($CONF__SOFTWARE_CLASS__DP_NORMALIZED_TYPE__SHARE)=join(",","reg");
   local($CONF__SOFTWARE_CLASS__DP_NORMALIZED_TYPE__CERTIFICATE)=join(",","cd");
   local($CONF__SOFTWARE_CLASS__LN_NORMALIZED_TYPE__CREDITCARD)=join(",","cc");
# usage has been deprecated #   local($[)=0;
	if($_[0] =~ /^init$/i){ &configure_account_by_cuprodigy_type__init(); return(1); }
	if     (join("",@_) =~ /\r/){
		&logfile("configure_account_by_cuprodigy_type(): Mapping may not contain the special character '\\r': "."'".join("','",@_)."'"."\n");
	}elsif(join("",@_) =~ /\n/){
		&logfile("configure_account_by_cuprodigy_type(): Mapping may not contain the special character '\\n': "."'".join("','",@_)."'"."\n");
	}elsif(join("",@_) =~ /\t/){
		&logfile("configure_account_by_cuprodigy_type(): Mapping may not contain the special character '\\t': "."'".join("','",@_)."'"."\n");
	}elsif(join("",@_) =~ /,/){
		&logfile("configure_account_by_cuprodigy_type(): Mapping may not contain the reserved character ',': "."'".join("','",@_)."'"."\n");
	}elsif($configure_account_by_cuprodigy_type{${class_dplncc},${core_balance_type}} ne ""){
		&logfile("configure_account_by_cuprodigy_type(): Mapping may not repeat key values: "."'".join("','",@_)."'"."\n");
	}else{
		if($TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{""} eq ""){ $TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{""}="O"; }
		if($TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{""} eq ""){ $TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{""}="O"; }
		if    ($class_dplncc =~ /^DP$/i){
			$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{${core_balance_type}}=${dms_depositloantype_open};
			if(index(",${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY}",",${core_balance_type},") < 0){
				$configure_account_by_cuprodigy_type{${class_dplncc},${core_balance_type}}=1;
				$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY} eq "" ? "" : "," ) . ${core_balance_type};
				$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN} eq "" ? "" : "," ) . ${dms_depositloantype_open};
				$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_CLOSED.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_CLOSED} eq "" ? "" : "," ) . ${dms_depositloantype_closed};
				if($core_allow_xfer_from =~ /^0$|^N$|^NO$/i){
					$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_DP.=( ${CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_DP} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_DP.=( ${CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_DP} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_DP.=( ${CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_DP} eq "" ? "" : "," ) . ${core_balance_type};
				}
				if($core_allow_xfer_to =~ /^0$|^N$|^NO$/i){
					$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_DP.=( ${CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_DP} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_DP.=( ${CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_DP} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_DP.=( ${CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_DP} eq "" ? "" : "," ) . ${core_balance_type};
				}
				if(index(",${CONF__SOFTWARE_CLASS__DP_NORMALIZED_TYPE__DRAFT},",",${normalized_type},") >= 0){
					$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT.=( ${CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT} eq "" ? "" : "," ) . ${core_balance_type};
				}
				if(index(",${CONF__SOFTWARE_CLASS__DP_NORMALIZED_TYPE__CERTIFICATE},",",${normalized_type},") >= 0){
					$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES.=( ${CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES} eq "" ? "" : "," ) . ${core_balance_type};
				}
			}
		}elsif($class_dplncc =~ /^LN$/i){
			$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{${core_balance_type}}=${dms_depositloantype_open};
			if(index(",${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY}",",${core_balance_type},") < 0){
				$configure_account_by_cuprodigy_type{${class_dplncc},${core_balance_type}}=1;
				if($core_account_group =~ /^cc$|^cc-/i){
					if    ($core_account_group =~ /^cc-loan$/i){
						$configure_account_by_cuprodigy_type__creditcard_behavior{${core_balance_type}}="loan";
					}elsif($core_account_group =~ /^cc-offbook$|cc-offbook-nonsweep$|cc-offbook-non-sweep$/i){
						$configure_account_by_cuprodigy_type__creditcard_behavior{${core_balance_type}}="offbook-nonsweep";
					}elsif($core_account_group =~ /^cc-offbook-sweep$/i){
						$configure_account_by_cuprodigy_type__creditcard_behavior{${core_balance_type}}="offbook-sweep";
					}elsif($core_account_group =~ /^cc-inhouse$/i){
						$configure_account_by_cuprodigy_type__creditcard_behavior{${core_balance_type}}="inhouse";
						($CONF__HIS_EXCL_LIST_ACCTTYPE_LN.=",${core_balance_type}")=~s/^,//;	# The CUProdigy API method Inquiry generates an XML branch <response><history><historyRecord> that is missing important (critical) values when the sub-account is cast as "cc-inhouse".
					}else{
						$configure_account_by_cuprodigy_type__creditcard_behavior{${core_balance_type}}="loan";
					}
				}
				if    ($core_account_group =~ /^[a-z0-9][a-z0-9]*-3rdparty$|^[a-z0-9][a-z0-9]*-3rdparty-nonsweep$|^[a-z0-9][a-z0-9]*-3rdparty-non-sweep$/i){
					$configure_account_by_cuprodigy_type__loan_behavior{${core_balance_type}}="3rdparty-nonsweep";
				}elsif($core_account_group =~ /^[a-z0-9][a-z0-9]*-3rdparty-sweep$/i){
					$configure_account_by_cuprodigy_type__loan_behavior{${core_balance_type}}="3rdparty-sweep";
				}
				$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY} eq "" ? "" : "," ) . ${core_balance_type};
				$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN} eq "" ? "" : "," ) . ${dms_depositloantype_open};
				$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED} eq "" ? "" : "," ) . ${dms_depositloantype_closed};
				if($core_allow_xfer_from =~ /^0$|^N$|^NO$/i){
					$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
				}
				if($core_allow_xfer_to =~ /^0$|^N$|^NO$/i){
					$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
				}
			}
		}elsif($class_dplncc =~ /^CC$/i){
			$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{${core_balance_type}}=${dms_depositloantype_open};
			if(index(",${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY}",",${core_balance_type},") < 0){
				$configure_account_by_cuprodigy_type{${class_dplncc},${core_balance_type}}=1;
				$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY} eq "" ? "" : "," ) . ${core_balance_type};
				$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN} eq "" ? "" : "," ) . ${dms_depositloantype_open};
				$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED.=( ${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED} eq "" ? "" : "," ) . ${dms_depositloantype_closed};
				if($core_allow_xfer_from =~ /^0$|^N$|^NO$/i){
					$CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_GEN_FROM_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_SELF_FROM_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_XAC_FROM_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
				}
				if($core_allow_xfer_to =~ /^0$|^N$|^NO$/i){
					$CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_GEN_TO_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_SELF_TO_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
					$CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN.=( ${CONF__XFER_EXCL_LIST_XAC_TO_ACCTTYPE_LN} eq "" ? "" : "," ) . ${core_balance_type};
				}
				if(index(",${CONF__SOFTWARE_CLASS__LN_NORMALIZED_TYPE__CREDITCARD},",",${normalized_type},") >= 0){
					$CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD.=( ${CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD} eq "" ? "" : "," ) . ${core_balance_type};
				}
			}
		}else{
			&logfile("configure_account_by_cuprodigy_type(): Unmapped \$class_dplncc value: ${class_dplncc}\n");
		}
	}
}

sub configure_account_by_cuprodigy_type__generate_default{
   local($class_dplncc,$core_balance_type,$core_account_group,$core_account_type,$core_allow_xfer_from,$core_allow_xfer_to,$normalized_type,$dms_depositloantype_open,$dms_depositloantype_closed)=@_;
   local($generate_default)=0;
	if(0){
		if    ($class_dplncc =~ /^DP$/i){
				if(index(",${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY}",",${core_balance_type},") < 0){
					$generate_default=1;
				}
		}elsif($class_dplncc =~ /^LN$/i){
				if(index(",${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY}",",${core_balance_type},") < 0){
					$generate_default=1;
				}
		}elsif($class_dplncc =~ /^CC$/i){
				if(index(",${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY}",",${core_balance_type},") < 0){
					$generate_default=1;
				}
		}
	}else{
		$generate_default=1;	# The configure_account_by_cuprodigy_type__generate_default__wrapper() already verified need to run configure_account_by_cuprodigy_type__generate_default()
	}
	if(${generate_default}){
		&logfile('configure_account_by_cuprodigy_type__generate_default(): adding default for: configure_account_by_cuprodigy_type("',join('","',@_).'")',"\n");
		$class_dplncc=~tr/a-z/A-Z/;
		$CTRL__CONFIGURE_ACCOUNT_BY_CUPRODIGY_TYPE__GENERATE_DEFAULT{${class_dplncc},${core_balance_type}}=join("\t",@_);
		&configure_account_by_cuprodigy_type(@_);
	}
}

sub configure_account_by_cuprodigy_type__generate_default__wrapper{
   local($DPLNCC,$cuprodigy_accountType,$cuprodigy_accountCategory,$cuprodigy_creditLimit)=@_;
   local($DPLN_not_CC);
	($DPLN_not_CC=${DPLNCC})=~s/^CC$/LN/i;
	if($configure_account_by_cuprodigy_type{${DPLN_not_CC},${cuprodigy_accountType}} eq ""){
		if($DPLNCC =~ /^DP$/i){
			if    (${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_DRAFT} eq ${cuprodigy_accountCategory}){
				&configure_account_by_cuprodigy_type__generate_default("DP",${cuprodigy_accountType},"sd","sd","yes","yes","sd","Y","y");		# The CUProdigy API response <transactionsRestricted> is expected to override (disable) this default enabled $core_allow_xfer_from and $core_allow_xfer_to
			}elsif(${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES} eq ${cuprodigy_accountCategory}){
				&configure_account_by_cuprodigy_type__generate_default("DP",${cuprodigy_accountType},"cd","cd","no","no","cd","o","o");			# The CUProdigy API response <transactionsRestricted> is expected to not override (enable) this default disabled $core_allow_xfer_from and $core_allow_xfer_to
			}else{
				&configure_account_by_cuprodigy_type__generate_default("DP",${cuprodigy_accountType},"reg","reg","yes","yes","reg","N","n");		# The CUProdigy API response <transactionsRestricted> is expected to override (disable) this default enabled $core_allow_xfer_from and $core_allow_xfer_to
			}
		}elsif($DPLNCC =~ /^LN$/i){
			if    (${CTRL__LIST_ACCOUNTCATEGORY_LN__CUPRODIGY_CREDITCARD} eq ${cuprodigy_accountCategory}){
				&configure_account_by_cuprodigy_type__generate_default("LN",${cuprodigy_accountType},"cc|mort|??","oel","yes","yes","cel|oel","L","l");	# The CUProdigy API response <transactionsRestricted> is expected to override (disable) this default enabled $core_allow_xfer_from and $core_allow_xfer_to ;;; Can not tell "cc" from "mort" because in CUProdigy API both "cc" and "mort" are coded as <accountCategory> value "Custom"
			}elsif(sprintf("%.2f",${cuprodigy_creditLimit}) > 0.00){
				&configure_account_by_cuprodigy_type__generate_default("LN",${cuprodigy_accountType},"conv","oel","yes","yes","oel","L","l");		# The CUProdigy API response <transactionsRestricted> is expected to override (disable) this default enabled $core_allow_xfer_from and $core_allow_xfer_to
			}else{
				&configure_account_by_cuprodigy_type__generate_default("LN",${cuprodigy_accountType},"conv","cel|oel","yes","yes","cel|oel","L","l");	# The CUProdigy API response <transactionsRestricted> is expected to override (disable) this default enabled $core_allow_xfer_from and $core_allow_xfer_to ;;; Can not tell "cel" from "oel" because in CUProdigy API an "oel" might have <creditLimit> value "0.00"
			}
		}elsif($DPLNCC =~ /^CC$/i){
			&configure_account_by_cuprodigy_type__generate_default("LN",${cuprodigy_accountType},"cc","oel","yes","yes","oel","L","l");			# The CUProdigy API response <transactionsRestricted> is expected to override (disable) this default enabled $core_allow_xfer_from and $core_allow_xfer_to
		}
	}
}

sub configure_account_by_cuprodigy_type__init{
	undef %CTRL__CONFIGURE_ACCOUNT_BY_CUPRODIGY_TYPE__GENERATE_DEFAULT;
	undef $CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT;
	undef $CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES;
	undef $CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD;
	undef $CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY;
	undef $CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_CLOSED;
	undef $CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN;
	undef $CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY;
	undef $CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED;
	undef $CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN;
	undef %TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE;
	undef %TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE;
	undef %TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE;
}

sub configure_account_by_cuprodigy_type__dump{
   local(*OUTPUT)=@_;
	print OUTPUT '$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT="',$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_DRAFT,'"',"\n";
	print OUTPUT '$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES="',$CTRL__LIST_ACCOUNTTYPE_DP__CUPRODIGY_CERTIFICATES,'"',"\n";
	print OUTPUT '$CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD="',$CTRL__LIST_ACCOUNTTYPE_LN__CUPRODIGY_CREDITCARD,'"',"\n";
	print OUTPUT '$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY="',$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY,'"',"\n";
	print OUTPUT '$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_CLOSED="',$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_CLOSED,'"',"\n";
	print OUTPUT '$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN="',$CTRL__REMAP_LIST_ACCOUNTTYPE_DP__DMS_OPEN,'"',"\n";
	print OUTPUT '$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY="',$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY,'"',"\n";
	print OUTPUT '$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED="',$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_CLOSED,'"',"\n";
	print OUTPUT '$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN="',$CTRL__REMAP_LIST_ACCOUNTTYPE_LN__DMS_OPEN,'"',"\n";
	foreach $key (sort(keys(%TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE))){
		print OUTPUT '$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{'.${key}.'}="',$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{${key}},'"',"\n";
	}
	foreach $key (sort(keys(%TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE))){
		print OUTPUT '$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{'.${key}.'}="',$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{${key}},'"',"\n";
	}
	foreach $key (sort(keys(%TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE))){
		print OUTPUT '$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{'.${key}.'}="',$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{${key}},'"',"\n";
	}
}

sub configure_account_by_cuprodigy_type__usage_history__load{
   local(*FH);
   local(@f);
   local($file_curr)="${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION/usage_history.${SCRIPT_SERVICE_ID}";
   local($file_next)="${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION/usage_history.${SCRIPT_SERVICE_ID}.wip";
	system("mkdir '${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION' 2> /dev/null") if ! -d "${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION";
	undef(%CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY);
	open(FH,"<${file_curr}");
	while(defined($line=<FH>)){
		$line=~s/[\r\n][\r\n]*$//;
		@f=split(/\t/,$line,6);
		$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{$f[4],$f[5],0,"seconds"}=$f[0];
		$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{$f[4],$f[5],0,"timestamp"}=$f[1];
		$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{$f[4],$f[5],9,"seconds"}=$f[2];
		$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{$f[4],$f[5],9,"timestamp"}=$f[3];
	}
	close(FH);
}

sub configure_account_by_cuprodigy_type__usage_history__save{
   local(*FH);
   local(@f);
   local($key);
   local($class,$description);
   local($file_curr)="${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION/usage_history.${SCRIPT_SERVICE_ID}";
   local($file_next)="${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION/usage_history.${SCRIPT_SERVICE_ID}.wip";
	system("mkdir '${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION' 2> /dev/null") if ! -d "${CTRL__DMS_ADMINDIR}/CONFIGURE_ACCOUNT_BY_DESCRIPTION";
	open(FH,">${file_next}");
	foreach $key (sort(keys(%CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY))){
		@f=split(/$;/,${key});
		if($f[$#f-1] eq "0" and $f[$#f] eq "seconds"){
			pop(@f); pop(@f);
			$class=shift(@f);
			$description=join($;,@f);
			print FH join("\t",
				$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},0,"seconds"},
				$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},0,"timestamp"},
				$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},9,"seconds"},
				$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},9,"timestamp"},
				${class},
				${description}
			),"\n";
		}
	}
	close(FH);
	if((stat(${file_curr}))[7] > (stat(${file_next}))[7]){
		unlink(${file_next});
	}else{
		system("chmod 0666 '${file_next}'");
		if(1){
			rename("${file_curr}.3","${file_curr}.4") if -f "${file_curr}.3";
			rename("${file_curr}.2","${file_curr}.3") if -f "${file_curr}.2";
			rename("${file_curr}.1","${file_curr}.2") if -f "${file_curr}.1";
			rename("${file_curr}.0","${file_curr}.1") if -f "${file_curr}.0";
			rename("${file_curr}","${file_curr}.0") if -f "${file_curr}";
		}
		rename("${file_next}","${file_curr}");
	}
}

sub configure_account_by_cuprodigy_type__usage_history__used{
   local($class,$description)=@_;
   local($time,$timestamp);
   local(@f);
	$time=time();
	@f=localtime(${time});
	$timestamp=sprintf("%04.0f%02.0f%02.0f%02.0f%02.0f%02.0f",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	if($CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},0,"seconds"} eq ""){
		$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},0,"seconds"}=${time};
		$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},0,"timestamp"}=${timestamp};
	}
	$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},9,"seconds"}=${time};
	$CONFIGURE_ACCOUNT_BY_DESCRIPTION_USAGE_HISTORY{${class},${description},9,"timestamp"}=${timestamp};
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- GENERIC
#===============================================================================

sub timeseconds{ sprintf("%11d",time()); }

sub filter_user_input{
   local($line)=@_;
   local($idx0,$idx1,$idx2);
   local($firstword);
	# Strip RETURN and NEWLINE characters
	$line=~s/[\r\n][\r\n]*$//;
	# Fitler for BACKSPACE and DELETE characters
	while(index($line,"\b")>=0 || index($line,"\x7f")>=0){
		$idx1=index($line,"\b");
		$idx2=index($line,"\x7f");
		if($idx1>=0 && $idx2>=0){
			if($idx1<$idx2){
				$idx0=$idx1;
			}else{
				$idx0=$idx2;
			}
		}else{
			if($idx1>=0){
				$idx0=$idx1;
			}else{
				$idx0=$idx2;
			}
		}
		if($idx0==0){
			$line=substr($line,1);
		}else{
			$line=substr($line,0,$idx0-1).substr($line,$idx0+1);
		}
	}
	# Strip $CTRL__EOL_CHARS characters
	if($CTRL__EOL_CHARS ne "\t"){ $line=~s/\Q$CTRL__EOL_CHARS\E//g; }
	# Strip leading SPACE characters
	$line=~s/^  *//;
	# Fold the first word to Upper-Case
	($firstword=$line)=~s/[:\s].*$//;
	$firstword=~tr/a-z/A-Z/;
	substr($line,0,length(${firstword}))=${firstword};
	# Return filter result
	return($line);
}

sub zerofill{
   local($value,$length)=@_;
	($value=sprintf("%${length}.${length}s",$value))=~s/ /0/g;
	return($value);
}

sub list_numentries{
   local($list,$delimiter)=@_;
   local($rtrn)=0;
   local(@f);
	if(${delimiter} eq ""){
		$delimiter=",";
	}
	@f=split(/${delimiter}/,${list}." "); $f[$#f]=~s/ $//;
	$rtrn=sprintf("%.0f",$#f+1-$[);
	return(${rtrn});
}

sub list_entry_to_entrynum{
   local($entry,$list,$delimiter,$ignore_case)=@_;
   local($rtrn)=0;
   local(@f);
	if(${delimiter} eq ""){
		$delimiter=",";
	}
	if(${ignore_case}){
		$entry=~tr/a-z/A-Z/;
		$list=~tr/a-z/A-Z/;
	}
	if(index("${delimiter}${list}${delimiter}","${delimiter}${entry}${delimiter}") >= $[){
		@f=split(/${delimiter}/,${list}." "); $f[$#f]=~s/ $//;
		while(${rtrn} <= $#f and $f[${rtrn}] ne ${entry}){
			$rtrn=sprintf("%.0f",${rtrn}+1);
		}
		if($f[${rtrn}] eq ${entry}){
			$rtrn=sprintf("%.0f",${rtrn}+1);
		}else{
			$rtrn=0;
		}
	}
	return(${rtrn});
}

sub list_entrynum_to_entry{
   local($entrynum,$list,$delimiter)=@_;
   local(@f);
	if(${delimiter} eq ""){
		$delimiter=",";
	}
	@f=split(/${delimiter}/,${list}." "); $f[$#f]=~s/ $//;
	if($entrynum > @f){
		return(undef);
	}else{
		return($f[${entrynum}+1]);
	}
}

sub list_found{
   local($entry,$list,$delimiter,$ignore_case)=@_;
   local($rtrn)=0;
	if(${delimiter} eq ""){
		$delimiter=",";
	}
	if(${ignore_case}){
		$entry=~tr/a-z/A-Z/;
		$list=~tr/a-z/A-Z/;
	}
	if(index("${delimiter}${list}${delimiter}","${delimiter}${entry}${delimiter}") >= $[){
		$rtrn=1;
	}
	return(${rtrn});
}

sub list_remap{
   local($entry,$list_from,$list_to,$default)=@_;
   local($rtrn);
   local(@list_from,@list_to);
   local($idx);
	@list_from=split(/,/,${list_from}.",x"); pop(@list_from);
	@list_to=split(/,/,${list_to}.",x"); pop(@list_to);
	$rtrn=${default};
	for($idx=0;$idx<=$#list_from;$idx++){
		if(${entry} eq $list_from[$idx]){
			if($idx<=$#list_to){
				$rtrn=$list_to[$idx];
			}
			last;
		}
	}
	return(${rtrn});
}

sub dms_status{
   local($tag,$mbnum,$status_code,$override_text)=@_;
   local($status_text,$status_text_extra);
   local($skip_io_recording)=0;
   local($cuprodigy_response_error_composit);
   local($cuprodigy_response_error_method);
   local($cuprodigy_response_error_text);
   local($text);
   local($status_text_extra_html_safe);
   local(@f);
	$tag=~tr/a-z/A-Z/;
	if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR} and ${override_text} ne ""){
		$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=~s/[\.;]$//;
		$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG.="; ".${CTRL__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__HINT};
		$override_text.="\t".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
	}
	if(${status_code} eq ${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO} and ${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO} ne "099"){
		&logfile("${tag} Status Tag Block: ",join("\t",${mbnum},${status_code},${override_text}),"\n");
		$status_code="099";
		$skip_io_recording=1;
	}
	&cuprodigy_io_recording("STATUS",${mbnum},${tag},${mbnum},${status_code},${override_text}) if !${skip_io_recording};
	if(${status_code} eq "999" and index(${override_text},${CTRL__ERROR_999_PREFIX__CUPRODIGY}) == $[){
		$cuprodigy_response_error_composit=substr(${override_text},length(${CTRL__ERROR_999_PREFIX__CUPRODIGY}));
		$cuprodigy_response_error_composit=~s/^\s\s*//;
		$cuprodigy_response_error_composit=~s/\s\s*$//;
		if($cuprodigy_response_error_composit =~ /^Failed using method: [^:][^:]*:\s\s*/){
			$cuprodigy_response_error_composit=~s/^Failed using method: //;
			($cuprodigy_response_error_method=${cuprodigy_response_error_composit})=~s/:.*$//;
			($cuprodigy_response_error_text=${cuprodigy_response_error_composit})=~s/[^:]*:  *//;
			if($CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{${cuprodigy_response_error_method},${cuprodigy_response_error_text},DMSSTATUSCODE} ne ""){
				$status_code=$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{${cuprodigy_response_error_method},${cuprodigy_response_error_text},DMSSTATUSCODE};
				$status_text=$CTRL__STATUS_TEXT{${status_code}};
				$override_text=join("\t",${status_text},${override_text});
				if($CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{${cuprodigy_response_error_method},${cuprodigy_response_error_text},HINT} ne ""){
					$text=$CTRL__CUPRODIGY_XML_RESPONSE_ERROR_TEXT{${cuprodigy_response_error_method},${cuprodigy_response_error_text},HINT};
					substr($text,0,1)=~tr/a-z/A-Z/;
					$override_text=join("\t",${override_text},${text});
				}
				if(${GLOB__PACKET_FETCH_DEBUGGING_NOTE} ne ""){
					$override_text=join("\t",${override_text},${GLOB__PACKET_FETCH_DEBUGGING_NOTE});
					$GLOB__PACKET_FETCH_DEBUGGING_NOTE="";
				}
			}
		}
	}elsif(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR} and ${GLOB__PACKET_FETCH_DEBUGGING_NOTE} ne ""){
		$override_text=join("\t",${override_text},${GLOB__PACKET_FETCH_DEBUGGING_NOTE});
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE="";
	}
	if($CTRL__STATUS_DONT_SEND{${tag},${status_code}} == 0){
		$status_text=$CTRL__STATUS_TEXT{${status_code}};
		if($status_text eq ""){
			$status_text="Status Code '${status_code}'";
		}
		if($override_text ne ""){
			($status_text,$status_text_extra)=split(/\t/,${override_text},2);
		}
		print STDOUT "<Status>${CTRL__EOL_CHARS}";
		if(${GLOB__PACKET_FETCH_DEBUGGING_NOTE} eq ""){
			@f=split(/\t/,${status_text_extra});
			while(@f>0){
				$f[0]=~s/^ *//;
				$f[0]=~s/ *$//;
				$status_text_extra_html_safe.=&textfilter_html($f[0])."\t";
				shift(@f);
			}
			$status_text_extra_html_safe=~s/\t$//;
			if(${status_text_extra} eq ""){
				print STDOUT join("\t",${mbnum},${status_code},&textfilter_html(${status_text})),${CTRL__EOL_CHARS};
			}else{
				print STDOUT join("\t",${mbnum},${status_code},&textfilter_html(${status_text}),${status_text_extra_html_safe}),${CTRL__EOL_CHARS};
			}
		}else{
			print STDOUT join("\t",${mbnum},${status_code},&textfilter_html(${status_text}),&textfilter_html(${GLOB__PACKET_FETCH_DEBUGGING_NOTE})),${CTRL__EOL_CHARS};
		}
		print STDOUT "</Status>${CTRL__EOL_CHARS}";
		if(${GLOB__PACKET_FETCH_DEBUGGING_NOTE} eq ""){
			if(${status_text_extra} eq ""){
				&logfile("${tag} Status Tag Block: ",join("\t",${mbnum},${status_code},${status_text}),"\n");
			}else{
				&logfile("${tag} Status Tag Block: ",join("\t",${mbnum},${status_code},${status_text},${status_text_extra}),"\n");
			}
		}else{
			&logfile("${tag} Status Tag Block: ",join("\t",${mbnum},${status_code},${status_text},${GLOB__PACKET_FETCH_DEBUGGING_NOTE}),"\n");
		}
	}
	if(${status_text} eq ""){
		if(${override_text} ne ""){
			$status_text="${override_text}";
		}else{
			$status_text=$CTRL__STATUS_TEXT{${status_code}};
		}
	}
	&cuprodigy_io_recording("STATUS",${mbnum},${tag},${mbnum},${status_code},${status_text}) if !${skip_io_recording};
}

sub dms_status__was_not_used_here{	# Alas, not everything used "dms_status()"
   local($tag,$mbnum,$status_code,$override_text)=@_;
   local($status_text);
	$tag=~tr/a-z/A-Z/;
	if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR} and ${override_text} ne ""){
		$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=~s/[\.;]$//;
		$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG.="; ".${CTRL__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__HINT};
		$override_text.="\t".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
	}
	&cuprodigy_io_recording("STATUS",${mbnum},${tag},${mbnum},${status_code},${override_text});
	if(${status_text} eq ""){
		if(${override_text} ne ""){
			$status_text="${override_text}";
		}else{
			$status_text=$CTRL__STATUS_TEXT{${status_code}};
		}
	}
	&cuprodigy_io_recording("STATUS",${mbnum},${tag},${mbnum},${status_code},${status_text});
}

sub crude_dms_status_and_action{
   local($action,$status_number,$status_text,$logfile_text)=@_;
	if(${SUPPRESS_STDOUT_DATASTREAM_OUTPUT} <= 0){
		if(${datastream_tag} ne ""){
			print STDOUT "<${datastream_tag}>${CTRL__EOL_CHARS}";
			&dms_status(${datastream_tag},${datastream_mbnum},${status_number},${status_text});
			print STDOUT "</${datastream_tag}>${CTRL__EOL_CHARS}";
			print STDOUT "EOT${CTRL__EOL_CHARS}";
		}else{
			print STDOUT "<PerlScript>${CTRL__EOL_CHARS}";
			&dms_status("PerlScript",0,${status_number},${status_text});
			print STDOUT "</PerlScript>${CTRL__EOL_CHARS}";
			print STDOUT "EOT${CTRL__EOL_CHARS}";
		}
	}
	if(${action} =~ /^abort$/i){
		&logfile("Stop process ($$); exiting due to ${logfile_text}\n");
		&selfpidfile_stop();
		exit(0);
	}else{
		&logfile("Detected ${logfile_text}\n");
	}
}

sub start{
   local($rtrn_service_id,$rtrn_service_id_ext);
   local($service_id);
	$service_id=&selfpidfile_start();
	$rtrn_service_id=${service_id};
	if(${service_id} ne ""){ $service_id=".${service_id}"; }
	$rtrn_service_id_ext=${service_id};
	if($DEBUG__LOG_CUPRODIGY_IO__FLAG){
		if(${service_id} ne ""){
			$DEBUG__LOG_CUPRODIGY_IO__service_id_ext=${service_id};
		}
	}
	if(! -d ${CTRL__DMS_TMPDIR}){
		system("mkdir ${CTRL__DMS_TMPDIR}");
	}
	&logfile_and_die("Can't create directory: ${CTRL__DMS_TMPDIR}\n") if ! -d ${CTRL__DMS_TMPDIR};
	chdir(${CTRL__DMS_TMPDIR}) || &logfile_and_die("Can not chdir(): ${CTRL__DMS_TMPDIR}\n");
	return($rtrn_service_id,$rtrn_service_id_ext);
}

sub datastream_tag_set{
	# selfpidfile_check() if ${datastream_tag} ne "" and $_[0] eq "" and ${datastream_mbnum} ne "" and $_[1] eq "";	# Need to call selfpidfile_check() immediately before datastream_tag_set() clears datastream parameters.
	$datastream_tag=$_[0];
	$datastream_mbnum=$_[1];
	# selfpidfile_check() if ${datastream_tag} ne "" and $_[0] ne "" and ${datastream_mbnum} ne "" and $_[1] ne "";	# Need to call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters.
}

sub selfpidfile_start{
# 	open(PIDFILE,"+>${SELFPIDFILE}");
# 	chmod(0666,${SELFPIDFILE});
# 	print PIDFILE $$,"\n";
# 	close(PIDFILE);
# 	open(PIDFILE,"<${SELFPIDFILE}");
   local($status,$message,$extent);
   local($old_processes_listed,$old_processes_killed);
	if(! -d ${CTRL__DMS_TMPDIR}){
		system("mkdir ${CTRL__DMS_TMPDIR}");
	}
	&logfile_and_die("Can't create directory: ${CTRL__DMS_TMPDIR}\n") if ! -d ${CTRL__DMS_TMPDIR};
	($status,$message)=&state_blocking_file_init(${CTRL__PROCESS_CONTROL__LOCK_FILE});
	if(${status} == 0){
		&logfile_and_die("state_blocking_file_init(): ${status}: ${message}\n");
	}
	&logfile("STATE BLOCKING: Wait for EXCLUSIVE access.\n");
	($status,$message)=&state_blocking_file_set(EXCLUSIVE);
	if(${status} == 0){
		&logfile_and_die("state_blocking_file_set(): ${status}: ${message}\n");
	}
	&logfile("STATE BLOCKING: Begin EXCLUSIVE access.\n");
	if(${ARG_SERVICESETS} ne ""){
		$extent=&avail_service_id(${ARG_SERVICESETS});
		if(${extent} ne ""){
			$CTRL__PROCESS_CONTROL__FILE.=".".${extent};
		}else{
			&logfile_and_die("Could not identify an available Service Set ID from extent list: ${ARG_SERVICESETS}\n");
		}
	}else{
		$extent="";
	}
	&logfile("Using Service Set ID: ${extent}\n");
	($old_processes_listed,$old_processes_killed)=&unix_process_control_kill(${CTRL__PROCESS_CONTROL__FILE});
	&unix_process_control_set(${CTRL__PROCESS_CONTROL__FILE},$$);
	$SIG{USR1}="signal_exit_requested";
	$SIG{USER1}="signal_exit_requested";
	($status,$message)=&state_blocking_file_set(UNLOCK,CLOSE);
	if(${status} == 0){
		&logfile_and_die("state_blocking_file_set(): ${status}: ${message}\n");
	}
	&logfile("STATE BLOCKING: End EXCLUSIVE access.\n");
	return(${extent});
}

sub selfpidfile_stop{
	&unix_process_control_clear(${CTRL__PROCESS_CONTROL__FILE},$$);
}

sub selfpidfile_check{	# Need to call selfpidfile_check() immediately after datastream_tag_set() set datastream parameters, and immediately before datastream_tag_set() clears datastream parameters.
#    local($curr_pid);
# 	seek(PIDFILE,0,0);
# 	while(read(PIDFILE,$curr_pid,1024,length($curr_pid))){ 1; }
# 	$curr_pid=~s/[\r\n]//g;
# 	if($curr_pid ne $$){
# 		&crude_dms_status_and_action(
#			"abort",
# 			"999",
# 			"MULTIPLE INTERFACE COPIES RUNNING",
# 			"new PID ${curr_pid}."
# 		);
# 	}
	if(!&unix_process_control_check_is_mine(0,${CTRL__PROCESS_CONTROL__FILE},$$)){
		&logfile("Process ($$) instructed to terminate.\n","Stop process ($$); forced to exit.\n");
		&selfpidfile_stop();
		&crude_dms_status_and_action(
			"abort",
			"999",
			"MULTIPLE INTERFACE COPIES RUNNING",
			"new process."
		);
	}
}

sub input_closed{
	&logfile("Input closed.\n");
	seek(PIDFILE,0,0);
	while(read(PIDFILE,$curr_pid,1024,length($curr_pid))){ 1; }
	$curr_pid=~s/[\r\n]//g;
	if($curr_pid ne $$){
		&logfile("Also detecting new PID ${curr_pid}.");
	}
	&logfile("Stop process ($$); exiting normally.\n");
	&selfpidfile_stop();
	exit(0);
}

sub output_closed{	# Received a PIPE signal.
   local($curr_pid);
	&logfile("Output closed.\n");
	seek(PIDFILE,0,0);
	while(read(PIDFILE,$curr_pid,1024,length($curr_pid))){ 1; }
	$curr_pid=~s/[\r\n]//g;
	if($curr_pid ne $$){
		&logfile("Also detecting new PID ${curr_pid}.");
	}
	&logfile("Stop process ($$); exiting normally.\n");
	&selfpidfile_stop();
	exit(0);
}

sub logfile_init{
   # args($LOGFILE_SIZE,$LOGFILE_NAME)=@_; #
	$LOGFILE_SIZE=$_[0];
	$LOGFILE_NAME=$_[1];
	$LOGFILE_FIRST_PASS=1;
}

sub logfile{
   local(@messages)=@_;
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f,$now,$timestamp);
   local($text,$lastchar);
	if(${LOGFILE_SIZE} > 0){
		if(${LOGFILE_FIRST_PASS}){
			if(! -f "${LOGFILE_NAME}.lock"){
				open(LOGFILE_LOCK,"+>>${LOGFILE_NAME}.lock");
				chmod(0666,"${LOGFILE_NAME}.lock");
			}else{
				open(LOGFILE_LOCK,"+>>${LOGFILE_NAME}.lock");
			}
			if(! -f ${LOGFILE_NAME}){
				open(LOGFILE_FH,">>${LOGFILE_NAME}");
				chmod(0666,${LOGFILE_NAME});
			}else{
				open(LOGFILE_FH,">>${LOGFILE_NAME}");
			}
			select((select(LOGFILE_FH),$|=1)[$[]);
			$LOGFILE_FIRST_PASS=0;
		}
		flock(LOGFILE_LOCK,${LOCK_EX});
		seek(LOGFILE_LOCK,0,2);
		if(-s LOGFILE_FH > ${LOGFILE_SIZE}){
			close(LOGFILE_FH);
			if(-s ${LOGFILE_NAME} > ${LOGFILE_SIZE}){
				# Recheck the file by name (not filehandle) just in case another process already rolled over the file
				if(!rename(${LOGFILE_NAME},"${LOGFILE_NAME}O")){
					system("mv '${LOGFILE_NAME}' '${LOGFILE_NAME}O' 2> /dev/null");
				}
			}
			open(LOGFILE_FH,">>${LOGFILE_NAME}");
			chmod(0666,${LOGFILE_NAME});
			select((select(LOGFILE_FH),$|=1)[$[]);
		}
		$now=time();
		@f=localtime($now);
		$timestamp=sprintf("%010d  %04d%02d%02d%02d%02d%02d  %07d  ",$now,1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0],$$);
		$lastchar="\n";
		foreach $text (@messages){
			print LOGFILE_FH ${timestamp} if $lastchar eq "\n";
			print LOGFILE_FH ${text};
			if(${text} ne ""){
				$lastchar=substr(${text},-1,1);
			}
		}
		print LOGFILE_FH "\n" if $lastchar ne "\n";
		flock(LOGFILE_LOCK,${LOCK_UN});
	}else{
		$lastchar="\n";
		foreach $text (@messages){
			push(@LOGFILE_QUEUE,"") if $lastchar eq "\n";
			$LOGFILE_QUEUE[$#LOGFILE_QUEUE].=${text};
			if(${text} ne ""){
				$lastchar=substr(${text},-1,1);
			}
		}
		$LOGFILE_QUEUE[$#LOGFILE_QUEUE].="\n" if $lastchar ne "\n";
	}
}

sub logfile_queue_flush{
	if(@LOGFILE_QUEUE > 0){
		&logfile(@LOGFILE_QUEUE);	# Must use logfile() instead of just directly printing to LOGFILE_LH (because of all the stuff that logfile() is already coded to handles for us).
		undef(@LOGFILE_QUEUE);
	}
}

sub logfile_and_die{
   local(@messages)=@_;
	&logfile(@messages);
	$messages[0]="${0}: ".$messages[0];
	die(@messages);
}

sub func_rename{
   local($from,$to)=@_;
   local(*FROM,*TO);
   local($buf);
	if(!rename($from,$to)){
		open(FROM,"<${from}");
		open(TO,">${to}");
		while(read(FROM,$buf,1024)){
			print TO $buf;
		}
		close(FROM);
		close(TO);
		unlink(${from});
	}
}

sub textfilter{	# Subroutine based upon htmlfilter().
   local($text)=@_;
   local(@htmlfrom)=  (	'&',	'<',	'>',	'"'	);
   local(@htmlto)=    (	'&amp;','&lt;',	'&gt;',	'&quot;');
   local($htmlidx,$textidx);
   local($htmlfrom,$htmlto);
	if(${textfilter_mode_SANE}){
		$text=~tr/\200-\377/\000-\177/;	# Fold to 7-bit ASCII
		$text=~s/[\000-\037\177]/ /g;	# Replace unprintable characters with SPACE
	}
	$text=~s/^\s\s*//;	# Strip leading pad characters
	$text=~s/\s\s*$//;	# Strip trailing pad characters
	$text=~s/\s\s*/ /g;	# Reduce multiple pad characters to single SPACE
	# Replace special HTML characters
	if(${textfilter_mode_HTML}){
		for($htmlidx=0;$htmlidx<=$#htmlfrom;$htmlidx++){
			if(index($text,$htmlfrom[$htmlidx])>=0){
				$htmlfrom=$htmlfrom[$htmlidx];
				$htmlto=$htmlto[$htmlidx];
				for($textidx=length($text)-1;$textidx>=0;$textidx--){
					if(substr($text,$textidx,1) eq $htmlfrom){
						substr($text,$textidx,1)=$htmlto;
					}
				}
			}
		}
	}
	# Replace other stuff
	if(${textfilter_mode_POSTGRES}){
		$text=~s/\\/\&#092;/g;	# Convert "\" to HTML equivalent
		if(length(${text}) > 255){
			$text=&htmlfilter_strip_trailing_incomplete_entity(&textfilter_shorten_text(${text},255));
		}
	}
	return($text);
}

sub textfilter_html{
   local($text)=@_;
   local(@htmlfrom)=  (	'&',	'<',	'>',	'"'	);
   local(@htmlto)=    (	'&amp;','&lt;',	'&gt;',	'&quot;');
   local($htmlidx,$textidx);
   local($htmlfrom,$htmlto);
	$text=~s/^\s\s*//;	# Strip leading pad characters
	$text=~s/\s\s*$//;	# Strip trailing pad characters
	$text=~s/\s\s*/ /g;	# Reduce multiple pad characters to single SPACE
	for($htmlidx=0;$htmlidx<=$#htmlfrom;$htmlidx++){
		if(index($text,$htmlfrom[$htmlidx])>=0){
			$htmlfrom=$htmlfrom[$htmlidx];
			$htmlto=$htmlto[$htmlidx];
			for($textidx=length($text)-1;$textidx>=0;$textidx--){
				if(substr($text,$textidx,1) eq $htmlfrom){
					substr($text,$textidx,1)=$htmlto;
				}
			}
		}
	}
	return($text);
}

sub textfilter_xml{
   local($text)=@_;
   local(@htmlfrom)=  (	'&',	'<',	'>'    );
   local(@htmlto)=    (	'&amp;','&lt;',	'&gt;' );
   local($htmlidx,$textidx);
   local($htmlfrom,$htmlto);
	for($htmlidx=0;$htmlidx<=$#htmlfrom;$htmlidx++){
		if(index($text,$htmlfrom[$htmlidx])>=0){
			$htmlfrom=$htmlfrom[$htmlidx];
			$htmlto=$htmlto[$htmlidx];
			for($textidx=length($text)-1;$textidx>=0;$textidx--){
				if(substr($text,$textidx,1) eq $htmlfrom){
					substr($text,$textidx,1)=$htmlto;
				}
			}
		}
	}
	return($text);
}

sub textfilter_mode{	# Subroutine based upon htmlfilter_mode().
	$textfilter_mode .= "," . join(",",@_) . "," ;
	$textfilter_mode =~ s/,,/,/g;
	$textfilter_mode =~ tr/a-z/A-Z/;
	if(index(${textfilter_mode},",SANE,")>=$[){
		$textfilter_mode_SANE=1;
	}else{
		$textfilter_mode_SANE=0;
	}
	if(index(${textfilter_mode},",POSTGRES,")>=$[){
		$textfilter_mode_POSTGRES=1;
	}else{
		$textfilter_mode_POSTGRES=0;
	}
	if(index(${textfilter_mode},",HTML,")>=$[){
		$textfilter_mode_HTML=1;
	}else{
		$textfilter_mode_HTML=0;
	}
}

sub textfilter_shorten_text{	# Subroutine based upon htmlfilter_shorten_text().
   local($text,$maxlen)=@_;
   local($idx,$idx_start);
   local($count)=0;
	for($idx=0;${idx}<${maxlen};$idx++){
		$next_char=substr(${text},$idx,1);
		if(${next_char} ne '&' && ${next_char} ne '<'){
			$count++;
		}elsif(${next_char} eq '&'){
			$idx_start=${idx};
			while(${idx}<${maxlen} && substr(${text},${idx},1) ne ';'){
				$idx++;
			}
			if(${idx}<${maxlen}){
				$count+=&math_quirk__int(${idx}-${idx_start}+1);
			}
		}elsif(${next_char} eq '<'){
			$idx_start=${idx};
			while(${idx}<${maxlen} && substr(${text},${idx},1) ne '>'){
				$idx++;
			}
			if(${idx}<${maxlen}){
				$count+=&math_quirk__int(${idx}-${idx_start}+1);
			}
		}else{
			$count++;
		}
	}
	return(substr(${text},0,${count}));
}

sub htmlfilter_strip_trailing_incomplete_entity{
   local($htmltext)=@_;
	$htmltext=~s/&[^;]{0,4}$//;	# Strip trailing incomplete entities (likely cut-off mid-entity) that would otherwise have looked like "&amp;", "&lt;", "&gt;", "&#092;", etc.
	return(${htmltext});
}

sub decimals{
   local($value,$decimals)=@_;
	# Must use int() or sprintf() to prevent PERL calculations like:
	#	192.15 - 189.85 = 2.30000000000001
	#	0 - 4.97 = -4.9699999999999998
	if($decimals<=0){
		&math_quirk__int($value);
	}else{
		sprintf("%.${decimals}f",$value);
	}
}

sub busy_bals_log{
   local($mbnum,$BalRecvBuf_before,$BalRecvBuf_after)=@_;
   local(*RAW);
   local($idx)=0;
   local($basename);
   local($curr_basename,$next_basename);
   local($ctrl);
	if(${CTRL__BUSY_BALS_LOG_MAX} > 0){
		$ctrl="%0".sprintf("%.0f",length(${CTRL__BUSY_BALS_LOG_MAX}))."d";
		$basename="${CTRL__DMS_TMPDIR}/busy_bals.";
		for($idx=${CTRL__BUSY_BALS_LOG_MAX}-1;$idx>0;$idx--){
			$curr_basename=${basename}.sprintf(${ctrl},${idx});
			$next_basename=${basename}.sprintf(${ctrl},sprintf("%.0f",${idx}+1));
			if( -f "${curr_basename}.1"){
				rename("${curr_basename}.1","${next_basename}.1");
			}
			if( -f "${curr_basename}.2"){
				rename("${curr_basename}.2","${next_basename}.2");
			}
		}
		$curr_basename=${basename}.sprintf(${ctrl},1);
		if(open(RAW,">${curr_basename}.1")){
			print RAW ${BalRecvBuf_before};
			close(RAW);
		}
		if(open(RAW,">${curr_basename}.2")){
			print RAW ${BalRecvBuf_after};
			close(RAW);
		}
	}
}

sub bal_excl_xfer_from{
   local($balance_class,$cuprodigy_accttype)=@_;
   local($excl_reason)="";
	if(&transaction_excl_xfer_from(${balance_class},${cuprodigy_accttype},"GEN") ne ""){
		$excl_reason="GEN";
	}
	if(&transaction_excl_xfer_from(${balance_class},${cuprodigy_accttype},"SELF") ne "" and
	   &transaction_excl_xfer_from(${balance_class},${cuprodigy_accttype},"XAC") ne ""){
		$excl_reason="SELF,XAC";
	}
	return(${excl_reason});
}

sub bal_excl_xfer_to{
   local($balance_class,$cuprodigy_accttype)=@_;
   local($excl_reason)="";
	if(&transaction_excl_xfer_to(${balance_class},${cuprodigy_accttype},"GEN") ne ""){
		$excl_reason="GEN";
	}
	if(&transaction_excl_xfer_to(${balance_class},${cuprodigy_accttype},"SELF") ne "" and
	   &transaction_excl_xfer_to(${balance_class},${cuprodigy_accttype},"XAC") ne ""){
		$excl_reason="SELF,XAC";
	}
	return(${excl_reason});
}

sub date_to_CCYYMMDD{
   local($date)=@_;
   local($rtrn)="";
	if    (${date} =~ /^\d\d\d\d\d\d\d\d$/){		# CCYYMMDD
		$rtrn=substr($date,0,4).substr($date,4,2).substr($date,6,2);
	}elsif(${date} =~ /^\d\d\d\d[^\d]\d\d[^\d]\d\d$/){	# CCYY?MM?DD
		$rtrn=substr($date,0,4).substr($date,5,2).substr($date,8,2);
	}elsif(${date} =~ /^\d\d[^\d]\d\d[^\d]\d\d\d\d$/){	# MM?DD?CCYY
		$rtrn=substr($date,6,4).substr($date,0,2).substr($date,3,2);
	}
	return(${rtrn});
}

sub time_to_CCYYMMDD{
   local($time)=@_;
   local(@f);
	@f=localtime(${time});
	sprintf("%04.0f%02.0f%02.0f",1900+$f[5],1+$f[4],$f[3]);
}

sub rawdata_for_mbnum{
   # arg($mbnum,$ext,$max_archive_copies,$data)=@_; #
   local(@f);
   local($timestamp);
   local($filename);
   local($max_archive_copies);
   local($max_archive_ext);
   local($archive_ext_width);
   local($archive_ext_at_0);
   local(*FILE);
   local($SPOOL_DIR)=&use_arg_extension_always("-d","${DMS_HOMEDIR}/ADMIN",${VAR_CUID},${VAR_EXTENSION},"/RAWDATA");
   local($SPOOL_MBNUM_MAXLEN)=12;
   local($SPOOL_BTREE_WIDTH)=3;
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	$filename=&cache_spoolmbfile($_[0]).".".$_[1];
	$max_archive_copies=sprintf("%.0f",$_[2]);
	if(${max_archive_copies} > 1){
		$max_archive_ext=sprintf("%.0f",${max_archive_copies}-1);
		$archive_ext_width=length(sprintf("%.0f",${max_archive_copies}-1));
		$archive_ext_at_0=sprintf("%0${archive_ext_width}.0f",0);
		if(-f "${filename}.${archive_ext_at_0}"){
			for($ext=${max_archive_ext}-1;$ext>=0;$ext=sprintf("%.0f",${ext}-1)){
				$archive_ext_newer=sprintf("%0${archive_ext_width}.0f",${ext});
				$archive_ext_older=sprintf("%0${archive_ext_width}.0f",${ext}+1);
				if(-f "${filename}.${archive_ext_newer}"){
					if(!rename("${filename}.${archive_ext_newer}","${filename}.${archive_ext_older}")){
						&logfile("WARNING: rawdata_for_mbnum(): Failed renaming '${filename}.${archive_ext_newer}' to '${filename}.${archive_ext_older}'.\n");
					}
				}
			}
		}
		$filename="${filename}.${archive_ext_at_0}";
	}
	if(!open(FILE,">${filename}")){
		&logfile("WARNING: rawdata_for_mbnum(): Can not create/write: ${filename}\n");
	}else{
		print FILE "FILENAME:\t${filename}\n";
		print FILE "TIMESTAMP:\t${timestamp}\n";
		print FILE $_[3];
		close(FILE);
	}
}

sub print_io_recording{
   local($prefix,$xml_composit);
	if(@_ > 0){
		if(@_ == 2 and ( index($_[0],"< ") == 0 or index($_[0],"> ") == 0 ) and $_[0] =~ /^..\s*</ and ( $_[0] =~ /\n./ or $_[0] =~ /^...*>[^<]*&lt;.*&gt;[^>]*</is ) and $_[1] eq "\n"){	# Special case where print_io_recording() could recieve multi-line XML from post_request() (as mutated by post_request_expand_io_text()).
			$prefix=substr($_[0],0,2);
			$xml_composit=substr($_[0],2);
			$xml_composit=~s/\n${prefix}/\n/sg;	# Because post_request_expand_io_text() would have reformatted the data and insert the $prefix after every "\n"
			&normalize_io_cuprodigy($xml_composit);	# Edit $xml_composit in place
			print CUPRODIGY_IO_RECORDING ${prefix},${xml_composit},$_[1];
			print CUPRODIGY_IO_RECORDING_RAW @_;
		}else{
			print CUPRODIGY_IO_RECORDING @_;
			print CUPRODIGY_IO_RECORDING_RAW @_;
		}
	}
}

sub normalize_io_cuprodigy{
	if($_[0] =~ /\n./ or $_[0] =~ />[^<]*&lt;.*&gt;[^>]*</is){
		$_[0]=~s/&lt;/</igs; $_[0]=~s/&gt;/>/igs; $_[0]=~s/&amp;/&/igs;
		$_[0]=~s/^[\s\r\n]*</</s;
		$_[0]=~s/>[\s\r\n]*</></gs;
		$_[0]=~s/>[\s\r\n]*$/>/s;
		$_[0]=~s/[\t\r\n]/ /gs;
		"1";	# For implied "return()"
	}else{
		"0";	# For implied "return()"
	}
}

sub cuprodigy_io_recording{
   local($action,$mbnum,@details)=@_;
   local(@f);
   local($timestamp);
   local($mbnumdir,$mbnumfilename);
   local($filename);
   local($filename_wip);
   local($filename_lock);
   local($max_archive_copies);
   local($max_archive_ext);
   local($archive_ext_width);
   local($archive_ext_at_0);
   local($SPOOL_DIR)=&use_arg_extension_always("-d","${DMS_HOMEDIR}/ADMIN",${VAR_CUID},${VAR_EXTENSION},"/CUPRODIGY_IO_RECORDING");
   local($SPOOL_MBNUM_MAXLEN)=12;
   local($SPOOL_BTREE_WIDTH)=3;
   local($MAX_ARCHIVE_COPIES)=15;
	$MAX_ARCHIVE_COPIES = ( ${CONF__CUPRODIGY_IO_RECORDING__MAX_ARCHIVE_COPIES} > 0 ? ${CONF__CUPRODIGY_IO_RECORDING__MAX_ARCHIVE_COPIES} : ${MAX_ARCHIVE_COPIES} ); 
	$MAX_ARCHIVE_COPIES = ( $mbnum =~ /_WITHOUT_MEMBER$/ ? 250 : ${MAX_ARCHIVE_COPIES} ); 
	$SPOOL_MBNUM_MAXLEN = ( $mbnum =~ /_WITHOUT_MEMBER$/ ? 1 : ${SPOOL_MBNUM_MAXLEN} );
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	($mbnumdir,$mbnumfilename)=&cache_spoolmbdir(${mbnum});
	$filename=${mbnumdir}."/".${mbnumfilename};
	$filename_wip=${filename}.".wip.".${SCRIPT_SERVICE_ID};
	$filename_lock=${mbnumdir}."/.file_moving_lock";	# $filename_lock=${filename}.".lck";
	if    ($action=~/^START$/i){
		if(-f "${filename_wip}"){
			rename("${filename_wip}.8","${filename_wip}.9") if -f "${filename_wip}.8";
			rename("${filename_wip}.8.raw","${filename_wip}.9.raw") if -f "${filename_wip}.8.raw";
			rename("${filename_wip}.7","${filename_wip}.8") if -f "${filename_wip}.7";
			rename("${filename_wip}.7.raw","${filename_wip}.8.raw") if -f "${filename_wip}.7.raw";
			rename("${filename_wip}.6","${filename_wip}.7") if -f "${filename_wip}.6";
			rename("${filename_wip}.6.raw","${filename_wip}.7.raw") if -f "${filename_wip}.6.raw";
			rename("${filename_wip}.5","${filename_wip}.6") if -f "${filename_wip}.5";
			rename("${filename_wip}.5.raw","${filename_wip}.6.raw") if -f "${filename_wip}.5.raw";
			rename("${filename_wip}.4","${filename_wip}.5") if -f "${filename_wip}.4";
			rename("${filename_wip}.4.raw","${filename_wip}.5.raw") if -f "${filename_wip}.4.raw";
			rename("${filename_wip}.3","${filename_wip}.4") if -f "${filename_wip}.3";
			rename("${filename_wip}.3.raw","${filename_wip}.4.raw") if -f "${filename_wip}.3.raw";
			rename("${filename_wip}.2","${filename_wip}.3") if -f "${filename_wip}.2";
			rename("${filename_wip}.2.raw","${filename_wip}.3.raw") if -f "${filename_wip}.2.raw";
			rename("${filename_wip}.1","${filename_wip}.2") if -f "${filename_wip}.1";
			rename("${filename_wip}.1.raw","${filename_wip}.2.raw") if -f "${filename_wip}.1.raw";
			rename("${filename_wip}.0","${filename_wip}.1") if -f "${filename_wip}.0";
			rename("${filename_wip}.0.raw","${filename_wip}.1.raw") if -f "${filename_wip}.0.raw";
			rename("${filename_wip}","${filename_wip}.0");
			rename("${filename_wip}.raw","${filename_wip}.0.raw");
		}
		open(CUPRODIGY_IO_RECORDING,">${filename_wip}"); select((select(CUPRODIGY_IO_RECORDING),$|=1)[$[]);
		open(CUPRODIGY_IO_RECORDING_RAW,">${filename_wip}.raw"); select((select(CUPRODIGY_IO_RECORDING_RAW),$|=1)[$[]);
		&print_io_recording("# DATE: ",${timestamp},"\n");
		&print_io_recording("# MBNUM: ",${mbnum},"\n");
		&print_io_recording("# COMMAND: ",join("\t",@details),"\n");
	}elsif($action=~/^NOTE$/i){
		&print_io_recording("# DATE: ",${timestamp},"\n");
		&print_io_recording("# NOTE: ",join("\t",@details),"\n");
	}elsif($action=~/^STATUS$/i){
		&print_io_recording("# STATUS: ",join("\t",@details),"\n");
	}elsif($action=~/^STOP$/i){
		&print_io_recording("# DATE: ",${timestamp},"\n");
		&print_io_recording("# DATE: ",${timestamp},"\n");
		close(CUPRODIGY_IO_RECORDING);
		close(CUPRODIGY_IO_RECORDING_RAW);
		&cuprodigy_io_recording_state_blocking("START",${filename_lock});
		if(sprintf("%.0f",${MAX_ARCHIVE_COPIES}) > 1){
			$max_archive_copies=sprintf("%.0f",${MAX_ARCHIVE_COPIES});
			$max_archive_ext=sprintf("%.0f",${max_archive_copies}-1);
			$archive_ext_width=length(sprintf("%.0f",${max_archive_copies}-1));
			$archive_ext_at_0=sprintf("%0${archive_ext_width}.0f",0);
			if(-f "${filename}.${archive_ext_at_0}"){
				for($ext=${max_archive_ext}-1;$ext>=0;$ext=sprintf("%.0f",${ext}-1)){
					$archive_ext_newer=sprintf("%0${archive_ext_width}.0f",${ext});
					$archive_ext_older=sprintf("%0${archive_ext_width}.0f",${ext}+1);
					if(-f "${filename}.${archive_ext_newer}"){
						if(!rename("${filename}.${archive_ext_newer}","${filename}.${archive_ext_older}")){
							&logfile("WARNING: cuprodigy_io_recording(): Failed renaming '${filename}.${archive_ext_newer}' to '${filename}.${archive_ext_older}'.\n");
						}
					}
					if(-f "${filename}.${archive_ext_newer}.raw"){
						if(!rename("${filename}.${archive_ext_newer}.raw","${filename}.${archive_ext_older}.raw")){
							&logfile("WARNING: cuprodigy_io_recording(): Failed renaming '${filename}.${archive_ext_newer}.raw' to '${filename}.${archive_ext_older}.raw'.\n");
						}
					}
				}
			}
			$filename="${filename}.${archive_ext_at_0}";
		}
		if(!rename(${filename_wip},${filename})){
			&logfile("WARNING: cuprodigy_io_recording(): Failed renaming '${filename_wip}' to '${filename}'.\n");
		}
		if(!rename("${filename_wip}.raw","${filename}.raw")){
			&logfile("WARNING: cuprodigy_io_recording(): Failed renaming '${filename_wip}.raw' to '${filename}.raw'.\n");
		}
		&cuprodigy_io_recording_state_blocking("STOP",${filename_lock});
	}
}

sub cuprodigy_io_recording_state_blocking{
   local($action,$file)=@_;
   local($status,$message);
	if    ($action =~ /^START$/i){
		($status,$message)=&state_blocking_file_init(${file});
		if(${status} == 0){
			&logfile_and_die("state_blocking_file_init(): ${status}: ${message}\n");
		}
		($status,$message)=&state_blocking_file_set(EXCLUSIVE);
		if(${status} == 0){
			&logfile_and_die("state_blocking_file_set(): ${status}: ${message}\n");
		}
	}elsif($action =~ /^STOP$/i){
		($status,$message)=&state_blocking_file_set(UNLOCK,CLOSE);
		if(${status} == 0){
			&logfile_and_die("state_blocking_file_set(): ${status}: ${message}\n");
		}
	}
}

sub cuprodigy_request_memberpwd{
   local($mbnum)=@_;
   local($cuprodigy_xml_request_memberpwd);
	if(${cuprodigy_xml_request_memberpwd} eq ""){
		if($CUSTOM{"custom_xmlrequest_memberpwd.pi"}>0){
			$cuprodigy_xml_request_memberpwd=&custom_xmlrequest_memberpwd__calc_request_memberpwd(${mbnum});
		}
	}
	if(${cuprodigy_xml_request_memberpwd} eq ""){
		if(${MB_OVERRIDES} eq ${mbnum}){
			$cuprodigy_xml_request_memberpwd=$MB_OVERRIDES{${mbnum},"ACCOUNTNUMBER_PASSWORD",${mbnum}};
		}
	}
	if(${cuprodigy_xml_request_memberpwd} eq ""){
		${cuprodigy_xml_request_memberpwd}=$CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD{${mbnum}};
	}
	if(${cuprodigy_xml_request_memberpwd} eq ""){
		${cuprodigy_xml_request_memberpwd}=${CONF__CUPRODIGY_SERVER__XML_CONSTANT_ACCOUNTNUMBER_PASSWORD};
	}
	return(${cuprodigy_xml_request_memberpwd});
}

sub calculate_micr{
   local($mbnum,$accttype,$certnum,$default)=@_;
   local($micr)="";
   local($mtime);
   local($SPOOL_DIR)=&use_arg_extension_if_exists("-d","${DMS_HOMEDIR}/MICR_OVERRIDES",${VAR_CUID},${VAR_EXTENSION});
   local($SPOOL_MBNUM_MAXLEN)=12;
   local($SPOOL_BTREE_WIDTH)=3;
	($mbnum,$accttype)=&split_dms_xjo_overloaded_composit(${mbnum},${accttype});
	if(${micr} eq ""){
		if(${MB_OVERRIDES} eq ${mbnum}){
			$micr=$MB_OVERRIDES{${mbnum},"MICR",${mbnum},${accttype}};
		}
	}
	if(${micr} eq ""){
		if($CUSTOM{"custom_micr.pi"}>0){
			$micr=&custom_micr__calc_micr($mbnum,$accttype,$certnum,${default});
		}
	}
	if(${micr} eq ""){
		$micr=${default};
	}
	return(${micr});
}

sub date_add_CCYYMMDD{
   local($ccyymmdd,$remaining)=@_;
   local($rtrn);
   local(@DAYSINMONTH)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
   local($year,$month,$day);
   local($lastdayofmonth);
   local($daystoeom);
	# Sanity Checks
	return("") if ${ccyymmdd} !~ /^\d{8}$/;
	$year=substr($ccyymmdd,0,4); $month=substr($ccyymmdd,4,2); $day=substr($ccyymmdd,6,2);
	return("") if ${month}<1 || ${month}>12;
	return("") if ${day}<1 || ${day}>&date_last_day_of_month(${year},${month});
	# Perform Math
	if($remaining>=0){
		# Add days to date
		while($remaining>0){
			$lastdayofmonth=&date_last_day_of_month(${year},${month});
			if(${day}+${remaining}<=${lastdayofmonth}){
				$day+=${remaining};
				$remaining=0;
			}else{
				$daystoeom=${lastdayofmonth}-${day}+1;
				$remaining-=${daystoeom};
				$day=1;
				$month++;
				if($month>12){
					$month=1;
					$year++;
				}
			}
		}
		$rtrn=sprintf("%04d%02d%02d",$year,$month,$day);
	}else{
		# Subtract days from date
		$remaining=~s/-//;
		while($remaining>0){
			if(${day}>${remaining}){
				$day-=${remaining};
				$remaining=0;
			}else{
				$remaining-=${day};
				$month--;
				if($month<1){
					$month=12;
					$year--;
				}
				$day=&date_last_day_of_month(${year},${month});
			}
		}
		$rtrn=sprintf("%04d%02d%02d",$year,$month,$day);
	}
	return($rtrn);
}

sub date_last_day_of_month{
   local($year,$month)=@_;
   local($rtrn);
   local(@DAYSINMONTH)=(0,31,28,31,30,31,30,31,31,30,31,30,31);
	if(${month}>=1 && ${month}<=12 && &math_quirk__is_int(${month})){
		$rtrn=$DAYSINMONTH[${month}];
		if(${month}==2){
			# February
			$rtrn=28;
			if($year%4 == 0){
				$rtrn=29;
				if($year%100 == 0){
					$rtrn=28;
					if($year%400 == 0){
						$rtrn=29;
						if($year%1000 == 0){
							$rtrn=28;
							if($year%2000 == 0){
								$rtrn=29;
							}
						}
					}
				}
			}
		}
	}
	return($rtrn);
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- STATE BLOCKING
#===============================================================================

sub state_blocking_file_init{
   local($filename)=@_;
   local($rtrn_state,$rtrn_message)=(1,"");
	if(${state_blocking_file__is_open} > 0){
		&state_blocking_file_set(UNLOCK);
		close(STATE_BLOCKING_FILE);
		$state_blocking_file__is_open=0;
	}
	$state_blocking_file__name="";
	$state_blocking_file__is_open=0;
	$filename=~s/^\s\s*//;
	$filename=~s/\s\s*$//;
	if    (${filename} eq ""){
		($rtrn_state,$rtrn_message)=(0,"Specified file name can not be blank.");
	}elsif(index(${filename},"<") >= $[){
		($rtrn_state,$rtrn_message)=(0,"Specified file name can not contain \"<\".");
	}elsif(index(${filename},">") >= $[){
		($rtrn_state,$rtrn_message)=(0,"Specified file name can not contain \">\".");
	}elsif(index(${filename},"|") >= $[){
		($rtrn_state,$rtrn_message)=(0,"Specified file name can not contain \"|\".");
	}elsif(${filename} eq "-"){
		($rtrn_state,$rtrn_message)=(0,"Specified file name can not be \"-\".");
	}elsif(-e ${filename} && ! -f ${filename}){
		($rtrn_state,$rtrn_message)=(0,"Specified file name must be a regular file.");
	}else{
		if(open(STATE_BLOCKING_FILE,"+>>${filename}")){
			$state_blocking_file__name=${filename};
			close(STATE_BLOCKING_FILE);
		}else{
			($rtrn_state,$rtrn_message)=(0,"Can not open/create/read/write: ${filename}");
		}
	}
	return(${rtrn_state},${rtrn_message});
}
	
sub state_blocking_file_set{
   local(@arg_ops)=@_;
   local($rtrn_state,$rtrn_message)=(1,"");
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local($sanitize_ops);
   local(@ops,$op);
   local($op_close,$op_shared,$op_exclusive,$op_noblock,$op_unlock)=(0,0,0,0,0);
   local($flock_ored_ops)=0;
	# +--[ WARNINGS ABOUT FLOCK() ]---------------------------------------+ 
	# |                                                                   |
	# | Perl's implementation of "flock()" is system dependent; and as    |
	# | such, the finer points of usage may vary by system.               |
	# |                                                                   |
	# | Things that I have found warnings about (on the internet):        |
	# |   *  The "flock()" does not really lock a file (okay, this        |
	# |      was probably already known by UNIX programs); instead,       |
	# |      it interacts with "flock()" calls of other programs.         |
	# |   *  The "flock()" may or may not work over networks; this        |
	# |      is system dependent.                                         |
	# |   *  The "flock()" state may or may not be inherited across       |
	# |      a "fork()" call; this is system dependent.                   |
	# |   *  The LOCK_SH operation may not be implemented on all          |
	# |      systems (some use "lockf()" to emulate "flock()"), so        |
	# |      try to use only the LOCK_EX instead of LOCK_SH.              |
	# |   *  The file being locked needs to be accessable (opened)        |
	# |      for both reading and writing.  Some system require           |
	# |      read access for LOCK_SH to work, while others require        |
	# |      write access for LOCK_EX to work.                            |
	# |                                                                   |
	# +-------------------------------------------------------------------+
	$sanitize_ops=join(",",@arg_ops);
	$sanitize_ops=~s/\s*,\s*/,/g;
	$sanitize_ops=~tr/a-z/A-Z/;
	@ops=split(/,/,${sanitize_ops});
	while(@ops > 0){
		$op=shift(@ops);
		if    (${op} eq "CL" || ${op} eq "CLOSE"){
			$op_close=1;
		}elsif(${op} eq "UN" || ${op} eq "UNLOCK"){
			$op_unlock=1;
			$flock_ored_ops = ${flock_ored_ops} | ${LOCK_UN};
		}elsif(${op} eq "SH" || ${op} eq "SHARED"){
			$op_shared=1;
			$flock_ored_ops = ${flock_ored_ops} | ${LOCK_SH};
		}elsif(${op} eq "EX" || ${op} eq "EXCLUSIVE"){
			$op_exclusive=1;
			$flock_ored_ops = ${flock_ored_ops} | ${LOCK_EX};
		}elsif(${op} eq "NB" || ${op} eq "NOBLOCK"){
			$op_noblock=1;
			$flock_ored_ops = ${flock_ored_ops} | ${LOCK_NB};
		}else{
			($rtrn_state,$rtrn_message)=(0,"Unknown operation requested: ${op}");
			last;
		}
	}
	if(${rtrn_state} == 1 && ${op_unlock}+${op_shared}+${op_exclusive} == 0){
		($rtrn_state,$rtrn_message)=(0,"Must specify operation UNLOCK or SHARED or EXCLUSIVE.");
	}
	if(${rtrn_state} == 1 && ${op_unlock} && ${op_shared}+${op_exclusive}+${op_noblock} > 0){
		($rtrn_state,$rtrn_message)=(0,"Can not combine operation UNLOCK with SHARED or EXCLUSIVE or NOBLOCK.");
	}
	if(${rtrn_state} == 1 && ${op_close} && ${op_shared}+${op_exclusive}+${op_noblock} > 0){
		($rtrn_state,$rtrn_message)=(0,"Can not combine operation CLOSE with SHARED or EXCLUSIVE or NOBLOCK.");
	}
	if(${rtrn_state} == 1 && ${op_shared} && ${op_exclusive}){
		($rtrn_state,$rtrn_message)=(0,"Can not combine operations SHARED and EXCLUSIVE.");
	}
	if(${rtrn_state} == 1){
		if(${state_blocking_file__name} eq ""){
			($rtrn_state,$rtrn_message)=(0,"Script has not successfully called \"state_blocking_file_init()\".");
		}
	}
	if(${rtrn_state} == 1){
		if(${state_blocking_file__is_open} != 1){
			if(-e ${state_blocking_file__name} && ! -f ${state_blocking_file__name}){
				($rtrn_state,$rtrn_message)=(0,"Not a regular file: ${state_blocking_file__name}");
			}else{
				if(!open(STATE_BLOCKING_FILE,"+>>${state_blocking_file__name}")){
					($rtrn_state,$rtrn_message)=(0,"Can not open/create/read/write: ${state_blocking_file__name}");
				}else{
					$state_blocking_file__is_open=1;
				}
			}
		}
	}
	if(${rtrn_state} == 1){
		if(flock(STATE_BLOCKING_FILE,${flock_ored_ops})){
			seek(STATE_BLOCKING_FILE,0,2) if ${op_shared} || ${op_exclusive};
		}else{
			($rtrn_state,$rtrn_message)=(0,"PERL function \"flock()\" failed on file \"${state_blocking_file__name}\" for operations: ".join(", ",(split(/,/,${sanitize_ops}))));
			if((${op_shared} || ${op_exclusive}) && ${op_noblock}){
				($rtrn_state,$rtrn_message)=(-1,"NOBLOCK");
			}
		}
	}
	if(${rtrn_state} == 1){
		if(${op_close}){
			close(STATE_BLOCKING_FILE);
			$state_blocking_file__is_open=0;
		}
	}
	return(${rtrn_state},${rtrn_message});
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- SIGNAL TRAP
#===============================================================================

sub signal_exit_requested{
   local($signal)=@_;
	&logfile("Trapped signal SIG${signal}.\n");
	&core_degradation_check("killed");
	&logfile("Stop process ($$); forced to exit.\n");
	&selfpidfile_stop();
	# &crude_dms_status_and_action(
	# 	"abort",
	# 	"999",
	# 	"MULTIPLE INTERFACE COPIES RUNNING",
	# 	"new process."
	# );
	exit(0);
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- UNIX PROCESSES CONTROL
#===============================================================================

sub unix_related_process_check{
   local($control_file,$pid_compare_against,$pid_to_be_checked)=@_;
   local(*TMP);
   local($ps_text_orig);
   local($ps_text_curr);
   local(*PS);
   local($ps_hdr);
   local($ps_text_self);
   local($ps_text_relative);
   local($orig_SIG_CHLD);
   local($orig_SIG_CLD);
   local($processes_are_related)=0;
	if(${CTRL__PROCESS_CONTROL__PS_SIMILAR_CMD}){
		# Check ${pid_to_be_checked} by comparing its current 'ps' CMD
		# value against the ${pid_compare_against} current 'ps' CMD
		# value.  This is an allowed configuration only if the named
		# pipe devices are being shared by process that have identical
		# 'ps' CMD values.
		$orig_SIG_CHLD=$SIG{"CHLD"}; $SIG{"CHLD"}="DEFAULT";
		$orig_SIG_CLD=$SIG{"CLD"}; $SIG{"CLD"}="DEFAULT";
		if(open(PS,"ps -fp ${pid_compare_against} |")){
			while(defined($ps_hdr=<PS>)){ last ; }
			$ps_hdr=~s/[\r\n][\r\n]*$//;
			$ps_hdr=~s/\s\s*$//;
			$ps_hdr=~s/[^\s][^\s]*$//;
			while(defined($ps_text_self=<PS>)){
				$ps_text_self=~s/[\r\n][\r\n]*$//;
				last;
			}
			$ps_text_self=substr(${ps_text_self},length(${ps_hdr}));
			close(PS);
		}
		if(${ps_text_self} ne ""){
			if(open(PS,"ps -fp ${pid_to_be_checked} |")){
				while(defined($ps_text_relative=<PS>)){
					$ps_text_relative=~s/[\r\n][\r\n]*$//;
					$ps_text_relative=substr(${ps_text_relative},length(${ps_hdr}));
					if(${ps_text_relative} eq ${ps_text_self}){
						$processes_are_related=1;
						last;
					}
				}
				close(PS);
			}
		}
		$SIG{"CHLD"}=${orig_SIG_CHLD};
		$SIG{"CLD"}=${orig_SIG_CLD};
	}else{
		# Check ${pid_to_be_checked} by comparing its current 'ps' CMD
		# value against its originally saved 'ps' CMD value.  This is
		# the required configuration if the Service Set IDs are being
		# shared by process that do not have identical 'ps' CMD values.
		if(${control_file} ne "" && -f ${control_file}){
			if(open(TMP,"<${control_file}")){
				while(defined($pid_list=<TMP>)){
					$pid_list=~s/[\r\n][\r\n]*$//;
					if($pid_list =~ /^${pid_to_be_checked}\s/){
						($ps_text_orig=${pid_list})=~s/^${pid_to_be_checked}\s\s*//;
						last;
					}
				}
				close(TMP);
			}
			if(${ps_text_orig} ne ""){
				$orig_SIG_CHLD=$SIG{"CHLD"}; $SIG{"CHLD"}="DEFAULT";
				$orig_SIG_CLD=$SIG{"CLD"}; $SIG{"CLD"}="DEFAULT";
				if(open(PS,"ps -fp ${pid_to_be_checked} |")){
					while(defined($ps_hdr=<PS>)){ last ; }
					$ps_hdr=~s/[\r\n][\r\n]*$//;
					$ps_hdr=~s/\s\s*$//;
					$ps_hdr=~s/[^\s][^\s]*$//;
					while(defined($ps_text_curr=<PS>)){
						$ps_text_curr=~s/[\r\n][\r\n]*$//;
						last;
					}
					$ps_text_curr=substr(${ps_text_curr},length(${ps_hdr}));
					close(PS);
				}
				$SIG{"CHLD"}=${orig_SIG_CHLD};
				$SIG{"CLD"}=${orig_SIG_CLD};
				if(${ps_text_orig} eq ${ps_text_curr}){
					$processes_are_related=1;
				}
			}
		}
	}
	return(${processes_are_related});
}

sub unix_related_process_kill{
   local($control_file,$pid_compare_against,$pid_to_be_killed,$relation_text)=@_;
   local($rtrn)=0;
	$relation_text=~s/^\s\s*//; $relation_text=~s/\s\s*$//;
	if(${relation_text} eq ""){
		$relation_text="related";
	}else{
		$relation_text="${relation_text} related";
	}
	&logfile("Checking for ${relation_text} process (${pid_to_be_killed}).\n");
	if(&unix_related_process_check(${control_file},${pid_compare_against},${pid_to_be_killed})){
		&logfile("Killing ${relation_text} process (${pid_to_be_killed}).\n");
		if    (kill('USR1',${pid_to_be_killed})){
			$rtrn=1;
		}elsif(kill('USER1',${pid_to_be_killed})){
			$rtrn=1;
		}
	}
	return(${rtrn});
}

sub unix_process_control_set{
   local($control_file,@control_pid_list)=@_;
   local($pid);
   local(*PS);
   local($ps_hdr);
   local($ps_text);
   local($orig_SIG_CHLD);
   local($orig_SIG_CLD);
	if    (index(${control_file},"<") >= $[){
		die("${0}: unix_process_control_set(): Specified file name can not contain \"<\".\n");
	}elsif(index(${control_file},">") >= $[){
		die("${0}: unix_process_control_set(): Specified file name can not contain \">\".\n");
	}elsif(index(${control_file},"|") >= $[){
		die("${0}: unix_process_control_set(): Specified file name can not contain \"|\".\n");
	}elsif(${control_file} eq "-"){
		die("${0}: unix_process_control_set(): Specified file name can not be \"-\".\n");
	}
	open(UNIX_PROCESS_CONTROL__FH,"+>${control_file}") || die("${0}: unix_process_control_set(): Can not create/read/write file: ${control_file}\n");
	print UNIX_PROCESS_CONTROL__FH join(",",@control_pid_list),"\n";
	if(!${CTRL__PROCESS_CONTROL__PS_SIMILAR_CMD}){
		foreach $pid (@control_pid_list){
			$orig_SIG_CHLD=$SIG{"CHLD"}; $SIG{"CHLD"}="DEFAULT";
			$orig_SIG_CLD=$SIG{"CLD"}; $SIG{"CLD"}="DEFAULT";
			if(open(PS,"ps -fp ${pid} |")){
				while(defined($ps_hdr=<PS>)){ last ; }
				$ps_hdr=~s/[\r\n][\r\n]*$//;
				$ps_hdr=~s/\s\s*$//;
				$ps_hdr=~s/[^\s][^\s]*$//;
				while(defined($ps_text=<PS>)){
					$ps_text=~s/[\r\n][\r\n]*$//;
					last;
				}
				$ps_text=substr(${ps_text},length(${ps_hdr}));
				print UNIX_PROCESS_CONTROL__FH ${pid},"\t",${ps_text},"\n";
				close(PS);
			}
			$SIG{"CHLD"}=${orig_SIG_CHLD};
			$SIG{"CLD"}=${orig_SIG_CLD};
		}
	}
	close(UNIX_PROCESS_CONTROL__FH);
	open(UNIX_PROCESS_CONTROL__FH,"+>>${control_file}") || die("${0}: unix_process_control_set(): Can not open/read/write file: ${control_file}\n");
	$UNIX_PROCESS_CONTROL__FILENAME=${control_file};	# MARK -- discontinue "control_file" argument in other "unix_process_control_*" subroutines.
	$unix_process_control__timeout="";
}

sub unix_process_control_clear{
   local($control_file,$control_pid)=@_;
	if(${control_file} eq ""){ ${control_file}=${UNIX_PROCESS_CONTROL__FILENAME}; }
	if(&unix_process_control_check_is_mine(1,${control_file},${control_pid})){
		close(UNIX_PROCESS_CONTROL__FH);
		open(UNIX_PROCESS_CONTROL__FH,"+>${control_file}") || die("${0}: unix_process_control_clear(): Can not create/read/write file: ${control_file}\n");
		close(UNIX_PROCESS_CONTROL__FH);
		$unix_process_control__timeout="";
	}
}

sub unix_process_control_check_is_mine{
   local($force_reopen,$control_file,@control_pid_list)=@_;
   local($rtrn)=0;
   local($pid_list);
	if(${control_file} eq ""){ ${control_file}=${UNIX_PROCESS_CONTROL__FILENAME}; }
	if(${force_reopen} > 0 || ${unix_process_control__timeout} <= time()){
		close(UNIX_PROCESS_CONTROL__FH);
		if(open(UNIX_PROCESS_CONTROL__FH,"+>>${control_file}")){
			$unix_process_control__timeout=sprintf("%.0f",time()+${CTRL__PROCESS_CONTROL__CYCLE_SECONDS});
		}else{
			$unix_process_control__timeout="";
		}
	}
	seek(UNIX_PROCESS_CONTROL__FH,0,0);
	while(defined($pid_list=<UNIX_PROCESS_CONTROL__FH>)){ last; }
	$pid_list=~s/[\r\n][\r\n]*$//;
	if(@control_pid_list > 0 && ${pid_list} ne ""){
		$rtrn=1;
		while(@control_pid_list > 0){
			$pid=shift(@control_pid_list);
			if(${pid} eq "" || index(",${pid_list},",",${pid},") < $[){
				$rtrn=0;
			}
		}
	}
	utime(time(),time(),${control_file}) if ${rtrn} > 0;	# MTIME will tell us when last active.
	return(${rtrn});
}

sub unix_process_control_check_is_alive{
   local($control_file)=@_;
   local($rtrn_listed,$rtrn_alive)=(0,0);
   local($pid_list);
   local($pid);
	if(${control_file} eq ""){ ${control_file}=${UNIX_PROCESS_CONTROL__FILENAME}; }
	if(1){
		close(UNIX_PROCESS_CONTROL__FH);
		if(open(UNIX_PROCESS_CONTROL__FH,"+>>${control_file}")){
			$unix_process_control__timeout=sprintf("%.0f",time()+${CTRL__PROCESS_CONTROL__CYCLE_SECONDS});
		}else{
			$unix_process_control__timeout="";
		}
	}
	seek(UNIX_PROCESS_CONTROL__FH,0,0);
	while(defined($pid_list=<UNIX_PROCESS_CONTROL__FH>)){ last; }
	$pid_list=~s/[\r\n][\r\n]*$//;
	foreach $pid (split(/,/,${pid_list})){
		$rtrn_listed++;
		if(&unix_related_process_check(${control_file},$$,${pid})){
			$rtrn_alive++;
		}
	}
	return(${rtrn_listed},${rtrn_alive});
}

sub unix_process_control_kill{
   local($control_file)=@_;
   local($rtrn_listed,$rtrn_killed)=(0,0);
   local($pid_list);
   local($pid);
	if(${control_file} eq ""){ ${control_file}=${UNIX_PROCESS_CONTROL__FILENAME}; }
	if(1){
		close(UNIX_PROCESS_CONTROL__FH);
		if(open(UNIX_PROCESS_CONTROL__FH,"+>>${control_file}")){
			$unix_process_control__timeout=sprintf("%.0f",time()+${CTRL__PROCESS_CONTROL__CYCLE_SECONDS});
		}else{
			$unix_process_control__timeout="";
		}
	}
	seek(UNIX_PROCESS_CONTROL__FH,0,0);
	while(defined($pid_list=<UNIX_PROCESS_CONTROL__FH>)){ last; }
	$pid_list=~s/[\r\n][\r\n]*$//;
	foreach $pid (split(/,/,${pid_list})){
		$rtrn_listed++;
		if(&unix_related_process_kill(${control_file},$$,${pid},"distantly")){
			$rtrn_killed++;
		}
	}
	return(${rtrn_listed},${rtrn_killed});
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- AVAILABLE NAMED PIPE DEVICE PAIRS
#===============================================================================

sub avail_service_id{
   local($extentlist)=@_;
   local($rtrn_extent)="";
   local($extent);
   local($sane_extent);
   local(%SERVICESET_EXTENTS);
   local($status,$message);
   local($controlfile);
   local($found_listed,$found_alive);
   local(%MTIME,$mtime);
   local($key);
	# +--[ USAGE NOTE ]---------------------------------------------------+
	# | Any state blocking mechanism (such as "flock()") should have been |
	# | activated prior to running this subroutine.                       |
	# +-------------------------------------------------------------------+
	foreach $extent (split(/,/,$extentlist)){
		$sane_extent=${extent};
		$sane_extent=~s/^\s\s*//;
		$sane_extent=~s/\s\s*$//;
		next if $sane_extent eq "";
		if    (index(${sane_extent},"/") >= $[){
			die("${0}: process_service_pipe_avail_extent(): Extent can not contain \"/\".\n");
		}elsif(index(${sane_extent},"<") >= $[){
			die("${0}: process_service_pipe_avail_extent(): Extent can not contain \"<\".\n");
		}elsif(index(${sane_extent},">") >= $[){
			die("${0}: process_service_pipe_avail_extent(): Extent can not contain \">\".\n");
		}elsif(index(${sane_extent},"|") >= $[){
			die("${0}: process_service_pipe_avail_extent(): Extent can not contain \"|\".\n");
		}elsif(${sane_extent} eq "-"){
			die("${0}: process_service_pipe_avail_extent(): Extent can not be \"-\".\n");
		}
		$SERVICESET_EXTENTS{${sane_extent}}=${CTRL__PROCESS_CONTROL__FILE}.".".${sane_extent};
	}
	foreach $extent (sort(keys(%SERVICESET_EXTENTS))){
		$controlfile=$SERVICESET_EXTENTS{${extent}};
		open(CONTROLFILE,"+>>${controlfile}");
		close(CONTROLFILE);
	}
	if(${rtrn_extent} eq ""){
		# 1st, try and find an unused extent
		foreach $extent (sort(keys(%SERVICESET_EXTENTS))){
			$controlfile=$SERVICESET_EXTENTS{${extent}};
			if(-f ${controlfile} && (stat(${controlfile}))[7] == 0){
				$rtrn_extent=${extent};
				last;
			}
		}
	}
	if(${rtrn_extent} eq ""){
		# 2nd, wait a moment then again try and find an unused extent
		sleep(2);
		foreach $extent (sort(keys(%SERVICESET_EXTENTS))){
			$controlfile=$SERVICESET_EXTENTS{${extent}};
			if(-f ${controlfile} && (stat(${controlfile}))[7] == 0){
				$rtrn_extent=${extent};
				last;
			}
		}
	}
	if(${rtrn_extent} eq ""){
		# 3rd, try and find a fully terminated extent
		foreach $extent (sort(keys(%SERVICESET_EXTENTS))){
			$controlfile=$SERVICESET_EXTENTS{${extent}};
			($found_listed,$found_alive)=&unix_process_control_check_is_alive(${controlfile});
			if(${found_alive} == 0){
				# Expect 2 processes to be running, found 0.
				$rtrn_extent=${extent};
				last;
			}
		}
	}
	if(${rtrn_extent} eq ""){
		# 4th, try and find a partially terminated extent
		foreach $extent (sort(keys(%SERVICESET_EXTENTS))){
			$controlfile=$SERVICESET_EXTENTS{${extent}};
			($found_listed,$found_alive)=&unix_process_control_check_is_alive(${controlfile});
			if(${found_alive} < ${found_listed}){
				# Expect 2 processes to be running, found 1.
				$rtrn_extent=${extent};
				last;
			}
		}
	}
	if(${rtrn_extent} eq ""){
		# 5th (last resort), take over the least active process
		while(${rtrn_extent} eq ""){
			undef %MTIME;
			foreach $extent (sort(keys(%SERVICESET_EXTENTS))){
				$controlfile=$SERVICESET_EXTENTS{${extent}};
				$mtime=sprintf("%011.0f",(stat(${controlfile}))[9]);
				$MTIME{${mtime},${extent}}=${controlfile};
			}
			foreach $key (sort(keys(%MTIME))){
				($mtime,$extent)=split(/$;/,${key});
				$controlfile=$MTIME{${key}};
				if(${mtime} eq sprintf("%011.0f",(stat(${controlfile}))[9])){
					$rtrn_extent=${extent};
					last;
				}
			}
			sleep(2) if ${rtrn_extent} eq "";
		}
	}
	return(${rtrn_extent});
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- TIMED READ OF STDIN
#===============================================================================

sub timedread_eol_STDIN{
   local($timeout)=@_;
   local($rtrn_chars,$rtrn_status)=("","");
   local($SIGALARM)="ALRM";
   local($timedread_alarm);
	if(${timeout} > 0){
		# Input time requested.
		$chars="";
		eval {
			local $SIG{${SIGALARM}} = sub { die "alarm\n" };
			$timedread_alarm=0;
			alarm(${timeout});
			while(defined($chars=<STDIN>)){ last ; }
			alarm(0);	# Must reset 'alarm()', as 'alarm()' calls are not limited by 'eval{...}'.
		};
		$timedread_eol_STDIN__chars.=${chars};
		if($@){
			if($@ eq "alarm\n"){
				$timedread_alarm=1;
			}
		}
		if(${timedread_alarm} == 0){
			if(${timedread_eol_STDIN__chars} eq ""){
				$rtrn_status = "EOF";
			}else{
				$rtrn_chars=${timedread_eol_STDIN__chars};
				$timedread_eol_STDIN__chars="";
			}
		}else{
			$rtrn_status = "TIM";
		}
	}else{
		# No input time requested.
		$rtrn_status="EOF"; while(defined($rtrn_chars=<STDIN>)){ $rtrn_status=""; last ; }
	}
	return(${rtrn_chars},${rtrn_status});
}

sub timedread_bytes{
   local(*INPUT,$bytes_want,$timeout_seconds)=@_;
   local($rtrn_data,$rtrn_status)=("","");
   local($SIGALARM)="ALRM";
   local($bytes_have,$bytes_need);
	#-----------------------------------------------------------------------
	# Before Perl 5.001, input timeout must be handled by code like:
	#	sub timeout_alarm{ $timeout=1; }
	#	$ORIGALRM=$SIG{ALRM};
	#	while(1){
	#		$data=""; $status=""; $timeout=0;
	#		$SIG{ALRM}="timeout_alarm";
	#		alarm(5); read(INPUT,$data,1); alarm(0);
	#		$SIG{ALRM}=${ORIGALRM};
	#		if($timeout){ $status="TIM"; }
	#		if(!$timeout){ if($data eq ""){ $status="EOF"; } }
	#		print $data;
	#		last if $status ne "";
	#	}
	#
	# As of Perl 5.004, input timeout must be handled by code like:
	#	while(1){
	#		$data=""; $status="";
	#		eval {
	#			local($SIG{ALRM}) = sub { die("alarm\n") };
	#			alarm(5);
	#			if(read(INPUT,$data,1)==0){ $status="EOF"; }
	#			alarm(0);
	#		}
	#		if($@ ne "" and $@ eq "alarm\n"){ $status="TIM"; }
	#		if($@ ne "" and $@ ne "alarm\n"){ $status="ERR - ".$@; }
	#		print $data;
	#		last if $status ne "";
	#	}
	# 
	# Between Perl 5.001 and Perl 5.003 (inclusive), input timeout can be
	# handled by either coding method; though I have encountered periodic
	# data loss problems when using the "eval{..}" method under Perl 5.001.
	#
	# Either "read()" or "sysread()" may be used in these methods.  Your
	# choice will dependent upon Perl quirks (varying by version and O/S)
	# as well as your progamming needs.
	#-----------------------------------------------------------------------
	$bytes_want=sprintf("%.0f",${bytes_want});
	$timeout_seconds=sprintf("%.0f",${timeout_seconds});
	eval{
		local($SIG{${SIGALARM}}) = sub { die("alarm\n") };
		alarm(${timeout_seconds}) if ${timeout_seconds} > 0;
		$bytes_have=sprintf("%.0f",length(${rtrn_data}));
		while(${bytes_have}<${bytes_want}){
			$bytes_need=sprintf("%.0f",${bytes_want}-${bytes_have});
			if(sysread(INPUT,$rtrn_data,${bytes_need},${bytes_have})==0){
				$rtrn_status="EOF";
				last;
			}
			$bytes_have=sprintf("%.0f",length(${rtrn_data}));
		}
		alarm(0) if ${timeout_seconds} > 0;
	};
	if($@){
		if($@ eq "alarm\n"){
			$rtrn_status="TIM";
		}else{
			$rtrn_status="ERR - ".$@;
		}
	}
	return(${rtrn_data},${rtrn_status});
}

sub cache_read{
   my ($mbnum,@options)=@_;
   my ($rtrn_cache,$rtrn_mtime)=("",0);
   my ($oldmbfile);
   #my (*MBFILE);
	$oldmbfile=&cache_spoolmbfile(${mbnum},@options);
	if(open(MBFILE,"<${oldmbfile}")){
		$rtrn_cache=join("",<MBFILE>);
		$rtrn_mtime=(stat(MBFILE))[9];
		close(MBFILE);
	}
	return($rtrn_cache,$rtrn_mtime);
}

sub cache_write{
   my ($mbnum,$cache,@options)=@_;
   my ($rtrn)=0;
   my ($oldmbfile);
   #my (*MBFILE);
	$oldmbfile=&cache_spoolmbfile(${mbnum},@options);
	if(open(MBFILE,">${oldmbfile}")){
		print MBFILE $cache;
		close(MBFILE);
		$rtrn=1;
	}
	return(${rtrn});
}

sub cache_spooltmpfile{
   my ($spooldir);
	$spooldir=${SPOOL_DIR};
	if(! -d ${spooldir}){
		&cache_makedirectory(${spooldir},0777);
	}
	return(${spooldir}."/tmp-$$");
}

sub cache_spoolmbdir{
   my ($mbnum,@options)=@_;
   my ($spooldir);
   my ($mbnumdir);
   my ($zerofill);
   my ($lenmbnum);
   my ($maxgroup);
	# Filter the Member Number
	$mbnum=~s/^\s\s*//;
	$mbnum=~s/\s\s*$//;
	$mbnum=~s/\s/_/g;
	$mbnum=~s/\s/_/g;
	$mbnum=~s/\//_/g;
	$lenmbnum=length($mbnum);
	if(${lenmbnum}<${SPOOL_MBNUM_MAXLEN}){
		$zerofill="0" x (${SPOOL_MBNUM_MAXLEN}-${lenmbnum});
		$mbnum=${zerofill}.${mbnum};
		$lenmbnum=length($mbnum);
	}
	if(${lenmbnum} == ${SPOOL_MBNUM_MAXLEN} and ${SPOOL_BTREE_WIDTH}>0){
		$spooldir=${SPOOL_DIR};
		$maxgroup=${SPOOL_MBNUM_MAXLEN}-${SPOOL_BTREE_WIDTH};
		for(my $offset=0;$offset<${maxgroup};$offset+=${SPOOL_BTREE_WIDTH}){
			$spooldir.="/".substr($mbnum,$offset,${SPOOL_BTREE_WIDTH});
		}
	}else{
		$spooldir=${SPOOL_DIR};
	}
	$spooldir=~s?//*?/?g;
	$spooldir=~s?/$??;
	$mbnumdir=${spooldir}."/".${mbnum};
	if(! -d ${mbnumdir}){
		&cache_makedirectory(${mbnumdir},0777) if join(",","",@options,"") !~ /,NOCREATE,/i;
	}
	return(${mbnumdir},${mbnum});
}

sub cache_spoolmbfile{
   my ($mbnum,@options)=@_;
   my ($spooldir);
   my ($zerofill);
   my ($lenmbnum);
   my ($maxgroup);
	# Filter the Member Number
	$mbnum=~s/^\s\s*//;
	$mbnum=~s/\s\s*$//;
	$mbnum=~s/\s/_/g;
	$mbnum=~s/\s/_/g;
	$mbnum=~s/\//_/g;
	$lenmbnum=length($mbnum);
	if(${lenmbnum}<${SPOOL_MBNUM_MAXLEN}){
		$zerofill="0" x (${SPOOL_MBNUM_MAXLEN}-${lenmbnum});
		$mbnum=${zerofill}.${mbnum};
		$lenmbnum=length($mbnum);
	}
	if(${lenmbnum} == ${SPOOL_MBNUM_MAXLEN} and ${SPOOL_BTREE_WIDTH}>0){
		$spooldir=${SPOOL_DIR};
		$maxgroup=${SPOOL_MBNUM_MAXLEN}-${SPOOL_BTREE_WIDTH};
		for(my $offset=0;$offset<${maxgroup};$offset+=${SPOOL_BTREE_WIDTH}){
			$spooldir.="/".substr($mbnum,$offset,${SPOOL_BTREE_WIDTH});
		}
	}else{
		$spooldir=${SPOOL_DIR};
	}
	$spooldir=~s?//*?/?g;
	$spooldir=~s?/$??;
	if(! -d ${spooldir}){
		&cache_makedirectory(${spooldir},0777) if join(",","",@options,"") !~ /,NOCREATE,/i;
	}
	return(${spooldir}."/".${mbnum});
}

sub cache_makedirectory{
   my ($newdir,$perm)=@_;
   my ($len,$idx);
   my ($dir);
	if($newdir !~ /\/$/){
		$newdir.="/";
	}
	$len=length($newdir);
	for($idx=0;$idx<$len;$idx++){
		if(substr($newdir,$idx,1) eq "/"){
			$dir=substr($newdir,0,$idx);
			if($dir ne "" and ! -d ${dir}){
				mkdir(${dir},${perm});
			}
		}
	}
}

sub special_mode__parse_STDIN{
   local(*TTY);
   my($cuprodigy_header);
   my($cuprodigy_header_re);
   my($line);
   my($prefix_logfile);
   my($prefix_cuprodigy_header);
   my($seq);
	if(-c "/dev/tty"){
		open(TTY,">/dev/tty");
		print TTY "Reading from STDIN for input from recordings of CUProdigy XML.\n";
		print TTY "Printing to STDOUT the formatted datastream of the CUProdigy XML.\n";
		print TTY "Printing to STDERR the parsed values of the CUProdigy XML.\n";
		close(TTY);
	}
	$cuprodigy_header=&cuprodigy_header(0);
	($cuprodigy_header_re=${cuprodigy_header})=~s/[0-9][0-9]*/\\d\\d*/g;
	$preread="";
	while(1){
		if($preread eq ""){
			while(defined($line=<STDIN>)){ last; } last if $line eq "";
			$line=~s/[\r\n][\r\n]*$//;
		}else{
			$line=${preread}; $preread="";
			$line=~s/[\r\n][\r\n]*$//;
		}
		if    ($line =~ /^[<>#] /){
			# Appears to be data from the "ADMIN/CUPRODIGY_IO_RECORDING" files.
			if    ($line =~ /^[<>] </){
				# Okay, first lets slurp up a multi-line XML
				$common_prefix=substr($line,0,2);
				while(1){
					while(defined($line2=<STDIN>)){ last; } last if $line2 eq "";
					$line2=~s/[\r\n][\r\n]*$//;
					if(index($line2,substr($line,0,length(${common_prefix})))!=$[){
						$preread=${line2};
						last;
					}
					if($line2 !~ /^[<>]\s\s*</){
						$preread=${line2};
						last;
					}
					$line2=substr($line2,length(${common_prefix}));
					$line2=~s/^\s*//;
					$line=~s/\s*$//;
					$line.=${line2};
				}
				# Okay, now lets continue on as thought it were a single line
				$line =~ /^[<>] </;
				$prefix_logfile=${&};
				$line=${'};
				$prefix_logfile=~s/<$//;
				$line=~s/^/</;
				if(${cuprodigy_header_re} eq ""){
					$prefix_cuprodigy_header="";
				}else{
					if($line =~ /^${cuprodigy_header_re}/){
						$prefix_cuprodigy_header=${&};
						$line=${'};
					}
				}
				&xml_print_raw_datastream(STDOUT,${prefix_logfile},${prefix_cuprodigy_header},${line});
				&xml_print_associative_array(STDERR,${prefix_logfile},${prefix_cuprodigy_header},${line});
			}else{
				print STDOUT ${line},"\n";
				print STDERR ${line},"\n";
			}
		}elsif($line =~ /^<.*>/){
			# Appears to be raw XML, perhaps cut from "ADMIN/dmshomecucuprodigy.log".
			$seq=sprintf("%06.0f",${seq}+1);
			$prefix_logfile=${seq};
			if(${cuprodigy_header_re} eq ""){
				$prefix_cuprodigy_header="";
			}else{
				if($line =~ /^${cuprodigy_header_re}/){
					$prefix_cuprodigy_header=${&};
					$line=${'};
				}
			}
			&xml_print_raw_datastream(STDOUT,${prefix_logfile},${prefix_cuprodigy_header},${line});
			&xml_print_associative_array(STDERR,${prefix_logfile},${prefix_cuprodigy_header},${line});
		}else{
			print STDOUT ${line},"\n";
			print STDERR ${line},"\n";
		}
	}
	exit(0);
}

sub base64_decode{
   local($encoding_base64)=@_;
   local($encoding_text);
   local($composit);
   local($idx,$encoded_length,$remain);
   local($ord1,$ord2,$ord3,$ord4);
   local($tri1,$tri2,$tri3);
	use integer;
	$encoding_base64 =~ s/^[\s\r\n][\s\r\n]*//;
	$encoding_base64 =~ s/[\s\r\n][\s\r\n]*$//;
	if    ($encoding_base64 =~ /[^A-Za-z0-9+\/=]/){
		0;
	}elsif(length($encoding_base64)%4 != 0){
		0;
	}else{
		$idx=0; $encoded_length=length(${encoding_base64});
		$encoding_base64 =~ tr/[A-Za-z0-9+\/=]/[\0-\077\177]/;
		while($idx<$encoded_length){
			$ord1=ord(substr($encoding_base64,$idx+0,1));
			$ord2=ord(substr($encoding_base64,$idx+1,1));
			$ord3=ord(substr($encoding_base64,$idx+2,1));
			$ord4=ord(substr($encoding_base64,$idx+3,1));
			$composit=($ord1<<18)|($ord2<<12)|($ord3<<6)|($ord4<<0);
			$tri1=($composit>>16)&0377;
			$tri2=($composit>>8)&0377;
			$tri3=($composit>>0)&0377;
			if    ($ord4 ne 0177){
				$encoding_text.=pack("ccc",$tri1,$tri2,$tri3);
			}elsif($ord3 ne 0177){
				$encoding_text.=pack("cc",$tri1,$tri2);
			}elsif($ord2 ne 0177){
				$encoding_text.=pack("c",$tri1);
			}
			$idx+=4;
		}
	}
	return(${encoding_text});
}

sub base64_encode{
   local($encoding_text)=@_;
   local($encoding_base64);
   local($idx,$encoded_length,$remain);
   local($composit);
   local($tri1,$tri2,$tri3);
   local($ord1,$ord2,$ord3,$ord4);
	use integer;
	$idx=0; $encoded_length=length(${encoding_text});
	while($idx<$encoded_length){
		$remain=$encoded_length-$idx;
		if(${remain} >= 3){
			$tri1=ord(substr($encoding_text,$idx+0,1));
			$tri2=ord(substr($encoding_text,$idx+1,1));
			$tri3=ord(substr($encoding_text,$idx+2,1));
		}elsif(${remain} >= 2){
			$tri1=ord(substr($encoding_text,$idx+0,1));
			$tri2=ord(substr($encoding_text,$idx+1,1));
			$tri3="";
		}else{
			$tri1=ord(substr($encoding_text,$idx+0,1));
			$tri2="";
			$tri3="";
		}
		$composit=($tri1<<16)|($tri2<<8)|($tri3<<0);
		$ord1=($composit>>18)&0077;
		$ord2=($composit>>12)&0077;
		$ord3=($composit>>6)&0077;
		$ord4=($composit>>0)&0077;
		$encoding_base64.=pack("cccc",$ord1,$ord2,$ord3,$ord4);
		$idx+=3;
	}
	if($tri3 eq ""){ substr($encoding_base64,-1,1)=pack("c",0177); }
	if($tri2 eq ""){ substr($encoding_base64,-2,1)=pack("c",0177); }
	$encoding_base64 =~ tr/[\0-\077\177]/[A-Za-z0-9+\/=]/;
	return(${encoding_base64});
}

sub timestamp{
   my($time)=@_;
   my(@f);
	if(!defined($time) or $time eq ""){
		$time=time();
	}
	@f=localtime($time);
	return(sprintf("%04.0f%02.0f%02.0f%02.0f%02.0f%02.0f",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]));
}

sub min_date{
   # arg(@dates); #
   my($min_date);
   my($idx);
	for($idx=0;$idx<=$#_;$idx++){
		if($min_date eq ""){
			$min_date=$_[$idx];
		}elsif($min_date gt $_[$idx]){
			$min_date=$_[$idx];
		}
	}
	return($min_date);
}

sub max_date{
   # arg(@dates); #
   my($max_date);
   my($idx);
	for($idx=0;$idx<=$#_;$idx++){
		if($max_date eq ""){
			$max_date=$_[$idx];
		}elsif($max_date lt $_[$idx]){
			$max_date=$_[$idx];
		}
	}
	return($max_date);
}

sub filter_to_printable_data{
   my($data)=@_;
   my($idx);
	for($idx=length($data)-1;$idx>=0;$idx--){
		$char=substr($data,$idx,1);
		if($char lt ' ' or $char gt '~'){
			substr($data,$idx,1)="<_".sprintf("%02x",ord($char))."_>";
		}
	}
	return($data);
}

sub line_wrap_80{
   my($indent_width,$data)=@_;
   my($rtrn);
   my($max);
	$max=sprintf("%.0f",80-${indent_width}-2);
	while(${data} ne ""){
		if(${rtrn} ne ""){
			$rtrn.="\n". " " x ${indent_width};
		}
		if(length(${data}) <= ${max}){
			$rtrn.="[".${data}."]";
			$data="";
		}else{
			$rtrn.="[".substr(${data},0,${max})."]";
			$data=substr(${data},${max});
		}
	}
	return(${rtrn});
}

sub strip_account_id_from_desc{	# Used because DMS/HomeCU servers always append ACCOUNTBALANCE.ACCOUNTTYPE and/or LOANBALANCE.LOANNUMBER to the balance description before they are displayed.
   my($desc,$balance_class,$cuprodigy_accttype,$cuprodigy_certlnnum)=@_;
   my($lookfor)="";
	if    (${balance_class} eq "DP"){
		$lookfor=${cuprodigy_accttype};
	}elsif(${balance_class} eq "LN"){
		$lookfor="";	# $lookfor=${cuprodigy_certlnnum};
	}elsif(${balance_class} eq "CC"){
		$lookfor="";	# $lookfor=${cuprodigy_certlnnum};
	}
	$lookfor=~s/^\s\s*//; $lookfor=~s/\s\s*$//;
	if(${lookfor} ne ""){
		$desc=~s/^\s\s*//; $desc=~s/\s\s*$//;
		$desc=~s#^\Q${lookfor}\E[-/\s][-/\s]*##i;
		$desc=~s#[-/\s][-/\s]*\Q${lookfor}\E$##i;
	}
	return(${desc});
}

sub cuprodigy_header{	# CUProdigy's non-XML header
	# ShareTec HomeBanking Realtime Interface (STHBRI)
	# return(
	# 	"<DI>".		# Beginning of record identifiers
	# 	"<IID>".	# Instance ID
	# 	"12345678".	# The IID value for DMS/HomeCU
	# 	"<LEN>".	# Total length of XML section
	# 	sprintf("%08.0f",length($_[0]))
	# );
	return("");	# Nothing unusual since CUProdigy is more normalized.
}

sub cuprodigy_xml_sane_name{
   my($name_value,$default)=@_;
	if(${name_value} =~ /^\s*$/){
		if(defined(${default})){
			$name_value=${default};
		}else{
			$name_value=""; # $name_value="The ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." did not provide a name";
		}
	}else{
		$name_value=~s/^\s\s*//;
	}
	$name_value=&textfilter(${name_value});
	return(${name_value});
}

sub cuprodigy_xml_sane_bal_desc{
   my($desc_value,$default)=@_;
	if(${desc_value} =~ /^\s*$/){
		if(defined(${default})){
			$desc_value=${default};
		}else{
			$desc_value="The ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." did not provide a description";
		}
	}else{
		$desc_value=~s/^\s\s*//;
	}
	$desc_value=&textfilter(${desc_value});
	return(${desc_value});
}

sub cuprodigy_xml_sane_tran_memo{
   my($memo_value,$default)=@_;
	if(${memo_value} =~ /^\s*$/){
		if(defined(${default})){
			$memo_value=${default};
		}else{
			$memo_value="The ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." did not provide a description";
		}
	}else{
		$memo_value=~s/^\s\s*//;
	}
	$memo_value=&textfilter(${memo_value});
	return(${memo_value});
}

sub cuprodigy_xml_null_date{
   my($date_value,$default)=@_;
	if(${date_value} =~ /^\s*$/){
		if(defined(${default})){
			$date_value=${default};
		}else{
			$date_value="19000101";
		}
	}
	return(${date_value});
}

sub cuprodigy_xml_null_datetime{
   my($datetime_value,$default)=@_;
	if(${datetime_value} =~ /^\s*$/){
		if(defined(${default})){
			$datetime_value=${default};
		}else{
			$datetime_value="19000101000000";
		}
	}
	return(${datetime_value});
}

sub cuprodigy_first_name{
    my($cuprodigy_mbname)=@_;
    my($rtrn);
    my(@f);
	@f=split(/,/,$cuprodigy_mbname);
	for($idx=1;$idx<=$#f;$idx++){
		if($rtrn =~ /^\s*$/){
			$rtrn=$f[${idx}];
		}
	}
	if($rtrn eq ""){
		$rtrn=$f[0];
	}
	$rtrn=~s/^\s\s*//;
	$rtrn=~s/\s\s*$//;
	return($rtrn);
}

sub cuprodigy_to_dms_apr{
   local($multiplier,$cuprodigy_rate)=@_;
   local($percent);
   local(@f);
	@f=split(/\./,$cuprodigy_rate);
	if    (sprintf("%.0f",${multiplier}) == 100 or ${multiplier} eq ""){
		$f[1].="00";
		$percent=$f[0].substr($f[1],0,2).".".substr($f[1],2);
	}elsif(sprintf("%.0f",${multiplier}) == 10){
		$f[1].="0";
		$percent=$f[0].substr($f[1],0,1).".".substr($f[1],1);
	}elsif(sprintf("%.0f",${multiplier}) == 1){
		$f[1].="";
		$percent=$f[0].substr($f[1],0,0).".".substr($f[1],0);
	}else{
		$percent=sprintf("%.5f",${percent}*${multiplier});
	}
	$percent=~s/^0*//;
	if($percent=~/^\./){
		$percent="0".$percent;
	}
	$percent=~s/0*$//;
	if($percent=~/\.$/){
		$percent.="0";
	}
	return($percent);
}


#===============================================================================
# CUProdigy XML calls
#===============================================================================

sub cuprodigy_xml_initial_password{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$dmshomecu_initial_password)=@_;
   local($rtrn_error_text);
	if    (!${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__VALIDATE_PASSWORD} and !${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__GET_MEMBER_AUTO_ENROLL_INFO}){
		&logfile("cuprodigy_xml_initial_password(): Initial password method not allowed; the configuration variables \$CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__VALIDATE_PASSWORD and \$CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__GET_MEMBER_AUTO_ENROLL_INFO are disabled, so the INQ initial password value is rejected.");
		$rtrn_error_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
	}elsif(${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__VALIDATE_PASSWORD} and ${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__GET_MEMBER_AUTO_ENROLL_INFO}){
		if(${rtrn_error_text} eq ""){
			&logfile("cuprodigy_xml_initial_password(): Trying to validate initial password using ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method: ValidatePassword\n");
			$rtrn_error_text=&cuprodigy_xml_initial_password__ValidatePassword(@_);
			if(${rtrn_error_text} ne ""){
				&logfile("cuprodigy_xml_initial_password(): Trying to validate initial password using ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method: GetMemberAutoEnrollInfo\n");
				$rtrn_error_text=&cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo(@_);
			}
		}
	}else{
		if(${rtrn_error_text} eq ""){
			if(${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__VALIDATE_PASSWORD}){
				&logfile("cuprodigy_xml_initial_password(): Trying to validate initial password using ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method: ValidatePassword\n");
				$rtrn_error_text=&cuprodigy_xml_initial_password__ValidatePassword(@_);
			}
			if(${CTRL__INITIAL_PASSWORD_CHECK__USE_METHOD__GET_MEMBER_AUTO_ENROLL_INFO}){
				&logfile("cuprodigy_xml_initial_password(): Trying to validate initial password using ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method: GetMemberAutoEnrollInfo\n");
				$rtrn_error_text=&cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo(@_);
			}
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_initial_password__ValidatePassword{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$dmshomecu_initial_password)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($tmp_ccyymmdd);
   local($cuprodigy_xml_description);
   local(@key_prefix,$key_prefix);
   local($seq,$seq_key_prefix);
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ValidatePassword: ".join(", ",${cuprodigy_xml_request_membernumber},${dmshomecu_initial_password});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&ValidatePassword("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ValidatePassword: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_initial_password__ValidatePassword(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ValidatePassword: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					# $rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ValidatePassword: ${error}");
					&logfile("cuprodigy_xml_initial_password__ValidatePassword(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ValidatePassword: ${error}\n");
					$rtrn_error_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("","code+message");
			if(${error} ne ""){
				# $rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ValidatePassword: Response: ${error}");
				&logfile("cuprodigy_xml_initial_password__ValidatePassword(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ValidatePassword: Response: ${error}\n");
				$rtrn_error_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"ValidatePassword",${cuprodigy_xml_request_membernumber},${dmshomecu_initial_password}) if ${rtrn_error_text} ne "";
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$dmshomecu_initial_password)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($tmp_ccyymmdd);
   local($cuprodigy_xml_description);
   local(@key_prefix,$key_prefix);
   local($seq,$seq_key_prefix);
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML GetMemberAutoEnrollInfo: ".join(", ",${cuprodigy_xml_request_membernumber},${dmshomecu_initial_password});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&GetMemberAutoEnrollInfo("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					# $rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: ${error}");
					&logfile("cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: ${error}\n");
					$rtrn_error_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
				}
			}
		}
		if(0){
			# The GetMemberAutoEnrollInfo response does not include the XML branch <Envelope><Body><submitMessageResponse><return><response><transaction>.
			if(${rtrn_error_text} eq ""){
				$error=&validate_Body_message_transaction_RS("","code+message");
				if(${error} ne ""){
					# $rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: Response: ${error}");
					&logfile("cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: Response: ${error}\n");
					$rtrn_error_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if($XML_DATA_BY_TAG_INDEX{${XML_KEY_SOAP_BODY},"submitMessageResponse",${XML_SINGLE},"return",${XML_SINGLE},"response",${XML_SINGLE},"memberInformation",${XML_SINGLE},"memberNumber",${XML_SINGLE}} ne ${cuprodigy_xml_request_membernumber}){
				&logfile("cuprodigy_xml_initial_password__GetMemberAutoEnrollInfo(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberAutoEnrollInfo: Failure in XML body <submitMessageResponse><return><response><memberInformation> where <memberNumber> value does not match expected value of: ${cuprodigy_xml_request_membernumber}\n");
				$rtrn_error_text=join("\t","001",$CTRL__STATUS_TEXT{"001"});
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"GetMemberAutoEnrollInfo",${cuprodigy_xml_request_membernumber},${dmshomecu_initial_password}) if ${rtrn_error_text} ne "";
	}
	return(${rtrn_error_text});
}

sub date_min{
   my(@dates)=@_;
   my($rtrn);
	while(@dates > 0){
		if    ($rtrn eq ""){
			$rtrn=$dates[0];
		}elsif($rtrn gt $dates[0]){
			$rtrn=$dates[0];
		}
		shift(@dates);
	}
	return(${rtrn});
}

sub convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc{
   my($cuprodigy_accountNumber)=@_;
   my($dms_mb,$dms_dplncc);
	if($cuprodigy_accountNumber =~ /......$/){	# Regexp matches 4 character <accountType> value followed by a 2 digit sequence.
		$dms_mb=$`;
		$dms_dplncc=$&.$';
		$dms_dplncc=~s/..$/:$&/;
		$dms_dplncc=~s/ *:/:/;
	}else{
		($dms_mb,$dms_dplncc)=(${cuprodigy_accountNumber},${cuprodigy_accountNumber});	# Fake to return non-blank (though still invalid) values when the received argument is of incorrect format; the abnormality (and likely some failure) should end-up getting recorded in a log file.
	}
	return(${dms_mb},${dms_dplncc});
}

sub convert_dms_mb_and_dplncc_to_cuprodigy_accountNumber{
   my($dms_mb,$dms_dplncc)=@_;
   my($cuprodigy_accountNumber);
   my($cuprodigy_accountType,$cuprodigy_sequence);
	if(${CONF__XJO__USE}){
		if($dms_dplncc =~ /:..@\d\d*$/){	# Regexp matches 2 digit sequence followed by XJO '@' overloaded member number.
			if($dms_dplncc =~ /@\d\d*$/){	# Regexp matches XJO '@' overloaded member number.
				$dms_dplncc=$`;
				$dms_mb=$&.$';
				$dms_mb=~s/^@//;
			}
		}
	}
	if($dms_dplncc =~ /:..$/){	# Regexp matches 2 digit sequence
		$cuprodigy_accountType=$`;
		$cuprodigy_sequence=$&.$';
		$cuprodigy_sequence=~s/^://;
		if(length($cuprodigy_accountType) < 4){
			$cuprodigy_accountType=substr("${cuprodigy_accountType}    ",0,4);
		}
		$cuprodigy_accountNumber=join("",${dms_mb},${cuprodigy_accountType},${cuprodigy_sequence});
	}else{
		$cuprodigy_accountNumber=join("",${dms_mb},${dms_dplncc});	# Fake to return non-blank (though still invalid) value when the received arguments are of incorrect format; the abnormality (and likely some failure) should end-up getting recorded in a log file.
	}
	return(${cuprodigy_accountNumber});
}

sub convert_dms_dplncc_to_cuprodigy_accountType_and_accountSeq{
   my($dms_dplncc)=@_;
   my($cuprodigy_accountType,$cuprodigy_accountSeq);
   my($tmp);
	($tmp=&convert_dms_mb_and_dplncc_to_cuprodigy_accountNumber("1",${dms_dplncc}))=~s/^1//;
	if(length(${tmp}) == 6){
		($cuprodigy_accountType=substr(${tmp},0,4))=~s/ *$//;
		$cuprodigy_accountSeq=substr(${tmp},-2,2);
	}
	return(${cuprodigy_accountType},${cuprodigy_accountSeq});
}

sub convert_dms_dplncc_to_cuprodigy_accountType{
	return((&convert_dms_dplncc_to_cuprodigy_accountType_and_accountSeq(@_))[0]);
}

sub convert_dms_dplncc_to_cuprodigy_accountSeq{
	return((&convert_dms_dplncc_to_cuprodigy_accountType_and_accountSeq(@_))[1]);
}

sub cuprodigy_xml_balances_and_history{
   local($full_inquiry,$cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$dmshomecu_initial_password,$beg_ccyymmdd_dp,$beg_ccyymmdd_ln,$record_messages_in_logfile,$single_dp_ln,$single_member,$single_account,$single_cert)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($using_cuprodigy_method);
   local(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST);
   local(%XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS,$xml_mb_xjo_overloaded_account_dup_detected,$xml_mb_xjo_overloaded_account_dup_save_xjo_beg_ccyymmdd_dp,$xml_mb_xjo_overloaded_account_dup_save_xjo_beg_ccyymmdd_ln);
   local(%XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED);
   local(@xmldata_accumulated);
   local($xjo_cuprodigy_memberNumber,$xjo_cuprodigy_accountCategory,$xjo_cuprodigy_accountType,$xjo_cuprodigy_accountNumber,$xjo_cuprodigy_transactionsRestricted,$xjo_cuprodigy_accountNumber__mb,$xjo_cuprodigy_accountNumber__dplncc,$xjo_dp_ln_cc,$xjo_dms_xjo_overloaded_composit);
   local($xjo_beg_ccyymmdd_dp,$xjo_beg_ccyymmdd_ln);
	if($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
		$using_cuprodigy_method="${cuprodigy_method_used_for_inquiry_of_balances_only}";
		$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used_for_inquiry_of_balances_only}: ".join(", ",${cuprodigy_xml_request_membernumber});
	}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
		$using_cuprodigy_method="${cuprodigy_method_used_for_inquiry_of_single_dp}";
		if($single_member =~ /^\s*$/){ $single_member=${cuprodigy_xml_request_membernumber}; }
		$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used_for_inquiry_of_single_dp}: ".join(", ",${cuprodigy_xml_request_membernumber},${single_dp_ln},${single_member},${single_account},${single_cert});
	}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
		$using_cuprodigy_method="${cuprodigy_method_used_for_inquiry_of_single_ln}";
		if($single_member =~ /^\s*$/){ $single_member=${cuprodigy_xml_request_membernumber}; }
		$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used_for_inquiry_of_single_ln}: ".join(", ",${cuprodigy_xml_request_membernumber},${single_dp_ln},${single_member},${single_account});
	}else{
		$using_cuprodigy_method="${cuprodigy_method_used_for_inquiry_of_everything}";
		$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used_for_inquiry_of_everything}: ".join(", ",${cuprodigy_xml_request_membernumber});
	}
	if(${rtrn_error_text} eq ""){
		if    ($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
			($header,$xmldata,$status,$soap_exception)=&post_request(&AccountInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password},${CONF__PLASTIC_CARD__USE}),"filternulls,filternonprintables,parsexml,limitedreturn","");
			$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
			if(${rtrn_error_text} ne ""){
				if(${CONF__PLASTIC_CARD__USE}){
					($header,$xmldata,$status,$soap_exception)=&post_request(&AccountInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password},sprintf("%.0f",0*${CONF__PLASTIC_CARD__USE})),"filternulls,filternonprintables,parsexml,limitedreturn","");
					$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
					if(${rtrn_error_text} eq ""){
						&logfile("cuprodigy_xml_balances_and_history(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML AccountInquiry: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Skipping Plastic Card data so as to counter a known critical failure where AccountInquiry method request including <getCardInfo> option has likely caused a critical failure when a member has a card with an \"issue date\" or an \"expiration date\" value \"0000-00-00\", which the Java language used by ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." can not load as a \"date\" value.\n") if ${record_messages_in_logfile};
						push(@INQ_RESPONSE_NOTES,join("\t","PC",${cuprodigy_xml_request_membernumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML AccountInquiry: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Skipping Plastic Card data so as to counter a known critical failure where AccountInquiry method request including <getCardInfo> option has likely caused a critical failure when a member has a card with an \"issue date\" or an \"expiration date\" value \"0000-00-00\", which the Java language used by ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." can not load as a \"date\" value.\n"));
					}
				}
			}
		}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
			($header,$xmldata,$status,$soap_exception)=&post_request(&AccountDetailInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password},${single_dp_ln},${single_member},${single_account},${single_cert},${beg_ccyymmdd_dp}),"filternulls,filternonprintables,parsexml,limitedreturn","");
			$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
			($header,$xmldata,$status,$soap_exception)=&post_request(&AccountDetailInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password},${single_dp_ln},${single_member},${single_account},${single_cert},${beg_ccyymmdd_ln}),"filternulls,filternonprintables,parsexml,limitedreturn","");
			$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		}else{
			($header,$xmldata,$status,$soap_exception)=&post_request(&Inquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password},&date_min(${beg_ccyymmdd_dp},${beg_ccyymmdd_ln}),${CONF__PLASTIC_CARD__USE}),"filternulls,filternonprintables,parsexml,limitedreturn","");
			$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: Inquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
			if(${rtrn_error_text} ne "" and !${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12) and post-"Jetty" API version (after 2022-12-12)
				if(${CONF__PLASTIC_CARD__USE}){
					($header,$xmldata,$status,$soap_exception)=&post_request(&Inquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password},&date_min(${beg_ccyymmdd_dp},${beg_ccyymmdd_ln}),sprintf("%.0f",0*${CONF__PLASTIC_CARD__USE})),"filternulls,filternonprintables,parsexml,limitedreturn","");
					$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: Inquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
					if(${rtrn_error_text} eq ""){
						&logfile("cuprodigy_xml_balances_and_history(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML Inquiry: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Skipping Plastic Card data so as to counter a known critical failure where Inquiry method request including <getCardInfo> option has likely caused a critical failure when a member has a card with an \"issue date\" or an \"expiration date\" value \"0000-00-00\", which the Java language used by ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." can not load as a \"date\" value.\n") if ${record_messages_in_logfile};
						push(@INQ_RESPONSE_NOTES,join("\t","PC",${cuprodigy_xml_request_membernumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML Inquiry: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Skipping Plastic Card data so as to counter a known critical failure where Inquiry method request including <getCardInfo> option has likely caused a critical failure when a member has a card with an \"issue date\" or an \"expiration date\" value \"0000-00-00\", which the Java language used by ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." can not load as a \"date\" value.\n"));
					}
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		if(${dmshomecu_initial_password} ne ""){
			if($CUSTOM{"custom_password.pi"}>0){
				if(&custom_password__validate(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password})){
					1;
				}else{
					if(${rtrn_error_text} ne ""){ $rtrn_error_text.="\n"; }
					$rtrn_error_text.=join("\t","002",${CTRL__ERROR_NNN_PREFIX__DMS_NORMAL}.$CTRL__STATUS_TEXT{"002"});
				}
			}else{
				# if(${rtrn_error_text} ne ""){ $rtrn_error_text.="\n"; }
				# $rtrn_error_text.=join("\t","002",${CTRL__ERROR_NNN_PREFIX__DMS_ABNORMAL}."No initial password method configured.");
				$rtrn_error_text=&cuprodigy_xml_check_initial_password(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${dmshomecu_initial_password});
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
			if    ($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io){
				1;
			}elsif($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN}\E$/io){
				1;
			}else{
				if($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__ONLY_BALANCES}\E$/io){
					$xjo_beg_ccyymmdd_dp="";	# Trick the AccountDetailInquiry() (which uses message_xml_Request_AccountDetailInquiry() to generate AccountDetailInquiry method request) to return only balance data.
					$xjo_beg_ccyymmdd_ln="";	# Trick the AccountDetailInquiry() (which uses message_xml_Request_AccountDetailInquiry() to generate AccountDetailInquiry method request) to return only balance data.
				}else{
					$xjo_beg_ccyymmdd_dp=${beg_ccyymmdd_dp};
					$xjo_beg_ccyymmdd_ln=${beg_ccyymmdd_ln};
				}
				($rtrn_error_text,@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST)=&xjo_overloaded_account_list(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${record_messages_in_logfile});
				if(${rtrn_error_text} eq ""){
					while(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST > 0){
						$xml_mb_xjo_overloaded_account_dup_detected=( $XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{$XML_MB_XJO_OVERLOADED_ACCOUNT_LIST[0]} ? 1 : 0 );
						$XML_MB_XJO_OVERLOADED_ACCOUNT_KEYS{$XML_MB_XJO_OVERLOADED_ACCOUNT_LIST[0]}++;
						($xjo_cuprodigy_memberNumber,$xjo_cuprodigy_accountCategory,$xjo_cuprodigy_accountType,$xjo_cuprodigy_accountNumber,$xjo_cuprodigy_transactionsRestricted,$xjo_dp_ln_cc,$xjo_cuprodigy_accountNumber__mb,$xjo_cuprodigy_accountNumber__dplncc,$xjo_dms_xjo_overloaded_composit)=split(/\t/,shift(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST));
						if(${xml_mb_xjo_overloaded_account_dup_detected}){
							# Alas, when processing XJO/Overloaded/"@", the GetMemberRelatedAccounts duplicate balance records have to have duplicate AccountDetailInquiry responses passed through to cuprodigy_xml_balances_and_history__parse_balances() for it to properly populate %ACCOUNTLIST_ACCOUNTINFO_KEYS and then report (log) that duplicate XJO/Overloaded/"@" balance records were found.
							$xml_mb_xjo_overloaded_account_dup_save_xjo_beg_ccyymmdd_dp=${xjo_beg_ccyymmdd_dp}; $xjo_beg_ccyymmdd_dp=( ${xjo_beg_ccyymmdd_dp} =~ /^\s*$/ ? "" : "99991231" );	# Override cutoff date so XJO/Overloaded/"@" duplicate AccountDetailInquiry call does not include data for transaction history rows
							$xml_mb_xjo_overloaded_account_dup_save_xjo_beg_ccyymmdd_ln=${xjo_beg_ccyymmdd_ln}; $xjo_beg_ccyymmdd_ln=( ${xjo_beg_ccyymmdd_ln} =~ /^\s*$/ ? "" : "99991231" );	# Override cutoff date so XJO/Overloaded/"@" duplicate AccountDetailInquiry call does not include data for transaction history rows
						}
						$XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED{${xjo_cuprodigy_memberNumber},${xjo_cuprodigy_accountNumber}}=${xjo_cuprodigy_transactionsRestricted};
						$XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED{${xjo_cuprodigy_memberNumber},${xjo_dms_xjo_overloaded_composit}}=${xjo_cuprodigy_transactionsRestricted};
						if    ($xjo_dp_ln_cc =~ /^DP$/i){
							($header,$xmldata,$status,$soap_exception)=&post_request(&AccountDetailInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"",${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP},${xjo_cuprodigy_accountNumber__mb},${xjo_cuprodigy_accountNumber__dplncc},"0",${xjo_beg_ccyymmdd_dp}),"filternulls,filternonprintables,parsexml:append,limitedreturn","");
							$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
							if(${rtrn_error_text} eq ""){
								$error=&validate_Body_message_error_RS("");
								if(${error} ne ""){
									if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
										$rtrn_error_text=join("\t","999",${error});
										$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
									}else{
										$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ${error}");
									}
								}
							}
							if(${rtrn_error_text} eq ""){
								$error=&validate_Body_message_transaction_RS("");
								if(${error} ne ""){
									$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: Response: ${error}");
								}
							}
							push(@xmldata_accumulated,${xmldata}) if ${rtrn_error_text} eq "";	# Saving the results from the XJO/Overloaded AccountInquiry.
						}elsif($xjo_dp_ln_cc =~ /^LN$/i){
							($header,$xmldata,$status,$soap_exception)=&post_request(&AccountDetailInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"",${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_LN},${xjo_cuprodigy_accountNumber__mb},${xjo_cuprodigy_accountNumber__dplncc},"",${xjo_beg_ccyymmdd_ln}),"filternulls,filternonprintables,parsexml:append,limitedreturn","");
							$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
							if(${rtrn_error_text} eq ""){
								$error=&validate_Body_message_error_RS("");
								if(${error} ne ""){
									if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
										$rtrn_error_text=join("\t","999",${error});
										$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
									}else{
										$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: ${error}");
									}
								}
							}
							if(${rtrn_error_text} eq ""){
								$error=&validate_Body_message_transaction_RS("");
								if(${error} ne ""){
									$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: Response: ${error}");
								}
							}
							push(@xmldata_accumulated,${xmldata}) if ${rtrn_error_text} eq "";	# Saving the results from the XJO/Overloaded AccountInquiry.
						}else{
							&logfile("cuprodigy_xml_balances_and_history(): Not yet coded to handle xjo_overloaded_account_list() returned value for \$xjo_dp_ln_cc of '${xjo_dp_ln_cc}'; skipping the XJO/Overloaded balance record for '${xjo_cuprodigy_accountNumber}'.\n") if ${record_messages_in_logfile};
						}
						if(${xml_mb_xjo_overloaded_account_dup_detected}){
							# Alas, when processing XJO/Overloaded/"@", the GetMemberRelatedAccounts duplicate balance records have to have duplicate AccountDetailInquiry responses passed through to cuprodigy_xml_balances_and_history__parse_balances() for it to properly populate %ACCOUNTLIST_ACCOUNTINFO_KEYS and then report (log) that duplicate XJO/Overloaded/"@" balance records were found.
							$xjo_beg_ccyymmdd_dp=${xml_mb_xjo_overloaded_account_dup_save_xjo_beg_ccyymmdd_dp};	# Undo the override cutoff date done so XJO/Overloaded/"@" duplicate AccountDetailInquiry call did not include data for transaction history rows
							$xjo_beg_ccyymmdd_ln=${xml_mb_xjo_overloaded_account_dup_save_xjo_beg_ccyymmdd_ln};	# Undo the override cutoff date done so XJO/Overloaded/"@" duplicate AccountDetailInquiry call did not include data for transaction history rows
						}
						last if ${rtrn_error_text} ne "";
					}
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		$rtrn_error_text=&cuprodigy_xml_balances_and_history__parse_email(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${record_messages_in_logfile});
	}
	if(${rtrn_error_text} eq ""){
		$rtrn_error_text=&cuprodigy_xml_balances_and_history__parse_balances(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${record_messages_in_logfile},${single_dp_ln},${single_member},${single_account},${single_cert});
	}
	if(${rtrn_error_text} eq ""){
		if(${CONF__PLASTIC_CARD__USE}){
			$rtrn_error_text=&cuprodigy_xml_balances_and_history__parse_plastic_cards(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"",${record_messages_in_logfile},${single_dp_ln},${single_member},${single_account},${single_cert});
		}
	}
	if(${full_inquiry} > 0){
		if(${rtrn_error_text} eq ""){
			$rtrn_error_text=&cuprodigy_xml_balances_and_history__parse_holds(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${record_messages_in_logfile},${single_dp_ln},${single_member},${single_account},${single_cert});
		}
		if(${rtrn_error_text} eq ""){
			if(${beg_ccyymmdd_dp} ne "" or ${beg_ccyymmdd_ln} ne ""){	# Do not parse history (do not undefine current @XML_MB_DP_HIST and @XML_MB_LN_HIST and @XML_MB_CC_HIST and @XML_MB_HOLDS and @XML_MB_PLASTIC_CARDS and @XML_MB_PLASTIC_CARDS_WIP) when is mode of "Query ${mbnum}: ${cuprodigy_method_used} (after)"
				$rtrn_error_text=&cuprodigy_xml_balances_and_history__parse_history(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${beg_ccyymmdd_dp},${beg_ccyymmdd_ln},${record_messages_in_logfile},${single_dp_ln},${single_member},${single_account},${single_cert});
			}
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_balances_and_history__parse_email{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$record_messages_in_logfile)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   # local($cuprodigy_xml_description);	# Set in cuprodigy_xml_balances_and_history()
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_EMAIL
	#
	undef(@XML_MB_EMAIL);
	for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
		$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
		@key_prefix=split(/$;/,$key_L01);
		for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
			$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
			@key_prefix=split(/$;/,$key_L02);
			for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
				$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
				@key_prefix=split(/$;/,$key_L03);
				for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
					$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
					@key_prefix=split(/$;/,$key_L04);
					for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
						$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
						@key_prefix=split(/$;/,$key_L05);
						for($tag_L06="memberInformation",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
							$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
							@key_prefix=split(/$;/,$key_L06);
							$key_prefix=join($;,@key_prefix);
							$cuprodigy_membernumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberNumber",${XML_SINGLE})};
							$cuprodigy_email=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"email",${XML_SINGLE})};
							if(${cuprodigy_membernumber} eq ${cuprodigy_xml_request_membernumber}){
								push(@XML_MB_EMAIL,join("\t",
									${cuprodigy_membernumber},
									${cuprodigy_email}
								));
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
		pop(@key_prefix); pop(@key_prefix);
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_balances_and_history__parse_balances{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$record_messages_in_logfile,$single_dp_ln,$single_member,$single_account,$single_cert)=@_;
   local($rtrn_error_text);
   local($max_closed_ccyymmdd_dp,$max_closed_ccyymmdd_ln);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($tmp_ccyymmdd);
   local($flag_exclude);
   local($tmp_ln_year_make_model_1,$tmp_ln_year_make_model_2);
   # local($cuprodigy_xml_description);	# Set in cuprodigy_xml_balances_and_history()
   local($using_cuprodigy_method);
   local($xfer_excl_reason);
   local($xml_ref_1,$xml_ref_2,$xml_ref_3);
   local(@XJO_CURRENT_LIST);
   local(%ACCOUNTLIST_ACCOUNTINFO_KEYS,$accountlist_accountinfo_key);
   local(@STACK_LOGFILE_ENTRIES);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
   local($key,$idx,@f,$prev_mb,$curr_mb,$curr_cc,$curr_cc_seq,$curr_cc_last4);	# Used to manipulate %XML_MB_CC_TO_UNIQ and %XML_MB_CC_FROM_UNIQ
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_UNIQID
	#	@XML_MB_DP_UNIQID
	#	@XML_MB_LN_UNIQID
	#	@XML_MB_CC_UNIQID
	#	%XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY
	#	@XML_MB_DP_BALS
	#	@XML_MB_LN_BALS
	#	@XML_MB_CC_BALS, %XML_MB_CC_TO_UNIQ, %XML_MB_CC_FROM_UNIQ
	#	@XML_MB_XJO
	#	@XML_MB_DP_GROUPS
	#	@XML_MB_LN_GROUPS
	#	@XML_MB_CC_GROUPS
	#	@XML_MB_DP_ATTRS
	#	@XML_MB_LN_ATTRS
	#	@XML_MB_CC_ATTRS
	#	@XML_MB_DP_ACCESS_INFO
	#	@XML_MB_LN_ACCESS_INFO
	#	@XML_MB_CC_ACCESS_INFO
	#	@XML_MB_DP_EXPIRED
	#	@XML_MB_LN_EXPIRED
	#	@XML_MB_CC_EXPIRED
	#	@XML_MB_LN_PAYOFF
	#	@XML_MB_CC_PAYOFF
	#
	undef(@XML_MB_UNIQID);
	undef(@XML_MB_DP_UNIQID);
	undef(@XML_MB_LN_UNIQID);
	undef(@XML_MB_CC_UNIQID);
	undef(%XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY);
	undef(@XML_MB_DP_BALS);
	undef(@XML_MB_LN_BALS);
	undef(@XML_MB_CC_BALS); undef(%XML_MB_CC_TO_UNIQ); undef(%XML_MB_CC_FROM_UNIQ);
	undef(@XML_MB_XJO);
	undef(@XML_MB_DP_GROUPS);
	undef(@XML_MB_LN_GROUPS);
	undef(@XML_MB_CC_GROUPS);
	undef(@XML_MB_DP_ATTRS);
	undef(@XML_MB_LN_ATTRS);
	undef(@XML_MB_CC_ATTRS);
	undef(@XML_MB_DP_ACCESS_INFO);
	undef(@XML_MB_LN_ACCESS_INFO);
	undef(@XML_MB_CC_ACCESS_INFO);
	undef(@XML_MB_DP_EXPIRED);
	undef(@XML_MB_LN_EXPIRED);
	undef(@XML_MB_CC_EXPIRED);
	undef(@XML_MB_LN_PAYOFF);
	undef(@XML_MB_CC_PAYOFF);
	$max_closed_ccyymmdd_dp=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__BAL_CLOSED_DAYS_DP}*24*60*60));
	$max_closed_ccyymmdd_ln=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__BAL_CLOSED_DAYS_LN}*24*60*60));
	$cuprodigy_memberInformation_memberNumber="";
	$cuprodigy_memberInformation_entityId="";
	$cuprodigy_memberInformation_pinNumber="";
	for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
		$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
		@key_prefix=split(/$;/,$key_L01);
		for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
			$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
			@key_prefix=split(/$;/,$key_L02);
			for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
				$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
				@key_prefix=split(/$;/,$key_L03);
				for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
					$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
					@key_prefix=split(/$;/,$key_L04);
					for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
						$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
						@key_prefix=split(/$;/,$key_L05);
						for($tag_L06="memberInformation",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
							$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
							@key_prefix=split(/$;/,$key_L06);
							$key_prefix=join($;,@key_prefix);
							if(${cuprodigy_xml_request_membernumber} eq $XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberNumber",${XML_SINGLE})}){
								$cuprodigy_memberInformation_memberNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberNumber",${XML_SINGLE})};
								$cuprodigy_memberInformation_entityId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"entityId",${XML_SINGLE})};
								$cuprodigy_memberInformation_pinNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_perfix,join($;,@key_prefix),"pinNumber",${XML_SINGLE})};
							}
							push(@XML_MB_UNIQID,join("\t",
								${cuprodigy_xml_request_membernumber},
								join(":",${cuprodigy_memberInformation_memberNumber},"Member",${cuprodigy_memberInformation_entityId},"")
							));
							pop(@XML_MB_UNIQID) if @XML_MB_UNIQID > 1 and $XML_MB_UNIQID[$#XML_MB_UNIQID-1] eq $XML_MB_UNIQID[$#XML_MB_UNIQID-0];	# Compensate for quirk of reusing cuprodigy_xml_balances_and_history__parse_balances() for methods "Inquiry" (for member's own sub-accounts) and method "AccountDetailInquiry" (for XJO/Overloaded/@ sub-accounts as triggered by method "GetMemberRelatedAccounts").
							pop(@key_prefix); pop(@key_prefix);
						}
						for($tag_L06="accounts",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
							$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
							@key_prefix=split(/$;/,$key_L06);
							for($tag_L07="account",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
								$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
								@key_prefix=split(/$;/,$key_L07);
								$key_prefix=join($;,@key_prefix);
								undef(@STACK_LOGFILE_ENTRIES);
								$DPLNCC="";
								$cuprodigy_accountCategory=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountCategory",${XML_SINGLE})};
								$cuprodigy_accountType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountType",${XML_SINGLE})};
								$cuprodigy_accountId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountId",${XML_SINGLE})};
								$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
								$cuprodigy_description=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"description",${XML_SINGLE})};
								$cuprodigy_transactionsRestricted=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"transactionsRestricted",${XML_SINGLE})};
								$cuprodigy_textBankAccountDesc=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"textBankAccountDesc",${XML_SINGLE})};
								$cuprodigy_homeBankAccountDesc=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"homeBankAccountDesc",${XML_SINGLE})};
								$cuprodigy_openStatus=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openStatus",${XML_SINGLE})};
								$cuprodigy_lastTranDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastTranDate",${XML_SINGLE})};
								if(${CONF__XJO__USE}){
									if($XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}} ne ""){
										if($XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}} ne ${cuprodigy_transactionsRestricted}){
											&logfile("cuprodigy_xml_balances_and_history__parse_balances(): Forcing change of XJO/Overloaded '${cuprodigy_accountNumber}' value for <transactionsRestricted> from '${cuprodigy_transactionsRestricted}' (as was extracted from AccountDetailInquiry method response) with '".$XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}}."' (as was extracted from GetMemberRelatedAccounts method response).\n") if ${record_messages_in_logfile};
										$cuprodigy_transactionsRestricted=$XML_MB_XJO_OVERLOADED_ACCOUNT_TRANSACTIONSRESTRICTED{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}};
										}
									}
								}
								$XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${cuprodigy_accountType}}=${cuprodigy_accountCategory};
								$DPLNCC="";
								if    ($configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} ne ""){
									$DPLNCC="CC";
								}elsif(&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_XX__CUPRODIGY},"",1)){
									if    (&list_found(${cuprodigy_accountType},${CTRL__REMAP_LIST_ACCOUNTTYPE_DP__CUPRODIGY},"",1)){
										$DPLNCC="DP";
									}elsif(&list_found(${cuprodigy_accountType},${CTRL__REMAP_LIST_ACCOUNTTYPE_LN__CUPRODIGY},"",1)){
										$DPLNCC="LN";
									}else{
										$DPLNCC="";
										if(${record_messages_in_logfile}){
											($xml_ref_1="<".join("><",split(/$;/,$key_prefix),"accountCategory").">")=~s/<[0-9][0-9]*>//g;
											($xml_ref_2="<".join("><",split(/$;/,$key_prefix),"accountType").">")=~s/<[0-9][0-9]*>//g;
											($xml_ref_3="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
											&logfile("cuprodigy_xml_balances_and_history__parse_balances(): Modify the configuration file to include a configure_account_by_cuprodigy_type() call to handle ${CTRL__SERVER_REFERENCE__CUPRODIGY} where ".${xml_ref_1}." is '".${cuprodigy_accountCategory}."' and ".${xml_ref_2}." is '".${cuprodigy_accountType}."' and ".${xml_ref_3}." is '".${cuprodigy_accountNumber}."'\n");
										}
									}
								}elsif(&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__CUPRODIGY},"",1)){
									$DPLNCC="DP";
								}elsif(&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__CUPRODIGY},"",1)){
									$DPLNCC="LN";
								}elsif($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableBalance",${XML_SINGLE})} ne ""){	# Implies DP balance record
									$DPLNCC="DP";
								}elsif($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payoff",${XML_SINGLE})} ne "" or $XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openingBalance",${XML_SINGLE})} ne ""){	# Implies LN balance record
									$DPLNCC="LN";
								}else{
									$DPLNCC="";
								}
								($flag_exclude,$cuprodigy_openStatus,$cuprodigy_lastTranDate)=&cuprodigy_xml_balances_apply_limits__eval_openStatus_lastTranDate(${cuprodigy_xml_request_membernumber},${DPLNCC},${cuprodigy_openStatus},${cuprodigy_lastTranDate});
								if(${flag_exclude}){
									$dms_accountnumber=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[0];
									if    ($DPLNCC =~ /^DP$/i){
										$dms_accounttype=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[1];
										$dms_certnumber="0";
										if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
										}
										if(${CONF__XJO__USE} && ${dms_accountnumber} ne ${cuprodigy_xml_request_membernumber}){
											($dms_accountnumber,$dms_accounttype)=&join_dms_xjo_overloaded_composit(${cuprodigy_xml_request_membernumber},${dms_accountnumber},${dms_accounttype});
										}
										push(@XML_MB_DP_EXPIRED,join("\t",${dms_accountnumber},${dms_accounttype},${dms_certnumber}));
									}elsif($DPLNCC =~ /^LN$/i or $DPLNCC =~ /^CC$/i){
										$dms_loannumber=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[1];
										push(@XML_MB_LN_EXPIRED,join("\t",${dms_accountnumber},${dms_loannumber}));
									}elsif($DPLNCC =~ /^CC$/i){
										$dms_loannumber=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[1];
										push(@XML_MB_CC_EXPIRED,join("\t",${dms_accountnumber},${dms_loannumber}));
									}
								}else{
									if($DPLNCC =~ /^DP$/i){
										$cuprodigy_availableBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableBalance",${XML_SINGLE})};
										$cuprodigy_currentBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"currentBalance",${XML_SINGLE})};
										$cuprodigy_YTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"YTDInterest",${XML_SINGLE})};
										$cuprodigy_LYTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"LYTDInterest",${XML_SINGLE})};
										if(1){
											# DP Share Drafts
											$cuprodigy_checkDigit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"checkDigit",${XML_SINGLE})};
										}
										if(1){
											# DP Certificates
											$cuprodigy_maturityDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"maturityDate",${XML_SINGLE})};
											$cuprodigy_dividendRate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"dividendRate",${XML_SINGLE})};
											$cuprodigy_termInMonths=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"termInMonths",${XML_SINGLE})};
											$cuprodigy_certType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"certType",${XML_SINGLE})};
										}
									}elsif($DPLNCC =~ /^LN$/i){
										$cuprodigy_currentBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"currentBalance",${XML_SINGLE})};
										$cuprodigy_currentBalance=sprintf("%.2f",0-${cuprodigy_currentBalance}) if $configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} eq "3rdparty-nonsweep";	# CUProdigy treats (non-sweep and sweep) 3rdparty LNs as a DP, but the sign of the balance amount is backwards when not a "3rdparty-sweep".
										$cuprodigy_payoff=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payoff",${XML_SINGLE})};
										$cuprodigy_YTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"YTDInterest",${XML_SINGLE})};
										$cuprodigy_LYTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"LYTDInterest",${XML_SINGLE})};
										$cuprodigy_lastPaymentDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastPaymentDate",${XML_SINGLE})};
										$cuprodigy_nextPaymentDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nextPaymentDate",${XML_SINGLE})};
										$cuprodigy_lastPaymentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastPaymentAmount",${XML_SINGLE})};
										$cuprodigy_unpaidInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"unpaidInterest",${XML_SINGLE})};
										$cuprodigy_paymentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"paymentAmount",${XML_SINGLE})};
										$cuprodigy_partialPayment=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"partialPayment",${XML_SINGLE})};
										$cuprodigy_delinquentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"delinquentAmount",${XML_SINGLE})};
										$cuprodigy_paymentsPerYear=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"paymentsPerYear",${XML_SINGLE})};
										$cuprodigy_maturityDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"maturityDate",${XML_SINGLE})};
										$cuprodigy_interestRate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"interestRate",${XML_SINGLE})};
										$cuprodigy_creditLimit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"creditLimit",${XML_SINGLE})};
										$cuprodigy_availableCreditLimit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableCreditLimit",${XML_SINGLE})};
										$cuprodigy_openingBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openingBalance",${XML_SINGLE})};
										$cuprodigy_make=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"make",${XML_SINGLE})};
										$cuprodigy_model=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"model",${XML_SINGLE})};
										$cuprodigy_vin=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"vin",${XML_SINGLE})};
										$cuprodigy_year=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"year",${XML_SINGLE})};
									}elsif($DPLNCC =~ /^CC$/i){
										$cuprodigy_currentBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"currentBalance",${XML_SINGLE})};
										$cuprodigy_currentBalance=sprintf("%.2f",0-${cuprodigy_currentBalance}) if $configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} eq "offbook-nonsweep";	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, but the sign of the balance amount is backwards when not a "offbook-sweep".
										$cuprodigy_payoff=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payoff",${XML_SINGLE})};
										# $cuprodigy_payoff=${cuprodigy_currentBalance} if $configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} eq "loan" and $cuprodigy_payoff =~ /^\s*$/;	# Just in case CUProdigy failes to include "payoff" even though the loan CCs is a native loan.
										$cuprodigy_payoff=${cuprodigy_currentBalance} if $configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} eq "offbook-nonsweep" and $cuprodigy_payoff =~ /^\s*$/;	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, so for "non-sweep" offbook there likely is no "payoff" in the XML.
										$cuprodigy_payoff=${cuprodigy_currentBalance} if $configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} eq "offbook-sweep" and $cuprodigy_payoff =~ /^\s*$/;	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, so for "sweep" offbook there likely is no "payoff" in the XML.
										$cuprodigy_payoff=${cuprodigy_currentBalance} if $configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} eq "inhouse" and $cuprodigy_payoff =~ /^\s*$/;	# Just in case CUProdigy failes to include "payoff" even though it treats inhouse CCs as an LN.
										$cuprodigy_YTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"YTDInterest",${XML_SINGLE})};
										$cuprodigy_LYTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"LYTDInterest",${XML_SINGLE})};
										$cuprodigy_lastPaymentDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastPaymentDate",${XML_SINGLE})};
										$cuprodigy_nextPaymentDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nextPaymentDate",${XML_SINGLE})};
										$cuprodigy_lastPaymentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastPaymentAmount",${XML_SINGLE})};
										$cuprodigy_unpaidInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"unpaidInterest",${XML_SINGLE})};
										$cuprodigy_paymentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"paymentAmount",${XML_SINGLE})};
										$cuprodigy_partialPayment=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"partialPayment",${XML_SINGLE})};
										$cuprodigy_delinquentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"delinquentAmount",${XML_SINGLE})};
										$cuprodigy_paymentsPerYear=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"paymentsPerYear",${XML_SINGLE})};
										$cuprodigy_maturityDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"maturityDate",${XML_SINGLE})};
										$cuprodigy_interestRate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"interestRate",${XML_SINGLE})};
										$cuprodigy_creditLimit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"creditLimit",${XML_SINGLE})};
										$cuprodigy_availableCreditLimit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableCreditLimit",${XML_SINGLE})};
										$cuprodigy_openingBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openingBalance",${XML_SINGLE})};
										$cuprodigy_make="";
										$cuprodigy_model="";
										$cuprodigy_vin="";
										$cuprodigy_year="";
										if(${CONF__BAL_CC__DESC__INCLUDE_LAST_4_DIGITS}){
											$cuprodigy_cardNumberLastFour=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"cardNumberLastFour",${XML_SINGLE})};
											if($cuprodigy_cardNumberLastFour =~ /^\s*$/){
												$cuprodigy_cardNumberLastFour=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"CardNumberLastFour",${XML_SINGLE})};	# Glitch in older versions of CUProdigy API methods Inquiry / AccountInquiry / AccountDetailInquiry
											}
											if(${cuprodigy_cardNumberLastFour} ne ""){
												if(length(${cuprodigy_cardNumberLastFour}) > 4){
													$cuprodigy_cardNumberLastFour=substr(${cuprodigy_cardNumberLastFour},-4,4);
												}
												if(${cuprodigy_homeBankAccountDesc} ne "" and index(${cuprodigy_homeBankAccountDesc},${cuprodigy_cardNumberLastFour}) < 0){
													$cuprodigy_homeBankAccountDesc.=${CONF__BAL_CC__DESC__PREFIX_TO_LAST_4_DIGITS}.substr(${cuprodigy_cardNumberLastFour},-4,4);
												}
												if(${cuprodigy_description} ne "" and index(${cuprodigy_description},${cuprodigy_cardNumberLastFour}) < 0){
													$cuprodigy_description.=${CONF__BAL_CC__DESC__PREFIX_TO_LAST_4_DIGITS}.substr(${cuprodigy_cardNumberLastFour},-4,4);
												}
											}
										}
									}else{
										$DPLNCC="";
										if(${record_messages_in_logfile}){
											($xml_ref_1="<".join("><",split(/$;/,$key_prefix),"accountCategory").">")=~s/<[0-9][0-9]*>//g;
											($xml_ref_2="<".join("><",split(/$;/,$key_prefix),"accountType").">")=~s/<[0-9][0-9]*>//g;
											($xml_ref_3="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
											&logfile("cuprodigy_xml_balances_and_history__parse_balances(): Unmapped value from ${CTRL__SERVER_REFERENCE__CUPRODIGY} where ".${xml_ref_1}." is '".${cuprodigy_accountCategory}."' and ".${xml_ref_2}." is '".${cuprodigy_accountType}."' and ".${xml_ref_3}." is '".${cuprodigy_accountNumber}."'; skipping the balance record.\n");
										}
									}
									&configure_account_by_cuprodigy_type__generate_default__wrapper(${DPLNCC},${cuprodigy_accountType},${cuprodigy_accountCategory},${cuprodigy_creditLimit});
									$dms_accountnumber=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[0];
									if($DPLNCC =~ /^DP$/i){
										$dms_accounttype=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[1];
										$dms_certnumber="0";
										if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
										}
										if($single_dp_ln =~ /^\Q${CTRL__INQ__EXTRA_ARGS_KEYWORD__SINGLE_DP}\E$/io and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE}){
												if(sprintf("%.0f",${single_cert}) ne sprintf("%.0f",${dms_certnumber})){
													$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: "."Middleware detected DP certificate number mis-match.");
													return(${rtrn_error_text});
												}
											}else{
												if(sprintf("%.0f",${single_cert}) ne "0"){
													$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountDetailInquiry: "."Middleware detected DP certificate number mis-match.");
													return(${rtrn_error_text});
												}
											}
										}
										if(${CONF__XJO__USE} && ${dms_accountnumber} ne ${cuprodigy_xml_request_membernumber}){
											($dms_accountnumber,$dms_accounttype)=&join_dms_xjo_overloaded_composit(${cuprodigy_xml_request_membernumber},${dms_accountnumber},${dms_accounttype});
										}
										$dms_micraccount=${cuprodigy_checkDigit};
										$dms_amount=${cuprodigy_currentBalance};
										$dms_available=${cuprodigy_availableBalance};
										$dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{${cuprodigy_accountType}};
										if(${dms_deposittype} eq ""){ $dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{${cuprodigy_accountCategory}}; }
										if(${dms_deposittype} eq ""){ $dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{""}; }
										$dms_description=( ${cuprodigy_homeBankAccountDesc} ne "" ? ${cuprodigy_homeBankAccountDesc} : ${cuprodigy_description} );
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										if($CUSTOM{"custom_baldesc.pi"}>0){
											if(defined(&custom_baldesc)){
												$dms_description=&custom_baldesc(${dms_description},"INQ","DP",${key_prefix},${record_messages_in_logfile},&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}),"0");
											}
										}
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										if    (${CONF__BAL_DP__CERT_DESC__INCLUDE_MATURITY_DATE} and ${cuprodigy_maturityDate} ne "" and 
										       ${CONF__BAL_DP__CERT_DESC__INCLUDE_APR} and ${cuprodigy_dividendRate} > 0){
											$dms_description.=" (Matures ".${cuprodigy_maturityDate}.", APR ".${cuprodigy_dividendRate}."%)";
										}elsif(${CONF__BAL_DP__CERT_DESC__INCLUDE_MATURITY_DATE} and ${cuprodigy_maturityDate} ne ""){
											$dms_description.=" (Matures ".${cuprodigy_maturityDate}.")";
										}elsif(${CONF__BAL_DP__CERT_DESC__INCLUDE_APR} and ${cuprodigy_dividendRate} > 0){
											$dms_description.=" (APR ".${cuprodigy_dividendRate}."%)";
										}
										$dms_ytdinterest=${cuprodigy_YTDInterest};
										$dms_lastyrinterest=${cuprodigy_LYTDInterest};
										if($cuprodigy_transactionsRestricted =~ /^true$/i or $cuprodigy_openStatus =~ /^closed$/i){
											$fake_cuprodigy_canbetransfersource="false";
											$fake_cuprodigy_canbetransferdestination="false";
										}else{
# MARK -- 2017-06-07
											if(($xfer_excl_reason=&transaction_excl_xfer_from(${DPLNCC},${dms_accounttype},"GEN")) eq ""){
												$fake_cuprodigy_canbetransfersource="true";
											}else{
												$fake_cuprodigy_canbetransfersource="false";
												&logfile("Account Restricted: INQ reason transfer FROM would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};
												push(@INQ_RESPONSE_NOTES,join("\t","DP",${dms_accountnumber},${dms_accounttype},${dms_certnumber},"Account Restricted: INQ reason transfer FROM would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n"));
											}
											if(($xfer_excl_reason=&transaction_excl_xfer_to(${DPLNCC},${dms_accounttype},"GEN")) eq ""){
												$fake_cuprodigy_canbetransferdestination="true";
											}else{
												$fake_cuprodigy_canbetransferdestination="false";
												&logfile("Account Restricted: INQ reason transfer TO would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};
												push(@INQ_RESPONSE_NOTES,join("\t","DP",${dms_accountnumber},${dms_accounttype},${dms_certnumber},"Account Restricted: INQ reason transfer TO would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n"));
											}
										}
										$accountlist_accountinfo_key=join("\t",
											${cuprodigy_xml_request_membernumber},
											${DPLNCC},
											${dms_accountnumber},
											${dms_accounttype},
											${dms_certnumber},
											${dms_deposittype},
											${dms_description},
											${dms_micraccount},
											${fake_cuprodigy_canbetransfersource},
											${fake_cuprodigy_canbetransferdestination}
										);
										if($ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}} > 0){
											# Do not save duplicated balance record
											$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}++;
										}else{
											# Save non-duplicated balance record
											$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}++;
											if(${dms_accountnumber} eq ${cuprodigy_xml_request_membernumber}){
												if(${record_messages_in_logfile}){
													while(@STACK_LOGFILE_ENTRIES > 0){
														&logfile("cuprodigy_xml_balances_and_history__parse_balances(): ".join("/","DP",${dms_accountnumber},${dms_accounttype},${dms_certnumber})." sub-account: ".shift(@STACK_LOGFILE_ENTRIES)."\n");	# Not XJO/Overloaded/@
													}
												}
												if((&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_accounttype}))[0] eq ${dms_accountnumber}){
													push(@XML_MB_DP_UNIQID,join("\t",
														${dms_accountnumber},
														${dms_accounttype},
														${dms_certnumber},
														&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},"")
													));
												}else{
													push(@XML_MB_DP_UNIQID,join("\t",	# XJO Overloaded (using '@') in @XML_MB_DP_UNIQID
														${dms_accountnumber},
														${dms_accounttype},
														${dms_certnumber},
														&subaccount_recast_uniqid((&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_accounttype}))[0],${cuprodigy_accountCategory},${cuprodigy_accountId},${dms_accountnumber})
													));
												}
												push(@XML_MB_DP_ATTRS,join("\t",
													${dms_accountnumber},
													${dms_accounttype},
													${dms_certnumber},
													${cuprodigy_accountCategory}."|".${cuprodigy_accountType},
													&list_remap(${cuprodigy_openStatus},"open,closed,close","Y,N,N",""),
													&list_remap(${fake_cuprodigy_canbetransferdestination},"true,false","Y,N",""),
													&list_remap(${fake_cuprodigy_canbetransfersource},"true,false","Y,N",""),
													${cuprodigy_currentBalance},
													${cuprodigy_availableBalance},
													${cuprodigy_dividendRate},
													${cuprodigy_maturityDate}
												));
												push(@XML_MB_DP_BALS,join("\t",
													${dms_accountnumber},
													${dms_accounttype},
													${dms_certnumber},
													${dms_deposittype},
													${dms_description},
													${dms_amount},
													${dms_ytdinterest},
													${dms_lastyrinterest},
													${dms_available},
													${dms_micraccount},
													${fake_cuprodigy_canbetransfersource},
													${fake_cuprodigy_canbetransferdestination}
												));
												push(@XML_MB_DP_ACCESS_INFO,join("\t",
													${cuprodigy_xml_request_membernumber},
													${dms_accountnumber},
													${dms_accounttype},
													${dms_certnumber},
													${dms_deposittype},
													${cuprodigy_accountCategory},
													${fake_cuprodigy_canbetransfersource},
													${fake_cuprodigy_canbetransferdestination},
													${cuprodigy_openStatus},
													${cuprodigy_lastTranDate}
												));
											}else{
												push(@XJO_CURRENT_LIST,join("/","DP",${dms_accounttype}.'@'.${dms_accountnumber},${dms_certnumber}));
												if(${CONF__XJO__USE}){
													if(${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
														if(${record_messages_in_logfile}){
															while(@STACK_LOGFILE_ENTRIES > 0){
																&logfile("cuprodigy_xml_balances_and_history__parse_balances(): ".join("/","DP",${cuprodigy_xml_request_membernumber},${dms_accounttype}.'@'.${dms_accountnumber},${dms_certnumber})." sub-account: ".shift(@STACK_LOGFILE_ENTRIES)."\n");	# Is XJO/Overloaded/@
															}
														}
														push(@XML_MB_DP_UNIQID,join("\t",	# XJO Overloaded (using '@') in @XML_MB_DP_UNIQID
															${cuprodigy_xml_request_membernumber},
															${dms_accounttype}.'@'.${dms_accountnumber},
															${dms_certnumber},
															&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},${cuprodigy_xml_request_membernumber})
														));
														push(@XML_MB_DP_ATTRS,join("\t",	# XJO Overloaded (using '@') in @XML_MB_DP_ATTRS
															${cuprodigy_xml_request_membernumber},
															${dms_accounttype}.'@'.${dms_accountnumber},
															${dms_certnumber},
															${cuprodigy_accountCategory}."|".${cuprodigy_accountType},
															&list_remap(${cuprodigy_openStatus},"open,closed,close","Y,N,N",""),
															&list_remap(${fake_cuprodigy_canbetransferdestination},"true,false","Y,N",""),
															&list_remap(${fake_cuprodigy_canbetransfersource},"true,false","Y,N",""),
															${cuprodigy_currentBalance},
															${cuprodigy_availableBalance},
															${cuprodigy_dividendRate},
															${cuprodigy_maturityDate}
														));
														push(@XML_MB_DP_BALS,join("\t",		# XJO Overloaded (using '@') in @XML_MB_DP_BALS
															${cuprodigy_xml_request_membernumber},
															${dms_accounttype}.'@'.${dms_accountnumber},
															${dms_certnumber},
															${dms_deposittype},
															${dms_description},
															${dms_amount},
															${dms_ytdinterest},
															${dms_lastyrinterest},
															${dms_available},
															${dms_micraccount},
															${fake_cuprodigy_canbetransfersource},
															${fake_cuprodigy_canbetransferdestination}
														));
														push(@XML_MB_DP_ACCESS_INFO,join("\t",
															${cuprodigy_xml_request_membernumber},
															${cuprodigy_xml_request_membernumber},
															${dms_accounttype}.'@'.${dms_accountnumber},
															${dms_certnumber},
															${dms_deposittype},
															${cuprodigy_accountCategory},
															${fake_cuprodigy_canbetransfersource},
															${fake_cuprodigy_canbetransferdestination},
															${cuprodigy_openStatus},
															${cuprodigy_lastTranDate}
														));
													}else{
														push(@XML_MB_XJO,join("\t",
															${cuprodigy_xml_request_membernumber},
															"DP",
															${dms_accountnumber},
															${dms_accounttype},
															${dms_certnumber}
														));
													}
												}
											}
											push(@XML_MB_DP_GROUPS,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_accountnumber},
												${dms_accounttype},
												${dms_certnumber},
												${dms_deposittype},
												${cuprodigy_accountCategory}
											));
										}
									}
									if($DPLNCC =~ /^LN$/i or $DPLNCC =~ /^CC$/i){
										$dms_loannumber=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[1];
										if(${CONF__XJO__USE} && ${dms_accountnumber} ne ${cuprodigy_xml_request_membernumber}){
											($dms_accountnumber,$dms_loannumber)=&join_dms_xjo_overloaded_composit(${cuprodigy_xml_request_membernumber},${dms_accountnumber},${dms_loannumber});
										}
										$dms_currentbalance="0";
										$dms_creditlimit="0";
										$dms_payoff="0";
										$dms_paymentamount="0";
										if(0){
											$dms_nextduedate="9999-12-31";		# LOANBALANCE.NEXTDUEDATE default to prevent null value (sent as "") if not allowed
											$dms_lastpaymentdate="9999-12-31";	# LOANBALANCE.LASTPAYMENTDATE default to prevent null value (sent as "") if not allowed
										}else{
											$dms_nextduedate="";			# LOANBALANCE.NEXTDUEDATE allows null value (sent as "") to display nothing on balance page (as per Mark (HomeCU) on 2020-08-13)
											$dms_lastpaymentdate="";		# LOANBALANCE.LASTPAYMENTDATE allows null value (sent as "") to display nothing on balance page (as per Mark (HomeCU) on 2020-08-13)
										}
										$dms_interestrate="0";
										$dms_ytdinterest="0";
										$dms_lastyrinterest="0";
										$dms_misc="";
										$dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{${cuprodigy_accountType}};
										if(${dms_deposittype} eq ""){ $dms_deposittype="L"; }
										if    ($configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} ne ""){	# Non-blank value should be either "loan" or "offbook-nonsweep" or "offbook-sweep" or "inhouse"
											$dms_type=${CTRL__CC_CREDIT_BUREAU_PURP_CODE};	# C/B Type for CC
										}elsif($configure_account_by_cuprodigy_type__loan_behavior{${cuprodigy_accountType}} ne ""){	# Non-blank value should be either "3rdparty-nonsweep" or "3rdparty-sweep"
											$dms_type=${CTRL__LN_CREDIT_BUREAU_PURP_CODE_3RD_PARTY};	# C/B Type for LN when 3rd Party
										}else{
											$dms_type=${CTRL__LN_CREDIT_BUREAU_PURP_CODE};	# C/B Type for LN
										}
										if(${dms_type} ne ${CTRL__LN_CREDIT_BUREAU_PURP_CODE}){
											if($CUSTOM{"custom_sso.pi"}>0){
												if(defined(&custom_sso)){
													$dms_misc=&custom_sso(${DPLNCC},${key_prefix},${record_messages_in_logfile},${dms_accountnumber},${dms_loannumber},${dms_type});
	
												}
											}
											if(${dms_misc} eq ""){
												if(${cuprodigy_accountCategory} eq "Custom"){
													if($CUSTOM{"custom_sso.pi"}>0){
														&logfile("cuprodigy_xml_balances_and_history__parse_balances(): The \"".$CUSTOM{DIR}."/custom_sso.pi\" subroutine \"custom_sso()\" did not generate any SSO related value for: ".join("/",${DPLNCC},${dms_accountnumber},${dms_loannumber},${dms_type})."\n") if ${record_messages_in_logfile};
														push(@INQ_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_loannumber},"cuprodigy_xml_balances_and_history__parse_balances(): The \"".$CUSTOM{DIR}."/custom_sso.pi\" subroutine \"custom_sso()\" did not generate any SSO related value for: ".join("/",${DPLNCC},${dms_accountnumber},${dms_loannumber},${dms_type})."\n"));
													}else{
														&logfile("cuprodigy_xml_balances_and_history__parse_balances(): No \"".$CUSTOM{DIR}."/custom_sso.pi\", so no subroutine \"custom_sso()\" to generate any SSO related value for: ".join("/",${DPLNCC},${dms_accountnumber},${dms_loannumber},${dms_type})."\n") if ${record_messages_in_logfile};
														push(@INQ_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_loannumber},"cuprodigy_xml_balances_and_history__parse_balances(): No \"".$CUSTOM{DIR}."/custom_sso.pi\", so no subroutine \"custom_sso()\" to generate any SSO related value for: ".join("/",${DPLNCC},${dms_accountnumber},${dms_loannumber},${dms_type})."\n"));
													}
												}
											}
										}
										$dms_description=( ${cuprodigy_homeBankAccountDesc} ne "" ? ${cuprodigy_homeBankAccountDesc} : ${cuprodigy_description} );
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										if("${cuprodigy_year}${cuprodigy_make}${cuprodigy_model}" ne ""){
											($tmp_ln_year_make_model_1=${dms_description})=~s/\s//g;
										    ($tmp_ln_year_make_model_2="${cuprodigy_year} ${cuprodigy_make} ${cuprodigy_model}")=~s/\s//g;
											if($tmp_ln_year_make_model_2 !~ /^\d*$/){
												if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
											    	($tmp_ln_year_make_model_2.=${cuprodigy_vin})=~s/\s//g;
												}
												if    (${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__APPEND}){
													$dms_description.=" -";
													if(${cuprodigy_year} ne ""){ $dms_description.=" ".${cuprodigy_year}; }
													if(${cuprodigy_make} ne ""){ $dms_description.=" ".${cuprodigy_make}; }
													if(${cuprodigy_model} ne ""){ $dms_description.=" ".${cuprodigy_model}; }
													if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
														if(${cuprodigy_vin} ne ""){ $dms_description.=" ".${cuprodigy_vin}; }
													}
												}elsif(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__REPLACE}){
													$dms_description="";
													if(${cuprodigy_year} ne ""){ $dms_description.=" ".${cuprodigy_year}; }
													if(${cuprodigy_make} ne ""){ $dms_description.=" ".${cuprodigy_make}; }
													if(${cuprodigy_model} ne ""){ $dms_description.=" ".${cuprodigy_model}; }
													if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
														if(${cuprodigy_vin} ne ""){ $dms_description.=" ".${cuprodigy_vin}; }
													}
													$dms_description=~s/^ *//;
												}elsif(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__AUGMENT}){
													$tmp_ln_year_make_model_1=~tr/A-Z/a-z/;
													$tmp_ln_year_make_model_2=~tr/A-Z/a-z/;
													if(index(${tmp_ln_year_make_model_2},${tmp_ln_year_make_model_1}) >= 0){
														$dms_description="";
														if(${cuprodigy_year} ne ""){ $dms_description.=" ".${cuprodigy_year}; }
														if(${cuprodigy_make} ne ""){ $dms_description.=" ".${cuprodigy_make}; }
														if(${cuprodigy_model} ne ""){ $dms_description.=" ".${cuprodigy_model}; }
														if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
															if(${cuprodigy_vin} ne ""){ $dms_description.=" ".${cuprodigy_vin}; }
														}
														$dms_description=~s/^ *//;
													}
												}
											}
										}
										if($CUSTOM{"custom_baldesc.pi"}>0){
											if(defined(&custom_baldesc)){
												$dms_description=&custom_baldesc(${dms_description},"INQ","LN",${key_prefix},${record_messages_in_logfile},&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}),${dms_type});
											}
										}
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										$dms_currentbalance=sprintf("%.2f",${cuprodigy_currentBalance});
										$dms_creditlimit=sprintf("%.2f",${cuprodigy_creditLimit});
										$dms_availablecreditlimit=sprintf("%.2f",${cuprodigy_availableCreditLimit});
										$dms_payoff=sprintf("%.2f",${cuprodigy_payoff});
										$dms_paymentamount=sprintf("%.2f",${cuprodigy_paymentAmount});
										$dms_regularpaymentamount=sprintf("%.2f",${cuprodigy_paymentAmount}+${cuprodigy_partialPayment}-${cuprodigy_delinquentAmount});
										if    ($cuprodigy_nextPaymentDate =~ /^\d{8}$/){
											($dms_nextduedate=${cuprodigy_nextPaymentDate})=~s/^(....)(..)(..)/$1-$2-$3/;
										}elsif($cuprodigy_nextPaymentDate =~ /^\d{4}-\d{2}-\d{2}$/){
											$dms_nextduedate=${cuprodigy_nextPaymentDate};
										}else{
											push(@STACK_LOGFILE_ENTRIES,"Bad \"next due date\" value (${CTRL__SERVER_REFERENCE__CUPRODIGY} XML tag <nextPaymentDate>): ${cuprodigy_nextPaymentDate}");	# &logfile("");
											push(@INQ_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_loannumber},"Bad \"next due date\" value (${CTRL__SERVER_REFERENCE__CUPRODIGY} XML tag <nextPaymentDate>): ${cuprodigy_nextPaymentDate}\n"));
										}
										if    ($cuprodigy_lastPaymentDate =~ /^\d{8}$/){
											($dms_lastpaymentdate=${cuprodigy_lastPaymentDate})=~s/^(....)(..)(..)/$1-$2-$3/;
										}elsif($cuprodigy_lastPaymentDate =~ /^\d{4}-\d{2}-\d{2}$/){
											$dms_lastpaymentdate=${cuprodigy_lastPaymentDate};
										}else{
											push(@STACK_LOGFILE_ENTRIES,"Bad \"last payment date\" value (${CTRL__SERVER_REFERENCE__CUPRODIGY} XML tag <lastPaymentDate>): ${cuprodigy_lastPaymentDate}");	# &logfile("");
											push(@INQ_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_loannumber},"Bad \"last payment date\" value (${CTRL__SERVER_REFERENCE__CUPRODIGY} XML tag <lastPaymentDate>): ${cuprodigy_lastPaymentDate}\n"));
										}
										$dms_interestrate=sprintf("%.3f",${cuprodigy_interestRate});
										$dms_ytdinterest=sprintf("%.2f",${cuprodigy_YTDInterest});
										$dms_lastyrinterest=sprintf("%.2f",${cuprodigy_LYTDInterest});
										if($cuprodigy_transactionsRestricted =~ /^true$/i or $cuprodigy_openStatus =~ /^closed$/i){
											$fake_cuprodigy_canbetransfersource="false";
											$fake_cuprodigy_canbetransferdestination="false";
										}else{
											if(($xfer_excl_reason=&transaction_excl_xfer_from(${DPLNCC},${dms_loannumber},"GEN")) eq ""){
												$fake_cuprodigy_canbetransfersource="true";
											}else{
												$fake_cuprodigy_canbetransfersource="false";
												&logfile("Account Restricted: INQ reason transfer FROM would be restricted on loan ${dms_accountnumber}/${dms_loannumber}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};
												push(@INQ_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_loannumber},"Account Restricted: INQ reason transfer FROM would be restricted on loan ${dms_accountnumber}/${dms_loannumber}: ${xfer_excl_reason}\n"));
											}
											if(($xfer_excl_reason=&transaction_excl_xfer_to(${DPLNCC},${dms_loannumber},"GEN")) eq ""){
												$fake_cuprodigy_canbetransferdestination="true";
											}else{
												$fake_cuprodigy_canbetransferdestination="false";
												&logfile("Account Restricted: INQ reason transfer TO would be restricted on loan ${dms_accountnumber}/${dms_loannumber}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};
												push(@INQ_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_loannumber},"Account Restricted: INQ reason transfer TO would be restricted on loan ${dms_accountnumber}/${dms_loannumber}: ${xfer_excl_reason}\n"));
											}
										}
										$accountlist_accountinfo_key=join("\t",
											${cuprodigy_xml_request_membernumber},
											${DPLNCC},
											${dms_accountnumber},
											${dms_loannumber},
											${dms_description},
											${dms_creditlimit},
											${dms_misc},
											${dms_type},
											${fake_cuprodigy_canbetransfersource},
											${fake_cuprodigy_canbetransferdestination}
										);
										if($ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}} > 0){
											# Do not save duplicated balance record
											$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}++;
										}else{
											# Save non-duplicated balance record
											$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}++;
											if(${dms_accountnumber} eq ${cuprodigy_xml_request_membernumber}){
												if(${record_messages_in_logfile}){
													while(@STACK_LOGFILE_ENTRIES > 0){
														&logfile("cuprodigy_xml_balances_and_history__parse_balances(): ".join("/","LN",${dms_accountnumber},${dms_loannumber})." sub-account: ".shift(@STACK_LOGFILE_ENTRIES)."\n");	# Not XJO/Overloaded/@
													}
												}
												if((&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_loannumber}))[0] eq ${dms_accountnumber}){
													push(@XML_MB_LN_UNIQID,join("\t",
														${dms_accountnumber},
														${dms_loannumber},
														&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},"")
													));
												}else{
													push(@XML_MB_LN_UNIQID,join("\t",	# XJO Overloaded (using '@') in @XML_MB_LN_UNIQID
														${dms_accountnumber},
														${dms_loannumber},
														&subaccount_recast_uniqid((&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_loannumber}))[0],${cuprodigy_accountCategory},${cuprodigy_accountId},${dms_accountnumber})
													));
												}
												push(@XML_MB_LN_ATTRS,join("\t",
													${dms_accountnumber},
													${dms_loannumber},
													${cuprodigy_accountCategory}."|".${cuprodigy_accountType},
													&list_remap(${cuprodigy_openStatus},"open,closed,close","Y,N,N",""),
													&list_remap(${fake_cuprodigy_canbetransferdestination},"true,false","Y,N",""),
													&list_remap(${fake_cuprodigy_canbetransfersource},"true,false","Y,N",""),
													${dms_creditlimit},
													${dms_availablecreditlimit},	# &min_zero(sprintf("%.2f",${dms_creditlimit}-${dms_currentbalance})),
													${dms_interestrate},
													&list_remap(${cuprodigy_maturityDate},"null","",${cuprodigy_maturityDate}),
													${dms_nextduedate},
													${dms_regularpaymentamount},
													${dms_paymentamount}
												));
												push(@XML_MB_LN_BALS,join("\t",
													${dms_accountnumber},
													${dms_loannumber},
													${dms_currentbalance},
													${dms_payoff},
													${dms_paymentamount},
													${dms_nextduedate},
													${dms_description},
													${dms_interestrate},
													${dms_creditlimit},
													${dms_ytdinterest},
													${dms_lastyrinterest},
													${dms_misc},
													${dms_type},
													${dms_lastpaymentdate},
													${fake_cuprodigy_canbetransfersource},
													${fake_cuprodigy_canbetransferdestination}
												));
												push(@XML_MB_LN_ACCESS_INFO,join("\t",
													${cuprodigy_xml_request_membernumber},
													${dms_accountnumber},
													${dms_loannumber},
													"L",	# ${dms_deposittype}
													${cuprodigy_accountCategory},
													${fake_cuprodigy_canbetransfersource},
													${fake_cuprodigy_canbetransferdestination},
													${cuprodigy_openStatus},
													${cuprodigy_lastTranDate}
												));
												push(@XML_MB_LN_PAYOFF,join("\t",
													${cuprodigy_xml_request_membernumber},
													${dms_accountnumber},
													${dms_loannumber},
													${dms_payoff}
												));
											}else{
												push(@XJO_CURRENT_LIST,join("/","LN",${dms_loannumber}.'@'.${dms_accountnumber}));
												if(${CONF__XJO__USE}){
													if(${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
														if(${record_messages_in_logfile}){
															while(@STACK_LOGFILE_ENTRIES > 0){
																&logfile("cuprodigy_xml_balances_and_history__parse_balances(): ".join("/","LN",${cuprodigy_xml_request_membernumber},${dms_loannumber}.'@'.${dms_accountnumber})." sub-account: ".shift(@STACK_LOGFILE_ENTRIES)."\n");	# Is XJO/Overloaded/@
															}
														}
														push(@XML_MB_LN_UNIQID,join("\t",	# XJO Overloaded (using '@') in @XML_MB_LN_UNIQID
															${cuprodigy_xml_request_membernumber},
															${dms_loannumber}.'@'.${dms_accountnumber},
															&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},${cuprodigy_xml_request_membernumber})
														));
														push(@XML_MB_LN_ATTRS,join("\t",	# XJO Overloaded (using '@') in @XML_MB_LN_ATTRS
															${cuprodigy_xml_request_membernumber},
															${dms_loannumber}.'@'.${dms_accountnumber},
															${cuprodigy_accountCategory}."|".${cuprodigy_accountType},
															&list_remap(${cuprodigy_openStatus},"open,closed,close","Y,N,N",""),
															&list_remap(${fake_cuprodigy_canbetransferdestination},"true,false","Y,N",""),
															&list_remap(${fake_cuprodigy_canbetransfersource},"true,false","Y,N",""),
															${dms_creditlimit},
															${dms_availablecreditlimit},	# &min_zero(sprintf("%.2f",${dms_creditlimit}-${dms_currentbalance})),
															${dms_interestrate},
															&list_remap(${cuprodigy_maturityDate},"null","",${cuprodigy_maturityDate}),
															${dms_nextduedate},
															${dms_regularpaymentamount},
															${dms_paymentamount}
														));
														push(@XML_MB_LN_BALS,join("\t",		# XJO Overloaded (using '@') in @XML_MB_LN_BALS
															${cuprodigy_xml_request_membernumber},
															${dms_loannumber}.'@'.${dms_accountnumber},
															${dms_currentbalance},
															${dms_payoff},
															${dms_paymentamount},
															${dms_nextduedate},
															${dms_description},
															${dms_interestrate},
															${dms_creditlimit},
															${dms_ytdinterest},
															${dms_lastyrinterest},
															${dms_misc},
															${dms_type},
															${dms_lastpaymentdate},
															${fake_cuprodigy_canbetransfersource},
															${fake_cuprodigy_canbetransferdestination}
														));
														push(@XML_MB_LN_ACCESS_INFO,join("\t",
															${cuprodigy_xml_request_membernumber},
															${cuprodigy_xml_request_membernumber},
															${dms_loannumber}.'@'.${dms_accountnumber},
															"L",	# ${dms_deposittype}
															${cuprodigy_accountCategory},
															${fake_cuprodigy_canbetransfersource},
															${fake_cuprodigy_canbetransferdestination},
															${cuprodigy_openStatus},
															${cuprodigy_lastTranDate}
														));
														push(@XML_MB_LN_PAYOFF,join("\t",
															${cuprodigy_xml_request_membernumber},
															${cuprodigy_xml_request_membernumber},
															${dms_loannumber}.'@'.${dms_accountnumber},
															${dms_payoff}
														));
													}else{
														push(@XML_MB_XJO,join("\t",
															${cuprodigy_xml_request_membernumber},
															"LN",
															${dms_accountnumber},
															${dms_loannumber}
														));
													}
												}
											}
											push(@XML_MB_LN_GROUPS,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_accountnumber},
												${dms_loannumber},
												${dms_deposittype},
												${cuprodigy_accountCategory}
											));
										}
									}
									if($DPLNCC =~ /^CC$/i){
# Old CUSA/FiServ code (waiting for CUProdigy example of CC in XML data) {
#	 									$cuprodigy_accountid=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"ACCOUNT",${XML_SINGLE},"CARDACCOUNTID",${XML_SINGLE},"ACCOUNTID",${XML_SINGLE})};
#	 									($dms_accountnumber,$dms_loannumber)=split(/=/,${cuprodigy_accountid},2);
#	 									$cuprodigy_accounttype=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"ACCOUNT",${XML_SINGLE},"CARDACCOUNTID",${XML_SINGLE},"ACCOUNTTYPE",${XML_SINGLE})};
#	 									&configure_account_by_cuprodigy_type__usage_history__used(${DPLNCC},${cuprodigy_accountCategory});
#	 									$cuprodigy_creditlimit="";
#	 									$cuprodigy_availablecredit="";
#	 									$dms_currentbalance="";
#	 									$seq_key_prefix=join($;,$key_prefix,"ACCOUNT",${XML_SINGLE},"ACCOUNTBALANCE");
#	 									for($seq=1;$seq<=$XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix)};$seq=sprintf("%.0f",${seq}+1)){
#	 										if($XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix,sprintf(${XML_TAG_INDEX_FMT},${seq}),"BALANCETYPE",${XML_SINGLE})} =~ /^CREDITLIMIT$/i){	# Found CC to have "CREDITLIMIT", maybe some day LN will have "CREDITLIMIT".
#	 											$cuprodigy_creditlimit=$XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix,sprintf(${XML_TAG_INDEX_FMT},${seq}),"CURRENCYAMOUNT",${XML_SINGLE},"AMOUNT",${XML_SINGLE})};
#	 										}
#	 										if($XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix,sprintf(${XML_TAG_INDEX_FMT},${seq}),"BALANCETYPE",${XML_SINGLE})} =~ /^AVAILABLE$/i){	# The keyword was "AVAILABLECREDIT" 2008-12-11, but had changed to "AVAILABLE" by 2008-12-17.
#	 											$cuprodigy_availablecredit=$XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix,sprintf(${XML_TAG_INDEX_FMT},${seq}),"CURRENCYAMOUNT",${XML_SINGLE},"AMOUNT",${XML_SINGLE})};
#	 										}
#	 										if($XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix,sprintf(${XML_TAG_INDEX_FMT},${seq}),"BALANCETYPE",${XML_SINGLE})} =~ /^LEDGER$/i){
#	 											$dms_currentbalance=$XML_DATA_BY_TAG_INDEX{join($;,$seq_key_prefix,sprintf(${XML_TAG_INDEX_FMT},${seq}),"CURRENCYAMOUNT",${XML_SINGLE},"AMOUNT",${XML_SINGLE})};
#	 										}
#	 									}
#	 									$cuprodigy_description=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"ACCOUNT",${XML_SINGLE},"BANKACCOUNTINFO",${XML_SINGLE},"DESCRIPTION",${XML_SINGLE})};
#	 									if($cuprodigy_availablecredit eq ""){
#	 										$cuprodigy_availablecredit="0";
#	 									}
#	 									if($dms_currentbalance eq ""){
#	 										$dms_currentbalance="0";
#	 									}
#	 									if($cuprodigy_creditlimit ne ""){
#	 										$dms_creditlimit=${cuprodigy_creditlimit};
#	 									}else{
#	 										if($cuprodigy_availablecredit > 0){
#	 											$dms_creditlimit=sprintf("%.2f",${dms_currentbalance}+${cuprodigy_availablecredit});
#	 										}else{
#	 											$dms_creditlimit="0";
#	 										}
#	 									}
#	 									$dms_availablecredit=sprintf("%.2f",${cuprodigy_availablecredit});
#	 									$dms_payoff="0";
#	 									$dms_paymentamount="0";
#	 									if(0){
#	 										$dms_nextduedate="9999-12-31";		# LOANBALANCE.NEXTDUEDATE default to prevent null value (sent as "") if not allowed
#	 										$dms_lastpaymentdate="9999-12-31";	# LOANBALANCE.LASTPAYMENTDATE default to prevent null value (sent as "") if not allowed
#	 									}else{
#	 										$dms_nextduedate="";			# LOANBALANCE.NEXTDUEDATE allows null value (sent as "") to display nothing on balance page (as per Mark (HomeCU) on 2020-08-13)
#	 										$dms_lastpaymentdate="";		# LOANBALANCE.LASTPAYMENTDATE allows null value (sent as "") to display nothing on balance page (as per Mark (HomeCU) on 2020-08-13)
#	 									}
#	 									$dms_interestrate="0";
#	 									$dms_ytdinterest="0";
#	 									$dms_lastyrinterest="0";
#	 									$dms_misc="";
#	 									$dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{${cuprodigy_accountType}};
#	 									if(${dms_deposittype} eq ""){ $dms_deposittype="L"; }
#	 									$dms_type=${CTRL__CC_CREDIT_BUREAU_PURP_CODE};	# C/B Type for CC
#	 									$dms_description=${cuprodigy_accountCategory};
#	 									if(${cuprodigy_description} ne ""){ $dms_description.=" ; ".${cuprodigy_description}; }
#	 									if($CUSTOM{"custom_baldesc.pi"}>0){
#	 										if(defined(&custom_baldesc)){
#	 											$dms_description=&custom_baldesc(${dms_description},"INQ","CC",${key_prefix},${record_messages_in_logfile},&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}),${dms_type});
#	 										}
#	 									}
#	 	# print FH_DEBUG join("\t","CC",$dms_accountnumber,$dms_loannumber,$dms_currentbalance,$dms_payoff,$dms_paymentamount,$dms_nextduedate,$dms_description,$dms_interestrate,$dms_creditlimit,$dms_ytdinterest,$dms_lastyrinterest,$dms_misc,$dms_type,$dms_lastpaymentdate,$fake_cuprodigy_canbetransfersource,$fake_cuprodigy_canbetransferdestination),"\n";	# MARK -- DEBUG
#	 									$accountlist_accountinfo_key=join("\t",
#	 										${cuprodigy_xml_request_membernumber},
#	 										${DPLNCC},
#	 										${dms_accountnumber},
#	 										${dms_loannumber},
#	 										${dms_description},
#	 										${dms_creditlimit},
#	 										${dms_misc},
#	 										${dms_type},
#	 										${fake_cuprodigy_canbetransfersource},
#	 										${fake_cuprodigy_canbetransferdestination}
#	 									);
#	 									if($ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}} > 0){
#	 										# Do not save duplicated balance record
#	 										$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}++;
#	 									}else{
#	 										# Save non-duplicated balance record
#	 										$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}++;
#	 										if(${dms_accountnumber} eq ${cuprodigy_xml_request_membernumber}){
#												if(${record_messages_in_logfile}){
#													while(@STACK_LOGFILE_ENTRIES > 0){
#														&logfile("cuprodigy_xml_balances_and_history__parse_balances(): ".join("/","CC",${dms_accountnumber},${dms_loannumber})." sub-account: ".shift(@STACK_LOGFILE_ENTRIES)."\n");	# Not XJO/Overloaded/@
#													}
#												}
#												if((&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_loannumber}))[0] eq ${dms_accountnumber}){
#													push(@XML_MB_CC_UNIQID,join("\t",
#														${dms_accountnumber},
#														${dms_loannumber},
#														&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},"")
#													));
#												}else{
#													push(@XML_MB_CC_UNIQID,join("\t",	# XJO Overloaded (using '@') in @XML_MB_CC_UNIQID
#														${dms_accountnumber},
#														${dms_loannumber},
#														&subaccount_recast_uniqid((&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_loannumber}))[0],${cuprodigy_accountCategory},${cuprodigy_accountId},${dms_accountnumber})
#													));
#												}
#												push(@XML_MB_CC_ATTRS,join("\t",
#													${dms_accountnumber},
#													${dms_loannumber},
#													${cuprodigy_accountCategory}."|".${cuprodigy_accountType},
#													&list_remap(${cuprodigy_openStatus},"open,closed,close","Y,N,N",""),
#													&list_remap(${fake_cuprodigy_canbetransferdestination},"true,false","Y,N",""),
#													&list_remap(${fake_cuprodigy_canbetransfersource},"true,false","Y,N",""),
#													${dms_creditlimit},
#													${dms_availablecredit},	# &min_zero(sprintf("%.2f",${dms_creditlimit}-${dms_currentbalance})),
#													${dms_interestrate},
#													&list_remap(${cuprodigy_maturityDate},"null","",${cuprodigy_maturityDate}),
#													${dms_nextduedate},
#													${dms_regularpaymentamount},
#													${dms_paymentamount}
#												));
#	 											push(@XML_MB_CC_BALS,join("\t",
#	 												${dms_accountnumber},
#	 												${dms_loannumber},
#	 												${dms_currentbalance},
#	 												${dms_payoff},
#	 												${dms_paymentamount},
#	 												${dms_nextduedate},
#	 												${dms_description},
#	 												${dms_interestrate},
#	 												${dms_creditlimit},
#	 												${dms_ytdinterest},
#	 												${dms_lastyrinterest},
#	 												${dms_misc},
#	 												${dms_type},
#	 												${dms_lastpaymentdate},
#	 												${fake_cuprodigy_canbetransfersource},
#	 												${fake_cuprodigy_canbetransferdestination}
#	 											));
#	 											$XML_MB_CC_TO_UNIQ{${dms_accountnumber},${dms_loannumber}}="";
#	 										}else{
#	 											push(@XJO_CURRENT_LIST,join("/","LN",${dms_loannumber}.'@'.${dms_accountnumber}));
#	 											if(${CONF__XJO__USE}){
#	 												if(${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
#														if(${record_messages_in_logfile}){
#															while(@STACK_LOGFILE_ENTRIES > 0){
#																&logfile("cuprodigy_xml_balances_and_history__parse_balances(): ".join("/","CC",${cuprodigy_xml_request_membernumber},${dms_loannumber}.'@'.${dms_accountnumber})." sub-account: ".shift(@STACK_LOGFILE_ENTRIES)."\n");	# Is XJO/Overloaded/@
#															}
#														}
#														push(@XML_MB_CC_UNIQID,join("\t",	# XJO Overloaded (using '@') in @XML_MB_CC_UNIQID
#	 														${cuprodigy_xml_request_membernumber},
#	 														${dms_loannumber}.'@'.${dms_accountnumber},
#															&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},${cuprodigy_xml_request_membernumber})
#														));
#														push(@XML_MB_CC_ATTRS,join("\t",	# XJO Overloaded (using '@') in @XML_MB_CC_ATTRS
#	 														${cuprodigy_xml_request_membernumber},
#	 														${dms_loannumber}.'@'.${dms_accountnumber},
#															${cuprodigy_accountCategory}."|".${cuprodigy_accountType},
#															&list_remap(${cuprodigy_openStatus},"open,closed,close","Y,N,N",""),
#															&list_remap(${fake_cuprodigy_canbetransferdestination},"true,false","Y,N",""),
#															&list_remap(${fake_cuprodigy_canbetransfersource},"true,false","Y,N",""),
#															${dms_creditlimit},
#															${dms_availablecredit},	# &min_zero(sprintf("%.2f",${dms_creditlimit}-${dms_currentbalance})),
#															${dms_interestrate},
#															&list_remap(${cuprodigy_maturityDate},"null","",${cuprodigy_maturityDate}),
#															${dms_nextduedate},
#															${dms_regularpaymentamount},
#															${dms_paymentamount}
#														));
#	 													push(@XML_MB_CC_BALS,join("\t",		# XJO Overloaded (using '@') in @XML_MB_CC_BALS
#	 														${cuprodigy_xml_request_membernumber},
#	 														${dms_loannumber}.'@'.${dms_accountnumber},
#	 														${dms_currentbalance},
#	 														${dms_payoff},
#	 														${dms_paymentamount},
#	 														${dms_nextduedate},
#	 														${dms_description},
#	 														${dms_interestrate},
#	 														${dms_creditlimit},
#	 														${dms_ytdinterest},
#	 														${dms_lastyrinterest},
#	 														${dms_misc},
#	 														${dms_type},
#	 														${dms_lastpaymentdate},
#	 														${fake_cuprodigy_canbetransfersource},
#	 														${fake_cuprodigy_canbetransferdestination}
#	 													));
#	 													$XML_MB_CC_TO_UNIQ{${cuprodigy_xml_request_membernumber},${dms_loannumber}.'@'.${dms_accountnumber}}="";		# XJO Overloaded (using '@') in %XML_MB_C_TO_UNIQ
#	 												}else{
#	 													push(@XML_MB_XJO,join("\t",
#	 														${cuprodigy_xml_request_membernumber},
#	 														"CC",
#	 														${dms_accountnumber},
#	 														${dms_loannumber}
#	 													));
#	 													$XML_MB_CC_TO_UNIQ{${dms_accountnumber},${dms_loannumber}}="";
#	 												}
#	 											}
#	 										}
#	 										push(@XML_MB_CC_GROUPS,join("\t",
#	 											${cuprodigy_xml_request_membernumber},
#	 											${dms_accountnumber},
#	 											${dms_loannumber},
#	 											${dms_deposittype},
#	 											${cuprodigy_accountCategory}
#	 										));
#	 									}
# } Old CUSA/FiServ code (waiting for CUProdigy example of CC in XML data)
									}
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
		pop(@key_prefix); pop(@key_prefix);
	}
	if(${record_messages_in_logfile}){
		foreach $accountlist_accountinfo_key (sort(keys(%ACCOUNTLIST_ACCOUNTINFO_KEYS))){
			$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}=sprintf("%.0f",$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}});
			if($ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}} > 1){
				&logfile(${cuprodigy_xml_description}.": "."Duplicate records (response contained ".$ACCOUNTLIST_ACCOUNTINFO_KEYS{${accountlist_accountinfo_key}}." occurrences) for key values: ".${accountlist_accountinfo_key}."\n");
			}
		}
	}
	if(@XJO_CURRENT_LIST > 0){
		if(${record_messages_in_logfile}){
			if(${CONF__XJO__USE}){
				if(${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
					&logfile("Included XJO/Overloaded ${cuprodigy_xml_request_membernumber}: ".join(", ",@XJO_CURRENT_LIST)."\n");	# This logged information will be useful to explain why holes appear in the history of XJO/Overloaded accounts.
				}else{
					&logfile("Discarded XJO/Overloaded ${cuprodigy_xml_request_membernumber}: ".join(", ",@XJO_CURRENT_LIST)."\n");	# This logged information will be useful to note that XJO/Overloaded accounts were discarded.
				}
			}else{
				&logfile("Excluded XJO/Overloaded ${cuprodigy_xml_request_membernumber}: ".join(", ",@XJO_CURRENT_LIST)."\n");	# This logged information will be useful to explain why expected XAC records are missing.
			}
		}
	}
	if(!${CTRL__SHORTEN_CC_TO_LAST_4_DIGITS}){
		# Do not shorten CC numbers.
		foreach $key (sort(keys(%XML_MB_CC_TO_UNIQ))){
			($curr_mb,$curr_cc)=split(/$;/,$key);
			$XML_MB_CC_TO_UNIQ{$curr_mb,$curr_cc}=$curr_cc;
			$XML_MB_CC_FROM_UNIQ{$curr_mb,$curr_cc}=$curr_cc;
		}
	}else{
		# Shorten CC numbers to the last 4 digits with a 2 digit sequence prefix.
		$prev_mb="";
		$curr_mb="";
		$curr_cc="";
		$curr_cc_seq="";
		$curr_cc_last4="";
		foreach $key (sort(keys(%XML_MB_CC_TO_UNIQ))){
			($curr_mb,$curr_cc)=split(/$;/,$key);
			$curr_cc_last4=substr("0000".$curr_cc,-4,4);
			if($prev_mb ne $curr_mb){
				$curr_cc_seq=sprintf("%02.0f",0);
				$prev_mb=$curr_mb;
			}
			$curr_cc_seq=sprintf("%02.0f",$curr_cc_seq+1);
			$XML_MB_CC_TO_UNIQ{$curr_mb,$curr_cc}=$curr_cc_seq.$curr_cc_last4;
			$XML_MB_CC_FROM_UNIQ{$curr_mb,$curr_cc_seq.$curr_cc_last4}=$curr_cc;
		}
		for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
			@f=split(/\t/,$XML_MB_CC_BALS[$idx]." "); $f[$#f]=~s/ $//;
			if($XML_MB_CC_TO_UNIQ{$f[0],$f[1]} ne ""){
				$f[1]=$XML_MB_CC_TO_UNIQ{$f[0],$f[1]};
				$XML_MB_CC_BALS[$idx]=join("\t",@f);
				@f=split(/\t/,$XML_MB_CC_UNIQID[$idx]." "); $f[$#f]=~s/ $//;
				$f[1]=$XML_MB_CC_TO_UNIQ{$f[0],$f[1]};
				$XML_MB_CC_UNIQID[$idx]=join("\t",@f);
			}
		}
	}
# print FH_DEBUG "B\n";	# MARK -- DEBUG
	for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
		$XML_MB_DP_BALS[$idx]=&cuprodigy_xml_balances_apply_limits(${cuprodigy_xml_request_membernumber},"DP",${max_closed_ccyymmdd_dp},$XML_MB_DP_BALS[$idx]);
	}
	for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
		$XML_MB_LN_BALS[$idx]=&cuprodigy_xml_balances_apply_limits(${cuprodigy_xml_request_membernumber},"LN",${max_closed_ccyymmdd_ln},$XML_MB_LN_BALS[$idx]);
	}
	for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
		$XML_MB_CC_BALS[$idx]=&cuprodigy_xml_balances_apply_limits(${cuprodigy_xml_request_membernumber},"CC",${max_closed_ccyymmdd_ln},$XML_MB_CC_BALS[$idx]);
	}
	if(!${CTRL__DP_BALANCE_INCLUDE_XFER_AUTH}){
		for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
			$XML_MB_DP_BALS[$idx]=~s/\t[^\t]*\t[^\t]*$//;
			
		}
	}
	if(!${CTRL__LN_BALANCE_INCLUDE_XFER_AUTH}){
		for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
			$XML_MB_LN_BALS[$idx]=~s/\t[^\t]*\t[^\t]*$//;
		}
		for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
			$XML_MB_CC_BALS[$idx]=~s/\t[^\t]*\t[^\t]*$//;
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_balances_and_history__fake_dp_certnumber{
   local($dms_accountnumber,$dms_accounttype)=@_;
   local($dms_certnumber);
	if(${CONF__XJO__USE}){
		($dms_accountnumber,$dms_accounttype)=&split_dms_xjo_overloaded_composit(${dms_accountnumber},${dms_accounttype});
	}
	if($dms_accounttype =~ /:\d\d$/){
		$dms_certnumber=$&;
		$dms_certnumber=~s/^:0{0,1}//;
	}else{
		$dms_certnumber="0";
	}
	return(${dms_certnumber});
}

sub cuprodigy_xml_balances_apply_limits{
   local($cuprodigy_xml_request_membernumber,$dplncc,$max_closed_ccyymmdd,$bal_record)=@_;
   local(@bal_record_f);
   local($line);
   local(@f);
   local($flag_xfer_from,$flag_xfer_to,$flag_open,$flag_exclude)=(0,0,0,0);
	@bal_record_f=split(/\t/,${bal_record}." "); $bal_record_f[$#bal_record_f]=~s/ $//;
	if($dplncc =~ /^DP$/i){
		foreach $line (@XML_MB_DP_ACCESS_INFO){
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if($f[0] eq ${cuprodigy_xml_request_membernumber} and $f[1] eq  $bal_record_f[0] and $f[2] eq $bal_record_f[1] and $f[3] eq $bal_record_f[2]){
# print FH_DEBUG join(" / ",@f),"\n";	# MARK -- DEBUG
				if($f[4]){ 1; }					# ${dms_deposittype}	
				if($f[5]){ 1; }					# ${cuprodigy_accountCategory}
				if($f[6] =~ /^true$/i){ $flag_xfer_from=1; }	# ${fake_cuprodigy_canbetransfersource}
				if($f[7] =~ /^true$/i){ $flag_xfer_to=1; }	# ${fake_cuprodigy_canbetransferdestination}
# print FH_DEBUG "bankaccountstatuscode: $f[8]\n";	# MARK -- DEBUG
				if($f[8] =~ /^open$/i){ $flag_open=1; }		# ${cuprodigy_openStatus}
				if(&reformat_date_to_ccyymmdd($f[9]) lt ${max_closed_ccyymmdd} and !${flag_open}){ $flag_exclude=1; }
				if(!${flag_xfer_from}){ $bal_record_f[8]="0.00"; }	# ${dms_available}
				if(!${flag_xfer_from} and !${flag_xfer_to}){ $bal_record_f[3]=~tr/A-Z/a-z/; }	# ${dms_deposittype}
				if(!${flag_open}){ $bal_record_f[3]=~tr/A-Z/a-z/; }	# ${dms_deposittype}
				if(!${flag_exclude}){
					$bal_record=join("\t",@bal_record_f);
				}else{
					$bal_record="";
				}
				last;
			}
		}
	}
	if($dplncc =~ /^LN$/i){
		foreach $line (@XML_MB_LN_ACCESS_INFO){
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if($f[0] eq ${cuprodigy_xml_request_membernumber} and $f[1] eq  $bal_record_f[0] and $f[2] eq $bal_record_f[1]){
# print FH_DEBUG join(" / ",@f),"\n";	# MARK -- DEBUG
				if($f[3]){ 1; }					# ${dms_deposittype}	
				if($f[4]){ 1; }					# ${cuprodigy_accountCategory}
				if($f[5] =~ /^true$/i){ $flag_xfer_from=1; }	# ${fake_cuprodigy_canbetransfersource}
				if($f[6] =~ /^true$/i){ $flag_xfer_to=1; }	# ${fake_cuprodigy_canbetransferdestination}
# print FH_DEBUG "bankaccountstatuscode: $f[7]\n";	# MARK -- DEBUG
				if($f[7] =~ /^open$/i){ $flag_open=1; }		# ${cuprodigy_openStatus}
				if(&reformat_date_to_ccyymmdd($f[8]) lt ${max_closed_ccyymmdd} and !${flag_open}){ $flag_exclude=1; }
				if(!${flag_xfer_from}){ $bal_record_f[8]="0.00"; }	# ${dms_creditlimit}
				if(!${flag_exclude}){
					$bal_record=join("\t",@bal_record_f);
				}else{
					$bal_record="";
				}
				last;
			}
		}
	}
	if($dplncc =~ /^CC$/i){
		foreach $line (@XML_MB_CC_ACCESS_INFO){
			@f=split(/\t/,$line." "); $f[$#f]=~s/ $//;
			if($f[0] eq ${cuprodigy_xml_request_membernumber} and $f[1] eq  $bal_record_f[0] and $f[2] eq &full_cc_num($bal_record_f[0],$bal_record_f[1])){
				if($f[3]){ 1; }					# ${dms_deposittype}	
				if($f[4]){ 1; }					# ${cuprodigy_accountCategory}
				if($f[5] =~ /^true$/i){ $flag_xfer_from=1; }	# ${fake_cuprodigy_canbetransfersource}
				if($f[6] =~ /^true$/i){ $flag_xfer_to=1; }	# ${fake_cuprodigy_canbetransferdestination}
				if($f[7] =~ /^open$/i){ $flag_open=1; }		# ${cuprodigy_openStatus}
				if(&reformat_date_to_ccyymmdd($f[8]) lt ${max_closed_ccyymmdd} and !${flag_open}){ $flag_exclude=1; }
				if(!${flag_xfer_from}){ $bal_record_f[8]="0.00"; }	# ${dms_creditlimit}
				if(!${flag_exclude}){
					$bal_record=join("\t",@bal_record_f);
				}else{
					$bal_record="";
				}
				last;
			}
		}
	}
	return(${bal_record});
}

sub cuprodigy_xml_balances_apply_limits__eval_openStatus_lastTranDate{
   local($cuprodigy_xml_request_membernumber,$dplncc,$cuprodigy_openStatus,$cuprodigy_lastTranDate)=@_;
   local($max_closed_ccyymmdd);
   local($flag_open,$flag_exclude)=(0,0);
	if(1){
		if($cuprodigy_openStatus =~ /^open$|^close$|^closed$/i){
			1;
		}else{
			$cuprodigy_openStatus="open";	# Fake a CUProdigy <openStatus> value
		}
		if($cuprodigy_lastTranDate =~ /^\d{8}$/){
			$cuprodigy_lastTranDate=substr(${cuprodigy_lastTranDate},0,4)."-".substr(${cuprodigy_lastTranDate},4,2)."-".substr(${cuprodigy_lastTranDate},6,2);
		}
		if($cuprodigy_lastTranDate !~ /^\d{4}-\d{2}-\d{2}$/){
			$cuprodigy_lastTranDate="9999-12-31";	# Fake a CUProdigy <lastTranDate> value
		}
	}else{
		$cuprodigy_openStatus="open";	# Fake a CUProdigy <openStatus> value
		$cuprodigy_lastTranDate="9999-12-31";	# Fake a CUProdigy <lastTranDate> value
	}
	if($cuprodigy_openStatus =~ /^open$/i){ $flag_open=1; }	# See the same rule in cuprodigy_xml_balances_apply_limits()
	if(!${flag_open}){
		if    (${dplncc} eq "DP"){
			$max_closed_ccyymmdd=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__BAL_CLOSED_DAYS_DP}*24*60*60));
		}elsif(${dplncc} eq "LN"){
			$max_closed_ccyymmdd=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__BAL_CLOSED_DAYS_LN}*24*60*60));
		}elsif(${dplncc} eq "CC"){
			$max_closed_ccyymmdd=&time_to_CCYYMMDD(${CURR_TIME}-(${CTRL__BAL_CLOSED_DAYS_LN}*24*60*60));
		}else{
			$max_closed_ccyymmdd="00010101";
		}
		if(&reformat_date_to_ccyymmdd(${cuprodigy_lastTranDate}) lt ${max_closed_ccyymmdd} and !${flag_open}){ $flag_exclude=1; }	# See the same rule in cuprodigy_xml_balances_apply_limits()
	}
	return(${flag_exclude},${cuprodigy_openStatus},${cuprodigy_lastTranDate});
}

sub reformat_date_to_ccyymmdd{
   local($formatted_date)=@_;
   local($rtrn_ccyymmdd);
	if    ($formatted_date =~ /^\d{8}$|^\d{14}$/){					# Like: CCYYMMDD or CCYYMMDDHHMMSS
		$rtrn_ccyymmdd=substr(${formatted_date},0,8);
	}elsif($formatted_date =~ /^\d{4}-\d{2}-\d{2}|^\d{4}-\d{2}-\d{2}[^\d]/){	# Like: CCYY-MM-DD or CCYY-MM-DD HH:MM:SS
		($rtrn_ccyymmdd=substr(${formatted_date},0,10))=~s/-//g;
	}elsif($formatted_date =~ /^\d{2}\/\d{2}\/\d{4}|^\d{2}\/\d{2}\/\d{4}[^\d]/){	# Like: MM/DD/CCYY or MM/DD/CCYY HH:MM:SS
		$rtrn_ccyymmdd=substr(${formatted_date},6,4).substr(${formatted_date},0,2).substr(${formatted_date},3,2);
	}else{
		$rtrn_ccyymmdd="";
	}
	return(${rtrn_ccyymmdd});
}

sub cuprodigy_xml_check_initial_password{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$dmshomecu_initial_password)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local(%XML_NAMESPACE_BY_TAG_INDEX,%XML_ATTRIBUTES_BY_TAG_INDEX,%XML_DATA_BY_TAG_INDEX,%XML_SEQ_BY_TAG_INDEX,%XML_TAGS_FOUND);	# Preserve any already existant (external cuprodigy_xml_xjo_overloaded_accounts()) xml parsed structures (as already populated by xml_parse() called in post_request() with "parsexml" option) while cuprodigy_xml_xjo_overloaded_accounts() processes its GetMemberRelatedAccounts data.
	if(${CTRL__DBM_FILE__XML_DATA_BY_TAG_INDEX}){
		&logfile_and_die("${0}: dbm_local_scoping__XML_DATA_BY_TAG_INDEX(): ${error}\n") if ($error=&dbm_local_scoping__XML_DATA_BY_TAG_INDEX("push")) ne "";
	}
	$rtrn_error_text=join("\t","999","Subroutine cuprodigy_xml_check_initial_password() not yet coded to validate initial password value; suspect that only the ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method ValidatePassword is allowed");
	return(${rtrn_error_text});
}

sub cuprodigy_xml_balances_and_history__parse_history{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$beg_ccyymmdd_dp,$beg_ccyymmdd_ln,$record_messages_in_logfile,$single_dp_ln,$single_member,$single_account,$single_cert)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($beg_ccyymmdd_xx);
   local($fmt_beg_ccyymmdd_dp,$fmt_beg_ccyymmdd_ln,$fmt_beg_ccyymmdd_xx);
   local($fmt_beg_ccyymmdd_xx);
   local($query_ccyymmdd_dp,$query_ccyymmdd_ln);
   # local($cuprodigy_xml_description);	# Set in cuprodigy_xml_balances_and_history()
   local(%HIST_BALS);
   local(%HIST_GROUPS);
   local($line);
   local(@f);
   local($timestamp);
   local($transaction_datetime);
   local($hist_class,$hist_mbnum,$hist_qualifier1,$hist_qualifier2);
   local($hist_dp,$hist_dp_certnum);
   local($hist_ln);
   local($hist_cc);
   local($hist_class_tested_for);
   local($prehistory_rows_and_columns);
   local($prehistory_overlap_date);
   local($prehistory_trandate);
   local($idx);
   local($key);
   local($tmp_cuprodigy_accountType);
   local($is_pending_transaction);
   local($dms_xjo_overloaded_mbnum,$dms_xjo_overloaded_qualifier1);
   local($post_request_mode,$post_request_mode_seq);
   local($post_request_parallel_options)="";
   local($echeck_text);
   local($history_tracenumbers_recalculate_max_yyyy_mm_dd);
   local(%SEQUENCE,$sequence_date);
   local(%CUDP_TRACENUMBER);
   local(%CUDP_TRANSACTIONID_ENCOUNTERED,%CUDP_TRANSACTIONID_DUPLICATE,$cudp_transactionid_duplicate);
   local(%KNOWN_HIST_CLASS,$xjo_extracted_mb,$xjo_extracted_dp,$xjo_extracted_ln,$xjo_extracted_cc);
   local(%KNOWN_CUPRODIGY_ACCOUNTCATEGORY);
   local(%KNOWN_DP_DRAFT);
   local(%ENCOUNTERED_UNKNOWN_HIST_CLASS);
   local($KNOWN_EXPIRED_HIST_CLASS);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
	#
	# Expects populated (calling routine must have declared as "local()"):
	#	@XML_MB_UNIQID
	#	@XML_MB_DP_UNIQID
	#	@XML_MB_LN_UNIQID
	#	@XML_MB_CC_UNIQID
	#	@XML_MB_DP_BALS, @XML_MB_DP_GROUPS, @XML_MB_DP_ATTRS
	#	@XML_MB_LN_BALS, @XML_MB_LN_GROUPS, @XML_MB_LN_ATTRS
	#	@XML_MB_CC_BALS, @XML_MB_CC_GROUPS, @XML_MB_CC_ATTRS, %XML_MB_CC_TO_UNIQ, %XML_MB_CC_FROM_UNIQ
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_DP_HIST
	#	@XML_MB_LN_HIST
	#	@XML_MB_CC_HIST
	#	@XML_MB_HOLDS
	#	@XML_MB_PLASTIC_CARDS, @XML_MB_PLASTIC_CARDS_WIP
	#
	undef(@XML_MB_DP_HIST);
	undef(@XML_MB_LN_HIST);
	undef(@XML_MB_CC_HIST);
	undef(@XML_MB_HOLDS);
	undef(@XML_MB_PLASTIC_CARDS);
	undef(@XML_MB_PLASTIC_CARDS_WIP);
	if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_TO_BACKWARD_COMPATIBLE}){
		$history_tracenumbers_recalculate_max_yyyy_mm_dd=${CONF__HISTORY_TRACENUMBERS_RECALCULATE_MAX_YYYYMMDD};
		if    ($history_tracenumbers_recalculate_max_yyyy_mm_dd =~ /^\d{4}-\d{2}-\d{2}$/){
			1;
		}elsif($history_tracenumbers_recalculate_max_yyyy_mm_dd =~ /^\d{8}$/){
			$history_tracenumbers_recalculate_max_yyyy_mm_dd=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
		}else{
			($history_tracenumbers_recalculate_max_yyyy_mm_dd="99991231")=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
		}
	}
	if($beg_ccyymmdd_dp eq ""){
		$beg_ccyymmdd_dp="99991231";
		$fmt_beg_ccyymmdd_dp="9999-12-31";
	}else{
		($fmt_beg_ccyymmdd_dp=${beg_ccyymmdd_dp})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
	}
	if($beg_ccyymmdd_ln eq ""){
		$beg_ccyymmdd_ln="99991231";
		$fmt_beg_ccyymmdd_ln="9999-12-31";
	}else{
		($fmt_beg_ccyymmdd_ln=${beg_ccyymmdd_ln})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
	}
	for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
		@f=split(/\t/,$XML_MB_DP_BALS[${idx}]);
		$KNOWN_HIST_CLASS{$f[0],$f[0],$f[1],$f[2]}="DP";
		if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],$f[0],$f[1],$f[2]}=1; }
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_dp=$f[1])=~s/@\d\d*$//;
			$KNOWN_HIST_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}="DP";
			if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}=1; }
		}
	}
	for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
		@f=split(/\t/,$XML_MB_LN_BALS[${idx}]);
		$KNOWN_HIST_CLASS{$f[0],$f[0],$f[1]}="LN";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_ln=$f[1])=~s/@\d\d*$//;
			$KNOWN_HIST_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_ln}}="LN";
		}
	}
	for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
		@f=split(/\t/,$XML_MB_CC_BALS[${idx}]);
		$KNOWN_HIST_CLASS{$f[0],$f[0],$f[1]}="CC";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_cc=$f[1])=~s/@\d\d*$//;
			$KNOWN_HIST_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_cc}}="CC";
		}
	}
	for($idx=0;$idx<=$#XML_MB_DP_EXPIRED;$idx++){
		@f=split(/\t/,$XML_MB_DP_EXPIRED[${idx}]);
		$KNOWN_EXPIRED_HIST_CLASS{$f[0],$f[0],$f[1],$f[2]}="DP";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_dp=$f[1])=~s/@\d\d*$//;
			$KNOWN_EXPIRED_HIST_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}="DP";
			if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}=1; }
		}
	}
	for($idx=0;$idx<=$#XML_MB_LN_EXPIRED;$idx++){
		@f=split(/\t/,$XML_MB_LN_EXPIRED[${idx}]);
		$KNOWN_EXPIRED_HIST_CLASS{$f[0],$f[0],$f[1]}="LN";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_ln=$f[1])=~s/@\d\d*$//;
			$KNOWN_EXPIRED_HIST_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_ln}}="LN";
		}
	}
	for($idx=0;$idx<=$#XML_MB_CC_EXPIRED;$idx++){
		@f=split(/\t/,$XML_MB_CC_EXPIRED[${idx}]);
		$KNOWN_EXPIRED_HIST_CLASS{$f[0],$f[0],$f[1]}="CC";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_cc=$f[1])=~s/@\d\d*$//;
			$KNOWN_EXPIRED_HIST_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_cc}}="CC";
		}
	}
	for($idx=0;$idx<=$#XML_MB_DP_ACCESS_INFO;$idx++){
		@f=split(/\t/,$XML_MB_DP_ACCESS_INFO[${idx}]);
		$KNOWN_CUPRODIGY_ACCOUNTCATEGORY{$f[0],$f[0],$f[1],$f[2]}=$f[5];
	}
	for($idx=0;$idx<=$#XML_MB_LN_ACCESS_INFO;$idx++){
		@f=split(/\t/,$XML_MB_LN_ACCESS_INFO[${idx}]);
		$KNOWN_CUPRODIGY_ACCOUNTCATEGORY{$f[0],$f[0],$f[1]}=$f[4];
	}
	for($idx=0;$idx<=$#XML_MB_CC_ACCESS_INFO;$idx++){
		@f=split(/\t/,$XML_MB_CC_ACCESS_INFO[${idx}]);
		$KNOWN_CUPRODIGY_ACCOUNTCATEGORY{$f[0],$f[0],$f[1]}=$f[4];
	}
	for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
		$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
		@key_prefix=split(/$;/,$key_L01);
		for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
			$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
			@key_prefix=split(/$;/,$key_L02);
			for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
				$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
				@key_prefix=split(/$;/,$key_L03);
				for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
					$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
					@key_prefix=split(/$;/,$key_L04);
					for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
						$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
						@key_prefix=split(/$;/,$key_L05);
						for($tag_L06="history",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
							$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
							@key_prefix=split(/$;/,$key_L06);
							for($tag_L07="historyRecord",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
								$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
								@key_prefix=split(/$;/,$key_L07);
								$key_prefix=join($;,$key_L07);
								$hist_class="";
								$cuprodigy_accountId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountId",${XML_SINGLE})};
								$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
								($tmp_cuprodigy_accountType=substr($cuprodigy_accountNumber,-6,4))=~s/ *$//;
								($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
								($hist_mbnum,$hist_qualifier1,$hist_qualifier2)=($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc,"0");
								if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
									$hist_qualifier2=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${hist_mbnum},${hist_qualifier1});
								}
								$hist_class_tested_for="";
								if    ($KNOWN_HIST_CLASS{${cuprodigy_xml_request_membernumber},${hist_mbnum},${hist_qualifier1},${hist_qualifier2}} ne ""){
									$hist_class=$KNOWN_HIST_CLASS{${cuprodigy_xml_request_membernumber},${hist_mbnum},${hist_qualifier1},${hist_qualifier2}};
								}elsif($KNOWN_HIST_CLASS{${cuprodigy_xml_request_membernumber},${hist_mbnum},${hist_qualifier1}} ne ""){
									$hist_class=$KNOWN_HIST_CLASS{${cuprodigy_xml_request_membernumber},${hist_mbnum},${hist_qualifier1}};
								}elsif(0){
									# Well, on 2017-09-13 I came to realize that it is a bad idea to guess what the $hist_class might be based upon my guess of what values CUProdigy is likely to include in history records of DP vs LN vs CC.
									$hist_class_tested_for='"'.join('", "',"checkNumber","principle").'"';
									if    ($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"checkNumber")} ne ""){
										$hist_class="DP";
									}elsif($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"principle")} ne ""){
										$hist_class="LN";
									}
								}
								if    (${hist_class} eq "DP"){
									($hist_dp,$hist_dp_certnum)=(${hist_qualifier1},${hist_qualifier2});
									if(&list_found(${tmp_cuprodigy_accountType},${CONF__HIS_EXCL_LIST_ACCTTYPE_DP})){
										$hist_class="CONF__HIS_EXCL_LIST_ACCTTYPE_DP";
									}
								}elsif(${hist_class} eq "LN"){
									($hist_ln,$hist_qualifier2)=(${hist_qualifier1},"");
									if(&list_found(${tmp_cuprodigy_accountType},${CONF__HIS_EXCL_LIST_ACCTTYPE_LN})){
										$hist_class="CONF__HIS_EXCL_LIST_ACCTTYPE_LN";
									}
								}elsif(${hist_class} eq "CC"){
									($hist_cc,$hist_qualifier2)=(${hist_qualifier1},"");
									if(&list_found(${tmp_cuprodigy_accountType},${CONF__HIS_EXCL_LIST_ACCTTYPE_LN})){
										$hist_class="CONF__HIS_EXCL_LIST_ACCTTYPE_LN";
									}
								}else{
									$hist_class="";
									if    ($KNOWN_EXPIRED_HIST_CLASS{${hist_mbnum},${hist_mbnum},${hist_qualifier1},${hist_qualifier2}} ne ""){
										$hist_class="";	# This subroutine would undesirably export history records if $hist_class=$KNOWN_EXPIRED_HIST_CLASS{${hist_mbnum},${hist_mbnum},${hist_qualifier1},${hist_qualifier2}};
									}elsif($KNOWN_EXPIRED_HIST_CLASS{${hist_mbnum},${hist_mbnum},${hist_qualifier1}} ne ""){
										$hist_class="";	# This subroutine would undesirably export history records if $hist_class=$KNOWN_EXPIRED_HIST_CLASS{${hist_mbnum},${hist_mbnum},${hist_qualifier1}};
									}else{
										($ENCOUNTERED_UNKNOWN_HIST_CLASS{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}}="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
									}
								}
								$cuprodigy_amount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"amount",${XML_SINGLE})};
								$cuprodigy_balance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"balance",${XML_SINGLE})};
								$cuprodigy_checkDigit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"checkDigit",${XML_SINGLE})};
								$cuprodigy_checkNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"checkNumber",${XML_SINGLE})};
								$cuprodigy_date=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"date",${XML_SINGLE})};
								$cuprodigy_description=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"description",${XML_SINGLE})};
								$cuprodigy_routingTransitNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"routingTransitNumber",${XML_SINGLE})};
								$cuprodigy_traceNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"traceNumber",${XML_SINGLE})};
								$cuprodigy_tranCode=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"tranCode",${XML_SINGLE})};
								if(${hist_class} eq "DP"){
									$cuprodigy_corpTraceNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"corpTraceNumber",${XML_SINGLE})};
								}
								if(${hist_class} eq "LN"){
									$cuprodigy_fees=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"fees",${XML_SINGLE})};
									$cuprodigy_interest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"interest",${XML_SINGLE})};
									$cuprodigy_principle=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"principle",${XML_SINGLE})};
									if($configure_account_by_cuprodigy_type__creditcard_behavior{${tmp_cuprodigy_accountType}} eq "offbook-nonsweep" or $configure_account_by_cuprodigy_type__creditcard_behavior{${tmp_cuprodigy_accountType}} eq "offbook-sweep"){
										$cuprodigy_balance="0.00" if $cuprodigy_balance =~ /^\s*$/;	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, so there likely is no "balance" in the XML.
										$cuprodigy_fees="0.00" if $cuprodigy_fees=~/^\s*$/;	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, so there likely is no "fees" in the XML.
										$cuprodigy_interest="0.00" if $cuprodigy_interest =~ /^\s*$/;	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, so there likely is no "interest" in the XML.
										$cuprodigy_principle=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"amount",${XML_SINGLE})} if $cuprodigy_principle =~ /^\s*$/	# CUProdigy treats (non-sweep and sweep) offbook CCs as a DP, so there likely is no "principal" in the XML but there is an "amount" in the XML.
									}
								}
								if(${cuprodigy_accountNumber__mb} ne ${cuprodigy_xml_request_membernumber}){
									if(${CONF__XJO__USE}){
										$cuprodigy_accountNumber__dplncc.='@'.${cuprodigy_accountNumber__mb};
									}
								}
								if(index(${cuprodigy_description},${cuprodigy_tranCode}." ") == 0){
									$cuprodigy_description=~s/^[^ ]*  *//;
								}
								if(${hist_class} eq "DP"){
									$dms_accountnumber=${cuprodigy_xml_request_membernumber};
									$dms_accounttype=${cuprodigy_accountNumber__dplncc};
									$dms_certnumber="0";
									if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
										$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
									}
									($dms_date=${cuprodigy_date})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
									substr(($dms_tracenumber=${cuprodigy_traceNumber}),0,9+6)=~tr/a-z/A-Z/;
									if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_TO_BACKWARD_COMPATIBLE}){
										if(${dms_date} le ${history_tracenumbers_recalculate_max_yyyy_mm_dd}){
											$dms_tracenumber=&convert_cuprodigy_tracenumber_new_to_old(${dms_tracenumber},${dms_date});
										}
									}
									($dms_checknumber=${cuprodigy_checkNumber})=~s/^[\s0]*$//;
									$dms_amount=${cuprodigy_amount};
									$dms_description=${cuprodigy_description};
									$dms_balance=${cuprodigy_balance};
									($dms_sortkey=${cuprodigy_corpTraceNumber})=~s/^[\s0]*$//;
									if($cuprodigy_checkDigit !~ /^[\s0]*$/){
										if(${CONF__HIS__SORTKEY_INCLUDE_ROUTINGTRANSITNUMBER} or ${CONF__HIS__SORTKEY_INCLUDE_CHECKDIGIT}){
											if(${CONF__HIS__SORTKEY_INCLUDE_ROUTINGTRANSITNUMBER}){
												$dms_sortkey.=",".${cuprodigy_routingTransitNumber};
											}else{
												$dms_sortkey.=",";
											}
											if(${CONF__HIS__SORTKEY_INCLUDE_CHECKDIGIT}){
												$dms_sortkey.=",".${cuprodigy_checkDigit};
											}else{
												$dms_sortkey.=",";
											}
											$dms_sortkey=~s/,*$//;
										}
									}
									if(&list_found(${cuprodigy_tranCode},${CTRL__DP_SHARE_DRAFT_POSTING_ECHECK_TRANCODES})){
										for $echeck_text (split(/,/,${CTRL__DP_SHARE_DRAFT_POSTING_ECHECK_DESCRIPTION_CONTAINS})){
											next if $echeck_text =~ /^\s*$/;
											if(index(${cuprodigy_description},${echeck_text}) >= $[){
												$dms_sortkey="ECHECK";
											}
										}
									}
									if(${cuprodigy_tranCode} ne "" and index(${GLOB__CUSTOM_XXXHISTORY_SORTKEY__TRANCODE_LIST},",${cuprodigy_tranCode},")>=0){
										if($CUSTOM{"custom_xxxhistory_sortkey.pi"}>0){
											if(defined(&custom_xxxhistory_sortkey)){
												$dms_sortkey=&custom_xxxhistory_sortkey(${hist_class},${key_prefix},${record_messages_in_logfile},${dms_accountnumber},${dms_accounttype},${dms_certnumber},${cuprodigy_tranCode},${dms_sortkey});
											}
										}
									}
									if(!$KNOWN_DP_DRAFT{${dms_accountnumber},${dms_accountnumber},${dms_accounttype},${dms_certnumber}}){
										if($dms_checknumber !~ /^0*$/){
											$dms_description.=" (Ref# ".${dms_checknumber}.")";
											$dms_checknumber="0";
										}
									}
									if(length($dms_checknumber) > 6){
										$dms_description.=" (# ".${dms_checknumber}.")";
										$dms_checknumber=substr(${dms_checknumber},-6,6);
									}
									if(${dms_checknumber} eq ""){ $dms_checknumber="0"; }
									if(1){
										$dms_description=~s/\t/ /g;
										$dms_description=~s/  */ /g;
										$dms_description=~s/[ \t]*[\r\n][\r\n]*[ \t]*/ ; /g;
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
									}
									if(${dms_date} ge ${fmt_beg_ccyymmdd_dp}){
										push(@XML_MB_DP_HIST,
											join("\t",
												substr($dms_date,0,10),
												${dms_accountnumber},
												${dms_accounttype},
												${dms_certnumber},
												${dms_tracenumber},
												${dms_checknumber},
												${dms_date},
												${dms_amount},
												${dms_description},
												${dms_balance},
												&shorten_sortkey_value_16(${CONF__HIS__SORTKEY__LOG_WHEN_SHORTEND},${dms_sortkey},"DP",${dms_accountnumber},${dms_accounttype},${dms_certnumber},${dms_date},${dms_tracenumber})
											)
										);
									}
								}elsif($hist_class eq "LN"){
									# WARNING -- History for LN class and CC class are very similar
									$dms_accountnumber=${cuprodigy_xml_request_membernumber};
									$dms_loannumber=${cuprodigy_accountNumber__dplncc};
									($dms_date=${cuprodigy_date})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
									substr(($dms_tracenumber=${cuprodigy_traceNumber}),0,9+6)=~tr/a-z/A-Z/;
									if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_TO_BACKWARD_COMPATIBLE}){
										if(${dms_date} le ${history_tracenumbers_recalculate_max_yyyy_mm_dd}){
											$dms_tracenumber=&convert_cuprodigy_tracenumber_new_to_old(${dms_tracenumber},${dms_date});
										}
									}
									($dms_checknumber=${cuprodigy_checkNumber})=~s/^[\s0]*$//;
									$dms_principleamount=${cuprodigy_principle};
									$dms_interestamount=${cuprodigy_interest};
									$dms_description=${cuprodigy_description};
									$dms_balance=${cuprodigy_balance};
									$dms_fee=${cuprodigy_fees};
									$dms_escrow=0;
									$dms_sortkey="";
									if(!${CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW} and ${dms_fee} != 0){
										$tmp_amount=sprintf("%.2f",${dms_fee});
										if($tmp_amount !~ /\d\\./){ $tmp_amount=~s/\\./0$&/; }
										$dms_description.=" (Plus \$".${tmp_amount}." in fees)";
										$dms_fee=0;
									}
									if(!${CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW} and ${dms_escrow} != 0){
										$tmp_amount=sprintf("%.2f",${dms_escrow});
										if($tmp_amount !~ /\d\\./){ $tmp_amount=~s/\\./0$&/; }
										$dms_description.=" (Plus \$".${tmp_amount}." for Escrow)";
										$dms_escrow=0;
									}
									if(${dms_checknumber} eq ""){ $dms_checknumber="0"; }
									if($dms_checknumber !~ /^0*$/){
										$dms_description.=" (Ref# ".${dms_checknumber}.")";
										$dms_checknumber="0";
									}
									if(1){
										$dms_description=~s/\t/ /g;
										$dms_description=~s/  */ /g;
										$dms_description=~s/[ \t]*[\r\n][\r\n]*[ \t]*/ ; /g;
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
									}
									if(${dms_date} ge ${fmt_beg_ccyymmdd_ln}){
										if(!${CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW}){
											push(@XML_MB_LN_HIST,
												join("\t",
													substr($dms_date,0,10),
													${dms_accountnumber},
													${dms_loannumber},
													${dms_tracenumber},
													${dms_date},
													${dms_principleamount},
													${dms_interestamount},
													${dms_description},
													${dms_balance},
													&shorten_sortkey_value_16(${CONF__HIS__SORTKEY__LOG_WHEN_SHORTEND},${dms_sortkey},"LN",${dms_accountnumber},${dms_loannumber},${dms_date},${dms_tracenumber})
												)
											);
										}else{
											push(@XML_MB_LN_HIST,
												join("\t",
													substr($dms_date,0,10),
													${dms_accountnumber},
													${dms_loannumber},
													${dms_tracenumber},
													${dms_date},
													${dms_principleamount},
													${dms_interestamount},
													${dms_description},
													${dms_balance},
													&shorten_sortkey_value_16(${CONF__HIS__SORTKEY__LOG_WHEN_SHORTEND},${dms_sortkey},"LN",${dms_accountnumber},${dms_loannumber},${dms_date},${dms_tracenumber}),
													${dms_fee},
													${dms_escrow}
												)
											);
										}
									}
								}elsif($hist_class eq "CC"){
									# WARNING -- History for LN class and CC class are very similar
									$dms_accountnumber=${cuprodigy_xml_request_membernumber};
									$dms_loannumber=${cuprodigy_accountNumber__dplncc};
									if(${CTRL__SHORTEN_CC_TO_LAST_4_DIGITS}){
										if($XML_MB_TO_UNIQ{${dms_accountnumber},${cuprodigy_accountNumber_dplncc}} ne ""){
											$dms_loannumber=$XML_MB_TO_UNIQ{${dms_accountnumber},${cuprodigy_accountNumber_dplncc}};
										}
									}
									($dms_date=${cuprodigy_date})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
									substr(($dms_tracenumber=${cuprodigy_traceNumber}),0,9+6)=~tr/a-z/A-Z/;
									if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_TO_BACKWARD_COMPATIBLE}){
										if(${dms_date} le ${history_tracenumbers_recalculate_max_yyyy_mm_dd}){
											$dms_tracenumber=&convert_cuprodigy_tracenumber_new_to_old(${dms_tracenumber},${dms_date});
										}
									}
									($dms_checknumber=${cuprodigy_checkNumber})=~s/^[\s0]*$//;
									$dms_principleamount=${cuprodigy_principle};
									$dms_interestamount=${cuprodigy_interest};
									$dms_description=${cuprodigy_description};
									$dms_balance=${cuprodigy_balance};
									$dms_fee=${cuprodigy_fees};
									$dms_escrow=0;
									$dms_sortkey="";
									if(!${CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW} and ${dms_fee} != 0){
										$tmp_amount=sprintf("%.2f",${dms_fee});
										if($tmp_amount !~ /\d\\./){ $tmp_amount=~s/\\./0$&/; }
										$dms_description.=" (Plus \$".${tmp_amount}." in fees)";
										$dms_fee=0;
									}
									if(!${CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW} and ${dms_escrow} != 0){
										$tmp_amount=sprintf("%.2f",${dms_escrow});
										if($tmp_amount !~ /\d\\./){ $tmp_amount=~s/\\./0$&/; }
										$dms_description.=" (Plus \$".${tmp_amount}." for Escrow)";
										$dms_escrow=0;
									}
									if(${dms_checknumber} eq ""){ $dms_checknumber="0"; }
									if($dms_checknumber !~ /^0*$/){
										$dms_description.=" (Ref# ".${dms_checknumber}.")";
										$dms_checknumber="0";
									}
									if(1){
										$dms_description=~s/\t/ /g;
										$dms_description=~s/  */ /g;
										$dms_description=~s/[ \t]*[\r\n][\r\n]*[ \t]*/ ; /g;
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
									}
									if(${dms_date} ge ${fmt_beg_ccyymmdd_ln}){
										if(!${CTRL__LN_HISTORY_EXPORT_FEE_AND_ESCROW}){
											push(@XML_MB_CC_HIST,
												join("\t",
													substr($dms_date,0,10),
													${dms_accountnumber},
													${dms_loannumber},
													${dms_tracenumber},
													${dms_date},
													${dms_principleamount},
													${dms_interestamount},
													${dms_description},
													${dms_balance},
													&shorten_sortkey_value_16(${CONF__HIS__SORTKEY__LOG_WHEN_SHORTEND},${dms_sortkey},"CC",${dms_accountnumber},${dms_loannumber},${dms_date},${dms_tracenumber})
												)
											);
										}else{
											push(@XML_MB_CC_HIST,
												join("\t",
													substr($dms_date,0,10),
													${dms_accountnumber},
													${dms_loannumber},
													${dms_tracenumber},
													${dms_date},
													${dms_principleamount},
													${dms_interestamount},
													${dms_description},
													${dms_balance},
													&shorten_sortkey_value_16(${CONF__HIS__SORTKEY__LOG_WHEN_SHORTEND},${dms_sortkey},"CC",${dms_accountnumber},${dms_loannumber},${dms_date},${dms_tracenumber}),
													${dms_fee},
													${dms_escrow}
												)
											);
										}
									}
								}else{
									if(${hist_class} eq "CONF__HIS_EXCL_LIST_ACCTTYPE_DP" or ${hist_class} eq "CONF__HIS_EXCL_LIST_ACCTTYPE_LN"){
										1;	# Quietly ignore history that was suppose to be excluded
									}else{
										if(${cuprodigy_accountNumber__mb} eq ${cuprodigy_xml_request_membernumber} or !${CTRL__CUPRODIGY_GLITCH__HOLDS__INCLUDES_OTHER_MEMBERS_PENDINGS_FOR_CROSS_ACCOUNT_TRANSFERS}){
											if($KNOWN_EXPIRED_HIST_CLASS{${hist_mbnum},${hist_mbnum},${hist_qualifier1},${hist_qualifier2}} ne ""){
												1;
											}elsif($KNOWN_EXPIRED_HIST_CLASS{${hist_mbnum},${hist_mbnum},${hist_qualifier1}} ne ""){
												1;
											}else{
												if(${hist_class} ne ""){
													&logfile("cuprodigy_xml_balances_and_history__parse_history(): Not coded to handle \$hist_class value '".${hist_class}."' for ${hist_mbnum}/${hist_qualifier1}/${hist_qualifier2}.\n") if ${record_messages_in_logfile};
												}else{
													&logfile("cuprodigy_xml_balances_and_history__parse_history(): Unable to determine a \$hist_class value (having checked \%KNOWN_HIST_CLASS and checked \%KNOWN_EXPIRED_HIST_CLASS and tested for existance of values ${hist_class_tested_for}) for ${hist_mbnum}/${hist_qualifier1}/${hist_qualifier2}.\n") if ${record_messages_in_logfile};
												}
											}
										}
									}
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
		pop(@key_prefix); pop(@key_prefix);
	}
	if(${record_messages_in_logfile}){
		foreach $key (sort(keys(%ENCOUNTERED_UNKNOWN_HIST_CLASS))){
			&logfile("cuprodigy_xml_balances_and_history__parse_history(): History records have no related balance records from ${CTRL__SERVER_REFERENCE__CUPRODIGY} using ${cuprodigy_method_used} where ".$ENCOUNTERED_UNKNOWN_HIST_CLASS{${key}}." is '".(split(/$;/,${key}))[1]."'; skipping those history records.\n");
		}
	}
	if($CUSTOM{"custom_prehistory.pi"}>0){
		# The prehistory will only be included back to value in either $beg_ccyymmdd_dp or $beg_ccyymmdd_ln (not $query_ccyymmdd_dp nor $query_ccyymmdd_ln).
		if($CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE =~ /^\d{8}$/ and sprintf("%.0f",${CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE}) > 0){
			$prehistory_overlap_date=&date_add_CCYYMMDD(${CONF__CUSTOM_PREHISTORY__MAXDATE_IN_FILE},1);
			if    (${hist_class} eq "DP"){
				$beg_ccyymmdd_xx=${beg_ccyymmdd_dp};
				($fmt_beg_ccyymmdd_xx=${beg_ccyymmdd_xx})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
			}elsif(${hist_class} eq "LN"){
				$beg_ccyymmdd_xx=${beg_ccyymmdd_ln};
				($fmt_beg_ccyymmdd_xx=${beg_ccyymmdd_xx})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
			}elsif(${hist_class} eq "CC"){
				$beg_ccyymmdd_xx=${beg_ccyymmdd_ln};
				($fmt_beg_ccyymmdd_xx=${beg_ccyymmdd_xx})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
			}
			if($beg_ccyymmdd_xx =~ /^\d{8}$/ and $prehistory_overlap_date =~ /^\d{8}$/ and ${beg_ccyymmdd_xx} le ${prehistory_overlap_date}){
				if(${hist_class} eq "DP"){
					$prehistory_rows_and_columns=&custom_prehistory_dp(${beg_ccyymmdd_dp},${hist_mbnum},${hist_dp},${hist_dp_certnum});
					foreach $prehistory_row (split(/\n/,$prehistory_rows_and_columns)){
						next if $prehistory_row eq "";
						$prehistory_trandate=(split(/\t/,${prehistory_row}))[5];	# DMS/HomeCU table column ACCOUNTHISTORY.DATE column is position 5 (6th column)
						$prehistory_trandate=~s/[^-\d\/].*$//;
						$prehistory_trandate=&date_to_CCYYMMDD(${prehistory_trandate});
						push(@XML_MB_DP_HIST,join("\t",${prehistory_trandate},${prehistory_row}));
					}
				}
				if(${hist_class} eq "LN"){
					$prehistory_rows_and_columns=&custom_prehistory_ln(${beg_ccyymmdd_ln},${hist_mbnum},${hist_ln});
					foreach $prehistory_row (split(/\n/,$prehistory_rows_and_columns)){
						next if $prehistory_row eq "";
						$prehistory_trandate=(split(/\t/,${prehistory_row}))[3]; # DMS/HomeCU table column LOANHISTORY.DATE column is in position 3 (4th column)
						$prehistory_trandate=~s/[^-\d\/].*$//;
						$prehistory_trandate=&date_to_CCYYMMDD(${prehistory_trandate});
						push(@XML_MB_LN_HIST,join("\t",${prehistory_trandate},${prehistory_row}));
					}
				}
				if(${hist_class} eq "CC"){
					if(${CTRL__CUPRODIGY_HAS_CC_HIST}){
						if(${CTRL__SHORTEN_CC_TO_LAST_4_DIGITS}){
							&logfile("cuprodigy_xml_balances_and_history__parse_history(): Can not handle CC pre-history for ${hist_mbnum}/${hist_cc} because the short CC number values may change (hence causing problems with already loaded history).\n") if ${record_messages_in_logfile};
							# $prehistory_rows_and_columns.=&custom_prehistory_ln(${beg_ccyymmdd_ln},${hist_mbnum},${hist_cc});
							# foreach $prehistory_row (split(/\n/,$prehistory_rows_and_columns)){
							# 	next if $prehistory_row eq "";
							# 	$prehistory_trandate=(split(/\t/,${prehistory_row}))[3]; # DMS/HomeCU table column LOANHISTORY.DATE column is in position 3 (4th column)
							# 	$prehistory_trandate=~s/[^-\d\/].*$//;
							# 	$prehistory_trandate=&date_to_CCYYMMDD(${prehistory_trandate});
							# 	push(@XML_MB_LN_HIST,join("\t",${prehistory_trandate},${prehistory_row}));
							# }
						}else{
							$prehistory_rows_and_columns=&custom_prehistory_ln(${beg_ccyymmdd_ln},${hist_mbnum},${hist_cc});
							foreach $prehistory_row (split(/\n/,$prehistory_rows_and_columns)){
								next if $prehistory_row eq "";
								$prehistory_trandate=(split(/\t/,${prehistory_row}))[3]; # DMS/HomeCU table column LOANHISTORY.DATE column is in position 3 (4th column)
								$prehistory_trandate=~s/[^-\d\/].*$//;
								$prehistory_trandate=&date_to_CCYYMMDD(${prehistory_trandate});
								push(@XML_MB_LN_HIST,join("\t",${prehistory_trandate},${prehistory_row}));
							}
						}
					}
				}
			}
		}
	}
	for($idx=0;$idx<=$#XML_MB_DP_HIST;$idx++){
		$XML_MB_DP_HIST[${idx}]=~s/^[^\t]*\t//;
	}
	for($idx=0;$idx<=$#XML_MB_LN_HIST;$idx++){
		$XML_MB_LN_HIST[${idx}]=~s/^[^\t]*\t//;
	}
	for($idx=0;$idx<=$#XML_MB_CC_HIST;$idx++){
		$XML_MB_CC_HIST[${idx}]=~s/^[^\t]*\t//;
	}
	return(${rtrn_error_text});
}

sub shorten_sortkey_value_16{
   local($log_exception,$dms_sortkey,$dp_ln_cc,@key)=@_;
   local($dms_sortkey_orig);
	$dms_sortkey=~s/ *$//;
	if(length(${dms_sortkey}) > 16){
		$dms_sortkey_orig=${dms_sortkey};
		substr($dms_sortkey,16-4)="....";
	}
	return(${dms_sortkey});
}

sub cuprodigy_history_description{
   my($cuprodigy_transactioncode,@cuprodigy_others)=@_;
   my($rtrn);
   my($idx);
	if(${CONF__HIS__DESC_INCLUDE_TRANSACTION_CODE}){
		$rtrn=${cuprodigy_transactioncode};
	}else{
		$rtrn=shift(@cuprodigy_others);
	}
	for($idx=0;$idx<=$#cuprodigy_others;$idx++){
		if($cuprodigy_others[${idx}] ne "" and index($rtrn,$cuprodigy_others[${idx}])<$[){
			$rtrn.=" ; ".$cuprodigy_others[${idx}];
		}
	}
	return(${rtrn});
}

sub cuprodigy_xml_balances_and_history__parse_holds{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$record_messages_in_logfile,$single_dp_ln,$single_member,$single_account,$single_cert)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   # local($cuprodigy_xml_description);	# Set in cuprodigy_xml_balances_and_history()
   local(%HIST_BALS);
   local(%HIST_GROUPS);
   local($line);
   local(@f);
   local($timestamp);
   local($transaction_datetime);
   local($hold_class,$hold_mbnum,$hold_qualifier1,$hold_qualifier2);
   local($hold_dp,$hold_dp_certnum);
   local($hold_ln);
   local($hold_cc);
   local($hold_tracenumber_unique_group_seq);
   local($beg_yyyy,$beg_mm,$beg_dd);
   local($idx);
   local($key);
   local($tmp_cuprodigy_accountType);
   local($dms_xjo_overloaded_mbnum,$dms_xjo_overloaded_qualifier1);
   local($post_request_mode,$post_request_mode_seq);
   local($post_request_parallel_options)="";
   local(%SEQUENCE,$sequence_date);
   local(%CUDP_TRACENUMBER);
   local(%CUDP_TRANSACTIONID_ENCOUNTERED,%CUDP_TRANSACTIONID_DUPLICATE,$cudp_transactionid_duplicate);
   local(%KNOWN_HOLD_CLASS,$xjo_extracted_mb,$xjo_extracted_dp,$xjo_extracted_ln,$xjo_extracted_cc);
   local(%KNOWN_DP_DRAFT);
   local(%KNOWN_RELATED_MBNUM);
   local(%ENCOUNTERED_UNKNOWN_HOLD_CLASS);
   local(%XJO_PLEDGE_DUPS_IN_COMPOSIT_INQUIRY_AND_ACCOUNTDETAILINQUIRY);
   local($xjo_pledge_dups_in_composit_Inquiry_and_AccountDetailInquiry__key);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
	#
	# Expects populated (calling routine must have declared as "local()"):
	#	@XML_MB_UNIQID
	#	@XML_MB_DP_UNIQID
	#	@XML_MB_LN_UNIQID
	#	@XML_MB_CC_UNIQID
	#	@XML_MB_DP_BALS, @XML_MB_DP_GROUPS, @XML_MB_DP_ATTRS
	#	@XML_MB_LN_BALS, @XML_MB_LN_GROUPS, @XML_MB_LN_ATTRS
	#	@XML_MB_CC_BALS, @XML_MB_CC_GROUPS, @XML_MB_CC_ATTRS, %XML_MB_CC_TO_UNIQ, %XML_MB_CC_FROM_UNIQ
	#	@XML_MB_PLASTIC_CARDS, @XML_MB_PLASTIC_CARDS_WIP
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_HOLDS
	#
	undef(@XML_MB_HOLDS);
	for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
		@f=split(/\t/,$XML_MB_DP_BALS[${idx}]);
		$KNOWN_RELATED_MBNUM{$f[0]}=1;
		$KNOWN_HOLD_CLASS{$f[0],$f[0],$f[1],$f[2]}="DP";
		if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],$f[0],$f[1],$f[2]}=1; }
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_dp=$f[1])=~s/@\d\d*$//;
			$KNOWN_RELATED_MBNUM{${xjo_extracted_mb}}=1;
			$KNOWN_HOLD_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}="DP";
			if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}=1; }
		}
	}
	for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
		@f=split(/\t/,$XML_MB_LN_BALS[${idx}]);
		$KNOWN_RELATED_MBNUM{$f[0]}=1;
		$KNOWN_HOLD_CLASS{$f[0],$f[0],$f[1]}="LN";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_ln=$f[1])=~s/@\d\d*$//;
			$KNOWN_RELATED_MBNUM{${xjo_extracted_mb}}=1;
			$KNOWN_HOLD_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_ln}}="LN";
		}
	}
	for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
		@f=split(/\t/,$XML_MB_CC_BALS[${idx}]);
		$KNOWN_RELATED_MBNUM{$f[0]}=1;
		$KNOWN_HOLD_CLASS{$f[0],$f[0],$f[1]}="CC";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_cc=$f[1])=~s/@\d\d*$//;
			$KNOWN_RELATED_MBNUM{${xjo_extracted_mb}}=1;
			$KNOWN_HOLD_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_cc}}="CC";
		}
	}
	if(1){	# For Holds always include data from <submitMessageResponse><return><response><holds>
		$hold_tracenumber_unique_group_seq++;
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="holds",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="hold",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,$key_L07);
									$hold_class="";
									$cuprodigy_holdId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"holdId",${XML_SINGLE})};
									$cuprodigy_holdType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"holdType",${XML_SINGLE})};
									$cuprodigy_accountId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountId",${XML_SINGLE})};
									$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
									($tmp_cuprodigy_accountType=substr($cuprodigy_accountNumber,-6,4))=~s/ *$//;
									($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
									($hold_mbnum,$hold_qualifier1,$hold_qualifier2)=($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc,"0");
									if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
										$hold_qualifier2=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${hold_mbnum},${hold_qualifier1});
									}
									if    ($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}};
									}elsif($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}};
									}
									if    (${hold_class} eq "DP"){
										($hold_dp,$hold_dp_certnum)=(${hold_qualifier1},${hold_qualifier2});
									}elsif(${hold_class} eq "LN"){
										($hold_ln,$hold_qualifier2)=(${hold_qualifier1},"");
									}elsif(${hold_class} eq "CC"){
										($hold_cc,$hold_qualifier2)=(${hold_qualifier1},"");
									}else{
										$hold_class="";
										($ENCOUNTERED_UNKNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}}="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
									}
									if(${hold_class} eq "DP" or ${hold_class} eq "LN"){	# Intentionally excluding '${hold_class} eq "CC"' until I get an actual example of the XML
										$cuprodigy_amount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"amount",${XML_SINGLE})};
										$cuprodigy_dateReceived=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"dateReceived",${XML_SINGLE})};
										$cuprodigy_expireDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"expireDate",${XML_SINGLE})};
										$cuprodigy_message=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"message",${XML_SINGLE})};
										if(${cuprodigy_accountNumber__mb} ne ${cuprodigy_xml_request_membernumber}){
											if(${CONF__XJO__USE}){
												$cuprodigy_accountNumber__dplncc.='@'.${cuprodigy_accountNumber__mb};
											}
										}
										$dms_accountnumber=${cuprodigy_xml_request_membernumber};
										$dms_accounttype=${cuprodigy_accountNumber__dplncc};
										$dms_certnumber="0";
										if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
										}
										$dms_holdtype=( ${hold_class} eq "DP" ? "D" : "L" );
										($dms_postdate=${cuprodigy_dateReceived})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										($dms_expiredate=${cuprodigy_expireDate})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										$dms_amount=${cuprodigy_amount};
										$dms_description=&cuprodigy_holds_description(1,"holds",${cuprodigy_holdType},${cuprodigy_expireDate},"",${cuprodigy_message});
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
										$dms_tracenumber="";
										$dms_tracenumber_part1="";
										$dms_tracenumber_part2="";
										if(${CTRL__HOLDS__GENERATED_TRACENUMBER_COULD_BE_TOO_LONG}){
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											($dms_tracenumber_part1=sprintf("%lx",${dms_tracenumber_part1}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part1}) < 7){
												$dms_tracenumber_part1=substr("0000000".${dms_tracenumber_part1},-7,7);
											}
											($dms_tracenumber_part2=sprintf("%lx",${cuprodigy_holdId}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part2}) < 11){
												$dms_tracenumber_part2=substr("00000000000".${dms_tracenumber_part2},-11,11);
											}
										}else{
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											$dms_tracenumber_part2=${cuprodigy_holdId};
											if(length(${dms_tracenumber_part2}) < 10){
												$dms_tracenumber_part2=substr("0000000000".${dms_tracenumber_part2},-10,10);
											}
										}
										if(0){
											$dms_tracenumber=${dms_tracenumber_part1}.${dms_tracenumber_part2};
										}else{
											$dms_tracenumber=${dms_tracenumber_part1}.pack("c",ord("a")-1+${hold_tracenumber_unique_group_seq}).substr(${dms_tracenumber_part2},1);
										}
										push(@XML_MB_HOLDS,
											join("\t",
												${dms_accountnumber},
												${dms_accounttype},
												${dms_certnumber},
												${dms_holdtype},
												${dms_tracenumber},
												${dms_postdate},
												${dms_expiredate},
												${dms_amount},
												${dms_description},
											)
										);
									}else{
										if(${record_messages_in_logfile}){
											if(${cuprodigy_accountNumber__mb} eq ${cuprodigy_xml_request_membernumber} or !${CTRL__CUPRODIGY_GLITCH__HOLDS__INCLUDES_OTHER_MEMBERS_PENDINGS_FOR_CROSS_ACCOUNT_TRANSFERS}){
												&logfile("cuprodigy_xml_balances_and_history__parse_holds(): Not coded to handle \$hold_class value '".${hold_class}."' for ${hold_mbnum}/${hold_qualifier1}/${hold_qualifier2}.\n") if ${hold_class} ne "";	# The %ENCOUNTERED_UNKNOWN_HOLD_CLASS has already been populated to handle (via logfile()) when $hold_class is "";
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(${CTRL__HOLDS__INCLUDE_PLEDGES}){	# For Holds optionally include data from <submitMessageResponse><return><response><pledges>
		$hold_tracenumber_unique_group_seq++;
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="pledges",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="pledge",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,$key_L07);
									$hold_class="";
									$cuprodigy_pledgeId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"pledgeId",${XML_SINGLE})};
									$cuprodigy_pledgedTo=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"pledgedTo",${XML_SINGLE})};
									$cuprodigy_pledgedFrom=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"pledgedFrom",${XML_SINGLE})};
									($tmp_cuprodigy_accountType=substr($cuprodigy_pledgedFrom,-6,4))=~s/ *$//;
									($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_pledgedFrom});
									($hold_mbnum,$hold_qualifier1,$hold_qualifier2)=($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc,"0");
									if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
										$hold_qualifier2=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${hold_mbnum},${hold_qualifier1});
									}
									if    ($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}};
									}elsif($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}};
									}
									if    (${hold_class} eq "DP"){
										($hold_dp,$hold_dp_certnum)=(${hold_qualifier1},${hold_qualifier2});
									}elsif(${hold_class} eq "LN"){
										($hold_ln,$hold_qualifier2)=(${hold_qualifier1},"");
									}elsif(${hold_class} eq "CC"){
										($hold_cc,$hold_qualifier2)=(${hold_qualifier1},"");
									}else{
										$hold_class="";
										($ENCOUNTERED_UNKNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${cuprodigy_pledgedFrom}}="<".join("><",split(/$;/,$key_prefix),"pledgedFrom").">")=~s/<[0-9][0-9]*>//g;
									}
									if(${hold_class} eq "DP" or ${hold_class} eq "LN"){	# Intentionally excluding '${hold_class} eq "CC"' until I get an actual example of the XML
										$cuprodigy_amountPledged=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"amountPledged",${XML_SINGLE})};
										$cuprodigy_pledgedDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"pledgedDate",${XML_SINGLE})};
										$cuprodigy_remarks=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"remarks",${XML_SINGLE})};
										if(${cuprodigy_accountNumber__mb} ne ${cuprodigy_xml_request_membernumber}){
											if(${CONF__XJO__USE}){
												$cuprodigy_accountNumber__dplncc.='@'.${cuprodigy_accountNumber__mb};
											}
										}
										$dms_accountnumber=${cuprodigy_xml_request_membernumber};
										$dms_accounttype=${cuprodigy_accountNumber__dplncc};
										$dms_certnumber="0";
										if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
										}
										$dms_holdtype=( ${hold_class} eq "DP" ? "D" : "L" );
										($dms_postdate=${cuprodigy_pledgedDate})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										if($CTRL__HOLDS__PLEDGE__FAKE_END_YYYYMMDD_VALUE =~ /^today$|^now$/i){
											($dms_expiredate=substr(&timestamp(),0,8))=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										}else{
											($dms_expiredate=${CTRL__HOLDS__PLEDGE__FAKE_END_YYYYMMDD_VALUE})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										}
										$dms_amount=${cuprodigy_amountPledged};
										$dms_description=&cuprodigy_holds_description(1,"pledges","Pledge","",&cuprodigy_holds_description__account_format(${cuprodigy_pledgedTo}),"Funds pledged to account ".&cuprodigy_holds_description__account_format(${cuprodigy_pledgedTo}),${cuprodigy_remarks});
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
										$dms_tracenumber="";
										$dms_tracenumber_part1="";
										$dms_tracenumber_part2="";
										if(${CTRL__HOLDS__GENERATED_TRACENUMBER_COULD_BE_TOO_LONG}){
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											($dms_tracenumber_part1=sprintf("%lx",${dms_tracenumber_part1}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part1}) < 7){
												$dms_tracenumber_part1=substr("0000000".${dms_tracenumber_part1},-7,7);
											}
											($dms_tracenumber_part2=sprintf("%lx",${cuprodigy_pledgeId}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part2}) < 11){
												$dms_tracenumber_part2=substr("00000000000".${dms_tracenumber_part2},-11,11);
											}
										}else{
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											$dms_tracenumber_part2=${cuprodigy_pledgeId};
											if(length(${dms_tracenumber_part2}) < 10){
												$dms_tracenumber_part2=substr("0000000000".${dms_tracenumber_part2},-10,10);
											}
										}
										if(0){
											$dms_tracenumber=${dms_tracenumber_part1}.${dms_tracenumber_part2};
										}else{
											$dms_tracenumber=${dms_tracenumber_part1}.pack("c",ord("a")-1+${hold_tracenumber_unique_group_seq}).substr(${dms_tracenumber_part2},1);
										}
										$xjo_pledge_dups_in_composit_Inquiry_and_AccountDetailInquiry__key=join($;,
												${dms_accountnumber},
												${dms_accounttype},
												${dms_certnumber},
												${dms_holdtype},
												${dms_tracenumber},
												${dms_postdate},
												${dms_expiredate},
												${dms_amount},
												${dms_description},
										);
										if(!$XJO_PLEDGE_DUPS_IN_COMPOSIT_INQUIRY_AND_ACCOUNTDETAILINQUIRY{${xjo_pledge_dups_in_composit_Inquiry_and_AccountDetailInquiry__key}}){
											push(@XML_MB_HOLDS,
												join("\t",
													${dms_accountnumber},
													${dms_accounttype},
													${dms_certnumber},
													${dms_holdtype},
													${dms_tracenumber},
													${dms_postdate},
													${dms_expiredate},
													${dms_amount},
													${dms_description},
												)
											);
											$XJO_PLEDGE_DUPS_IN_COMPOSIT_INQUIRY_AND_ACCOUNTDETAILINQUIRY{${xjo_pledge_dups_in_composit_Inquiry_and_AccountDetailInquiry__key}}=1;
										}
									}else{
										if(${record_messages_in_logfile}){
											if(${cuprodigy_accountNumber__mb} eq ${cuprodigy_xml_request_membernumber} or !${CTRL__CUPRODIGY_GLITCH__HOLDS__INCLUDES_OTHER_MEMBERS_PENDINGS_FOR_CROSS_ACCOUNT_TRANSFERS}){
												&logfile("cuprodigy_xml_balances_and_history__parse_holds(): Not coded to handle \$hold_class value '".${hold_class}."' for ${hold_mbnum}/${hold_qualifier1}/${hold_qualifier2}.\n") if ${hold_class} ne "";	# The %ENCOUNTERED_UNKNOWN_HOLD_CLASS has already been populated to handle (via logfile()) when $hold_class is "";
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(${CTRL__HOLDS__INCLUDE_ACH_CREDITS}){	# For Holds optionally include data from <submitMessageResponse><return><response><achCredits>
		$hold_tracenumber_unique_group_seq++;
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="achCredits",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="achCredit",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,$key_L07);
									$hold_class="";
									$cuprodigy_recordId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"recordId",${XML_SINGLE})};
									$cuprodigy_accountId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountId",${XML_SINGLE})};
									$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
									($tmp_cuprodigy_accountType=substr($cuprodigy_accountNumber,-6,4))=~s/ *$//;
									($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
									($hold_mbnum,$hold_qualifier1,$hold_qualifier2)=($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc,"0");
									if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
										$hold_qualifier2=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${hold_mbnum},${hold_qualifier1});
									}
									if    ($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}};
									}elsif($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}};
									}
									if    (${hold_class} eq "DP"){
										($hold_dp,$hold_dp_certnum)=(${hold_qualifier1},${hold_qualifier2});
									}elsif(${hold_class} eq "LN"){
										($hold_ln,$hold_qualifier2)=(${hold_qualifier1},"");
									}elsif(${hold_class} eq "CC"){
										($hold_cc,$hold_qualifier2)=(${hold_qualifier1},"");
									}else{
										$hold_class="";
										($ENCOUNTERED_UNKNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}}="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
									}
									if(${hold_class} eq "DP" or ${hold_class} eq "LN"){	# Intentionally excluding '${hold_class} eq "CC"' until I get an actual example of the XML
										$cuprodigy_companyName=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"companyName",${XML_SINGLE})};
										$cuprodigy_description=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"description",${XML_SINGLE})};
										$cuprodigy_amount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"amount",${XML_SINGLE})};
										$cuprodigy_effectiveDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"effectiveDate",${XML_SINGLE})};
										if(${cuprodigy_accountNumber__mb} ne ${cuprodigy_xml_request_membernumber}){
											if(${CONF__XJO__USE}){
												$cuprodigy_accountNumber__dplncc.='@'.${cuprodigy_accountNumber__mb};
											}
										}
										$dms_accountnumber=${cuprodigy_xml_request_membernumber};
										$dms_accounttype=${cuprodigy_accountNumber__dplncc};
										$dms_certnumber="0";
										if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
										}
										$dms_holdtype=( ${hold_class} eq "DP" ? "D" : "L" );
										($dms_expiredate=${cuprodigy_effectiveDate})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										if($CTRL__HOLDS__ACH_CREDITS__FAKE_BEGIN_YYYYMMDD_VALUE =~ /^today$|^now$/i){
											($dms_postdate=substr(&timestamp(),0,8))=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
											if(1){
												# When faking the Pre-Auth ACH "post date" value (because CUProdigy does not provide it) with the floating value of "today" make sure that the faked value is at least minimum 1 day before the Pre-Auth ACH's "expire date" value
												if(${dms_postdate} ge ${dms_expiredate} and $dms_expiredate =~ /^\d{4}-\d{2}-\d{2}/){
													while(${dms_postdate} ge ${dms_expiredate}){
														($beg_yyyy,$beg_mm,$beg_dd)=split(/-/,${dms_postdate});
														$beg_dd=sprintf("%02.0f",${beg_dd}-1);
														if($beg_dd ne "00"){ $dms_postdate=join("-",${beg_yyyy},${beg_mm},${beg_dd}); next ; }
														$beg_mm=sprintf("%02.0f",${beg_mm}-1);
														
														if($beg_mm ne "00"){ $beg_dd=&date_last_day_of_month(${beg_yyyy},${beg_mm}); $dms_postdate=join("-",${beg_yyyy},${beg_mm},${beg_dd}); next ; }
														$beg_yyyy=sprintf("%04.0f",${beg_yyyy}-1); $beg_mm="12"; $beg_dd="31";
														$dms_postdate=join("-",${beg_yyyy},${beg_mm},${beg_dd});
													}
												}
											}
										}else{
											($dms_postdate=${CTRL__HOLDS__ACH_CREDITS__FAKE_BEGIN_YYYYMMDD_VALUE})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										}
										$dms_amount=${cuprodigy_amount};
										if   (${CTRL__HOLDS__ACH_CREDITS__INCLUDES_DEBITS_WITHOUT_SIGNED_AMOUNT}){
											$dms_description=&cuprodigy_holds_description(0,"ach","Pre-Authorized ACH",${dms_expiredate},"",${cuprodigy_companyName},${cuprodigy_description});
										}elsif(sprintf("%.2f",${dms_amount}) >= 0.00){
											$dms_description=&cuprodigy_holds_description(0,"achCredits","Pre-Authorized ACH Credit (withdrawal)",${dms_expiredate},"",${cuprodigy_companyName},${cuprodigy_description});
											if($dms_holdtype eq "D" and ${CTRL__HOLDS__ACH_CREDITS__DP_ENCODE_ACH_CREDIT_AS_HOMECU_MODE_PENDING}){
												$dms_holdtype="d"	# Override HOLDS.HOLDTYPE with HomeCU mode "Pending" for DPs (lower-case "d" instead of upper-case "D") because in CUProdigy API the DP's Available Balance is not affected by the DP's ACH Credit Hold record, and the HomeCU mode "Pending" allows the Hold record to be included in the response data but trigger HomeCU to not display the Hold record to the member
											}
											if($dms_holdtype eq "L" and ${CTRL__HOLDS__ACH_CREDITS__LN_ENCODE_ACH_CREDIT_AS_HOMECU_MODE_PENDING}){
												$dms_holdtype="l"	# Override HOLDS.HOLDTYPE with HomeCU mode "Pending" for LNs (lower-case "l" instead of upper-case "L") because in CUProdigy API the LN's Available Credit is not affected by the LN's ACH Credit Hold record, and the HomeCU mode "Pending" allows the Hold record to be included in the response data but trigger HomeCU to not display the Hold record to the member
											}
										}else{
											$dms_description=&cuprodigy_holds_description(0,"achDebits","Pre-Authorized ACH Debit (deposit)",${dms_expiredate},"",${cuprodigy_companyName},${cuprodigy_description});
											if($dms_holdtype eq "D" and ${CTRL__HOLDS__ACH_CREDITS__DP_ENCODE_ACH_DEBIT_AS_HOMECU_MODE_PENDING}){
												$dms_holdtype="d"	# Override HOLDS.HOLDTYPE with HomeCU mode "Pending" for DPs (lower-case "d" instead of upper-case "D") because in CUProdigy API the DP's Available Balance is not affected by the DP's ACH Debit Hold record, and the HomeCU mode "Pending" allows the Hold record to be included in the response data but trigger HomeCU to not display the Hold record to the member
											}
											if($dms_holdtype eq "L" and ${CTRL__HOLDS__ACH_CREDITS__LN_ENCODE_ACH_DEBIT_AS_HOMECU_MODE_PENDING}){
												$dms_holdtype="l"	# Override HOLDS.HOLDTYPE with HomeCU mode "Pending" for LNs (lower-case "l" instead of upper-case "L") because in CUProdigy API the LN's Available Credit is not affected by the LN's ACH Debit Hold record, and the HomeCU mode "Pending" allows the Hold record to be included in the response data but trigger HomeCU to not display the Hold record to the member
											}
										}
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
										$dms_tracenumber="";
										$dms_tracenumber_part1="";
										$dms_tracenumber_part2="";
										if(${CTRL__HOLDS__GENERATED_TRACENUMBER_COULD_BE_TOO_LONG}){
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											($dms_tracenumber_part1=sprintf("%lx",${dms_tracenumber_part1}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part1}) < 7){
												$dms_tracenumber_part1=substr("0000000".${dms_tracenumber_part1},-7,7);
											}
											($dms_tracenumber_part2=sprintf("%lx",${cuprodigy_recordId}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part2}) < 11){
												$dms_tracenumber_part2=substr("00000000000".${dms_tracenumber_part2},-11,11);
											}
										}else{
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											$dms_tracenumber_part2=${cuprodigy_recordId};
											if(length(${dms_tracenumber_part2}) < 10){
												$dms_tracenumber_part2=substr("0000000000".${dms_tracenumber_part2},-10,10);
											}
										}
										if(0){
											$dms_tracenumber=${dms_tracenumber_part1}.${dms_tracenumber_part2};
										}else{
											$dms_tracenumber=${dms_tracenumber_part1}.pack("c",ord("a")-1+${hold_tracenumber_unique_group_seq}).substr(${dms_tracenumber_part2},1);
										}
										push(@XML_MB_HOLDS,
											join("\t",
												${dms_accountnumber},
												${dms_accounttype},
												${dms_certnumber},
												${dms_holdtype},
												${dms_tracenumber},
												${dms_postdate},
												${dms_expiredate},
												${dms_amount},
												${dms_description},
											)
										);
									}else{
										if(${record_messages_in_logfile}){
											if(${cuprodigy_accountNumber__mb} eq ${cuprodigy_xml_request_membernumber} or !${CTRL__CUPRODIGY_GLITCH__HOLDS__INCLUDES_OTHER_MEMBERS_PENDINGS_FOR_CROSS_ACCOUNT_TRANSFERS}){
												&logfile("cuprodigy_xml_balances_and_history__parse_holds(): Not coded to handle \$hold_class value '".${hold_class}."' for ${hold_mbnum}/${hold_qualifier1}/${hold_qualifier2}.\n") if ${hold_class} ne "";	# The %ENCOUNTERED_UNKNOWN_HOLD_CLASS has already been populated to handle (via logfile()) when $hold_class is "";
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(${CTRL__HOLDS__INCLUDE_PENDING_CREDITS}){	# For Holds optionally include data from <submitMessageResponse><return><response><pendingCredits>
		$hold_tracenumber_unique_group_seq++;
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="pendingCredits",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="pendingCredit",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,$key_L07);
									$hold_class="";
									$cuprodigy_pendingCreditId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"pendingCreditId",${XML_SINGLE})};
									$cuprodigy_accountId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountId",${XML_SINGLE})};
									$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
									($tmp_cuprodigy_accountType=substr($cuprodigy_accountNumber,-6,4))=~s/ *$//;
									($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
									($hold_mbnum,$hold_qualifier1,$hold_qualifier2)=($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc,"0");
									if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
										$hold_qualifier2=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${hold_mbnum},${hold_qualifier1});
									}
									if    ($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1},${hold_qualifier2}};
									}elsif($KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}} ne ""){
										$hold_class=$KNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${hold_mbnum},${hold_qualifier1}};
									}
									if    (${hold_class} eq "DP"){
										($hold_dp,$hold_dp_certnum)=(${hold_qualifier1},${hold_qualifier2});
									}elsif(${hold_class} eq "LN"){
										($hold_ln,$hold_qualifier2)=(${hold_qualifier1},"");
									}elsif(${hold_class} eq "CC"){
										($hold_cc,$hold_qualifier2)=(${hold_qualifier1},"");
									}else{
										$hold_class="";
										($ENCOUNTERED_UNKNOWN_HOLD_CLASS{${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber}}="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
									}
									if(${hold_class} eq "DP" or ${hold_class} eq "LN"){	# Intentionally excluding '${hold_class} eq "CC"' until I get an actual example of the XML
										$cuprodigy_message=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"message",${XML_SINGLE})};
										$cuprodigy_amount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"amount",${XML_SINGLE})};
										$cuprodigy_dateReceived=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"dateReceived",${XML_SINGLE})};
										if(${cuprodigy_accountNumber__mb} ne ${cuprodigy_xml_request_membernumber}){
											if(${CONF__XJO__USE}){
												$cuprodigy_accountNumber__dplncc.='@'.${cuprodigy_accountNumber__mb};
											}
										}
										$dms_accountnumber=${cuprodigy_xml_request_membernumber};
										$dms_accounttype=${cuprodigy_accountNumber__dplncc};
										$dms_certnumber="0";
										if(${CONF__DP_CERTNUMBER__FAKE_TO_BACKWARD_COMPATIBLE} and $XML_MB_DP_CUPRODIGY_ACCOUNTCATEGORY{${tmp_cuprodigy_accountType}} eq ${CTRL__LIST_ACCOUNTCATEGORY_DP__CUPRODIGY_CERTIFICATES}){
											$dms_certnumber=&cuprodigy_xml_balances_and_history__fake_dp_certnumber(${dms_accountnumber},${dms_accounttype});
										}
										$dms_holdtype=( ${hold_class} eq "DP" ? "D" : "L" );
										($dms_postdate=${cuprodigy_dateReceived})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										if($CTRL__HOLDS__PENDING_CREDITS__FAKE_END_YYYYMMDD_VALUE =~ /^today$|^now$/i){
											($dms_expiredate=substr(&timestamp(),0,8))=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										}else{
											($dms_expiredate=${CTRL__HOLDS__PENDING_CREDITS__FAKE_END_YYYYMMDD_VALUE})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										}
										$dms_amount=${cuprodigy_amount};
										if   (${CTRL__HOLDS__PENDING_CREDITS__INCLUDES_DEBITS_WITHOUT_SIGNED_AMOUNT}){
											$dms_description=&cuprodigy_holds_description(0,"pending","Pending Chargeback","","",${cuprodigy_message});
										}elsif(sprintf("%.2f",${dms_amount}) >= 0.00){
											$dms_description=&cuprodigy_holds_description(0,"pendingCredits","Pending Chargeback Credit (withdrawal)","","",${cuprodigy_message});
										}else{
											$dms_description=&cuprodigy_holds_description(0,"pendingDebits","Pending Chargeback Debit (deposit)","","",${cuprodigy_message});
										}
										if(length(${dms_description}) > 255){ $dms_description=&htmlfilter_strip_trailing_incomplete_entity(substr(${dms_description},0,255)); }
										$dms_tracenumber="";
										$dms_tracenumber_part1="";
										$dms_tracenumber_part2="";
										if(${CTRL__HOLDS__GENERATED_TRACENUMBER_COULD_BE_TOO_LONG}){
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											($dms_tracenumber_part1=sprintf("%lx",${dms_tracenumber_part1}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part1}) < 7){
												$dms_tracenumber_part1=substr("0000000".${dms_tracenumber_part1},-7,7);
											}
											($dms_tracenumber_part2=sprintf("%lx",${cuprodigy_pendingCreditId}))=~tr/a-z/A-Z/;
											if(length(${dms_tracenumber_part2}) < 11){
												$dms_tracenumber_part2=substr("00000000000".${dms_tracenumber_part2},-11,11);
											}
										}else{
											($dms_tracenumber_part1=${dms_postdate})=~s/[^\d]//g;
											$dms_tracenumber_part2=${cuprodigy_pendingCreditId};
											if(length(${dms_tracenumber_part2}) < 10){
												$dms_tracenumber_part2=substr("0000000000".${dms_tracenumber_part2},-10,10);
											}
										}
										if(0){
											$dms_tracenumber=${dms_tracenumber_part1}.${dms_tracenumber_part2};
										}else{
											$dms_tracenumber=${dms_tracenumber_part1}.pack("c",ord("a")-1+${hold_tracenumber_unique_group_seq}).substr(${dms_tracenumber_part2},1);
										}
										push(@XML_MB_HOLDS,
											join("\t",
												${dms_accountnumber},
												${dms_accounttype},
												${dms_certnumber},
												${dms_holdtype},
												${dms_tracenumber},
												${dms_postdate},
												${dms_expiredate},
												${dms_amount},
												${dms_description},
											)
										);
									}else{
										if(${record_messages_in_logfile}){
											if(${cuprodigy_accountNumber__mb} eq ${cuprodigy_xml_request_membernumber} or !${CTRL__CUPRODIGY_GLITCH__HOLDS__INCLUDES_OTHER_MEMBERS_PENDINGS_FOR_CROSS_ACCOUNT_TRANSFERS}){
												&logfile("cuprodigy_xml_balances_and_history__parse_holds(): Not coded to handle \$hold_class value '".${hold_class}."' for ${hold_mbnum}/${hold_qualifier1}/${hold_qualifier2}.\n") if ${hold_class} ne "";	# The %ENCOUNTERED_UNKNOWN_HOLD_CLASS has already been populated to handle (via logfile()) when $hold_class is "";
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	foreach $key (sort(keys(%ENCOUNTERED_UNKNOWN_HOLD_CLASS))){
		# For some unknown reason the CUProdigy interface is including hold related data (Pending, Pledges, ACH Credits, Pending Credits) for other members with no obvious relationship to the requesting member.
		if(${record_messages_in_logfile}){
			if(0){
				# Log all hold data exceptions regardless of if a relation to the requesting member has been detected.
				&logfile("cuprodigy_xml_balances_and_history__parse_holds(): Hold records have no related balance records from ${CTRL__SERVER_REFERENCE__CUPRODIGY} using ${cuprodigy_method_used} where ".$ENCOUNTERED_UNKNOWN_HOLD_CLASS{${key}}." is '".(split(/$;/,${key}))[1]."'; skipping those hold records.\n");
			}else{
				# Log only the hold data exceptions where a relation to the requesting member has been detected.
				($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc((split(/$;/,${key}))[1]);
				if($KNOWN_RELATED_MBNUM{${cuprodigy_accountNumber__mb}}){
					&logfile("cuprodigy_xml_balances_and_history__parse_holds(): Hold records have no related balance records from ${CTRL__SERVER_REFERENCE__CUPRODIGY} using ${cuprodigy_method_used} where ".$ENCOUNTERED_UNKNOWN_HOLD_CLASS{${key}}." is '".(split(/$;/,${key}))[1]."'; skipping those hold records.\n");
				}
			}
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_holds_description{
   my($affects_available_balance,$holdgroup,$cuprodigy_holdType,$cuprodigy_expireDate,$cuprodigy_pledgedTo_formatted,@cuprodigy_others)=@_;
   my($rtrn);
   my($idx);
   my(@f);
   my($holdgroup_desc);
	if    ($holdgroup =~ /^holds$/i){
		$holdgroup_desc="Hold";
	}elsif($holdgroup =~ /^pledges$/i){
		$holdgroup_desc="Pledge";
	}elsif($holdgroup =~ /^ach$/i){
		$holdgroup_desc="ACH";
	}elsif($holdgroup =~ /^achCredits$/i){
		if($cuprodigy_holdType !~ /withdrawal/i){
			$holdgroup_desc="ACH credit (withdrawal)";
		}else{
			$holdgroup_desc="ACH credit";
		}
	}elsif($holdgroup =~ /^achDebits$/i){
		if($cuprodigy_holdType !~ /deposit/i){
			$holdgroup_desc="ACH debit (deposit)";
		}else{
			$holdgroup_desc="ACH debit";
		}
	}elsif($holdgroup =~ /^pending$/i){
		$holdgroup_desc="Chargeback";
	}elsif($holdgroup =~ /^pendingCredits$/i){
		if($cuprodigy_holdType !~ /withdrawal/i){
			$holdgroup_desc="Chargeback credit (withdrawal)";
		}else{
			$holdgroup_desc="Chargeback credit";
		}
	}elsif($holdgroup =~ /^pendingDebits$/i){
		if($cuprodigy_holdType !~ /deposit/i){
			$holdgroup_desc="Chargeback debit (deposit)";
		}else{
			$holdgroup_desc="Chargeback debit";
		}
	}else{
		if($cuprodigy_holdType !~ /^\s*$/){
			$holdgroup_desc=${cuprodigy_holdType};
		}else{
			$holdgroup_desc=${holdgroup};
		}
	}
	if($holdgroup =~ /^holds$/i){
		$rtrn=${holdgroup_desc}." for ".${cuprodigy_holdType};
	}else{
		$rtrn=${cuprodigy_holdType};
	}
	if(!${affects_available_balance}){
			$rtrn.=" [does not affect available balance]";
	}
	for($idx=0;$idx<=$#cuprodigy_others;$idx++){
		if($cuprodigy_others[${idx}] !~ /^\s*$/ and index($rtrn,$cuprodigy_others[${idx}])<$[){
			if(${rtrn} eq ""){
				$rtrn.=$cuprodigy_others[${idx}];
			}else{
				$rtrn.=" ; ".$cuprodigy_others[${idx}];
			}
			$rtrn=~s/  *$//;
		}
	}
	$cuprodigy_expireDate=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
	if($cuprodigy_expireDate !~ /^\s*$/){
		if(${rtrn} ne ""){
			$rtrn.=" ; ";
		}
		$rtrn.="This ${holdgroup_desc} is due to expire on or after ${cuprodigy_expireDate}";
	}elsif($holdgroup =~ /^pending$/i){
		1;
	}elsif($holdgroup =~ /^pendingCredits$/i){
		1;
	}elsif($holdgroup =~ /^pendingDebits$/i){
		1;
	}else{
		if(${rtrn} ne ""){
			$rtrn.=" ; ";
		}
		if($holdgroup =~ /^pledges$/i and $cuprodigy_pledgedTo_formatted !~ /^\s*$/){
			$rtrn.="This ${holdgroup_desc} expires when account ${cuprodigy_pledgedTo_formatted} has closed";
		}else{
			$rtrn.="This ${holdgroup_desc} never expires";
		}
	}
	return(${rtrn});
}

sub cuprodigy_holds_description__account_format{
   local($cuprodigy_accountNumber)=@_;
   local($memberNumber,$accountType,$accountSequence);
   local($cuprodigy_hold_text_format_for_account);
	$accountSequence=substr(${cuprodigy_accountNumber},-2,2);
	$accountType=substr(${cuprodigy_accountNumber},-6,4);
	$memberNumber=substr(${cuprodigy_accountNumber},0,length(${cuprodigy_accountNumber})-6);
	($cuprodigy_hold_text_format_for_account=${memberNumber}."-".${accountType}."-".${accountSequence})=~s/ //g;
	return(${cuprodigy_hold_text_format_for_account});
}

sub cuprodigy_xml_balances_and_history__parse_plastic_cards{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$reuse_random_17_bytes,$record_messages_in_logfile,$single_dp_ln,$single_member,$single_account,$single_cert)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   # local($cuprodigy_xml_description);	# Set in cuprodigy_xml_balances_and_history()
   local($use_as_clientid);
   local(%HIST_BALS);
   local(%HIST_GROUPS);
   local($line);
   local(@f);
   local($timestamp);
   local($transaction_datetime);
   local($XML_has_branch_cardInfo)=0;
   local($plastic_card_class,$plastic_card_mbnum,$plastic_card_qualifier1,$plastic_card_qualifier2);
   local($plastic_card_dp,$plastic_card_dp_certnum);
   local($plastic_card_ln);
   local($plastic_card_cc);
   local($plastic_card_tracenumber_unique_group_seq);
   local($beg_yyyy,$beg_mm,$beg_dd);
   local($idx);
   local($key);
   local($tmp_cuprodigy_accountType);
   local($dms_xjo_overloaded_mbnum,$dms_xjo_overloaded_qualifier1);
   local($post_request_mode,$post_request_mode_seq);
   local($post_request_parallel_options)="";
   local(%SEQUENCE,$sequence_date);
   local(%CUDP_TRACENUMBER);
   local(%CUDP_TRANSACTIONID_ENCOUNTERED,%CUDP_TRANSACTIONID_DUPLICATE,$cudp_transactionid_duplicate);
   local(%KNOWN_PLASTIC_CARD_CLASS,$xjo_extracted_mb,$xjo_extracted_dp,$xjo_extracted_ln,$xjo_extracted_cc);
   local(%KNOWN_DP_DRAFT);
   local(%KNOWN_RELATED_MBNUM);
   local(%ENCOUNTERED_UNKNOWN_PLASTIC_CARD_CLASS);
   local(%XJO_PLEDGE_DUPS_IN_COMPOSIT_INQUIRY_AND_ACCOUNTDETAILINQUIRY);
   local($xjo_pledge_dups_in_composit_Inquiry_and_AccountDetailInquiry__key);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
	#
	# Expects populated (calling routine must have declared as "local()"):
	#	@XML_MB_UNIQID
	#	@XML_MB_DP_UNIQID
	#	@XML_MB_LN_UNIQID
	#	@XML_MB_CC_UNIQID
	#	@XML_MB_DP_BALS, @XML_MB_DP_GROUPS, @XML_MB_DP_ATTRS
	#	@XML_MB_LN_BALS, @XML_MB_LN_GROUPS, @XML_MB_LN_ATTRS
	#	@XML_MB_CC_BALS, @XML_MB_CC_GROUPS, @XML_MB_CC_ATTRS, %XML_MB_CC_TO_UNIQ, %XML_MB_CC_FROM_UNIQ
	#	@XML_MB_PLASTIC_CARDS, @XML_MB_PLASTIC_CARDS_WIP
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_PLASTIC_CARDS, @XML_MB_PLASTIC_CARDS_WIP
	#
	undef(@XML_MB_PLASTIC_CARDS);
	undef(@XML_MB_PLASTIC_CARDS_WIP);
	for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
		@f=split(/\t/,$XML_MB_DP_BALS[${idx}]);
		$KNOWN_RELATED_MBNUM{$f[0]}=1;
		$KNOWN_PLASTIC_CARD_CLASS{$f[0],$f[0],$f[1],$f[2]}="DP";
		if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],$f[0],$f[1],$f[2]}=1; }
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_dp=$f[1])=~s/@\d\d*$//;
			$KNOWN_RELATED_MBNUM{${xjo_extracted_mb}}=1;
			$KNOWN_PLASTIC_CARD_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}="DP";
			if($f[3] =~ /^Y$/i){ $KNOWN_DP_DRAFT{$f[0],${xjo_extracted_mb},${xjo_extracted_dp},$f[2]}=1; }
		}
	}
	for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
		@f=split(/\t/,$XML_MB_LN_BALS[${idx}]);
		$KNOWN_RELATED_MBNUM{$f[0]}=1;
		$KNOWN_PLASTIC_CARD_CLASS{$f[0],$f[0],$f[1]}="LN";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_ln=$f[1])=~s/@\d\d*$//;
			$KNOWN_RELATED_MBNUM{${xjo_extracted_mb}}=1;
			$KNOWN_PLASTIC_CARD_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_ln}}="LN";
		}
	}
	for($idx=0;$idx<=$#XML_MB_CC_BALS;$idx++){
		@f=split(/\t/,$XML_MB_CC_BALS[${idx}]);
		$KNOWN_RELATED_MBNUM{$f[0]}=1;
		$KNOWN_PLASTIC_CARD_CLASS{$f[0],$f[0],$f[1]}="CC";
		if(${CONF__XJO__USE} and $f[1]=~/@\d\d*$/){
			($xjo_extracted_mb=$f[1])=~s/^.*@//;
			($xjo_extracted_cc=$f[1])=~s/@\d\d*$//;
			$KNOWN_RELATED_MBNUM{${xjo_extracted_mb}}=1;
			$KNOWN_PLASTIC_CARD_CLASS{$f[0],${xjo_extracted_mb},${xjo_extracted_cc}}="CC";
		}
	}
	if(1){	# For Plastic Cards always include data from <submitMessageResponse><return><response><cardInfo>
		$plastic_card_tracenumber_unique_group_seq++;
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="cardInfo",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								$XML_has_branch_cardInfo=1;
								for($tag_L07="card",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,$key_L07);
									$cuprodigy_cardType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"cardType",${XML_SINGLE})};
									$cuprodigy_cardNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"cardNumber",${XML_SINGLE})};
									$cuprodigy_issueDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"issueDate",${XML_SINGLE})};
									$cuprodigy_expireDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"expireDate",${XML_SINGLE})};
									$cuprodigy_code=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"code",${XML_SINGLE})};
									if($cuprodigy_cardNumber =~ /^\s*$/){
										if    ($CONF__PLASTIC_CARD__CARD_TYPE{${cuprodigy_cardType}} eq ""){
											$dms_cardstatus="";	# Quietly ignore when the <cardNumber> is blank and the <cardType> is not configured.
										}else{
											$dms_cardstatus="";
											&logfile("cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" (\"".$CONF__PLASTIC_CARD__CARD_TYPE{${cuprodigy_cardType}}."\") has an empty <cardNumber> value; is likely that ${CTRL__SERVER_REFERENCE__CUPRODIGY} is incorrectly configured.\n") if ${record_messages_in_logfile};
											push(@INQ_RESPONSE_NOTES,join("\t","PC",${dms_accountnumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" (\"".$CONF__PLASTIC_CARD__CARD_TYPE{${cuprodigy_cardType}}."\") has an empty <cardNumber> value; is likely that ${CTRL__SERVER_REFERENCE__CUPRODIGY} is incorrectly configured.\n"));
										}
									}else{
										$dms_accountnumber=${cuprodigy_xml_request_membernumber};
										($dms_cardnumber_last_4=substr("    ".${cuprodigy_cardNumber},-4,4))=~s/^ *//;
										$dms_pan=${cuprodigy_cardNumber};
										if    ($CONF__PLASTIC_CARD__CARD_TYPE{${cuprodigy_cardType}} eq ""){
											$dms_cardstatus="";
											&logfile("cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" is assigned an unconfigured (\%CONF__PLASTIC_CARD__CARD_TYPE) \"cardType\" value of \"${cuprodigy_cardType}\".\n") if ${record_messages_in_logfile};
											push(@INQ_RESPONSE_NOTES,join("\t","PC",${dms_accountnumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" is assigned an unconfigured (\%CONF__PLASTIC_CARD__CARD_TYPE) \"cardType\" value of \"${cuprodigy_cardType}\".\n"));
										}elsif($CTRL__PLASTIC_CARD__CODE__KNOWN_VALUES{${cuprodigy_code}} eq ""){
											$dms_cardstatus="";
											&logfile("cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" is assigned an unconfigured (\%CTRL__PLASTIC_CARD__CODE__KNOWN_VALUES) \"code\" value of of \"${cuprodigy_code}\".\n") if ${record_messages_in_logfile};
											push(@INQ_RESPONSE_NOTES,join("\t","PC",${dms_accountnumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" is assigned an unconfigured (\%CTRL__PLASTIC_CARD__CODE__KNOWN_VALUES) \"code\" value of of \"${cuprodigy_code}\".\n"));
										}elsif($CTRL__PLASTIC_CARD__CODE__DISABLED{${cuprodigy_code}}){
											$dms_cardstatus="blocked";
										}elsif($CTRL__PLASTIC_CARD__CODE__ENABLED{${cuprodigy_code}}){
											$dms_cardstatus="unblocked";
										}else{
											$dms_cardstatus="cancelled";
										}
										$dms_description=$CONF__PLASTIC_CARD__CARD_TYPE{${cuprodigy_cardType}}." ending ".${dms_cardnumber_last_4};
										($dms_issuedate=${cuprodigy_issueDate})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										($dms_expiredate=${cuprodigy_expireDate})=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										$dms_attached_deposittype="";
										$dms_attached_membernumber="";
										$dms_attached_subaccount="";
										$dms_attached_description="";
										if(${cuprodigy_cardType} ne "" and $CONF__PLASTIC_CARD__CARD_TYPE{${cuprodigy_cardType}} ne ""){
											if($dms_pan !~ /^\d{16}$/){
												&logfile("cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" is not 16 digits long; need ${CTRL__SERVER_REFERENCE__CUPRODIGY} vendor to install the correct version of ${cuprodigy_method_use} method.\n") if ${record_messages_in_logfile};
												push(@INQ_RESPONSE_NOTES,join("\t","PC",${dms_accountnumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ${cuprodigy_method_used}: ".join(", ",${cuprodigy_xml_request_membernumber}).": "."Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" is not 16 digits long; need ${CTRL__SERVER_REFERENCE__CUPRODIGY} vendor to install the correct version of ${cuprodigy_method_use} method.\n"));
											}else{
												if    (${CONF__PLASTIC_CARD__SIGNATURE__CLIENTID} =~ /^\d\d*$/){
													$use_as_clientid=${CONF__PLASTIC_CARD__SIGNATURE__CLIENTID};
												}elsif($cuprodigy_memberInformation_entityId =~ /^\d\d*$/){
													$use_as_clientid=${cuprodigy_memberInformation_entityId};
												}elsif($cuprodigy_memberInformation_pinNumber =~ /^\d\d*$/){
													$use_as_clientid=${cuprodigy_memberInformation_pinNumber};
												}else{
													$use_as_clientid="";
												}
												if(${use_as_clientid} eq ""){
													$dms_cardsignature_composit="";
												}else{
													$dms_cardsignature_composit=&plastic_card__calc_signature(${dms_accountnumber},${dms_attached_deposittype},${dms_attached_membernumber},${dms_attached_subaccount},${dms_pan},${use_as_clientid},${CONF__PLASTIC_CARD__SIGNATURE__CARDTYPE},${CONF__PLASTIC_CARD__SIGNATURE__LENGTH_RANDOM},${cuprodigy_memberInformation_entityId},${reuse_random_17_bytes});
													if(${reuse_random_17_bytes} eq ""){
														local($last_4,$old_signature,$type);
	    												local($digest_composit,$digest_16_bytes,$random_17_bytes);
														local($test_cardsignature_composit);
														($last_4,$old_signature,$type)=split(/,/,${dms_cardsignature_composit});
														$digest_composit=&plastic_card__fis_ezcardinfo_sso_signature_decode(${old_signature});
														$digest_16_bytes=substr($digest_composit,-16,16);
														$random_17_bytes=substr($digest_composit,0,length($digest_composit)-length(${digest_16_bytes}));
														$test_cardsignature_composit=&plastic_card__calc_signature(${dms_accountnumber},${dms_attached_deposittype},${dms_attached_membernumber},${dms_attached_subaccount},${dms_pan},${use_as_clientid},${CONF__PLASTIC_CARD__SIGNATURE__CARDTYPE},${CONF__PLASTIC_CARD__SIGNATURE__LENGTH_RANDOM},${cuprodigy_memberInformation_entityId},${random_17_bytes});
														if(${dms_cardsignature_composit} ne ${test_cardsignature_composit}){
															&logfile("cuprodigy_xml_balances_and_history__parse_plastic_cards(): Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" failed using plastic_card__calc_signature() to generate a reproducible card signature value.\n");
															push(@INQ_RESPONSE_NOTES,join("\t","PC",${dms_accountnumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history__parse_plastic_cards(): Plastic Card of type \"${cuprodigy_cardType}\" with last 4 digits of \"${dms_cardnumber_last_4}\" failed using plastic_card__calc_signature() to generate a reproducible card signature value.\n"));
														}
													}
												}
												if(${dms_cardstatus} eq "blocked" or ${dms_cardstatus} eq "unblocked"){
													push(@XML_MB_PLASTIC_CARDS_WIP,
														join("\t",
															${dms_accountnumber},
															${dms_cardsignature_composit},
															${dms_cardstatus},
															${dms_issuedate},
															${dms_expiredate},
															${dms_description},
															${dms_attached_deposittype},
															${dms_attached_membernumber},
															${dms_attached_subaccount},
															${dms_attached_description},
															${dms_pan},
															${cuprodigy_code}
														)
													);
												}
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(!${XML_has_branch_cardInfo}){
		if(0){
			# Error when API method response does NOT contain <cardInfo> (presumes that all member numbers must have attached Plastic Cards)
			if(${rtrn_error_text} eq ""){
				$rtrn_error_text=join("\t","999","API RESPONSE HAS INCOMPLETE DATA",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method \"${cuprodigy_method_used}\": The XML branch <cardInfo> does not exist in the XML response data.");
			}
		}else{
			# Warning when API method response does NOT contain <cardInfo>, as could be valid for member numbers that do NOT have any attached Plastic Cards
			if(${rtrn_error_text} eq ""){
				&logfile("cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method \"${cuprodigy_method_used}\": The XML branch <cardInfo> does not exist in the XML response data; could be that member number ".${dms_accountnumber}." does not have any Platic Cards.\n") if ${full_inquiry} > 0;
				push(@INQ_RESPONSE_NOTES,join("\t","PC",${dms_accountnumber},${CONF__XXX__RESPONSE_NOTES__VALUE_PLACEHOLDER},"cuprodigy_xml_balances_and_history__parse_plastic_cards(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method \"${cuprodigy_method_used}\": The XML branch <cardInfo> does not exist in the XML response data; could be that member number ".${dms_accountnumber}." does not have any Platic Cards.\n"));
			}
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_crossaccount{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$record_messages_in_logfile)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST);
   local($xjo_cuprodigy_memberNumber,$xjo_cuprodigy_accountCategory,$xjo_cuprodigy_accountType,$xjo_cuprodigy_accountNumber,$xjo_cuprodigy_transactionsRestricted,$xjo_dp_ln_cc,$xjo_cuprodigy_accountNumber__mb,$xjo_cuprodigy_accountNumber__dplncc,$xjo_dms_xjo_overloaded_composit);
   local(%MB_DP_EXISTS_IN_XJO,%MB_LN_EXISTS_IN_XJO);
   local($tmp_ln_year_make_model_1,$tmp_ln_year_make_model_2);
   local($cuprodigy_xml_description);
   local($using_cuprodigy_method);
   local(%DETECT_DUPLICATES_IN_CORE_API_DATA);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_UNIQID
	#	@XML_MB_DP_UNIQID
	#	@XML_MB_LN_UNIQID
	#	@XML_MB_CC_UNIQID
	#	@XML_MB_XAC
	#	@XML_MB_XAC_LN_PAYOFF
	#
	undef(@XML_MB_UNIQID);
	undef(@XML_MB_DP_UNIQID);
	undef(@XML_MB_LN_UNIQID);
	undef(@XML_MB_CC_UNIQID);
	undef(@XML_MB_XAC);
	undef(@XML_MB_XAC_LN_PAYOFF);
	$using_cuprodigy_method="CrossAccountAuthority";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML CrossAccountAuthority: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
		($rtrn_error_text,@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST)=&xjo_overloaded_account_list(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${record_messages_in_logfile});
		if(${rtrn_error_text} eq ""){
			while(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST > 0){
				($xjo_cuprodigy_memberNumber,$xjo_cuprodigy_accountCategory,$xjo_cuprodigy_accountType,$xjo_cuprodigy_accountNumber,$xjo_cuprodigy_transactionsRestricted,$xjo_dp_ln_cc,$xjo_cuprodigy_accountNumber__mb,$xjo_cuprodigy_accountNumber__dplncc,$xjo_dms_xjo_overloaded_composit)=split(/\t/,shift(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST));
				if($xjo_cuprodigy_transactionsRestricted =~ /^true$/i){
					1;	# When the XJO account does not allow transfers (i.e. the $fake_cuprodigy_canbetransferdestination would be "false") then it should not block the accounts existing in XAC (the CUProdigy method CrossAccountAuthority may have an seperate/independent ability to allow the transfer).
				}else{
					if    ($xjo_dp_ln_cc =~ /^DP$/i){
						$MB_DP_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber}}=1;
						$MB_DP_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber__mb},${xjo_cuprodigy_accountNumber__dplncc}}=1;
						$MB_DP_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber__mb},${xjo_cuprodigy_accountNumber__dplncc},0}=1;
					}elsif($xjo_dp_ln_cc =~ /^LN$/i){
						$MB_LN_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber}}=1;
						$MB_LN_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber__mb},${xjo_cuprodigy_accountNumber__dplncc}}=1;
					}elsif($xjo_dp_ln_cc =~ /^CC$/i){
						$MB_LN_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber}}=1;
						$MB_LN_EXISTS_IN_XJO{${xjo_cuprodigy_accountNumber__mb},${xjo_cuprodigy_accountNumber__dplncc}}=1;
					}
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&CrossAccountAuthority("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CrossAccountAuthority: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="authorizedAccounts",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="account",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,@key_prefix);
									$DPLNCC="";
									$cuprodigy_accountCategory=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountCategory",${XML_SINGLE})};
									$cuprodigy_accountType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountType",${XML_SINGLE})};
									$cuprodigy_accountId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountId",${XML_SINGLE})};
									$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
									$cuprodigy_description=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"description",${XML_SINGLE})};
									$cuprodigy_transactionsRestricted=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"transactionsRestricted",${XML_SINGLE})};
									$cuprodigy_firstName=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"firstName",${XML_SINGLE})};
									$cuprodigy_middleName=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"middleName",${XML_SINGLE})};
									$cuprodigy_lastName=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastName",${XML_SINGLE})};
									$cuprodigy_availableBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableBalance",${XML_SINGLE})};
									$cuprodigy_currentBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"currentBalance",${XML_SINGLE})};
									$cuprodigy_YTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"YTDInterest",${XML_SINGLE})};
									$cuprodigy_LYTDInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"LYTDInterest",${XML_SINGLE})};
									if    (&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__CUPRODIGY},"",1)){
										$DPLNCC="DP";
									}elsif(&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__CUPRODIGY},"",1)){
										$DPLNCC="LN";
									}elsif($configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} ne ""){
										$DPLNCC="CC";
									}elsif($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payoff",${XML_SINGLE})} ne ""){	# Implies LN balance record
										$DPLNCC="LN";
									}else{
										$DPLNCC="DP";
									}
									if($DPLNCC =~ /^DP$/i){
										$cuprodigy_maturityDate="";
										$cuprodigy_dividendRate="";
									}
									if($DPLNCC =~ /^LN$/i){
										$cuprodigy_payoff=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payoff",${XML_SINGLE})};
										$cuprodigy_lastPaymentDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastPaymentDate",${XML_SINGLE})};
										$cuprodigy_nextPaymentDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nextPaymentDate",${XML_SINGLE})};
										$cuprodigy_lastPaymentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastPaymentAmount",${XML_SINGLE})};
										$cuprodigy_unpaidInterest=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"unpaidInterest",${XML_SINGLE})};
										$cuprodigy_partialPayment=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"partialPayment",${XML_SINGLE})};
										$cuprodigy_delinquentAmount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"delinquentAmount",${XML_SINGLE})};
										$cuprodigy_paymentsPerYear=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"paymentsPerYear",${XML_SINGLE})};
										$cuprodigy_interestRate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"interestRate",${XML_SINGLE})};
										$cuprodigy_creditLimit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"creditLimit",${XML_SINGLE})};
										$cuprodigy_availableCreditLimit=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableCreditLimit",${XML_SINGLE})};
										$cuprodigy_openingBalance=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openingBalance",${XML_SINGLE})};
										$cuprodigy_make=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"make",${XML_SINGLE})};
										$cuprodigy_model=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"model",${XML_SINGLE})};
										$cuprodigy_vin=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"vin",${XML_SINGLE})};
										$cuprodigy_year=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"year",${XML_SINGLE})};
									}
									$dms_accountnumber=(&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}))[0];
									if(${dms_accountnumber} eq ${cuprodigy_xml_request_membernumber}){
										$DPLNCC="";
										if(${record_messages_in_logfile}){
											($xml_ref_1="<".join("><",split(/$;/,$key_prefix),"accountCategory").">")=~s/<[0-9][0-9]*>//g;
											($xml_ref_2="<".join("><",split(/$;/,$key_prefix),"accountType").">")=~s/<[0-9][0-9]*>//g;
											($xml_ref_3="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
											&logfile("cuprodigy_xml_crossaccount(): Balance record is for a current member from ${CTRL__SERVER_REFERENCE__CUPRODIGY} where ".${xml_ref_1}." is '".${cuprodigy_accountCategory}."' and ".${xml_ref_2}." is '".${cuprodigy_accountType}."' and ".${xml_ref_3}." is '".${cuprodigy_accountNumber}."'; skipping the balance record.\n");
										}
									}
									&configure_account_by_cuprodigy_type__generate_default__wrapper(${DPLNCC},${cuprodigy_accountType},${cuprodigy_accountCategory},${cuprodigy_creditLimit});
									if($DPLNCC =~ /^DP$/i){
										($dms_tomember,$dms_accounttype)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
										$dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_DEPOSITTYPE{${cuprodigy_accountType}};
										if(1){
											if($DETECT_DUPLICATES_IN_CORE_API_DATA{${cuprodigy_xml_request_membernumber},${dms_tomember},${dms_accounttype},${dms_deposittype}}){
												&logfile("Duplicate Data: XAC processing found the ${CTRL__SERVER_REFERENCE__CUPRODIGY} response contained duplicate data for: ".join("/","DP",${cuprodigy_xml_request_membernumber},${dms_tomember},${dms_accounttype},${dms_deposittype})."\n") if ${record_messages_in_logfile};
												pop(@key_prefix); pop(@key_prefix);
												next;
											}
											$DETECT_DUPLICATES_IN_CORE_API_DATA{${cuprodigy_xml_request_membernumber},${dms_tomember},${dms_accounttype},${dms_deposittype}}=1;
										}
										if(${dms_deposittype} eq ""){ $dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{${cuprodigy_accountCategory}}; }
										if(${dms_deposittype} eq ""){ $dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTCATEGORY__DMS_DEPOSITTYPE{""}; }
										$dms_description=( ${cuprodigy_homeBankAccountDesc} ne "" ? ${cuprodigy_homeBankAccountDesc} : ${cuprodigy_description} );
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										if($CUSTOM{"custom_baldesc.pi"}>0){
											if(defined(&custom_baldesc)){
												$dms_description=&custom_baldesc(${dms_description},"XAC","DP",${key_prefix},${record_messages_in_logfile},&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}),"0");
											}
										}
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										$dms_misc="";
										if(1){
											if    ($cuprodigy_firstName !~ /^\s*$/){
												$dms_description=join(" - ",${cuprodigy_firstName},${cuprodigy_description});
											}elsif($cuprodigy_lastName !~ /^\s*$/){
												$dms_description=join(" - ",${cuprodigy_lastName},${cuprodigy_description});
											}else{
												$dms_description=join(" - ",${dms_tomember},${cuprodigy_description});
											}
										}
										if    (${CONF__BAL_DP__CERT_DESC__INCLUDE_MATURITY_DATE} and ${cuprodigy_maturityDate} ne "" and 
										       ${CONF__BAL_DP__CERT_DESC__INCLUDE_APR} and ${cuprodigy_dividendRate} > 0){
											$dms_description.=" (Matures ".${cuprodigy_maturityDate}.", APR ".${cuprodigy_dividendRate}."%)";
										}elsif(${CONF__BAL_DP__CERT_DESC__INCLUDE_MATURITY_DATE} and ${cuprodigy_maturityDate} ne ""){
											$dms_description.=" (Matures ".${cuprodigy_maturityDate}.")";
										}elsif(${CONF__BAL_DP__CERT_DESC__INCLUDE_APR} and ${cuprodigy_dividendRate} > 0){
											$dms_description.=" (APR ".${cuprodigy_dividendRate}."%)";
										}
										if($cuprodigy_transactionsRestricted =~ /^true$/i){
											$fake_cuprodigy_canbetransferdestination="false";
										}else{
											if(($xfer_excl_reason=&transaction_excl_xfer_to(${DPLNCC},${dms_accounttype},"GEN")) eq ""){
												$fake_cuprodigy_canbetransferdestination="true";
											}else{
												$fake_cuprodigy_canbetransferdestination="false";
												&logfile("Account Restricted: XAC reason transfer TO would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};
												push(@XAC_RESPONSE_NOTES,join("\t","DP",${dms_accountnumber},${dms_accounttype},${dms_certnumber},"Account Restricted: XAC reason transfer TO would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n"));
											}
											if(($xfer_excl_reason=&transaction_excl_xfer_to(${DPLNCC},${dms_accounttype},"XAC")) eq ""){
												$fake_cuprodigy_canbetransferdestination="true";
											}else{
												$fake_cuprodigy_canbetransferdestination="false";
												&logfile("Account Restricted: XAC reason transfer TO would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};
												push(@XAC_RESPONSE_NOTES,join("\t","DP",${dms_accountnumber},${dms_accounttype},${dms_certnumber},"Account Restricted: XAC reason transfer TO would be restricted on share ${dms_accountnumber}/${dms_accounttype}/${dms_certnumber}: ${xfer_excl_reason}\n"));
											}
										}
										if(!$MB_DP_EXISTS_IN_XJO{${cuprodigy_accountNumber}} and $fake_cuprodigy_canbetransferdestination =~ /^true$/i){
											push(@XML_MB_DP_UNIQID,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_tomember},
												${dms_accounttype},
												'0',
												&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},"")
											));
											push(@XML_MB_XAC,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_tomember},
												${dms_accounttype},
												${dms_deposittype},
												${dms_description},
												${dms_misc}
											));
										}
									}
									if($DPLNCC =~ /^LN$/i){
										($dms_tomember,$dms_accounttype)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
										$dms_deposittype=$TODO__REMAP__CUDP_ACCOUNTTYPE__DMS_LOANTYPE{${cuprodigy_accountType}};
										if(${dms_deposittype} eq ""){ $dms_deposittype="L"; }
										if(1){
											if($DETECT_DUPLICATES_IN_CORE_API_DATA{${cuprodigy_xml_request_membernumber},${dms_tomember},${dms_accounttype},${dms_deposittype}}){
												&logfile("Duplicate Data: XAC processing found the ${CTRL__SERVER_REFERENCE__CUPRODIGY} response contained duplicate data for: ".join("/","LN",${cuprodigy_xml_request_membernumber},${dms_tomember},${dms_accounttype},${dms_deposittype})."\n") if ${record_messages_in_logfile};
												pop(@key_prefix); pop(@key_prefix);
												next;
											}
											$DETECT_DUPLICATES_IN_CORE_API_DATA{${cuprodigy_xml_request_membernumber},${dms_tomember},${dms_accounttype},${dms_deposittype}}=1;
										}
										if    ($configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} ne ""){	# Non-blank value should be either "loan" or "offbook-nonsweep" or "offbook-sweep" or "inhouse"
											$dms_type=${CTRL__CC_CREDIT_BUREAU_PURP_CODE};	# C/B Type for CC
										}elsif($configure_account_by_cuprodigy_type__loan_behavior{${cuprodigy_accountType}} ne ""){	# Non-blank value should be either "3rdparty-nonsweep" or "3rdparty-sweep"
											$dms_type=${CTRL__LN_CREDIT_BUREAU_PURP_CODE_3RD_PARTY};	# C/B Type for LN when 3rd Party
										}else{
											$dms_type=${CTRL__LN_CREDIT_BUREAU_PURP_CODE};	# C/B Type for LN
										}
										$dms_description=( ${cuprodigy_homeBankAccountDesc} ne "" ? ${cuprodigy_homeBankAccountDesc} : ${cuprodigy_description} );
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										if("${cuprodigy_year}${cuprodigy_make}${cuprodigy_model}" ne ""){
											($tmp_ln_year_make_model_1=${dms_description})=~s/\s//g;
										    ($tmp_ln_year_make_model_2="${cuprodigy_year} ${cuprodigy_make} ${cuprodigy_model}")=~s/\s//g;
											if($tmp_ln_year_make_model_2 !~ /^\d*$/){
												if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
											    	($tmp_ln_year_make_model_2.=${cuprodigy_vin})=~s/\s//g;
												}
												if    (${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__APPEND}){
													$dms_description.=" -";
													if(${cuprodigy_year} ne ""){ $dms_description.=" ".${cuprodigy_year}; }
													if(${cuprodigy_make} ne ""){ $dms_description.=" ".${cuprodigy_make}; }
													if(${cuprodigy_model} ne ""){ $dms_description.=" ".${cuprodigy_model}; }
													if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
														if(${cuprodigy_vin} ne ""){ $dms_description.=" ".${cuprodigy_vin}; }
													}
												}elsif(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__REPLACE}){
													$dms_description="";
													if(${cuprodigy_year} ne ""){ $dms_description.=" ".${cuprodigy_year}; }
													if(${cuprodigy_make} ne ""){ $dms_description.=" ".${cuprodigy_make}; }
													if(${cuprodigy_model} ne ""){ $dms_description.=" ".${cuprodigy_model}; }
													if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
														if(${cuprodigy_vin} ne ""){ $dms_description.=" ".${cuprodigy_vin}; }
													}
													$dms_description=~s/^ *//;
												}elsif(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__AUGMENT}){
													$tmp_ln_year_make_model_1=~tr/A-Z/a-z/;
													$tmp_ln_year_make_model_2=~tr/A-Z/a-z/;
													if(index(${tmp_ln_year_make_model_2},${tmp_ln_year_make_model_1}) >= 0){
														$dms_description="";
														if(${cuprodigy_year} ne ""){ $dms_description.=" ".${cuprodigy_year}; }
														if(${cuprodigy_make} ne ""){ $dms_description.=" ".${cuprodigy_make}; }
														if(${cuprodigy_model} ne ""){ $dms_description.=" ".${cuprodigy_model}; }
														if(${CONF__BAL_LN__DESC__YEAR_MAKE_MODEL__INCLUDE_VIN}){
															if(${cuprodigy_vin} ne ""){ $dms_description.=" ".${cuprodigy_vin}; }
														}
														$dms_description=~s/^ *//;
													}
												}
											}
										}
										if($CUSTOM{"custom_baldesc.pi"}>0){
											if(defined(&custom_baldesc)){
												$dms_description=&custom_baldesc(${dms_description},"XAC","LN",${key_prefix},${record_messages_in_logfile},&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber}),${dms_type});
											}
										}
										if($dms_description =~ /^\s*$/){ $dms_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory}); }
										$dms_misc="";
										$dms_payoff=sprintf("%.2f",${cuprodigy_payoff});
										if(1){
											if    ($cuprodigy_firstName !~ /^\s*$/){
												$dms_description=join(" - ",${cuprodigy_firstName},${cuprodigy_description});
											}elsif($cuprodigy_lastName !~ /^\s*$/){
												$dms_description=join(" - ",${cuprodigy_lastName},${cuprodigy_description});
											}else{
												$dms_description=join(" - ",${dms_tomember},${cuprodigy_description});
											}
										}
										if($cuprodigy_transactionsRestricted =~ /^true$/i){
											$fake_cuprodigy_canbetransferdestination="false";
										}else{
											if(($xfer_excl_reason=&transaction_excl_xfer_to(${DPLNCC},${dms_accounttype},"GEN")) eq ""){
												$fake_cuprodigy_canbetransferdestination="true";
											}else{
												$fake_cuprodigy_canbetransferdestination="false";
												&logfile("Account Restricted: XAC reason transfer TO would be restricted on loan ${dms_accountnumber}/${dms_accounttype}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};	# $dms_loannumber held in $dms_accounttype
												push(@XAC_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_accounttype},"Account Restricted: XAC reason transfer TO would be restricted on loan ${dms_accountnumber}/${dms_accounttype}: ${xfer_excl_reason}\n"));	# $dms_loannumber held in $dms_accounttype
											}
											if(($xfer_excl_reason=&transaction_excl_xfer_to(${DPLNCC},${dms_accounttype},"XAC")) eq ""){
												$fake_cuprodigy_canbetransferdestination="true";
											}else{
												$fake_cuprodigy_canbetransferdestination="false";
												&logfile("Account Restricted: XAC reason transfer TO would be restricted on loan ${dms_accountnumber}/${dms_accounttype}: ${xfer_excl_reason}\n") if ${record_messages_in_logfile};	# $dms_loannumber held in $dms_accounttype
												push(@XAC_RESPONSE_NOTES,join("\t","LN",${dms_accountnumber},${dms_accounttype},"Account Restricted: XAC reason transfer TO would be restricted on loan ${dms_accountnumber}/${dms_accounttype}: ${xfer_excl_reason}\n"));	# $dms_loannumber held in $dms_accounttype
											}
										}
										if(!$MB_LN_EXISTS_IN_XJO{${cuprodigy_accountNumber}} and $fake_cuprodigy_canbetransferdestination =~ /^true$/i){
											push(@XML_MB_LN_UNIQID,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_tomember},
												${dms_accounttype},
												&subaccount_recast_uniqid(${dms_accountnumber},${cuprodigy_accountCategory},${cuprodigy_accountId},"")
											));
											push(@XML_MB_XAC,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_tomember},
												${dms_accounttype},
												${dms_deposittype},
												${dms_description},
												${dms_misc}
											));
											push(@XML_MB_XAC_LN_PAYOFF,join("\t",
												${cuprodigy_xml_request_membernumber},
												${dms_tomember},
												${dms_accounttype},
												${dms_payoff}
											));
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_getstatement_toc{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($using_cuprodigy_method);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_ETOC
	#
	undef(@XML_MB_ETOC);
	$using_cuprodigy_method="GetETOC";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML GetETOC: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&GetETOC("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetETOC: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="EStatementTOC",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="Statements",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									for($tag_L08="Statement",$idx_L08=1,$limit_L08=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L08)};$idx_L08<=$limit_L08;$idx_L08++){
										$key_L08=join($;,@key_prefix,$tag_L08,sprintf(${XML_TAG_INDEX_FMT},${idx_L08}));
										@key_prefix=split(/$;/,$key_L08);
										$key_prefix=join($;,@key_prefix);
										$cuprodigy_yyyy_mm=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"statementName",${XML_SINGLE})};
										if(${cuprodigy_yyyy_mm} eq ""){ $cuprodigy_yyyy_mm=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"StatementName",${XML_SINGLE})}; }
										$cuprodigy_yyyy_mm=~s/^(\d{4}\d{2})(\d{2})$/$1/;
										$cuprodigy_yyyy_mm=~s/^(\d{4}-\d{2})(-\d{2})$/$1/;
										$cuprodigy_yyyy_mm=~s/^(\d{4})(\d{2})$/$1-$2/;
										$cuprodigy_end_yyyy_mm_dd=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"periodEnd",${XML_SINGLE})};
										if(${cuprodigy_end_yyyy_mm_dd} eq ""){ $cuprodigy_end_yyyy_mm_dd=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"PeriodEnd",${XML_SINGLE})}; }
										$cuprodigy_end_yyyy_mm_dd==~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
										$cuprodigy_period="M";
										$cuprodigy_description=${cuprodigy_yyyy_mm}."-Statement";
										$cuprodigy_format="PDF";
										$cuprodigy_other="";
										push(@XML_MB_ETOC,join("\t",
											${cuprodigy_xml_request_membernumber},
											${cuprodigy_yyyy_mm},
											${cuprodigy_period},
											${cuprodigy_end_yyyy_mm_dd},
											${cuprodigy_description},
											${cuprodigy_format},
											${cuprodigy_other}
										));
										pop(@key_prefix); pop(@key_prefix);
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(${CONF__ETOC__FAKE_DATA_FOR_TESTING} and @XML_MB_ETOC == 0 and $rtrn_error_text =~ /Failed using method: GetETOC: Vendor doesn[^ ]*t have permission to perform that transaction type: GetETOC/i){
		&cuprodigy_xml_getstatement_toc__fake_data_for_testing(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd});
		$rtrn_error_text="";
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_getstatement_toc__fake_data_for_testing{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd)=@_;
   local($estm_period,$estm_type,$estm_end_date,$estm_description,$estm_data_type,$estm_other);
   local(@f);
   local($yyyy,$mm);
   local($yyyy_mm);
   local($eom__yyyy_mm_dd);
   local($periods_to_fake)=24;
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_ETOC
	#
	undef(@XML_MB_ETOC);
	@f=localtime(time());
	$yyyy=sprintf("%04.0f",1900+$f[5]);
	$mm=sprintf("%02.0f",1+$f[4]);
	while(${periods_to_fake} > 0){
		$periods_to_fake=sprintf("%.0f",${periods_to_fake}-1);
		$mm=sprintf("%02.0f",${mm}-1);
		if(${mm} == 0){
			$yyyy=sprintf("%04.0f",${yyyy}-1);
			$mm="12";
		}
		$yyyy_mm=${yyyy}."-".${mm};
		$eom__yyyy_mm_dd=${yyyy_mm}."-".&date_last_day_of_month(${yyyy},${mm});
		($estm_period,$estm_type,$estm_end_date,$estm_description,$estm_data_type,$estm_other)=(${yyyy_mm},"M",${eom__yyyy_mm_dd},"${yyyy_mm}-Statement","PDF","");
		$cuprodigy_yyyy_mm=${estm_period};
		$cuprodigy_period=${estm_type},
		$cuprodigy_enddate=${estm_end_date};
		$cuprodigy_description=${estm_description}." (may not actually exist)",
		$cuprodigy_format=${estm_data_type};
		$cuprodigy_other=${estm_other};
		push(@XML_MB_ETOC,join("\t",
			${cuprodigy_xml_request_membernumber},
			${cuprodigy_yyyy_mm},
			${cuprodigy_period},
			${cuprodigy_enddate},
			${cuprodigy_description},
			${cuprodigy_format},
			${cuprodigy_other}
		));
	}
}

sub cuprodigy_xml_getstatement{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$yyyy_mm)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($using_cuprodigy_method);
   local($encoded_data);
   local($key_prefix);
	$using_cuprodigy_method="GetStatement";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML GetStatement: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&GetStatement("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${yyyy_mm}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_getstatement(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_getstatement(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","error|file");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","error|file");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_getstatement(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: Response: ${error}");
			}
			if(${error} ne ""){
				if($error =~ /^No statement for [^ ][^ ]* found/i){
					$rtrn_error_text=join("\t","012",$CTRL__STATUS_TEXT{"012"});
				}
			}
		}
	}
	$key_prefix=join($;,"Envelope",${XML_SINGLE},"Body",${XML_SINGLE},"submitMessageResponse",${XML_SINGLE},"return",${XML_SINGLE},"response",${XML_SINGLE},"transaction",${XML_SINGLE});
	if(${rtrn_error_text} eq ""){
		$encoded_data=$XML_DATA_BY_TAG_INDEX{join($;,${key_prefix},"file",${XML_SINGLE})};
	}else{
		$encoded_data="";
		if(${rtrn_error_text} eq ""){
			if($XML_DATA_BY_TAG_INDEX{join($;,${key_prefix},"file")} eq ""){
				$error="The XML response contained neither an error message nor a data value node";
			}else{
				$error="The XML response returned a data value node that is unexpectedly empty";
			}
			&logfile("cuprodigy_xml_getstatement(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: ${error}\n");
			$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetStatement: Response: ${error}");
		}
	}
	if(${CONF__ESTM__FAKE_DATA_FOR_TESTING} and ${encoded_data} eq "" and $rtrn_error_text eq join("\t","012",$CTRL__STATUS_TEXT{"012"})){
		$encoded_data=&cuprodigy_xml_getstatement__fake_data_for_testing(${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${yyyy_mm});
		if(${encoded_data} ne ""){
			$rtrn_error_text="";
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"GetStatement",${cuprodigy_xml_request_membernumber},${yyyy_mm}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text},${encoded_data});
}

sub cuprodigy_xml_getstatement__fake_data_for_testing{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$yyyy_mm)=@_;
   local($periods_to_fake)=12;	# To allow testing for "012"/"STATEMENT NOT FOUND", the cuprodigy_xml_getstatement_toc__fake_data_for_testing() uses "24" but cuprodigy_xml_getstatement__fake_data_for_testing() uses "12".
   local($encoded_data);
   local(*INPUT);
   local(*OUTPUT);
   local($buf);
   local($eom__yyyy_mm_dd);
   local(@f);
   local($yyyy,$mm);
   local($pdffile_faking_dir);
   local($composit_mir_data);
   local(%XML_MB_MIR);
   local($mbname,$mbaddr1,$mbaddr2,$mbaddr3);
   local($error_num_and_text);
	$eom__yyyy_mm_dd=${yyyy_mm}."-".&date_last_day_of_month(substr(${yyyy_mm},0,4),substr(${yyyy_mm},-2,2));
	@f=localtime(time());
	$yyyy=sprintf("%04.0f",1900+$f[5]);
	$mm=sprintf("%02.0f",1+$f[4]);
	if(${yyyy_mm} lt sprintf("%04.0f-%02.0f",${yyyy}-1,${mm})){
		1;	# To allow testing for "012"/"STATEMENT NOT FOUND"
	}else{
		if(-d $CUSTOM{DIR} and -f $CUSTOM{DIR}."/pdffile.cgi" and -f $CUSTOM{DIR}."/pdffile.in.pdfdefs${VAR_CUID}"){
			$pdffile_faking_dir=$CUSTOM{DIR};
		}else{
			$pdffile_faking_dir=${DMS_HOMEDIR};
		}
		if    (! -f "${pdffile_faking_dir}/pdffile.cgi"){
			1;
		}elsif(! -f "${pdffile_faking_dir}/pdffile.in.pdfdefs${VAR_CUID}"){
			1;
		}elsif(!open(INPUT,"<${pdffile_faking_dir}/pdffile.in.pdfdefs${VAR_CUID}")){
			1;
		}else{
			$buf=""; while(read(INPUT,$buf,1024,length($buf))>0){ 1; }
			close(INPUT);
			if($buf =~ /STMT_MBNAME|STMT_MBADDR1|STMT_MBADDR2|STMT_MBADDR3/){
				($error_num_and_text,$composit_mir_data)=&mir_inquiry(${cuprodigy_xml_request_membernumber},1);
				($XML_MB_MIR{"ACCOUNTNUMBER"},$XML_MB_MIR{"NAMEFIRST"},$XML_MB_MIR{"NAMEMIDDLE"},$XML_MB_MIR{"NAMELAST"},$XML_MB_MIR{"EMAIL"},$XML_MB_MIR{"PHONEHOME"},$XML_MB_MIR{"PHONEWORK"},$XML_MB_MIR{"PHONECELL"},$XML_MB_MIR{"PHONEFAX"},$XML_MB_MIR{"SSN"},$XML_MB_MIR{"ADDRESS","ADDRESS1"},$XML_MB_MIR{"ADDRESS","ADDRESS2"},$XML_MB_MIR{"ADDRESS","CITY"},$XML_MB_MIR{"ADDRESS","STATE"},$XML_MB_MIR{"ADDRESS","POSTALCODE"},$XML_MB_MIR{"ADDRESS","COUNTRY"},$XML_MB_MIR{"DATEOFBIRTH"},$XML_MB_MIR{"MEMBERTYPE"})=split(/\t/,${composit_mir_data});
				if($XML_MB_MIR{"NAMEFIRST"} ne ""){
					$mbname=$XML_MB_MIR{"NAMEFIRST"}." ".substr($XML_MB_MIR{"NAMELAST"},0,1)."....";
				}else{
					$mbname=substr($XML_MB_MIR{"NAMELAST"},0,5)."....";
				}
				($mbaddr1=$XML_MB_MIR{"ADDRESS","ADDRESS1"})=~s/[^ ]/X/g;
				($mbaddr2=$XML_MB_MIR{"ADDRESS","ADDRESS2"})=~s/[^ ]/X/g;
				$mbaddr3=$XML_MB_MIR{"ADDRESS","CITY"}.", ".$XML_MB_MIR{"ADDRESS","STATE"}."  ".$XML_MB_MIR{"ADDRESS","POSTALCODE"};
				if($mbaddr2 =~ /^\s*$/){ ($mbaddr2,$mbaddr3)=(${mbaddr3},""); }
				if($mbaddr1 =~ /^\s*$/){ ($mbaddr1,$mbaddr2)=(${mbaddr2},""); }
			}
			$buf=~s/\$\{STMT_MBNUM\}/${cuprodigy_xml_request_membernumber}/g;
			$buf=~s/\$STMT_MBNUM/${cuprodigy_xml_request_membernumber}/g;
			$buf=~s/\$\{STMT_MBNAME\}/${mbname}/g;
			$buf=~s/\$STMT_MBNAME/${mbname}/g;
			$buf=~s/\$\{STMT_MBADDR1\}/${mbaddr1}/g;
			$buf=~s/\$STMT_MBADDR1/${mbaddr1}/g;
			$buf=~s/\$\{STMT_MBADDR2\}/${mbaddr2}/g;
			$buf=~s/\$STMT_MBADDR2/${mbaddr2}/g;
			$buf=~s/\$\{STMT_MBADDR3\}/${mbaddr3}/g;
			$buf=~s/\$STMT_MBADDR3/${mbaddr3}/g;
			$buf=~s/\$\{STMT_BEG_DATE\}/${yyyy_mm}-01/g;
			$buf=~s/\$STMT_BEG_DATE/${yyyy_mm}-01/g;
			$buf=~s/\$\{STMT_END_DATE\}/${eom__yyyy_mm_dd}/g;
			$buf=~s/\$STMT_END_DATE/${eom__yyyy_mm_dd}/g;
			open(OUTPUT,">${CTRL__DMS_TMPDIR}/pdffile.cgi.tmp.$$");
			print OUTPUT ${buf};
			close(OUTPUT);
			open(INPUT,"( /usr/bin/perl '${pdffile_faking_dir}/pdffile.cgi' '${CTRL__DMS_TMPDIR}/pdffile.cgi.tmp.$$' - < /dev/null | /usr/bin/base64 -w 0 ) 2> /dev/null |");
			$encoded_data=""; while(read(INPUT,$encoded_data,1024,length($encoded_data))>0){ 1; }
			close(INPUT);
			unlink("${CTRL__DMS_TMPDIR}/pdffile.cgi.tmp.$$");
		}
	}
	return(${encoded_data});
}

sub cuprodigy_xml_loanapplication{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$data,%data)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($cuprodigy_applicationid,$cuprodigy_message,$cuprodigy_rate,$cuprodigy_payment);
   local($mode_new_or_status);
   local($key_prefix);
	$using_cuprodigy_method="LoanApplication";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML LoanApplication: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&LoanApplication("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${data},%data),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplication: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_loanapplication(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplication: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_loanapplication(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplication: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplication: ${error}");
				}
			}
		}
	}
	$key_prefix=join($;,"Envelope",${XML_SINGLE},"Body",${XML_SINGLE},"submitMessageResponse",${XML_SINGLE},"return",${XML_SINGLE});
	if(${rtrn_error_text} eq ""){
		$cuprodigy_applicationid=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"response",${XML_SINGLE},"application",${XML_SINGLE},"applicationId",${XML_SINGLE})};
		$cuprodigy_message=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"response",${XML_SINGLE},"application",${XML_SINGLE},"message",${XML_SINGLE})};
		$cuprodigy_rate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"rate",${XML_SINGLE})};
		$cuprodigy_payment=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payment",${XML_SINGLE})};
		if($using_cuprodigy_method =~ /Application$/ and ( $cuprodigy_payment > 0 and $cuprodigy_rate > 0 )){	# Only valid for LoanApplication not for LoanApplicationStatus
			$rtrn_error_text=join("\t","000",${cuprodigy_message});	# HomeCU LoanApp non-error specs "000"/? (if CUProdigy directly posts the loanapp to the core (as opposed to being a multi-step "automated loan approval system"))
		}elsif($cuprodigy_message=~/Invalid Application ID/i){
			$rtrn_error_text=join("\t","025",${cuprodigy_message});	# HomeCU LoanApp non-error specs "025"/"Invalid Application ID"
		}elsif($cuprodigy_message=~/Application Pending/i){
			$rtrn_error_text=join("\t","026",${cuprodigy_message});	# HomeCU LoanApp non-error specs "026"/"Application Pending"
		}elsif($cuprodigy_message=~/Application Approved/i or ( $cuprodigy_payment > 0 and $cuprodigy_rate > 0 )){
			$rtrn_error_text=join("\t","027",${cuprodigy_message});	# HomeCU LoanApp non-error specs "027"/"Application Approved"
		}elsif($cuprodigy_message=~/Application Rejected/i){
			$rtrn_error_text=join("\t","028",${cuprodigy_message});	# HomeCU LoanApp error specs "028"/"Application Rejected"
		}elsif($cuprodigy_message=~/Application Requires Additional Review/i){
			$rtrn_error_text=join("\t","029",${cuprodigy_message});	# HomeCU LoanApp non-error specs "029"/"Application Requires Additional Review"
		}elsif($cuprodigy_message=~/Contact the Credit Union for additional information/i){
			$rtrn_error_text=join("\t","030",${cuprodigy_message});	# HomeCU LoanApp error specs "030"/"Contact the Credit Union for additional information"
		}else{
			$rtrn_error_text=join("\t","999",${cuprodigy_message});	# HomeCU LoanApp error specs "999"/?
		}
		if($cuprodigy_applicationid =~ /^\s*0*\s*$/){
			$rtrn_error_text=join("\t","028",${cuprodigy_message});	# HomeCU LoanApp error specs "028"/"Application Rejected"
			$cuprodigy_applicationid="";
		}else{
			$rtrn_error_text=join("\t","026",${cuprodigy_message});	# HomeCU LoanApp non-error specs "026"/"Application Pending"
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"LoanApplication",${cuprodigy_xml_request_membernumber},${yyyy_mm}) if ${rtrn_error_text} ne "" and (split(/\t/,${rtrn_error_text}))[0] !~ /^000$|^026$|^027$|^029$/;	# HomeCU LoanApp non-error specs "000"/"", "026"/"Application Pending", "027"/"Application Approved", "029"/"Application Requires Additional Review"
	return(${rtrn_error_text},${cuprodigy_applicationid});
}

sub cuprodigy_xml_loanapplicationstatus{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$loanappid)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($cuprodigy_applicationid,$cuprodigy_message,$cuprodigy_rate,$cuprodigy_payment);
   local($using_cuprodigy_method);
   local($key_prefix);
	$using_cuprodigy_method="LoanApplicationStatus";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML LoanApplicationStatus: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&LoanApplicationStatus("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${loanappid}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplicationStatus: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_loanapplicationstatus(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplicationStatus: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_loanapplicationstatus(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplicationStatus: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanApplicationStatus: ${error}");
				}
			}
		}
	}
	$key_prefix=join($;,"Envelope",${XML_SINGLE},"Body",${XML_SINGLE},"submitMessageResponse",${XML_SINGLE},"return",${XML_SINGLE},"response",${XML_SINGLE},"application",${XML_SINGLE});
	if(${rtrn_error_text} eq ""){
		$cuprodigy_applicationid=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"applicationId",${XML_SINGLE})};
		$cuprodigy_message=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"message",${XML_SINGLE})};
		$cuprodigy_rate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"rate",${XML_SINGLE})};
		$cuprodigy_payment=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payment",${XML_SINGLE})};
		if($using_cuprodigy_method =~ /Application$/ and ( $cuprodigy_payment > 0 and $cuprodigy_rate > 0 )){	# Only valid for LoanApplication not for LoanApplicationStatus
			$rtrn_error_text=join("\t","000",${cuprodigy_message});	# HomeCU LoanApp non-error specs "000"/? (if CUProdigy directly posts the loanapp to the core (as opposed to being a multi-step "automated loan approval system"))
		}elsif($cuprodigy_message=~/Invalid Application ID/i){
			$rtrn_error_text=join("\t","025",${cuprodigy_message});	# HomeCU LoanApp non-error specs "025"/"Invalid Application ID"
		}elsif($cuprodigy_message=~/Application Pending/i){
			$rtrn_error_text=join("\t","026",${cuprodigy_message});	# HomeCU LoanApp non-error specs "026"/"Application Pending"
		}elsif($cuprodigy_message=~/Application Approved/i or ( $cuprodigy_payment > 0 and $cuprodigy_rate > 0 )){
			$rtrn_error_text=join("\t","027",${cuprodigy_message});	# HomeCU LoanApp non-error specs "027"/"Application Approved"
		}elsif($cuprodigy_message=~/Application Rejected/i){
			$rtrn_error_text=join("\t","028",${cuprodigy_message});	# HomeCU LoanApp error specs "028"/"Application Rejected"
		}elsif($cuprodigy_message=~/Application Requires Additional Review/i){
			$rtrn_error_text=join("\t","029",${cuprodigy_message});	# HomeCU LoanApp non-error specs "029"/"Application Requires Additional Review"
		}elsif($cuprodigy_message=~/Contact the Credit Union for additional information/i){
			$rtrn_error_text=join("\t","030",${cuprodigy_message});	# HomeCU LoanApp error specs "030"/"Contact the Credit Union for additional information"
		}else{
			$rtrn_error_text=join("\t","999",${cuprodigy_message});	# HomeCU LoanApp error specs "999"/"Contact the Credit Union for additional information"
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"LoanApplicationStatus",${cuprodigy_xml_request_membernumber},${yyyy_mm}) if ${rtrn_error_text} ne "" and (split(/\t/,${rtrn_error_text}))[0] !~ /^000$|^026$|^027$|^029$/;	# HomeCU LoanApp non-error specs "000"/"", "026"/"Application Pending", "027"/"Application Approved", "029"/"Application Requires Additional Review"
	return(${rtrn_error_text},${loanappid});
}

sub cuprodigy_xml_getvendorloantypes{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($cuprodigy_applicationid,$cuprodigy_message,$cuprodigy_rate,$cuprodigy_payment);
   local($using_cuprodigy_method);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_LOANTYPES
	#
	undef(@XML_LOANTYPES);
	$using_cuprodigy_method="GetVendorLoanTypes";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML GetVendorLoanTypes: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&GetVendorLoanTypes("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetVendorLoanTypes: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_getvendorloantypes(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetVendorLoanTypes: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_getvendorloantypes(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetVendorLoanTypes: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetVendorLoanTypes: ${error}");
				}
			}
		}
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="loanTypes",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="loanType",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,@key_prefix);
									$cuprodigy_name=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"name",${XML_SINGLE})};
									$cuprodigy_modified=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"modified",${XML_SINGLE})};
									$dms_loantype_code=${cuprodigy_name};		# CUProdigy uses same value for "code" and "description".
									$dms_loantype_description=${cuprodigy_name};	# CUProdigy uses same value for "code" and "description".
									$dms_loantype_ittext=${cuprodigy_name};		# CUProdigy uses same value for "description" and "ittext" (based upon the HomeCU middleware to Symitar/Cruise API and their "ITText" data field).
									if(${dms_loantype_description} eq ${dms_loantype_ittext}){ $dms_loantype_ittext="" ; }	# Based upon Symitar/Cruise API behavior, the "ittext" should only have a value if it is different than "description".
									push(@XML_LOANTYPES,join("\t",
										${dms_loantype_code},
										${dms_loantype_description},
										${dms_loantype_ittext}
									));
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"GetVendorLoanTypes",${cuprodigy_xml_request_membernumber},${yyyy_mm}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_xjo_overloaded_accounts{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$record_messages_in_logfile)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_accountCategory,$cuprodigy_accountType,$cuprodigy_accountNumber,$cuprodigy_transactionsRestricted);
   local($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc);
   local($flag_exclude);
   local($DPLNCC);
   local($xml_ref_1,$xml_ref_2,$xml_ref_3);
   local(%XML_NAMESPACE_BY_TAG_INDEX,%XML_ATTRIBUTES_BY_TAG_INDEX,%XML_DATA_BY_TAG_INDEX,%XML_SEQ_BY_TAG_INDEX,%XML_TAGS_FOUND);	# Preserve any already existant (external cuprodigy_xml_xjo_overloaded_accounts()) xml parsed structures (as already populated by xml_parse() called in post_request() with "parsexml" option) while cuprodigy_xml_xjo_overloaded_accounts() processes its GetMemberRelatedAccounts data.
   local($using_cuprodigy_method);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_XJO
	#
	undef(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST);
	$using_cuprodigy_method="GetMemberRelatedAccounts";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML GetMemberRelatedAccounts: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&GetMemberRelatedAccounts("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GetMemberRelatedAccounts: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="jointAccounts",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="account",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,@key_prefix);
									$cuprodigy_accountCategory=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountCategory",${XML_SINGLE})};
									$cuprodigy_accountType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountType",${XML_SINGLE})};
									$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
									$cuprodigy_transactionsRestricted=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"transactionsRestricted",${XML_SINGLE})};
									($cuprodigy_accountNumber__mb,$cuprodigy_accountNumber__dplncc)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
									if(1){
										$cuprodigy_openStatus=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openStatus",${XML_SINGLE})};
										$cuprodigy_lastTranDate=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"lastTranDate",${XML_SINGLE})};
									}else{
										$cuprodigy_openStatus="open";	# Fake a CUProdigy <openStatus> value
										$cuprodigy_lastTranDate="9999-12-31";	# Fake a CUProdigy <lastTranDate> value
									}
									$DPLNCC="";
									if    (&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__CUPRODIGY},"",1)){
										$DPLNCC="DP";
									}elsif(&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__CUPRODIGY},"",1)){
										$DPLNCC="LN";
									}elsif($configure_account_by_cuprodigy_type__creditcard_behavior{${cuprodigy_accountType}} ne ""){
										$DPLNCC="CC";
									}elsif($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"availableBalance",${XML_SINGLE})} ne ""){	# Implies DP balance record
										$DPLNCC="DP";
									}elsif($XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"payoff",${XML_SINGLE})} ne "" or $XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"openingBalance",${XML_SINGLE})} ne ""){	# Implies LN balance record
										$DPLNCC="LN";
									}else{
										$DPLNCC="";
									}
									if(${cuprodigy_xml_request_membernumber} ne ${cuprodigy_accountNumber__mb}){
										if(${DPLNCC} eq ""){
											if(${record_messages_in_logfile}){
												($xml_ref_1="<".join("><",split(/$;/,$key_prefix),"accountCategory").">")=~s/<[0-9][0-9]*>//g;
												($xml_ref_2="<".join("><",split(/$;/,$key_prefix),"accountType").">")=~s/<[0-9][0-9]*>//g;
												($xml_ref_3="<".join("><",split(/$;/,$key_prefix),"accountNumber").">")=~s/<[0-9][0-9]*>//g;
												&logfile("cuprodigy_xml_xjo_overloaded_accounts(): Unmapped value from ${CTRL__SERVER_REFERENCE__CUPRODIGY} where ".${xml_ref_1}." is '".${cuprodigy_accountCategory}."' and ".${xml_ref_2}." is '".${cuprodigy_accountType}."' and ".${xml_ref_3}." is '".${cuprodigy_accountNumber}."'; skipping the XJO/Overloaded balance record.\n");
											}
										}else{
											($flag_exclude,$cuprodigy_openStatus,$cuprodigy_lastTranDate)=&cuprodigy_xml_balances_apply_limits__eval_openStatus_lastTranDate(${cuprodigy_xml_request_membernumber},${DPLNCC},${cuprodigy_openStatus},${cuprodigy_lastTranDate});
											if(!${flag_exclude}){
												push(@XML_MB_XJO_OVERLOADED_ACCOUNT_LIST,join("\t",
													${cuprodigy_xml_request_membernumber},
													${cuprodigy_accountCategory},
													${cuprodigy_accountType},
													${cuprodigy_accountNumber},
													${cuprodigy_transactionsRestricted},
													${DPLNCC},
													${cuprodigy_accountNumber__mb},
													${cuprodigy_accountNumber__dplncc},
													(&join_dms_xjo_overloaded_composit(${cuprodigy_xml_request_membernumber},${cuprodigy_accountNumber__mb},${cuprodigy_accountNumber__dplncc}))[1]
												));
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_get_member_auto_enroll_info{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd)=@_;
   local($rtrn_error_text);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($using_cuprodigy_method);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	%XML_MB_MIR
	#
	undef(%XML_MB_MIR);
	$using_cuprodigy_method="AccountInquiry";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML AccountInquiry: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&AccountInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"",sprintf("%.0f",0*${CONF__PLASTIC_CARD__USE})),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="memberInformation",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								$key_prefix=join($;,@key_prefix);
								$cuprodigy_memberNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberNumber",${XML_SINGLE})};
								$cuprodigy_pinNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"pinNumber",${XML_SINGLE})};
								$cuprodigy_nameFirst=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nameFirst",${XML_SINGLE})};
								$cuprodigy_nameMiddle=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nameMiddle",${XML_SINGLE})};
								$cuprodigy_nameLast=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nameLast",${XML_SINGLE})};
								$cuprodigy_nameSuffix=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"nameSuffix",${XML_SINGLE})};
								$cuprodigy_email=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"email",${XML_SINGLE})};
								$cuprodigy_address1=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"address1",${XML_SINGLE})};
								$cuprodigy_address2=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"address2",${XML_SINGLE})};
								$cuprodigy_city=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"city",${XML_SINGLE})};
								$cuprodigy_state=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"state",${XML_SINGLE})};
								$cuprodigy_zip=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"zip",${XML_SINGLE})};
								$cuprodigy_countryCode=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"countryCode",${XML_SINGLE})};
								$cuprodigy_foreignAddress=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"foreignAddress",${XML_SINGLE})};
								$cuprodigy_phone=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"phone",${XML_SINGLE})};
								$cuprodigy_phoneType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"phoneType",${XML_SINGLE})};
								$cuprodigy_altPhone=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"altPhone",${XML_SINGLE})};
								$cuprodigy_altPhoneType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"altPhoneType",${XML_SINGLE})};
								$cuprodigy_workPhone=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"workPhone",${XML_SINGLE})};
								$cuprodigy_eStatementActive=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"eStatementActive",${XML_SINGLE})};
								$cuprodigy_maintMode=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"maintMode",${XML_SINGLE})};
								$cuprodigy_verifyName=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"verifyName",${XML_SINGLE})};
								$cuprodigy_ssn__defined=( $XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"ssn")} ne "" ? 1 : 0 );
								$cuprodigy_ssn=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"ssn",${XML_SINGLE})};
								$cuprodigy_dob__defined=( $XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"dob")} ne "" ? 1 : 0 );
								$cuprodigy_dob=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"dob",${XML_SINGLE})};
								$cuprodigy_memberType__defined=( $XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberType")} ne "" ? 1 : 0 );
								$cuprodigy_memberType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberType",${XML_SINGLE})};
								#
								$XML_MB_MIR{"ACCOUNTNUMBER"}=${cuprodigy_memberNumber};
								$XML_MB_MIR{"NAMEFIRST"}=${cuprodigy_nameFirst};
								$XML_MB_MIR{"NAMEMIDDLE"}=${cuprodigy_nameMiddle};
								$XML_MB_MIR{"NAMELAST"}=${cuprodigy_nameLast};
								$XML_MB_MIR{"EMAIL"}=${cuprodigy_email};
								$XML_MB_MIR{"ADDRESS","ADDRESS1"}=${cuprodigy_address1};
								$XML_MB_MIR{"ADDRESS","ADDRESS2"}=${cuprodigy_address2};
								$XML_MB_MIR{"ADDRESS","CITY"}=${cuprodigy_city};
								$XML_MB_MIR{"ADDRESS","STATE"}=${cuprodigy_state};
								$XML_MB_MIR{"ADDRESS","POSTALCODE"}=${cuprodigy_zip};
								$XML_MB_MIR{"ADDRESS","COUNTRY"}="";
								$XML_MB_MIR{"DATEOFBIRTH"}="";
								$XML_MB_MIR{"MEMBERTYPE"}="";
								$XML_MB_MIR{"SSN"}="";
								$XML_MB_MIR{"PHONEHOME"}="";
								$XML_MB_MIR{"PHONEWORK"}="";
								$XML_MB_MIR{"PHONECELL"}="";
								$XML_MB_MIR{"PHONEFAX"}="";
								#
								if($cuprodigy_nameSuffix !~ /^\s*$/){
									if($XML_MB_MIR{"NAMEFIRST"} !~ /^\s*$/ and $XML_MB_MIR{"NAMELAST"} !~ /^\s*$/){
										$XML_MB_MIR{"NAMELAST"}.=" ".${cuprodigy_nameSuffix};
									}
								}
								#
								if(${cuprodigy_countryCode} =~ /^[A-Z0-9][A-Z0-9]$/i){
									($XML_MB_MIR{"ADDRESS","COUNTRY"}=${cuprodigy_countryCode})=~tr/a-z/A-Z/;
								}elsif(${CONF__MIR_DEFAULT_COUNTRY_CODE} ne "" and $cuprodigy_foreignAddress !~ /^true$/){
									$XML_MB_MIR{"ADDRESS","COUNTRY"}=${CONF__MIR_DEFAULT_COUNTRY_CODE};
								}elsif($cuprodigy_foreignAddress !~ /^true$/){
									$XML_MB_MIR{"ADDRESS","COUNTRY"}="US";
								}else{
									$XML_MB_MIR{"ADDRESS","COUNTRY"}="??";
								}
								#
								if(${cuprodigy_dob__defined}){
									$XML_MB_MIR{"DATEOFBIRTH"}=${cuprodigy_dob};
								}else{
									if(${CONF__MIR__FAKE_DATA_FOR_TESTING}){
										$XML_MB_MIR{"DATEOFBIRTH"}="19000101";
									}else{
										$XML_MB_MIR{"DATEOFBIRTH"}="";
									}
								}
								#
								if(${cuprodigy_memberType__defined}){
									$XML_MB_MIR{"MEMBERTYPE"}=$CTRL__MIR__MEMBERTYPE__CUPRODIGY_REMAP{${cuprodigy_memberType}};
									&logfile("mir_inquiry(): cuprodigy_xml_get_member_auto_enroll_info(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."The XML tag <memberType> value '${cuprodigy_memberType}' is not configured in \%CTRL__MIR__MEMBERTYPE__CUPRODIGY_REMAP.\n") if ${CONF__MIR__MEMBERTYPE__INCLUDE} and $XML_MB_MIR{"MEMBERTYPE"} eq "";
									push(@MIR_RESPONSE_NOTES,join("\t","MB",${cuprodigy_memberNumber},"mir_inquiry(): cuprodigy_xml_get_member_auto_enroll_info(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."The XML tag <memberType> value '${cuprodigy_memberType}' is not configured in \%CTRL__MIR__MEMBERTYPE__CUPRODIGY_REMAP.\n")) if ${CONF__MIR__MEMBERTYPE__INCLUDE} and $XML_MB_MIR{"MEMBERTYPE"} eq "";
								}else{
									if(${CONF__MIR__FAKE_DATA_FOR_TESTING}){
										$XML_MB_MIR{"MEMBERTYPE"}=$CTRL__MIR__MEMBERTYPE__CUPRODIGY_REMAP{""};
									}else{
										$XML_MB_MIR{"MEMBERTYPE"}="";
										&logfile("mir_inquiry(): cuprodigy_xml_get_member_auto_enroll_info(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."The XML tag <memberType> does not exist in the XML response data.\n") if ${CONF__MIR__MEMBERTYPE__INCLUDE};
										push(@MIR_RESPONSE_NOTES,join("\t","MB",${cuprodigy_memberNumber},"mir_inquiry(): cuprodigy_xml_get_member_auto_enroll_info(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."The XML tag <memberType> does not exist in the XML response data.\n")) if ${CONF__MIR__MEMBERTYPE__INCLUDE};
									}
								}
								#
								if(${cuprodigy_ssn__defined}){
									$XML_MB_MIR{"SSN"}=${cuprodigy_ssn};
								}else{
									if(${CONF__MIR__FAKE_DATA_FOR_TESTING}){
										$XML_MB_MIR{"SSN"}="555555555";
									}else{
										$XML_MB_MIR{"SSN"}="" ;
									}
								}
								#
								if($cuprodigy_workPhone !~ /^\s*$/){
										$XML_MB_MIR{"PHONEWORK"}=${cuprodigy_workPhone};
								}
								if($cuprodigy_altPhone !~ /^\s*$/){
									if    ($cuprodigy_altPhoneType =~ /^Home$/i){
										$XML_MB_MIR{"PHONEHOME"}=${cuprodigy_altPhone};
									}elsif($cuprodigy_altPhoneType =~ /^Work$/i){
										$XML_MB_MIR{"PHONEWORK"}=${cuprodigy_altPhone};
									}elsif($cuprodigy_altPhoneType =~ /^Mobile$/i){
										$XML_MB_MIR{"PHONECELL"}=${cuprodigy_altPhone};
									}elsif($cuprodigy_altPhoneType =~ /^Fax$/i){
										$XML_MB_MIR{"PHONEFAX"}=${cuprodigy_altPhone};
									}else{
										$XML_MB_MIR{"PHONEHOME"}=${cuprodigy_altPhone};
									}
								}
								if($cuprodigy_phone !~ /^\s*$/){
									if    ($cuprodigy_phoneType =~ /^Home$/i){
										$XML_MB_MIR{"PHONEHOME"}=${cuprodigy_phone};
									}elsif($cuprodigy_phoneType =~ /^Work$/i){
										$XML_MB_MIR{"PHONEWORK"}=${cuprodigy_phone};
									}elsif($cuprodigy_phoneType =~ /^Mobile$/i){
										$XML_MB_MIR{"PHONECELL"}=${cuprodigy_phone};
									}elsif($cuprodigy_phoneType =~ /^Fax$/i){
										$XML_MB_MIR{"PHONEFAX"}=${cuprodigy_phone};
									}else{
										$XML_MB_MIR{"PHONEHOME"}=${cuprodigy_phone};
									}
								}
								$XML_MB_MIR{"PHONEHOME"}=~s/[^\d]//g;	# Strip phone number value to just digits (the CUProdigy core appears to allow phone numbers to be pretty much any alpha-numeric string in any format)
								$XML_MB_MIR{"PHONEWORK"}=~s/[^\d]//g;	# Strip phone number value to just digits (the CUProdigy core appears to allow phone numbers to be pretty much any alpha-numeric string in any format)
								$XML_MB_MIR{"PHONECELL"}=~s/[^\d]//g;	# Strip phone number value to just digits (the CUProdigy core appears to allow phone numbers to be pretty much any alpha-numeric string in any format)
								$XML_MB_MIR{"PHONEFAX"}=~s/[^\d]//g;	# Strip phone number value to just digits (the CUProdigy core appears to allow phone numbers to be pretty much any alpha-numeric string in any format)
								if(${CONF__MIR_DEFAULT_PHONE_AREA_CODE} ne ""){
									substr($XML_MB_MIR{"PHONEHOME"},0,0)=${CONF__MIR_DEFAULT_PHONE_AREA_CODE} if $XML_MB_MIR{"PHONEHOME"} =~ /^\d{7}$/;
									substr($XML_MB_MIR{"PHONEWORK"},0,0)=${CONF__MIR_DEFAULT_PHONE_AREA_CODE} if $XML_MB_MIR{"PHONEWORK"} =~ /^\d{7}$/;
									substr($XML_MB_MIR{"PHONECELL"},0,0)=${CONF__MIR_DEFAULT_PHONE_AREA_CODE} if $XML_MB_MIR{"PHONECELL"} =~ /^\d{7}$/;
									substr($XML_MB_MIR{"PHONEFAX"},0,0)=${CONF__MIR_DEFAULT_PHONE_AREA_CODE} if $XML_MB_MIR{"PHONEFAX"} =~ /^\d{7}$/;
								}
								#
								$XML_MB_MIR{"PHONEHOME"}=~s/^(\d{3})(\d{3})(\d{4})$/$1-$2-$3/;
								$XML_MB_MIR{"PHONEWORK"}=~s/^(\d{3})(\d{3})(\d{4})$/$1-$2-$3/;
								$XML_MB_MIR{"PHONECELL"}=~s/^(\d{3})(\d{3})(\d{4})$/$1-$2-$3/;
								$XML_MB_MIR{"PHONEFAX"}=~s/^(\d{3})(\d{3})(\d{4})$/$1-$2-$3/;
								$XML_MB_MIR{"DATEOFBIRTH"}=~s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
								$XML_MB_MIR{"SSN"}=~s/^(\d{3})(\d{2})(\d{4})$/$1-$2-$3/;
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_lookup_plastic_card_from_signature{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$cardsignature_or_pan)=@_;
   local($rtrn_error_text,$rtrn_pan,$rtrn_code,$rtrn_state);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($XML_has_branch_cardInfo)=0;
   local($use_as_clientid);
   local($str_cardsignature_composit,$str_pan);
   local($last_4,$old_signature,$type);
   local($digest_composit,$digest_16_bytes,$random_17_bytes);
   local($test_cardsignature_composit);
   local($cuprodigy_xml_description);
   local($using_cuprodigy_method);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	%XML_MB_MIR
	#
	undef(%XML_MB_MIR);
	$using_cuprodigy_method="AccountInquiry";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML AccountInquiry: ".join(", ",${cuprodigy_xml_request_membernumber});
	return("cuprodigy_xml_lookup_plastic_card_from_signature(): Configuration variable \$CONF__PLASTIC_CARD__USE is not enabled.") if !${CONF__PLASTIC_CARD__USE};
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&AccountInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"",${CONF__PLASTIC_CARD__USE}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="memberInformation",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								$key_prefix=join($;,@key_prefix);
								$cuprodigy_memberInformation_memberNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"memberNumber",${XML_SINGLE})};
								$cuprodigy_memberInformation_entityId=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"entityId",${XML_SINGLE})};
								$cuprodigy_memberInformation_pinNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_perfix,join($;,@key_prefix),"pinNumber",${XML_SINGLE})};
								pop(@key_prefix); pop(@key_prefix);
							}
							for($tag_L06="cardInfo",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								$XML_has_branch_cardInfo=1;
								for($tag_L07="card",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,@key_prefix);
									$cuprodigy_cardInfo_card_cardNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"cardNumber",${XML_SINGLE})};
									$cuprodigy_cardInfo_card_code=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"code",${XML_SINGLE})};
									if($cuprodigy_cardInfo_card_cardNumber !~ /^\s*$/){
										if(${cardsignature_or_pan} =~ /,.*,/){
											$str_cardsignature_composit=${cardsignature_or_pan};
											if    (${CONF__PLASTIC_CARD__SIGNATURE__CLIENTID} =~ /^\d\d*$/){
												$use_as_clientid=${CONF__PLASTIC_CARD__SIGNATURE__CLIENTID};
											}elsif($cuprodigy_memberInformation_entityId =~ /^\d\d*$/){
												$use_as_clientid=${cuprodigy_memberInformation_entityId};
											}elsif($cuprodigy_memberInformation_pinNumber =~ /^\d\d*$/){
												$use_as_clientid=${cuprodigy_memberInformation_pinNumber};
											}else{
												$use_as_clientid="";
											}
											if(${use_as_clientid} ne ""){
												($last_4,$old_signature,$type)=split(/,/,${str_cardsignature_composit});
												$digest_composit=&plastic_card__fis_ezcardinfo_sso_signature_decode(${old_signature});
												$digest_16_bytes=substr($digest_composit,-16,16);
												$random_17_bytes=substr($digest_composit,0,length($digest_composit)-length(${digest_16_bytes}));
												$test_cardsignature_composit=&plastic_card__calc_signature(undef,undef,undef,undef,${cuprodigy_cardInfo_card_cardNumber},${use_as_clientid},${CONF__PLASTIC_CARD__SIGNATURE__CARDTYPE},${CONF__PLASTIC_CARD__SIGNATURE__LENGTH_RANDOM},${cuprodigy_memberInformation_entityId},${random_17_bytes});
												if(${str_cardsignature_composit} eq ${test_cardsignature_composit} and ${last_4} eq substr(${cuprodigy_cardInfo_card_cardNumber},-4,4)){
													$rtrn_pan=${cuprodigy_cardInfo_card_cardNumber};
													$rtrn_code=${cuprodigy_cardInfo_card_code};
												}
											}
										}elsif(${cardsignature_or_pan} =~ /^\d\d*$/){
											$str_pan=${cardsignature_or_pan};
											if(${str_pan} eq ${cuprodigy_cardInfo_card_cardNumber}){
												$rtrn_pan=${cuprodigy_cardInfo_card_cardNumber};
												$rtrn_code=${cuprodigy_cardInfo_card_code};
											}
										}else{
											1;
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(${rtrn_error_text} eq ""){
		if    ($CTRL__PLASTIC_CARD__CODE__KNOWN_VALUES{${rtrn_code}} eq ""){
			$rtrn_state="undef";
		}elsif($CTRL__PLASTIC_CARD__CODE__DISABLED{${rtrn_code}}){
			$rtrn_state="blocked";
		}elsif($CTRL__PLASTIC_CARD__CODE__ENABLED{${rtrn_code}}){
			$rtrn_state="unblocked";
		}else{
			$rtrn_state="cancelled";
		}
		if(!${XML_has_branch_cardInfo}){
			$rtrn_error_text="API RESPONSE HAS INCOMPLETE DATA"."\t".${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."cuprodigy_xml_lookup_plastic_card_from_signature(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method \"${using_cuprodigy_method}\": The XML branch <cardInfo> does not exist in the XML response data.";
		}
	}else{
		$rtrn_pan="";
		$rtrn_code="";
		$rtrn_state="";
	}
	return(${rtrn_error_text},${rtrn_pan},${rtrn_code},${rtrn_state});
}

sub cuprodigy_xml_get_plastic_card_attached{
   local($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$plastic_card_pan)=@_;
   local($rtrn_error_text,$rtrn_dms_attached_deposittype,$rtrn_dms_attached_membernumber,$rtrn_dms_attached_subaccount,$rtrn_dms_attached_description);
   local($header,$xmldata,$status,$soap_exception);
   local($error);
   local($cuprodigy_xml_description);
   local($XML_has_branch_cardInfo)=0;
   local($using_cuprodigy_method);
   local(@key_prefix,$key_prefix);
   local($tag_L01,$idx_L01,$limit_L01,$key_L01);
   local($tag_L02,$idx_L02,$limit_L02,$key_L02);
   local($tag_L03,$idx_L03,$limit_L03,$key_L03);
   local($tag_L04,$idx_L04,$limit_L04,$key_L04);
   local($tag_L05,$idx_L05,$limit_L05,$key_L05);
   local($tag_L06,$idx_L06,$limit_L06,$key_L06);
   local($tag_L07,$idx_L07,$limit_L07,$key_L07);
   local($tag_L08,$idx_L08,$limit_L08,$key_L08);
   local($tag_L09,$idx_L09,$limit_L09,$key_L09);
   local($tag_L10,$idx_L10,$limit_L10,$key_L10);
   local($seq,$seq_key_prefix);
   local($cuprodigy_fundingAccount,$cuprodigy_accountNumber,$cuprodigy_accountType,$cuprodigy_accountCategory);
	#
	# Will use data in:
	#	@XML_MB_DP_BALS
	#	@XML_MB_LN_BALS
	undef(%XML_MB_MIR);
	$using_cuprodigy_method="CardInquiry";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML CardInquiry: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&CardInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${plastic_card_pan}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CardInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					$rtrn_error_text=join("\t","999",${error});
					$GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG=${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ".${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG};
				}else{
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ${using_cuprodigy_method}: Response: ${error}");
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"${using_cuprodigy_method}",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	}
	if(${rtrn_error_text} eq ""){
		for($tag_L01="Envelope",$idx_L01=1,$limit_L01=$XML_DATA_BY_TAG_INDEX{join($;,$tag_L01)};$idx_L01<=$limit_L01;$idx_L01++){
			$key_L01=join($;,$tag_L01,sprintf(${XML_TAG_INDEX_FMT},${idx_L01}));
			@key_prefix=split(/$;/,$key_L01);
			for($tag_L02="Body",$idx_L02=1,$limit_L02=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L02)};$idx_L02<=$limit_L02;$idx_L02++){
				$key_L02=join($;,@key_prefix,$tag_L02,sprintf(${XML_TAG_INDEX_FMT},${idx_L02}));
				@key_prefix=split(/$;/,$key_L02);
				for($tag_L03="submitMessageResponse",$idx_L03=1,$limit_L03=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L03)};$idx_L03<=$limit_L03;$idx_L03++){
					$key_L03=join($;,@key_prefix,$tag_L03,sprintf(${XML_TAG_INDEX_FMT},${idx_L03}));
					@key_prefix=split(/$;/,$key_L03);
					for($tag_L04="return",$idx_L04=1,$limit_L04=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L04)};$idx_L04<=$limit_L04;$idx_L04++){
						$key_L04=join($;,@key_prefix,$tag_L04,sprintf(${XML_TAG_INDEX_FMT},${idx_L04}));
						@key_prefix=split(/$;/,$key_L04);
						for($tag_L05="response",$idx_L05=1,$limit_L05=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L05)};$idx_L05<=$limit_L05;$idx_L05++){
							$key_L05=join($;,@key_prefix,$tag_L05,sprintf(${XML_TAG_INDEX_FMT},${idx_L05}));
							@key_prefix=split(/$;/,$key_L05);
							for($tag_L06="cardInfo",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								$XML_has_branch_cardInfo=1;
								for($tag_L07="card",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,@key_prefix);
									if(${cuprodigy_fundingAccount} eq ""){
										$cuprodigy_fundingAccount=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"fundingAccount",${XML_SINGLE})};
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							for($tag_L06="accounts",$idx_L06=1,$limit_L06=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L06)};$idx_L06<=$limit_L06;$idx_L06++){
								$key_L06=join($;,@key_prefix,$tag_L06,sprintf(${XML_TAG_INDEX_FMT},${idx_L06}));
								@key_prefix=split(/$;/,$key_L06);
								for($tag_L07="Account",$idx_L07=1,$limit_L07=$XML_DATA_BY_TAG_INDEX{join($;,@key_prefix,$tag_L07)};$idx_L07<=$limit_L07;$idx_L07++){
									$key_L07=join($;,@key_prefix,$tag_L07,sprintf(${XML_TAG_INDEX_FMT},${idx_L07}));
									@key_prefix=split(/$;/,$key_L07);
									$key_prefix=join($;,@key_prefix);
									if(${cuprodigy_fundingAccount} ne ""){
										$cuprodigy_accountNumber=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountNumber",${XML_SINGLE})};
										$cuprodigy_accountType=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountType",${XML_SINGLE})};
										$cuprodigy_accountCategory=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"accountCategory",${XML_SINGLE})};
										if(${cuprodigy_fundingAccount} eq ${cuprodigy_accountNumber}){
											($rtrn_dms_attached_membernumber,$rtrn_dms_attached_subaccount)=&convert_cuprodigy_accountNumber_to_dms_mb_and_dplncc(${cuprodigy_accountNumber});
											$rtrn_dms_attached_description=join(" ",${cuprodigy_accountType}.${cuprodigy_accountCategory},"(may be closed)");	# A "simple" value for now, will later attempt to more "accurately" specify using data already loaded in @XML_MB_DP_BALS and @XML_MB_LN_BALS
											if    (&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_DP__CUPRODIGY},"",1)){
												$rtrn_dms_attached_deposittype="D";
											}elsif(&list_found(${cuprodigy_accountCategory},${CTRL__REMAP_LIST_ACCOUNTCATEGORY_LN__CUPRODIGY},"",1)){
												$rtrn_dms_attached_deposittype="L";
											}else{
												$rtrn_dms_attached_deposittype="";
											}
										}
									}
									pop(@key_prefix); pop(@key_prefix);
								}
								pop(@key_prefix); pop(@key_prefix);
							}
							pop(@key_prefix); pop(@key_prefix);
						}
						pop(@key_prefix); pop(@key_prefix);
					}
					pop(@key_prefix); pop(@key_prefix);
				}
				pop(@key_prefix); pop(@key_prefix);
			}
			pop(@key_prefix); pop(@key_prefix);
		}
	}
	if(${rtrn_dms_attached_membernumber} ne "" and ${rtrn_dms_attached_subaccount} ne ""){
		if(${rtrn_dms_attached_deposittype} eq "D"){
			local($idx);
			for($idx=0;$idx<=$#XML_MB_DP_BALS;$idx++){
				if((split(/\t/,$XML_MB_DP_BALS[${idx}]))[0] eq ${rtrn_dms_attached_membernumber} and (split(/\t/,$XML_MB_DP_BALS[${idx}]))[1] eq ${rtrn_dms_attached_subaccount}){
					$rtrn_dms_attached_description=(split(/\t/,$XML_MB_DP_BALS[${idx}]))[4];
				}
			}
		}
		if(${rtrn_dms_attached_deposittype} eq "L"){
			local($idx);
			for($idx=0;$idx<=$#XML_MB_LN_BALS;$idx++){
				if((split(/\t/,$XML_MB_LN_BALS[${idx}]))[0] eq ${rtrn_dms_attached_membernumber} and (split(/\t/,$XML_MB_LN_BALS[${idx}]))[1] eq ${rtrn_dms_attached_subaccount}){
					$rtrn_dms_attached_description=(split(/\t/,$XML_MB_LN_BALS[${idx}]))[6];
				}
			}
		}
	}
	if(!${XML_has_branch_cardInfo}){
		if(${rtrn_error_text} eq ""){
			$rtrn_error_text=join("\t","999","API RESPONSE HAS INCOMPLETE DATA",${CTRL__ERROR_999_PREFIX__DMS_ABNORMAL}."cuprodigy_xml_get_plastic_card_attached(): ".${CTRL__SERVER_REFERENCE__CUPRODIGY}." method \"${using_cuprodigy_method}\": The XML branch <cardInfo> does not exist in the XML response data.");
		}
	}
	return(${rtrn_error_text},${rtrn_dms_attached_deposittype},${rtrn_dms_attached_membernumber},${rtrn_dms_attached_subaccount},${rtrn_dms_attached_description});
}

sub cuprodigy_xml_accounttransfer{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML AccountTransfer: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&AccountTransfer("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountTransfer: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_accounttransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountTransfer: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_accounttransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountTransfer: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountTransfer: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_accounttransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountTransfer: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountTransfer: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"AccountTransfer",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_loanpayment{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML LoanPayment: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&LoanPayment("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanPayment: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_loanpayment(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanPayment: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_loanpayment(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanPayment: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanPayment: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_loanpayment(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanPayment: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanPayment: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"LoanPayment",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_loanaddon{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML LoanAddon: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&LoanAddon("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanAddon: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_loanaddon(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanAddon: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_loanaddon(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanAddon: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanAddon: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_loanaddon(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanAddon: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: LoanAddon: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"LoanAddon",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_checkwithdrawal{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML CheckWithdrawal: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&CheckWithdrawal("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawal: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_checkwithdrawal(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawal: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_checkwithdrawal(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawal: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawal: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_checkwithdrawal(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawal: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawal: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"CheckWithdrawal",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_checkwithdrawalloan{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML CheckWithdrawalLoan: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&CheckWithdrawalLoan("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawalLoan: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_checkwithdrawalloan(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawalLoan: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_checkwithdrawalloan(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawalLoan: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawalLoan: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_checkwithdrawalloan(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawalLoan: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CheckWithdrawalLoan: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"CheckWithdrawalLoan",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_creditcardpayment{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML CreditCardPayment: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&CreditCardPayment("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CreditCardPayment: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_creditcardpayment(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CreditCardPayment: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_creditcardpayment(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CreditCardPayment: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CreditCardPayment: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_transaction_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_creditcardpayment(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CreditCardPayment: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: CreditCardPayment: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"CreditCardPayment",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_gltomembertransfer{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML GLToMemberTransfer: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&GLToMemberTransfer("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}=&cuprodigy_gltransfer_error_sanitize($XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}});
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GLToMemberTransfer: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_gltomembertransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GLToMemberTransfer: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_gltomembertransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GLToMemberTransfer: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GLToMemberTransfer: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_gltomembertransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GLToMemberTransfer: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: GLToMemberTransfer: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"GLToMemberTransfer",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_membertogltransfer{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$from_dplncc,$from_request_membernumber,$from_dp_or_ln,$to_dplncc,$to_request_membernumber,$to_dp_or_ln,$amount,$optional_memo)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
	if(0){
		if(${cuprodigy_xml_request_membernumber} ne ${from_request_membernumber}){
			$auth_request_membernumber_ref="Requested by ${cuprodigy_xml_request_membernumber}: ";
		}
	}else{
		if(&get_glob_mbnum_with_xjo(${from_request_membernumber}) ne ""){
			$auth_request_membernumber_ref=&get_glob_mbnum_with_xjo(${from_request_membernumber}).": ";
		}
	}
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML MemberToGLTransfer: ".${auth_request_membernumber_ref}.join(", ",${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&MemberToGLTransfer("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}=&cuprodigy_gltransfer_error_sanitize($XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}});
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: MemberToGLTransfer: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_membertogltransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: MemberToGLTransfer: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_membertogltransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: MemberToGLTransfer: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: MemberToGLTransfer: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
				$error=&validate_Body_message_RS("","code+message");
			}else{
				($error,$core_system_transfer_rejection_reason)=&validate_Body_message_RS("","code+message");
			}
			if(${error} ne ""){
				&logfile("cuprodigy_xml_membertogltransfer(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: MemberToGLTransfer: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: MemberToGLTransfer: Response: ${error}");
			}
			if(${error} ne ""){
				if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){
					if(${core_system_transfer_rejection_reason} ne ""){
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
					}
				}
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"MemberToGLTransfer",${cuprodigy_xml_request_membernumber},${from_dplncc},${from_request_membernumber},${from_dp_or_ln},${to_dplncc},${to_request_membernumber},${to_dp_or_ln},${amount},${optional_memo}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_gltransfer_error_sanitize{
   my($error)=@_;
	if    ($error =~ /' is not a valid GL Transfer Description\s*$/){
		1;
	}elsif($error =~ /" is not a valid GL Transfer Description\s*$/){
		1;
	}elsif($error =~ / is not a valid GL Transfer Description\s*$/){
		if($error =~ /".* is not a valid GL Transfer Description\s*$/){
			$error=~s/^(.*)( is not a valid GL Transfer Description\s*$)/'$1'$2/;
		}else{
			$error=~s/^(.*)( is not a valid GL Transfer Description\s*$)/"$1"$2/;
		}
	}
   return(${error});
}

sub cuprodigy_xml_estatementinquiry{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error);
   local(@key_prefix,$key_prefix);
   local($cuprodigy_estatementactive);
	#
	# Will populate (calling routine must have declared as "local()"):
	#	@XML_MB_ESTATEMENTACTIVE
	undef(@XML_MB_ESTATEMENTACTIVE);
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML AccountInquiry: ".join(", ",${cuprodigy_xml_request_membernumber});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&AccountInquiry("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"",sprintf("%.0f",0*${CONF__PLASTIC_CARD__USE})),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_estatementinquiry(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_estatementinquiry(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				&logfile("cuprodigy_xml_estatementinquiry(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: AccountInquiry: Response: ${error}");
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"AccountInquiry",${cuprodigy_xml_request_membernumber}) if ${rtrn_error_text} ne "";
	@key_prefix=("Envelope",${XML_SINGLE},"Body",${XML_SINGLE},"submitMessageResponse",${XML_SINGLE},"return",${XML_SINGLE});
	$key_prefix=join($;,@key_prefix);
	$cuprodigy_estatementactive=$XML_DATA_BY_TAG_INDEX{join($;,$key_prefix,"response",${XML_SINGLE},"memberInformation",${XML_SINGLE},"eStatementActive",${XML_SINGLE})};
	push(@XML_MB_ESTATEMENTACTIVE,${cuprodigy_estatementactive});
	return(${rtrn_error_text});
}

sub cuprodigy_xml_estatementchange{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$enable_electronic_statement)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error);
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML EStatementChange: ".join(", ",${cuprodigy_xml_request_membernumber},${enable_electronic_statement});
	if(${rtrn_error_text} eq ""){
		if($enable_electronic_statement =~ /^1$|^true$|^yes$/i){
			($header,$xmldata,$status,$soap_exception)=&post_request(&EStatementActivation("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${enable_electronic_statement}),"filternulls,filternonprintables,parsexml,limitedreturn","");
			$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: EStatementActivation: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		}else{
			&logfile("cuprodigy_xml_estatementchange(): The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not have any ${CTRL__SERVER_REFERENCE__DMS} request method available to disable E-Statements.\n");
			$rtrn_error_text=join("\t","999","The ${CTRL__SERVER_REFERENCE__CUPRODIGY} does not have any ${CTRL__SERVER_REFERENCE__DMS} request method available to disable E-Statements");
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_estatementchange(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: EStatementActivation: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_estatementchange(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: EStatementActivation: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: EStatementActivation: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				&logfile("cuprodigy_xml_estatementchange(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: EStatementActivation: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: EStatementActivation: Response: ${error}");
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"EStatementActivation",${cuprodigy_xml_request_membernumber},${enable_electronic_statement}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_changecardstatus{
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$plastic_card_pan,$enable_plastic_card)=@_;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error);
   my($masked_plastic_card_pan) = '*' x length(${plastic_card_pan})-4 . substr(${plastic_card_pan},-4,4);
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML ChangeCardStatus: ".join(", ",${cuprodigy_xml_request_membernumber},${masked_plastic_card_pan});
	if(${rtrn_error_text} eq ""){
		($header,$xmldata,$status,$soap_exception)=&post_request(&ChangeCardStatus("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},${plastic_card_pan},${enable_plastic_card}),"filternulls,filternonprintables,parsexml,limitedreturn","");
		$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ChangeCardStatus: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_error_RS("");
			if(${error} ne ""){
				if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
					&logfile("cuprodigy_xml_changecardstatus(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ChangeCardStatus: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					$rtrn_error_text=join("\t","999",${error});
				}else{
					&logfile("cuprodigy_xml_changecardstatus(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ChangeCardStatus: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ChangeCardStatus: ${error}");
				}
			}
		}
		if(${rtrn_error_text} eq ""){
			$error=&validate_Body_message_transaction_RS("");
			if(${error} ne ""){
				&logfile("cuprodigy_xml_changecardstatus(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ChangeCardStatus: Response: ${error}\n");
				$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: ChangeCardStatus: Response: ${error}");
			}
		}
	}
	&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"ChangeCardStatus",${cuprodigy_xml_request_membernumber},${enable_plastic_card}) if ${rtrn_error_text} ne "";
	return(${rtrn_error_text});
}

sub cuprodigy_xml_emailupdate{	# CUProdigy's UpdateInfo method request and respons is formatted just like all of CUProdigy's "Transaction" methods (for funds transfers) requests and responses.
   my($cuprodigy_xml_request_membernumber,$cuprodigy_xml_request_memberpwd,$next_email,$curr_email)=@_;
   my($rtrn)=1;
   my($rtrn_error_text);
   my($header,$xmldata,$status,$soap_exception);
   my($error,$core_system_transfer_rejection_reason);
   my($auth_request_membernumber_ref);
   my($const_curr_email_raw,$const_next_email_raw);
   my($const_curr_email_sane,$const_next_email_sane);
   	$auth_request_membernumber_ref=$cuprodigy_xml_request_membernumber.": ";
	$cuprodigy_xml_description="".${CTRL__SERVER_REFERENCE__CUPRODIGY}." XML UpdateInfo: ".${auth_request_membernumber_ref}.join(", ","email",${next_email},${curr_email});
	if($rtrn == 1){
		if($next_email =~ /^\s*$/){
			$rtrn=0;
		}
	}
	if(${rtrn} == 1){
		$const_curr_email_raw=${curr_email};
		$const_curr_email_raw=~s/^\s*//; $const_curr_email_raw=~s/\s*$//;
		$const_curr_email_sane=${curr_email};
		$const_curr_email_sane=~s/^\s*//; $const_curr_email_sane=~s/\s*$//; $const_curr_email_sane=~tr/A-Z/a-z/;
		if($const_curr_email_sane !~ /@/){ $const_curr_email_sane=~s/%40/@/; }
		$const_next_email_raw=${next_email};
		$const_next_email_raw=~s/^\s*//; $const_next_email_raw=~s/\s*$//;
		$const_next_email_sane=${next_email};
		$const_next_email_sane=~s/^\s*//; $const_next_email_sane=~s/\s*$//; $const_next_email_sane=~tr/A-Z/a-z/;
		if($const_next_email_sane !~ /@/){ $const_next_email_sane=~s/%40/@/; }
		if(${const_curr_email_sane} eq ${const_next_email_sane}){
			
			$rtrn=2;
			&logfile("cuprodigy_xml_emailupdate(): Member ${cuprodigy_xml_request_membernumber}: No change in email address.\n") if ${CONF__EMAILUPDATE__LOG_WHEN_NO_CHANGE};
		}
	}
	if(${rtrn} == 1){
		&cuprodigy_xml_emailupdate_log(1,"request",${cuprodigy_xml_request_membernumber},${const_curr_email_raw},${const_next_email_raw},"");
		&cuprodigy_xml_emailupdate_log(2,"adjust",${cuprodigy_xml_request_membernumber},${const_curr_email_sane},${const_next_email_sane},"");
	}
	if(${rtrn} == 1){
		if(length(${const_next_email_sane}) > 999){
			$rtrn=0;
			&logfile("cuprodigy_xml_emailupdate(): Member ${cuprodigy_xml_request_membernumber}: Can not update ${CTRL__CORE_VAR} for email address because the new email address value is too long: ${const_next_email_sane}\n");
			&cuprodigy_xml_emailupdate_log(3,"error",${cuprodigy_xml_request_membernumber},${const_curr_email_sane},${const_next_email_sane},"New email address value is too long (999 character limit)");
		}
	}
	if(${rtrn} == 1){
		if(${rtrn_error_text} eq ""){
			($header,$xmldata,$status,$soap_exception)=&post_request(&UpdateInfo("",${cuprodigy_xml_request_membernumber},${cuprodigy_xml_request_memberpwd},"email",${next_email}),"filternulls,filternonprintables,parsexml,limitedreturn","");
			$rtrn_error_text=&common_cuprodigy_soap_like_errors("999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: ",${status},${soap_exception},join("\t",$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_CODE}},$XML_DATA_BY_TAG_INDEX{${XML_KEY__ERROR_DESCRIPTION}}));
			if(${rtrn_error_text} eq ""){
				$error=&validate_Body_message_error_RS("");
				if(${error} ne ""){
					if(${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR}){	# For pre-"Jetty" API version (before 2022-12-12)
						&logfile("cuprodigy_xml_emailupdate(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
						$rtrn_error_text=join("\t","999",${error});
						&cuprodigy_xml_emailupdate_log(3,"error",${cuprodigy_xml_request_membernumber},${const_curr_email_sane},${const_next_email_sane},${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: ${GLOB__CUPRODIGY_SERVER__INTERNAL_TIMEOUT_ERROR__ERRMSG}\n");
					}else{
						&logfile("cuprodigy_xml_emailupdate(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: ${error}\n");
						$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: ${error}");
						&cuprodigy_xml_emailupdate_log(3,"error",${cuprodigy_xml_request_membernumber},${const_curr_email_sane},${const_next_email_sane},${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: ${error}\n");
					}
				}
			}
			if(${rtrn_error_text} eq ""){
				if(!${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){	# Yes, CUProdigy's UpdateInfo method response is formatted just like all of CUProdigy's "Transaction" methods (for funds transfers) responses.
					$error=&validate_Body_message_transaction_RS("","code+message");
				}else{
					($error,$core_system_transfer_rejection_reason)=&validate_Body_message_transaction_RS("","code+message");
				}
				if(${error} ne ""){
					&logfile("cuprodigy_xml_emailupdate(): ".${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: Response: ${error}\n");
					$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: Response: ${error}");
					&cuprodigy_xml_emailupdate_log(3,"error",${cuprodigy_xml_request_membernumber},${const_curr_email_sane},${const_next_email_sane},${CTRL__ERROR_999_PREFIX__CUPRODIGY}."Failed using method: UpdateInfo: Response: ${error}\n");
				}
				if(${error} ne ""){
					if(${CTRL__METHOD__TRANSFER__MESSAGE_RESPONSE_STATUS__IS_NORMAL}){	# Yes, CUProdigy's UpdateInfo method response is formatted just like all of CUProdigy's "Transaction" method (for funds transfers) responses.
						if(${core_system_transfer_rejection_reason} ne ""){
							$rtrn_error_text=join("\t","999",${CTRL__ERROR_999_PREFIX__CUPRODIGY}."${core_system_transfer_rejection_reason}");
						}
					}
				}
				if(${error} eq ""){
					&cuprodigy_xml_emailupdate_log(3,"posted",${cuprodigy_xml_request_membernumber},${const_curr_email_sane},${const_next_email_sane},"");
				}
			}
		}
		&set_GLOB__PACKET_FETCH_DEBUGGING_NOTE(${error},"UpdateInfo",${cuprodigy_xml_request_membernumber},"email",${next_email}) if ${rtrn_error_text} ne "";
	}
	return(${rtrn_error_text});
}

sub cuprodigy_xml_emailupdate_log{
   local($level_order,$level_text,@values)=@_;
   local($EMAIL_LOGFILE_MAX_BYTES)=20971520;
   local($EMAIL_LOGFILE_NAME);
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f);
   local($timestamp);
   local($fmt_pid);
   local(*EMAIL_LOGFILE_LOCK,*EMAIL_LOGFILE_FH);
	$fmt_pid=sprintf("%07.0f",$$);
	@f=localtime(time());
	$timestamp=sprintf("%04d%02d%02d%02d%02d%02d",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	if(${CTRL__DMS_ADMINDIR} eq ""){
		$EMAIL_LOGFILE_NAME="${DMS_HOMEDIR}/q_email.log";
	}else{
		$EMAIL_LOGFILE_NAME="${CTRL__DMS_ADMINDIR}/q_email.log";
	}
	if(! -f "${EMAIL_LOGFILE_NAME}.lock"){
		open(EMAIL_LOGFILE_LOCK,"+>>${EMAIL_LOGFILE_NAME}.lock");
		chmod(0666,"${EMAIL_LOGFILE_NAME}.lock");
	}else{
		open(EMAIL_LOGFILE_LOCK,"+>>${EMAIL_LOGFILE_NAME}.lock");
	}
	flock(EMAIL_LOGFILE_LOCK,${LOCK_EX});
	seek(EMAIL_LOGFILE_LOCK,0,2);
	if(! -f ${EMAIL_LOGFILE_NAME}){
		open(EMAIL_LOGFILE_FH,"+>>${EMAIL_LOGFILE_NAME}");
		chmod(0666,${EMAIL_LOGFILE_NAME});
	}else{
		open(EMAIL_LOGFILE_FH,"+>>${EMAIL_LOGFILE_NAME}");
	}
	if(-s EMAIL_LOGFILE_FH > ${EMAIL_LOGFILE_MAX_BYTES} and ${level_order} eq "1"){
		if(-f "${EMAIL_LOGFILE_NAME}O.8"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.8","${EMAIL_LOGFILE_NAME}O.9")){
				system("mv '${EMAIL_LOGFILE_NAME}O.8' '${EMAIL_LOGFILE_NAME}O.9'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.7"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.7","${EMAIL_LOGFILE_NAME}O.8")){
				system("mv '${EMAIL_LOGFILE_NAME}O.7' '${EMAIL_LOGFILE_NAME}O.8'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.6"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.6","${EMAIL_LOGFILE_NAME}O.7")){
				system("mv '${EMAIL_LOGFILE_NAME}O.6' '${EMAIL_LOGFILE_NAME}O.7'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.5"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.5","${EMAIL_LOGFILE_NAME}O.6")){
				system("mv '${EMAIL_LOGFILE_NAME}O.5' '${EMAIL_LOGFILE_NAME}O.6'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.4"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.4","${EMAIL_LOGFILE_NAME}O.5")){
				system("mv '${EMAIL_LOGFILE_NAME}O.4' '${EMAIL_LOGFILE_NAME}O.5'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.3"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.3","${EMAIL_LOGFILE_NAME}O.4")){
				system("mv '${EMAIL_LOGFILE_NAME}O.3' '${EMAIL_LOGFILE_NAME}O.4'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.2"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.2","${EMAIL_LOGFILE_NAME}O.3")){
				system("mv '${EMAIL_LOGFILE_NAME}O.2' '${EMAIL_LOGFILE_NAME}O.3'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.1"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.1","${EMAIL_LOGFILE_NAME}O.2")){
				system("mv '${EMAIL_LOGFILE_NAME}O.1' '${EMAIL_LOGFILE_NAME}O.2'");
			}
		}
		if(-f "${EMAIL_LOGFILE_NAME}O.0"){
			if(!rename("${EMAIL_LOGFILE_NAME}O.0","${EMAIL_LOGFILE_NAME}O.1")){
				system("mv '${EMAIL_LOGFILE_NAME}O.0' '${EMAIL_LOGFILE_NAME}O.1'");
			}
		}
		if(!rename("${EMAIL_LOGFILE_NAME}","${EMAIL_LOGFILE_NAME}O.0")){
			system("mv '${EMAIL_LOGFILE_NAME}' '${EMAIL_LOGFILE_NAME}O.0'");
		}
		open(EMAIL_LOGFILE_FH,"+>>${EMAIL_LOGFILE_NAME}");
		chmod(0666,${EMAIL_LOGFILE_NAME});
	}
	print EMAIL_LOGFILE_FH join("\t",${timestamp},${fmt_pid},${level_order},${level_text},@values),"\n";
	close(EMAIL_LOGFILE_FH);
	flock(EMAIL_LOGFILE_LOCK,${LOCK_UN});
	close(EMAIL_LOGFILE_LOCK);
}

#===============================================================================
# Altered I/O Functions
#===============================================================================

sub debug_log_cuprodigy_io{
   my($tag,@data)=@_;
   local(*LOGDATA);
	open(LOGDATA,">>debug_log_cuprodigy_io.out".${DEBUG__LOG_CUPRODIGY_IO__service_id_ext});
	if($tag ne ""){
		print LOGDATA ${tag}," ",&filter_to_printable_data(join("",@data)),"\n";
	}else{
		print LOGDATA &filter_to_printable_data(join("",@data)),"\n";
	}
	close(LOGDATA);
}

#===============================================================================
# Altered DBM Functions
#===============================================================================

sub dbm_local_scoping__XML_DATA_BY_TAG_INDEX{
   my($action,$dbmfile,$dbmmode)=@_;
   my($error);
	# Because scoping with "local(%XML_DATA_BY_TAG_INDEX);" is ignored by DBM.
	if(${CTRL__DBM_FILE__XML_DATA_BY_TAG_INDEX} > 0){
		$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count=sprintf("%.0f",${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count});
		if    ($action=~/^dbmopen$/i){
			if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} != 0){
				$error="Action argument 'dbmopen' called before expected 'dbmclose' (already have an active 'dbmopen').";
			}else{
				$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmfile=${dbmfile};
				$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmmode=${dbmmode};
				if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmfile} eq ""){
					$error="Need first call using 'dbmopen' to include an argument for 'dbmfile'.";
				}else{
					dbmopen(%XML_DATA_BY_TAG_INDEX,${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmfile},${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmmode});
					$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count=sprintf("%.0f",${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count}+1);
				}
			}
		}elsif($action=~/^push$/i){
			# Do not need to do anything when local scoping works with DBM 
			if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} < 1){
				$error="Action argument 'push' called before 'dbmopen'.";
			}else{
				if(${CTRL__DBM_FILE__PERL_GLITCH_IGNORES_LOCAL_SCOPING} > 0){
					if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} == 1){
						dbmclose(%XML_DATA_BY_TAG_INDEX);
					}
				}
				$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count=sprintf("%.0f",${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count}+1);
			}
		}elsif($action=~/^dbmclose$/i){
			if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} != 1){
				if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} == 0){
					$error="Action argument 'dbmclose' used before expected 'dbmopen'.";
				}else{
					$error="Action argument 'dbmclose' used before expected 'pop'.";
				}
			}else{
				dbmclose(%XML_DATA_BY_TAG_INDEX);
				$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count=sprintf("%.0f",${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count}-1);
			}
		}elsif($action=~/^pop$/i){
			# Do not need to do anything when local scoping works with DBM 
			if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} <= 1){
				$error="Action argument 'pop' called out-of-sync with 'push'.";
			}else{
				$dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count=sprintf("%.0f",${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count}-1);
				if(${CTRL__DBM_FILE__PERL_GLITCH_IGNORES_LOCAL_SCOPING} > 0){
					if(${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__count} == 1){
						dbmopen(%XML_DATA_BY_TAG_INDEX,${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmfile},${dbm_local_scoping__XML_DATA_BY_TAG_INDEX__dbmmode});
					}
				}
			}
		}else{
			$error="Invalid argument: ${action}";
		}
	}
	return(${error});
}

#===============================================================================
# SUBROUTINE DEFINITIONS -- SIMULTANIOUS REQUEST
#===============================================================================

sub simultanious_request_blocking{
   local($action,$tag,$mbnum,@optional)=@_;
   local($rtrn)=0;	# Default to return 0 (is not a simultanious request).
   local($lockfile);
   local($cleanup_lockfiles_beginning);
	$lockfile="/tmp/srblf${VAR_CUID}${VAR_EXTENSION}.${mbnum}.${tag}";
	$cleanup_lockfiles_beginning="/tmp/srblf${VAR_CUID}${VAR_EXTENSION}.${mbnum}.";
	if(@optional>0){
		$lockfile.=".".join(".",@optional);
	}
	if    ($action=~/^START$/i){
		if(${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST}){
			if(&simultanious_request_blocking_lockfile("START",${lockfile})){
				$rtrn=0;	# Is not a simultanious request so return 0.
				$GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT="";
			}else{
				$rtrn=1;	# Is a simultanious request so return 1.
				$GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT=$CTRL__STATUS_TEXT{${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST__STATUS_ERRNO}};
				if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT} eq ""){
					$GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT=$CTRL__STATUS_TEXT{"099"};
				}
				if(${GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT} eq ""){
					$GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT="simultanious_request_blocking";
				}
			}
		}
	}elsif($action=~/^STOP$/i){
		if(${CTRL__RETURN_IMMEDIATE_099_FOR_SIMULTANIOUS_REQUEST}){
			$rtrn=0;		# For STOP always return 0.
			if(&simultanious_request_blocking_lockfile("LOCKED",${lockfile})){
				&simultanious_request_blocking_cleanup(${cleanup_lockfiles_beginning},${lockfile});
				&simultanious_request_blocking_lockfile("STOP",${lockfile});
			}
			$GLOB__STACKED_ERROR_SIMULTANIOUS_REQUEST_TEXT="";
		}
	}
	return(${rtrn});
}

sub simultanious_request_blocking_lockfile{
   local($action,$lockfile)=@_;
   local($rtrn)=0;
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(@f,$now,$timestamp);
   local($when_who_what);
	$now=time();
	@f=localtime($now);
	$timestamp=sprintf("%010d  %04d%02d%02d%02d%02d%02d  %07d",$now,1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0],$$);
	if    ($action =~ /^START$/i){
		if(open(SIMULTANIOUS_REQUEST_LOCKFILE,"+>>${lockfile}")){
			if(flock(SIMULTANIOUS_REQUEST_LOCKFILE,${LOCK_EX}|${LOCK_NB})){
				$rtrn=1;	# Do have lockfile so return 1.
				seek(SIMULTANIOUS_REQUEST_LOCKFILE,0,0);
				truncate(SIMULTANIOUS_REQUEST_LOCKFILE,0);
				print SIMULTANIOUS_REQUEST_LOCKFILE ${timestamp},"  ","simultanious_request_blocking_lockfile=${lockfile}","\n";
				select((select(SIMULTANIOUS_REQUEST_LOCKFILE),$|=1)[$[]);
				seek(SIMULTANIOUS_REQUEST_LOCKFILE,0,0);
			}else{
				$rtrn=0;	# Do not have lockfile so return 0.
				seek(SIMULTANIOUS_REQUEST_LOCKFILE,0,0);
				while(defined($when_who_what=<SIMULTANIOUS_REQUEST_LOCKFILE>)){ last ; }
				$when_who_what=~s/[\r\n][\r\n]*$//;
				&logfile("simultanious_request_blocking_lockfile(): "."Request already being processed by: ".${when_who_what}."\n");
				close(SIMULTANIOUS_REQUEST_LOCKFILE);
			}
		}else{
			$rtrn=1;	# Can not create/append to the file (for whatever reason) so return 1 (just quietly continue on as though everything is okay).
		}
	}elsif($action =~ /^STOP$/i){
		if(!defined(fileno(SIMULTANIOUS_REQUEST_LOCKFILE)) or fileno(SIMULTANIOUS_REQUEST_LOCKFILE) eq "" or fileno(SIMULTANIOUS_REQUEST_LOCKFILE) < 0){
			$rtrn=0;	# Did not already have lockfile so return 0.
		}else{
			$rtrn=1;	# Did already have lockfile so return 1.
			seek(SIMULTANIOUS_REQUEST_LOCKFILE,0,0);
			truncate(SIMULTANIOUS_REQUEST_LOCKFILE,0);
			unlink(${lockfile});
			flock(SIMULTANIOUS_REQUEST_LOCKFILE,${LOCK_UN});
			close(SIMULTANIOUS_REQUEST_LOCKFILE);
		}
	}elsif($action =~ /^LOCKED$/i){
		if(!defined(fileno(SIMULTANIOUS_REQUEST_LOCKFILE)) or fileno(SIMULTANIOUS_REQUEST_LOCKFILE) eq "" or fileno(SIMULTANIOUS_REQUEST_LOCKFILE) < 0){
			$rtrn=0;	# Closed lockfile at this point implies no lock so return 0.
		}else{
			$rtrn=1;	# Open lockfile at this point implies that it locked so return 1.
		}
	}
	return(${rtrn});
}

sub simultanious_request_blocking_cleanup{
   local($cleanup_lockfiles_beginning,$excluding_lockfile)=@_;
   local($rtrn)=0;
   local($LOCK_SH,$LOCK_EX,$LOCK_NB,$LOCK_UN)=(1,2,4,8);
   local(*DIR);
   local(*TEST_LOCKFILE);
   local($cleanup_dir,$cleanup_filename_beg);
   local($exclude_filename);
   local($object,$mtime);
   local(@TEST_LOCKFILES,$test_lockfile);
	if($cleanup_lockfiles_beginning !~ /^\//){ $cleanup_lockfiles_beginning="./".${cleanup_lockfiles_beginning}; }
	if($excluding_lockfile !~ /^\//){ $excluding_lockfile="./".${excluding_lockfile}; }
	($cleanup_dir=${cleanup_lockfiles_beginning})=~s/\/[^\/]*$//;
	($cleanup_filename_beg=${cleanup_lockfiles_beginning})=~s/^.*\///;
	($exclude_filename=${excluding_lockfile})=~s/^.*\///;
	if(opendir(DIR,${cleanup_dir})){
		while(defined($object=readdir(DIR))){
			next if index(${object},${cleanup_filename_beg}) != $[;
			next if ${object} eq ${exclude_filename};
			next if ! -f ${object};
			$mtime=(stat(${object}))[9];
			next if sprintf("%.0f",${mtime}+1*60*60) > time();
			push(@TEST_LOCKFILES,${cleanup_dir}."/".${object});
		}
		closedir(DIR);
	}
	foreach $test_lockfile (@TEST_LOCKFILES){
		if(open(TEST_LOCKFILE,"+>>${test_lockfile}")){
			if(flock(TEST_LOCKFILE,${LOCK_EX}|${LOCK_NB})){
				unlink(${test_lockfile});
				flock(TEST_LOCKFILE,${LOCK_UN});
				$rtrn++;
			}
		}
	}
	return(${rtrn});
}

sub join_dms_xjo_overloaded_composit{
   local($mbnum,$xjo_mbnum,$dp_or_ln_or_cc,$optional__is_not_xjo)=@_;
	if    (${optional__is_not_xjo}){	# For whatever reason the caller of split_dms_xjo_overloaded_composit() knows that though the values could be interpreted as XJO they are not XJO
		$mbnum=sprintf("%.0f",${xjo_mbnum});
	}elsif(${xjo_mbnum} eq ""){
		1;
	}elsif(sprintf("%.0f",${mbnum}) eq sprintf("%.0f",${xjo_mbnum})){	# Presumes mbnum and xjo_mbnum are numeric integers
		1;
	}else{
		if(${CONF__XJO__USE} and ${CTRL__XJO_OVERLOADED__INCLUDE_IN_BALANCES}){
			$dp_or_ln_or_cc.='@'.sprintf("%.0f",${xjo_mbnum});
		}else{
			$mbnum=sprintf("%.0f",${xjo_mbnum});
		}
	}
	return(${mbnum},${dp_or_ln_or_cc});
}

sub split_dms_xjo_overloaded_composit{
   local($mbnum,$dp_or_ln_or_cc,$optional__is_not_xjo)=@_;
	if    (${optional__is_not_xjo}){	# For whatever reason the caller of split_dms_xjo_overloaded_composit() knows that though the values could be interpreted as XJO they are not XJO
		1;
	}elsif(${CONF__XJO__USE}){
		if($dp_or_ln_or_cc =~ /@[^@][^@]*$/){	# Presumes mbnum is numeric integer (does not contain an '@').
			$dp_or_ln_or_cc=${`};
			$mbnum=${&}; $mbnum=~s/^@//;
		}
	}
	return(${mbnum},${dp_or_ln_or_cc});
}

sub set_glob_mbnum{
   local($mbnum)=@_;
	$glob_mbnum=${mbnum};
}

sub get_glob_mbnum{
   local($mbnum)=@_;
	if(${glob_mbnum} ne ""){
		$mbnum=${glob_mbnum};
	}
	return(${mbnum});
}

sub get_glob_mbnum_with_xjo{
   local($mbnum)=@_;
	if(${glob_mbnum} ne ""){
		if(${glob_mbnum} ne ${mbnum}){
			$mbnum=${glob_mbnum}."/XJO#".${mbnum};
		}
	}
	return(${mbnum});
}

sub core_degradation_check{
   local($mode,$description,$core_degradation_check__time_beg,$core_degradation_check__time_end,$core_degradation_check__row_count,$core_degradation_check__bal_count)=@_;
   local($rtrn)=0;
   local($core_degradation_check__seconds,$core_degradation_check__rows_per_second,$core_degradation_check__touch_time);
   local(*CORE_DEGRADATION_CHECK__CONTROL_FILE);
	$mode=~tr/A-Z/a-z/;
	if    ($mode eq "calculate"){
		$rtrn=0;
		$GLOB__CORE_DEGRADATION_CHECK_BEGAN="";
		$core_degradation_check__row_count=sprintf("%.0f",${core_degradation_check__row_count});
		$core_degradation_check__seconds=sprintf("%.0f",${core_degradation_check__time_end}-${core_degradation_check__time_beg});
		if    (${core_degradation_check__seconds} < 0){
			&logfile("core_degradation_check(${mode}): ${description}: Skipped: The clock has been adjusted backwards on the ${CTRL__SERVER_REFERENCE__DMS}.\n");
		}elsif(${core_degradation_check__row_count} < ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND}*3){
			&logfile("core_degradation_check(${mode}): ${description}: Skipped: too few rows, ${core_degradation_check__bal_count} bals, ${core_degradation_check__row_count} rows, ${core_degradation_check__seconds} seconds.\n");
		}elsif(${core_degradation_check__seconds} == 0){
			$core_degradation_check__rows_per_second=${core_degradation_check__row_count};
			&logfile("core_degradation_check(${mode}): ${description}: ${core_degradation_check__bal_count} bals, ${core_degradation_check__row_count} rows, ${core_degradation_check__seconds} seconds, ${core_degradation_check__rows_per_second} rows per second, passed minimum ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} rps.\n");
		}else{
			$core_degradation_check__rows_per_second=sprintf("%.0f",${core_degradation_check__row_count}/${core_degradation_check__seconds});
			if(${core_degradation_check__rows_per_second} < ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND}){
				&logfile("core_degradation_check(${mode}): ${description}: ${core_degradation_check__bal_count} bals, ${core_degradation_check__row_count} rows, ${core_degradation_check__seconds} seconds, ${core_degradation_check__rows_per_second} rows per second, failed minimum ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} rps.\n");
				$rtrn=&core_degradation_check__set_control_file(${mode},${description});
			}else{
				&logfile("core_degradation_check(${mode}): ${description}: ${core_degradation_check__bal_count} bals, ${core_degradation_check__row_count} rows, ${core_degradation_check__seconds} seconds, ${core_degradation_check__rows_per_second} rows per second, passed minimum ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} rps.\n");
			}
		}
	}elsif($mode eq "remaining"){
		$rtrn=0;
		if(${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} > 0){
			if(${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS} > 0){
				$core_degradation_check__touch_time=(stat(${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE}))[9];
				$rtrn=sprintf("%.0f",${core_degradation_check__touch_time}-time());
				if($rtrn <= 0){
					$rtrn=0;
				}else{
					if(${description} ne ""){
						&logfile("core_degradation_check(${mode}): ${description}: Degradated ${CTRL__SERVER_REFERENCE__CUPRODIGY}: I/O scheduled to remain disabled for another ${rtrn} seconds (until ".&timestamp(${core_degradation_check__touch_time}).") using mtime on: ${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE}\n");
					}
				}
			}
		}
	}elsif($mode eq "began"){
		$rtrn=0;
		$GLOB__CORE_DEGRADATION_CHECK_BEGAN=join("\t",${description},time());
	}elsif($mode eq "killed"){
		$rtrn=0;
		if(${GLOB__CORE_DEGRADATION_CHECK_BEGAN} ne ""){
			($core_degradation_check__row_count,$core_degradation_check__bal_count)=&core_degradation_check__killed__estimate_row_count();
			($description,$core_degradation_check__seconds)=split(/\t/,${GLOB__CORE_DEGRADATION_CHECK_BEGAN});
			$core_degradation_check__seconds=sprintf("%.0f",time()-${core_degradation_check__seconds});
			if($core_degradation_check__row_count == 0){
				$core_degradation_check__rows_per_second=0;
			}else{
				$core_degradation_check__rows_per_second=sprintf("%.0f",${core_degradation_check__row_count}/${core_degradation_check__seconds});
			}
			if(${core_degradation_check__rows_per_second} < ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND}){
				&logfile("core_degradation_check(${mode}): ${description}: ${core_degradation_check__bal_count}e bals, ${core_degradation_check__row_count}e rows, ${core_degradation_check__seconds} seconds, ${core_degradation_check__rows_per_second}e rows per second, likely would have failed minimum ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} rps.\n");	# Note the estimate "e" qualifier for the bals and rows and rows per second values.
			}else{
				&logfile("core_degradation_check(${mode}): ${description}: ${core_degradation_check__bal_count}e bals, ${core_degradation_check__row_count}e rows, ${core_degradation_check__seconds} seconds, ${core_degradation_check__rows_per_second}e rows per second, likely would have passed minimum ${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} rps.\n");	# Note the estimate "e" qualifier for the bals and rows and rows per second values.
			}
			if(${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS} > 0){
				if(${core_degradation_check__seconds} >= ${CTRL__CORE_DEGRADATION_CHECK__KILLED_MAX_SECONDS_FOR_FAILURE}){
					$rtrn=&core_degradation_check__set_control_file(${mode},${description},"May be");
				}else{
					&logfile("core_degradation_check(${mode}): May be degradated ${CTRL__SERVER_REFERENCE__CUPRODIGY}: I/O is not being disabled in reaction to this process having been killed.\n");
				}
			}
		}
	}else{
		$rtrn=0;
	}
	return(${rtrn});
}

sub core_degradation_check__set_control_file{
   local($mode,$description,$degradated_prefix)=@_;
   local($rtrn)=0;
   local($core_degradation_check__touch_time);
   local(*CORE_DEGRADATION_CHECK__CONTROL_FILE);
	if(${degradated_prefix} eq ""){
		$degradated_prefix="Degradated";
	}else{
		$degradated_prefix.=" degradated";
	}
	if(${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS} > 0){
		$rtrn=${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS};
		$core_degradation_check__touch_time=sprintf("%.0f",time()+${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS});
		if(utime(${core_degradation_check__touch_time},${core_degradation_check__touch_time},${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE})){
			&logfile("core_degradation_check(${mode}): ${degradated_prefix} ${CTRL__SERVER_REFERENCE__CUPRODIGY}: I/O is being disabled for ${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS} seconds (until ".&timestamp(${core_degradation_check__touch_time}).") using mtime on: ${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE}\n");
		}else{
			open(CORE_DEGRADATION_CHECK__CONTROL_FILE,">${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE}");
			if(utime(${core_degradation_check__touch_time},${core_degradation_check__touch_time},${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE})){
				&logfile("core_degradation_check(${mode}): ${degradated_prefix} ${CTRL__SERVER_REFERENCE__CUPRODIGY}: I/O is being disabled for ${CONF__CORE_DEGRADATION_CHECK__FORCE_099_FOR_NEXT_SECONDS} seconds (until ".&timestamp(${core_degradation_check__touch_time}).") using mtime on: ${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE}\n");
			}else{
				&logfile("core_degradation_check(${mode}): ${description}: Failed setting mtime on: ${CTRL__CORE_DEGRADATION_CHECK__CONTROL_FILE}\n");
			}
			close(CORE_DEGRADATION_CHECK__CONTROL_FILE);
		}
	}
}

sub core_degradation_check__killed__estimate_row_count{
   local($core_degradation_check__row_count,$core_degradation_check__bal_count)=(0,0);
	if(${GLOB__CORE_DEGRADATION_CHECK_BEGAN} ne ""){		# Globally defined variable, set and cleared by "inquiry()" calls to "core_degradation_check()".
		if(${CONF__CORE_DEGRADATION_CHECK__MIN_ROWS_PER_SECOND} > 0){
			# Calculation of $core_degradation_check__row_count occurs in "inquiry()" and "core_degradation_check__killed__estimate_row_count()".
			$core_degradation_check__row_count=0;
			$core_degradation_check__row_count+=@XML_MB_DP_BALS;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_LN_BALS;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_CC_BALS;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_DP_HIST;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_LN_HIST;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_CC_HIST;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_HOLDS;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__row_count+=@XML_MB_PLASTIC_CARDS;	# Globally defined array, initialized and populated by "inquiry()".
			if(${CTRL__RECHECK_BALANCES_AFTER_HISTORY}!=0){
				$core_degradation_check__row_count+=@XML_MB_DP_BALS;	# Globally defined array, initialized and populated by "inquiry()".
				$core_degradation_check__row_count+=@XML_MB_LN_BALS;	# Globally defined array, initialized and populated by "inquiry()".
				$core_degradation_check__row_count+=@XML_MB_CC_BALS;	# Globally defined array, initialized and populated by "inquiry()".
			}
			$core_degradation_check__bal_count=0;
			$core_degradation_check__bal_count+=@XML_MB_DP_BALS;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__bal_count+=@XML_MB_LN_BALS;	# Globally defined array, initialized and populated by "inquiry()".
			$core_degradation_check__bal_count+=@XML_MB_CC_BALS;	# Globally defined array, initialized and populated by "inquiry()".
		}
	}
	return(${core_degradation_check__row_count},${core_degradation_check__bal_count});
}

sub set_GLOB__PACKET_FETCH_DEBUGGING_NOTE{
   local($failure_text,$cuprodigy_method,$mbnum,@other)=@_;
   local($SPOOL_DIR)=&use_arg_extension_always("-d","${DMS_HOMEDIR}/ADMIN",${VAR_CUID},${VAR_EXTENSION},"/CUPRODIGY_IO_RECORDING");
   local($SPOOL_MBNUM_MAXLEN)=12;
   local($SPOOL_BTREE_WIDTH)=3;
   local($MAX_ARCHIVE_COPIES)=15;
   local($mbnumdir,$mbnumfilename);
   local($anchor_text,$anchor_text_regexp);
   local(@f);
   local($timestamp_long,$timestamp_short);
	#
	# The set_GLOB__PACKET_FETCH_DEBUGGING_NOTE() should be called whenever
	# the error message is set to a value matching the regular expression:
	#	/^Failed using method: [^:][^:]*:\s\s*/
	# minimally for the likes of:
	#	Failed using method: ValidatePassword:
	#	Failed using method: AccountList:
	#	Failed using method: AccountInquiry:
	#	Failed using method: AccountTransactionHistory:
	# and optionally (maybe in the future if needed) for the likes of:
	#	Failed using method: Transfer:
	#	Failed using method: CheckWithdrawal:
	#
	$MAX_ARCHIVE_COPIES = ( ${CONF__CUPRODIGY_IO_RECORDING__MAX_ARCHIVE_COPIES} > 0 ? ${CONF__CUPRODIGY_IO_RECORDING__MAX_ARCHIVE_COPIES} : ${MAX_ARCHIVE_COPIES} ); 
	$MAX_ARCHIVE_COPIES = ( $mbnum =~ /_WITHOUT_MEMBER/ ? 250 : ${MAX_ARCHIVE_COPIES} ); 
	$SPOOL_MBNUM_MAXLEN = ( $mbnum =~ /_WITHOUT_MEMBER$/ ? 1 : ${SPOOL_MBNUM_MAXLEN} );
	@f=localtime(time());
	$timestamp_long=sprintf("%04.0f-%02.0f-%02.0f %02.0f:%02.0f:%02.0f",1900+$f[5],1+$f[4],$f[3],$f[2],$f[1],$f[0]);
	($timestamp_short=${timestamp_long})=~s/[^0-9]//g;
	($mbnumdir,$mbnumfilename)=&cache_spoolmbdir(${mbnum});
	if    ($cuprodigy_method =~ /^ValidatePassword$/){
		if($GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS =~ /^# [<>] DESC: ${cuprodigy_method} /){	# The $GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS is set in post_request().
			($anchor_text=$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS) =~s /^# [<>] //;
		}else{
			$anchor_text="DESC: ".join(" / ","ValidatePassword","MB",${mbnum},@other);	# Matches what using &ValidatePassword(...) generates.
		}
		($anchor_text_regexp=${anchor_text})=~s/\//\\\//g;
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE=join("; ",
			"Failed for MB ${mbnum}",
			"the ${CTRL__SERVER_REFERENCE__CUPRODIGY} method ValidatePassword validates the DMS/HomeCU initial password value for the member",
			"see the general logfiles as \`ls -tr ${LOGFILE_NAME}* | tail -n 3\` for entries near timestamp ${timestamp_short}",
			"see the member specific logfiles ${mbnumdir}/${mbnumfilename}.* with mtime near ${timestamp_long}, where the request XML is after the unique anchor text regexp /^# > ${anchor_text_regexp}/ and the response XML is after the unique anchor text regexp /^# < ${anchor_text_regexp}/."
		);
	}elsif($cuprodigy_method =~ /^Inquiry$/){
		if($GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS =~ /^# [<>] DESC: ${cuprodigy_method} /){	# The $GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS is set in post_request().
			($anchor_text=$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS) =~s /^# [<>] //;
		}else{
			$anchor_text="DESC: ".join(" / ","Inquiry","MB",@other);	# Matches what using &Account(...) generates.
		}
		($anchor_text_regexp=${anchor_text})=~s/\//\\\//g;
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE=join("; ",
			"Failed for MB ${mbnum}",
			"the ${CTRL__SERVER_REFERENCE__CUPRODIGY} method Inquiry provides the list of deposit and loan accounts and holds and transaction history that exist for the member",
			"see the general logfiles as \`ls -tr ${LOGFILE_NAME}* | tail -n 3\` for entries near timestamp ${timestamp_short}",
			"see the member specific logfiles ${mbnumdir}/${mbnumfilename}.* with mtime near ${timestamp_long}, where the request XML is after the unique anchor text regexp /^# > ${anchor_text_regexp}/ and the response XML is after the unique anchor text regexp /^# < ${anchor_text_regexp}/."
		);
	}elsif($cuprodigy_method =~ /^AccountInquiry$/){
		if($GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS =~ /^# [<>] DESC: ${cuprodigy_method} /){	# The $GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS is set in post_request().
			($anchor_text=$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS) =~s /^# [<>] //;
		}else{
			$anchor_text="DESC: ".join(" / ","AccountInquiry","MB",@other);	# Matches what using &Account(...) generates.
		}
		($anchor_text_regexp=${anchor_text})=~s/\//\\\//g;
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE=join("; ",
			"Failed for MB ${mbnum}",
			"the ${CTRL__SERVER_REFERENCE__CUPRODIGY} method AccountInquiry provides the list of deposit and loan accounts and holds but no transaction history that exist for the member",
			"see the general logfiles as \`ls -tr ${LOGFILE_NAME}* | tail -n 3\` for entries near timestamp ${timestamp_short}",
			"see the member specific logfiles ${mbnumdir}/${mbnumfilename}.* with mtime near ${timestamp_long}, where the request XML is after the unique anchor text regexp /^# > ${anchor_text_regexp}/ and the response XML is after the unique anchor text regexp /^# < ${anchor_text_regexp}/."
		);
	}elsif($cuprodigy_method =~ /^AccountDetailInquiry$/){
		if($GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS =~ /^# [<>] DESC: ${cuprodigy_method} /){	# The $GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS is set in post_request().
			($anchor_text=$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS) =~s /^# [<>] //;
		}else{
			$anchor_text="DESC: ".join(" / ", "AccountDetailInquiry",@other);	# Matches what using &AccountDetailInquiry(...) generates; note that $mbnum and $other[1] may be different member values, such that member $mbnum may be querying alternate member $other[1] suffix $other[2].
		}
		($anchor_text_regexp=${anchor_text})=~s/\//\\\//g;
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE=join("; ",
			"Failed for MB ${mbnum} requesting ".$other[0]." Member ".$other[1]." Account '".$other[2]."'",
			"the ${CTRL__SERVER_REFERENCE__CUPRODIGY} method AccountDetailInquiry provides account balance and holds and transaction history about specific deposit or loan accounts",
			"see the general logfiles as \`ls -tr ${LOGFILE_NAME}* | tail -n 3\` for entries near timestamp ${timestamp_short}",
			"see the member specific logfiles ${mbnumdir}/${mbnumfilename}.* with mtime near ${timestamp_long}, where the request XML is after the unique anchor text regexp /^# > ${anchor_text_regexp}/ and the response XML is after the unique anchor text regexp /^# < ${anchor_text_regexp}/."
		);
	}elsif($cuprodigy_method =~ /^Transfer$/){
		if($GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS =~ /^# [<>] DESC: ${cuprodigy_method} /){	# The $GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS is set in post_request().
			($anchor_text=$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS) =~s /^# [<>] //;
		}else{
			$anchor_text="DESC: ".join(" / ", "Transfer",$other[0],$other[1],$other[2],"");	# Matches what using &Transfer(...) generates; note that only including $other[0] and $other[1] and $other[2] because formatting everything after those 3 elements is different for DP vs LN vs CC.
		}
		($anchor_text_regexp=${anchor_text})=~s/\//\\\//g;
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE=join("; ",
			"Failed for MB ${mbnum}",
			"see the general logfiles as \`ls -tr ${LOGFILE_NAME}* | tail -n 3\` for entries near timestamp ${timestamp_short}",
			"see the member specific logfiles ${mbnumdir}/${mbnumfilename}.* with mtime near ${timestamp_long}, where the request XML is after the unique anchor text regexp /^# > ${anchor_text_regexp}/ and the response XML is after the unique anchor text regexp /^# < ${anchor_text_regexp}/."
		);
	}elsif($cuprodigy_method =~ /^CheckWithdrawal$/){
		if($GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS =~ /^# [<>] DESC: ${cuprodigy_method} /){	# The $GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS is set in post_request().
			($anchor_text=$GLOB__IO_RECORDING__METHOD_PLUS_DESCRIBERS) =~s /^# [<>] //;
		}else{
			$anchor_text="DESC: ".join(" / ", "CheckWithdrawal",$other[0],$other[1],$other[2],"");	# Matches what using &CheckWithdrawal(...) generates; note that only including $other[0] and $other[1] and $other[2] because formatting everything after those 3 elements is different for DP vs LN vs CC.
		}
		($anchor_text_regexp=${anchor_text})=~s/\//\\\//g;
		$GLOB__PACKET_FETCH_DEBUGGING_NOTE=join("; ",
			"Failed for MB ${mbnum}",
			"see the general logfiles as \`ls -tr ${LOGFILE_NAME}* | tail -n 3\` for entries near timestamp ${timestamp_short}",
			"see the member specific logfiles ${mbnumdir}/${mbnumfilename}.* with mtime near ${timestamp_long}, where the request XML is after the unique anchor text regexp /^# > ${anchor_text_regexp}/ and the response XML is after the unique anchor text regexp /^# < ${anchor_text_regexp}/."
		);
	}
}

sub convert_cuprodigy_tracenumber_new_to_old{
   local($new_cuprodigy_tracenumber,$posted_yyyymmdd)=@_;
   local($rtrn);
   local($cuprodigy_base34)="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   local($cuprodigy_day_weight)=sprintf("%.0f",679616);	# Something in CUProdigy core must have a 679616 limit such that it must be used as multiplier constant in thier tracenumber calculation
   local($part1,$part2,$part3);
   local($yyyymmddhhmmss);
   local($posted_yyyy,$posted_mm,$posted_dd);
   local($posted_overload);
	if( ( length(${new_cuprodigy_tracenumber}) != 9+6 and length(${new_cuprodigy_tracenumber}) != 9+6+1 and length(${new_cuprodigy_tracenumber}) != 9+6+2 ) or $new_cuprodigy_tracenumber !~ /^[0-9A-Z][0-9A-Z]*[0-9A-Za-z][0-9A-Za-z]$/){
		if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_LOG_WARNINGS}){
			&logfile("convert_cuprodigy_tracenumber_new_to_old($new_cuprodigy_tracenumber,$posted_yyyymmdd): Invalid format of CUProdigy tracenumber value: ${new_cuprodigy_tracenumber}\n");
		}
		$rtrn=${new_cuprodigy_tracenumber};
	}else{
		$part1=substr(${new_cuprodigy_tracenumber},0,9);
		$part2=substr(${new_cuprodigy_tracenumber},9,6);
		$part3=substr(${new_cuprodigy_tracenumber},15);
		$yyyymmddhhmmss=&conv_mapfrom(${part1},${cuprodigy_base34});
		if(${posted_yyyymmdd} eq ""){
			# From the "new" tracenumber format we can easily extract the "posted" date so specifying a "posted" date is an optional argument
			$posted_yyyymmdd=substr(${yyyymmddhhmmss},0,8);
		}else{
			$posted_yyyymmdd=~s/-//g;
		}
		$posted_yyyy=substr(${posted_yyyymmdd},0,4);
		$posted_mm=substr(${posted_yyyymmdd},4,2);
		$posted_dd=substr(${posted_yyyymmdd},6,2);
		$posted_overload=sprintf("%.0f",(${posted_yyyy}*100*100+${posted_mm}*100+${posted_dd})*${cuprodigy_day_weight});
		$rtrn=&conv_mapto(sprintf("%.0f",${posted_overload}+${yyyymmddhhmmss}),${cuprodigy_base34}).${part2}.${part3};
	}
	return(${rtrn});
}

sub convert_cuprodigy_tracenumber_old_to_new{
   local($old_cuprodigy_tracenumber,$posted_yyyymmdd)=@_;
   local($rtrn);
   local($cuprodigy_base34)="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
   local($cuprodigy_day_weight)=sprintf("%.0f",679616);	# Something in CUProdigy core must have a 679616 limit such that it must be used as multiplier constant in thier tracenumber calculation
   local($part1,$part2,$part3);
   local($yyyymmddhhmmss);
   local($posted_yyyy,$posted_mm,$posted_dd);
   local($posted_overload);
	if( ( length(${old_cuprodigy_tracenumber}) != 9+6 and length(${old_cuprodigy_tracenumber}) != 9+6+1 and length(${old_cuprodigy_tracenumber}) != 9+6+2 ) or $old_cuprodigy_tracenumber !~ /^[0-9A-Z][0-9A-Z]*[0-9A-Za-z][0-9A-Za-z]$/){
		if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_LOG_WARNINGS}){
			&logfile("convert_cuprodigy_tracenumber_old_to_new($old_cuprodigy_tracenumber,$posted_yyyymmdd): Invalid format of CUProdigy tracenumber value: ${old_cuprodigy_tracenumber}\n");
		}
		$rtrn=${old_cuprodigy_tracenumber};
	}else{
		$part1=substr(${old_cuprodigy_tracenumber},0,9);
		$part2=substr(${old_cuprodigy_tracenumber},9,6);
		$part3=substr(${old_cuprodigy_tracenumber},15);
		$overload_yyyymmddhhmmss=&conv_mapfrom(${part1},${cuprodigy_base34});
		$posted_yyyymmdd=~s/-//g;	# From the "old" tracenumber format we can not easily extract the "posted" date so instead the "posted" date must be provided as an argument
		$posted_yyyy=substr(${posted_yyyymmdd},0,4);
		$posted_mm=substr(${posted_yyyymmdd},4,2);
		$posted_dd=substr(${posted_yyyymmdd},6,2);
		$posted_overload=sprintf("%.0f",(${posted_yyyy}*100*100+${posted_mm}*100+${posted_dd})*${cuprodigy_day_weight});
		$part2=~tr/a-z/A-Z/;
		$rtrn=&conv_mapto(sprintf("%.0f",${overload_yyyymmddhhmmss}-${posted_overload}),${cuprodigy_base34}).${part2}.${part3};
		if(${CONF__HISTORY_TRACENUMBERS_RECALCULATE_LOG_WARNINGS}){
			$yyyymmddhhmmss=sprintf("%.0f",${overload_yyyymmddhhmmss}-${posted_overload});
			&logfile("convert_cuprodigy_tracenumber_old_to_new($old_cuprodigy_tracenumber,$posted_yyyymmdd): Suspect tracenumber was generated with an \"effective\" date (not the \"posted\" date): ${old_cuprodigy_tracenumber} / ${posted_date} / ".substr(${yyyymmddhhmmss},0,8)."\n") if ${posted_date} ne substr(${yyyymmddhhmmss},0,8);
		}
	}
	return(${rtrn});
}

sub conv_mapto{
   local(${base10},${map})=@_;
   local(${baseXX});
   local(${mapbase},${mapidx});
	${mapbase}=length(${map});
	while(${base10} != 0){
		${mapidx}=${base10}%${mapbase};
		${base10}=int(${base10}-(${base10}%${mapbase}));
		${base10}=int(${base10}/${mapbase});
		${baseXX}=substr(${map},${mapidx},1).${baseXX};
	}
	if(${baseXX} eq ""){
		${baseXX}=0;
	}
	return(${baseXX});
}

sub conv_mapfrom{
   local(${baseXX},${map})=@_;
   local(${base10})=0;
   local(${mapbase},${mapidx});
	${mapbase}=length(${map});
	while(${baseXX} ne ""){
		${base10}=int(${base10}*${mapbase})+index($map,substr($baseXX,0,1));
		substr($baseXX,0,1)="";
	}
	return(${base10});
}

sub subaccount_recast_uniqid{
   local($mbnum,$category,$uniqid,$overloaded_mbnum)=@_;
   local($rtrn);
	if(${CONF__SUBACCOUNT_RECAST_UNIQID__REQUIRES_MEMBER}){
		$rtrn.=${mbnum}.":";
	}
	if(${CONF__SUBACCOUNT_RECAST_UNIQID__REQUIRES_CATEGORY}){
		$rtrn.=${category}.":";
	}
	$rtrn.=${uniqid}.":".${overloaded_mbnum};
	return(${rtrn});
}

sub xxx_response_notes_print_STDOUT_as_XML{
   local($source,@response_notes)=@_;
   local($note,@lines);
   local($orig_textfilter_mode_POSTGRES);
   local($orig_textfilter_mode_HTML);
   local(@fields,$idx);
   local(%DUPLICATE_NOTE);
	if(@response_notes > 0){
		print STDOUT "<Notes>".${CTRL__EOL_CHARS};
		while(@response_notes > 0){
			$note=shift(@response_notes);
			$note=~s/[\r\n][\r\n]*$//;
			next if $DUPLICATE_NOTE{${note}};
			$DUPLICATE_NOTE{${note}}=1;
			@lines=split(/[\r\n][\r\n]*/,$note);
			while(@lines > 0){
				$lines[0]=~s/\s*$//;
				if($lines[0] ne ""){
					@fields=split(/\t/,$lines[0]);
	   				$orig_textfilter_mode_POSTGRES=${textfilter_mode_POSTGRES};
	   				$orig_textfilter_mode_HTML=${textfilter_mode_HTML};
					$textfilter_mode_POSTGRES=0;
					$textfilter_mode_HTML=1;
					for($idx=0;$idx<=$#fields;$idx++){
						$fields[${idx}]=&textfilter($fields[${idx}]);
					}
   					$textfilter_mode_POSTGRES=${orig_textfilter_mode_POSTGRES};
   					$textfilter_mode_HTML=${orig_textfilter_mode_HTML};
					$lines[0]=join("\t",@fields);
					print STDOUT $lines[0].${CTRL__EOL_CHARS} if $lines[0] ne "";
				}
				shift(@lines);
			}
		}
		print STDOUT "</Notes>".${CTRL__EOL_CHARS};
	}else{
		if(${CONF__XXX__RESPONSE_NOTES__FORCE_TAGS}){
			print STDOUT "<Notes>".${CTRL__EOL_CHARS};
			print STDOUT "</Notes>".${CTRL__EOL_CHARS};
		}
	}
}

sub plastic_card__calc_signature{
   local($mbnum,$attached_type,$attached_mbnum,$attached_subacct,$cardnumber,$clientid,$cardtype,$length_random,$hidden_random_bytes,$reuse_random_17_bytes)=@_;
   local($rtrn);
   local($fis_ezcardinfo_clientid)=${clientid};			# For FIS/EZCardInfo would be a 6 digit number.
   local($fis_ezcardinfo_cardtype)=${cardtype};			# For FIS/EZCardInfo would be "P" or "B".
   local($fis_ezcardinfo_length_random)=${length_random};	# For FIS/EZCardInfo the specs say it is suppose to be "18", but testing reveals that it must be "17".
   local($fis_ezcardinfo_sso_signature);
	# For FIS/EZCardInfo SSO Signature
	if($cardnumber =~ /^\d{16}$/){
		$fis_ezcardinfo_sso_signature=&plastic_card__fis_ezcardinfo_sso_signature(${mbnum},${attached_mbnum},${attached_subacct},${cardnumber},${fis_ezcardinfo_clientid},${fis_ezcardinfo_cardtype},${fis_ezcardinfo_length_random},${hidden_random_bytes},${reuse_random_17_bytes});
		$rtrn=join(",",substr(${cardnumber},-4,4),${fis_ezcardinfo_sso_signature},${fis_ezcardinfo_cardtype});
	}
	return(${rtrn});
}

sub plastic_card__base64_decode{
   local($encoding_base64)=@_;
   local($encoding_text);
   local($composit);
   local($idx,$encoded_length,$remain);
   local($ord1,$ord2,$ord3,$ord4);
   local($tri1,$tri2,$tri3);
	use integer;
	$encoding_base64 =~ s/^[\s\r\n][\s\r\n]*//;
	$encoding_base64 =~ s/[\s\r\n][\s\r\n]*$//;
	if    ($encoding_base64 =~ /[^A-Za-z0-9+\/=]/){
		0;
	}elsif(length($encoding_base64)%4 != 0){
		0;
	}else{
		$idx=0; $encoded_length=length(${encoding_base64});
		$encoding_base64 =~ tr/[A-Za-z0-9+\/=]/[\0-\077\177]/;
		while($idx<$encoded_length){
			$ord1=ord(substr($encoding_base64,$idx+0,1));
			$ord2=ord(substr($encoding_base64,$idx+1,1));
			$ord3=ord(substr($encoding_base64,$idx+2,1));
			$ord4=ord(substr($encoding_base64,$idx+3,1));
			$composit=($ord1<<18)|($ord2<<12)|($ord3<<6)|($ord4<<0);
			$tri1=($composit>>16)&0377;
			$tri2=($composit>>8)&0377;
			$tri3=($composit>>0)&0377;
			if    ($ord4 ne 0177){
				$encoding_text.=pack("ccc",$tri1,$tri2,$tri3);
			}elsif($ord3 ne 0177){
				$encoding_text.=pack("cc",$tri1,$tri2);
			}elsif($ord2 ne 0177){
				$encoding_text.=pack("c",$tri1);
			}
			$idx+=4;
		}
	}
	return(${encoding_text});
}

sub plastic_card__base64_encode{
   local($encoding_text)=@_;
   local($encoding_base64);
   local($idx,$encoded_length,$remain);
   local($composit);
   local($tri1,$tri2,$tri3);
   local($ord1,$ord2,$ord3,$ord4);
	use integer;
	$idx=0; $encoded_length=length(${encoding_text});
	while($idx<$encoded_length){
		$remain=$encoded_length-$idx;
		if(${remain} >= 3){
			$tri1=ord(substr($encoding_text,$idx+0,1));
			$tri2=ord(substr($encoding_text,$idx+1,1));
			$tri3=ord(substr($encoding_text,$idx+2,1));
		}elsif(${remain} >= 2){
			$tri1=ord(substr($encoding_text,$idx+0,1));
			$tri2=ord(substr($encoding_text,$idx+1,1));
			$tri3="";
		}else{
			$tri1=ord(substr($encoding_text,$idx+0,1));
			$tri2="";
			$tri3="";
		}
		$composit=($tri1<<16)|($tri2<<8)|($tri3<<0);
		$ord1=($composit>>18)&0077;
		$ord2=($composit>>12)&0077;
		$ord3=($composit>>6)&0077;
		$ord4=($composit>>0)&0077;
		$encoding_base64.=pack("cccc",$ord1,$ord2,$ord3,$ord4);
		$idx+=3;
	}
	if($tri3 eq ""){ substr($encoding_base64,-1,1)=pack("c",0177); }
	if($tri2 eq ""){ substr($encoding_base64,-2,1)=pack("c",0177); }
	$encoding_base64 =~ tr/[\0-\077\177]/[A-Za-z0-9+\/=]/;
	return(${encoding_base64});
}

sub plastic_card__fis_ezcardinfo_sso_signature{
   local($mbnum,$attached_mbnum,$attched_subacct,$cardnumber,$fis_ezcardinfo_clientid,$fis_ezcardinfo_cardtype,$fis_ezcardinfo_length_random,$hidden_random_bytes,$reuse_random_17_bytes)=@_;
   local($rtrn);
   local($random_17_bytes);	# Specs say it is suppose to be "18", but testing reveals that it must be "17".
   local($time);
   local($digest_16_bytes);
	# Generate 17 bytes of random data
	use Digest::MD5 qw(md5 md5_hex md5_base64);
	if($fis_ezcardinfo_length_random !~ /^\d\d*$/){ $fis_ezcardinfo_length_random=17; }
	if($fis_ezcardinfo_length_random < 1 ){ $fis_ezcardinfo_length_random=17; }
	if($fis_ezcardinfo_length_random > 17 ){ $fis_ezcardinfo_length_random=17; }
	if(${reuse_random_17_bytes} ne "" and length(${reuse_random_17_bytes}) == ${fis_ezcardinfo_length_random}){
		$random_17_bytes=${reuse_random_17_bytes};
	}else{
		$time=time();
		if(${attached_mbnum} eq ""){ $attached_mbnum=${mbnum}; }
		$random_17_bytes=substr(join("",md5(${attached_mbnum}.${attached_subacct}.${time}.$$),md5($$.${time}.${attached_subacct}.${attached_mbnum})),0,${fis_ezcardinfo_length_random});
		if(defined(${CUSTOM_CREDITCARD__TESTING__RANDOM})){ $random_17_bytes=${CUSTOM_CREDITCARD__TESTING__RANDOM}; }
	}
	$digest_16_bytes=md5(${hidden_random_bytes}.${random_17_bytes}.${fis_ezcardinfo_clientid}.${cardnumber});
	$rtrn=&plastic_card__fis_ezcardinfo_sso_signature_encode(${random_17_bytes}.${digest_16_bytes});	# Excludes (hides) the existence of any $hidden_random_bytes and of the $fis_ezcardinfo_client_id
	return(${rtrn});
}

sub plastic_card__fis_ezcardinfo_sso_signature_decode{
   local($encoded_signature)=@_;
   local($decoded_signature)="";
	$encoded_signature=~s/-/+/g;
	$encoded_signature=~s/_/\//g;
	$encoded_signature=~s/\./=/g;
	$decoded_signature=&plastic_card__base64_decode(${encoded_signature});
	return(${decoded_signature});
}

sub plastic_card__fis_ezcardinfo_sso_signature_encode{
   local($decoded_signature)=@_;
   local($encoded_signature)="";
	$encoded_signature=&plastic_card__base64_encode(${decoded_signature});
	$encoded_signature=~s/=/./g;
	$encoded_signature=~s/\//_/g;
	$encoded_signature=~s/\+/-/g;
	return(${encoded_signature});
}

sub min_zero{
   local($amount)=@_;
	if    ($amount =~ /^-\d\d*$/){
		$amount="0";
	}elsif($amount =~ /^-\d\d*\.\d*$/){
		$amount=~s/^-\d\d*/0/;
		$amount=~s/\d/0/g;
	}elsif($amount =~ /^-\.\d\d*$/){
		$amount=~s/^-//;
		$amount=~s/\d/0/g;
	}
	return(${amount});
}

# MARK -- To Do List {
# For INQ initial password the CUSA/FiServ method MemberVerification has been replace with the CUProdigy method ValidatePassword, however, the MIR request for CUSA/FiServ also used method MemberVerification where CUProdigy needs to use method GetMemberAutoEnrollInfo.
# Have not stripped/replaced all "MEMBER_VERIFICATION" with either "VALIDATE_PASSWORD" or "GETMEMBERAUTOENROLLINFO".
# Have not stripped/replaced all "member_verification" with either "validate_password" or "get_member_auto_enroll_info".
# Need to re-code set_GLOB__PACKET_FETCH_DEBUGGING_NOTE() for CUProdigy methods
# } MARK -- To Do List
