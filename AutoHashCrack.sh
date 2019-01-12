#!/bin/bash
# Given filenames like this:
#	vendor1-half_md5-m200.hash
#	server1-md5crypt-m500.hash
#	server2-descrypt-m1500.hash
#	vendor2-sha3_256-m5000.hash
#	vendor3-m900.hash
#
# we can programmatically run hashcat correctly
###############################
PROG="${0##*/}"
##
WD=/usr/local/src/AutoHashCrack
HCdir=/usr/local/src/hashcat-bin
DICTS=${WD}/Dictionaries/
RULEdir=${HCdir}/rules
ATTACK="-a 0"	# default to a straight (dictionary) attack
AUTORULE=0

if [ -z "${1}" -o -z "${1##*-h*}" ]
then
	echo "usage:"
	echo "${PROG} [hashfile] [options]"
	echo ""
	echo "        where [hashfile] is  {name}-{cryptinfo}-m{mode#}"
	echo "              [options] can be additional rules, or a different attack mode, per hashcat"
	echo ""
	echo "		-A 	enabled Automatic rule mode, running against all rules in ${RULEdir}"
	echo "		-l 	list restorable sessions"
	echo ""
	echo "       eg: firefly-descrypt-m1500.hash  or   alu-sha3_256-m5000.hash"
	echo "              the {cryptinfo} section is optional"
	exit 1
else
	FILE=$1
	shift
fi

FILE=${FILE//.hash/}
MODE="-${FILE##*-}"
#MODE="-${MODE%%.*}"
SESSION=${FILE}
FILE="${FILE}.hash"
POTFILE="--potfile-path=${WD}/Cracked-Hashes.pot"

if [ -z "${FILE##*-l*}" ]
then
	ls -1 *.restore | sed 's/.restore//g'
	exit 0
fi

if [ -n "$*" ]
then
	OPTIONS="$*"
	if [ -z "${OPTIONS##*-a*}" ]
	then
		ATTACK="$(echo \"${OPTIONS}\" | egrep -o -- '-a[[:space:]]*[0-9]+')"
		OPTIONS=${OPTIONS//$ATTACK/}
	elif [ -z "${OPTIONS##*--attack-mode=*}" ]
	then
		ATTACK="$(echo \"${OPTIONS}\" | egrep -o -- '--attack-mode=[^[:space:]]+')"
		OPTIONS=${OPTIONS//$ATTACK/}
	fi

	if [ -z "${OPTIONS##*-A*}" ]
	then
		#AutoRuleMode
		AUTORULE=1
		OPTIONS=${OPTIONS//-A/}
	fi

	if [ -z "${OPTIONS##*-r*}" ]
	then
		RULES="$(echo \"${OPTIONS}\" | egrep -o -- '-r[[:space:]]*[0-9]+')"
		OPTIONS=${OPTIONS//$RULES/}
	elif [ -z "${OPTIONS##*--rules-file=*}" ]
	then
		RULES="$(echo \"${OPTIONS}\" | egrep -o -- '--rules-file=[^[:space:]]+')"
		OPTIONS=${OPTIONS//$RULES/}
	fi

	if [ -z "${OPTIONS##*--potfile-path=*}" ]
	then
		POTFILE="$(echo \"${OPTIONS}\" | egrep -o -- '--potfile-path=[^[:space:]]+')"
		OPTIONS=${OPTIONS//$POTFILE/}
	fi

	if [ -z "${OPTIONS##*.hcmask*}" ]
	then
		MASKFILE="$(echo \"${OPTIONS}\" | egrep -o -- '[^[:space:]]+\.hcmask')"
		OPTIONS=${OPTIONS//$MASKFILE/}
	fi

fi


if [ -e "${WD}/${SESSION}.restore" ];
then
	hashcat --advice-disable --force --remove --status --restore --restore-file-path=${WD}/${SESSION}.restore 
else
	RESTORE="--session=${SESSION}"

	grep -q ":" ${FILE} && USERS="--username"

	if [ 1 -eq ${AUTORULE:-0} ];
	then
		for RULE in ${RULEdir}/*.rule
		do
			hashcat --advice-disable --force --remove --status ${USERS} ${POTFILE} ${RESTORE} --restore-file-path=${WD}/${SESSION}.restore ${MODE} ${ATTACK} ${OPTIONS} ${FILE} ${DICTS} --rules-file=${RULE}
		done
	else
		if [ -z "${MASKFILE}" ]
		then
			MORD=${DICTS}
		else
			MORD=${MASKFILE}
		fi
		hashcat --advice-disable --force --remove --status ${USERS} ${POTFILE} ${RESTORE} --restore-file-path=${WD}/${SESSION}.restore ${MODE} ${ATTACK} ${OPTIONS} ${FILE} ${MORD} ${RULES} 
	fi
fi

