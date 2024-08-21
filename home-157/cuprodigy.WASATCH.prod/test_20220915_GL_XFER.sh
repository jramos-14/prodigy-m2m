( ( cat ; sleep 60 ) | telnet 127.0.0.1 9003 ) << __EOD__
TRN: 29013	GT	7:00	XBLOSSOM SWEEP ACCOUNT	gary@homecu.com		29013	1.00	29013	Test transfer from share to G/L
TRN: 29013	GF	XBLOSSOM SWEEP ACCOUNT	7:00	gary@homecu.com		29013	1.00	29013	Test transfer from G/L to share
TRN: 29013	GT	7:00	BLOSSOM SWEEP ACCOUNT	gary@homecu.com		29013	1.00	29013	Test transfer from share to G/L
TRN: 29013	GF	BLOSSOM SWEEP ACCOUNT	7:00	gary@homecu.com		29013	1.00	29013	Test transfer from G/L to share
TRN: 29013	GT	7:00	BL SWP ACC	gary@homecu.com		29013	1.00	29013	Test transfer from share to G/L
TRN: 29013	GF	BL SWP ACC	7:00	gary@homecu.com		29013	1.00	29013	Test transfer from G/L to share
QUIT
__EOD__
