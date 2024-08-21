#!/usr/bin/perl

$mbnum="1";
$subacct="";
$card="9999999999999999";
$old_signature_composit="9999,xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,P";

($last_4,$old_signature,$type)=split(/,/,${old_signature_composit});

$digest_composit=&plastic_card__fis_ezcardinfo_sso_signature_decode(${old_signature});
$digest_16_bytes=substr($digest_composit,-16,16);
$random_17_bytes=substr($digest_composit,0,length($digest_composit)-length(${digest_16_bytes}));
$new_signature=&plastic_card__fis_ezcardinfo_sso_signature($mbnum,$subacct,$card,$mbnum,$type,17,${random_17_bytes});

print "[${old_signature}]\n";
print "[${new_signature}]\n";

sub plastic_card__calc_signature{
   local($mbnum,$subacct,$cardnumber,$clientid,$cardtype,$length_random)=@_;
   local($rtrn);
   local($fis_ezcardinfo_clientid)=${clientid};			# For FIS/EZCardInfo would be a 6 digit number.
"358423";
   local($fis_ezcardinfo_cardtype)=${cardtype};			# For FIS/EZCardInfo would be "P" or "B".
   local($fis_ezcardinfo_length_random)=${length_random};	# For FIS/EZCardInfo the specs say it is suppose to be "18", but testing reveals that it must be "17".
   local($fis_ezcardinfo_sso_signature);
	# For FIS/EZCardInfo SSO Signature
	if($cardnumber =~ /^\d{16}$/){
		$fis_ezcardinfo_sso_signature=&plastic_card__fis_ezcardinfo_sso_signature(${mbnum},${subacct},${cardnumber},${fis_ezcardinfo_clientid},${fis_ezcardinfo_cardtype},${fis_ezcardinfo_length_random});
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
   local($mbnum,$subacct,$cardnumber,$fis_ezcardinfo_clientid,$fis_ezcardinfo_cardtype,$fis_ezcardinfo_length_random,$reuse_random_17_bytes)=@_;
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
		$random_17_bytes=substr(join("",md5(${mbnum}.${subacct}.${time}.$$),md5($$.${time}.${subacct}.${mbnum})),0,${fis_ezcardinfo_length_random});
		if(defined(${CUSTOM_CREDITCARD__TESTING__RANDOM})){ $random_17_bytes=${CUSTOM_CREDITCARD__TESTING__RANDOM}; }
	}
	$digest_16_bytes=md5(${random_17_bytes}.${fis_ezcardinfo_clientid}.${cardnumber});
	$rtrn=&plastic_card__fis_ezcardinfo_sso_signature_encode(${random_17_bytes}.${digest_16_bytes});
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
