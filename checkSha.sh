#!/bin/bash

# if for help

shaSumString="$1"
fileToCheck="$2"
algo="$3"

if [ $1 = "-h" ] || [ $1 = "--help" ]; then
	echo "	Usage: $ ./checkSha [SHASUMSTRING] [FILETOCHECK] [ALGORITHM]"
	echo "	If [ALGORITHM] is not specificied, sha256 will be selected."
else
	if [ -z "$1" ] || [ -z "$2" ]; then
		echo "Needs Arg 1 and 2"
	elif [ -z "$3" ]; then
		echo "$shaSumString $fileToCheck" | sha256sum -c
	else
		#looking like this is not going to work
		echo "$shaSumString $fileToCheck" | shasum -a $algo -c
	fi
fi
