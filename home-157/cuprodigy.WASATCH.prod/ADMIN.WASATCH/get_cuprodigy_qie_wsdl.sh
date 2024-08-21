# File: /home/cuprodigy/ADMIN/get_cuprodigy_qie_wsdl.sh
# Gary Jay Peters
# 2014-12-15

# Get a current copy of the "QIE.wsdl" file (aka the "schema.wsdl.xsd" file)
# for the CUProdigy interface that the HomeCU I/A is connecting to.

# Example: http://10.0.254.28:19007/ws/QIE?wsdl
# Exmaple: http://ws.qie.qvera.com/

USAGE="${0} [--also-fetch-each-schema-xsd]"

func_abort(){ errno="${1}" ; shift ; echo "${@}" 1>&2 ; exit ${errno} ; }

#
ARG__ALSO_FETCH_EACH_SCHEMA_XSD=false
while [ $# -gt 0 ] ; do # {
	case "${1}" in (-?*) true ;; (*) break ;; esac
	arg="${1}" ; shift
	case "${arg}" in # {
	    (--help)				func_abort 0 "USAGE: ${USAGE}" ;;
	    (--also-fetch-each-schema-xsd)	ARG__ALSO_FETCH_EACH_SCHEMA_XSD=true ;;
	    (*)					func_abort 22 "USAGE: ${USAGE}" ;;
	esac # }
done # }
[ $# -eq 0 ] || func_abort 22 "USAGE: ${USAGE}"

#
[ -f "../dmshomecucuprodigy.cfg" ] || func_abort 2 "${0}: No file: ../dmshomecucuprodigy.cfg"
server_and_port=`( grep '\$CONF__CUPRODIGY_SERVER__TELNET_' ../dmshomecucuprodigy.cfg ; echo '$rtrn="${CONF__CUPRODIGY_SERVER__TELNET_IPADDR}:${CONF__CUPRODIGY_SERVER__TELNET_PORT}" ; print ${rtrn},"\n" if $rtrn =~ /^..*:\d\d*$/;' ) | perl`
[ "" != "${server_and_port}" ] || func_abort 22 "${0}: Failed extracting CUSA/FiServ interface ipaddr and port from: ../dmshomecucuprodigy.cfg"

#
func_split_xml_tags(){
	perl -e 'while(<>){ s/^\s*//; s/[\r\n\s]*$//; $b.=join("",$_) ; } $b=~s/</\n</g; $b=~s/>/>\n/g; $b=~s/\n\n*/\n/g; print $b;'
}

#
timestamp=`date '+%Y%m%d%H%M%S'`
(
	echo "+ lwp-request 'http://${server_and_port}/ws/QIE?WSDL' > 'QIE.wsdl.${timestamp}'" 1>&2
	lwp-request "http://${server_and_port}/ws/QIE?WSDL" > "QIE.wsdl.${timestamp}"
	echo "+ ln -s 'QIE.wsdl.${timestamp}' 'schema.wsdl.xsd.${timestamp}'" 1>&2
	sleep 1	# So "ls -ltr" sorts better
	ln -s "QIE.wsdl.${timestamp}" "schema.wsdl.xsd.${timestamp}"
)

if ${ARG__ALSO_FETCH_EACH_SCHEMA_XSD} ; then # {
	sleep 1	# So "ls -ltr" sorts better
	cat "schema.wsdl.xsd.${timestamp}" | func_split_xml_tags | \
	grep -e '^<import[^>]* namespace="' -e '^<[^:]*:import[^>]* namespace="' | sed 's/^<//; s/>$//' | \
	while read entry ; do # {
		set x `echo "${entry}"` ; shift
		namespace=""
		schemaLocation=""
		while [ $# -gt 0 ] ; do # {
			attr="${1}" ; shift
			case "${attr}" in # {
				'namespace="'*)		namespace=`echo "${attr}" | sed 's/^namespace="//; s/".*$//; s#^.*/##'` ;;
				'schemaLocation="'*)	schemaLocation=`echo "${attr}" | sed 's/^schemaLocation="//; s/".*$//'` ;;
			esac # }
		done # }
		if [ "" != "${namespace}" -a "" != "${schemaLocation}" ] ; then # {
			echo "+ lwp-request '${schemaLocation}' '>' 'schema.${namespace}.xsd.${timestamp}'" 1>&2
			lwp-request "${schemaLocation}" > "schema.${namespace}.xsd.${timestamp}"
		fi # }
	done # }
fi # }
