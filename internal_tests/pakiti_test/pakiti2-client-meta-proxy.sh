#!/bin/bash

# Default values

VERSION="4"

CONF=''

SERVERS="pakiti.com"

SERVER_URL="/feed3/"

METHOD="curl"

OPENSSL_BIN=`which openssl`

CURL_BIN=`which curl`

TAG="SECANT"

CA_PATH="/etc/ssl/certs/"

HOST_CERT=""

IS_PROXY=1

REPORT=1

MAX_TIME=60



usage=$0" [-v] [-h] [-d]\n\t-v: verbose output\n\t-h: this help\n\t-d: debug output"



VERBOSE=0

DEBUG=0

TMPFILE=`mktemp`



# Getting options

while getopts "dvh" options; do

  case $options in

    v ) VERBOSE=1;;

    d ) DEBUG=1

				VERBOSE=1;;

    h ) echo -e "$usage"

         exit 1;;

    * ) echo -e "$usage"

          exit 1;;

  esac

done



if [ "X${CONF}" = "X" -o ! -f "${CONF}" ]

then

	if [ ${VERBOSE} -eq 1 ]; 

		then

	  echo "Configuration file is missing at '${CONF}', using defaults!"

	fi

else

	# Getting parameters from the configuration file

	L_SERVERS=`grep servers_name ${CONF} | grep -v \# | awk  -F "=" '{print $2}' | tr -d " "`

	L_SERVER_URL=`grep server_url ${CONF} | grep -v \# | awk  -F "=" '{print $2}' | tr -d " "`

	L_OPENSSL_BIN=`grep openssl_path ${CONF} | grep -v \# | awk -F "=" '{print $2}'`

	L_CURL_BIN=`grep curl_path ${CONF} | grep -v \# | awk -F "=" '{print $2}'`

	L_CA_PATH=`grep ca_certificate ${CONF} | grep -v \# | awk -F "=" '{print $2}'`

	L_HOST_CERT=`grep host_cert ${CONF} | grep -v \# | awk -F "=" '{print $2}'`

	L_TAG=`grep tag ${CONF} | grep -v \# | awk -F "=" '{print $2}' | tr -d " "`

	L_METHOD=`grep connection_method ${CONF} | grep -v \# | awk -F "=" '{print $2}' | tr -d " "`

	L_REPORT=`grep report ${CONF} | grep -v \# | awk -F "=" '{print $2}' | tr -d " "`

	L_IS_PROXY=`grep is_proxy ${CONF} | grep -v \# | awk -F "=" '{print $2}' | tr -d " "`



	if [ ! -z "${L_SERVERS}" ];

		then

		SERVERS=${L_SERVERS};

	fi

	if [ ! -z "${L_SERVER_URL}" ];

		then

		SERVER_URL=${L_SERVER_URL};

	fi

	if [ ! -z "${L_OPENSSL_BIN}" ];

		then

		OPENSSL_BIN=${L_OPENSSL_BIN};

	fi

	if [ ! -z "${L_CURL_BIN}" ];

		then

		CURL_BIN=${L_CURL_BIN};

	fi	

	if [ ! -z "${L_CA_PATH}" ];

		then

		CA_PATH=${L_CA_PATH};

	fi

	if [ ! -z "${L_HOST_CERT}" ];

		then

		HOST_CERT=${L_HOST_CERT};

	fi

	if [ ! -z "${L_TAG}" ];

		then

		TAG=${L_TAG};

	fi

	if [ ! -z "${L_METHOD}" ];

		then

		METHOD=${L_METHOD};

	fi

	if [ ! -z "${L_REPORT}" ];

		then

		REPORT=${L_REPORT};

	fi

	if [ ! -z "${L_IS_PROXY}" ];

		then

		IS_PROXY=${L_IS_PROXY};

	fi



	if [ ${VERBOSE} -eq 1 ];

        	then

	        echo -e "Preparing the list of installed packages...";

	fi

fi

# If proxy mode is enabled, then method cannot be stdout

if [ ${IS_PROXY} -eq 1 -a "X${METHOD}" = "Xstdout" ]; then

  echo "ERROR: Proxy and stdout method cannot be used together" >&2

  exit 1

fi

# If we are in proxy mode, read the data from stdin

if [ ${IS_PROXY} -eq 1 ]; then

  # Parse firs line which contains host,arch,os,...

  read

      ARGS=${REPLY}

  

      IFS=","

      for i in ${ARGS}; do

	VAR=`echo $i | sed -e 's/^\([a-zA-Z]*\)=.*$/\1/'`

	VAL=`echo $i | sed -e 's/^[a-zA-Z]*="\(.*\)"$/\1/'`

  

	if [ "X${VAR}" = "Xversion" ]; then

	  # Check if the client using the same version

	  if [ "X${VAL}" != "X${VERSION}" ]; then

	    echo "ERROR: Client is using version ${VAL}, but proxy is using ${VERSION}" >&2

	    exit 1

	  fi

	fi

	if [ "X${VAR}" = "Xtype" ]; then

	  TYPE=${VAL}

	fi

	if [ "X${VAR}" = "Xhost" ]; then

	  REPHOST=${VAL}

	fi

	if [ "X${VAR}" = "Xtag" ]; then

	  TAG=${VAL}

	fi

	if [ "X${VAR}" = "Xkernel" ]; then

	  KERNEL=${VAL}

	fi

	if [ "X${VAR}" = "Xarch" ]; then

	  ARCH=${VAL}

	fi

	if [ "X${VAR}" = "Xos" ]; then

	  OS=${VAL}

	fi

      done



      cat >> ${TMPFILE}

else

  # Getting system parameters

  REPHOST=`hostname -f`

  KERNEL=`uname -r | sed -e 's/\+/%2b/g'`

  ARCH=`uname -m`

  PKGS=""

  TYPE=""



  # Get list of packages by method which is available on the host

  if [ ! -z "`which rpm`"  -a  -x "`which rpm`"  ]; then

     rpm -qa --queryformat "'%{NAME}' '%{EPOCH}:%{VERSION}' '%{RELEASE}' '%{ARCH}'\n" 2>/dev/null | sed -e 's/(none)/0/g' | sed -e 's/\+/%2b/g' > ${TMPFILE}

     TYPE="rpm"

  fi

  if [ ! -s "${TMPFILE}" ]; then

     if [ ! -z "`which dpkg-query`"  -a  -x "`which dpkg-query`"  ]; then

        dpkg-query -W --showformat="\${Status}\|'\${Package}' '\${Version}' '' '\${Architecture}'\n" 2>/dev/null | grep '^install ok installed' | sed -e 's/^install ok installed|//' | sed -e 's/\+/%2b/g' > ${TMPFILE}

     fi

     if [ -s "${TMPFILE}" ]; then

  	TYPE="dpkg"

     fi

  fi



  # Looking for type of OS

  OS="unknown"

  for i in /etc/lsb-release /etc/debian_version /etc/fermi-release /etc/redhat-release /etc/fedora-release /etc/SuSE-release; do

    if [ -f $i ]; then

      case "${i}" in

	/etc/lsb-release)

	 TMP_OS=`grep DISTRIB_DESCRIPTION ${i}`

	 OS=`echo ${TMP_OS} | sed -e 's/DISTRIB_DESCRIPTION="\(.*\)"/\1/'`

	 if [ -z "${OS}" ]; then

		  TMP_OS=`grep  DISTRIB_DESC ${i}`

		  OS=`echo ${TMP_OS} | sed -e 's/DISTRIB_DESC="\(.*\)"/\1/'`

	 fi

	 ;;

	/etc/debian_version)

	 OS="Debian `cat ${i}`"

	 ;;

	/etc/fermi-release|/etc/redhat-release|/etc/fedora-release)

	 OS=`cat ${i}`

	 ;;

	/etc/SuSE-release)

	 OS=`grep -i suse ${i}`

	 ;;

      esac

    fi

    if [ "${OS}" != "unknown" ]; then

      break

    fi

  done

fi

for SERVER in $SERVERS; do 

	if [ "X${METHOD}" = "Xopenssl" ]; then
		
		# Preparing openssl s_client string

		OPENSSL_BIN="${OPENSSL_BIN} s_client";

		

		if [ "X${CA_PATH}" != "X" ]; 

			then 

			OPENSSL_BIN="${OPENSSL_BIN} -CApath \"${CA_PATH}\"";

		fi

		

		if [ ${VERBOSE} -eq 1 ];

		        then

		        OPENSSL_BIN="${OPENSSL_BIN} -msg";

			echo -e "Sending to the server...";

		else

			OPENSSL_BIN="${OPENSSL_BIN} -quiet";

		fi

		

		if [ ${DEBUG} -eq 1 ];

		        then

		        OPENSSL_BIN="${OPENSSL_BIN} -debug";

		else

			OPENSSL_BIN="${OPENSSL_BIN} -quiet";

		fi

		if [ "X${HOST_CERT}" != "X" ];

			then

			OPENSSL_BIN="${OPENSSL_BIN} -cert \"${HOST_CERT}\"";

		fi

	

		# Format of the SERVER variable is hostname:port

		OPENSSL_BIN="${OPENSSL_BIN} -connect ${SERVER}";

		

		POST_DATA="type=${TYPE}&host=${REPHOST}&os=${OS}&arch=${ARCH}&tag=${TAG}&kernel=${KERNEL}&version=${VERSION}&report=${REPORT}&proxy=${IS_PROXY}&pkgs=";

		POST_DATA_SIZE=`echo -n ${POST_DATA} | wc -m`;

		FILE_SIZE=`cat ${TMPFILE} | wc -c`

		let POST_DATA_SIZE=${POST_DATA_SIZE}+${FILE_SIZE}-1

	

		POST_HTTP_HEADER="POST ${SERVER_URL} HTTP/1.0\nContent-Type: application/x-www-form-urlencoded\nContent-Length: ${POST_DATA_SIZE}\n\n";

		 

		POST_DATA="${POST_HTTP_HEADER}${POST_DATA}";

		if [ ${VERBOSE} -eq 1 -o ${DEBUG} -eq 1 ]; then

			COMMAND="echo -e \"${POST_DATA}\" | cat - ${TMPFILE} | ${OPENSSL_BIN}";

		else

			COMMAND="echo -e \"${POST_DATA}\" | cat - ${TMPFILE} | ${OPENSSL_BIN} 2>/dev/null";

		fi

	

	elif [ "X${METHOD}" = "Xcurl" ]; then

		# Return code 22 instead HTML error page, limit the time of the execution to the MAX_TIME

		CURL=" -f -m ${MAX_TIME}"

	

		# Preparing curl string

		if [ "X${CA_PATH}" != "X" ];

		        then

		        CURL="${CURL} --connect-timeout 30 --capath \"${CA_PATH}\"";

		fi

		

		if [ ${VERBOSE} -eq 1 ];

		        then

		        CURL="${CURL} -F verbose=\"1\"";

		        echo -e "Sending to the server with curl...";

		fi

		

		if [ ${DEBUG} -eq 1 ];

		        then

		        CURL="${CURL} -F debug=\"1\"";

		fi

		

		# Be silent if debug nor verbose was requested

		if [ ${DEBUG} -ne 1 -a ${VERBOSE} -ne 1 ];

						then

						CURL="${CURL} -s";

		fi



		if [ "X${HOST_CERT}" != "X" ];

			then

			CURL="${CURL} --cert \"${HOST_CERT}\"";

		fi

		

		CURL="${CURL} -F type=\"${TYPE}\"";

		CURL="${CURL} -F host=\"${REPHOST}\"";

		CURL="${CURL} -F tag=\"${TAG}\"";

		CURL="${CURL} -F kernel=\"${KERNEL}\"";

		CURL="${CURL} -F arch=\"${ARCH}\"";

		CURL="${CURL} -F version=\"${VERSION}\"";

		CURL="${CURL} -F os=\"${OS}\"";

		CURL="${CURL} -F report=\"${REPORT}\"";

		CURL="${CURL} -F proxy=\"${IS_PROXY}\"";

		CURL="${CURL} -F pkgs=\<${TMPFILE}";

		COMMAND="${CURL_BIN}${CURL} http://${SERVER}${SERVER_URL}"

	

	elif [ "X${METHOD}" = "Xstdout" ]; then

#		OUTFILE=`mktemp`

		echo -e "type=\"${TYPE}\",host=\"${REPHOST}\",tag=\"${TAG}\",kernel=\"${KERNEL}\",arch=\"${ARCH}\",version=\"${VERSION}\",os=\"${OS}\",report=\"${REPORT}\"\n";



		cat $TMPFILE | sed -e 's/%2b/\+/g';

	fi



	RESULT=`eval "${COMMAND}"`;



	if [ $? -ne 0 ]; then

		echo "ERROR occured while sending data to the server!" >&2

		rm -f ${TMPFILE}

		exit 1

	fi



	# Print out the results

	if [ ${REPORT} -eq 1 ]; then

		if [ ! -z "${RESULT}" ]; then

			if [ "X${METHOD}" = "Xopenssl" ]; then

				# Skip HTTP response header, it is separeted from the body by the new line

				echo -e "${RESULT}" | grep -v $'[\x0d]'

			else

				echo -e "${RESULT}";

			fi

		fi

	fi

done


rm -f ${TMPFILE}


