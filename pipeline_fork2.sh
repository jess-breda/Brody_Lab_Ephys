#!/bin/bash

stringinputfromuser=$1
echo $stringinputfromuser
lengthofstring=${#stringinputfromuser}
echo $lengthofstring
session={$stringinputfromuser:0:lengthofstring-4}
echo $session
typeoffile={$stringinputfromuser:lengthofstring-3:3}
echo $typeoffile

echo "Processing Session $session"


if [ typeoffile = ".dat" ]; then
	echo "Step stringinputfromuser: Creating rec file from dat file"
	./sdtorec -sd $stringinputfromuser -numchan 128 -mergeconf 128_Tetrodes_Sensors_CustomRF.trodesconf
#	rm ${session}.dat
else
	echo "Skipping step 1: creation rec file"
fi

	echo "Step 2: Creating mda files from rec file"
	./exportdio -rec $stringinputfromuser
	./exportmda -rec $stringinputfromuser
#	mv ${session}.rec recs
#	mv ${session}.DIO/* ${session}.mda
#	rmdir ${session}.DIO
